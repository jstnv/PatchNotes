extends SceneTree
## Isolated cold-save fixture: run against a profile seeded by the guided UI test.
class TestStore extends StudioCheckpointStore:
	func acquire() -> bool:
		if _writer != null: return true
		var server := TCPServer.new()
		if server.listen(int(OS.get_environment("PN_CHECKPOINT_TEST_PORT")),"127.0.0.1") != OK: return false
		_writer = server
		return true

var failed := 0
func check(value: bool, description: String) -> void:
	print("PASS: " if value else "FAIL: ",description)
	if not value: failed += 1

func _initialize() -> void: run.call_deferred()
func run() -> void:
	node_added.connect(func(node: Node):
		if node is CheckpointCoordinator:
			node.store.release_writer()
			node.store = TestStore.new("user://saves/studio",node._validate_payload))
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game); current_scene = game
	game._onboarding.path = "user://continue-invitation-independent.cfg"
	var start := Time.get_ticks_msec()
	var deadline := start + 90000
	while not game._active_phase is MainMenu and Time.get_ticks_msec() < deadline: await process_frame
	check(game._active_phase is MainMenu,"Cold fixture enters Main Menu")
	if game._active_phase is MainMenu:
		while (game._title_checkpoint_job != null or game._active_phase.checkpoint_info.get("status") == &"checking") and Time.get_ticks_msec() < deadline: await process_frame
		var ready: bool = game._active_phase.checkpoint_info.get("status") == &"valid"
		print("GUIDED_COLD_READY ms=",Time.get_ticks_msec()-start," status=",game._active_phase.checkpoint_info.get("status"))
		check(ready,"Inspected checkpoint is ready before Continue")
		if ready:
			game._active_phase.continue_requested.emit()
			deadline = Time.get_ticks_msec() + 90000
			while game._loading_checkpoint and Time.get_ticks_msec() < deadline: await process_frame
			check(not game._loading_checkpoint and game.guided_tutorial == null and game._active_phase is StudioPhase,"Continue enters Studio without invitation")
			check(game._start_guided_practice(),"Tutorial remains available after Continue")
	game.queue_free(); await process_frame
	print("GUIDED_CONTINUE_READINESS failures=",failed)
	quit(failed)
