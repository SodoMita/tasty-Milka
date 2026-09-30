extends Node
## Shared settings menu: the title screen and the VN balloon instance the SAME authored
## scene (scenes/ui/settings_menu.tscn). On the title the menu drives itself through
## SettingsStore; in-game the balloon drives it. Both must use the same settings.json.
## Run: godot --headless res://tests/test_settings_menu.tscn   (exit code = failures)

const MENU_SCENE := "res://scenes/ui/settings_menu.tscn"

var failures := 0


func check(ok: bool, what: String) -> void:
	print(("[PASS] " if ok else "[FAIL] ") + what)
	if not ok:
		failures += 1


func _ready() -> void:
	_run()


func _run() -> void:
	var store = get_node("/root/SettingsStore")
	var saved: Dictionary = (store.load_settings() as Dictionary).duplicate(true)

	# --- title screen: same scene, driving itself --------------------------------
	var title := (load("res://scenes/title_screen.tscn") as PackedScene).instantiate()
	add_child(title)
	await get_tree().process_frame
	var menu := title.get_node("SettingsPanel") as SettingsMenu
	check(menu != null and menu.scene_file_path == MENU_SCENE, "title instances the shared settings_menu.tscn")
	check(menu.drive_settings, "title menu drives itself")
	for b: Button in [title.get_node("%StartButton"), title.get_node("%SettingsButton")]:
		check(b.text == "" and b.icon != null, "title %s is icon-only (SVG)" % b.name)
	menu.open()
	check(menu.visible and menu.close_button.visible, "title menu opens with its own close button")
	var speed := menu.get_node("%TextSpeedSlider") as HSlider
	var want := speed.min_value + speed.step * 3.0
	speed.value = want
	check(is_equal_approx(float(store.get_value("text_speed")), speed.value), "title slider writes text_speed to SettingsStore")
	check((menu.get_node("%TextSpeedValue") as Label).text == "%.3f s" % speed.value, "value label follows the slider")
	var lang := menu.get_node("%LanguageOption") as OptionButton
	lang.select(1)
	lang.item_selected.emit(1)
	check(store.get_value("language") == "ru" and TranslationServer.get_locale().begins_with("ru"), "language applies from the title")
	lang.select(0)
	lang.item_selected.emit(0)
	menu.close()
	check(not menu.visible, "close hides the title menu")
	var title_speed := speed.value
	title.queue_free()
	await get_tree().process_frame

	# --- in-game: the balloon drives the same scene and loads the title's value ---
	var vn := (load("res://scenes/vn_scene.tscn") as PackedScene).instantiate()
	add_child(vn)
	await get_tree().create_timer(1.5).timeout
	var button := get_tree().root.find_child("SettingsButton", true, false) as Button
	check(button != null and button.text == "" and button.icon != null, "balloon settings button is icon-only (SVG)")
	button.pressed.emit()
	await get_tree().process_frame
	var panel := get_tree().root.find_child("SettingsPanel", true, false) as SettingsMenu
	check(panel != null and panel.scene_file_path == MENU_SCENE, "balloon instances the same settings_menu.tscn")
	check(panel != null and not panel.drive_settings and panel.visible, "balloon opens the menu and drives it")
	check(panel != null and not panel.close_button.visible, "balloon keeps its own floating close button")
	var s2 := panel.get_node("%TextSpeedSlider") as HSlider
	check(is_equal_approx(s2.value, title_speed), "balloon loaded the value set on the title")
	s2.value = s2.min_value + s2.step * 5.0
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("user://settings.json"))
	check(data is Dictionary and is_equal_approx(float(data.get("text_speed", -1.0)), s2.value), "in-game change is saved to settings.json")
	check(is_equal_approx(float(store.get_value("text_speed")), s2.value), "SettingsStore stays in sync with the balloon")

	store.data = saved
	store.save_settings()
	print("settings menu tests: %d failure(s)" % failures)
	get_tree().quit(failures)
