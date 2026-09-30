#!/usr/bin/env python3
"""Check first-party GDScript with Godot 4.7's enabled warnings promoted to errors.

Uses an isolated project configuration; never changes the game's warning policy.
Usage: python3 tools/check_scripts.py /path/to/godot
"""
import os
import pathlib
import subprocess
import sys
import tempfile

PROJECT = pathlib.Path(__file__).resolve().parents[1]
GODOT = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("GODOT", "godot")
DUMP = '''extends SceneTree
func _init() -> void:
	for setting: Dictionary in ProjectSettings.get_property_list():
		var key: String = setting.name
		var value: Variant = ProjectSettings.get_setting(key)
		if key.begins_with("debug/gdscript/warnings/") and typeof(value) == TYPE_INT and value == 1:
			print("WARNING_LEVEL:" + key)
	quit()
'''

with tempfile.TemporaryDirectory(prefix="milka-compiler-") as temporary:
    temporary = pathlib.Path(temporary)
    dump = temporary / "warning_levels.gd"
    dump.write_text(DUMP)
    result = subprocess.run([GODOT, "--headless", "--path", str(PROJECT), "--script", str(dump)], text=True, capture_output=True)
    if result.returncode:
        print(result.stdout + result.stderr)
        sys.exit(result.returncode)
    warnings = [line.partition("WARNING_LEVEL:")[2] for line in result.stdout.splitlines() if line.startswith("WARNING_LEVEL:")]
    if not warnings:
        sys.exit("No enabled warning levels found; use Godot 4.7 or newer.")
    isolated = temporary / "project"
    isolated.mkdir()
    for entry in PROJECT.iterdir():
        if entry.name not in ["project.godot", ".git"]:
            (isolated / entry.name).symlink_to(entry, target_is_directory=entry.is_dir())
    config = (PROJECT / "project.godot").read_text()
    config += "\n[debug]\n\n" + "\n".join(key.removeprefix("debug/") + "=2" for key in warnings) + "\n"
    (isolated / "project.godot").write_text(config)
    print(f"Promoting {len(warnings)} enabled warning levels to errors in an isolated project.", flush=True)
    result = subprocess.run([GODOT, "--headless", "--path", str(isolated), "--script", "res://tools/check_scripts.gd"])
    sys.exit(result.returncode)
