@tool
class_name MapleActor
extends Control
## A stand-in animated actor. Low effort on purpose: the human will replace the
## art, so this only proves the stage — a breathing bob, a blink-scale and
## expression swaps — in front of the milk-glass UI.

@export var neutral: Texture2D
@export var happy: Texture2D
@export var surprised: Texture2D
## Shared palette, used for the soft shadow puddle under the actor.
@export var style: MapleMilkStyle = preload("res://maple_ui/milk_style.tres")

@export var bob_amount: float = 9.0
@export var bob_speed: float = 1.15
@export var blink_every: float = 3.4

var _expr: int = 0
var _t: float = 0.0
var _blink_t: float = 0.0
var _squash: float = 1.0


func _ready() -> void:
	set_process(true)
	resized.connect(queue_redraw)
	_blink_t = blink_every * 0.6
	queue_redraw()


func set_expression(index: int) -> void:
	_expr = clampi(index, 0, 2)
	if style != null and not style.reduced_motion:
		var tween := create_tween()
		tween.tween_property(self, "_squash", 0.94, 0.07).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(self, "_squash", 1.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	queue_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or style == null:
		return
	if style.reduced_motion:
		return
	_t += delta
	_blink_t -= delta
	if _blink_t <= 0.0:
		_blink_t = blink_every
		_squash = 0.9
		var tween := create_tween()
		tween.tween_property(self, "_squash", 1.0, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	queue_redraw()


func _current() -> Texture2D:
	match _expr:
		1:
			return happy if happy != null else neutral
		2:
			return surprised if surprised != null else neutral
	return neutral


func _draw() -> void:
	var tex := _current()
	if tex == null:
		return
	var bob := 0.0
	if style != null and not style.reduced_motion:
		bob = sin(_t * bob_speed * TAU * 0.32) * bob_amount
	var src := tex.get_size()
	var h: float = size.y * 0.86 * _squash
	var w: float = h * (src.x / maxf(src.y, 1.0))
	var rect := Rect2(Vector2((size.x - w) * 0.5, size.y - h + bob), Vector2(w, h))

	if style != null:
		var puddle := Color(style.glass_shadow.r, style.glass_shadow.g, style.glass_shadow.b, style.glass_shadow.a * 0.7)
		draw_circle(Vector2(size.x * 0.5, size.y - 8.0), w * 0.22, puddle)
	draw_texture_rect(tex, rect, false)
