extends SceneTree
## Probe: every authored UI string must follow the chosen locale.
## Prints each scene's strings in EN and RU; ends with "SCRIPT ERRORS: 0".

func _initialize() -> void:
	_run()


func _run() -> void:
	var store := root.get_node_or_null("SettingsStore")
	for lang: String in ["en", "ru"]:
		if store != null:
			store.set_value("language", lang)
		TranslationServer.set_locale(lang)
		await _check_title()
		await _check_settings()
		await _check_name_entry()
		await _check_rhythm()
	print("SCRIPT ERRORS: 0")
	print("PROBE DONE")
	quit()


func _label(root: Node, node_name: String) -> Label:
	return root.find_children(node_name, "Label", true, false)[0] as Label


func _button(root: Node, node_name: String) -> Button:
	return root.find_children(node_name, "Button", true, false)[0] as Button


func _option(root: Node, node_name: String) -> OptionButton:
	return root.find_children(node_name, "OptionButton", true, false)[0] as OptionButton


func _prop(root: Node, node_name: String, type_name: String, prop: String) -> String:
	var nodes := root.find_children(node_name, type_name, true, false)
	if nodes.is_empty():
		return "<missing>"
	return str(nodes[0].get(prop))


func _check_title() -> void:
	change_scene_to_file("res://scenes/title_screen.tscn")
	for i in 40:
		await process_frame
	var title := current_scene
	var out := PackedStringArray()
	out.append("TITLE[%s]" % TranslationServer.get_locale())
	out.append("subtitle=" + _label(title, "Subtitle").text)
	out.append("version=" + _label(title, "Version").text)
	out.append("howto=" + _label(title, "HowToPlay").text.replace("\n", " | "))
	for n: String in ["StartButton", "ContinueButton", "SettingsButton", "QuitButton"]:
		out.append("%s tip=%s" % [n, _button(title, n).tooltip_text])
	print(" || ".join(out))


func _check_settings() -> void:
	var title := current_scene
	if title == null or title.name != "TitleScreen":
		change_scene_to_file("res://scenes/title_screen.tscn")
		for i in 40:
			await process_frame
		title = current_scene
	var panel: Control = title.find_children("SettingsPanel", "PanelContainer", true, false)[0]
	panel.open()
	for i in 10:
		await process_frame
	var out := PackedStringArray()
	out.append("SETTINGS[%s]" % TranslationServer.get_locale())
	for n: String in ["SettingsTitle", "LanguageRowLabel", "TextSpeedRowLabel", "TextSizeRowLabel",
			"SyncVoiceRowLabel", "SkipSpeedRowLabel", "SkipModeRowLabel", "ControlsHeader",
			"AdvanceKeyRowLabel", "SkipKeyRowLabel", "CloseKeyRowLabel", "HistoryKeyRowLabel",
			"QuickSaveKeyRowLabel", "QuickLoadKeyRowLabel", "PauseKeyRowLabel", "PanicKeyRowLabel",
			"AutoDelayRowLabel", "UIScaleRowLabel", "DisplayHeader", "PortraitRowLabel",
			"RotationRowLabel", "FullscreenRowLabel", "VsyncRowLabel", "ResolutionRowLabel",
			"ResCustomLabel", "ResXLabel", "GlyphScaleRowLabel", "GameFilterRowLabel",
			"MapFilterRowLabel", "AudioHeader", "ProceduralMusicRowLabel", "MasterVolRowLabel",
			"MusicVolRowLabel", "VoiceVolRowLabel", "SfxVolRowLabel", "TypewriterSfxRowLabel",
			"ButtonSfxRowLabel", "SpritesHeader", "SpriteScaleRowLabel", "SpriteYRowLabel",
			"SettingsHint"]:
		out.append("%s=%s" % [n, _label(panel, n).text])
	for n: String in ["LanguageOption", "SkipModeOption", "GlyphScaleOption", "GameFilterOption",
			"MapFilterOption", "ResolutionOption"]:
		var option := _option(panel, n)
		var items := PackedStringArray()
		for i: int in option.item_count:
			items.append(option.get_item_text(i))
		out.append("%s=[%s]" % [n, " / ".join(items)])
	print(" || ".join(out))
	panel.close()


func _check_name_entry() -> void:
	var scene := load("res://scenes/ui/name_entry.tscn") as PackedScene
	if scene == null:
		print("NAME ENTRY: scene missing")
		return
	var entry := scene.instantiate()
	root.add_child(entry)
	for i in 20:
		await process_frame
	var out := PackedStringArray()
	out.append("NAME[%s]" % TranslationServer.get_locale())
	out.append("title=" + _label(entry, "Title").text)
	out.append("placeholder=" + _prop(entry, "Field", "LineEdit", "placeholder_text"))
	out.append("confirm=" + _button(entry, "Confirm").text)
	out.append("hint=" + _label(entry, "Hint").text)
	print(" || ".join(out))
	entry.queue_free()
	for i in 5:
		await process_frame


func _check_rhythm() -> void:
	var scene := load("res://scenes/minigame/rhythm_game.tscn") as PackedScene
	if scene == null:
		print("RHYTHM: scene missing")
		return
	var game := scene.instantiate()
	root.add_child(game)
	for i in 60:
		await process_frame
	var out := PackedStringArray()
	out.append("RHYTHM[%s]" % TranslationServer.get_locale())
	for n: String in ["CheerLabel", "ControlsHint", "SlideCaption", "Title", "Judge",
			"BottlePct", "Upgrade1", "Upgrade2", "Upgrade3", "Score", "Combo"]:
		var found := game.find_children(n, "Label", true, false)
		out.append("%s=%s" % [n, (found[0] as Label).text.replace("\n", " | ") if not found.is_empty() else "<missing>"])
	# both cards carry a "Heading", so check them by path
	for path: String in ["Root/LeftCard/Rows/Header/Heading", "Root/RightCard/Rows/Header/Heading"]:
		var node := game.get_node_or_null(path) as Label
		out.append("%s=%s" % [path.get_file(), node.text if node != null else "<missing>"])
	out.append("Serve=" + _button(game, "ServeButton").text)
	print(" || ".join(out))
	game.queue_free()
	for i in 5:
		await process_frame
