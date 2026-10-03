## Global story state that dialogue files can read and mutate.
## Dialogue files use `using GameState` to reference these members directly.
extends Node

const Lore = preload("res://autoloads/name_lore.gd")

@export var player_name: String = "Protagonist"
@export var chapter: int = 1
@export var story_seed: int = 1

var custom_flags: Dictionary = {}

## How the player wrote their name (see Lore.analyze).
var name_traits: Dictionary = {}

## Last rhythm minigame result (see scenes/minigame/rhythm_game.gd).
var rhythm_result: Dictionary = {}

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
	name_traits.clear()
	rhythm_result.clear()
	_reseed()

func _reseed() -> void:
	rng.seed = story_seed
	seed(story_seed)
	var manager := get_tree().root.get_node_or_null("DialogueManager")
	if manager != null and manager.has_method("reseed_randomizer"):
		manager.reseed_randomizer(story_seed)

## Store the name the player typed and analyse how it is written.
func set_player_name(new_name: String) -> void:
	var clean: String = new_name.strip_edges()
	if clean.is_empty():
		clean = "Traveler"
	player_name = clean
	name_traits = Lore.analyze(clean)

## Dialogue helper: `if GameState.name_is("has_emoji")`.
func name_is(trait_name: String) -> bool:
	return bool(name_traits.get(trait_name, false))

## Dialogue helper: how many characters of a kind the name holds.
func name_count(key: String) -> int:
	return int(name_traits.get(key, 0))

func record_rhythm_result(result: Dictionary) -> void:
	rhythm_result = result.duplicate(true)

func rhythm_score() -> int:
	return int(rhythm_result.get("score", 0))

func rhythm_rank() -> String:
	return tr(String(rhythm_result.get("rank", "unplayed")))

func rhythm_missed() -> int:
	return int(rhythm_result.get("missed", 0))

func rhythm_clicks() -> int:
	return int(rhythm_result.get("clicks", 0))

func rhythm_slides() -> int:
	return int(rhythm_result.get("slides", 0))

func rhythm_style() -> String:
	return String(rhythm_result.get("style", "none"))

func snapshot() -> Dictionary:
	var data: Dictionary = {
		"player_name": player_name,
		"chapter": chapter,
		"story_seed": story_seed,
		"custom_flags": custom_flags.duplicate(true),
		"rng_state": rng.state,
		"name_traits": name_traits.duplicate(true),
		"rhythm_result": rhythm_result.duplicate(true),
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
	if data.has("name_traits") and data["name_traits"] is Dictionary:
		name_traits = data["name_traits"].duplicate(true)
	if data.has("rhythm_result") and data["rhythm_result"] is Dictionary:
		rhythm_result = data["rhythm_result"].duplicate(true)
	if data.has("rng_state"):
		rng.state = int(data["rng_state"])
