extends SceneTree
## Probe: every UI string I authored must follow the chosen locale.

func _initialize() -> void:
	_run()


func _run() -> void:
	# Switch the way a user does: through the shared settings store, which is
	# also what the settings panel calls.
	var store := root.get_node_or_null("SettingsStore")
	for lang: String in ["en", "ru"]:
		if store != null:
			store.set_value("language", lang)
		TranslationServer.set_locale(lang)
		change_scene_to_file("res://scenes/title_screen.tscn")
		for i in 40:
			await process_frame
		var title := current_scene
		var out: PackedStringArray = []
		out.append("locale=%s" % TranslationServer.get_locale())
		out.append("subtitle=%s" % title.find_children("Subtitle", "Label", true, false)[0].text)
		out.append("version=%s" % title.find_children("Version", "Label", true, false)[0].text)
		out.append("name_label=%s" % title.find_children("PlayerNameLabel", "Label", true, false)[0].text)
		out.append("placeholder=%s" % title.find_children("PlayerNameInput", "LineEdit", true, false)[0].placeholder_text)
		out.append("name_tooltip=%s" % title.find_children("PlayerNameInput", "LineEdit", true, false)[0].tooltip_text)
		var start: Button = title.find_children("StartButton", "Button", true, false)[0]
		var cont: Button = title.find_children("ContinueButton", "Button", true, false)[0]
		var quit: Button = title.find_children("QuitButton", "Button", true, false)[0]
		out.append("tooltips=%s | %s | %s" % [start.tooltip_text, cont.tooltip_text, quit.tooltip_text])
		# settings panel labels
		var panel: Control = title.find_children("SettingsPanel", "PanelContainer", true, false)[0]
		panel.open()
		for i in 6:
			await process_frame
		out.append("panel_title=%s" % panel.find_children("Title", "Label", true, false)[0].text)
		out.append("language_label=%s" % panel.find_children("LanguageLabel", "Label", true, false)[0].text)
		out.append("lang_items=%s / %s" % [
			panel.find_children("LanguageOption", "OptionButton", true, false)[0].get_item_text(0),
			panel.find_children("LanguageOption", "OptionButton", true, false)[0].get_item_text(1)])
		out.append("fullscreen_label=%s" % panel.find_children("FullscreenLabel", "Label", true, false)[0].text)
		out.append("vsync_label=%s" % panel.find_children("VSyncLabel", "Label", true, false)[0].text)
		out.append("master_vol_label=%s" % panel.find_children("MasterVolLabel", "Label", true, false)[0].text)
		print(" || ".join(out))
		panel.close()
	print("PROBE DONE")
	quit()
