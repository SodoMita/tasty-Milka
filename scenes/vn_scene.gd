extends Node2D
## The Milka VN main scene. The player is asked for a name first, then the
## dialogue balloon takes over. Visual elements are driven by the balloon.

const NAME_ENTRY_SCENE: PackedScene = preload("res://scenes/ui/name_entry.tscn")

@export var dialogue_resource: DialogueResource = preload("res://dialogue/milka.dialogue")
@export var start_from_cue: String = "start"

## Skip the prompt when a save is being resumed (the name is already known).
@export var ask_for_name: bool = true

func _ready() -> void:
	var game_state: Node = get_tree().root.get_node_or_null("GameState")
	var resuming: bool = game_state != null and int(game_state.get("pending_resume_slot")) >= 0
	if ask_for_name and not resuming:
		var prompt: CanvasLayer = NAME_ENTRY_SCENE.instantiate()
		add_child(prompt)
		var chosen: String = await prompt.name_confirmed
		if game_state != null and game_state.has_method("set_player_name"):
			game_state.set_player_name(chosen)
	Engine.get_singleton("DialogueManager").show_dialogue_balloon(dialogue_resource, start_from_cue)
