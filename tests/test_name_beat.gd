extends Node
## Headless probe for:
##   1) Mid-dialogue top-anchored NameEntry popout (layer 110 > VNBalloon layer 100,
##      with top margin for screen keyboard)
##   2) NameLore trait analysis & Milka's reactions (lowercase, digits, emoji, math, special, etc.)
##   3) Visual Cookie-Clicker + Rhythm Click & Optional Slide minigame with strict
##      Single Tap vs Swipe/Slide classification & reactions (mouse, touch & 1-key)
##   4) Full live vn_scene.tscn + vn_balloon.tscn play-through using real Viewport.push_input()
##      mouse clicks, mouse drags, and keyboard typing events.

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
	await _test_rhythm_visuals_and_tap_vs_swipe()
	await _test_rhythm_completion()
	await _test_dialogue_reactions()
	await _test_rhythm_style_dialogue_reactions()
	await _test_live_vn_scene_with_real_inputs()
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

func _click_at(pos: Vector2) -> void:
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = pos
	down.global_position = pos
	get_viewport().push_input(down, true)
	await get_tree().process_frame
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = pos
	up.global_position = pos
	get_viewport().push_input(up, true)
	await get_tree().process_frame

func _drag_mouse(from_pos: Vector2, to_pos: Vector2) -> void:
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = from_pos
	down.global_position = from_pos
	get_viewport().push_input(down, true)
	await get_tree().process_frame
	var move := InputEventMouseMotion.new()
	move.position = to_pos
	move.global_position = to_pos
	move.relative = to_pos - from_pos
	get_viewport().push_input(move, true)
	await get_tree().process_frame
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = to_pos
	up.global_position = to_pos
	get_viewport().push_input(up, true)
	await get_tree().process_frame

func _type_char(ch: String, keycode: Key = KEY_NONE) -> void:
	var code: int = ch.unicode_at(0) if ch.length() > 0 else 0
	var k := InputEventKey.new()
	k.pressed = true
	k.unicode = code
	k.keycode = keycode if keycode != KEY_NONE else (code as Key)
	k.physical_keycode = k.keycode
	get_viewport().push_input(k, true)
	await get_tree().process_frame
	var ku := InputEventKey.new()
	ku.pressed = false
	ku.unicode = code
	ku.keycode = k.keycode
	ku.physical_keycode = k.keycode
	get_viewport().push_input(ku, true)
	await get_tree().process_frame

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
	_check("popout is on layer >= 110 (above VNBalloon layer 100)", entry.layer >= 110)
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

func _test_rhythm_visuals_and_tap_vs_swipe() -> void:
	var game: CanvasLayer = RhythmScene.instantiate()
	game.set("note_count", 8)
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame

	_check("minigame is on layer >= 110 (above VNBalloon layer 100)", game.layer >= 110)
	var cookie_tex: TextureRect = game.get_node("Root/CenterStage/CookiePivot/CookieTexture")
	var milka_tex: TextureRect = game.get_node("Root/LeftCard/Rows/MilkaPortrait")
	var bottle_tex: TextureRect = game.get_node("Root/RightCard/Rows/Header/BottleIcon")
	var stage_canvas: Control = game.get_node("Root/StageCanvas")
	var cheer_label: Label = game.get_node("Root/LeftCard/Rows/CheerLabel")
	_check("visual Milk Cookie texture loaded", cookie_tex != null and cookie_tex.texture != null)
	_check("visual Milka cheerleader portrait loaded", milka_tex != null and milka_tex.texture != null)
	_check("visual Milk Churn bottle icon loaded", bottle_tex != null and bottle_tex.texture != null)
	_check("custom stage canvas present", stage_canvas != null and stage_canvas.visible)

	# 1. Mouse SINGLE TAP: press + release at same spot -> increments _clicks ONLY (never _slides)
	game.call("_press", Vector2(640.0, 330.0))
	_check("mouse press-down does not prematurely count as a tap before release", int(game.get("_clicks")) == 0 and int(game.get("_slides")) == 0)
	game.call("_release", Vector2(642.0, 330.0))
	_check("mouse single tap increments clicks=1 and slides=0", int(game.get("_clicks")) == 1 and int(game.get("_slides")) == 0)
	_check("Milka reacts specifically to single tap", String(game.get("_last_gesture")) == "SINGLE TAP" and cheer_label.text.to_lower().contains("single tap"))

	# 2. Mouse SWIPE / DRAG: press + motion >= 24px + release -> increments _slides ONLY (never _clicks!)
	var clicks_before_swipe: int = int(game.get("_clicks"))
	game.call("_press", Vector2(560.0, 330.0))
	game.call("_motion", Vector2(650.0, 330.0))
	game.call("_release", Vector2(650.0, 330.0))
	_check("mouse swipe increments slides without incrementing clicks", int(game.get("_slides")) == 1 and int(game.get("_clicks")) == clicks_before_swipe)
	_check("Milka reacts specifically to swipe and draws swipe trail", String(game.get("_last_gesture")) == "SWIPE" and cheer_label.text.to_lower().contains("swipe") and (game.get("_swipe_trail") as Array).size() > 0)

	# 3. 1-Button Keyboard SINGLE TAP vs HOLD-SLIDE:
	var c_before_k: int = int(game.get("_clicks"))
	var s_before_k: int = int(game.get("_slides"))
	game.call("press_one_button")
	_check("1-key press-down waits to classify tap vs hold-slide", int(game.get("_clicks")) == c_before_k and int(game.get("_slides")) == s_before_k)
	game.call("release_one_button")
	_check("1-key quick tap increments clicks only (slides unchanged)", int(game.get("_clicks")) == c_before_k + 1 and int(game.get("_slides")) == s_before_k)

	var c_before_hold: int = int(game.get("_clicks"))
	var s_before_hold: int = int(game.get("_slides"))
	game.call("hold_one_button", 0.62)
	_check("1-key hold increments slides only (clicks unchanged!)", int(game.get("_slides")) > s_before_hold and int(game.get("_clicks")) == c_before_hold)

	# 4. Mobile ScreenTouch SINGLE TAP vs ScreenDrag SWIPE:
	var c_before_touch: int = int(game.get("_clicks"))
	var s_before_touch: int = int(game.get("_slides"))
	var t_down := InputEventScreenTouch.new()
	t_down.pressed = true
	t_down.position = Vector2(640.0, 330.0)
	game.call("_on_gui_input", t_down)
	var t_up := InputEventScreenTouch.new()
	t_up.pressed = false
	t_up.position = Vector2(641.0, 330.0)
	game.call("_on_gui_input", t_up)
	_check("mobile touch tap increments clicks only (slides unchanged)", int(game.get("_clicks")) == c_before_touch + 1 and int(game.get("_slides")) == s_before_touch)

	var c_before_tdrag: int = int(game.get("_clicks"))
	var s_before_tdrag: int = int(game.get("_slides"))
	t_down.position = Vector2(570.0, 330.0)
	game.call("_on_gui_input", t_down)
	var t_drag := InputEventScreenDrag.new()
	t_drag.position = Vector2(660.0, 330.0)
	game.call("_on_gui_input", t_drag)
	t_up.position = Vector2(660.0, 330.0)
	game.call("_on_gui_input", t_up)
	_check("mobile touch drag increments slides only (clicks unchanged!)", int(game.get("_slides")) > s_before_tdrag and int(game.get("_clicks")) == c_before_tdrag)

	# 5. Single tap on an arrow slide note vs swiping it:
	var notes: Array = game.get("_notes")
	var slide_note: Dictionary = {}
	for n: Dictionary in notes:
		if bool(n["slide"]):
			slide_note = n
			break
	if not slide_note.is_empty():
		game.set("_time", float(slide_note["time"]))
		var sx: float = float(game.call("_lane_x", int(slide_note["lane"])))
		var sy: float = 540.0
		var s_before_arrow_tap: int = int(game.get("_slides"))
		game.call("_press", Vector2(sx, sy))
		game.call("_release", Vector2(sx, sy))
		_check("single tap on slide arrow note is NOT counted as a swipe and prompts user to swipe", int(game.get("_slides")) == s_before_arrow_tap and String(game.get("_last_gesture")) == "TAP_ON_SLIDE" and not bool(slide_note["done"]))
		var dir_sign: float = float(int(slide_note["dir"]))
		game.call("_press", Vector2(sx, sy))
		game.call("_motion", Vector2(sx + 75.0 * dir_sign, sy))
		game.call("_release", Vector2(sx + 75.0 * dir_sign, sy))
		_check("directional swipe on slide arrow note resolves it and increments slides", bool(slide_note["done"]) and int(game.get("_slides")) > s_before_arrow_tap)

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
		_check("result carries rank, clicks, slides, and style", String(result[0].get("rank", "")) != "" and result[0].has("slides") and result[0].has("style"))

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
		line = await dm.get_next_dialogue_line(DialogueRes, line.next_id)
	var joined: String = "\n".join(seen).to_lower()
	_check("dialogue interpolates the player name", joined.contains("boris42+🥛!"))
	_check("dialogue reacts to lowercase start", joined.contains("small letter"))
	_check("dialogue reacts to numbers", joined.contains("numbers hiding"))
	_check("dialogue reacts to emoji", joined.contains("emoji"))
	_check("dialogue reacts to math", joined.contains("arithmetic"))
	_check("dialogue reacts to special symbols", joined.contains("brackets and slashes"))
	_check("dialogue reaches the cookie-clicker rhythm offer", joined.contains("milk cookie"))

func _test_rhythm_style_dialogue_reactions() -> void:
	var dm: Node = get_tree().root.get_node("DialogueManager")
	_gs().set_player_name("Sonya")

	# 1. Tap-only result reaction
	_gs().record_rhythm_result({"score": 40, "clicks": 12, "slides": 0, "style": "tap_only", "missed": 0, "rank": "wobbly whisk"})
	var lines_tap: PackedStringArray = []
	var l1: DialogueLine = await dm.get_next_dialogue_line(DialogueRes, "rhythm_result")
	while l1 != null and l1.responses.is_empty():
		lines_tap.append(l1.text)
		l1 = await dm.get_next_dialogue_line(DialogueRes, l1.next_id)
	_check("dialogue reacts to tap_only play style", "\n".join(lines_tap).to_lower().contains("all single taps and zero swipes"))

	# 2. Swipe-only result reaction
	_gs().record_rhythm_result({"score": 60, "clicks": 0, "slides": 8, "style": "swipe_only", "missed": 0, "rank": "steady churner"})
	var lines_swipe: PackedStringArray = []
	var l2: DialogueLine = await dm.get_next_dialogue_line(DialogueRes, "rhythm_result")
	while l2 != null and l2.responses.is_empty():
		lines_swipe.append(l2.text)
		l2 = await dm.get_next_dialogue_line(DialogueRes, l2.next_id)
	_check("dialogue reacts to swipe_only play style", "\n".join(lines_swipe).to_lower().contains("all swipes and not a single tap"))

func _test_live_vn_scene_with_real_inputs() -> void:
	_gs().reset()
	var vn: Node = (load("res://scenes/vn_scene.tscn") as PackedScene).instantiate()
	add_child(vn)
	for i in 15:
		await get_tree().process_frame
	var balloon: CanvasLayer = get_tree().current_scene.get_node_or_null("VNBalloon")
	_check("live VNScene spawned VNBalloon", balloon != null)
	if balloon == null:
		return

	for step in 20:
		if _mg().active_name_prompt != null:
			break
		await _click_at(Vector2(640.0, 600.0))
		for f_i in 4:
			await get_tree().process_frame

	var prompt: CanvasLayer = _mg().active_name_prompt
	_check("live game opened NameEntry above VNBalloon", prompt != null and prompt.layer > balloon.layer)
	if prompt == null:
		return

	var field: LineEdit = prompt.call("get_field")
	var confirm: Button = prompt.call("get_confirm_button")
	for ch_pair in [["m", KEY_M], ["i", KEY_I], ["s", KEY_S], ["h", KEY_H], ["a", KEY_A], ["7", KEY_7], ["+", KEY_EQUAL]]:
		await _type_char(ch_pair[0], ch_pair[1])
	_check("real keyboard typing entered 'misha7+' into LineEdit", field.text == "misha7+")
	_check("typing 'h' into LineEdit did not open VNBalloon history", not (balloon.get("history_panel") as Control).visible)

	await _click_at(confirm.get_global_rect().get_center())
	for f_i in 10:
		await get_tree().process_frame
	_check("real mouse click on Tell Milka confirmed name and resumed VNBalloon", _mg().active_name_prompt == null and _gs().player_name == "misha7+")

	for step in 50:
		if (balloon.get("responses_menu") as Control).visible:
			break
		await _click_at(Vector2(640.0, 600.0))
		for f_i in 4:
			await get_tree().process_frame

	var rmenu: Control = balloon.get("responses_menu")
	_check("live game reached rhythm choices", rmenu.visible and rmenu.get_child_count() >= 2)
	await get_tree().process_frame
	var choice_btn: Control = rmenu.get_child(1)
	await _click_at(choice_btn.get_global_rect().get_center())
	for step in 10:
		if _mg().is_playing:
			break
		await _click_at(Vector2(640.0, 600.0))
		for f_i in 4:
			await get_tree().process_frame

	var rgame: CanvasLayer = _mg().active_rhythm_game
	_check("live game launched RhythmGame above VNBalloon", _mg().is_playing and rgame != null and rgame.layer > balloon.layer)
	if rgame != null:
		await _click_at(Vector2(640.0, 320.0))
		_check("live single click counted as 1 tap and 0 swipes", int(rgame.get("_clicks")) == 1 and int(rgame.get("_slides")) == 0)
		await _drag_mouse(Vector2(560.0, 320.0), Vector2(700.0, 320.0))
		_check("live mouse drag counted as 1 swipe and did not increment taps", int(rgame.get("_slides")) == 1 and int(rgame.get("_clicks")) == 1)
		await _type_char(" ", KEY_SPACE)
		_check("live Space key tap counted as 2nd tap and kept swipes at 1", int(rgame.get("_clicks")) == 2 and int(rgame.get("_slides")) == 1)
		var serve_btn: Button = rgame.get_node("Root/RightCard/Rows/ServeButton")
		await _click_at(serve_btn.get_global_rect().get_center())
		for f_i in 15:
			await get_tree().process_frame
		_check("real mouse click on Serve Milk finished minigame and recorded balanced style", not _mg().is_playing and _gs().rhythm_clicks() == 2 and _gs().rhythm_slides() == 1 and _gs().rhythm_style() == "balanced")

	vn.queue_free()
	if is_instance_valid(balloon):
		balloon.queue_free()
	await get_tree().process_frame
