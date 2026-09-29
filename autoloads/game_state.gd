## Global story state that dialogue files can read and mutate.
## Dialogue files use `using GameState` to reference these members directly.
extends Node

@export var player_name: String = "Protagonist"
@export var chapter: int = 1
@export var story_seed: int = 1

var custom_flags: Dictionary = {}

## Save slot the title screen asked to resume (-1 = none). The VN balloon
## consumes it when it starts.
var pending_resume_slot: int = -1
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	_reseed()
	call_deferred("_reseed")

func reset() -> void:
	player_name = "Protagonist"
	chapter = 1
	custom_flags.clear()
	_reseed()

func _reseed() -> void:
	rng.seed = story_seed
	seed(story_seed)
	var manager := get_tree().root.get_node_or_null("DialogueManager")
	if manager != null and manager.has_method("reseed_randomizer"):
		manager.reseed_randomizer(story_seed)

func snapshot() -> Dictionary:
	var data: Dictionary = {
		"player_name": player_name,
		"chapter": chapter,
		"story_seed": story_seed,
		"custom_flags": custom_flags.duplicate(true),
		"rng_state": rng.state,
	}
	return data

func restore(data: Dictionary) -> void:
	if data.has("player_name"):
		player_name = String(data["player_name"])
	if data.has("chapter"):
		chapter = int(data["chapter"])
	if data.has("story_seed"):
		story_seed = int(data["story_seed"])
	if data.has("custom_flags") and data["custom_flags"] is Dictionary:
		custom_flags = data["custom_flags"].duplicate(true)
	if data.has("rng_state"):
		rng.state = int(data["rng_state"])
