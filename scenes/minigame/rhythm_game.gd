extends CanvasLayer
## "Milk Beat Clicker" — a visual Cookie-Clicker + Rhythm Click & Optional Slide
## minigame for Milka VN (runs on layer 110, above VNBalloon's layer 100).
##
## Playable with PC mouse, mobile touch, or 1-button keyboard:
##   - Mouse / Touch : click/tap the giant Milk Cookie (in rhythm with the
##                     contracting beat ring for x2/x3 bonus, or rapidly like
##                     Cookie Clicker), and optionally drag/sweep across the
##                     cookie (or hold LMB) to churn-slide!
##   - 1-Key only    : tap Space / Enter (or any single key) to click the cookie;
##                     hold the same single key down to slide the churn whisk!

signal finished(result: Dictionary)

const DisplayRotation = preload("res://scenes/display_rotation.gd")

const LANES: int = 4
const FALL_TIME: float = 1.4
const PERFECT_WINDOW: float = 0.14
const GOOD_WINDOW: float = 0.26
const MISS_WINDOW: float = 0.34
const SLIDE_DISTANCE: float = 56.0
const HOLD_TO_SLIDE_TIME: float = 0.18
const HOLD_SWEEP_TIME: float = 0.38
const LEAD_IN: float = 0.45

const TEX_COOKIE: Texture2D = preload("res://assets/ui/milk_cookie.svg")
const TEX_DROPLET: Texture2D = preload("res://assets/ui/milk_droplet.svg")
const TEX_MILKA_SMILE: Texture2D = preload("res://assets/characters/milka_chan_smile.svg")
const TEX_MILKA_SURPRISED: Texture2D = preload("res://assets/characters/milka_chan_surprised.svg")

@export var note_count: int = 18
@export var beat_length: float = 0.55
@export var target_drops: int = 120

@onready var _root: Control = $Root
@onready var _canvas: Control = $Root/StageCanvas
@onready var _lanes: Control = $Root/Play/Lanes
@onready var _notes_layer: Control = $Root/Play/Notes
@onready var _hit_line: ColorRect = $Root/Play/HitLine
@onready var _note_template: Control = $Root/Play/NoteTemplate
@onready var _cookie_pivot: Control = $Root/CenterStage/CookiePivot
@onready var _cookie_tex: TextureRect = $Root/CenterStage/CookiePivot/CookieTexture
@onready var _milka_tex: TextureRect = $Root/LeftCard/Rows/MilkaPortrait
@onready var _milka_line: Label = $Root/LeftCard/Rows/CheerLabel
@onready var _upgrade_1: Label = $Root/RightCard/Rows/Upgrade1
@onready var _upgrade_2: Label = $Root/RightCard/Rows/Upgrade2
@onready var _upgrade_3: Label = $Root/RightCard/Rows/Upgrade3
@onready var _bottle_label: Label = $Root/RightCard/Rows/BottlePct
@onready var _bottle_canvas: Control = $Root/RightCard/Rows/Spacer
@onready var _serve_button: Button = $Root/RightCard/Rows/ServeButton
@onready var _score_label: Label = $Root/Hud/Top/Score
@onready var _combo_label: Label = $Root/Hud/Top/Combo
@onready var _judge_label: Label = $Root/Hud/Judge
@onready var _title_label: Label = $Root/Hud/Top/Title

var _time: float = 0.0
var _running: bool = false
var _finishing: bool = false
var _notes: Array[Dictionary] = []
var _score: int = 0
var _clicks: int = 0
var _slides: int = 0
var _combo: int = 0
var _best_combo: int = 0
var _perfect: int = 0
var _good: int = 0
var _missed: int = 0
var _dragging: Dictionary = {}

## Cookie-clicker + 1-button hold-to-slide state
var _pointer_down: bool = false
var _pointer_start: Vector2 = Vector2.ZERO
var _pointer_last: Vector2 = Vector2.ZERO
var _pointer_drag_accum: float = 0.0
var _key_down: bool = false
var _hold_duration: float = 0.0
var _hold_slide_progress: float = 0.0
var _slider_pos: float = 0.5
var _slider_dir: float = 1.0
var _cookie_scale: float = 1.0
var _cookie_angle: float = 0.0
var _beat_pulse: float = 0.0
var _auto_drip_accum: float = 0.0

## Visual particles & popups drawn on _canvas
var _particles: Array[Dictionary] = []
var _ripples: Array[Dictionary] = []
var _popups: Array[Dictionary] = []

func _ready() -> void:
	layer = 110
	_note_template.visible = false
	_root.gui_input.connect(_on_gui_input)
	_canvas.draw.connect(_on_canvas_draw)
	_bottle_canvas.draw.connect(_on_bottle_draw)
	_serve_button.pressed.connect(_on_serve_pressed)
	get_viewport().size_changed.connect(_sync_display_rotation)
	_sync_display_rotation()
	_build_chart()
	_spawn_notes()
	_update_hud("Click the Milk Cookie on the beat — or hold/drag to slide!")
	_running = true

func _sync_display_rotation() -> void:
	if not is_node_ready():
		return
	var store: Node = get_node_or_null("/root/SettingsStore")
	var deg: int = 0
	if store != null and store.get("data") is Dictionary:
		deg = DisplayRotation.normalize(int((store.get("data") as Dictionary).get("rotation", 0)))
	var win: Vector2 = get_viewport().get_visible_rect().size
	if win.x > 1.0 and win.y > 1.0:
		_root.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		_root.pivot_offset = Vector2.ZERO
		_root.size = DisplayRotation.logical_size(win, deg)
		transform = DisplayRotation.canvas_transform(win, deg)

func start_with_seed(seed_value: int, notes: int = 18) -> void:
	note_count = notes
	seed(seed_value)

func _build_chart() -> void:
	_notes.clear()
	var t: float = LEAD_IN
	for i: int in note_count:
		var is_slide: bool = i >= 3 and (i % 4 == 3)
		var lane: int = i % LANES
		if is_slide:
			lane = clampi(lane, 1, LANES - 2)
		_notes.append({
			"time": t,
			"lane": lane,
			"slide": is_slide,
			"dir": 1 if (i % 2 == 0) else -1,
			"done": false,
			"optional": is_slide,
			"node": null,
		})
		t += beat_length

func _spawn_notes() -> void:
	for note: Dictionary in _notes:
		var n: Control = _note_template.duplicate()
		n.visible = true
		_notes_layer.add_child(n)
		note["node"] = n
		var label: Label = n.get_node("Glyph")
		if bool(note["slide"]):
			label.text = "»" if int(note["dir"]) > 0 else "«"
			n.modulate = Color(1.0, 0.92, 0.62, 0.95)
		else:
			label.text = "●"
			n.modulate = Color(1.0, 0.98, 0.9, 0.92)

func _input(event: InputEvent) -> void:
	if not _running:
		return
	if event is InputEventKey:
		var ke: InputEventKey = event
		if ke.echo:
			return
		if ke.keycode == KEY_ESCAPE or ke.keycode == KEY_F12:
			return
		if ke.pressed:
			press_one_button()
			get_viewport().set_input_as_handled()
		else:
			release_one_button()
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not _running:
		return
	_time += delta

	var beat_phase: float = fposmod(_time, beat_length) / maxf(beat_length, 0.001)
	_beat_pulse = exp(-beat_phase * 5.0)
	_cookie_scale = move_toward(_cookie_scale, 1.0 + _beat_pulse * 0.06, delta * 6.0)
	_cookie_angle = sin(_time * 2.4) * 0.05
	if is_instance_valid(_cookie_pivot):
		_cookie_pivot.pivot_offset = _cookie_pivot.size * 0.5
		_cookie_pivot.scale = Vector2.ONE * _cookie_scale
		_cookie_pivot.rotation = _cookie_angle
	if is_instance_valid(_milka_tex):
		_milka_tex.position.y = sin(_time * TAU / maxf(beat_length, 0.15)) * 5.0

	if _score >= 45:
		_auto_drip_accum += delta
		if _auto_drip_accum >= beat_length:
			_auto_drip_accum -= beat_length
			_score += 2
			_spawn_burst(_cookie_center() + Vector2(randf_range(-55.0, 55.0), randf_range(-55.0, 55.0)), 2, false)
			_update_hud("")

	if _key_down or _pointer_down:
		_hold_duration += delta
		if _hold_duration >= HOLD_TO_SLIDE_TIME:
			var step: float = delta / HOLD_SWEEP_TIME
			_hold_slide_progress += step
			_slider_pos = pingpong(_slider_pos + step * _slider_dir, 1.0)
			if _hold_slide_progress >= 1.0:
				_hold_slide_progress -= 1.0
				_slider_dir = -_slider_dir
				_complete_slide_churn(_cookie_center())

	_tick_visuals(delta)

	var remaining: int = 0
	for note: Dictionary in _notes:
		if bool(note["done"]):
			continue
		remaining += 1
		var n: Control = note["node"]
		var dt: float = float(note["time"]) - _time
		if n != null:
			n.position = Vector2(_lane_x(int(note["lane"])) - n.size.x * 0.5, _note_y(dt))
		if dt < -MISS_WINDOW:
			_resolve(note, "MISS")
	_canvas.queue_redraw()
	_bottle_canvas.queue_redraw()
	if remaining == 0:
		_finish(false)

func _tick_visuals(delta: float) -> void:
	var next_particles: Array[Dictionary] = []
	for p: Dictionary in _particles:
		p["life"] = float(p["life"]) - delta
		if float(p["life"]) > 0.0:
			var vel: Vector2 = p["vel"]
			vel.y += 460.0 * delta
			p["vel"] = vel
			p["pos"] = (p["pos"] as Vector2) + vel * delta
			next_particles.append(p)
	_particles = next_particles

	var next_ripples: Array[Dictionary] = []
	for r: Dictionary in _ripples:
		r["life"] = float(r["life"]) - delta
		if float(r["life"]) > 0.0:
			r["radius"] = float(r["radius"]) + float(r["speed"]) * delta
			next_ripples.append(r)
	_ripples = next_ripples

	var next_popups: Array[Dictionary] = []
	for pop: Dictionary in _popups:
		pop["life"] = float(pop["life"]) - delta
		if float(pop["life"]) > 0.0:
			pop["pos"] = (pop["pos"] as Vector2) + Vector2(0.0, -48.0 * delta)
			next_popups.append(pop)
	_popups = next_popups

func _cookie_center() -> Vector2:
	if is_instance_valid(_cookie_pivot):
		return _cookie_pivot.position + _cookie_pivot.size * 0.5
	var vp: Vector2 = _root.size if _root.size.x > 10.0 else Vector2(1280.0, 720.0)
	return Vector2(vp.x * 0.5, vp.y * 0.45)

func _on_bottle_draw() -> void:
	var sz: Vector2 = _bottle_canvas.size
	var bw: float = 78.0
	var bh: float = maxf(sz.y - 12.0, 110.0)
	var bx: float = (sz.x - bw) * 0.5
	var by: float = (sz.y - bh) * 0.5
	var bottle_rect := Rect2(bx, by, bw, bh)
	_bottle_canvas.draw_rect(bottle_rect, Color(0.24, 0.18, 0.14, 0.88), true)
	var fill_ratio: float = clampf(float(_score) / float(maxi(target_drops, 1)), 0.0, 1.0)
	var fill_h: float = (bottle_rect.size.y - 10.0) * fill_ratio
	if fill_h > 1.0:
		var milk_rect := Rect2(
			bottle_rect.position.x + 5.0,
			bottle_rect.position.y + bottle_rect.size.y - 5.0 - fill_h,
			bottle_rect.size.x - 10.0,
			fill_h
		)
		_bottle_canvas.draw_rect(milk_rect, Color(1.0, 0.97, 0.84, 0.98), true)
		_bottle_canvas.draw_line(
			Vector2(milk_rect.position.x, milk_rect.position.y),
			Vector2(milk_rect.end.x, milk_rect.position.y),
			Color(0.95, 0.82, 0.38, 1.0),
			3.0
		)
	_bottle_canvas.draw_rect(bottle_rect, Color(0.62, 0.48, 0.22, 0.95), false, 3.0)

func _on_canvas_draw() -> void:
	var c: Vector2 = _cookie_center()
	var vp: Vector2 = _canvas.size if _canvas.size.x > 10.0 else Vector2(1280.0, 720.0)

	_canvas.draw_circle(c, 250.0, Color(1.0, 0.96, 0.80, 0.12))
	_canvas.draw_circle(c, 195.0, Color(1.0, 0.95, 0.72, 0.16))
	var ray_count: int = 12
	for i: int in ray_count:
		var a0: float = _time * 0.45 + float(i) * TAU / float(ray_count)
		var a1: float = a0 + TAU / float(ray_count * 2.4)
		var pts := PackedVector2Array([
			c,
			c + Vector2(cos(a0), sin(a0)) * 245.0,
			c + Vector2(cos(a1), sin(a1)) * 245.0,
		])
		_canvas.draw_colored_polygon(pts, Color(1.0, 0.94, 0.68, 0.11))

	var cookie_radius: float = 114.0 + _beat_pulse * 8.0
	_canvas.draw_arc(c, cookie_radius, 0.0, TAU, 64, Color(1.0, 0.95, 0.74, 0.9), 5.0)
	for note: Dictionary in _notes:
		if bool(note["done"]):
			continue
		var dt: float = float(note["time"]) - _time
		if dt < -MISS_WINDOW or dt > FALL_TIME:
			continue
		var t_norm: float = clampf(dt / FALL_TIME, 0.0, 1.0)
		var ring_r: float = lerpf(cookie_radius, cookie_radius + 135.0, t_norm)
		var in_sweet: bool = absf(dt) <= GOOD_WINDOW
		var ring_col: Color = (
			Color(1.0, 0.86, 0.35, 0.95) if bool(note["slide"])
			else (Color(0.65, 1.0, 0.78, 0.95) if in_sweet else Color(1.0, 0.98, 0.9, 0.65))
		)
		_canvas.draw_arc(c, ring_r, 0.0, TAU, 56, ring_col, 6.0 if in_sweet else 3.5)

	var track_w: float = 320.0
	var track_y: float = c.y + 152.0
	var track_left: float = c.x - track_w * 0.5
	var track_rect := Rect2(track_left, track_y - 14.0, track_w, 28.0)
	_canvas.draw_rect(track_rect, Color(0.22, 0.17, 0.14, 0.75), true)
	_canvas.draw_rect(track_rect, Color(1.0, 0.92, 0.62, 0.9), false, 2.5)
	var fill_w: float = track_w * clampf(_slider_pos, 0.05, 1.0)
	_canvas.draw_rect(Rect2(track_left + 3.0, track_y - 11.0, fill_w - 6.0, 22.0), Color(1.0, 0.88, 0.45, 0.55), true)
	var orb_x: float = lerpf(track_left + 18.0, track_left + track_w - 18.0, clampf(_slider_pos, 0.0, 1.0))
	_canvas.draw_circle(Vector2(orb_x, track_y), 17.0, Color(1.0, 0.96, 0.78, 1.0))
	_canvas.draw_arc(Vector2(orb_x, track_y), 17.0, 0.0, TAU, 28, Color(0.58, 0.42, 0.16, 1.0), 3.0)



	for r: Dictionary in _ripples:
		var alpha: float = clampf(float(r["life"]) / 0.45, 0.0, 1.0)
		var col: Color = r["color"]
		col.a = alpha
		_canvas.draw_arc(r["pos"], float(r["radius"]), 0.0, TAU, 40, col, 4.0)

	for p: Dictionary in _particles:
		var alpha: float = clampf(float(p["life"]) / 0.7, 0.0, 1.0)
		var pos: Vector2 = p["pos"]
		var col: Color = p["color"]
		col.a = alpha
		var rad: float = float(p["size"])
		_canvas.draw_circle(pos, rad, col)
		_canvas.draw_circle(pos + Vector2(-rad * 0.28, -rad * 0.28), rad * 0.35, Color(1.0, 1.0, 1.0, alpha))

	var font: Font = ThemeDB.fallback_font
	if font != null:
		for pop: Dictionary in _popups:
			var alpha: float = clampf(float(pop["life"]) / 0.75, 0.0, 1.0)
			var col: Color = pop["color"]
			col.a = alpha
			_canvas.draw_string(
				font,
				pop["pos"],
				String(pop["text"]),
				HORIZONTAL_ALIGNMENT_CENTER,
				180.0,
				20,
				col
			)

func _lane_x(lane: int) -> float:
	var w: float = _lanes.size.x if _lanes.size.x > 1.0 else (_root.size.x if _root.size.x > 1.0 else 1280.0)
	return _lanes.position.x + w * (float(lane) + 0.5) / float(LANES)

func _note_y(dt: float) -> float:
	var line_y: float = _hit_line.position.y
	var travel: float = line_y + 120.0
	return line_y - travel * (dt / FALL_TIME)

func _on_gui_input(event: InputEvent) -> void:
	if not _running:
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_press(mb.position)
		else:
			_release(mb.position)
	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event
		_motion(mm.position)
	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event
		if st.pressed:
			_press(st.position)
		else:
			_release(st.position)
	elif event is InputEventScreenDrag:
		var sd: InputEventScreenDrag = event
		_motion(sd.position)

func press_one_button() -> void:
	if not _running:
		return
	_key_down = true
	_hold_duration = 0.0
	_hold_slide_progress = 0.0
	perform_click(_cookie_center())

func release_one_button() -> void:
	if not _running:
		return
	if _key_down and _hold_duration >= HOLD_TO_SLIDE_TIME and _hold_slide_progress >= 0.35:
		_complete_slide_churn(_cookie_center())
	_key_down = false
	_hold_duration = 0.0
	_hold_slide_progress = 0.0

func hold_one_button(seconds: float) -> void:
	press_one_button()
	var step: float = 0.05
	var elapsed: float = 0.0
	while elapsed < seconds:
		var dt: float = minf(step, seconds - elapsed)
		_process(dt)
		elapsed += dt
	release_one_button()

func _press(pos: Vector2) -> void:
	_pointer_down = true
	_pointer_start = pos
	_pointer_last = pos
	_pointer_drag_accum = 0.0
	_hold_duration = 0.0
	_hold_slide_progress = 0.0

	var note: Dictionary = _note_at(pos)
	if not note.is_empty():
		if bool(note["slide"]):
			_dragging = {"note": note, "from": pos}
			_bounce_cookie(1.12)
			return
		_judge(note)
		return

	perform_click(pos)

func _motion(pos: Vector2) -> void:
	if not _dragging.is_empty():
		var note: Dictionary = _dragging["note"]
		var from: Vector2 = _dragging["from"]
		var dx: float = pos.x - from.x
		_slider_pos = clampf(0.5 + dx / (SLIDE_DISTANCE * 2.0), 0.0, 1.0)
		if absf(dx) >= SLIDE_DISTANCE and signf(dx) == float(int(note["dir"])):
			_dragging = {}
			_slides += 1
			_judge(note)
			_spawn_burst(pos, 10, true)
			_add_popup(pos, "SLIDE PERFECT!", Color(1.0, 0.90, 0.35))
		return

	if _pointer_down:
		var step_dx: float = absf(pos.x - _pointer_last.x) + absf(pos.y - _pointer_last.y) * 0.5
		_pointer_last = pos
		_pointer_drag_accum += step_dx
		_slider_pos = pingpong(_slider_pos + step_dx / 180.0, 1.0)
		if _pointer_drag_accum >= SLIDE_DISTANCE:
			_pointer_drag_accum = 0.0
			_complete_slide_churn(pos)

func _release(_pos: Vector2) -> void:
	_pointer_down = false
	_hold_duration = 0.0
	_hold_slide_progress = 0.0
	if _dragging.is_empty():
		return
	var note: Dictionary = _dragging["note"]
	_dragging = {}
	if bool(note.get("optional", true)):
		_resolve(note, "GOOD")
	else:
		_resolve(note, "MISS")

func perform_click(pos: Vector2 = Vector2(640.0, 330.0)) -> void:
	_clicks += 1
	_bounce_cookie(1.18)
	var nearest: Dictionary = _nearest_active_note()
	if not nearest.is_empty():
		var dt: float = absf(float(nearest["time"]) - _time)
		if not bool(nearest["slide"]) and dt <= GOOD_WINDOW:
			_judge(nearest)
			_spawn_burst(pos, 9, dt <= PERFECT_WINDOW)
			return
	var mult: int = _current_multiplier()
	var gain: int = 2 * mult
	_score += gain
	_combo += 1
	_best_combo = maxi(_best_combo, _combo)
	_spawn_burst(pos, 6, false)
	_add_popup(pos, "+%d" % gain, Color(1.0, 0.98, 0.88))
	_sfx("click")
	_update_hud("CLICK +%d" % gain)

func _complete_slide_churn(pos: Vector2) -> void:
	_slides += 1
	_bounce_cookie(1.22)
	var slide_note: Dictionary = _nearest_slide_note()
	if not slide_note.is_empty():
		_resolve(slide_note, "PERFECT")
	var mult: int = _current_multiplier()
	var gain: int = 6 * mult
	_score += gain
	_combo += 1
	_best_combo = maxi(_best_combo, _combo)
	_spawn_burst(pos, 11, true)
	_add_popup(pos, "SLIDE +%d!" % gain, Color(1.0, 0.88, 0.32))
	_sfx("confirm")
	_update_hud("SLIDE CHURN +%d!" % gain)

func _current_multiplier() -> int:
	var mult: int = 1
	if _score >= 15:
		mult = 2
	if _score >= 90:
		mult = 3
	return mult

func _bounce_cookie(peak: float) -> void:
	_cookie_scale = maxf(_cookie_scale, peak)

func _spawn_burst(origin: Vector2, count: int, golden: bool) -> void:
	_ripples.append({
		"pos": origin,
		"radius": 28.0,
		"speed": 220.0,
		"life": 0.42,
		"color": Color(1.0, 0.88, 0.36, 0.9) if golden else Color(1.0, 0.98, 0.90, 0.85),
	})
	for i: int in count:
		var angle: float = randf() * TAU
		var speed: float = randf_range(95.0, 260.0)
		_particles.append({
			"pos": origin,
			"vel": Vector2(cos(angle) * speed, sin(angle) * speed - 110.0),
			"size": randf_range(5.0, 10.0),
			"life": randf_range(0.38, 0.70),
			"color": Color(1.0, 0.90, 0.42, 1.0) if golden else Color(1.0, 0.98, 0.92, 1.0),
		})

func _add_popup(origin: Vector2, text: String, col: Color) -> void:
	_popups.append({
		"pos": origin + Vector2(-70.0, -24.0),
		"text": text,
		"color": col,
		"life": 0.72,
	})

func _nearest_active_note() -> Dictionary:
	var best: Dictionary = {}
	var best_dt: float = MISS_WINDOW
	for note: Dictionary in _notes:
		if bool(note["done"]):
			continue
		var dt: float = absf(float(note["time"]) - _time)
		if dt < best_dt:
			best_dt = dt
			best = note
	return best

func _nearest_slide_note() -> Dictionary:
	for note: Dictionary in _notes:
		if bool(note["done"]) or not bool(note["slide"]):
			continue
		if absf(float(note["time"]) - _time) <= MISS_WINDOW * 1.5:
			return note
	return {}

func _note_at(pos: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_dt: float = MISS_WINDOW
	var root_w: float = _root.size.x if _root.size.x > 1.0 else 1280.0
	for note: Dictionary in _notes:
		if bool(note["done"]):
			continue
		var dt: float = absf(float(note["time"]) - _time)
		if dt > MISS_WINDOW:
			continue
		if absf(_lane_x(int(note["lane"])) - pos.x) > (root_w / float(LANES)) * 0.6:
			continue
		if dt < best_dt:
			best_dt = dt
			best = note
	return best

func _judge(note: Dictionary) -> void:
	var dt: float = absf(float(note["time"]) - _time)
	if dt <= PERFECT_WINDOW:
		_resolve(note, "PERFECT")
	elif dt <= GOOD_WINDOW:
		_resolve(note, "GOOD")
	else:
		_resolve(note, "MISS")

func _resolve(note: Dictionary, verdict: String) -> void:
	if bool(note["done"]):
		return
	note["done"] = true
	var n: Control = note["node"]
	if n != null:
		n.queue_free()
		note["node"] = null
	var mult: int = _current_multiplier()
	match verdict:
		"PERFECT":
			_perfect += 1
			_combo += 1
			var pts: int = (100 + _combo * 5) * mult
			_score += pts
			_spawn_burst(_cookie_center(), 10, true)
			_add_popup(_cookie_center(), "PERFECT +%d" % pts, Color(1.0, 0.90, 0.36))
			_sfx("confirm")
		"GOOD":
			_good += 1
			_combo += 1
			var pts_g: int = (50 + _combo * 2) * mult
			_score += pts_g
			_spawn_burst(_cookie_center(), 6, false)
			_add_popup(_cookie_center(), "GOOD +%d" % pts_g, Color(0.75, 1.0, 0.82))
			_sfx("click")
		_:
			_missed += 1
			if _clicks == 0 and _slides == 0 and not bool(note.get("optional", false)):
				_combo = 0
	_best_combo = maxi(_best_combo, _combo)
	_update_hud(verdict if (verdict != "MISS" or (_clicks == 0 and _slides == 0)) else "")

func _update_hud(verdict: String) -> void:
	_score_label.text = "Milk Drops: %d" % _score
	_combo_label.text = "Combo x%d (Mult x%d)" % [_combo, _current_multiplier()]
	_title_label.text = "Milk Beat Clicker"
	var pct: int = clampi(int(round(float(_score) * 100.0 / float(maxi(target_drops, 1)))), 0, 999)
	if is_instance_valid(_bottle_label):
		_bottle_label.text = "Bottle: %d%%" % pct
	if is_instance_valid(_upgrade_1):
		_upgrade_1.text = "[x] Butter Whisk (x2)" if _score >= 15 else "[ ] Butter Whisk (15 drops)"
	if is_instance_valid(_upgrade_2):
		_upgrade_2.text = "[x] Meadow Bell (Auto)" if _score >= 45 else "[ ] Meadow Bell (45 drops)"
	if is_instance_valid(_upgrade_3):
		_upgrade_3.text = "[x] Cream Fever (x3!)" if _score >= 90 else "[ ] Cream Fever (90 drops)"
	if is_instance_valid(_milka_line):
		if _score >= 90:
			_milka_line.text = "Milka: \"GOLDEN CREAM FEVER! Look at all that milk!!\""
			_milka_tex.texture = TEX_MILKA_SURPRISED
		elif _slides > 0 and verdict.begins_with("SLIDE"):
			_milka_line.text = "Milka: \"Ooh, smooth slide churn~! Keep going!\""
			_milka_tex.texture = TEX_MILKA_SMILE
		elif _combo >= 4:
			_milka_line.text = "Milka: \"Nya~ You caught the meadow heartbeat!\""
			_milka_tex.texture = TEX_MILKA_SMILE
		else:
			_milka_line.text = "Milka: \"Click the Milk Cookie! Hold or drag to slide~\""
	if verdict != "":
		_judge_label.text = verdict

func _on_serve_pressed() -> void:
	_sfx("save")
	_finish(true)

func _finish(immediate: bool = false) -> void:
	if not _running or _finishing:
		return
	_running = false
	_finishing = true
	var total: int = _notes.size()
	var hits: int = _perfect + _good + _clicks + _slides
	var accuracy: float = clampf((float(hits) / float(maxi(total, 1))) * 100.0, 0.0, 100.0)
	var rank: String = "milk puddle"
	if _score >= 220 or accuracy >= 95.0:
		rank = "cream legend"
	elif _score >= 90 or accuracy >= 70.0:
		rank = "steady churner"
	elif _score >= 10 or accuracy >= 35.0:
		rank = "wobbly whisk"
	var result: Dictionary = {
		"score": _score,
		"clicks": _clicks,
		"slides": _slides,
		"perfect": _perfect,
		"good": _good,
		"missed": _missed,
		"best_combo": _best_combo,
		"accuracy": accuracy,
		"rank": rank,
		"total": total,
	}
	_judge_label.text = "%s! %d Milk Drops" % [rank, _score]
	if not immediate and DisplayServer.get_name() != "headless":
		await get_tree().create_timer(0.55).timeout
	else:
		await get_tree().process_frame
	finished.emit(result)
	queue_free()

func _sfx(sfx_name: String) -> void:
	var audio: Node = get_tree().root.get_node_or_null("AudioDirector")
	if audio != null and audio.has_method("play_sfx"):
		audio.play_sfx(sfx_name)
