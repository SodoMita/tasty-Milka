extends Control
## Milka VN Title Screen - milk-themed main menu

@onready var start_button: Button = %StartButton
@onready var load_button: Button = %LoadButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	load_button.pressed.connect(_on_load_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	var ad = get_node_or_null("/root/AudioDirector")
	if ad and ad.has_method("play_sfx"):
		ad.play_sfx("open")

func _on_start_pressed() -> void:
	var ad = get_node_or_null("/root/AudioDirector")
	if ad and ad.has_method("play_sfx"):
		ad.play_sfx("confirm")
	get_tree().change_scene_to_file("res://scenes/vn_scene.tscn")

func _on_load_pressed() -> void:
	var ad = get_node_or_null("/root/AudioDirector")
	if ad and ad.has_method("play_sfx"):
		ad.play_sfx("open")
	get_tree().change_scene_to_file("res://scenes/vn_scene.tscn")

func _on_settings_pressed() -> void:
	var ad = get_node_or_null("/root/AudioDirector")
	if ad and ad.has_method("play_sfx"):
		ad.play_sfx("click")

func _on_quit_pressed() -> void:
	var ad = get_node_or_null("/root/AudioDirector")
	if ad and ad.has_method("play_sfx"):
		ad.play_sfx("close")
	get_tree().quit()
