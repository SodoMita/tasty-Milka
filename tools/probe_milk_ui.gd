extends SceneTree
## Headless probe for the milk-glass UI contract.
##   godot --headless --path . --script res://tools/probe_milk_ui.gd
## Asserts: every system/title button is icon-only (SVG icon, no text, tooltip),
## the balloon and the title screen resolve their styles from the one shared
## theme (res://assets/ui/milk_glass_theme.tres), overlays open/close cleanly.

const THEME_PATH := "res://assets/ui/milk_glass_theme.tres"
const SYSTEM_BUTTONS := ["QSButton", "QLButton", "SaveButton", "LoadButton", "AutoButton",
	"SkipButton", "PrevChoiceButton", "NextChoiceButton", "LogButton", "SettingsButton",
	"PanicButton", "PauseButton", "RouteButton", "SaveCloseButton", "SettingsCloseButton",
	"ResumeButton", "PauseHistoryButton", "PauseSaveButton", "PauseLoadButton",
	"PauseSettingsButton", "QuitButton"]
const TITLE_BUTTONS := ["StartButton", "ContinueButton", "SettingsButton", "QuitButton"]

var _passed := 0
var _failed := 0


func _initialize() -> void:
	_run()


func check(ok: bool, what: String) -> void:
	if ok:
		_passed += 1
		print("  [PASS] ", what)
	else:
		_failed += 1
		print("  [FAIL] ", what)


func _icon_only(b: Button) -> bool:
	return b.text == "" and b.icon != null and b.tooltip_text != "" \
		and String(b.icon.resource_path).ends_with(".svg")


func _run() -> void:
	var theme: Theme = load(THEME_PATH)
	check(theme != null, "shared milk-glass theme loads")
	for variation in ["IconButton", "TitleButton", "GhostButton"]:
		check(theme.get_type_variation_base(variation) == &"Button", "%s is a Button variation" % variation)
	for variation in ["DialogueBox", "NamePlate", "OverlayPanel"]:
		check(theme.get_type_variation_base(variation) == &"PanelContainer", "%s is a PanelContainer variation" % variation)

	# --- title screen ---
	change_scene_to_file("res://scenes/title_screen.tscn")
	for i in 20:
		await process_frame
	var title := current_scene
	check(title.theme == theme, "title screen uses the shared theme resource")
	for n in TITLE_BUTTONS:
		var b: Button = title.get_node("%" + n)
		check(_icon_only(b), "title %s is icon-only (svg + tooltip, no text)" % n)
		check(b.theme_type_variation == &"TitleButton", "title %s uses TitleButton variation" % n)
	var block: PanelContainer = title.get_node("TitleBlock")
	check(block.theme_type_variation == &"DialogueBox"
		and block.get_theme_stylebox("panel") == theme.get_stylebox("panel", "DialogueBox"),
		"title panel reuses the dialogue bubble style from the theme")
	var start: Button = title.get_node("%StartButton")
	start.mouse_entered.emit()
	await process_frame
	check(title.get_node("%Hint").text == "Begin the story", "hover shows the icon's tooltip as a hint")
	check(title.find_children("Crema", "Node2D", true, false).size() == 1, "animated character scene is on the title")
	var tsp: PanelContainer = title.get_node("SettingsPanel")
	tsp.open()
	await process_frame
	check(tsp.visible and tsp.get_node("%CloseButton").text == "" and tsp.get_node("%CloseButton").icon != null,
		"title settings panel opens with an icon-only close button")
	tsp.close()
	await process_frame

	# --- VN scene / balloon ---
	change_scene_to_file("res://scenes/vn_scene.tscn")
	for i in 40:
		await process_frame
	var balloons := root.find_children("VNBalloon", "CanvasLayer", true, false)
	check(balloons.size() == 1, "balloon is on stage")
	if balloons.is_empty():
		_finish()
		return
	var balloon: CanvasLayer = balloons[0]
	var bcontrol: Control = balloon.get_node("%Balloon")
	check(bcontrol.theme == theme, "balloon uses the shared theme resource")
	var box: PanelContainer = balloon.get_node("%DialogueBox")
	check(box.theme_type_variation == &"DialogueBox"
		and box.get_theme_stylebox("panel") == theme.get_stylebox("panel", "DialogueBox"),
		"dialogue box style comes from the theme (same as title panel)")
	var sb: StyleBoxFlat = box.get_theme_stylebox("panel")
	check(sb.bg_color.a < 0.7 and sb.bg_color.r > 0.95, "dialogue box is translucent milk")
	check(balloon.get_node("%NamePlate").theme_type_variation == &"NamePlate", "name plate uses the NamePlate variation")
	var tscn := FileAccess.get_file_as_string("res://scenes/vn_balloon.tscn")
	check(not tscn.contains("type=\"Theme\" id=") and not tscn.contains("[sub_resource type=\"StyleBoxFlat\""),
		"balloon scene holds no inline theme/stylebox (all in milk_glass_theme.tres)")
	for n in SYSTEM_BUTTONS:
		var b: Button = balloon.get_node("%" + n)
		check(_icon_only(b) and b.theme_type_variation == &"IconButton", "balloon %s is an icon-only IconButton" % n)
	for n in ["SaveMenuPanel", "SettingsPanel", "PausePanel", "HistoryPanel"]:
		check(balloon.get_node("%" + n).theme_type_variation == &"OverlayPanel", "%s uses OverlayPanel variation" % n)
	# overlays open and close
	balloon.get_node("%PauseButton").pressed.emit()
	await process_frame
	check(balloon.get_node("%PausePanel").visible, "pause overlay opens from the icon button")
	balloon.get_node("%ResumeButton").pressed.emit()
	await process_frame
	check(not balloon.get_node("%PausePanel").visible, "resume icon closes pause")
	balloon.get_node("%SettingsButton").pressed.emit()
	await process_frame
	check(balloon.get_node("%SettingsPanel").visible, "settings overlay opens")
	balloon.get_node("%SettingsCloseButton").pressed.emit()
	await process_frame
	check(not balloon.get_node("%SettingsPanel").visible, "settings close icon works")
	balloon.get_node("%LogButton").pressed.emit()
	await process_frame
	check(balloon.get_node("%HistoryPanel").visible, "history overlay opens")
	if balloon.has_method("toggle_history"):
		balloon.toggle_history()
	await process_frame
	# locale: tooltips translate
	TranslationServer.set_locale("ru")
	await process_frame
	check(balloon.atr(balloon.get_node("%SaveButton").tooltip_text) == "Сохранить", "icon tooltips follow the locale")
	TranslationServer.set_locale("en")
	_finish()


func _finish() -> void:
	print("milk-ui probe: %d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)
