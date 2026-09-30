extends Node
## Godot regression checks for the Vanilla-based milk UI additions.
## Run: godot --headless res://tests/test_milk_cows.tscn

var failures := 0
var passes := 0


func check(ok: bool, name: String) -> void:
	print(("[PASS] " if ok else "[FAIL] ") + name)
	if ok:
		passes += 1
	else:
		failures += 1


func _ready() -> void:
	_run()


func _run() -> void:
	var title := (load("res://scenes/title_screen.tscn") as PackedScene).instantiate()
	add_child(title)
	await get_tree().process_frame
	var menu := title.get_node("SettingsPanel") as SettingsMenu
	check(menu != null and menu.drive_settings, "title uses self-driving shared settings scene")
	check(menu.HoldTiming.SECONDS == preload("res://scenes/vn_balloon.gd").HOLD_SECONDS,
		"title and balloon share the same hold duration")
	menu.open()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = Vector2(100, 100)
	press.pressed = true
	menu._on_empty_press(press)
	check(menu._hold_active, "press on empty title settings starts hold")
	menu._process(0.13)
	check(menu.hold_indicator.visible and menu.visible, "hold ring appears after the same delay as balloon")
	var drag := InputEventMouseMotion.new()
	drag.position = menu._hold_from + Vector2(20, 0)
	menu._input(drag)
	check(not menu._hold_active and menu.visible and not menu.hold_indicator.visible,
		"drag cancels hold without closing title settings")
	menu._on_empty_press(press)
	menu._process(0.2)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = press.position
	release.pressed = false
	menu._input(release)
	check(menu.visible and not menu._hold_active, "quick tap does not dismiss title settings")
	menu._on_empty_press(press)
	menu._process(0.56)
	check(not menu.visible and not menu._hold_active and not menu.hold_indicator.visible,
		"long hold closes title settings and hides ring")
	menu.open()
	menu.close_button.pressed.emit()
	check(not menu.visible, "title settings close icon still works")
	title.queue_free()
	await get_tree().process_frame

	var vn := (load("res://scenes/vn_scene.tscn") as PackedScene).instantiate()
	add_child(vn)
	for i in 50:
		await get_tree().process_frame
	var balloon = get_tree().root.find_child("VNBalloon", true, false)
	check(balloon != null, "VN balloon instantiated")
	if balloon == null:
		_finish()
		return
	var row := balloon.get_node("%SystemRow")
	check(row.get_child(0).name == "HideUIButton", "Hide UI is the leftmost system button")
	var hide_btn := balloon.get_node("%HideUIButton") as Button
	var panic_btn := balloon.get_node("%PanicButton") as Button
	check(hide_btn.text == "" and hide_btn.icon.resource_path.ends_with("/panic.svg"),
		"Hide UI uses the former panic crossed-eye SVG")
	check(panic_btn.icon.resource_path.ends_with("/panic_red.svg"), "panic uses dedicated red SVG")
	hide_btn.pressed.emit()
	check(not balloon.bottom_ui.visible and balloon.reveal_ui_button.visible,
		"hide leaves a reveal affordance outside BottomUI")
	balloon.reveal_ui_button.pressed.emit()
	check(balloon.bottom_ui.visible and not balloon.reveal_ui_button.visible, "reveal restores dialogue UI")
	var in_game_menu := balloon.get_node("%SettingsPanel") as SettingsMenu
	check(not in_game_menu.drive_settings, "in-game settings still let balloon drive hold")
	in_game_menu.open()
	in_game_menu._on_empty_press(press)
	check(not in_game_menu._hold_active, "title hold handler does not compete with balloon")
	in_game_menu.hide()
	var map = balloon.get_node("%RouteGraphPanel")
	check(map.theme == load("res://assets/ui/milk_glass_theme.tres") and map.theme_type_variation == &"MilkPanel",
		"story map reuses the shared milk-glass theme")
	for name in ["VisitedToggle", "CloseButton", "SpoilerCancel", "SpoilerConfirm"]:
		var b := map.get_node("%" + name) as Button
		check(b.text == "" and b.icon != null and b.tooltip_text != "", "map %s is icon-only" % name)
	map.show_graph()
	await get_tree().process_frame
	check(map.visible and map.view.full_nodes.size() > 0, "milk-glass story map compiles and opens")
	map.close_btn.pressed.emit()
	check(not map.visible, "map close icon still works")
	var paper := (load("res://scenes/panic_screen.tscn") as PackedScene).instantiate()
	add_child(paper)
	await get_tree().process_frame
	var article := paper.get_node("PanicMargin/PanicScroll/PanicVBox/PanicBody") as Label
	check(article.text.length() > 3000 and article.text.contains("rumen") and article.text.contains("colostrum"),
		"panic screen contains the long educational cow article")
	check(paper.get_node("PanicMargin/PanicScroll") is ScrollContainer, "cow guide is scrollable")
	paper.queue_free()
	_finish()


func _finish() -> void:
	print("Milk/cows checks: %d passed; %d failed" % [passes, failures])
	get_tree().quit(1 if failures > 0 else 0)
