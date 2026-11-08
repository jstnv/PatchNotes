extends SceneTree

class TestStore extends StudioCheckpointStore:
	func acquire() -> bool:
		var port := OS.get_environment("PN_CHECKPOINT_TEST_PORT")
		if port.is_empty(): return false
		if _writer != null: return true
		var server := TCPServer.new()
		if server.listen(int(port),"127.0.0.1") != OK: return false
		_writer = server
		return true

var checks := 0
var failures := 0

func expect(ok: bool, label: String) -> void:
	checks += 1
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok: failures += 1

func wait_until(condition: Callable, timeout_ms: int = 90000) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_ms
	while not condition.call() and Time.get_ticks_msec() < deadline:
		await process_frame
	return condition.call()

func _replace_store(node: Node) -> void:
	if node is CheckpointCoordinator:
		node.store = TestStore.new("user://saves/studio", node._validate_payload)

func _initialize() -> void:
	go.call_deferred()

func go() -> void:
	create_timer(220.0).timeout.connect(func(): push_error("Real boundary route timeout"); quit(2))
	node_added.connect(_replace_store)
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var menu: MainMenu = game._active_phase as MainMenu
	expect(menu != null, "Main Menu opens")
	if menu == null: quit(1); return
	if not await wait_until(func(): return game._title_checkpoint_job == null and menu.checkpoint_info.get("status") != &"checking"):
		expect(false, "Initial Main Menu completes checkpoint inspection"); quit(1); return
	game._on_studio_created("Trial Player", &"action", [], menu)
	await process_frame
	if not game._active_phase is StudioPhase:
		expect(false, "New Studio creation completes"); quit(1); return
	await preload("res://scripts/debug/ui_test_actions.gd").finish_new_save(game)
	if not await wait_until(func(): return not game._transition_in_progress):
		expect(false, "Studio entrance completes"); quit(1); return
	expect(game._active_phase is StudioPhase and game.rival_world != null and game.rival_world.studios.size() == 8, "Studio opens with eight rivals")
	var studio: StudioPhase = game._active_phase
	studio._open_rival_info()
	await create_timer(MenuTransitions.ENTRANCE_SECONDS + 0.08).timeout
	var info: Control = studio._rival_info
	expect(info != null and info.is_visible_in_tree() and info.entries.size() == 8 and info.table.get_column_title(0) == "Studio" and info.table.get_column_title(3) == "Bankroll", "Rival Info exposes all eight labeled rival facts")
	if info != null: info.close()
	await create_timer(MenuTransitions.ENTRANCE_SECONDS + 0.08).timeout
	expect(game.checkpoints.store.inspect().status == &"valid", "Initial player and rival checkpoint is valid")
	studio._open_market()
	await create_timer(0.5).timeout
	var market: MarketBrowser = studio._market_browser
	expect(market != null and market.is_visible_in_tree() and market.rows.size() > 0, "Daily Chart opens with actual rival releases")
	if market != null: market.close()
	await create_timer(0.5).timeout
	var old_cycle: int = game.rival_world.cycle
	expect(game.run_state.complete_productive_action(Callable(), 0, old_cycle), "A real productive Studio action succeeds")
	expect(game.rival_world.cycle == old_cycle + 1, "The rival world advances once")
	var checkpoint_before_exit: Dictionary = game.checkpoints.store.inspect()
	expect(checkpoint_before_exit.status == &"valid" and int(checkpoint_before_exit.payload.rival_world.cycle) == old_cycle and game.checkpoints.pending, "Ordinary Studio action stays pending until the exit save boundary")
	var live_cash: int = game.run_state.get_cash_cents()
	var old_game: WeakRef = weakref(game)
	game.pause_menu.open()
	expect(game.pause_menu.is_open(), "Pause opens")
	game.pause_menu.main_menu_button.pressed.emit()
	if not await wait_until(func(): return old_game.get_ref() == null):
		expect(false, "Studio-to-Main-Menu transition completes"); quit(1); return
	if not await wait_until(func(): return current_scene != null and current_scene._active_phase is MainMenu and current_scene._title_checkpoint_job == null and not current_scene._transition_in_progress and current_scene._active_phase.checkpoint_info.get("status") != &"checking"):
		expect(false, "Main Menu finishes inspecting the saved checkpoint"); quit(1); return
	var new_game: Node = current_scene
	var new_menu: MainMenu = new_game._active_phase
	expect(new_menu.checkpoint_info.get("status") == &"valid", "Main Menu finds the saved checkpoint")
	new_menu.continue_requested.emit()
	if not await wait_until(func(): return is_instance_valid(new_game) and new_game._active_phase is StudioPhase and not new_game._loading_checkpoint):
		expect(false, "Continue finishes loading Studio"); quit(1); return
	expect(new_game.rival_world != null and new_game.rival_world.cycle == old_cycle + 1, "Continue restores the advanced rival world exactly once")
	expect(new_game.run_state.get_completed_run_cycles() == old_cycle + 1 and new_game.run_state.get_cash_cents() == live_cash, "Continue restores the player cycle and cash")
	var restored_studio: StudioPhase = new_game._active_phase
	restored_studio._open_market()
	await create_timer(0.5).timeout
	expect(restored_studio._market_browser != null and restored_studio._market_browser.rows.size() > 0, "Daily Chart remains populated after Continue")
	new_game.checkpoints.store.release_writer()
	print("REAL_DAILY_BOUNDARY checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
