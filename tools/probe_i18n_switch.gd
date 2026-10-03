extends SceneTree
## Probe: switching language in the title settings must re-translate live.

func _initialize() -> void:
	_run()


func _run() -> void:
	TranslationServer.set_locale("en")
	change_scene_to_file("res://scenes/title_screen.tscn")
	for i in 40:
		await process_frame
	var title := current_scene
	var subtitle: Label = title.find_children("Subtitle", "Label", true, false)[0]
	var panel: Control = title.find_children("SettingsPanel", "PanelContainer", true, false)[0]
	panel.open()
	for i in 6:
		await process_frame
	print("BEFORE: ", subtitle.text)

	# pick Russian in the language dropdown (real signal, as a user would)
	var option: OptionButton = panel.find_children("LanguageOption", "OptionButton", true, false)[0]
	option.selected = 1
	option.item_selected.emit(1)
	for i in 30:
		await process_frame
	print("AFTER RU: ", subtitle.text, " | locale=", TranslationServer.get_locale())
	print("PANEL TITLE: ", panel.find_children("Title", "Label", true, false)[0].text)
	var store := root.get_node_or_null("SettingsStore")
	print("PERSISTED language: ", store.get_value("language", "?") if store else "?")

	# back to English
	option.selected = 0
	option.item_selected.emit(0)
	for i in 30:
		await process_frame
	print("AFTER EN: ", subtitle.text)
	print("PROBE DONE")
	quit()
