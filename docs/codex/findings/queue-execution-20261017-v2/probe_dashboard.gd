extends "res://scripts/debug/verify_release_menus.gd"

class TestStore extends StudioCheckpointStore:
	func acquire() -> bool:
		if _writer != null: return true
		var server := TCPServer.new()
		if server.listen(47865,"127.0.0.1") != OK: return false
		_writer = server
		return true

func _initialize() -> void:
	node_added.connect(func(node):
		if node is CheckpointCoordinator: node.store = TestStore.new("user://saves/studio",node._validate_payload))
	super._initialize()

func check(ok: bool,message: String) -> void:
	super.check(ok,message)
	if message == "Launch review Continue opens dashboard": _inspect.call_deferred()

func _inspect() -> void:
	await _settle()
	var game = root.get_node("Gameplay")
	var studio = game._active_phase
	for path in [".","Dashboard","Dashboard/Layout","Dashboard/Layout/Heading","Dashboard/Layout/StudioIdentity","Dashboard/Layout/MenuCenter"]:
		var item: Control = studio.get_node(path)
		print("DASHBOARD_GEOMETRY ",path," rect=",item.get_global_rect()," visible=",item.is_visible_in_tree()," minimum=",item.get_combined_minimum_size())
