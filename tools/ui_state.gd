extends Node
## Opens the title or the VN scene in a given UI state, drives it with real
## Viewport.push_input() events, and signals sway_capture.sh when the frame is
## ready for grim.

func _click_at(pos: Vector2) -> void:
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = pos
	down.global_position = pos
	get_viewport().push_input(down, true)
	await get_tree().process_frame
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = pos
	up.global_position = pos
	get_viewport().push_input(up, true)
	await get_tree().process_frame


func _drag_mouse(from_pos: Vector2, to_pos: Vector2) -> void:
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = from_pos
	down.global_position = from_pos
	get_viewport().push_input(down, true)
	await get_tree().process_frame
	var move := InputEventMouseMotion.new()
	move.position = to_pos
	move.global_position = to_pos
	move.relative = to_pos - from_pos
	get_viewport().push_input(move, true)
	await get_tree().process_frame
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = to_pos
	up.global_position = to_pos
	get_viewport().push_input(up, true)
	await get_tree().process_frame


func _type_char(ch: String, keycode: Key = KEY_NONE) -> void:
	var code: int = ch.unicode_at(0) if ch.length() > 0 else 0
	var k := InputEventKey.new()
	k.pressed = true
	k.unicode = code
	k.keycode = keycode if keycode != KEY_NONE else (code as Key)
	k.physical_keycode = k.keycode
	get_viewport().push_input(k, true)
	await get_tree().process_frame
	var ku := InputEventKey.new()
	ku.pressed = false
	ku.unicode = code
	ku.keycode = k.keycode
	ku.physical_keycode = k.keycode
	get_viewport().push_input(ku, true)
	await get_tree().process_frame


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var state: String = args[0] if args.size() > 0 else "title"
	var out_file: String = args[1] if args.size() > 1 else "/tmp/shot.png"
	var path := "res://scenes/title_screen.tscn" if state.begins_with("title") else "res://scenes/vn_scene.tscn"
	add_child((load(path) as PackedScene).instantiate())
	for i in 15:
		await get_tree().process_frame
	var mg: Node = get_tree().root.get_node_or_null("Minigame")
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
		"vn_name", "vn_reaction", "vn_rhythm":
			for step in 25:
				if mg != null and mg.active_name_prompt != null:
					break
				await _click_at(Vector2(640.0, 600.0))
				for f_i in 4:
					await get_tree().process_frame
			if mg != null and mg.active_name_prompt != null:
				for ch_pair in [["m", KEY_M], ["i", KEY_I], ["s", KEY_S], ["h", KEY_H], ["a", KEY_A], ["7", KEY_7], ["+", KEY_EQUAL], ["!", KEY_1]]:
					await _type_char(ch_pair[0], ch_pair[1])
				if state != "vn_name":
					var confirm: Button = mg.active_name_prompt.call("get_confirm_button")
					await _click_at(confirm.get_global_rect().get_center())
					for f_i in 8:
						await get_tree().process_frame
					for step in 4:
						await _click_at(Vector2(640.0, 600.0))
						for f_i in 4:
							await get_tree().process_frame
				if state == "vn_rhythm":
					var balloon: CanvasLayer = get_tree().current_scene.get_node_or_null("VNBalloon")
					for step in 50:
						if balloon != null and (balloon.get("responses_menu") as Control).visible:
							break
						await _click_at(Vector2(640.0, 600.0))
						for f_i in 4:
							await get_tree().process_frame
					if balloon != null:
						var rmenu: Control = balloon.get("responses_menu")
						await get_tree().process_frame
						var choice_btn: Control = rmenu.get_child(1)
						await _click_at(choice_btn.get_global_rect().get_center())
						for step in 12:
							if mg.is_playing:
								break
							await _click_at(Vector2(640.0, 600.0))
							for f_i in 4:
								await get_tree().process_frame
					if mg.is_playing:
						for f_i in 6:
							await get_tree().process_frame
						await _click_at(Vector2(640.0, 320.0))
						await _drag_mouse(Vector2(560.0, 320.0), Vector2(700.0, 320.0))
						await _type_char(" ", KEY_SPACE)
						await _click_at(Vector2(640.0, 320.0))
	for f_i in 8:
		await get_tree().process_frame
	if out_file.begins_with("/"):
		OS.execute("grim", ["-o", "HEADLESS-1", out_file])
		print("CAPTURED: ", out_file)
	for f_i in 4:
		await get_tree().process_frame
	get_tree().quit()
