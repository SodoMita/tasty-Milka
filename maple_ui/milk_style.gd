@tool
class_name MapleMilkStyle
extends Resource
## Shared milk-glass settings — Maple [q9].
##
## The whole point of this file: the look lives *here*, not inside the scenes.
## `maple_ui/dialogue_bubble.tscn` and `maple_ui/title_screen.tscn` both hold a
## reference to the same `milk_style.tres`, so the bubble and the title can never
## drift apart. Swap the .tres (or tweak a value in the inspector) and every
## milk surface follows at once.
##
## Nothing in here creates a node. Scenes stay hand-authored; this resource only
## owns palette, glass geometry, type scale, icon sizing and motion timings.

@export_group("Palette")
## Butter-cream page behind everything. Never pure white.
@export var surface: Color = Color(0.984, 0.965, 0.925, 1.0)
## The glass itself: milk-white and translucent so the art shows through.
@export var glass: Color = Color(1.0, 0.992, 0.972, 0.72)
## Milk skin at the rim of the glass — a warm cream edge, never black.
@export var glass_edge: Color = Color(0.878, 0.792, 0.655, 1.0)
## Soft drop under the glass, tinted cocoa rather than grey.
@export var glass_shadow: Color = Color(0.23, 0.17, 0.12, 0.22)
## The thin meniscus highlight that runs along the top of the glass.
@export var highlight: Color = Color(1.0, 1.0, 1.0, 0.85)
## Cocoa ink for text and icons. Never pure black.
@export var ink: Color = Color(0.231, 0.165, 0.133, 0.96)
## Tinted neutral for secondary text.
@export var quiet: Color = Color(0.663, 0.584, 0.518, 1.0)
## Pale butter — the one saturated accent, used for focus rings and cues.
@export var butter: Color = Color(0.98, 0.878, 0.522, 1.0)
## Warm caramel: hover warmth for icons and plates.
@export var caramel: Color = Color(0.788, 0.541, 0.292, 1.0)

@export_group("Glass geometry")
## Corner radius of the big glass surfaces (bubble, title lockup).
@export var glass_radius: int = 28
## Corner radius of the small plates (name plate, icon chips).
@export var chip_radius: int = 16
## Rim thickness of the glass.
@export var rim_width: int = 2
## Inner padding of the big glass surfaces.
@export var padding: Vector2 = Vector2(30.0, 22.0)
## Extra scrim behind the glass when it sits over busy art (0 = none).
@export var scrim: float = 0.12

@export_group("Layout")
## Bubble width; the bubble is shallow and wide, not a full-width band.
@export var bubble_width: float = 720.0
## Bubble distance from the bottom-left corner of the screen.
@export var bubble_offset: Vector2 = Vector2(56.0, 48.0)
## Droplet tail that points at the speaker.
@export var tail_length: float = 30.0
@export var tail_width: float = 34.0
## The floating icon rail sits at the right edge, unattached to the bubble.
@export var rail_offset: Vector2 = Vector2(40.0, 0.0)
@export var rail_gap: float = 12.0
## Icon chip and icon glyph sizes.
@export var chip_size: float = 52.0
@export var icon_size: float = 26.0

@export_group("Type")
## Serif display (name plate + title), sans UI (chrome) — see consumers.
@export var body_size: int = 21
@export var name_size: int = 19
@export var chrome_size: int = 14
## Tracking for the small-caps name plate, in px.
@export var name_tracking: float = 1.4
@export var line_gap: int = 6

@export_group("Motion")
## Typewriter speed, characters per second.
@export var type_cps: float = 34.0
## The glass "swells" into place: scale y and alpha, in seconds.
@export var swell_time: float = 0.34
@export var hover_time: float = 0.14
## Skip overshoot/typing animation entirely.
@export var reduced_motion: bool = false


## Big translucent surface: dialogue bubble, title lockup, menus.
func glass_box(alpha_scale: float = 1.0, radius: int = -1) -> StyleBoxFlat:
	return _box(glass, glass_edge, glass_radius if radius < 0 else radius, alpha_scale)


## Small surface: name plate, icon chips. `state` is normal / hover / pressed.
func chip_box(state: StringName = &"normal", radius: int = -1) -> StyleBoxFlat:
	var fill := glass
	var edge := glass_edge
	var glow := 0.0
	match state:
		&"hover":
			fill = glass.lerp(caramel, 0.16)
			edge = caramel
			glow = 0.26
		&"pressed":
			fill = glass.lerp(butter, 0.42)
			edge = butter
			glow = 0.18
		&"disabled":
			fill = glass.lerp(quiet, 0.12)
			edge = glass_edge.lerp(quiet, 0.5)
	var box := _box(fill, edge, chip_radius if radius < 0 else radius, 1.0)
	# Small chips carry a small shadow — a 52px button with a 18px drop looks pasted on.
	box.shadow_size = 8
	box.shadow_offset = Vector2(0.0, 3.0)
	if glow > 0.0:
		box.shadow_color = Color(caramel.r, caramel.g, caramel.b, glow)
		box.shadow_size = 10
	return box


## The drop shadow + rim recipe shared by every glass surface.
func _box(fill: Color, edge: Color, radius: int, alpha_scale: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	var f := fill
	f.a *= alpha_scale
	box.bg_color = f
	box.set_corner_radius_all(radius)
	box.border_width_left = rim_width
	box.border_width_top = rim_width
	box.border_width_right = rim_width
	box.border_width_bottom = rim_width
	box.border_color = Color(edge.r, edge.g, edge.b, edge.a * alpha_scale)
	box.shadow_color = Color(glass_shadow.r, glass_shadow.g, glass_shadow.b, glass_shadow.a * alpha_scale)
	box.shadow_size = 18
	box.shadow_offset = Vector2(0.0, 6.0)
	box.anti_aliasing = true
	return box
