extends "res://scripts/debug/verify_contract_extraction.gd"
class GateCheckpointStore extends StudioCheckpointStore:
	func acquire() -> bool:
		var test_port := OS.get_environment("PN_CHECKPOINT_TEST_PORT")
		if test_port.is_empty(): return super.acquire()
		if _writer != null: return true
		var server := TCPServer.new()
		if server.listen(int(test_port),"127.0.0.1") != OK: return false
		_writer = server
		return true

func _initialize() -> void:
	if OS.get_environment("PN_CHECKPOINT_TEST_PORT") != "47733":
		push_error("Gate checkpoint isolation requires dedicated port47733")
		quit(1)
		return
	node_added.connect(_gate_isolate_checkpoint_writer)
	# Parent _init already scheduled its original deferred verifier.

func _gate_isolate_checkpoint_writer(node: Node) -> void:
	if not node is CheckpointCoordinator: return
	var original: StudioCheckpointStore = node.store
	if original == null or original.get_script() != preload("res://scripts/persistence/studio_checkpoint_store.gd") or original._writer != null or original.fault != &"":
		push_error("Gate isolation refuses a non-pristine coordinator store")
		quit(1)
		return
	node.store = GateCheckpointStore.new(original.directory,original.validator)
	print("CHECKPOINT_WRITER_ISOLATED port=47733 directory=",node.store.directory)
