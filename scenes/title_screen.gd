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
@onready var player_name_label: Label = %PlayerNameLabel
@onready var player_name_input: LineEdit = %PlayerNameInput


func _ready() -> void:
	_apply_milk_glass()
	ambient.play("ambient")
	_apply_settings()
	_restore_player_name()
	_translate_labels()
	player_name_input.text_submitted.connect(_on_player_name_submitted)
	player_name_input.focus_exited.connect(_persist_player_name)
	player_name_input.call_deferred("grab_focus")
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
	var settings_store := get_node_or_null("/root/SettingsStore")
	if settings_store != null and settings_store.has_signal("settings_changed"):
		settings_store.settings_changed.connect(_on_shared_setting_changed)
	_play_sfx("open")


## Boot-time settings (language, display, volumes) apply on the title too.
func _apply_settings() -> void:
	var store := get_node_or_null("/root/SettingsStore")
	if store != null and store.has_method("apply_globals"):
		store.apply_globals()


## The title screen carries no scene builder: everything is authored in
## title_screen.tscn. It only borrows the shared milk-glass settings
## (assets/ui/milk_ui_settings.tres) that the dialogue bubble uses too.
func _apply_milk_glass() -> void:
	theme = MilkGlass.settings().build_theme()
	MilkGlass.dress_all(self, MilkGlass.TITLE_MENU)
	# The entry point is the one chip in butter, so the eye lands on it.
	MilkGlass.settings()
	start_button.add_theme_stylebox_override(&"normal", MilkGlass.settings().chip_style(&"pressed"))


func _translate_labels() -> void:
	subtitle.text = tr(subtitle.text)
	version.text = tr(version.text)
	player_name_label.text = tr("Your name")
	player_name_input.placeholder_text = tr("Type your name here")
	for button: Button in [start_button, continue_button, settings_button, quit_button]:
		if button.tooltip_text.is_empty():
			continue
		button.tooltip_text = tr(button.tooltip_text)


func _on_start_pressed() -> void:
	_persist_player_name()
	player_name_input.release_focus()
	start_button.disabled = true
	_play_sfx("confirm")
	crema.greet()
	await get_tree().create_timer(0.55).timeout
	get_tree().change_scene_to_file("res://scenes/vn_scene.tscn")


func _on_player_name_submitted(_submitted_text: String) -> void:
	_on_start_pressed()


func _restore_player_name() -> void:
	var game_state := get_node_or_null("/root/GameState")
	var fallback := "Protagonist"
	if game_state != null and not str(game_state.player_name).strip_edges().is_empty():
		fallback = str(game_state.player_name)
	var settings_store := get_node_or_null("/root/SettingsStore")
	var saved_name := fallback
	if settings_store != null and settings_store.has_method("get_value"):
		saved_name = str(settings_store.get_value("player_name", fallback))
	if saved_name.strip_edges().is_empty():
		saved_name = fallback
	player_name_input.text = saved_name


func _persist_player_name() -> void:
	var entered_name := player_name_input.text.strip_edges()
	if entered_name.is_empty():
		entered_name = "Protagonist"
		player_name_input.text = entered_name
	var game_state := get_node_or_null("/root/GameState")
	if game_state != null:
		game_state.player_name = entered_name
	var settings_store := get_node_or_null("/root/SettingsStore")
	if settings_store != null and settings_store.has_method("set_value"):
		settings_store.set_value("player_name", entered_name)


func _on_shared_setting_changed(key: String, _value: Variant) -> void:
	if key == "language":
		_translate_labels()


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
