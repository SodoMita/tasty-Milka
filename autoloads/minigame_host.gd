extends Node
## Hosts mid-dialogue interactive overlays above VNBalloon (layer 100):
##   - `do Minigame.ask_player_name()` pops out the top-of-screen name prompt
##     (layer 110, with top margin so an on-screen virtual keyboard never covers
##     it) right when Milka asks for the player's name mid-dialogue.
##   - `do Minigame.play_rhythm(18)` launches the visual Cookie-Clicker +
##     Rhythm Click & Optional Slide minigame (layer 110).

const NAME_ENTRY_SCENE: PackedScene = preload("res://scenes/ui/name_entry.tscn")
const RHYTHM_SCENE: PackedScene = preload("res://scenes/minigame/rhythm_game.tscn")

signal name_prompt_opened(prompt: CanvasLayer)
signal name_prompt_finished(chosen_name: String)
signal minigame_finished(result: Dictionary)

var last_result: Dictionary = {}
var is_playing: bool = false
var active_name_prompt: CanvasLayer = null
var active_rhythm_game: CanvasLayer = null
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

	var saved_balloon: Dictionary = _suspend_balloon(true)

	var prompt: CanvasLayer = NAME_ENTRY_SCENE.instantiate()
	active_name_prompt = prompt
	get_tree().root.add_child(prompt)
	emit_signal.call_deferred("name_prompt_opened", prompt)
	var chosen: String = await prompt.name_confirmed
	active_name_prompt = null

	await get_tree().process_frame
	_restore_balloon(saved_balloon)

	if game_state != null and game_state.has_method("set_player_name"):
		game_state.set_player_name(chosen)
	name_prompt_finished.emit(chosen)

## Awaited mutation. `notes` sets the rhythm chart length.
func play_rhythm(notes: int = 18) -> void:
	if is_playing:
		return
	is_playing = true
	var saved_balloon: Dictionary = _suspend_balloon(false)

	var game: CanvasLayer = RHYTHM_SCENE.instantiate()
	game.set("note_count", notes)
	active_rhythm_game = game
	get_tree().root.add_child(game)
	var result: Dictionary = await game.finished
	active_rhythm_game = null
	is_playing = false

	await get_tree().process_frame
	_restore_balloon(saved_balloon)

	last_result = result
	var game_state: Node = get_tree().root.get_node_or_null("GameState")
	if game_state != null and game_state.has_method("record_rhythm_result"):
		game_state.record_rhythm_result(result)
	minigame_finished.emit(result)

func _find_balloon() -> Node:
	var layers: Array[Node] = get_tree().root.find_children("*", "CanvasLayer", true, false)
	for child: Node in layers:
		if child.has_method("apply_dialogue_line"):
			return child
	return null

func _suspend_balloon(keep_dialogue_box_visible: bool) -> Dictionary:
	var balloon: Node = _find_balloon()
	if balloon == null or not is_instance_valid(balloon):
		return {}
	var state: Dictionary = {
		"balloon": balloon,
		"will_block": bool(balloon.get("will_block_other_input")),
	}
	balloon.set("will_block_other_input", false)
	balloon.set("is_waiting_for_input", false)
	balloon.set("skip_mode", false)
	var skip_timer: Timer = balloon.get("skip_timer") as Timer
	if skip_timer != null:
		skip_timer.stop()
	var auto_timer: Timer = balloon.get("auto_timer") as Timer
	if auto_timer != null:
		auto_timer.stop()
	if keep_dialogue_box_visible:
		balloon.set("will_hide_box", false)
		var mc: Timer = balloon.get("mutation_cooldown") as Timer
		if mc != null:
			mc.stop()
		var dbox: Control = balloon.get("dialogue_box") as Control
		if dbox != null:
			dbox.show()
	var base_ctrl: Control = balloon.get("balloon") as Control
	if base_ctrl != null:
		state["focus_mode"] = base_ctrl.focus_mode
		state["mouse_filter"] = base_ctrl.mouse_filter
		base_ctrl.focus_mode = Control.FOCUS_NONE
		base_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		base_ctrl.release_focus()
	return state

func _restore_balloon(state: Dictionary) -> void:
	var balloon: Node = state.get("balloon")
	if balloon == null or not is_instance_valid(balloon):
		return
	balloon.set("will_block_other_input", bool(state.get("will_block", true)))
	var base_ctrl: Control = balloon.get("balloon") as Control
	if base_ctrl != null:
		base_ctrl.focus_mode = int(state.get("focus_mode", Control.FOCUS_ALL)) as Control.FocusMode
		base_ctrl.mouse_filter = int(state.get("mouse_filter", Control.MOUSE_FILTER_STOP)) as Control.MouseFilter

func score() -> int:
	return int(last_result.get("score", 0))

func rank() -> String:
	return String(last_result.get("rank", "unplayed"))
