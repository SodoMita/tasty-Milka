extends Node2D
## Milk Spirit - the animated 2D droplet character.
## Idle breathing + random blinking + switchable expressions.
## The scene structure lives in milk_spirit.tscn; this script only animates it.

const TEXTURES := {
	"neutral": preload("res://assets/characters/milk_spirit/neutral.svg"),
	"happy": preload("res://assets/characters/milk_spirit/happy.svg"),
	"surprised": preload("res://assets/characters/milk_spirit/surprised.svg"),
	"blink": preload("res://assets/characters/milk_spirit/blink.svg"),
}

@export var blink_interval_min: float = 2.2
@export var blink_interval_max: float = 5.5

@onready var sprite: Sprite2D = $Sprite
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var blink_timer: Timer = $BlinkTimer

var _expression: String = "neutral"


func _ready() -> void:
	anim.animation_finished.connect(_on_animation_finished)
	blink_timer.timeout.connect(_on_blink_timer_timeout)
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
		await get_tree().create_timer(0.13).timeout
		if _expression == "neutral":
			sprite.texture = TEXTURES["neutral"]
	_schedule_blink()


func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "greet":
		anim.play("idle")
