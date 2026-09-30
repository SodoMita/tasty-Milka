extends Node
## Opens the title or the VN scene in a given UI state and keeps it on screen, so a
## real compositor capture (tools/sway_capture.sh: sway headless + pixman + grim)
## shows what a player sees. Scenes are instanced as authored - nothing is built.
##   godot res://tools/ui_state.tscn -- <title|title_settings|vn|vn_settings> [seconds]


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var state: String = args[0] if args.size() > 0 else "title"
	var seconds: float = float(args[1]) if args.size() > 1 else 20.0
	var path := "res://scenes/title_screen.tscn" if state.begins_with("title") else "res://scenes/vn_scene.tscn"
	add_child((load(path) as PackedScene).instantiate())
	await get_tree().create_timer(2.5).timeout
	match state:
		"title_settings":
			var menu := find_child("SettingsPanel", true, false)
			if menu != null and menu.has_method("open"):
				menu.call("open")
		"vn_settings", "vn_pause", "vn_map":
			var names := {"vn_settings": "SettingsButton", "vn_pause": "PauseButton", "vn_map": "RouteButton"}
			var button := get_tree().root.find_child(str(names[state]), true, false) as Button
			if button != null:
				button.pressed.emit()
		"vn_panic":
			add_child((load("res://scenes/panic_screen.tscn") as PackedScene).instantiate())
		"title_ru":
			TranslationServer.set_locale("ru")
	var block := find_child("TitleBlock", true, false) as Control
	if block != null:
		print("TitleBlock rect: ", block.get_global_rect())
	await get_tree().create_timer(seconds).timeout
	get_tree().quit()
