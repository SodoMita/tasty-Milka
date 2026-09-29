extends Control
## Interaction only: all visuals and animations are authored in .tscn/.tres.

@onready var start_button: Button = %StartButton
@onready var continue_button: Button = %ContinueButton
@onready var overlay: Control = %Overlay
@onready var settings_panel: PanelContainer = %SettingsPanel
@onready var about_panel: PanelContainer = %AboutPanel
@onready var empty_load_panel: PanelContainer = %EmptyLoadPanel
@onready var sound_check: CheckButton = %SoundCheck
@onready var motion_check: CheckButton = %MotionCheck
@onready var volume_slider: HSlider = %VolumeSlider
@onready var speed_slider: HSlider = %SpeedSlider

var _config := ConfigFile.new()
var _loading := true
var _latest_slot := -1

func _ready() -> void:
	start_button.pressed.connect(_start_story)
	continue_button.pressed.connect(_continue_story)
	%LoadButton.pressed.connect(_load_story)
	%SettingsButton.pressed.connect(_show_panel.bind(settings_panel))
	%AboutButton.pressed.connect(_show_panel.bind(about_panel))
	%QuitButton.pressed.connect(_quit)
	%SettingsClose.pressed.connect(_close_overlay)
	%AboutClose.pressed.connect(_close_overlay)
	%EmptyClose.pressed.connect(_close_overlay)
	%EmptyStart.pressed.connect(_start_story)
	_config.load("user://milka_title.cfg")
	sound_check.button_pressed = bool(_config.get_value("player", "sound", true))
	motion_check.button_pressed = bool(_config.get_value("player", "reduced_motion", false))
	volume_slider.value = float(_config.get_value("player", "volume", 65.0))
	speed_slider.value = float(_config.get_value("player", "text_speed", 32.0))
	sound_check.toggled.connect(_on_preferences_changed)
	motion_check.toggled.connect(_on_preferences_changed)
	volume_slider.value_changed.connect(_on_preferences_changed)
	speed_slider.value_changed.connect(_on_preferences_changed)
	_loading = false
	_apply_preferences()
	_latest_slot = _find_latest_slot()
	continue_button.disabled = _latest_slot < 0
	continue_button.tooltip_text = "No saved story yet" if _latest_slot < 0 else "Resume your most recent save"
	# Focus remains keyboard-accessible without painting a ring on mouse launch.
	start_button.grab_focus()

func _sfx(key: String) -> void:
	if sound_check.button_pressed:
		var audio := get_node_or_null("/root/AudioDirector")
		if audio != null and audio.has_method("play_sfx"):
			audio.play_sfx(key)

func _start_story() -> void:
	_sfx("confirm")
	get_tree().set_meta("milka_title_action", "start")
	get_tree().change_scene_to_file("res://scenes/vn_scene.tscn")

func _continue_story() -> void:
	if _latest_slot < 0:
		return
	_sfx("confirm")
	get_tree().set_meta("milka_title_action", "continue")
	get_tree().set_meta("milka_title_slot", _latest_slot)
	get_tree().change_scene_to_file("res://scenes/vn_scene.tscn")

func _load_story() -> void:
	if _latest_slot < 0:
		_show_panel(empty_load_panel)
		return
	_sfx("open")
	get_tree().set_meta("milka_title_action", "load")
	get_tree().change_scene_to_file("res://scenes/vn_scene.tscn")

func _show_panel(panel: PanelContainer) -> void:
	settings_panel.hide()
	about_panel.hide()
	empty_load_panel.hide()
	panel.show()
	overlay.show()
	_sfx("open")
	if panel == settings_panel:
		%SettingsClose.grab_focus()
	elif panel == about_panel:
		%AboutClose.grab_focus()
	else:
		%EmptyStart.grab_focus()

func _close_overlay() -> void:
	overlay.hide()
	_sfx("close")
	start_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and overlay.visible:
		_close_overlay()
		get_viewport().set_input_as_handled()

func _on_preferences_changed(_value: Variant) -> void:
	if _loading:
		return
	_config.set_value("player", "sound", sound_check.button_pressed)
	_config.set_value("player", "reduced_motion", motion_check.button_pressed)
	_config.set_value("player", "volume", volume_slider.value)
	_config.set_value("player", "text_speed", speed_slider.value)
	_config.save("user://milka_title.cfg")
	_apply_preferences()

func _apply_preferences() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume_slider.value / 100.0, 0.0001)))
	%VolumeValue.text = "%d%%" % int(volume_slider.value)
	%SpeedValue.text = "%d ms / character" % int(speed_slider.value)
	var players: Array[AnimationPlayer] = [$TitleCharacter/AnimationPlayer, $FloatingAnimation]
	for player in players:
		if motion_check.button_pressed:
			player.stop()
			player.play("RESET")
			player.advance(0)
			player.pause()
		else:
			player.play("idle" if player == $TitleCharacter/AnimationPlayer else "float")

func _find_latest_slot() -> int:
	var dir := DirAccess.open("user://saves")
	if dir == null:
		return -1
	var newest := ""
	var latest := -1
	for filename: String in dir.get_files():
		if not filename.begins_with("slot_") or not filename.ends_with(".json"):
			continue
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("user://saves/" + filename))
		if data is not Dictionary or not data.get("history", []) is Array or data.get("history", []).is_empty():
			continue
		var number := filename.trim_prefix("slot_").trim_suffix(".json")
		if not number.is_valid_int() or data.get("meta", {}) is not Dictionary:
			continue
		var when: String = str(data.get("meta", {}).get("when", ""))
		if latest < 0 or when > newest:
			newest = when
			latest = number.to_int()
	return latest

func _quit() -> void:
	get_tree().quit()
