@tool
class_name MapleIconButton
extends Button
## An icon-only button on a chip of milk glass. No text ever appears on the face
## of the button — the glyph is an SVG and the meaning lives in `tooltip_text`,
## so the same button reads correctly in every language.
##
## Used by both the dialogue bubble's rail and the title menu; both pass the
## same MapleMilkStyle so the chips match the glass they sit next to.

signal action(id: StringName)

## Shared milk-glass settings.
@export var style: MapleMilkStyle: set = _set_style
## The SVG glyph. Tinted with `ink` at rest, warmed to caramel on hover.
@export var icon_tex: Texture2D: set = _set_icon
## Which action this button reports when pressed.
@export var action_id: StringName = &"none"
## Chip shape: round chip or a wider pill.
@export_enum("Chip", "Pill") var shape: int = 0
## Scales the chip; 1.0 is style.chip_size.
@export_range(0.6, 2.0) var scale_hint: float = 1.0

var _hover_t: float = 0.0
var _press_t: float = 0.0


func _set_style(value: MapleMilkStyle) -> void:
	style = value
	queue_redraw()
	update_minimum_size()


func _set_icon(value: Texture2D) -> void:
	icon_tex = value
	queue_redraw()


func _init() -> void:
	text = ""
	flat = true
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))
	button_down.connect(_on_down)
	button_up.connect(_on_up)
	resized.connect(queue_redraw)


func _on_down() -> void:
	_press_t = 1.0
	queue_redraw()


func _on_up() -> void:
	_press_t = 0.0
	queue_redraw()


func _ready() -> void:
	if style == null:
		push_warning("MapleIconButton '%s' has no MapleMilkStyle." % name)
	update_minimum_size()
	queue_redraw()


func _get_minimum_size() -> Vector2:
	var chip := 52.0 if style == null else style.chip_size
	if shape == 1:
		return Vector2(chip * 1.7, chip) * scale_hint
	return Vector2(chip, chip) * scale_hint


func _on_hover(entered: bool) -> void:
	if style == null or style.reduced_motion:
		_hover_t = 1.0 if entered else 0.0
		queue_redraw()
		return
	var tween := create_tween()
	tween.tween_property(self, "_hover_t", 1.0 if entered else 0.0, style.hover_time) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(queue_redraw)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAW:
		_draw_chip()


func _draw_chip() -> void:
	if style == null:
		return
	var rect := Rect2(Vector2.ZERO, size)
	var state: StringName = &"normal"
	if is_disabled():
		state = &"disabled"
	elif is_pressed() or _press_t > 0.5:
		state = &"pressed"
	elif is_hovered() or _hover_t > 0.5:
		state = &"hover"

	# A gentle squash while pressed, a breath while hovered.
	var squash := 1.0 - 0.05 * _press_t + 0.03 * _hover_t
	var extra := rect.size.x * (squash - 1.0) * -0.5
	var grown := rect.grow_individual(extra, extra * 0.9, extra, extra * 0.9)
	draw_style_box(style.chip_box(state), grown)

	if icon_tex != null:
		var glyph := style.icon_size * scale_hint * (1.0 + 0.05 * _hover_t)
		var dst := Rect2((size - Vector2(glyph, glyph)) * 0.5, Vector2(glyph, glyph))
		var tint := style.ink
		if state == &"hover":
			tint = style.caramel.lerp(style.ink, 0.45)
		elif state == &"disabled":
			tint = style.quiet
		draw_texture_rect(icon_tex, dst, false, tint)

	if has_focus():
		var ring := style.chip_box(&"hover")
		ring.bg_color = Color(0, 0, 0, 0)
		ring.border_color = style.butter
		ring.set_border_width_all(3)
		ring.shadow_size = 0
		draw_style_box(ring, rect.grow(4.0))
