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
	push_error("Rival cold Continue: "+label)

func _replace_store(node: Node) -> void:
	if node is CheckpointCoordinator:
		node.store = TestStore.new("user://saves/studio",node._validate_payload)

func _initialize() -> void:
	await process_frame
	create_timer(60.0).timeout.connect(func() -> void: push_error("Rival cold Continue timed out"); quit(2))
	node_added.connect(_replace_store)
	var gameplay: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(gameplay)
	await process_frame
	expect(gameplay._active_phase is MainMenu,"cold process opens menu")
	expect(gameplay.checkpoints.store.inspect().status==&"valid","prior generation validates cold")
	gameplay._continue_checkpoint()
	await process_frame
	expect(gameplay._active_phase is StudioPhase,"cold Continue enters Studio")
	# Opened-save Continue always defers a real tutorial invitation that hides Studio.
	var invitation_deadline:=Time.get_ticks_msec()+3000
	while (gameplay.guided_tutorial==null or not gameplay.guided_tutorial.asking) and Time.get_ticks_msec()<invitation_deadline:
		await process_frame
	var invitation: GuidedProductionTutorial=gameplay.guided_tutorial
	expect(invitation!=null and invitation.asking,"cold Continue offers its real tutorial invitation before navigation")
	var invitation_rng: Dictionary=gameplay.run_state.random_streams.snapshot()
	if invitation!=null:
		invitation.experienced_button.pressed.emit()
		invitation.skip_button.pressed.emit()
	await process_frame
	expect(gameplay.guided_tutorial==null and gameplay._active_phase.is_visible_in_tree() and gameplay.run_state.random_streams.snapshot()==invitation_rng,"real Skip restores visible cold Studio without consuming game RNG")
	expect(gameplay.rival_world!=null and gameplay.rival_world.cycle==1,"cold Continue restores exact shared cycle")
	if gameplay.rival_world!=null:
		expect(gameplay.rival_world.studios.size()==8 and gameplay.rival_world.live_releases.is_empty(),"cold Continue preserves eight active rivals")
		var studio: StudioPhase=gameplay._active_phase
		studio._open_rival_info()
		await create_timer(MenuTransitions.ENTRANCE_SECONDS+0.08).timeout
		var info: Control=studio._rival_info
		expect(info!=null and info.is_visible_in_tree() and info.entries.size()==8 and info.table.get_column_title(0)=="Studio" and info.table.get_column_title(3)=="Bankroll","cold Market Info displays all eight labeled rival facts")
		info.close()
		await create_timer(MenuTransitions.ENTRANCE_SECONDS+0.08).timeout
		expect(gameplay.run_state.complete_productive_action(Callable(),0,1),"cold player action commits")
		expect(gameplay.rival_world.cycle==2,"rivals advance once after cold Continue")
		await process_frame
		expect(gameplay.checkpoints.store.inspect().status==&"valid","next atomic generation validates")
	print("RIVAL_GAMEPLAY_COLD_CONTINUE checks=%d failures=%d" % [checks,failures])
	gameplay.checkpoints.store.release_writer()
	quit(0 if failures==0 else 1)
