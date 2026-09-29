extends Node
## Native Start + persistence smoke test against the shipped scene/resource.
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
	var scene: Node = load("res://scenes/vn_scene.tscn").instantiate()
	add_child(scene)
	for i in range(20):
		await get_tree().process_frame
	var balloon: Node = get_tree().root.find_child("VNBalloon", true, false)
	check(balloon != null, "Start instantiates the existing VN balloon")
	if balloon == null:
		get_tree().quit(1)
		return
	balloon.button_sfx = false
	balloon.typewriter_sfx = false
	check(balloon.dialogue_line != null, "The first dialogue line is resolved")
	print("Initial tags: ", balloon.dialogue_line.tags)
	print("Initial background: ", balloon._current_bg)
	check(balloon._current_bg == "milky_meadow", "First line stages the meadow")
	check(balloon.background.texture != null, "First background texture is visible")
	check(balloon.stage_actors.actors.has("milka_chan"), "Start shows a live 2D actor")
	if balloon.stage_actors.actors.has("milka_chan"):
		var actor_root: Node = balloon.stage_actors.actors["milka_chan"].root
		var actor_animation: AnimationPlayer = actor_root.find_child("Anim", true, false)
		check(actor_animation != null and actor_animation.is_playing(), "Actor idle animation is playing")
	check(balloon.history.size() > 0, "Initial line is recorded in history")
	check(balloon.save_to_slot(864210) == OK, "A native save can be written")
	balloon._set_background("none")
	balloon.load_from_slot(864210)
	for i in range(10):
		await get_tree().process_frame
	check(balloon._current_bg == "milky_meadow", "Loading restores the background key")
	check(balloon.background.texture != null, "Loading restores the background texture")
	DirAccess.remove_absolute("user://saves/slot_864210.json")
	scene.queue_free()
	balloon.queue_free()
	scene = null
	balloon = null
	await get_tree().create_timer(1.0).timeout
	print("Milk Start: %d passed, %d failed" % [passes, failures])
	get_tree().quit.call_deferred(0 if failures == 0 else 1)
