extends Control
## All visuals and help text are authored in title_screen.tscn, never built here.

const LABEL_KEYS := {
	"Subtitle": "a milk-soft visual novel",
	"Version": "v0.1.0 · milk-glass UI · placeholder art",
	"HowToPlayTitle": "How to play",
	"HowToPlay": "Enter / Space / tap · Advance\nH / swipe up · History    Esc · Pause\nF5 · Quick save    F9 · Quick load    F12 · Field notes",
}

@onready var start_button: Button = %StartButton
@onready var continue_button: Button = %ContinueButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var crema: Node2D = %Crema
@onready var ambient: AnimationPlayer = $Ambient
@onready var settings_panel: Control = $SettingsPanel
var _leaving := false


func _ready() -> void:
	ambient.play("ambient")
	_apply_settings()
	_translate_labels()
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	var reactions := {start_button: "happy", continue_button: "surprised", settings_button: "thinking", quit_button: "sad"}
	for button: Button in reactions:
		button.mouse_entered.connect(_react.bind(str(reactions[button])))
		button.focus_entered.connect(_react.bind(str(reactions[button])))
		button.mouse_exited.connect(_reset_expression)
		button.focus_exited.connect(_reset_expression)
	settings_panel.closed.connect(_reset_expression)
	_play_sfx("open")


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_translate_labels()


func _apply_settings() -> void:
	var store := get_node_or_null("/root/SettingsStore")
	if store != null and store.has_method("apply_globals"):
		store.apply_globals()


func _translate_labels() -> void:
	# Always use the English source keys, so EN -> RU -> EN is reversible.
	for node_name: String in LABEL_KEYS:
		var label := get_node("%" + node_name) as Label
		label.text = tr(str(LABEL_KEYS[node_name]))


func _react(expression: String) -> void:
	if not _leaving and not settings_panel.visible:
		crema.set_expression(expression)
		_play_sfx("click")


func _reset_expression() -> void:
	if not _leaving:
		crema.set_expression("thinking" if settings_panel.visible else "neutral")


func _on_start_pressed() -> void:
	if _leaving:
		return
	_leaving = true
	_play_sfx("confirm")
	crema.set_expression("happy")
	crema.greet()
	await get_tree().create_timer(0.55).timeout
	get_tree().change_scene_to_file("res://scenes/vn_scene.tscn")


func _on_continue_pressed() -> void:
	if _leaving:
		return
	_leaving = true
	_play_sfx("open")
	var game_state := get_node_or_null("/root/GameState")
	var slot := _latest_save_slot()
	if game_state != null and slot >= 0:
		game_state.pending_resume_slot = slot
	get_tree().change_scene_to_file("res://scenes/vn_scene.tscn")


func _on_settings_pressed() -> void:
	if _leaving:
		return
	_play_sfx("open")
	settings_panel.open()
	crema.set_expression("thinking")


func _on_quit_pressed() -> void:
	if _leaving:
		return
	_leaving = true
	_play_sfx("close")
	crema.set_expression("sad")
	await get_tree().create_timer(0.35).timeout
	get_tree().quit()


func _play_sfx(sfx_name: String) -> void:
	var ad = get_node_or_null("/root/AudioDirector")
	if ad and ad.has_method("play_sfx"):
		ad.play_sfx(sfx_name)


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
