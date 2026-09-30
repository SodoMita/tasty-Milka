@tool
class_name MapleGlassPanel
extends Control
## A pane of milk glass. Drawn, not textured: rounded translucent fill, a cream
## rim, a meniscus highlight along the top edge and an optional droplet tail
## pointing at whoever is speaking.
##
## Any Control can wear it — the dialogue bubble and the title lockup both use
## this node and both read the same MapleMilkStyle, so they are the same glass.

## What the glass is made of. Shared with every other milk surface.
@export var style: MapleMilkStyle: set = _set_style
## Draw the droplet tail that points at the speaker.
@export var show_tail: bool = false
## Which edge the tail hangs off.
@export_enum("Bottom Left", "Bottom Center", "Top Left")
var tail_anchor: int = 0
## Multiplier on the glass alpha — lets a surface be milkier or clearer.
@export_range(0.2, 1.5) var alpha_scale: float = 1.0
## Draw the thin meniscus highlight along the top edge.
@export var meniscus: bool = true
## Corner radius override; -1 follows style.glass_radius.
@export var radius_override: int = -1


func _set_style(value: MapleMilkStyle) -> void:
	if style != null and style.changed.is_connected(queue_redraw):
		style.changed.disconnect(queue_redraw)
	style = value
	if style != null and not style.changed.is_connected(queue_redraw):
		style.changed.connect(queue_redraw)
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	if style == null:
		push_warning("MapleGlassPanel has no MapleMilkStyle assigned.")
	queue_redraw()


func _draw() -> void:
	if style == null:
		return
	var rect := Rect2(Vector2.ZERO, size)
	if style.scrim > 0.0:
		var scrim := StyleBoxFlat.new()
		scrim.bg_color = Color(1, 1, 1, style.scrim * alpha_scale)
		scrim.set_corner_radius_all(style.glass_radius)
		scrim.anti_aliasing = true
		draw_style_box(scrim, rect)

	draw_style_box(style.glass_box(alpha_scale, radius_override), rect)

	if meniscus:
		var inset := float(style.rim_width) + 2.0
		var y := inset + 1.0
		var a := style.highlight.a * alpha_scale
		draw_line(
			Vector2(inset + style.glass_radius * 0.5, y),
			Vector2(size.x - inset - style.glass_radius * 0.5, y),
			Color(style.highlight.r, style.highlight.g, style.highlight.b, a),
			2.0,
			true
		)

	if show_tail:
		_draw_tail()


## A soft teardrop: wide at the glass, rounded at the tip.
func _draw_tail() -> void:
	var w := style.tail_width
	var l := style.tail_length
	var base_y := size.y - float(style.rim_width)
	var tip := Vector2(float(style.glass_radius) * 1.15, base_y + l)
	if tail_anchor == 1:
		tip = Vector2(size.x * 0.5, base_y + l)
	elif tail_anchor == 2:
		base_y = float(style.rim_width)
		tip = Vector2(float(style.glass_radius) * 1.15, base_y - l)
	var points := PackedVector2Array([
		Vector2(tip.x - w * 0.5, base_y),
		Vector2(tip.x + w * 0.5, base_y),
		tip,
	])
	var fill := style.glass
	fill.a = minf(1.0, fill.a * alpha_scale * 1.25)
	draw_colored_polygon(points, fill)
	# Round the tip so it reads as a drop, not a spike.
	draw_circle(tip, w * 0.3, fill)
	# Cream rim continuing around the drop.
	var rim := float(style.rim_width) + 1.0
	draw_line(points[0], points[2], style.glass_edge, rim, true)
	draw_line(points[1], points[2], style.glass_edge, rim, true)
	draw_arc(tip, w * 0.3, 0.15 * PI, 0.85 * PI, 18, style.glass_edge, rim, true)
