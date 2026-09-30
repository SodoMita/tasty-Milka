extends SceneTree
## Verifies the title's visible player-name input and Start submission path.

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var error := change_scene_to_file("res://scenes/title_screen.tscn")
	if error != OK:
		push_error("Could not load title scene: %s" % error)
		quit(1)
		return
	for i in 30:
		await process_frame

	var title := current_scene
	var fields := title.find_children("PlayerNameInput", "LineEdit", true, false)
	if fields.is_empty():
		push_error("PlayerNameInput is missing")
		quit(1)
		return
	var field: LineEdit = fields[0]
	var game_state := root.get_node_or_null("GameState")
	var store := root.get_node_or_null("SettingsStore")
	var expected_name := str(game_state.player_name) if game_state != null else "Protagonist"
	if store != null:
		expected_name = str(store.get_value("player_name", expected_name))
	print("FIELD visible=", field.is_visible_in_tree(), " size=", field.size,
		" text=", field.text, " placeholder=", field.placeholder_text)
	if not field.is_visible_in_tree() or field.size.x < 200 or field.text.is_empty():
		push_error("Name field is not visibly rendered")
		quit(1)
		return
	if field.text != expected_name:
		push_error("Saved name was not restored into the input field")
		quit(1)
		return

	field.text = "Mika"
	field.emit_signal("text_submitted", field.text)
	await create_timer(0.8).timeout
	for i in 5:
		await process_frame
	game_state = root.get_node_or_null("GameState")
	store = root.get_node_or_null("SettingsStore")
	var stored_name := str(store.get_value("player_name", "")) if store != null else ""
	var disk_data: Variant = JSON.parse_string(FileAccess.get_file_as_string("user://settings.json"))
	var disk_name := str(disk_data.get("player_name", "")) if disk_data is Dictionary else ""
	print("SUBMIT scene=", current_scene.name, " GameState.player_name=",
		game_state.player_name if game_state != null else "MISSING", " stored=", stored_name,
		" disk=", disk_name)
	if current_scene.name != "VNScene" or game_state == null or game_state.player_name != "Mika" or stored_name != "Mika" or disk_name != "Mika":
		push_error("Name did not reach VN scene and settings")
		quit(1)
		return
	print("TITLE NAME INPUT: PASS")
	quit(0)
