extends SceneTree

## Real Studio hub, fixed phases: check actual button edges instead of config.
const Hub := preload("res://scripts/ui/studio_hub.gd")
const KEYS: Array[StringName] = [&"studio_info", &"management", &"market", &"production"]
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failures += 1

func edges(control: Control) -> Vector2:
	var transform := control.get_global_transform()
	return Vector2((transform * Vector2.ZERO).x, (transform * Vector2(control.size.x, 0)).x)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.size = Vector2i(1152, 648)
	root.content_scale_size = root.size
	var host := Control.new()
	root.add_child(host)
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var motion := MenuTransitions.new()
	motion.automatic_entrances = false
	host.add_child(motion)
	var hub := Hub.new()
	hub.motion = motion
	host.add_child(hub)
	hub.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for id: StringName in KEYS:
		hub.add_group(id, str(id).capitalize())
	for frame in 5: await process_frame
	hub.set_process(false)
	var wave: Node = hub.get("_wave")
	check(absf(float(wave.get("travel")) / float(wave.get("period")) - 7.0 / 3.6) < 0.001,
		"Studio bounce retains the previous travel-to-period speed")
	for screen in [Vector2i(1152,648), Vector2i(1600,900)]:
		root.size = screen
		root.content_scale_size = screen
		for frame in 5: await process_frame
		for id: StringName in KEYS:
			var button: Button = hub.root_buttons[id]
			var index: int = wave.get("_buttons").find(button)
			var phases: PackedFloat64Array = wave.get("_phases")
			var weights: PackedFloat32Array = wave.get("_hover_weights")
			weights[index] = 0.0
			wave.set("_hover_weights", weights)
			phases[index] = 0.0
			wave.set("_phases", phases)
			wave.call("_apply_poses")
			var min_edges := edges(button)
			phases[index] = PI
			wave.set("_phases", phases)
			wave.call("_apply_poses")
			var max_edges := edges(button)
			check(absf(max_edges.x - min_edges.x - 3.0) < 0.05 and absf(max_edges.y - min_edges.y - 3.0) < 0.05,
				"%s %s bounces three pixels total" % [screen, id])
			weights[index] = 1.0
			wave.set("_hover_weights", weights)
			for phase in [0.0, PI]:
				phases[index] = phase
				wave.set("_phases", phases)
				wave.call("_apply_poses")
				var hovered := edges(button)
				check(absf(hovered.x - min_edges.x) < 0.05 and absf(hovered.y - max_edges.y) < 0.05,
					"%s %s stretched bounds match bounce extremes at phase %.2f" % [screen, id, phase])
			if DisplayServer.get_name() != "headless" and id == &"production":
				await RenderingServer.frame_post_draw
				var path := "user://studio-wave-%dx%d.png" % [screen.x, screen.y]
				check(root.get_texture().get_image().save_png(path) == OK, "%s native screenshot saved" % screen)
			weights[index] = 0.0
			wave.set("_hover_weights", weights)
	host.queue_free()
	await process_frame
	print("STUDIO_WAVE_BOUNDS checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
