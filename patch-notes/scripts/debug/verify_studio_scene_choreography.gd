extends SceneTree

## Real new-save, invitation, Studio and title route, using an isolated profile.
## Record presentation samples without mutating the underlying Studio.
class TestStore extends StudioCheckpointStore:
	func acquire() -> bool:
		if _writer != null: return true
		var port := OS.get_environment("PN_CHECKPOINT_TEST_PORT")
		if port.is_empty(): return false
		var server := TCPServer.new()
		if server.listen(int(port), "127.0.0.1") != OK: return false
		_writer = server
		return true

var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failures += 1

func capture(name: String) -> void:
	var folder := OS.get_environment("PN_TRANSITION_CAPTURE_DIR")
	if folder.is_empty() or DisplayServer.get_name() == "headless": return
	DirAccess.make_dir_recursive_absolute(folder)
	RenderingServer.force_draw()
	check(root.get_texture().get_image().save_png(folder.path_join(name + ".png")) == OK, "Captured " + name)

func _initialize() -> void:
	create_timer(120.0).timeout.connect(func():
		push_error("Studio choreography verifier timed out")
		quit(2))
	run.call_deferred()

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	node_added.connect(func(node):
		if node is CheckpointCoordinator:
			node.store = TestStore.new("user://saves/studio", node._validate_payload))
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for i in 4: await process_frame
	var menu: MainMenu = game._active_phase
	var circuits: Control = game.circuit_background
	var circuit_id := circuits.get_instance_id()
	var music: Node = root.get_node("Soundtrack")
	var player: AudioStreamPlayer = music.player
	var start_time: float = music.presentation_seconds()
	menu.studio_created.emit("Transition Studio", &"action", [])
	check(game._transition_in_progress, "New Studio immediately guards against duplicate input")
	menu.studio_created.emit("Duplicate Studio", &"action", [])
	var deadline := Time.get_ticks_msec() + 90000
	var departure_started := Time.get_ticks_msec()
	var departure_capture := false
	var saw_loader := false
	while game._transition_in_progress and Time.get_ticks_msec() < deadline:
		if game.get_node_or_null("NewStudioLoading") != null: saw_loader = true
		if not departure_capture and Time.get_ticks_msec()-departure_started >= 200:
			capture("new-studio-departure"); departure_capture = true
		await process_frame
	check(saw_loader and not game._transition_in_progress, "Creation reaches and leaves its loading screen")
	if game._transition_in_progress or not game._active_phase is StudioPhase:
		game.queue_free(); await process_frame; quit(1); return
	check(game.run_state.get_studio_name() == "Transition Studio", "Repeated create input cannot replace the Studio")
	var guide: GuidedProductionTutorial = game.guided_tutorial
	check(guide != null and not game._active_phase.visible, "New Studio waits behind the tutorial invitation")
	if guide == null:
		game.queue_free(); await process_frame; quit(1); return
	var before := StudioCheckpoint.new().capture(game.run_state)
	var hud: GameplayHUD = game.get_node("%GameplayHUD")
	var studio: StudioPhase = game._active_phase
	guide.choice.emit(true, false)
	var header_ys: Array[float] = []
	var footer_ys: Array[float] = []
	var root_xs: Array[float] = []
	var first_header_motion := -1
	var last_header_motion := -1
	var first_hub_motion := -1
	var sample_deadline := Time.get_ticks_msec() + 2500
	while Time.get_ticks_msec() < sample_deadline:
		await process_frame
		if not is_instance_valid(studio) or not is_instance_valid(studio._hub): break
		var header_y := hud.scoreboard.get_global_rect().position.y
		var footer_y := hud.footer_panel.get_global_rect().position.y
		var hub_x: float = studio._hub._root_panel.get_global_rect().position.x
		var n := header_ys.size()
		if n > 0 and (absf(header_y-header_ys[-1]) > 0.1 or absf(footer_y-footer_ys[-1]) > 0.1):
			if first_header_motion < 0:
				first_header_motion = n
				capture("studio-hud-entering")
			last_header_motion = n
		if n > 0 and absf(hub_x-root_xs[-1]) > 0.1 and first_hub_motion < 0:
			first_hub_motion = n
			capture("studio-hub-entering")
		header_ys.append(header_y); footer_ys.append(footer_y); root_xs.append(hub_x)
	check(first_header_motion >= 0, "Studio header or footer visibly enters after the invitation")
	check(first_hub_motion >= 0, "Studio panel visibly slides in after the invitation")
	check(first_header_motion >= 0 and first_hub_motion > first_header_motion, "Studio HUD begins its entrance before the panel")
	check(first_hub_motion >= last_header_motion, "Studio panel starts after the HUD entrance completes")
	check(StudioCheckpoint.new().capture(game.run_state) == before, "Arrival leaves Studio state, finances and RNG unchanged")
	capture("studio-settled")
	check(is_instance_valid(circuits) and circuits.get_instance_id() == circuit_id and music.player == player and player.playing and music.presentation_seconds() > start_time, "Persistent circuits and soundtrack continue through creation and arrival")
	print("STUDIO_CHOREOGRAPHY samples=%d first_hud=%d last_hud=%d first_hub=%d" % [header_ys.size(), first_header_motion, last_header_motion, first_hub_motion])
	# A returning tutorial can leave a Studio group open. Its companion must
	# stay hidden during the next panel entrance, then return unchanged.
	studio._hub.select_group(&"management")
	var group_deadline := Time.get_ticks_msec()+4000
	while studio._hub.transitioning and Time.get_ticks_msec()<group_deadline: await process_frame
	check(studio._hub.selected == &"management" and studio._hub._companion.visible, "Studio management companion opens before return rehearsal")
	studio._hub.prepare_studio_arrival()
	check(not studio._hub._companion.visible, "Open companion stays hidden during staged panel arrival")
	await studio._hub.animate_studio_arrival()
	check(studio._hub._companion.visible and studio._hub.selected == &"management", "Companion restores its selected group after panel arrival")
	check(StudioCheckpoint.new().capture(game.run_state) == before, "Companion arrival changes no Studio state or RNG")
	var saved: Dictionary = game.checkpoints.store.inspect().get("payload", {}).duplicate(true)
	game.pause_menu.open()
	check(game.pause_menu.is_open(), "Pause opens from the settled Studio")
	game._return_to_main_menu()
	var outgoing_ys: Array[float] = []
	var outgoing_deadline := Time.get_ticks_msec() + 10000
	while (current_scene == null or current_scene == game) and Time.get_ticks_msec() < outgoing_deadline:
		if is_instance_valid(hud):
			outgoing_ys.append(hud.scoreboard.get_global_rect().position.y)
			if outgoing_ys.size() > 1 and absf(outgoing_ys[-1]-outgoing_ys[0]) > 5.0 and not has_meta("departure_captured"):
				set_meta("departure_captured", true)
				capture("studio-hud-exiting")
		await process_frame
	check(current_scene != game and current_scene != null, "Studio return reaches the title through scene replacement")
	if current_scene != game and current_scene != null:
		var title: Control = current_scene
		capture("title-return-start")
		await create_timer(2.0).timeout
		capture("title-return-logo-complete")
		var title_menu: MainMenu = title._active_phase
		var title_deadline := Time.get_ticks_msec()+6000
		while title_menu._boot_entrance and Time.get_ticks_msec() < title_deadline: await process_frame
		capture("title-return-settled")
		check(not title_menu._boot_entrance, "Returned title entrance finishes within its time budget")
		var inspection_deadline := Time.get_ticks_msec()+30000
		while title._title_checkpoint_job != null and Time.get_ticks_msec() < inspection_deadline: await process_frame
		check(title._title_checkpoint_job == null, "Returned title completes checkpoint inspection")
		capture("title-return-ready")
		for action in [&"StartGame", &"Continue", &"HowToPlay", &"Settings", &"Quit"]:
			var button: Button = title_menu._actions[action]
			if not button.visible: continue
			check(button.is_visible_in_tree() and button.modulate.a >= 0.99 and button.mouse_filter != Control.MOUSE_FILTER_IGNORE and button.focus_mode != Control.FOCUS_NONE, "Returned title button is visible and accepts input: " + str(action))
		var header_moved := false
		for i in range(1, outgoing_ys.size()):
			if absf(outgoing_ys[i]-outgoing_ys[0]) > 1.0: header_moved = true
		check(header_moved, "Studio HUD exits before title scene replacement")
		check(title.circuit_background == circuits and music.player == player and player.playing, "Title return retains the same circuits and music transport")
		check(title.checkpoints.store.inspect().get("payload", {}) == saved, "Returning to title does not rewrite or corrupt the Studio checkpoint")
		title.queue_free()
	else:
		game.queue_free()
	await process_frame
	print("STUDIO_CHOREOGRAPHY checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
