extends Node
## Capture tool: runs the demo and writes PNG frames to docs/screenshots.
## Used for the sway + pixman review pass (see tools/sway_capture.sh); it is not
## part of the game. Safe to run headless — screenshots are skipped when the
## dummy renderer has no framebuffer.

const DEMO := "res://maple_ui/demo/maple_demo.tscn"
const OUT_DIR := "res://docs/screenshots"


func _ready() -> void:
	var packed := load(DEMO) as PackedScene
	if packed == null:
		push_error("capture: could not load %s" % DEMO)
		get_tree().quit(1)
		return
	var demo := packed.instantiate()
	get_tree().root.add_child.call_deferred(demo)
	await _frames(20)
	if demo == null or not is_instance_valid(demo):
		get_tree().quit(1)
		return

	await _shot("%s/maple_title.png" % OUT_DIR)

	demo.open_dialogue()
	await _frames(45)
	await _shot("%s/maple_dialogue.png" % OUT_DIR)
	await _crop("%s/maple_bubble_detail.png" % OUT_DIR, 0.0, 0.5, 0.66, 0.5)

	demo.open_title()
	await _frames(20)
	print("[capture] done")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _viewport_image() -> Image:
	var tex := get_viewport().get_texture()
	if tex == null:
		return null
	var img := tex.get_image()
	if img == null or img.is_empty():
		return null
	return img


func _shot(path: String) -> void:
	await get_tree().process_frame
	var img := _viewport_image()
	if img == null:
		print("[capture] skipped (no framebuffer): %s" % path)
		return
	print("[capture] %s -> %s" % [path, img.save_png(path)])


func _crop(path: String, x: float, y: float, w: float, h: float) -> void:
	await get_tree().process_frame
	var img := _viewport_image()
	if img == null:
		print("[capture] skipped (no framebuffer): %s" % path)
		return
	var size := img.get_size()
	var rect := Rect2i(
		Vector2i(int(size.x * x), int(size.y * y)),
		Vector2i(int(size.x * w), int(size.y * h))
	)
	print("[capture] %s -> %s" % [path, img.get_region(rect).save_png(path)])
