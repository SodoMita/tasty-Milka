extends Node
## Milk-glass UI contract tests.
##
## The dialogue bubble and the title screen must share one settings
## resource (assets/ui/milk_ui_settings.tres) and the same icon-only
## button language: SVG icon, empty text, translated tooltip.

var fails := 0
var checks := 0


func _ready() -> void:
	await get_tree().process_frame
	_settings_are_shared()
	await _title_screen_uses_the_settings()
	_balloon_uses_the_settings()
	_icon_set_is_svg()
	print("=====================================")
	print("milk-glass tests: %d passed, %d failed" % [checks - fails, fails])
	print("=====================================")
	get_tree().quit(1 if fails > 0 else 0)


func check(ok: bool, what: String) -> void:
	checks += 1
	if ok:
		print("[PASS] ", what)
	else:
		fails += 1
		print("[FAIL] ", what)


func _settings_are_shared() -> void:
	var settings: MilkUISettings = MilkGlass.settings()
	check(settings is MilkUISettings, "MilkGlass hands out a MilkUISettings resource")
	check(settings != null and settings.resource_path.ends_with("milk_ui_settings.tres"),
		"settings load from the shared .tres, not from a scene")
	check(settings.corner_radius > 0 and settings.glass.a < 1.0,
		"the glass is translucent (alpha %.2f)" % settings.glass.a)
	var panel := settings.panel_style()
	check(panel is StyleBoxFlat and panel.corner_radius_top_left == settings.corner_radius,
		"panel style comes from the shared radius")
	var plate := settings.plate_style()
	check(plate is StyleBoxFlat and plate.bg_color == settings.butter,
		"name plate style comes from the shared butter colour")
	var theme := settings.build_theme()
	check(theme.get_stylebox(&"panel", &"Panel") is StyleBoxFlat,
		"the shared settings can build a whole Theme")


func _title_screen_uses_the_settings() -> void:
	var title: Control = load("res://scenes/title_screen.tscn").instantiate()
	add_child(title)
	await get_tree().process_frame
	check(title.theme != null, "title screen takes its theme from the shared settings")
	var menu := title.find_child("Menu", true, false)
	check(menu != null and menu.get_child_count() == 4, "title menu holds four chips")
	for button: Node in menu.get_children():
		check(button is Button and button.text == "" and button.icon != null,
			"%s is icon-only (no text on the button)" % button.name)
		check(not String(button.tooltip_text).is_empty(),
			"%s carries a tooltip for hover and screen readers" % button.name)
	title.free()


func _balloon_uses_the_settings() -> void:
	var text := FileAccess.get_file_as_string("res://scenes/vn_balloon.tscn")
	var chrome: Dictionary = MilkGlass.BALLOON_CHROME
	check(text.contains("MilkGlass") or FileAccess.file_exists("res://scenes/ui/milk_glass.gd"),
		"the bubble has a MilkGlass helper to borrow settings from")
	var missing := 0
	for node_name: String in chrome:
		var at := text.find("[node name=\"%s\"" % node_name)
		if at < 0:
			missing += 1
			continue
		var block := text.substr(at, text.find("\n[node", at + 1) - at)
		if not block.contains("icon = ExtResource(") or not block.contains("text = \"\""):
			missing += 1
	check(missing == 0, "every dialogue chrome button is icon-only in the scene itself")
	var gd := FileAccess.get_file_as_string("res://scenes/vn_balloon.gd")
	check(gd.contains("_apply_milk_glass()"), "the bubble applies the shared settings at startup")
	var title_gd := FileAccess.get_file_as_string("res://scenes/title_screen.gd")
	check(title_gd.contains("MilkGlass.settings()"), "the title screen reads the same settings")
	check(not "Button.new(" in title_gd, "the title screen builds no UI in code (no builder script)")


func _icon_set_is_svg() -> void:
	var count := 0
	var dir := DirAccess.open("res://assets/ui/icons")
	if dir != null:
		for f in dir.get_files():
			if f.ends_with(".svg"):
				count += 1
	check(count >= 16, "the icon set ships %d hand-drawn SVGs" % count)
	check(MilkGlass.icon("ic_save") is Texture2D, "icons load as textures for buttons")
