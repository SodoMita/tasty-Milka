extends SceneTree
## Renders a scene for N frames and saves a PNG screenshot.
## Usage:
##   godot --path . --script res://tools/capture_title.gd -- \
##       --scene res://scenes/title_screen.tscn --out /tmp/shot.png --frames 90
## Optional: --settings (open the settings panel), --lang ru (set the locale).


func _initialize() -> void:
	_run()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var scene_path := "res://scenes/title_screen.tscn"
	var out_path := "/tmp/capture.png"
	var frames := 90
	var open_settings := false
	var lang := ""
	for i in range(0, args.size() - 1):
		match args[i]:
			"--scene":
				scene_path = args[i + 1]
			"--out":
				out_path = args[i + 1]
			"--frames":
				frames = int(args[i + 1])
			"--settings":
				open_settings = true
			"--lang":
				lang = args[i + 1]
	if not lang.is_empty():
		# Switch the way a player does: through the shared settings store.
		var store := root.get_node_or_null("/root/SettingsStore")
		if store != null:
			store.set_value("language", lang)
		TranslationServer.set_locale(lang)
	change_scene_to_file(scene_path)
	if open_settings:
		for i in 20:
			await process_frame
		var title := current_scene
		var panel: Control = title.find_children("SettingsPanel", "PanelContainer", true, false)[0]
		panel.open()
	for i in frames:
		await process_frame
	var image := root.get_viewport().get_texture().get_image()
	image.save_png(out_path)
	print("CAPTURED ", out_path)
	quit()
