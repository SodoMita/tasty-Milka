extends Node
## Smoke test for the authored title scene. No runtime UI construction.

var failures := 0
var passes := 0

func check(condition: bool, message: String) -> void:
	if condition:
		passes += 1
		print("[PASS] ", message)
	else:
		failures += 1
		push_error("[FAIL] " + message)

func _ready() -> void:
	var config_path := "user://milka_title.cfg"
	var had_config := FileAccess.file_exists(config_path)
	var original_config := FileAccess.get_file_as_string(config_path) if had_config else ""
	var title: Control = load("res://scenes/title_screen.tscn").instantiate()
	add_child(title)
	await get_tree().process_frame
	# No audio playback is needed by this deterministic UI smoke test.
	title.sound_check.button_pressed = false
	check(title.get_node("Menu/StartButton") is Button, "Start is an authored Button")
	check(title.get_node("Menu/LoadButton") is Button, "Load is an authored Button")
	check(not title.get_node("Overlay").visible, "Overlays start closed")
	var glass: StyleBoxFlat = title.theme.get_stylebox("normal", "Button")
	check(glass.bg_color.a < 1.0 and glass.bg_color.a > 0.1, "Milk-glass buttons are transparent")
	check(glass.border_color.a > 0.8, "Glass has a bright milk edge")
	var character: Sprite2D = title.get_node("TitleCharacter/Portrait")
	check(character.texture != null, "Replaceable character texture is loaded")
	var idle: AnimationPlayer = title.get_node("TitleCharacter/AnimationPlayer")
	check(idle.has_animation("idle"), "Character idle is an authored animation")
	check(idle.get_animation("idle").loop_mode == Animation.LOOP_LINEAR, "Character idle loops")
	idle.seek(2.8, true)
	check(character.position.y < -1.0, "Idle animation moves the 2D character")
	title.get_node("Menu/SettingsButton").pressed.emit()
	check(title.get_node("Overlay").visible, "Settings opens its authored overlay")
	check(title.get_node("Overlay/Center/SettingsPanel").visible, "Settings panel becomes visible")
	var reduce_motion: CheckButton = title.get_node("Overlay/Center/SettingsPanel/Content/MotionCheck")
	reduce_motion.button_pressed = true
	check(not idle.is_playing(), "Reduced motion pauses character animation")
	var volume: HSlider = title.get_node("Overlay/Center/SettingsPanel/Content/VolumeSlider")
	volume.value = 37.0
	var persisted := ConfigFile.new()
	check(persisted.load(config_path) == OK, "Preferences are persisted")
	check(float(persisted.get_value("player", "volume", -1)) == 37.0, "Volume survives a settings read")
	title.get_node("Overlay/Center/SettingsPanel/Content/SettingsClose").pressed.emit()
	check(not title.get_node("Overlay").visible, "Done closes settings")
	title.get_node("AboutButton").pressed.emit()
	check(title.get_node("Overlay/Center/AboutPanel").visible, "About opens the authored panel")
	var cancel := InputEventAction.new()
	cancel.action = "ui_cancel"
	cancel.pressed = true
	title._unhandled_input(cancel)
	check(not title.get_node("Overlay").visible, "Escape closes the current panel")

	DirAccess.make_dir_recursive_absolute("user://saves")
	var fixture_path := "user://saves/slot_864209.json"
	var fixture := FileAccess.open(fixture_path, FileAccess.WRITE)
	fixture.store_string(JSON.stringify({"history": [{"text": "test only"}], "meta": {"when": "9999-12-31T23:59:59"}}))
	fixture.close()
	check(title._find_latest_slot() == 864209, "Continue scans arbitrary save slots, not a fixed subset")
	DirAccess.remove_absolute(fixture_path)

	title.queue_free()
	await get_tree().process_frame
	if had_config:
		var restore := FileAccess.open(config_path, FileAccess.WRITE)
		restore.store_string(original_config)
		restore.close()
	else:
		DirAccess.remove_absolute(config_path)
	print("Milk title: %d passed, %d failed" % [passes, failures])
	get_tree().quit(0 if failures == 0 else 1)
