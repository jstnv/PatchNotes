## Run with PN_CHECKPOINT_TEST_PORT set to an unused port.
extends SceneTree

class TestStore extends StudioCheckpointStore:
	func acquire() -> bool:
		if _writer != null: return true
		var port := OS.get_environment("PN_CHECKPOINT_TEST_PORT")
		if port.is_empty(): return false
		var server := TCPServer.new()
		if server.listen(int(port),"127.0.0.1") != OK: return false
		_writer = server
		return true

var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _replace_store(node: Node) -> void:
	if node is CheckpointCoordinator:
		node.store = TestStore.new("user://engine-world-continue-" + str(Time.get_ticks_usec()),node._validate_payload)

func _initialize() -> void: _verify.call_deferred()

func _verify() -> void:
	node_added.connect(_replace_store)
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var title_deadline := Time.get_ticks_msec() + 20000
	while (game._loading_checkpoint or game._title_checkpoint_job != null) and Time.get_ticks_msec() < title_deadline: await process_frame
	check(not game._loading_checkpoint and game._title_checkpoint_job == null,"Title checkpoint inspection finishes before Studio creation")
	if game._loading_checkpoint or game._title_checkpoint_job != null: quit(1); return
	var menu: MainMenu = game._active_phase
	game._on_studio_created("Engine Continue",&"action",[],menu)
	var deadline := Time.get_ticks_msec() + 20000
	while game._transition_in_progress and Time.get_ticks_msec() < deadline: await process_frame
	await process_frame
	check(game.rival_world != null and game.rival_world.studios.has(&"incumbent-adventure"),"Certified Adventure creator is active in the normal world")
	if game.rival_world == null: quit(1);return
	var creator_before: int = game.rival_world.studios[&"incumbent-adventure"].run.get_cash_cents()
	check(game.run_state.get_cash_cents()>=250000,"Player can afford the engine license")
	check(game.rival_world.license_engine(&"adventure_engine").get("ok",false),"Normal world settles the license")
	check(game.run_state.select_engine(&"adventure_engine"),"Player selects the licensed engine")
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../docs/codex/threads/engine-system/2026-10-31-starting-libraries-recommended.json"))
	var expected: Array[StringName]=[]
	for id: String in manifest.libraries.rival_adventure.ids:expected.append(StringName(id))
	check(Array(game.run_state.get_future_project_feature_ids())==Array(expected) and game.run_state.get_selected_engine_capacity()==27,"Adventure fixed library and capacity are available immediately")
	var creator_after: int = game.rival_world.studios[&"incumbent-adventure"].run.get_cash_cents()
	check(creator_after == creator_before + 250000,"Real rival bankroll receives exactly $2,500")
	check(await game.checkpoints.wait_saved() and game.checkpoints.store.inspect().status == &"valid","Player and rival world save together")
	game._continue_checkpoint()
	await process_frame
	check(game.rival_world != null and game.run_state.get_selected_engine_id() == &"adventure_engine","Continue restores selected engine")
	check(game.run_state.get_future_project_feature_ids()==expected,"Continue restores the Adventure Feature library")
	check(game.rival_world != null and game.rival_world.studios[&"incumbent-adventure"].run.get_cash_cents() == creator_after,"Continue restores creator bankroll without replaying purchase")
	print("Engine world Continue: %d failures" % failures)
	game.checkpoints.store.release_writer()
	quit(1 if failures else 0)
