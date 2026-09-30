extends Node
## Run with Godot 4.7: --headless res://tests/test_rotation.tscn.
## Exercise the real authored controls, not only the transform helper.

const Rotation = preload("res://scenes/display_rotation.gd")
var passes := 0
var failures := 0


func check(ok: bool, message: String) -> void:
	print(("[PASS] " if ok else "[FAIL] ") + message)
	if ok:
		passes += 1
	else:
		failures += 1


func frames(count: int = 4) -> void:
	for _frame in count:
		await get_tree().process_frame


func covers_window(control: Control, window_size: Vector2) -> bool:
	var pose := control.get_global_transform_with_canvas()
	var points: Array[Vector2] = [pose * Vector2.ZERO, pose * Vector2(control.size.x, 0), pose * control.size, pose * Vector2(0, control.size.y)]
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point: Vector2 in points:
		bounds = bounds.expand(point)
	return bounds.position.length() < 0.05 and bounds.size.distance_to(window_size) < 0.05


func click(control: Control) -> void:
	var point := control.get_global_transform_with_canvas() * (control.size * 0.5)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.global_position = point
	event.pressed = true
	get_viewport().push_input(event, true)
	await frames(2)
	event = event.duplicate() as InputEventMouseButton
	event.pressed = false
	get_viewport().push_input(event, true)
	await frames(2)


func _ready() -> void:
	_run()


func _run() -> void:
	var store := get_node("/root/SettingsStore")
	var existed := FileAccess.file_exists("user://settings.json")
	var saved := FileAccess.get_file_as_string("user://settings.json") if existed else ""
	var original_size := get_tree().root.size
	store.data = {"language": "en", "rotation": 0, "ui_scale": 1.0, "sfx_buttons": false}
	store.save_settings()
	TranslationServer.set_locale("en")

	check(Rotation.normalize(-90) == 270 and Rotation.normalize(450) == 90 and Rotation.normalize(45) == 0, "angles normalize to valid quarter turns")
	var title := (load("res://scenes/title_screen.tscn") as PackedScene).instantiate() as Control
	add_child(title)
	await frames()
	var menu := title.get_node("SettingsPanel") as SettingsMenu
	for angle: int in [0, 90, 180, 270]:
		menu.open()
		var button := menu.get_node("%%Rot%dButton" % angle) as Button
		check(button != null and button.pressed.get_connections().size() > 0, "title rotation %d has a live authored connection" % angle)
		button.pressed.emit()
		await frames()
		var window_size := get_viewport().get_visible_rect().size
		check(int(store.get_value("rotation", -1)) == angle, "title rotation %d is persisted" % angle)
		check(is_equal_approx(title.rotation, deg_to_rad(float(angle))), "title applies %d immediately" % angle)
		check(covers_window(title, window_size), "title %d fills every window edge" % angle)
		check(covers_window(menu, window_size), "title settings %d remain fullscreen" % angle)
		check(button.button_pressed, "title %d shows the selected angle" % angle)
		await click(menu.close_button)
		check(not menu.visible, "real transformed click closes title settings at %d" % angle)

	store.set_values({"rotation": 90, "ui_scale": 1.5})
	await frames()
	for physical: Vector2i in [Vector2i(720, 1280), Vector2i(1280, 720)]:
		get_tree().root.size = physical
		await frames(8)
		var window_size := get_viewport().get_visible_rect().size
		check(covers_window(title, window_size), "title follows physical resize %s while rotated" % physical)
		check(covers_window(menu, window_size), "scaled title settings follow physical resize %s" % physical)
	menu.open()
	await frames()
	await click(menu.close_button)
	check(not menu.visible, "scaled and rotated settings retain real pointer input")
	title.queue_free()
	await frames()

	var balloon := (load("res://scenes/vn_balloon.tscn") as PackedScene).instantiate() as VNBalloon
	add_child(balloon)
	balloon.balloon.show()
	await frames()
	check(balloon.rotation_deg == 90, "game inherits title's saved rotation")
	for angle: int in [0, 90, 180, 270]:
		balloon.settings_button.pressed.emit()
		await frames()
		(balloon.settings_panel.get_node("%%Rot%dButton" % angle) as Button).pressed.emit()
		await frames()
		var window_size := get_viewport().get_visible_rect().size
		check(balloon.rotation_deg == angle, "game rotation %d applies immediately" % angle)
		check(covers_window(balloon.balloon, window_size), "game %d fills every window edge" % angle)
		check(covers_window(balloon.settings_panel, window_size), "game settings %d remain fullscreen with UI scale" % angle)
		check((balloon.settings_panel.get_node("%%Rot%dButton" % angle) as Button).button_pressed, "game %d shows the selected angle" % angle)
		await click(balloon.settings_close_button)
		check(not balloon.settings_panel.visible, "real transformed click closes game settings at %d" % angle)
	balloon.queue_free()
	await frames()

	# A newly loaded title must restore the angle written by the game.
	title = (load("res://scenes/title_screen.tscn") as PackedScene).instantiate() as Control
	add_child(title)
	await frames()
	check(is_equal_approx(title.rotation, deg_to_rad(270.0)), "returning to title restores the game's saved rotation")
	title.queue_free()
	await frames()
	get_tree().root.size = original_size
	if existed:
		var file := FileAccess.open("user://settings.json", FileAccess.WRITE)
		file.store_string(saved)
		file.close()
	else:
		DirAccess.remove_absolute("user://settings.json")
	store.load_settings()
	store.apply_globals()
	print("Rotation: %d passed; %d failed" % [passes, failures])
	get_tree().quit(1 if failures else 0)
