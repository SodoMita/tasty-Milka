extends Node
## Headless probe for:
##   1) Mid-dialogue top-anchored NameEntry popout (layer 110 > VNBalloon layer 100,
##      with top margin for screen keyboard)
##   2) NameLore trait analysis & Milka's reactions (lowercase, digits, emoji, math, special, etc.)
##   3) Visual Cookie-Clicker + Rhythm Click & Optional Slide minigame (mouse, touch & 1-key)
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
	await _test_rhythm_visuals_and_controls()
	await _test_rhythm_completion()
	await _test_dialogue_reactions()
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

func _test_rhythm_visuals_and_controls() -> void:
	var game: CanvasLayer = RhythmScene.instantiate()
	game.set("note_count", 8)
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame

	_check("minigame is on layer >= 110 (above VNBalloon layer 100)", game.layer >= 110)
	var cookie_tex: TextureRect = game.get_node("Root/CenterStage/CookiePivot/CookieTexture")
	var milka_tex: TextureRect = game.get_node("Root/LeftCard/Rows/MilkaPortrait")
	var milka_cheer: Label = game.get_node("Root/LeftCard/Rows/CheerLabel")
	var bottle_tex: TextureRect = game.get_node("Root/RightCard/Rows/Header/BottleIcon")
	var stage_canvas: Control = game.get_node("Root/StageCanvas")
	_check("visual Milk Cookie texture loaded", cookie_tex != null and cookie_tex.texture != null)
	_check("visual Milka cheerleader portrait loaded", milka_tex != null and milka_tex.texture != null)
	_check("visual Milk Churn bottle icon loaded", bottle_tex != null and bottle_tex.texture != null)
	_check("custom stage canvas present", stage_canvas != null and stage_canvas.visible)

	var cookie_center: Vector2 = game.call("_cookie_center")
	var s0: int = int(game.get("_score"))
	game.call("perform_click", cookie_center)
	var s1: int = int(game.get("_score"))
	_check("mouse cookie click scores drops & spawns particles", s1 > s0 and (game.get("_particles") as Array).size() > 0)

	# Mouse tap is classified only on release. Tiny pointer jitter remains a tap.
	var clicks_before_tap: int = int(game.get("_clicks"))
	var slides_before_tap: int = int(game.get("_slides"))
	var score_before_tap: int = int(game.get("_score"))
	game.call("_press", cookie_center)
	_check("mouse-down alone does not prematurely score a tap", int(game.get("_clicks")) == clicks_before_tap and int(game.get("_score")) == score_before_tap)
	game.call("_motion", cookie_center + Vector2(8.0, 3.0))
	game.call("_release", cookie_center + Vector2(8.0, 3.0))
	_check("small-jitter release becomes exactly one tap", int(game.get("_clicks")) == clicks_before_tap + 1 and int(game.get("_slides")) == slides_before_tap)
	_check("Milka reacts specifically to the tap", milka_cheer.text.contains("One clean tap"))

	# Crossing the swipe threshold suppresses the pending tap.
	var clicks_before_swipe: int = int(game.get("_clicks"))
	var slides_before_swipe: int = int(game.get("_slides"))
	var score_before_swipe: int = int(game.get("_score"))
	game.call("_press", cookie_center - Vector2(40.0, 0.0))
	game.call("_motion", cookie_center + Vector2(40.0, 0.0))
	game.call("_release", cookie_center + Vector2(40.0, 0.0))
	_check("mouse swipe grants slide bonus", int(game.get("_slides")) > slides_before_swipe and int(game.get("_score")) > score_before_swipe)
	_check("same mouse swipe does not also count as a tap", int(game.get("_clicks")) == clicks_before_swipe)
	_check("Milka reacts specifically to the swipe", milka_cheer.text.contains("That was a swipe"))

	# A medium ambiguous move is cancelled instead of being guessed as a tap.
	var clicks_before_cancel: int = int(game.get("_clicks"))
	var slides_before_cancel: int = int(game.get("_slides"))
	game.call("_press", cookie_center)
	game.call("_motion", cookie_center + Vector2(34.0, 0.0))
	game.call("_release", cookie_center + Vector2(34.0, 0.0))
	_check("ambiguous movement is neither tap nor swipe", int(game.get("_clicks")) == clicks_before_cancel and int(game.get("_slides")) == slides_before_cancel)
	_check("Milka explains the cancelled ambiguous gesture", milka_cheer.text.contains("between a tap and swipe"))

	var clicks_before_key: int = int(game.get("_clicks"))
	var score_before_key: int = int(game.get("_score"))
	game.call("press_one_button")
	_check("key-down waits before deciding tap versus hold", int(game.get("_clicks")) == clicks_before_key and int(game.get("_score")) == score_before_key)
	game.call("release_one_button")
	_check("quick key release becomes exactly one tap", int(game.get("_clicks")) == clicks_before_key + 1 and int(game.get("_score")) > score_before_key)

	var clicks_before_hold: int = int(game.get("_clicks"))
	var slides_before_key: int = int(game.get("_slides"))
	var score_before_hold: int = int(game.get("_score"))
	game.call("hold_one_button", 0.62)
	_check("1-button keyboard hold performs slide churn", int(game.get("_slides")) > slides_before_key and int(game.get("_score")) > score_before_hold)
	_check("keyboard hold suppresses its pending tap", int(game.get("_clicks")) == clicks_before_hold)
	_check("Milka reacts specifically to held-key slide", milka_cheer.text.contains("held key"))

	# Touch follows exactly the same down/move/up classifier.
	var touch_down := InputEventScreenTouch.new()
	touch_down.pressed = true
	touch_down.position = cookie_center - Vector2(20.0, 0.0)
	var score_before_touch: int = int(game.get("_score"))
	var clicks_before_touch: int = int(game.get("_clicks"))
	game.call("_on_gui_input", touch_down)
	_check("touch-down alone does not prematurely score", int(game.get("_score")) == score_before_touch)
	var touch_up_tap := InputEventScreenTouch.new()
	touch_up_tap.pressed = false
	touch_up_tap.position = cookie_center - Vector2(20.0, 0.0)
	game.call("_on_gui_input", touch_up_tap)
	_check("touch release becomes exactly one tap", int(game.get("_clicks")) == clicks_before_touch + 1)

	var touch_swipe_down := InputEventScreenTouch.new()
	touch_swipe_down.pressed = true
	touch_swipe_down.position = cookie_center - Vector2(45.0, 0.0)
	game.call("_on_gui_input", touch_swipe_down)
	var slides_before_drag: int = int(game.get("_slides"))
	var clicks_before_drag: int = int(game.get("_clicks"))
	var touch_drag := InputEventScreenDrag.new()
	touch_drag.position = cookie_center + Vector2(45.0, 0.0)
	game.call("_on_gui_input", touch_drag)
	var touch_up := InputEventScreenTouch.new()
	touch_up.pressed = false
	touch_up.position = cookie_center + Vector2(45.0, 0.0)
	game.call("_on_gui_input", touch_up)
	_check("mobile screen swipe triggers slide churn", int(game.get("_slides")) > slides_before_drag)
	_check("mobile screen swipe does not also tap", int(game.get("_clicks")) == clicks_before_drag)

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
		_check("result carries rank, tap/swipe stats, and style", String(result[0].get("rank", "")) != "" and result[0].has("clicks") and result[0].has("slides") and result[0].has("style"))

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

	_gs().record_rhythm_result({"score": 24, "clicks": 12, "slides": 0, "style": "tap_only", "missed": 1, "rank": "wobbly whisk"})
	var tap_result: DialogueLine = await dm.get_next_dialogue_line(DialogueRes, "rhythm_result")
	var tap_result_text: PackedStringArray = []
	var tap_guard: int = 0
	while tap_result != null and tap_guard < 6:
		tap_guard += 1
		tap_result_text.append(tap_result.text)
		if not tap_result.responses.is_empty():
			break
		tap_result = await dm.get_next_dialogue_line(DialogueRes, tap_result.next_id)
	_check("result dialogue reports separate tap/swipe totals", "\n".join(tap_result_text).contains("12 single taps, 0 swipes"))
	_check("result dialogue reacts to tap-only style", "\n".join(tap_result_text).contains("All single taps and zero swipes"))

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

	# 1. Click through opening lines with real mouse clicks until NameEntry appears
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

	# 2. Click through Milka's reactions until the choices menu is visible
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
		var live_cookie_local: Vector2 = rgame.call("_cookie_center")
		var live_cookie_viewport: Vector2 = rgame.transform * live_cookie_local
		await _click_at(live_cookie_viewport)
		var swipe_delta: Vector2 = (rgame.transform.basis_xform(Vector2(75.0, 0.0)))
		await _drag_mouse(live_cookie_viewport - swipe_delta, live_cookie_viewport + swipe_delta)
		await _type_char(" ", KEY_SPACE)
		_check("live RhythmGame distinguished real tap, swipe, and Space tap", int(rgame.get("_score")) > 0 and int(rgame.get("_slides")) >= 1 and int(rgame.get("_clicks")) >= 2)
		var serve_btn: Button = rgame.get_node("Root/RightCard/Rows/ServeButton")
		await _click_at(serve_btn.get_global_rect().get_center())
		for f_i in 15:
			await get_tree().process_frame
		_check("real mouse click on Serve Milk finished minigame and resumed story", not _mg().is_playing and _gs().rhythm_score() > 0)

	vn.queue_free()
	if is_instance_valid(balloon):
		balloon.queue_free()
	await get_tree().process_frame
