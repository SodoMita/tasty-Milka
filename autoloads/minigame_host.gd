extends Node
## Hosts mid-dialogue interactive overlays:
##   - `do Minigame.ask_player_name()` pops out the top-of-screen name prompt
##     (with top margin so an on-screen virtual keyboard never covers it) right
##     when Milka asks for the player's name in the middle of dialogue.
##   - `do Minigame.play_rhythm(18)` launches the visual Cookie-Clicker +
##     Rhythm Click & Optional Slide minigame.

const NAME_ENTRY_SCENE: PackedScene = preload("res://scenes/ui/name_entry.tscn")
const RHYTHM_SCENE: PackedScene = preload("res://scenes/minigame/rhythm_game.tscn")

signal name_prompt_opened(prompt: CanvasLayer)
signal name_prompt_finished(chosen_name: String)
signal minigame_finished(result: Dictionary)

var last_result: Dictionary = {}
var is_playing: bool = false
var active_name_prompt: CanvasLayer = null
var preset_next_name: String = ""

## Awaited from dialogue when Milka asks for the player's name mid-game.
func ask_player_name() -> void:
	var game_state: Node = get_tree().root.get_node_or_null("GameState")
	if not preset_next_name.is_empty():
		var auto_name: String = preset_next_name
		preset_next_name = ""
		if game_state != null and game_state.has_method("set_player_name"):
			game_state.set_player_name(auto_name)
		name_prompt_finished.emit(auto_name)
		return

	var balloon: Node = _find_balloon()
	var prev_block: bool = true
	if balloon != null:
		prev_block = bool(balloon.get("will_block_other_input"))
		balloon.set("will_block_other_input", false)
		balloon.set("is_waiting_for_input", false)

	var prompt: CanvasLayer = NAME_ENTRY_SCENE.instantiate()
	active_name_prompt = prompt
	get_tree().root.add_child(prompt)
	emit_signal.call_deferred("name_prompt_opened", prompt)
	var chosen: String = await prompt.name_confirmed
	active_name_prompt = null

	if balloon != null and is_instance_valid(balloon):
		balloon.set("will_block_other_input", prev_block)

	if game_state != null and game_state.has_method("set_player_name"):
		game_state.set_player_name(chosen)
	name_prompt_finished.emit(chosen)

## Awaited mutation. `notes` sets the rhythm chart length.
func play_rhythm(notes: int = 18) -> void:
	if is_playing:
		return
	is_playing = true
	var balloon: Node = _find_balloon()
	var prev_block: bool = true
	if balloon != null:
		prev_block = bool(balloon.get("will_block_other_input"))
		balloon.set("will_block_other_input", false)
		balloon.set("is_waiting_for_input", false)

	var game: Node = RHYTHM_SCENE.instantiate()
	game.set("note_count", notes)
	get_tree().root.add_child(game)
	var result: Dictionary = await game.finished
	is_playing = false

	if balloon != null and is_instance_valid(balloon):
		balloon.set("will_block_other_input", prev_block)

	last_result = result
	var game_state: Node = get_tree().root.get_node_or_null("GameState")
	if game_state != null and game_state.has_method("record_rhythm_result"):
		game_state.record_rhythm_result(result)
	minigame_finished.emit(result)

func _find_balloon() -> Node:
	for child: Node in get_tree().root.get_children():
		if child.get_class() == "CanvasLayer" and child.has_method("apply_dialogue_line"):
			return child
	return null

func score() -> int:
	return int(last_result.get("score", 0))

func rank() -> String:
	return String(last_result.get("rank", "unplayed"))
