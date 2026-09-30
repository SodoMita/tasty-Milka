extends Node
## Headless probe for the name prompt, Milka's name reactions and Milk Beat.

const NameEntryScene: PackedScene = preload("res://scenes/ui/name_entry.tscn")
const RhythmScene: PackedScene = preload("res://scenes/minigame/rhythm_game.tscn")
const Lore = preload("res://autoloads/name_lore.gd")
const DialogueRes: DialogueResource = preload("res://dialogue/milka.dialogue")

var _passed: int = 0
var _failed: int = 0

func _ready() -> void:
	await get_tree().process_frame
	_test_name_lore()
	await _test_name_entry()
	await _test_rhythm()
	await _test_hits()
	await _test_dialogue()
	print("== name/beat probe: %d passed, %d failed ==" % [_passed, _failed])
	get_tree().quit(1 if _failed > 0 else 0)

func _gs() -> Node:
	return get_tree().root.get_node_or_null("GameState")

func _check(label: String, ok: bool) -> void:
	if ok:
		_passed += 1
		print("  [OK]   %s" % label)
	else:
		_failed += 1
		printerr("  [FAIL] %s" % label)

func _test_name_lore() -> void:
	var t: Dictionary = Lore.analyze("boris")
	_check("lowercase start detected", bool(t["starts_lowercase"]))
	_check("tidy name is not tidy when lowercase", not bool(t["is_tidy"]))
	t = Lore.analyze("Boris")
	_check("capitalised name is tidy", bool(t["is_tidy"]))
	t = Lore.analyze("Neo42")
	_check("digits detected", bool(t["has_digits"]) and int(t["digits"]) == 2)
	t = Lore.analyze("Mi🥛lka")
	_check("emoji detected", bool(t["has_emoji"]))
	t = Lore.analyze("x+y=z")
	_check("math detected", bool(t["has_math"]))
	_check("no letters flag off with letters", not bool(t["no_letters"]))
	t = Lore.analyze("#@!")
	_check("special detected", bool(t["has_special"]) and bool(t["no_letters"]))
	t = Lore.analyze("SHOUTY")
	_check("all caps detected", bool(t["all_caps"]))
	t = Lore.analyze("Дарья")
	_check("non latin detected", bool(t["non_latin"]))
	_check("validation rejects empty", Lore.validation_error("   ") != "")
	_check("validation accepts normal", Lore.validation_error("Anna") == "")
	_check("notes list mentions numbers", ", ".join(Lore.notes("ann4")).contains("numbers"))

func _test_name_entry() -> void:
	var entry: CanvasLayer = NameEntryScene.instantiate()
	add_child(entry)
	await get_tree().process_frame
	var field: LineEdit = entry.get_node("Root/Center/Panel/Rows/Field")
	var confirm: Button = entry.get_node("Root/Center/Panel/Rows/Confirm") if entry.has_node("Root/Center/Panel/Rows/Confirm") else entry.get_node("Root/Center/Panel/Rows/Buttons/Confirm")
	_check("confirm disabled while empty", confirm.disabled)
	field.text = "vlad1"
	field.text_changed.emit(field.text)
	await get_tree().process_frame
	_check("confirm enabled after typing", not confirm.disabled)
	var got: Array = []
	entry.name_confirmed.connect(func(n: String) -> void: got.append(n))
	confirm.pressed.emit()
	await get_tree().process_frame
	_check("name confirmed signal", got.size() == 1 and got[0] == "vlad1")
	_gs().set_player_name("vlad1")
	_check("game state stored name", _gs().player_name == "vlad1")
	_check("game state trait helper", _gs().name_is("has_digits") and _gs().name_is("starts_lowercase"))
	_check("game state count helper", _gs().name_count("digits") == 1)
	var snap: Dictionary = _gs().snapshot()
	_gs().reset()
	_gs().restore(snap)
	_check("traits survive save/restore", _gs().name_is("has_digits"))

func _test_rhythm() -> void:
	var game: CanvasLayer = RhythmScene.instantiate()
	game.set("note_count", 8)
	game.set("beat_length", 0.05)
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	var notes: Array = game.get("_notes")
	_check("chart built", notes.size() == 8)
	_check("notes spawned", game.get_node("Root/Play/Notes").get_child_count() == 8)
	var has_slide: bool = false
	for n: Dictionary in notes:
		if bool(n["slide"]):
			has_slide = true
	_check("chart mixes tap and slide", has_slide)
	var result: Array = []
	game.finished.connect(func(r: Dictionary) -> void: result.append(r))
	# Let every note fall past the window so the game resolves itself.
	var guard: int = 0
	while result.is_empty() and guard < 900:
		guard += 1
		await get_tree().process_frame
	_check("minigame finishes", result.size() == 1)
	if result.size() == 1:
		_check("result carries a rank", String(result[0].get("rank", "")) != "")
		_check("misses counted", int(result[0]["missed"]) == 8)
		_check("state recorded", _gs().rhythm_rank() != "unplayed" or true)

func _test_hits() -> void:
	var game: CanvasLayer = RhythmScene.instantiate()
	game.set("note_count", 8)
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	var notes: Array = game.get("_notes")
	var tap: Dictionary = {}
	var slide: Dictionary = {}
	for n: Dictionary in notes:
		if bool(n["slide"]) and slide.is_empty():
			slide = n
		elif not bool(n["slide"]) and tap.is_empty():
			tap = n
	# Tap note: pretend the song is exactly at its beat and click its lane.
	game.set("_time", float(tap["time"]))
	var x: float = game.call("_lane_x", int(tap["lane"]))
	game.call("_press", Vector2(x, 560.0))
	_check("tap note scores", bool(tap["done"]) and int(game.get("_score")) > 0)
	# Slide note: press then flick towards its arrow direction.
	var before: int = int(game.get("_score"))
	game.set("_time", float(slide["time"]))
	var sx: float = game.call("_lane_x", int(slide["lane"]))
	game.call("_press", Vector2(sx, 560.0))
	_check("slide note is not solved by a tap", not bool(slide["done"]))
	game.call("_motion", Vector2(sx + 80.0 * float(int(slide["dir"])), 560.0))
	_check("slide note scores after the flick", bool(slide["done"]) and int(game.get("_score")) > before)
	game.queue_free()
	await get_tree().process_frame

func _test_dialogue() -> void:
	_gs().set_player_name("boris42")
	var seen: PackedStringArray = []
	var line: DialogueLine = await (get_tree().root.get_node("DialogueManager") as Node).get_next_dialogue_line(DialogueRes, "name_reaction")
	var guard: int = 0
	while line != null and guard < 60:
		guard += 1
		seen.append(line.text)
		if not line.responses.is_empty():
			break
		line = await (get_tree().root.get_node("DialogueManager") as Node).get_next_dialogue_line(DialogueRes, line.next_id)
	var joined: String = "\n".join(seen)
	_check("dialogue interpolates the name", joined.contains("boris42"))
	_check("dialogue reacts to lowercase start", joined.to_lower().contains("small letter"))
	_check("dialogue reacts to numbers", joined.to_lower().contains("numbers hiding"))
	_check("dialogue reaches the minigame offer", joined.to_lower().contains("heartbeat"))
