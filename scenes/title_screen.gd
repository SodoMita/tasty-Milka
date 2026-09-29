extends Control
## Milka VN - title screen behaviour.
## Every visual element is authored in title_screen.tscn.
## This script only wires input: buttons, SFX and small reactions.

@onready var start_button: Button = %StartButton
@onready var continue_button: Button = %ContinueButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var spirit: Node2D = %Spirit
@onready var ambient: AnimationPlayer = $Ambient


func _ready() -> void:
	ambient.play("ambient")
	start_button.pressed.connect(_on_start_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	start_button.mouse_entered.connect(_on_start_hover)
	start_button.mouse_exited.connect(_on_start_unhover)
	_play_sfx("open")


func _on_start_hover() -> void:
	spirit.set_expression("happy")


func _on_start_unhover() -> void:
	spirit.set_expression("neutral")


func _on_start_pressed() -> void:
	_play_sfx("confirm")
	spirit.greet()
	await get_tree().create_timer(0.55).timeout
	get_tree().change_scene_to_file("res://scenes/vn_scene.tscn")


func _on_continue_pressed() -> void:
	_play_sfx("open")
	get_tree().change_scene_to_file("res://scenes/vn_scene.tscn")


func _on_settings_pressed() -> void:
	_play_sfx("click")


func _on_quit_pressed() -> void:
	_play_sfx("close")
	get_tree().quit()


func _play_sfx(sfx_name: String) -> void:
	var ad = get_node_or_null("/root/AudioDirector")
	if ad and ad.has_method("play_sfx"):
		ad.play_sfx(sfx_name)
