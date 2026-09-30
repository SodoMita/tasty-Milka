extends Node
## Headless probe for:
##   1) Mid-dialogue top-anchored NameEntry popout (with top margin for screen keyboard)
##   2) NameLore trait analysis & Milka's reactions (lowercase, digits, emoji, math, special, etc.)
##   3) Visual Cookie-Clicker + Rhythm Click & Optional Slide minigame (mouse-only & 1-key-only)

const Lore = preload("res://autoloads/name_lore.gd")
const NameEntryScene: PackedScene = preload("res://scenes/ui/name_entry.tscn")
const RhythmScene: PackedScene = preload("res://scenes/minigame/rhythm_game.tscn")
const DialogueRes: DialogueResource = preload("res://dialogue/milka.dialogue")

var _passed: int = 0
var _failed: int = 0

func _ready() -> void:
	await get_tree().process_frame
	_test_name_lore()
	await _test_name_entry_top_popout()
	await _test_mid_dialogue_name_ask()
	await _test_rhythm_visuals_and_controls()
	await _test_rhythm_completion()
	await _test_dialogue_reactions()
	print("== name/beat probe: %d passed, %d failed ==" % [_passed, _failed])
	get_tree().quit(1 if _failed > 0 else 0)

func _gs() -> Node:
	return get_tree().root.get_node_or_null("GameState")

func _mg() -> Node:
	return get_tree().root.get_node_or_null("Minigame")

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

func _test_name_entry_top_popout() -> void:
	var entry: CanvasLayer = NameEntryScene.instantiate()
	add_child(entry)
	await get_tree().process_frame
	var top_margin: MarginContainer = entry.get_node("Root/TopMargin")
	var field: LineEdit = entry.call("get_field")
	var confirm: Button = entry.call("get_confirm_button")
	var margin_top_px: int = int(entry.call("get_top_margin"))
	_check("popout has top margin for screen keyboard", margin_top_px >= 24)
	_check("popout sits in top area of screen (keyboard-safe)", top_margin.offset_bottom <= 280.0 and top_margin.anchor_top == 0.0)
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

func _test_mid_dialogue_name_ask() -> void:
	var dm: Node = get_tree().root.get_node("DialogueManager")
	# Walk from ~ start; verify Milka speaks first and then triggers ask_player_name mid-dialogue.
	var line: DialogueLine = await dm.get_next_dialogue_line(DialogueRes, "start")
	var before_ask_lines: int = 0
	var prompted: Array = []
	_mg().name_prompt_opened.connect(func(prompt: CanvasLayer) -> void:
		var f: LineEdit = prompt.call("get_field")
		var c: Button = prompt.call("get_confirm_button")
		f.text = "misha+7🥛!"
		f.text_changed.emit(f.text)
		c.pressed.emit()
	, CONNECT_ONE_SHOT)
	_mg().name_prompt_finished.connect(func(chosen: String) -> void:
		prompted.append(chosen)
	, CONNECT_ONE_SHOT)
	var guard: int = 0
	while line != null and guard < 10 and prompted.is_empty():
		guard += 1
		before_ask_lines += 1
		line = await dm.get_next_dialogue_line(DialogueRes, line.next_id)
	_check("Milka speaks several lines before asking name mid-game", before_ask_lines >= 4)
	_check("mid-dialogue name prompt acquired player name", prompted.size() == 1 and prompted[0] == "misha+7🥛!" and _gs().player_name == "misha+7🥛!")
	_check("line after prompt uses acquired player name", line != null and line.text.contains("misha+7🥛!"))

func _test_rhythm_visuals_and_controls() -> void:
	var game: CanvasLayer = RhythmScene.instantiate()
	game.set("note_count", 8)
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame

	# 1. Verify rich visual elements exist
	var cookie_tex: TextureRect = game.get_node("Root/CenterStage/CookiePivot/CookieTexture")
	var milka_tex: TextureRect = game.get_node("Root/LeftCard/Rows/MilkaPortrait")
	var bottle_tex: TextureRect = game.get_node("Root/RightCard/Rows/Header/BottleIcon")
	var stage_canvas: Control = game.get_node("Root/StageCanvas")
	_check("visual Milk Cookie texture loaded", cookie_tex != null and cookie_tex.texture != null)
	_check("visual Milka cheerleader portrait loaded", milka_tex != null and milka_tex.texture != null)
	_check("visual Milk Churn bottle icon loaded", bottle_tex != null and bottle_tex.texture != null)
	_check("custom stage canvas present", stage_canvas != null and stage_canvas.visible)

	# 2. Verify Mouse-only Cookie Click + Mouse Drag Optional Slide
	var s0: int = int(game.get("_score"))
	game.call("perform_click", Vector2(640.0, 330.0))
	var s1: int = int(game.get("_score"))
	_check("mouse cookie click scores drops & spawns particles", s1 > s0 and (game.get("_particles") as Array).size() > 0)

	var slides_before: int = int(game.get("_slides"))
	game.call("_press", Vector2(580.0, 330.0))
	game.call("_motion", Vector2(660.0, 330.0))
	game.call("_release", Vector2(660.0, 330.0))
	_check("mouse drag triggers optional slide churn bonus", int(game.get("_slides")) > slides_before and int(game.get("_score")) > s1)

	# 3. Verify 1-Button Keyboard-Only: tap to click, hold same button to slide
	var clicks_before: int = int(game.get("_clicks"))
	var score_before_key: int = int(game.get("_score"))
	game.call("press_one_button")
	game.call("release_one_button")
	_check("1-button keyboard tap clicks cookie", int(game.get("_clicks")) > clicks_before and int(game.get("_score")) > score_before_key)

	var slides_before_key: int = int(game.get("_slides"))
	var score_before_hold: int = int(game.get("_score"))
	game.call("hold_one_button", 0.62)
	_check("1-button keyboard hold performs slide churn", int(game.get("_slides")) > slides_before_key and int(game.get("_score")) > score_before_hold)

	# 4. Verify Mobile Touch & Drag accessibility
	var touch_down := InputEventScreenTouch.new()
	touch_down.pressed = true
	touch_down.position = Vector2(600.0, 330.0)
	var score_before_touch: int = int(game.get("_score"))
	game.call("_on_gui_input", touch_down)
	_check("mobile screen touch taps cookie", int(game.get("_score")) > score_before_touch)
	var slides_before_drag: int = int(game.get("_slides"))
	var touch_drag := InputEventScreenDrag.new()
	touch_drag.position = Vector2(680.0, 330.0)
	game.call("_on_gui_input", touch_drag)
	var touch_up := InputEventScreenTouch.new()
	touch_up.pressed = false
	touch_up.position = Vector2(680.0, 330.0)
	game.call("_on_gui_input", touch_up)
	_check("mobile screen drag triggers slide churn", int(game.get("_slides")) > slides_before_drag)

	game.queue_free()
	await get_tree().process_frame

func _test_rhythm_completion() -> void:
	var game: CanvasLayer = RhythmScene.instantiate()
	game.set("note_count", 8)
	game.set("beat_length", 0.05)
	add_child(game)
	await get_tree().process_frame
	var notes: Array = game.get("_notes")
	_check("chart built with 8 beats", notes.size() == 8)
	var has_slide: bool = false
	for n: Dictionary in notes:
		if bool(n["slide"]):
			has_slide = true
	_check("chart includes optional slide cues", has_slide)
	var result: Array = []
	game.finished.connect(func(r: Dictionary) -> void: result.append(r))
	var guard: int = 0
	while result.is_empty() and guard < 900:
		guard += 1
		await get_tree().process_frame
	_check("minigame finishes cleanly", result.size() == 1)
	if result.size() == 1:
		_check("result carries rank and stats", String(result[0].get("rank", "")) != "" and result[0].has("slides"))

func _test_dialogue_reactions() -> void:
	_gs().set_player_name("boris42+🥛!")
	var dm: Node = get_tree().root.get_node("DialogueManager")
	var seen: PackedStringArray = []
	var line: DialogueLine = await dm.get_next_dialogue_line(DialogueRes, "name_reaction")
	var guard: int = 0
	while line != null and guard < 60:
		guard += 1
		seen.append(line.text)
		if not line.responses.is_empty():
			break
		print("    step ", guard, " id=", line.id, " next=", line.next_id, " text=", line.text)
		line = await dm.get_next_dialogue_line(DialogueRes, line.next_id)
	var joined: String = "\n".join(seen).to_lower()
	_check("dialogue interpolates the player name", joined.contains("boris42+🥛!"))
	_check("dialogue reacts to lowercase start", joined.contains("small letter"))
	_check("dialogue reacts to numbers", joined.contains("numbers hiding"))
	_check("dialogue reacts to emoji", joined.contains("emoji"))
	_check("dialogue reacts to math", joined.contains("arithmetic"))
	_check("dialogue reacts to special symbols", joined.contains("brackets and slashes"))
	_check("dialogue reaches the cookie-clicker rhythm offer", joined.contains("milk cookie"))
