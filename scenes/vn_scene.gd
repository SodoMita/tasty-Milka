extends Node2D
## The Milka VN main scene. Visual elements and dialogue UI are driven by the balloon.

@export var dialogue_resource: DialogueResource = preload("res://dialogue/metro-meet.dialogue")
@export var start_from_cue: String = "start"

func _ready() -> void:
	Engine.get_singleton("DialogueManager").show_dialogue_balloon(dialogue_resource, start_from_cue)
