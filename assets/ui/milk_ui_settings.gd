@tool
class_name MilkUISettings
extends Resource
## Shared visual settings for every milk-glass surface in Milka VN.
##
## The dialogue bubble (`scenes/vn_balloon.tscn`) and the title screen
## (`scenes/title_screen.tscn`) both read this one resource, so the two
## scenes can never drift apart: change a value here and both follow.
##
## Nothing in here builds a node. Scenes stay hand-authored; this resource
## only owns the *look* - palette, glass geometry, name-plate motif, type
## scale and motion timings. `scenes/ui/milk_glass.gd` turns these values
## into StyleBoxes, a Theme and dressed icon buttons.

## Butter-warm cream page behind everything (never pure white).
@export_group("Palette")
@export var surface: Color = Color(0.984, 0.968, 0.937, 1)
## The glass itself: milk-white, translucent, so the art shows through.
@export var glass: Color = Color(1, 1, 1, 0.3)
@export var glass_hover: Color = Color(1, 1, 1, 0.55)
@export var glass_pressed: Color = Color(1, 0.96, 0.8, 0.8)
## Rim of the glass: a warm grey edge, never black.
@export var rim: Color = Color(0.56, 0.54, 0.47, 0.5)
@export var rim_strong: Color = Color(0.42, 0.4, 0.33, 0.9)
## Butter accent - the one saturated colour in the UI.
@export var butter: Color = Color(0.949, 0.902, 0.69, 0.92)
@export var butter_strong: Color = Color(0.937, 0.851, 0.463, 1)
## Deep cocoa ink for text (never pure black).
@export var ink: Color = Color(0.298, 0.282, 0.243, 0.95)
## Tinted neutral for secondary text.
@export var quiet: Color = Color(0.541, 0.514, 0.467, 1)

@export_group("Glass")
@export var corner_radius: int = 24
@export var chip_radius: int = 18
@export var plate_radius: int = 14
@export var border_width: int = 2
@export var content_margin: int = 24
@export var content_margin_y: int = 12
@export var chip_size: int = 44
## How far the name plate overlaps the bubble corner (px).
@export var plate_overlap: Vector2 = Vector2(-18, -18)

@export_group("Type")
@export var body_size: int = 20
@export var chrome_size: int = 15
@export var plate_size: int = 22
## Extra tracking for the name plate's small caps, in px.
@export var plate_tracking: float = 1.6

@export_group("Motion")
## Every panel rises this many pixels while it fades in.
@export var rise_px: float = 12.0
@export var fade_in: float = 0.32
@export var typewriter_cps: float = 32.0
@export var caret_blink: float = 1.06
## Skip all overshoot/typing animation (also honoured by the balloon).
@export var reduced_motion: bool = false


## The frosted panel behind dialogue and menus.
func panel_style() -> StyleBoxFlat:
	return _glass_box(glass, rim, corner_radius, content_margin, content_margin_y)


## Chip behind an icon-only button.
func chip_style(state: StringName = &"normal") -> StyleBoxFlat:
	var fill := glass
	var edge := rim
	match state:
		&"hover":
			fill = glass_hover
			edge = rim_strong
		&"pressed":
			fill = glass_pressed
			edge = rim_strong
	return _glass_box(fill, edge, chip_radius, 6, 6)


## The speaker plate that overlaps the bubble corner - also the title lockup.
func plate_style() -> StyleBoxFlat:
	return _glass_box(butter, rim_strong, plate_radius, 18, 6)


## Focus ring in the strong rim so keyboard users can see it.
func focus_style() -> StyleBoxFlat:
	var box := _glass_box(Color(0, 0, 0, 0), rim_strong, chip_radius, 6, 6)
	box.border_width_left = 3
	box.border_width_top = 3
	box.border_width_right = 3
	box.border_width_bottom = 3
	return box


## A whole Theme from the same values, for scene roots that want one.
func build_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = body_size
	theme.set_stylebox(&"panel", &"Panel", panel_style())
	theme.set_stylebox(&"panel", &"PanelContainer", panel_style())
	theme.set_color(&"font_color", &"Label", ink)
	theme.set_color(&"font_color", &"Button", ink)
	theme.set_color(&"font_hover_color", &"Button", Color(0.22, 0.21, 0.17, 1))
	theme.set_color(&"font_focus_color", &"Button", Color(1, 1, 1, 1))
	theme.set_color(&"font_pressed_color", &"Button", Color(0.22, 0.21, 0.17, 1))
	theme.set_font_size(&"font_size", &"Button", chrome_size)
	theme.set_constant(&"icon_max_width", &"Button", 24)
	theme.set_stylebox(&"normal", &"Button", chip_style(&"normal"))
	theme.set_stylebox(&"hover", &"Button", chip_style(&"hover"))
	theme.set_stylebox(&"pressed", &"Button", chip_style(&"pressed"))
	theme.set_stylebox(&"focus", &"Button", focus_style())
	return theme


func _glass_box(fill: Color, edge: Color, radius: int, margin_x: int, margin_y: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.border_width_left = border_width
	box.border_width_top = border_width
	box.border_width_right = border_width
	box.border_width_bottom = border_width
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_right = radius
	box.corner_radius_bottom_left = radius
	box.content_margin_left = margin_x
	box.content_margin_right = margin_x
	box.content_margin_top = margin_y
	box.content_margin_bottom = margin_y
	return box
