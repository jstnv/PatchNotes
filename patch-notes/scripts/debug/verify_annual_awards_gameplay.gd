extends SceneTree

var checks := 0
var failures := 0
var failure_context: Control
const OUT := "res://../docs/codex/findings/annual-awards-20261031-v1/ui-integration-native"

class PrivateStore extends StudioCheckpointStore:
	func acquire() -> bool:
		if _writer != null: return true
		var server := TCPServer.new()
		var port := int(OS.get_environment("PN_CHECKPOINT_TEST_PORT"))
		if port < 1: port = 47583
		if server.listen(port, "127.0.0.1") != OK: return false
		_writer = server
		return true

func _initialize() -> void:
	go.call_deferred()

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1
	print("PASS: " if value else "FAIL: ", message)

func finish() -> void:
	print("ANNUAL_AWARDS_GAMEPLAY checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

func settle() -> void:
	for index in 8: await process_frame

func shot(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT.path_join(label + ".png"))

func wait_for(predicate: Callable, label: String, seconds := 90.0) -> bool:
	var started := Time.get_ticks_msec()
	while not predicate.call() and Time.get_ticks_msec() - started < seconds * 1000.0:
		await process_frame
	var passed: bool = predicate.call()
	check(passed, label)
	if not passed and is_instance_valid(failure_context):
		print("SAVE FAILURE CONTEXT: ", failure_context.checkpoints.failure, " action=", failure_context._awards_action, " saving=", failure_context._awards_saving)
	return passed

func ready_ceremony(game: Control, expected_stage: int) -> bool:
	return is_instance_valid(game.annual_awards_ceremony) and game.annual_awards_ceremony.stage == expected_stage and not game._awards_saving and game._awards_action.is_empty() and not game._awards_navigation.busy

func stored_entry(game: Control) -> Dictionary:
	return game.checkpoints.last_payload.get("rival_world", {}).get("annual_awards", {}).get("entries", [{}])[0]

func mount(data: Dictionary, slot: String) -> Control:
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await settle()
	failure_context = game
	game._onboarding.answer(true)
	var adapter := StudioCheckpoint.new()
	var run := adapter.hydrate(data.player)
	var codec := preload("res://scripts/market/rival_world_checkpoint.gd").new()
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var world: RivalWorld = codec.restore(data.world, data.player, run, catalog)
	check(run != null and world != null, "Actual current paired fixture hydrates: " + adapter.error + codec.error)
	if run == null or world == null: game.queue_free(); return null
	game.checkpoints.store = PrivateStore.new("user://annual-gameplay-" + slot, game.checkpoints._validate_payload)
	game.run_state = run
	game.rival_world = world
	game.checkpoints.attach(run)
	check(game.checkpoints.attach_rivals(world, catalog), "Actual Gameplay attaches complete eight-rival world")
	game._connect_rival_calendar()
	game.get_node("%GameplayHUD").setup(null, run)
	check(game.get_node("%GameplayHUD").settings_menu.set_skip_awards(true), "Persistent future-skip fixture is enabled")
	check(game._enter_initial_studio(true), "Actual Gameplay mounts restored Studio")
	return game

func go() -> void:
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await settle()
	check(game.has_method("annual_awards_blocking"), "Actual Gameplay owns ceremony input exclusion")
	check(game.has_method("_queue_annual_awards"), "Actual Gameplay queues durable Studio ceremony")
	if failures:
		game.queue_free()
		await process_frame
		finish(); return
	check(not game.annual_awards_blocking(), "Title does not block for annual awards")
	game.queue_free()
	await settle()
	var fixture := OS.get_environment("PN_AWARDS_UI_FIXTURE")
	if fixture.is_empty():
		print("NOT RUN: set PN_AWARDS_UI_FIXTURE for actual-world integration matrix")
		finish(); return
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(fixture))
	game = await mount(data, "first")
	if game == null: finish(); return
	if "--later-only" in OS.get_cmdline_user_args() or "--later-final-only" in OS.get_cmdline_user_args() or "--later-manual" in OS.get_cmdline_user_args():
		var index: int = game.rival_world.pending_awards_index()
		check(index > 0 and game.rival_world.annual_awards.entries[0].complete, "Genuine later-year fixture follows completed first presentation")
		if index < 1: game.queue_free(); await settle(); finish(); return
		var before := StudioCheckpoint.new().capture(game.run_state)
		if "--later-manual" in OS.get_cmdline_user_args():
			check(game.get_node("%GameplayHUD").settings_menu.set_skip_awards(false), "Later manual presentation preference is persisted")
			if await wait_for(func(): return ready_ceremony(game,0), "Later ceremony opens when preference is false"):
				check(game.annual_awards_ceremony.skip_button.visible, "Later ceremony exposes Skip to results")
				game.annual_awards_ceremony.skip_button.pressed.emit()
				game.annual_awards_ceremony.skip_button.pressed.emit()
				check(game.annual_awards_ceremony.stage == 0 and game._awards_saving, "Skip waits for durable results and rejects duplicate")
				if await wait_for(func(): return ready_ceremony(game,9), "Later Skip reaches durable final results"):
					check(game.checkpoints.last_payload.rival_world.annual_awards.entries[index].stage == "9", "Later final result matches durable stage9")
					game.annual_awards_ceremony.next_button.pressed.emit()
		else:
			if "--later-final-only" in OS.get_cmdline_user_args():
				check(game.rival_world.advance_awards_stage(true), "Prepare genuine later final-stage resume")
		if await wait_for(func(): return not game.annual_awards_blocking() and game.rival_world.pending_awards_index() == -1, "Later ceremony completes durably under selected presentation policy"):
			var entry: Dictionary = game.checkpoints.last_payload.rival_world.annual_awards.entries[index]
			check(entry.complete and entry.stage == "9", "Later completion is stored exactly once")
			check(game.annual_awards_ceremony == null and game._active_phase.visible and game.get_node("%GameplayHUD").visible, "Later completion restores actual Studio and HUD")
			check(StudioCheckpoint.new().capture(game.run_state) == before, "Later presentation policy preserves owner DTO")
		await shot("later-completed")
		game.queue_free(); await settle(); finish(); return
	if "--focus-only" in OS.get_cmdline_user_args():
		for stage in 9: check(game.rival_world.advance_awards_stage(), "Prepare genuine resumed-stage9 progress")
		if await wait_for(func(): return ready_ceremony(game,9), "Genuine resumed stage9 is durable"):
			game.annual_awards_ceremony.next_button.pressed.emit()
			await wait_for(func(): return game.annual_awards_ceremony == null and not game._awards_waiting, "Resumed stage9 Exit completes durably")
			check(root.gui_get_focus_owner() != null and root.gui_get_focus_owner().is_visible_in_tree(), "Visible Studio focus restores after a result with no preexisting focus")
		game.queue_free(); await settle(); finish(); return
	root.size = Vector2i(1152,648); root.content_scale_size = root.size
	if not await wait_for(func(): return ready_ceremony(game, 0), "First ceremony appears after genuine durable world checkpoint"):
		game.queue_free(); await settle(); finish(); return
	var studio: Control = game._active_phase
	var hud: Control = game.get_node("%GameplayHUD")
	var result: Dictionary = game.rival_world.get_annual_awards().entries[0].result
	var owner_before := StudioCheckpoint.new().capture(game.run_state)
	var frozen_before := var_to_bytes(result)
	check(game.annual_awards_blocking() and not game.pause_menu.can_pause.call(), "Mandatory overlay excludes Pause")
	check(game._active_phase == studio and not studio.visible and not hud.visible, "Retained actual Studio and HUD are hidden")
	check(not game.developer_tools._safe_studio(), "Developer sandbox refuses ceremony Studio")
	game.developer_tools.open()
	check(not game.developer_tools.panel.visible, "Developer open is blocked")
	for code: Key in [KEY_F8, KEY_ESCAPE]:
		var event := InputEventKey.new(); event.keycode = code; event.pressed = true
		Input.parse_input_event(event)
		await process_frame
	check(not game.pause_menu.is_open() and not game.developer_tools.panel.visible and ready_ceremony(game,0), "F8 and Escape cannot cover or abandon ceremony")
	check(game.annual_awards_ceremony.skip_button.visible == false and stored_entry(game).stage == "0", "First ceremony overrides persisted skip and saves initial stage")
	check(not game._begin_next_project(studio, "Blocked during Awards", &"action", &"fantasy"), "Pending ceremony refuses a new production departure")
	await shot("first-1152")
	game.annual_awards_ceremony.next_button.pressed.emit()
	game.annual_awards_ceremony.next_button.pressed.emit()
	check(game.annual_awards_ceremony.stage == 0 and game._awards_saving and game.rival_world.annual_awards.entries[0].stage == 1, "Next retains old page while save owns new progress; duplicate rejected")
	if not await wait_for(func(): return ready_ceremony(game,1), "First Next reaches durable stage1"):
		game.queue_free(); await settle(); finish(); return
	check(stored_entry(game).stage == "1", "Visible stage1 matches stored stage")
	for stage in [2,3]:
		game.annual_awards_ceremony.next_button.pressed.emit()
		if not await wait_for(func(): return ready_ceremony(game,stage), "Durable Next stage%d" % stage):
			game.queue_free(); await settle(); finish(); return
		check(stored_entry(game).stage == str(stage), "Frozen page has matching durable stage%d" % stage)
	game._continue_checkpoint()
	await settle()
	check(game.guided_tutorial == null, "Continue does not reopen the tutorial invitation")
	if not await wait_for(func(): return ready_ceremony(game,3), "Continue resumes exact saved stage3"):
		game.queue_free(); await settle(); finish(); return
	studio = game._active_phase; hud = game.get_node("%GameplayHUD")
	root.size = Vector2i(1280,720); root.content_scale_size = root.size
	await settle()
	check(var_to_bytes(game.rival_world.annual_awards.entries[0].result) == frozen_before, "Continue preserves exact frozen rankings and rewards")
	await shot("continued-stage3-1280")
	game.checkpoints.store.fault = &"before_write"
	game.annual_awards_ceremony.next_button.pressed.emit()
	if not await wait_for(func(): return not game._awards_saving and not game.checkpoints.failure.is_empty(), "Injected durable-write failure reaches normal checkpoint recovery"):
		game.queue_free(); await settle(); finish(); return
	check(game.annual_awards_ceremony.stage == 3 and game.rival_world.annual_awards.entries[0].stage == 4 and stored_entry(game).stage == "3", "Failed save keeps old page while pending stage remains once-only")
	check(game._save_failure_dialog.visible and game.annual_awards_ceremony.next_button.disabled and not studio.visible and not hud.visible, "Failed-save ceremony remains modal with normal Retry")
	game.annual_awards_ceremony.next_button.pressed.emit()
	check(game.rival_world.annual_awards.entries[0].stage == 4, "Failed-save duplicate cannot consume another stage")
	game.checkpoints.store.fault = &""
	game._retry_checkpoint_save()
	if not await wait_for(func(): return ready_ceremony(game,4), "Retry saves pending progress and resumes stage4 once"):
		game.queue_free(); await settle(); finish(); return
	check(stored_entry(game).stage == "4" and not game._save_failure_dialog.visible, "Retry publishes exact stage and dismisses recovery")
	for stage in [5,6,7,8,9]:
		game.annual_awards_ceremony.next_button.pressed.emit()
		if not await wait_for(func(): return ready_ceremony(game,stage), "Durable Next stage%d" % stage):
			game.queue_free(); await settle(); finish(); return
		check(stored_entry(game).stage == str(stage), "Final award page matches stored stage%d" % stage)
	await shot("final-1280")
	var settings: DemoSettingsMenu = hud.settings_menu
	var path := settings.settings_path
	settings.settings_path = "user://missing-annual-preference/prefs.cfg"
	game.annual_awards_ceremony.skip_checkbox.button_pressed = false
	check(game.annual_awards_ceremony.skip_checkbox.button_pressed and settings.committed.skip_awards, "Failed final preference write restores committed checkbox")
	settings.settings_path = path
	game.annual_awards_ceremony.skip_checkbox.button_pressed = false
	check(not settings.committed.skip_awards and not DemoSettingsStore.read_settings(path).values.skip_awards, "Final checkbox persists future presentation choice")
	game.annual_awards_ceremony.next_button.pressed.emit()
	game.annual_awards_ceremony.next_button.pressed.emit()
	if not await wait_for(func(): return game.annual_awards_ceremony == null and not game._awards_waiting, "Final Exit becomes durable before returning Studio"):
		game.queue_free(); await settle(); finish(); return
	check(game._active_phase == studio and studio.visible and hud.visible and not game.annual_awards_blocking(), "Same Studio/HUD restore after completion")
	check(root.gui_get_focus_owner() != null and root.gui_get_focus_owner().is_visible_in_tree(), "Valid retained Studio focus restores")
	check(stored_entry(game).complete and stored_entry(game).stage == "9", "Completed final stage is durable")
	check(StudioCheckpoint.new().capture(game.run_state) == owner_before and var_to_bytes(game.rival_world.annual_awards.entries[0].result) == frozen_before, "All presentation actions preserve exact owner DTO and result")
	game._queue_annual_awards()
	await settle()
	check(game.annual_awards_ceremony == null and game.rival_world.pending_awards_index() == -1, "Completed ceremony never replays")
	await shot("restored-studio-1280")
	game.queue_free()
	await settle()
	game = await mount(data, "teardown")
	if game == null: finish(); return
	if not await wait_for(func(): return ready_ceremony(game,0), "Teardown fixture starts from real durable first result"):
		game.queue_free(); await settle(); finish(); return
	game.annual_awards_ceremony.next_button.pressed.emit()
	check(game._awards_saving, "Teardown begins during an actual background stage save")
	var destroyed: WeakRef = weakref(game)
	game.queue_free()
	await settle()
	check(destroyed.get_ref() == null and not root.gui_disable_input, "Async teardown destroys owner and releases all presentation input")
	finish()
