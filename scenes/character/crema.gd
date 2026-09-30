extends Node2D
## Crema - the animated 2D milk-droplet character.
## Idle breathing + random blinking + switchable expressions.
## The scene structure lives in crema.tscn; this script only animates it.

const TEXTURES := {
	"neutral": preload("res://assets/characters/crema/neutral.svg"),
	"happy": preload("res://assets/characters/crema/happy.svg"),
	"surprised": preload("res://assets/characters/crema/surprised.svg"),
	"blink": preload("res://assets/characters/crema/blink.svg"),
	"thinking": preload("res://assets/characters/crema/thinking.svg"),
	"sad": preload("res://assets/characters/crema/sad.svg"),
}

@export var blink_interval_min: float = 2.2
@export var blink_interval_max: float = 5.5

@onready var sprite: Sprite2D = $Sprite
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var blink_timer: Timer = $BlinkTimer
@onready var blink_end_timer: Timer = $BlinkEndTimer

var _expression: String = "neutral"


func _ready() -> void:
	anim.animation_finished.connect(_on_animation_finished)
	blink_timer.timeout.connect(_on_blink_timer_timeout)
	blink_end_timer.timeout.connect(_on_blink_end_timer_timeout)
	anim.play("idle")
	_schedule_blink()


func set_expression(expression_name: String) -> void:
	if not TEXTURES.has(expression_name):
		return
	_expression = expression_name
	sprite.texture = TEXTURES[expression_name]


func get_expression() -> String:
	return _expression


func greet() -> void:
	if anim.current_animation != "greet":
		anim.play("greet")


func _schedule_blink() -> void:
	blink_timer.wait_time = randf_range(blink_interval_min, blink_interval_max)
	blink_timer.start()


func _on_blink_timer_timeout() -> void:
	if _expression == "neutral":
		sprite.texture = TEXTURES["blink"]
		blink_end_timer.start()
	else:
		_schedule_blink()


func _on_blink_end_timer_timeout() -> void:
	if _expression == "neutral":
		sprite.texture = TEXTURES["neutral"]
	_schedule_blink()


func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "greet":
		anim.play("idle")
