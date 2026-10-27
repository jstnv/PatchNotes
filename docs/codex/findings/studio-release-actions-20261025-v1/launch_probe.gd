extends "C:/Users/64jus/OneDrive/Documents/GitHub/PatchNotes/patch-notes/scripts/debug/verify_beta_finalization_and_launch.gd"

class TestStore extends StudioCheckpointStore:
	func acquire() -> bool:
		if _writer != null: return true
		var port := OS.get_environment("PN_CHECKPOINT_TEST_PORT")
		if port.is_empty(): return false
		var server := TCPServer.new()
		if server.listen(int(port),"127.0.0.1") != OK: return false
		_writer=server
		return true

func _initialize() -> void:
	assert(OnboardingPreferences.new().answer(true))
	node_added.connect(func(node):
		if node is CheckpointCoordinator:
			node.store.release_writer()
			node.store=TestStore.new("user://saves/studio",node._validate_payload))
	await process_frame
	_snapshots=PrimitiveSnapshotDatabase.new()
	_snapshots.load_ledgers()
	await _verify_gameplay_transition()
	quit(_failures)
