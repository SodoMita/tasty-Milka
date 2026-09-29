extends Node2D
## Existing VN startup with a title-menu handoff; no visual nodes are built here.

@export var dialogue_resource: DialogueResource = preload("res://dialogue/milka.dialogue")
@export var start_from_cue: String = "start"

func _ready() -> void:
	var tree := get_tree()
	var action: String = str(tree.get_meta("milka_title_action", "start"))
	var slot: int = int(tree.get_meta("milka_title_slot", -1))
	if tree.has_meta("milka_title_action"):
		tree.remove_meta("milka_title_action")
	if tree.has_meta("milka_title_slot"):
		tree.remove_meta("milka_title_slot")
	var balloon: Node = Engine.get_singleton("DialogueManager").show_dialogue_balloon(dialogue_resource, start_from_cue)
	# The existing balloon starts its first line asynchronously.
	await tree.process_frame
	await tree.process_frame
	var config := ConfigFile.new()
	if config.load("user://milka_title.cfg") == OK:
		var speed_ms := float(config.get_value("player", "text_speed", 32.0))
		if balloon.get("dialogue_label") != null:
			balloon.seconds_per_step = speed_ms / 1000.0
			balloon.text_speed_slider.value = speed_ms / 1000.0
			balloon.dialogue_label.seconds_per_step = speed_ms / 1000.0
			balloon.button_sfx = bool(config.get_value("player", "sound", true))
			balloon.button_sfx_check.button_pressed = balloon.button_sfx
	if action == "continue" and slot >= 0:
		balloon.load_from_slot(slot)
	elif action == "load":
		balloon.open_save_menu("load")
