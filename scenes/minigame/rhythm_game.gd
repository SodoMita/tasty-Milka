extends CanvasLayer
## "Milk Beat Clicker" — a visual Cookie-Clicker + Rhythm Click & Optional Slide
## minigame for Milka VN (runs on layer 110, above VNBalloon's layer 100).
##
## Properly distinguishes a SINGLE TAP from a SWIPE / SLIDE and reacts to each:
##   - Single Tap : quick press & release (< 24 px movement and < 0.20s hold).
##                  Triggers crisp milk droplet burst, hits round tap notes (●),
##                  increments `clicks` (never `slides`).
##   - Swipe/Slide: pointer drag (>= 24 px movement) OR holding down a single
##                  key / button (>= 0.20s). Draws a golden butter swipe ribbon,
##                  sweeps the churn whisk, hits arrow slide notes (» / «), and
##                  increments `slides` (never `clicks`).

signal finished(result: Dictionary)

const DisplayRotation = preload("res://scenes/display_rotation.gd")

const LANES: int = 4
const FALL_TIME: float = 1.4
const PERFECT_WINDOW: float = 0.14
const GOOD_WINDOW: float = 0.26
const MISS_WINDOW: float = 0.34
const SWIPE_THRESHOLD: float = 24.0
const SLIDE_DISTANCE: float = 56.0
const HOLD_TO_SLIDE_TIME: float = 0.20
const HOLD_SWEEP_TIME: float = 0.36
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
var _last_gesture: String = "NONE"

## Pointer (mouse / touch) & 1-key gesture classification state
var _pointer_down: bool = false
var _pointer_start: Vector2 = Vector2.ZERO
var _pointer_last: Vector2 = Vector2.ZERO
var _pointer_down_time: float = 0.0
var _pointer_drag_accum: float = 0.0
var _gesture_became_swipe: bool = false
var _slides_in_gesture: int = 0
var _dragging: Dictionary = {}

var _key_down: bool = false
var _key_down_time: float = 0.0
var _key_became_slide: bool = false
var _hold_duration: float = 0.0
var _hold_slide_progress: float = 0.0

var _slider_pos: float = 0.5
var _slider_dir: float = 1.0
var _cookie_scale: float = 1.0
var _cookie_angle: float = 0.0
var _beat_pulse: float = 0.0
var _auto_drip_accum: float = 0.0

## Visual particles, swipe trail & popups drawn on _canvas
var _particles: Array[Dictionary] = []
var _ripples: Array[Dictionary] = []
var _swipe_trail: Array[Dictionary] = []
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
	_update_hud("Single-tap cookie for drops, or swipe/hold to churn!")
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
	_cookie_angle = move_toward(_cookie_angle, sin(_time * 2.4) * 0.05, delta * 4.0)
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

	# Hold-to-slide classification: once held >= HOLD_TO_SLIDE_TIME without moving,
	# the gesture becomes a SWIPE/SLIDE (and NOT a single tap!).
	if _key_down or (_pointer_down and not _gesture_became_swipe):
		_hold_duration += delta
		if _hold_duration >= HOLD_TO_SLIDE_TIME:
			if _key_down:
				_key_became_slide = true
			if _pointer_down:
				_gesture_became_swipe = true
			var step: float = delta / HOLD_SWEEP_TIME
			_hold_slide_progress += step
			_slider_pos = pingpong(_slider_pos + step * _slider_dir, 1.0)
			var c: Vector2 = _cookie_center()
			var trail_x: float = lerpf(c.x - 140.0, c.x + 140.0, _slider_pos)
			_swipe_trail.append({"pos": Vector2(trail_x, c.y + 152.0), "life": 0.35})
			if _hold_slide_progress >= 1.0:
				_hold_slide_progress -= 1.0
				_slider_dir = -_slider_dir
				_slides_in_gesture += 1
				perform_swipe(c, Vector2(_slider_dir * 80.0, 0.0))
	elif _pointer_down and _gesture_became_swipe:
		_hold_duration += delta

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

	var next_trail: Array[Dictionary] = []
	for tr_pt: Dictionary in _swipe_trail:
		tr_pt["life"] = float(tr_pt["life"]) - delta
		if float(tr_pt["life"]) > 0.0:
			next_trail.append(tr_pt)
	_swipe_trail = next_trail

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
	var rim_col: Color = Color(1.0, 0.86, 0.32, 0.95) if _last_gesture == "SWIPE" else Color(0.82, 0.96, 1.0, 0.92)
	_canvas.draw_arc(c, cookie_radius, 0.0, TAU, 64, rim_col, 5.0)
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

	# Golden Swipe Ribbon Trail
	for i: int in _swipe_trail.size():
		var pt: Dictionary = _swipe_trail[i]
		var a: float = clampf(float(pt["life"]) / 0.40, 0.0, 1.0)
		var pos: Vector2 = pt["pos"]
		_canvas.draw_circle(pos, 10.0 * a, Color(1.0, 0.88, 0.34, a * 0.85))
		if i > 0:
			var prev_pos: Vector2 = _swipe_trail[i - 1]["pos"]
			if prev_pos.distance_to(pos) < 160.0:
				_canvas.draw_line(prev_pos, pos, Color(1.0, 0.92, 0.45, a * 0.9), 7.0 * a)

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
				220.0,
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

## 1-button keyboard press: classifies as SINGLE TAP if released before
## HOLD_TO_SLIDE_TIME, or as SWIPE/SLIDE if held >= HOLD_TO_SLIDE_TIME.
func press_one_button() -> void:
	if not _running:
		return
	_key_down = true
	_key_down_time = _time
	_key_became_slide = false
	_hold_duration = 0.0
	_hold_slide_progress = 0.0
	_slides_in_gesture = 0
	_cookie_scale = 0.94

func release_one_button() -> void:
	if not _running or not _key_down:
		return
	_key_down = false
	if _key_became_slide or _hold_duration >= HOLD_TO_SLIDE_TIME:
		# Held long enough -> classified strictly as SWIPE/SLIDE (never a single tap).
		if _slides_in_gesture == 0:
			perform_swipe(_cookie_center(), Vector2(_slider_dir * 80.0, 0.0))
	else:
		# Quick press + release -> classified strictly as SINGLE TAP (never a swipe).
		perform_tap(_cookie_center(), _key_down_time)
	_hold_duration = 0.0
	_hold_slide_progress = 0.0
	_key_became_slide = false

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
	_pointer_down_time = _time
	_pointer_drag_accum = 0.0
	_gesture_became_swipe = false
	_slides_in_gesture = 0
	_hold_duration = 0.0
	_hold_slide_progress = 0.0
	_cookie_scale = 0.94

	var note: Dictionary = _note_at(pos)
	if not note.is_empty():
		_dragging = {"note": note, "from": pos, "down_time": _time}
	else:
		_dragging = {}

func _motion(pos: Vector2) -> void:
	if not _pointer_down and _dragging.is_empty():
		return

	var step_vec: Vector2 = pos - _pointer_last
	var step_dist: float = step_vec.length()
	_pointer_last = pos
	_pointer_drag_accum += step_dist
	var disp_from_start: float = pos.distance_to(_pointer_start)

	if disp_from_start >= SWIPE_THRESHOLD or _pointer_drag_accum >= SWIPE_THRESHOLD:
		_gesture_became_swipe = true
		_swipe_trail.append({"pos": pos, "life": 0.40})

	if not _dragging.is_empty():
		var note: Dictionary = _dragging["note"]
		var from: Vector2 = _dragging["from"]
		var dx: float = pos.x - from.x
		if bool(note["slide"]):
			_slider_pos = clampf(0.5 + dx / (SLIDE_DISTANCE * 2.0), 0.0, 1.0)
			if absf(dx) >= SLIDE_DISTANCE and signf(dx) == float(int(note["dir"])):
				_gesture_became_swipe = true
				_dragging = {}
				_slides += 1
				_slides_in_gesture += 1
				_last_gesture = "SWIPE"
				_cookie_angle = 0.18 * float(int(note["dir"]))
				_judge(note)
				_spawn_burst(pos, 11, true)
				_add_popup(pos, "SWIPE PERFECT!", Color(1.0, 0.90, 0.35))
				_update_hud("SWIPE PERFECT!")
				return
		elif _gesture_became_swipe:
			# Swiped across a tap note: drop the tap note target and treat as cookie swipe
			_dragging = {}

	if _pointer_down and _gesture_became_swipe:
		_slider_pos = pingpong(_slider_pos + step_dist / 160.0, 1.0)
		if _pointer_drag_accum >= SLIDE_DISTANCE:
			_pointer_drag_accum -= SLIDE_DISTANCE
			_slides_in_gesture += 1
			perform_swipe(pos, pos - _pointer_start)

func _release(pos: Vector2) -> void:
	var was_down: bool = _pointer_down
	_pointer_down = false
	_hold_duration = 0.0
	_hold_slide_progress = 0.0

	var dragged_entry: Dictionary = _dragging
	_dragging = {}

	var total_disp: float = pos.distance_to(_pointer_start)
	if total_disp >= SWIPE_THRESHOLD:
		_gesture_became_swipe = true

	if _gesture_became_swipe:
		# Classified strictly as a SWIPE (never increments _clicks).
		if not dragged_entry.is_empty():
			var s_note: Dictionary = dragged_entry["note"]
			if bool(s_note["slide"]) and not bool(s_note["done"]):
				var dx: float = pos.x - (dragged_entry["from"] as Vector2).x
				if absf(dx) >= SWIPE_THRESHOLD and signf(dx) == float(int(s_note["dir"])):
					_slides += 1
					_slides_in_gesture += 1
					_last_gesture = "SWIPE"
					_judge_at(s_note, float(dragged_entry.get("down_time", _time)))
					_spawn_burst(pos, 10, true)
					_add_popup(pos, "SWIPE!", Color(1.0, 0.90, 0.35))
					_update_hud("SWIPE!")
					return
				else:
					_resolve(s_note, "MISS")
		if _slides_in_gesture == 0 and was_down:
			perform_swipe(pos, pos - _pointer_start)
		return

	# Classified strictly as a SINGLE TAP (movement < 24 px and hold < 0.20s; never increments _slides).
	if not dragged_entry.is_empty():
		var note: Dictionary = dragged_entry["note"]
		if not bool(note["done"]):
			if bool(note["slide"]):
				# Single tap on a slide arrow note: distinguish from swipe!
				_clicks += 1
				_score += 1
				_last_gesture = "TAP_ON_SLIDE"
				_bounce_cookie(1.08)
				_spawn_burst(pos, 4, false)
				_add_popup(pos, "TAP! (SWIPE »)", Color(1.0, 0.72, 0.45))
				_sfx("click")
				_update_hud("SINGLE TAP — SWIPE ARROWS!")
				return
			else:
				_clicks += 1
				_last_gesture = "SINGLE TAP"
				_bounce_cookie(1.18)
				_judge_at(note, float(dragged_entry.get("down_time", _time)))
				return

	if was_down:
		perform_tap(pos, _pointer_down_time)

## Direct helper for single-tap / click (used by release of a tap or direct call).
func perform_click(pos: Vector2 = Vector2(640.0, 330.0)) -> void:
	perform_tap(pos, _time)

func perform_tap(pos: Vector2 = Vector2(640.0, 330.0), tap_time: float = -1.0) -> void:
	var eval_time: float = _time if tap_time < 0.0 else tap_time
	_clicks += 1
	_last_gesture = "SINGLE TAP"
	_bounce_cookie(1.18)
	var nearest: Dictionary = _nearest_active_tap_note(eval_time)
	if not nearest.is_empty():
		var dt: float = absf(float(nearest["time"]) - eval_time)
		if dt <= GOOD_WINDOW:
			_judge_at(nearest, eval_time)
			_spawn_burst(pos, 9, dt <= PERFECT_WINDOW)
			return
	var mult: int = _current_multiplier()
	var gain: int = 2 * mult
	_score += gain
	_combo += 1
	_best_combo = maxi(_best_combo, _combo)
	_spawn_burst(pos, 6, false)
	_add_popup(pos, "TAP +%d" % gain, Color(0.84, 0.97, 1.0))
	_sfx("click")
	_update_hud("SINGLE TAP +%d" % gain)

## Direct helper for swipe / slide churn (used by drag/hold or direct call).
func perform_slide(pos: Vector2 = Vector2(640.0, 330.0)) -> void:
	perform_swipe(pos, Vector2(80.0, 0.0))

func perform_swipe(pos: Vector2 = Vector2(640.0, 330.0), delta_vec: Vector2 = Vector2(80.0, 0.0)) -> void:
	_slides += 1
	_last_gesture = "SWIPE"
	_bounce_cookie(1.24)
	_cookie_angle = clampf(delta_vec.x / 320.0, -0.22, 0.22)
	var slide_note: Dictionary = _nearest_slide_note()
	if not slide_note.is_empty():
		_resolve(slide_note, "PERFECT")
	var mult: int = _current_multiplier()
	var gain: int = 6 * mult
	_score += gain
	_combo += 1
	_best_combo = maxi(_best_combo, _combo)
	_swipe_trail.append({"pos": pos - delta_vec * 0.5, "life": 0.40})
	_swipe_trail.append({"pos": pos, "life": 0.40})
	_spawn_burst(pos, 11, true)
	_add_popup(pos, "SWIPE +%d!" % gain, Color(1.0, 0.88, 0.32))
	_sfx("confirm")
	_update_hud("SWIPE CHURN +%d!" % gain)

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
		"color": Color(1.0, 0.88, 0.36, 0.9) if golden else Color(0.82, 0.96, 1.0, 0.88),
	})
	for i: int in count:
		var angle: float = randf() * TAU
		var speed: float = randf_range(95.0, 260.0)
		_particles.append({
			"pos": origin,
			"vel": Vector2(cos(angle) * speed, sin(angle) * speed - 110.0),
			"size": randf_range(5.0, 10.0),
			"life": randf_range(0.38, 0.70),
			"color": Color(1.0, 0.90, 0.42, 1.0) if golden else Color(0.90, 0.98, 1.0, 1.0),
		})

func _add_popup(origin: Vector2, text: String, col: Color) -> void:
	_popups.append({
		"pos": origin + Vector2(-90.0, -24.0),
		"text": text,
		"color": col,
		"life": 0.72,
	})

func _nearest_active_tap_note(eval_time: float) -> Dictionary:
	var best: Dictionary = {}
	var best_dt: float = MISS_WINDOW
	for note: Dictionary in _notes:
		if bool(note["done"]) or bool(note["slide"]):
			continue
		var dt: float = absf(float(note["time"]) - eval_time)
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
	_judge_at(note, _time)

func _judge_at(note: Dictionary, eval_time: float) -> void:
	var dt: float = absf(float(note["time"]) - eval_time)
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

func _play_style() -> String:
	if _clicks > 0 and _slides == 0:
		return "tap_only"
	if _slides > 0 and _clicks == 0:
		return "swipe_only"
	if _slides > _clicks and _clicks > 0:
		return "swipe_master"
	if _clicks > 0 and _slides > 0:
		return "balanced"
	return "none"

func _update_hud(verdict: String) -> void:
	_score_label.text = "Drops: %d  (Taps: %d | Swipes: %d)" % [_score, _clicks, _slides]
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
		if _last_gesture == "TAP_ON_SLIDE":
			_milka_line.text = "Milka: \"That was a single tap! Swipe or hold to slide the arrow~\""
			_milka_tex.texture = TEX_MILKA_SURPRISED
		elif _score >= 90:
			_milka_line.text = "Milka: \"GOLDEN CREAM FEVER! Taps & swipes overflowing!!\""
			_milka_tex.texture = TEX_MILKA_SURPRISED
		elif _last_gesture == "SWIPE":
			_milka_line.text = "Milka: \"Ooh, a golden swipe! Look at that butter swirl~!\""
			_milka_tex.texture = TEX_MILKA_SMILE
		elif _last_gesture == "SINGLE TAP":
			_milka_line.text = "Milka: \"Crisp single tap! Tap-tap-tap on the Milk Cookie~\""
			_milka_tex.texture = TEX_MILKA_SMILE
		else:
			_milka_line.text = "Milka: \"Single-tap the Cookie, or swipe/hold to churn~\""
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
		"style": _play_style(),
		"perfect": _perfect,
		"good": _good,
		"missed": _missed,
		"best_combo": _best_combo,
		"accuracy": accuracy,
		"rank": rank,
		"total": total,
	}
	_judge_label.text = "%s! %d Drops (%d Taps, %d Swipes)" % [rank, _score, _clicks, _slides]
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
