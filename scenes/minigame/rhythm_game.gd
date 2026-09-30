extends CanvasLayer
## "Milk Beat" - a small rhythm minigame with two note kinds:
##   tap   : click (or tap) the droplet when it reaches the cream line
##   slide : press the droplet and flick it left or right along the line
##
## The lanes, the cream line, the HUD and the note template are AUTHORED in
## rhythm_game.tscn. This script only spawns copies of the template and judges
## the input, so the look can be edited in the editor.

signal finished(result: Dictionary)

const LANES: int = 4
const FALL_TIME: float = 1.6          ## seconds a note needs to reach the line
const PERFECT_WINDOW: float = 0.12
const GOOD_WINDOW: float = 0.26
const MISS_WINDOW: float = 0.34
const SLIDE_DISTANCE: float = 64.0    ## pixels a slide note must be flicked
const LEAD_IN: float = 2.0

@export var note_count: int = 18
@export var beat_length: float = 0.55

@onready var _root: Control = $Root
@onready var _lanes: Control = $Root/Play/Lanes
@onready var _notes_layer: Control = $Root/Play/Notes
@onready var _hit_line: ColorRect = $Root/Play/HitLine
@onready var _note_template: Control = $Root/Play/NoteTemplate
@onready var _score_label: Label = $Root/Hud/Top/Score
@onready var _combo_label: Label = $Root/Hud/Top/Combo
@onready var _judge_label: Label = $Root/Hud/Judge
@onready var _title_label: Label = $Root/Hud/Top/Title

var _time: float = 0.0
var _running: bool = false
var _notes: Array[Dictionary] = []
var _score: int = 0
var _combo: int = 0
var _best_combo: int = 0
var _perfect: int = 0
var _good: int = 0
var _missed: int = 0
var _dragging: Dictionary = {}

func _ready() -> void:
	_note_template.visible = false
	_root.gui_input.connect(_on_gui_input)
	_build_chart()
	_spawn_notes()
	_update_hud("")
	_running = true

func start_with_seed(seed_value: int, notes: int = 18) -> void:
	note_count = notes
	seed(seed_value)

func _build_chart() -> void:
	_notes.clear()
	var t: float = LEAD_IN
	for i: int in note_count:
		var is_slide: bool = i > 3 and (i % 4 == 3)
		var lane: int = randi() % LANES
		if is_slide:
			lane = clampi(lane, 1, LANES - 2)
		_notes.append({
			"time": t,
			"lane": lane,
			"slide": is_slide,
			"dir": 1 if randi() % 2 == 0 else -1,
			"done": false,
			"node": null,
		})
		t += beat_length * (1.0 if i % 8 != 7 else 2.0)

func _spawn_notes() -> void:
	for note: Dictionary in _notes:
		var n: Control = _note_template.duplicate()
		n.visible = true
		_notes_layer.add_child(n)
		note["node"] = n
		var label: Label = n.get_node("Glyph")
		if bool(note["slide"]):
			label.text = "»" if int(note["dir"]) > 0 else "«"
			n.modulate = Color(0.78, 0.9, 1.0)
		else:
			label.text = "o"
			n.modulate = Color(1.0, 0.97, 0.86)

func _process(delta: float) -> void:
	if not _running:
		return
	_time += delta
	var remaining: int = 0
	for note: Dictionary in _notes:
		var n: Control = note["node"]
		if n == null:
			continue
		if bool(note["done"]):
			continue
		remaining += 1
		var dt: float = float(note["time"]) - _time
		n.position = Vector2(_lane_x(int(note["lane"])) - n.size.x * 0.5, _note_y(dt))
		if dt < -MISS_WINDOW:
			_resolve(note, "MISS")
	if remaining == 0:
		_finish()

func _lane_x(lane: int) -> float:
	var w: float = _lanes.size.x if _lanes.size.x > 1.0 else _root.size.x
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
	elif event is InputEventMouseMotion and not _dragging.is_empty():
		_motion((event as InputEventMouseMotion).position)

func _press(pos: Vector2) -> void:
	var note: Dictionary = _note_at(pos)
	if note.is_empty():
		return
	if bool(note["slide"]):
		_dragging = {"note": note, "from": pos}
	else:
		_judge(note)

func _motion(pos: Vector2) -> void:
	if _dragging.is_empty():
		return
	var note: Dictionary = _dragging["note"]
	var from: Vector2 = _dragging["from"]
	var dx: float = pos.x - from.x
	if absf(dx) >= SLIDE_DISTANCE and signf(dx) == float(int(note["dir"])):
		_dragging = {}
		_judge(note)

func _release(_pos: Vector2) -> void:
	if _dragging.is_empty():
		return
	var note: Dictionary = _dragging["note"]
	_dragging = {}
	_resolve(note, "MISS")

func _note_at(pos: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_dt: float = MISS_WINDOW
	for note: Dictionary in _notes:
		if bool(note["done"]):
			continue
		var dt: float = absf(float(note["time"]) - _time)
		if dt > MISS_WINDOW:
			continue
		if absf(_lane_x(int(note["lane"])) - pos.x) > (_root.size.x / float(LANES)) * 0.6:
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
	match verdict:
		"PERFECT":
			_perfect += 1
			_combo += 1
			_score += 100 + _combo * 5
		"GOOD":
			_good += 1
			_combo += 1
			_score += 50 + _combo * 2
		_:
			_missed += 1
			_combo = 0
	_best_combo = maxi(_best_combo, _combo)
	_update_hud(verdict)

func _update_hud(verdict: String) -> void:
	_score_label.text = "Score %d" % _score
	_combo_label.text = "Combo %d" % _combo
	_title_label.text = "Milk Beat"
	if verdict != "":
		_judge_label.text = verdict

func _finish() -> void:
	if not _running:
		return
	_running = false
	var total: int = _notes.size()
	var hits: int = _perfect + _good
	var accuracy: float = (float(hits) / float(maxi(total, 1))) * 100.0
	var rank: String = "milk puddle"
	if accuracy >= 95.0:
		rank = "cream legend"
	elif accuracy >= 75.0:
		rank = "steady churner"
	elif accuracy >= 45.0:
		rank = "wobbly whisk"
	var result: Dictionary = {
		"score": _score,
		"perfect": _perfect,
		"good": _good,
		"missed": _missed,
		"best_combo": _best_combo,
		"accuracy": accuracy,
		"rank": rank,
		"total": total,
	}
	_judge_label.text = "%s! %d points" % [rank, _score]
	await get_tree().create_timer(1.2).timeout
	finished.emit(result)
	queue_free()
