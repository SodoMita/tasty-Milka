@tool
class_name MapleDialogueBubble
extends Control
## The transparent milk-glass dialogue bubble.
##
## It contains no colour, no size and no timing of its own: everything comes
## from `style` (maple_ui/milk_style.tres), the same resource the title screen
## uses. Change the .tres and the bubble and the title move together.
##
## Buttons in the rail are icon-only; their meaning travels in `tooltip_text`,
## never as a caption on the button face.

## Emitted for every icon in the rail, and for a click anywhere on the bubble.
signal action_requested(id: StringName)
## Emitted when a finished line is advanced past.
signal line_finished

## Shared milk-glass settings. Defaults to the project's milk_style.tres.
@export var style: MapleMilkStyle = preload("res://maple_ui/milk_style.tres")

var _speaker: String = ""
var _full: String = ""
var _typed: float = 0.0

@onready var glass: Control = $Glass
@onready var body: Label = $Glass/Body
@onready var name_plate: Control = $NamePlate
@onready var name_label: Label = $NamePlate/Name
@onready var rail: Control = $Rail


func _ready() -> void:
	set_process(true)
	resized.connect(_layout)
	get_viewport().size_changed.connect(_layout)
	for child in rail.get_children():
		if child is MapleIconButton:
			child.action.connect(_on_button)
	# Type scale comes from the shared settings, not from the scene.
	body.add_theme_font_size_override("font_size", style.body_size)
	name_label.add_theme_font_size_override("font_size", style.name_size)
	# Start empty; the demo or the game driver calls show_line().
	body.text = ""
	name_label.text = ""
	_layout()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or style == null:
		return
	if _is_typing():
		_typed += style.type_cps * delta
		body.visible_characters = int(_typed)
		if not _is_typing():
			body.visible_characters = -1
			action_requested.emit(&"line_revealed")


func _is_typing() -> bool:
	return body != null and _full.length() > 0 and _typed < float(_full.length())


## Show one dialogue line. Speaker may be empty for narration.
func show_line(speaker: String, text: String) -> void:
	_speaker = speaker.strip_edges()
	_full = text
	_typed = 0.0
	name_label.text = _speaker.to_upper()
	name_plate.visible = _speaker != ""
	body.text = _full
	body.visible_characters = 0 if _full != "" else -1
	_layout()
	_swell()
	set_process(true)


## Skip the typewriter, or move on when the line is already complete.
## Returns true when the caller should hand over the next line.
func advance() -> bool:
	if _is_typing():
		_typed = float(_full.length())
		body.visible_characters = -1
		return false
	line_finished.emit()
	return true


## Extra icons the game wants to add to the rail at runtime.
func add_rail_button(button: MapleIconButton) -> void:
	rail.add_child(button)
	button.action.connect(_on_button)
	_layout()


func _on_button(id: StringName) -> void:
	action_requested.emit(id)


## The bubble swells into place like milk rising in a glass.
func _swell() -> void:
	if style == null or style.reduced_motion or Engine.is_editor_hint():
		modulate.a = 1.0
		return
	modulate.a = 0.0
	var rise := 10.0
	var target := glass.position
	glass.position = target + Vector2(0.0, rise)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, style.swell_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(glass, "position", target, style.swell_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(_layout)


## Every position in this scene is derived from the shared settings.
func _layout() -> void:
	if style == null or body == null or not is_inside_tree():
		return
	var vp := get_viewport_rect().size
	var w: float = minf(style.bubble_width, vp.x - style.bubble_offset.x * 2.0)

	var wrap_w := w - style.padding.x * 2.0
	body.position = style.padding
	body.size = Vector2(wrap_w, vp.y)
	var font := body.get_theme_font(&"font")
	var text_h := float(style.body_size) * 1.6
	if font != null and _full != "":
		text_h = font.get_multiline_string_size(
			_full, HORIZONTAL_ALIGNMENT_LEFT, wrap_w, style.body_size
		).y
	text_h = maxf(text_h, float(style.body_size) * 1.6)
	# A glass holds at least three lines of milk, even when the line is short.
	text_h = maxf(text_h, float(style.body_size) * 3.4)
	var h: float = style.padding.y * 2.0 + text_h

	var origin := Vector2(style.bubble_offset.x, vp.y - style.bubble_offset.y - h)
	glass.position = origin
	glass.size = Vector2(w, h)

	# Body is a child of Glass, so its position is local to the glass pane.
	body.position = style.padding
	body.size = Vector2(w - style.padding.x * 2.0, text_h + style.line_gap)

	# The name plate rides the top-left edge of the glass, half outside it.
	var plate_w: float = maxf(140.0, float(_speaker.length()) * style.name_size * 0.62 + 44.0)
	name_plate.size = Vector2(plate_w, float(style.name_size) + 26.0)
	name_plate.position = origin + Vector2(style.padding.x * 0.5, -name_plate.size.y * 0.5)
	name_label.position = Vector2(14.0, 0.0)
	name_label.size = name_plate.size - Vector2(28.0, 0.0)

	# The rail floats at the right edge of the screen, unattached to the bubble.
	var chips: Array = []
	for child in rail.get_children():
		if child is MapleIconButton:
			chips.append(child)
	if chips.is_empty():
		return
	var chip_h: float = style.chip_size
	var total: float = float(chips.size()) * chip_h + float(chips.size() - 1) * style.rail_gap
	rail.position = Vector2(
		vp.x - style.rail_offset.x - style.chip_size,
		(vp.y - total) * 0.5
	)
	rail.size = Vector2(style.chip_size, total)
	for i in chips.size():
		var child: Control = chips[i]
		child.position = Vector2(0.0, float(i) * (chip_h + style.rail_gap))
		child.size = Vector2(style.chip_size, chip_h)
