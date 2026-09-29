extends Control
## Milka VN - title screen behaviour.
## Every visual element is authored in title_screen.tscn.
## This script wires input: menu buttons, settings, saves and reactions.

@onready var start_button: Button = %StartButton
@onready var continue_button: Button = %ContinueButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var crema: Node2D = %Crema
@onready var ambient: AnimationPlayer = $Ambient
@onready var settings_panel: Control = $SettingsPanel
@onready var subtitle: Label = %Subtitle
@onready var version: Label = %Version


func _ready() -> void:
	ambient.play("ambient")
	_apply_settings()
	_translate_labels()
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	for button: Button in [start_button, continue_button, settings_button, quit_button]:
		button.mouse_entered.connect(func() -> void: _play_sfx("click"))
	start_button.mouse_entered.connect(func() -> void: crema.set_expression("happy"))
	start_button.mouse_exited.connect(func() -> void: crema.set_expression("neutral"))
	continue_button.mouse_entered.connect(func() -> void: crema.set_expression("surprised"))
	continue_button.mouse_exited.connect(func() -> void: crema.set_expression("neutral"))
	settings_panel.closed.connect(func() -> void: crema.set_expression("neutral"))
	_play_sfx("open")


## Boot-time settings (language, display, volumes) apply on the title too.
func _apply_settings() -> void:
	var store := get_node_or_null("/root/SettingsStore")
	if store != null and store.has_method("apply_globals"):
		store.apply_globals()


func _translate_labels() -> void:
	subtitle.text = tr(subtitle.text)
	version.text = tr(version.text)
	start_button.text = tr(start_button.text)
	continue_button.text = tr(continue_button.text)
	settings_button.text = tr(settings_button.text)
	quit_button.text = tr(quit_button.text)


func _on_start_pressed() -> void:
	_play_sfx("confirm")
	crema.greet()
	await get_tree().create_timer(0.55).timeout
	get_tree().change_scene_to_file("res://scenes/vn_scene.tscn")


## Continue: resume the newest save slot, or start fresh when none exist.
func _on_continue_pressed() -> void:
	_play_sfx("open")
	var game_state := get_node_or_null("/root/GameState")
	var slot := _latest_save_slot()
	if game_state != null and slot >= 0:
		game_state.pending_resume_slot = slot
	get_tree().change_scene_to_file("res://scenes/vn_scene.tscn")


func _on_settings_pressed() -> void:
	_play_sfx("open")
	crema.set_expression("surprised")
	settings_panel.open()


func _on_quit_pressed() -> void:
	_play_sfx("close")
	get_tree().quit()


func _play_sfx(sfx_name: String) -> void:
	var ad = get_node_or_null("/root/AudioDirector")
	if ad and ad.has_method("play_sfx"):
		ad.play_sfx(sfx_name)


## Newest save slot (by the "when" timestamp), or -1 when there are none.
func _latest_save_slot() -> int:
	var dir := DirAccess.open("user://saves")
	if dir == null:
		return -1
	var best := -1
	var best_when := ""
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.begins_with("slot_") and file_name.ends_with(".json"):
			var slot := int(file_name.trim_prefix("slot_").trim_suffix(".json"))
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("user://saves/%s" % file_name))
			var when := ""
			if parsed is Dictionary and parsed.get("meta", {}) is Dictionary:
				when = str(parsed.meta.get("when", ""))
			if when > best_when:
				best_when = when
				best = slot
		file_name = dir.get_next()
	dir.list_dir_end()
	return best
