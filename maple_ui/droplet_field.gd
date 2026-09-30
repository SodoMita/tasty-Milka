@tool
class_name MapleDropletField
extends Control
## Drifting milk droplets behind the title. Purely drawn: no textures, no
## particles, so it costs nothing and follows the shared palette exactly.

@export var style: MapleMilkStyle = preload("res://maple_ui/milk_style.tres")
@export var count: int = 16

var _drops: Array = []
var _t: float = 0.0


func _ready() -> void:
	set_process(true)
	resized.connect(queue_redraw)
	_seed_drops()
	queue_redraw()


func _seed_drops() -> void:
	_drops.clear()
	for i in count:
		var r := RandomNumberGenerator.new()
		r.seed = 7331 + i * 97
		_drops.append({
			"x": r.randf_range(0.02, 0.98),
			"y": r.randf_range(0.0, 1.0),
			"r": r.randf_range(4.0, 13.0),
			"speed": r.randf_range(0.012, 0.038),
			"sway": r.randf_range(6.0, 22.0),
			"phase": r.randf_range(0.0, TAU),
		})


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or style == null or style.reduced_motion:
		return
	_t += delta
	queue_redraw()


func _draw() -> void:
	if style == null or _drops.is_empty():
		return
	var s := size
	if s.x <= 0.0 or s.y <= 0.0:
		return
	for d in _drops:
		var y: float = fposmod(float(d.y) - _t * float(d.speed), 1.0)
		var x: float = float(d.x) * s.x + sin(_t * 0.6 + float(d.phase)) * float(d.sway)
		var pos := Vector2(x, y * s.y)
		var r: float = float(d.r)
		var a: float = 0.16 + 0.16 * (r / 13.0)
		draw_circle(pos, r, Color(style.glass.r, style.glass.g, style.glass.b, a))
		draw_arc(pos, r, 0.0, TAU, 24, Color(style.glass_edge.r, style.glass_edge.g, style.glass_edge.b, a * 1.6), 1.4, true)
		draw_circle(pos + Vector2(-r * 0.32, -r * 0.34), r * 0.22, Color(style.highlight.r, style.highlight.g, style.highlight.b, a * 2.2))
