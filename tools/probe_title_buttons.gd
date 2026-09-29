extends SceneTree
## Headless probe: title screen buttons must actually work.

func _initialize() -> void:
	_run()


func _run() -> void:
	change_scene_to_file("res://scenes/title_screen.tscn")
	for i in 30:
		await process_frame
	var title := root.get_node("TitleScreen")
	var start: Button = title.find_children("StartButton", "Button", true, false)[0]
	var cont: Button = title.find_children("ContinueButton", "Button", true, false)[0]
	var settings: Button = title.find_children("SettingsButton", "Button", true, false)[0]
	var quit: Button = title.find_children("QuitButton", "Button", true, false)[0]
	print("BTN wired: start=%d cont=%d set=%d quit=%d" % [start.pressed.get_connections().size(),
		cont.pressed.get_connections().size(), settings.pressed.get_connections().size(),
		quit.pressed.get_connections().size()])
	print("CREMA on stage: ", title.find_children("Crema", "Node2D", true, false).size() > 0)

	# Settings button opens the panel
	settings.pressed.emit()
	for i in 10:
		await process_frame
	var panel: Control = title.find_children("SettingsPanel", "PanelContainer", true, false)[0]
	print("SETTINGS OPEN: ", panel.visible)

	# Changing a setting persists and applies
	panel._on_language_selected(1)
	for i in 5:
		await process_frame
	var persisted: Variant = JSON.parse_string(FileAccess.get_file_as_string("user://settings.json"))
	print("SETTINGS PERSIST: language=", persisted.get("language", "?") if persisted is Dictionary else "?")
	print("LOCALE APPLIED: ", TranslationServer.get_locale())
	panel.close()
	for i in 5:
		await process_frame
	print("SETTINGS CLOSE: ", not panel.visible)

	# Continue (no saves yet) starts the VN scene
	cont.pressed.emit()
	for i in 60:
		await process_frame
	print("CONTINUE -> scene: ", current_scene.name)
	var bg := root.find_children("Background", "TextureRect", true, false)
	print("VN BG TAGS: ", bg[0].texture != null if bg.size() > 0 else "none")
	print("PROBE DONE")
	quit()
