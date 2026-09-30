class_name MilkGlassSettings
extends Resource
## Milk-glass look for the whole VN surface: one shared settings resource that
## the dialogue bubble, the title screen and the settings panel all read.
##
## The style deliberately lives OUTSIDE vn_balloon.tscn, so the title scene can
## reuse the exact same settings - no scene builder script, no duplicated theme.
## Edit `res://assets/ui/milk_glass_settings.tres` to restyle everything at once.

signal restyled

@export_group("Glass")
## Milk tint the frosted panels are made of.
@export var glass_tint: Color = Color(1.0, 1.0, 1.0, 1.0)
@export_range(0.0, 1.0, 0.01) var glass_alpha: float = 0.30
@export_range(0.0, 1.0, 0.01) var glass_alpha_hover: float = 0.55
@export_range(0.0, 1.0, 0.01) var glass_alpha_pressed: float = 0.82
@export_range(0.0, 1.0, 0.01) var bubble_alpha: float = 0.62
@export var border_color: Color = Color(0.56, 0.54, 0.47, 0.5)
@export var border_color_active: Color = Color(0.42, 0.40, 0.33, 0.90)
@export_range(0, 8, 1) var border_width: int = 2
@export_range(0, 48, 1) var radius: int = 18
@export_range(0, 48, 1) var bubble_radius: int = 26
## Pale butter highlight - the only saturated colour the chrome is allowed.
@export var accent: Color = Color(0.95, 0.90, 0.63, 0.92)

@export_group("Type")
@export var font: FontFile = null
@export var font_bold: FontFile = null
@export var font_size: int = 20
@export var chrome_font_size: int = 14

@export_group("Icons")
## Buttons carry no text: the glyph is loaded from this folder by key name.
@export var icon_dir: String = "res://assets/ui/icons"
@export_range(8, 64, 1) var icon_size: int = 22

@export_group("Metrics")
@export var button_margin: Vector2 = Vector2(24, 12)
@export var chrome_min_size: Vector2 = Vector2(44, 44)

## Caches; never persisted into the .tres.
var _theme: Theme = null
var _icons: Dictionary = {}


## Theme used by every milk-glass surface. Built once, reused by all callers.
func build_theme() -> Theme:
	if _theme == null:
		_theme = _make_theme()
	return _theme


## Push the shared look into a control (and, through it, its children).
func apply_to(control: Control) -> void:
	control.theme = build_theme()


## Call after changing a token so every surface rebuilds its theme.
func restyle() -> void:
	_theme = null
	restyled.emit()


func icon(key: String) -> Texture2D:
	if not _icons.has(key):
		var path := "%s/%s.svg" % [icon_dir, key]
		_icons[key] = load(path) if ResourceLoader.exists(path) else null
	return _icons[key]


## Icon-only button: glyph + tooltip + accessible name, no visible text.
func icon_only(button: Button, key: String, label: String) -> void:
	button.icon = icon(key)
	button.expand_icon = true
	button.text = ""
	button.tooltip_text = tr(label)
	button.accessible_name = tr(label)
	if button.custom_minimum_size == Vector2.ZERO:
		button.custom_minimum_size = chrome_min_size
	button.add_theme_constant_override("icon_max_width", icon_size)


## Standalone style boxes, for surfaces that paint their own panel.
func style(box: String) -> StyleBoxFlat:
	match box:
		"normal":
			return _flat(glass_alpha, border_color)
		"hover":
			return _flat(glass_alpha_hover, border_color_active)
		"pressed":
			return _flat(glass_alpha_pressed, border_color_active)
		"bubble":
			return _flat(bubble_alpha, border_color, bubble_radius, Vector2.ZERO)
		"panel":
			return _flat(glass_alpha * 0.9, Color(border_color.r, border_color.g, border_color.b, 0.8),
					bubble_radius, Vector2.ZERO)
		"name_tag":
			var tag := _flat(0.92, Color(border_color_active.r, border_color_active.g, border_color_active.b, 0.9),
					int(radius * 0.75), Vector2.ZERO)
			tag.bg_color = Color(accent.r, accent.g, accent.b, 0.92)
			return tag
	return null


func _flat(alpha: float, border: Color, corner: int = -1, margins: Vector2 = Vector2(NAN, NAN)) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(glass_tint.r, glass_tint.g, glass_tint.b, alpha)
	box.set_border_width_all(border_width)
	box.border_color = border
	box.set_corner_radius_all(radius if corner < 0 else corner)
	var m: Vector2 = button_margin if margins.x != margins.x else margins
	box.content_margin_left = m.x
	box.content_margin_right = m.x
	box.content_margin_top = m.y
	box.content_margin_bottom = m.y
	return box


func _make_theme() -> Theme:
	var ink := Color(0.30, 0.29, 0.24, 0.95)
	var ink_dark := Color(0.22, 0.21, 0.17, 1.0)
	var theme := Theme.new()
	if font != null:
		theme.default_font = font
	theme.default_font_size = font_size

	# Button: three glass states plus a ring for keyboard focus.
	var states: Dictionary = {
		"normal": [glass_alpha, border_color],
		"hover": [glass_alpha_hover, border_color_active],
		"pressed": [glass_alpha_pressed, border_color_active],
		"selected": [glass_alpha_pressed, border_color_active],
	}
	for state: String in states:
		theme.set_stylebox(state, "Button", _flat(states[state][0], states[state][1]))
	var focus_ring := _flat(0.0, Color(accent.r, accent.g, accent.b, 0.95))
	focus_ring.set_border_width_all(border_width + 1)
	theme.set_stylebox("focus", "Button", focus_ring)
	theme.set_stylebox("disabled", "Button",
			_flat(glass_alpha * 0.6, Color(border_color.r, border_color.g, border_color.b, 0.35)))
	theme.set_color("font_color", "Button", ink)
	theme.set_color("font_hover_color", "Button", ink_dark)
	theme.set_color("font_pressed_color", "Button", ink_dark)
	theme.set_color("font_focus_color", "Button", ink_dark)
	theme.set_color("font_selected_color", "Button", ink_dark)
	theme.set_color("font_disabled_color", "Button", Color(ink.r, ink.g, ink.b, 0.45))
	theme.set_font_size("font_size", "Button", font_size)
	theme.set_constant("h_separation", "Button", 8)
	theme.set_constant("icon_max_width", "Button", icon_size)
	theme.set_constant("icon_max_width", "HBoxContainer", icon_size)

	# Panels, list rows and the dialogue surfaces.
	var panel := style("panel")
	theme.set_stylebox("panel", "Panel", panel)
	theme.set_stylebox("panel", "PanelContainer", panel)
	theme.set_stylebox("panel", "MenuPanel", _flat(glass_alpha, border_color, bubble_radius))
	theme.set_stylebox("panel", "VBoxContainer", StyleBoxEmpty.new())
	theme.set_color("font_color", "Label", ink)
	theme.set_color("default_color", "RichTextLabel", ink)
	theme.set_color("font_color", "RichTextLabel", ink)
	theme.set_stylebox("hover", "OptionButton", _flat(glass_alpha_hover, border_color_active))
	theme.set_stylebox("normal", "OptionButton", _flat(glass_alpha, border_color))
	theme.set_stylebox("pressed", "OptionButton", _flat(glass_alpha_pressed, border_color_active))
	theme.set_color("font_color", "OptionButton", ink)
	theme.set_color("font_hover_color", "OptionButton", ink_dark)
	theme.set_color("font_focus_color", "OptionButton", ink_dark)
	theme.set_color("font_color", "CheckBox", ink)
	theme.set_color("font_hover_color", "CheckBox", ink_dark)

	# Sliders: a soft trough with a droplet grabber.
	var trough := _flat(glass_alpha * 0.8, Color(border_color.r, border_color.g, border_color.b, 0.7),
			int(radius * 0.5))
	trough.content_margin_top = 6.0
	trough.content_margin_bottom = 6.0
	theme.set_stylebox("slider", "HSlider", trough)
	theme.set_stylebox("grabber_area", "HSlider", _flat(0.9, Color(accent.r, accent.g, accent.b, 0.55),
			int(radius * 0.5)))

	# Tooltips carry the labels the icon-only buttons dropped.
	theme.set_color("font_color", "TooltipLabel", ink_dark)
	theme.set_font_size("font_size", "TooltipLabel", chrome_font_size)
	theme.set_stylebox("panel", "TooltipPanel",
			_flat(glass_alpha_pressed, border_color_active, 10))
	return theme
