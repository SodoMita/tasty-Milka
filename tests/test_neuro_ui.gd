extends Node
## Six reported regressions, tested against the real authored scenes.
var passes := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	print(("[PASS] " if ok else "[FAIL] ") + message)
	if ok:
		passes += 1
	else:
		failures += 1

func frames(count: int = 3) -> void:
	for i in count:
		await get_tree().process_frame

func icon_actions(parent: Node) -> Array[Button]:
	var found: Array[Button] = []
	for child in parent.get_children():
		if child is Button and child.theme_type_variation in [&"IconButton", &"IconButtonLarge"]:
			found.append(child)
		found.append_array(icon_actions(child))
	return found

func _ready() -> void:
	_run()

func _run() -> void:
	TranslationServer.set_locale("en")
	var title := (load("res://scenes/title_screen.tscn") as PackedScene).instantiate()
	add_child(title)
	await frames()
	check(title.get_node("%HowToPlay").text.contains("F12"), "title has authored keyboard and touch help")
	for locale in ["ru", "en", "ru", "en"]:
		TranslationServer.set_locale(locale)
		await frames()
		var help: String = title.get_node("%HowToPlayTitle").text
		check(help == ("Как играть" if locale == "ru" else "How to play"), "title help round-trip: " + locale)
		var empty := true
		for button in icon_actions(title):
			empty = empty and button.text.is_empty()
		check(empty, "all title/settings icon actions stay textless: " + locale)
	for pair in [["SettingsButton", "thinking"], ["QuitButton", "sad"]]:
		var button := title.get_node("%" + pair[0]) as Button
		button.mouse_entered.emit()
		check(title.crema.get_expression() == pair[1], pair[0] + " hover expression")
		button.mouse_exited.emit()
		check(title.crema.get_expression() == "neutral", pair[0] + " hover reset")
		button.focus_entered.emit()
		check(title.crema.get_expression() == pair[1], pair[0] + " keyboard-focus expression")
		button.focus_exited.emit()
	title.settings_button.pressed.emit()
	check(title.settings_panel.visible and title.crema.get_expression() == "thinking", "settings keeps its expression while open")
	await frames(8)
	check(title.settings_panel.size.x >= get_viewport().get_visible_rect().size.x * 0.95, "title settings panel is fullscreen wide")
	check(title.settings_panel.get_node("%SettingsScroll").size.x >= title.settings_panel.size.x * 0.85, "title settings content has no narrow fixed gutters")
	title.settings_panel.close()
	check(title.crema.get_expression() == "neutral", "settings close resets expression")
	title.queue_free()
	await frames()

	var vn := (load("res://scenes/vn_scene.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(vn)
	await frames(50)
	var balloon = get_tree().root.find_child("VNBalloon", true, false)
	check(balloon != null, "real VN balloon opens")
	if balloon == null:
		_finish()
		return
	for locale in ["ru", "en", "ru", "en"]:
		TranslationServer.set_locale(locale)
		await frames()
		balloon._retranslate_dynamic()
		var empty := true
		for button in icon_actions(balloon):
			empty = empty and button.text.is_empty()
		check(empty, "dialogue/pause/map icon actions stay textless: " + locale)
	check(not balloon.advance_key_button.text.is_empty(), "keyboard binding labels are not erased")
	var home := balloon.get_node("%PauseTitleButton") as Button
	check(home.icon != null and home.text.is_empty(), "pause has an authored icon-only home action")
	check(tr(home.tooltip_text) == "Back to title", "pause home tooltip has a source key")

	var paper := (load("res://scenes/panic_screen.tscn") as PackedScene).instantiate()
	balloon.get_node("Balloon/UIRoot").add_child(paper)
	await frames(8)
	var scroll := paper.get_node("PanicMargin/PanicScroll") as ScrollContainer
	var body := paper.get_node("PanicMargin/PanicScroll/PanicVBox/PanicBody") as Label
	check(scroll.mouse_filter == Control.MOUSE_FILTER_STOP, "panic scroll receives input")
	check(scroll.get_v_scroll_bar().max_value > scroll.size.y, "panic article overflows the viewport")
	print("Panic input probe: viewport=", get_viewport().get_visible_rect(), " scroll=", scroll.get_global_rect(), " canvas=", scroll.get_global_transform_with_canvas())
	var wheel := InputEventMouseButton.new()
	wheel.position = Vector2(400, 250)
	wheel.global_position = wheel.position
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	var before := scroll.scroll_vertical
	Input.parse_input_event(wheel)
	await frames(5)
	check(scroll.scroll_vertical > before, "real mouse wheel scrolls the cow article")
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = Vector2(400, 400)
	touch.pressed = true
	Input.parse_input_event(touch)
	await frames()
	before = scroll.scroll_vertical
	for i in 5:
		var drag := InputEventScreenDrag.new()
		drag.index = 0
		drag.position = Vector2(400, 400 - (i + 1) * 30)
		drag.relative = Vector2(0, -30)
		Input.parse_input_event(drag)
		await frames(2)
	check(scroll.scroll_vertical > before, "real touch swipe scrolls the cow article")
	touch.pressed = false
	Input.parse_input_event(touch)
	for locale in ["ru", "en", "ru", "en"]:
		TranslationServer.set_locale(locale)
		await frames()
		check(body.text.contains("молозив" if locale == "ru" else "colostrum"), "whole panic article translates: " + locale)
		check(paper.get_node("%PanicCloseButton").text.is_empty(), "panic close stays textless: " + locale)
	balloon._close_panic()
	paper.queue_free()
	await frames()

	var map = balloon.get_node("%RouteGraphPanel")
	var dim := map.get_node("SpoilerPanel/Dim") as Panel
	check(dim != null, "map dim is a themed panel, not a square ColorRect")
	if dim != null:
		var dim_style := dim.get_theme_stylebox("panel") as StyleBoxFlat
		var outer_style := map.get_theme_stylebox("panel") as StyleBoxFlat
		check(dim_style.corner_radius_top_left == outer_style.corner_radius_top_left, "map dim and outer panel share their corner radius")
	var canvas := map.get_node("Margin/VBox/GraphContainer") as PanelContainer
	var style := canvas.get_theme_stylebox("panel") as StyleBoxFlat
	check(style.shadow_size == 0, "map canvas has no second rectangular dim shadow")
	balloon.open_pause()
	check(balloon._audio_silenced, "pause silences the game before title return")
	get_tree().current_scene = vn
	home.pressed.emit()
	await frames(8)
	check(get_tree().current_scene.scene_file_path == "res://scenes/title_screen.tscn", "pause home actually changes to the authored title scene")
	check(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")), "return to title clears the pause bus mute")
	get_tree().current_scene.queue_free()
	await frames()
	_finish()

func _finish() -> void:
	print("Neuro UI: %d passed; %d failed" % [passes, failures])
	get_tree().quit(1 if failures else 0)
