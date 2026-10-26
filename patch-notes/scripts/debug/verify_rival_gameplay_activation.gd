extends SceneTree

class TestStore extends StudioCheckpointStore:
	func acquire() -> bool:
		var port := OS.get_environment("PN_CHECKPOINT_TEST_PORT")
		if port.is_empty(): return false
		if _writer != null: return true
		var server := TCPServer.new()
		if server.listen(int(port),"127.0.0.1")!=OK: return false
		_writer = server
		return true

var checks := 0
var failures := 0

func expect(value: bool,label: String) -> void:
	checks += 1
	if value: return
	failures += 1
	push_error("Rival Gameplay: "+label)

func _replace_store(node: Node) -> void:
	if node is CheckpointCoordinator:
		node.store = TestStore.new("user://saves/studio",node._validate_payload)

func _initialize() -> void:
	await process_frame
	create_timer(30.0).timeout.connect(func() -> void: push_error("Rival Gameplay verifier timed out"); quit(2))
	node_added.connect(_replace_store)
	var gameplay: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(gameplay)
	await process_frame
	var menu: MainMenu = gameplay._active_phase as MainMenu
	expect(menu!=null,"normal Main Menu opened")
	if menu==null: quit(1); return
	gameplay._on_studio_created("Trial Player",&"action",[],menu)
	await process_frame
	expect(gameplay.rival_world!=null and gameplay.rival_world.studios.size()==2,"normal new game activates trial rivals")
	expect(gameplay._active_phase is StudioPhase,"normal Studio entered")
	var status: Label = gameplay._active_phase.get_node_or_null("Dashboard/Layout/RivalTrialStatus")
	expect(status!=null and status.text.contains("Rivals (trial)"),"Studio shows labeled rival status")
	expect(gameplay.checkpoints.store.inspect().status==&"valid","initial player and rival world checkpoint valid")
	var old_cycle: int = gameplay.rival_world.cycle
	expect(gameplay.run_state.complete_productive_action(Callable(),0,old_cycle),"normal player calendar commits")
	expect(gameplay.rival_world.cycle==old_cycle+1,"normal Gameplay signal advances rivals once")
	await process_frame
	expect(gameplay.checkpoints.store.inspect().status==&"valid","post-cycle world checkpoint valid")
	gameplay._continue_checkpoint()
	await process_frame
	expect(gameplay.rival_world!=null and gameplay.rival_world.cycle==old_cycle+1,"normal Continue restores world without another turn")
	expect(gameplay._active_phase is StudioPhase,"Continue opens Studio")
	print("RIVAL_GAMEPLAY_ACTIVATION checks=%d failures=%d cycle=%d" % [checks,failures,gameplay.rival_world.cycle if gameplay.rival_world!=null else -1])
	gameplay.checkpoints.store.release_writer()
	quit(0 if failures==0 else 1)
