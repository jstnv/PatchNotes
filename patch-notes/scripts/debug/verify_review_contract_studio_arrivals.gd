extends "res://scripts/debug/verify_balanced_primitive_contract.gd"

func _verify() -> void:
	snapshots.load_ledgers()
	database = root.get_node("CardDatabase")
	root.size = Vector2i(1280, 720)
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	game.project_state = ProjectState.new(30)
	root.add_child(game)
	await process_frame
	var previous: Control = game._active_phase
	game.get_node("%PhaseRoot").remove_child(previous)
	previous.queue_free()
	game.checkpoints = null
	var project := release(751)
	var run := new_run(500000)
	game.project_state = project
	game.run_state = run
	var studio := load("res://scenes/phases/studio_phase.tscn").instantiate() as StudioPhase
	expect(studio.setup(project,run,game.get_snapshot_database()), "Fixture registers release")
	studio.launch_review_returned.connect(game._on_launch_review_returned)
	studio.contract_requested.connect(game._on_contract_requested)
	game.get_node("%PhaseRoot").add_child(studio)
	game._active_phase = studio
	var hud := game.get_node("%GameplayHUD") as GameplayHUD
	hud.setup(project,run)
	hud.set_phase(studio)
	await process_frame
	var before_review := run_snapshot(run,project)
	var frozen := project_snapshot(project)
	studio.open_launch_review()
	await create_timer(0.4).timeout
	expect(is_instance_valid(studio._review_view), "Launch review opens")
	studio._review_view.continue_to_studio_requested.emit()
	await _check_arrival(game, "Review")
	expect(run_snapshot(run,project) == before_review and project_snapshot(project) == frozen, "Review return preserves release and financial state")
	var state := run.accept_primitive_contract()
	expect(state != null, "Fixture legally accepts contract")
	game._on_contract_requested(studio,state)
	await process_frame
	var contract := game._active_phase as ContractPhase
	expect(contract != null, "Accepted contract becomes active")
	for hand in range(2):
		_select_first(contract,4)
		expect(contract.call("_play_selected_hand"), "Contract hand resolves")
	var completed := run_snapshot(run,project)
	var result := state.get_result()
	expect(state.is_completed() and state.is_payout_committed(), "Contract completes and pays once")
	game._on_contract_completion_dismissed(contract)
	await _check_arrival(game, "Contract")
	completed[2] = RunState.MAX_REDRAWS
	expect(run_snapshot(run,project) == completed and project_snapshot(project) == frozen and state.get_result() == result, "Contract return preserves payout, release and calendar")
	expect(game.active_contract_state == null, "Completed contract is cleared after return")
	game.queue_free()
	await process_frame
	print("Review and contract arrival verification: %d failures" % failures)
	quit(failures)

func _check_arrival(game: Control, label: String) -> void:
	for frame in range(180):
		if game._transition_in_progress: break
		await process_frame
	var studio := game._active_phase as StudioPhase
	var hud := game.get_node("%GameplayHUD") as GameplayHUD
	expect(game._transition_in_progress and studio != null, label + " begins guarded arrival")
	if studio == null: return
	var root_panel: Control = studio._hub._root_panel
	var start_x := root_panel.position.x
	expect(start_x < -root_panel.size.x * 0.5, label + " Studio panel starts offscreen")
	var fence := game.get_node_or_null("ContinueLoading")
	expect(fence != null and fence._surface.mouse_filter == Control.MOUSE_FILTER_STOP, label + " blocks interaction during arrival")
	await create_timer(0.12).timeout
	expect(is_equal_approx(root_panel.position.x,start_x) and hud._studio_bar_prepared, label + " HUD enters before the Studio panel")
	await create_timer(0.5).timeout
	expect(not game._transition_in_progress and not hud._studio_bar_prepared and is_equal_approx(root_panel.position.x,studio._hub.IDLE_OFFSET), label + " finishes with HUD and Studio panel in place")
