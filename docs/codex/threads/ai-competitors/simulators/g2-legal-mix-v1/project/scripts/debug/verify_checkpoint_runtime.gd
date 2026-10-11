extends "res://scripts/debug/verify_main_menu_history.gd"

func _run() -> void:
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var test_port := OS.get_environment("PN_CHECKPOINT_TEST_PORT")
	if not test_port.is_empty():
		game.checkpoints.store._writer = TCPServer.new()
		if game.checkpoints.store._writer.listen(int(test_port),"127.0.0.1")!=OK: quit(2); return
	var menu: MainMenu = game._active_phase
	game._on_studio_created("Durable Studio",&"action",[],menu)
	await process_frame
	var coordinator: CheckpointCoordinator = game.checkpoints
	var initial := coordinator.store.inspect()
	expect(initial.status==&"valid", "Initial Studio automatically saves")
	if initial.status!=&"valid":
		print(coordinator.failure)
		quit(1)
		return
	var run: RunState = game.run_state
	var before: Dictionary = initial.payload.duplicate(true)
	var cash := run.get_cash_cents()
	expect(not run.purchase_starter_feature(&"missing"),"Invalid Studio purchase rejects")
	await process_frame
	expect(coordinator.store.inspect().payload==before,"Invalid purchase leaves exact checkpoint unchanged")
	var expected_id: StringName
	var expected_cards := []
	var expected_streams := {}
	for attempt in range(2):
		var studio: StudioPhase = game._active_phase
		game.get_node("%GameplayHUD").tutorial_overlay.close()
		expect(game._begin_next_project(studio,"Repeat",&"action",&"fantasy"),"Depart from durable Studio")
		await process_frame
		var design: DesignPhase = game._active_phase
		expect(design.get_workspace().overlay.commit_draft(),"Actual Design deal")
		expect(design._candidate_cards.size()==7,"Actual deal contains seven candidates")
		var cards := []
		for card: CardData in design._candidate_cards: cards.append(card.id)
		if attempt==0:
			expected_id = game.project_state.get_release_id()
			expected_cards = cards
			expected_streams = game.run_state.random_streams.snapshot()
		else:
			expect(game.project_state.get_release_id()==expected_id and cards==expected_cards,"Continue reproduces project identity and actual tutorial deal")
			expect(game.run_state.random_streams.snapshot()==expected_streams,"Continue reproduces all stream positions")
		expect(coordinator.store.inspect().payload==before,"Departure and deal never overwrite Studio checkpoint")
		game._continue_checkpoint()
		await process_frame
		expect(game.run_state.get_cash_cents()==cash and game.run_state.get_completed_run_cycles()==0 and game.project_state==null,"Continue rolls back the entire unsaved project")
	# Failure after an actual action keeps the action in memory, blocks the next
	# mutation, and retry publishes state without replaying its cash receipt.
	run = game.run_state
	coordinator.store.fault = &"before_rename"
	expect(run.add_cash_cents(123),"Committed action before injected I/O failure")
	await process_frame
	expect(not coordinator.failure.is_empty() and run.get_cash_cents()==cash+123,"Save failure preserves committed memory")
	expect(not run.add_cash_cents(7),"Failed save blocks further mutations")
	expect(not game._begin_next_project(game._active_phase,"Blocked",&"action",&"fantasy"),"Failed save blocks departure")
	expect(coordinator.store.inspect().payload==before,"Interrupted publication preserves previous generation")
	coordinator.store.fault = &""
	expect(coordinator.retry(),"Retry saves without replaying action")
	expect(run.get_cash_cents()==cash+123 and run.checkpoint_mutations_allowed,"Retry restores action access without extra cash")
	game._continue_checkpoint()
	await process_frame
	expect(game.run_state.get_cash_cents()==cash+123,"Continue hydrates the newly committed generation")
	var latest := coordinator.store.inspect()
	var file := FileAccess.open(latest.path,FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	expect(coordinator.store.inspect().status==&"invalid" and coordinator.load_current()==null,"Corrupt current cannot silently load backup")
	expect(coordinator.store.recover_backup().status==&"saved","Explicit recovery publishes preserved valid backup")
	game._continue_checkpoint()
	await process_frame
	expect(game.run_state.get_cash_cents()==cash,"Explicit recovered backup restores exact earlier cash")
	game.queue_free()
	await process_frame
	print("Checkpoint runtime verification: %d failures" % failures)
	quit(0 if failures==0 else 1)
