@tool
class_name MapleTitleScreen
extends Control
## Title screen. The lockup here is the *same* glass as the dialogue bubble:
## `MapleGlassPanel` wearing the same `maple_ui/milk_style.tres`. Nothing about
## the look is restated in this file — only the composition is.
##
## Menu buttons carry icons only. Every caption a person could need lives in
## `tooltip_text` (and in the game's translation files), never on the button.

signal menu_action(id: StringName)

## Shared milk-glass settings — one resource for title and bubble alike.
@export var style: MapleMilkStyle = preload("res://maple_ui/milk_style.tres")
## Small-caps subtitle under the title.
@export var subtitle: String = "a milk-glass interface"

@onready var lockup: Control = $Lockup
@onready var title_label: Label = $Lockup/Title
@onready var rule: ColorRect = $Lockup/Rule
@onready var subtitle_label: Label = $Lockup/Subtitle
@onready var menu: Control = $Menu
@onready var mute: Control = $Mute
@onready var droplets: Control = $DropletField


func _ready() -> void:
	resized.connect(_layout)
	get_viewport().size_changed.connect(_layout)
	for child in menu.get_children():
		if child is MapleIconButton:
			child.action.connect(_on_button)
	if mute is MapleIconButton:
		mute.action.connect(_on_button)
	subtitle_label.text = subtitle
	if style != null:
		title_label.add_theme_font_size_override("font_size", int(style.body_size * 2.5))
		subtitle_label.add_theme_font_size_override("font_size", style.chrome_size + 3)
		rule.color = style.butter
	_layout()
	_swell()


func _on_button(id: StringName) -> void:
	menu_action.emit(id)


## The glass rises once, gently; the droplet field keeps drifting behind it.
func _swell() -> void:
	if style == null or style.reduced_motion or Engine.is_editor_hint():
		return
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, style.swell_time * 1.2) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Composition: lockup sits on the left third, the icon menu stacks along the
## same vertical axis, and the right half of the screen stays empty glass.
func _layout() -> void:
	if style == null or menu == null or not is_inside_tree():
		return
	var vp := get_viewport_rect().size
	var lockup_w: float = minf(560.0, vp.x * 0.52)
	var lockup_h: float = 210.0
	var axis_x: float = maxf(56.0, vp.x * 0.24 - lockup_w * 0.28)

	lockup.position = Vector2(axis_x, vp.y * 0.22)
	lockup.size = Vector2(lockup_w, lockup_h)
	title_label.position = Vector2(0.0, 34.0)
	title_label.size = Vector2(lockup_w, 72.0)
	rule.position = Vector2((lockup_w - 150.0) * 0.5, 112.0)
	rule.size = Vector2(150.0, 3.0)
	subtitle_label.position = Vector2(0.0, 126.0)
	subtitle_label.size = Vector2(lockup_w, 32.0)

	var items: Array = []
	for child in menu.get_children():
		if child is MapleIconButton:
			items.append(child)
	var chip: float = style.chip_size * 1.1
	var gap: float = style.rail_gap + 2.0
	var total: float = float(items.size()) * chip + float(maxi(items.size() - 1, 0)) * gap
	menu.position = Vector2(axis_x + 26.0, vp.y * 0.22 + lockup_h + 42.0)
	menu.size = Vector2(chip, total)
	for i in items.size():
		var child: Control = items[i]
		child.position = Vector2(0.0, float(i) * (chip + gap))
		child.size = Vector2(chip, chip)

	mute.position = Vector2(vp.x - style.rail_offset.x - style.chip_size, style.rail_offset.y + 34.0)
	mute.size = Vector2(style.chip_size, style.chip_size)
