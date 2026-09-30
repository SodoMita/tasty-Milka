extends SceneTree
## Renders the milk-glass UI views and saves PNGs (run under a real display,
## e.g. headless sway + pixman; see README "Screenshots").
##   godot --path . --display-driver wayland --rendering-driver opengl3 \
##       --script res://tools/capture_milk.gd -- --out docs/screenshots

var out_dir := "docs/screenshots"


func _initialize() -> void:
	_run()


func _shot(file_name: String, frames: int = 30) -> void:
	for i in frames:
		await process_frame
	var image := root.get_viewport().get_texture().get_image()
	var path := out_dir.path_join(file_name)
	image.save_png(path)
	print("CAPTURED ", path)


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	for i in range(0, args.size() - 1):
		if args[i] == "--out":
			out_dir = args[i + 1]
	DirAccess.make_dir_recursive_absolute(out_dir)

	# Title screen, then its shared settings panel.
	change_scene_to_file("res://scenes/title_screen.tscn")
	await _shot("title_screen.png", 90)
	var title := current_scene
	(title.get_node("%StartButton") as Button).grab_focus()
	title.get_node("%StartButton").mouse_entered.emit()
	await _shot("title_hover.png", 10)
	title.get_node("SettingsPanel").open()
	await _shot("title_settings.png", 20)
	title.get_node("SettingsPanel").close()

	# VN scene: dialogue balloon, pause row, in-game settings, history.
	change_scene_to_file("res://scenes/vn_scene.tscn")
	await _shot("vn_dialogue.png", 150)
	var balloons := root.find_children("VNBalloon", "CanvasLayer", true, false)
	if balloons.is_empty():
		print("no balloon on stage")
		quit(1)
		return
	var balloon: CanvasLayer = balloons[0]
	balloon.get_node("%PauseButton").pressed.emit()
	await _shot("vn_pause.png", 20)
	balloon.get_node("%ResumeButton").pressed.emit()
	await process_frame
	balloon.get_node("%SettingsButton").pressed.emit()
	await _shot("vn_settings.png", 20)
	balloon.get_node("%SettingsCloseButton").pressed.emit()
	await process_frame
	balloon.get_node("%SaveButton").pressed.emit()
	await _shot("vn_save_menu.png", 20)
	quit()
