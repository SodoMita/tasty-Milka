extends SceneTree
## Enable compiler warnings as errors only for this check; normal game settings
## and vendored addon warning policies are not changed or suppressed.

var failures := 0


func _init() -> void:
	ProjectSettings.set_setting("debug/gdscript/warnings/treat_warnings_as_errors", true)
	for directory: String in ["res://autoloads", "res://scenes"]:
		_check_directory(directory)
	print("First-party compiler check: %d failure(s)" % failures)
	quit(1 if failures else 0)


func _check_directory(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		failures += 1
		return
	for entry: String in directory.get_files():
		if not entry.ends_with(".gd"):
			continue
		var script := load(path.path_join(entry)) as GDScript
		if script == null or script.reload(true) != OK:
			failures += 1
			printerr("[FAIL] " + path.path_join(entry))
	for entry: String in directory.get_directories():
		_check_directory(path.path_join(entry))
