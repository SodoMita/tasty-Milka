extends Node
## Runs minigames from dialogue: `do Minigame.play_rhythm()` pauses the story,
## shows the rhythm scene and resumes when the player is done. The result is
## written back to GameState so later lines can talk about it.

const RHYTHM_SCENE: PackedScene = preload("res://scenes/minigame/rhythm_game.tscn")

signal minigame_finished(result: Dictionary)

var last_result: Dictionary = {}
var is_playing: bool = false

## Awaited mutation. `notes` sets the chart length.
func play_rhythm(notes: int = 18) -> void:
	if is_playing:
		return
	is_playing = true
	var game: Node = RHYTHM_SCENE.instantiate()
	game.set("note_count", notes)
	get_tree().root.add_child(game)
	var result: Dictionary = await game.finished
	is_playing = false
	last_result = result
	var game_state: Node = get_tree().root.get_node_or_null("GameState")
	if game_state != null and game_state.has_method("record_rhythm_result"):
		game_state.record_rhythm_result(result)
	minigame_finished.emit(result)

func score() -> int:
	return int(last_result.get("score", 0))

func rank() -> String:
	return String(last_result.get("rank", "unplayed"))
