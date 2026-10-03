extends SceneTree
func _initialize() -> void:
	_run()


func _run() -> void:
	change_scene_to_file("res://scenes/title_screen.tscn")
	for i in 40:
		await process_frame
	var title := current_scene
	var block: VBoxContainer = title.find_children("TitleBlock", "VBoxContainer", true, false)[0]
	print("BLOCK: ", block.get_global_rect())
	for child in block.get_children():
		print("  %s -> %s" % [child.name, child.get_global_rect() if child is Control else child])
	print("PROBE DONE")
	quit()
