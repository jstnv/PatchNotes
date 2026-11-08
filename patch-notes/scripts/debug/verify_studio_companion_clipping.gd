extends SceneTree

## Exercises real Studio hierarchy, including ancestors that clip drawing.
const Factory := preload("res://scripts/simulation/run_factory.gd")
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failures += 1

func _initialize() -> void: run.call_deferred()

func crop_is_hidden(hub: Control) -> bool:
	var companion: Control = hub._companion
	var rect := companion.get_global_rect()
	var root_right: float = hub._root_panel.get_global_rect().end.x
	var node: Node = companion.get_parent()
	while is_instance_valid(node):
		if node is Control and node.clip_contents:
			var clip_left: float = node.get_global_rect().position.x
			if clip_left > root_right + 1.0 and clip_left > rect.position.x + 1.0 and clip_left < rect.end.x - 1.0:
				print("EXPOSED_CROP left=", clip_left, " companion=", rect, " studio_right=", root_right, " ancestor=", node.get_path())
				return false
		node = node.get_parent()
	return true

func canvas_z(item: Control) -> int:
	var node: Node = item
	var value := 0
	while node is CanvasItem:
		value += node.z_index
		if not node.z_as_relative: break
		node = node.get_parent()
	return value

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	var out := OS.get_environment("PN_COMPANION_CAPTURE")
	if out.is_empty(): return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(out)
	var result := root.get_texture().get_image().save_png(out.path_join(label + ".png"))
	check(result == OK, "Captured " + label)

func pointer_click(button: Button) -> void:
	var point := button.get_global_rect().get_center()
	var move := InputEventMouseMotion.new()
	move.position = point
	move.global_position = point
	root.push_input(move, true)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
	await process_frame

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var run_state: RunState = Factory.create_fresh_session({"schema_version":1,"studio_id":"clip","studio_name":"Clip","specialty":"action","traits":[],"seed":"4417"},catalog).run
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for i in 4: await process_frame
	game._onboarding.answer(true)
	game.focused_guidance.automatic_enabled = false
	game.run_state = run_state
	var hud: GameplayHUD = game.get_node("%GameplayHUD")
	hud.setup(null, run_state)
	check(game._enter_initial_studio(true), "Actual Studio mounts")
	for i in 5: await process_frame
	var studio: StudioPhase = game._active_phase
	var hub = studio._hub
	var bad_entry := false
	var entry_frames := 0
	var midpoint_frames := 0
	var midpoint_in_front := false
	var entry_fades := false
	hub.root_buttons[&"management"].pressed.emit()
	var deadline := Time.get_ticks_msec() + 5000
	while hub.transitioning and Time.get_ticks_msec() < deadline:
		if hub._companion.visible:
			entry_frames += 1
			if hub._companion.modulate.a > 0.05 and hub._companion.modulate.a < 0.95: entry_fades = true
			if not crop_is_hidden(hub): bad_entry = true
			var comp_rect: Rect2 = hub._companion.get_global_rect()
			var root_rect: Rect2 = hub._root_panel.get_global_rect()
			if comp_rect.position.x >= root_rect.get_center().x and comp_rect.position.x < root_rect.end.x - 1.0:
				midpoint_frames += 1
				if canvas_z(hub._companion) >= canvas_z(hub._root_panel): midpoint_in_front = true
				if midpoint_frames == 1: await capture("management-midpoint")
		await process_frame
	check(entry_frames > 0, "Sampled Management entrance frames")
	check(midpoint_frames > 0, "Companion passes over the Studio midpoint during entrance")
	check(not midpoint_in_front, "Companion is behind the Studio panel at the midpoint")
	check(entry_fades, "Companion fades in during its entrance")
	check(not bad_entry, "No clip boundary cuts the emerging submenu outside the Studio panel")
	check(not hub.transitioning and hub.selected == &"management", "Management settles")
	check(crop_is_hidden(hub), "Settled Management is not clipped at its left edge")
	await capture("management-settled")
	var bad_exit := false
	var exit_frames := 0
	var exit_midpoint_frames := 0
	var exit_midpoint_in_front := false
	var exit_fades := false
	hub.root_buttons[&"management"].pressed.emit()
	deadline = Time.get_ticks_msec() + 5000
	while hub.transitioning and Time.get_ticks_msec() < deadline:
		if hub._companion.visible:
			exit_frames += 1
			if hub._companion.modulate.a > 0.05 and hub._companion.modulate.a < 0.95: exit_fades = true
			if not crop_is_hidden(hub): bad_exit = true
			var comp_rect: Rect2 = hub._companion.get_global_rect()
			var root_rect: Rect2 = hub._root_panel.get_global_rect()
			if comp_rect.position.x >= root_rect.get_center().x and comp_rect.position.x < root_rect.end.x - 1.0:
				exit_midpoint_frames += 1
				if canvas_z(hub._companion) >= canvas_z(hub._root_panel): exit_midpoint_in_front = true
				if exit_midpoint_frames == 1: await capture("management-exiting")
		await process_frame
	check(exit_frames > 0, "Sampled Management exit frames")
	check(exit_midpoint_frames > 0, "Companion passes over the Studio midpoint during exit")
	check(not exit_midpoint_in_front, "Companion is behind the Studio panel at the midpoint during exit")
	check(exit_fades, "Companion fades out during its exit")
	check(not bad_exit, "No clip boundary cuts the retracting submenu outside the Studio panel")
	for id: StringName in [&"studio_info", &"management", &"market", &"production"]:
		hub.root_buttons[id].pressed.emit()
		deadline = Time.get_ticks_msec() + 5000
		while hub.transitioning and Time.get_ticks_msec() < deadline: await process_frame
		check(hub.selected == id and hub.groups[id].is_visible_in_tree() and crop_is_hidden(hub), "Full settled submenu visible: " + str(id))
		hub.root_buttons[id].pressed.emit()
		deadline = Time.get_ticks_msec() + 5000
		while hub.transitioning and Time.get_ticks_msec() < deadline: await process_frame
		check(hub.selected.is_empty(), "Selected submenu closes: " + str(id))
	await pointer_click(hub.root_buttons[&"management"])
	deadline = Time.get_ticks_msec() + 5000
	while hub.transitioning and Time.get_ticks_msec() < deadline: await process_frame
	check(hub.selected == &"management", "Pointer opens Management")
	var engines := studio.get_node("%StudioEnginesButton") as Button
	await pointer_click(engines)
	deadline = Time.get_ticks_msec() + 5000
	while studio._hub_motion.busy and Time.get_ticks_msec() < deadline: await process_frame
	check(is_instance_valid(studio._engine_browser) and studio._engine_browser.visible, "Pointer opens Engines from the uncropped companion")
	game.queue_free()
	for i in 2: await process_frame
	print("STUDIO_COMPANION_CLIPPING checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
