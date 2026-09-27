extends SceneTree

var failures := 0
var snapshots := PrimitiveSnapshotDatabase.new()
var database: Node


func _initialize() -> void:
	call_deferred("_verify")


func expect(ok: bool, message: String) -> void:
	if ok:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)


func release(total: int) -> ProjectState:
	var project := ProjectState.new(30)
	project.initialize_snapshots(&"fast_follower", &"stable_market")
	project.finalize_design_bugs(false, 0, [], [])
	project.finalize_alpha(0, [], [])
	project.finalize_beta()
	project.commit_review_result(ReviewResult.new(PrimitiveReviewCalculator.get_baseline_profile(), {}, 0.0, 0.0, 0.0, 7.0, 1.0, 0, 0.0, 1.0, 50, 0.0, 7.0, 7.0))
	project.commit_awareness_result(PrimitiveAwarenessCalculator.calculate(project))
	project.commit_launch_market_context_result(PrimitiveLaunchMarketContextCalculator.calculate(project, snapshots))
	project.set("_units_sold_result", UnitsSoldResult.new(&"primitive_units_sold_v1", &"month_1", 500, 70, 70, 100, 200, 300, 10000, 10000, total, 1, float(total), total))
	project.commit_month_one_sales_revenue_result(PrimitiveMonthOneSalesRevenueCalculator.calculate(project))
	return project


func new_run(cents: int = 0) -> RunState:
	var run := RunState.new()
	run.initialize_cash_cents(cents)
	return run


func run_snapshot(run: RunState, project: ProjectState) -> Array:
	return [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_available_redraws(), run.get_released_game_sales(project.get_release_id())]


func project_snapshot(project: ProjectState) -> Array:
	return [project.get_current_scope(), project.get_current_cycle(),
		project.get_core_score(ProjectState.CoreScore.GRAPHICS), project.get_core_score(ProjectState.CoreScore.SOUND),
		project.get_core_score(ProjectState.CoreScore.TECHNOLOGY), project.get_core_score(ProjectState.CoreScore.DESIGN),
		project.get_implemented_design_feature_ids(), project.get_implemented_alpha_feature_ids(), project.get_review_result(), project.get_month_one_sales_revenue_result()]


func _verify() -> void:
	snapshots.load_ledgers()
	database = root.get_node("CardDatabase")
	_verify_formula()
	await _verify_offer_and_navigation()
	await _verify_redraw_and_priorities()
	await _verify_two_hand_completion()
	await _verify_overflow_rollback()
	await _verify_gameplay_transition()
	print("Balanced Primitive Contract verification: %d failures" % failures)
	quit(failures)


func _verify_formula() -> void:
	var zero := _scores(0)
	var half := _scores(6)
	var perfect := _scores(12)
	var over := _scores(200)
	expect(ContractState.calculate_completion(0, zero) == {"numerator": 0, "payout_cents": 0}, "Zero completion pays zero cents")
	expect(ContractState.calculate_completion(6, half) == {"numerator": 48, "payout_cents": 120000}, "Half completion pays exactly 120000 cents")
	expect(ContractState.calculate_completion(12, perfect) == {"numerator": 96, "payout_cents": 240000}, "Perfect completion pays exactly 240000 cents")
	expect(ContractState.calculate_completion(999, over) == {"numerator": 96, "payout_cents": 240000}, "Scope and Core overproduction cap before payout")
	expect(ContractState.calculate_completion(-1, perfect).is_empty(), "Invalid completion input rejects")
	var specialization_state := ContractState.new([&"sprites", &"enemies", &"levels", &"maps"])
	var specialization_cards: Array[CardData] = [database.get_card(&"sprites"), database.get_card(&"enemies"), database.get_card(&"levels"), database.get_card(&"maps")]
	var specialized := specialization_state.plan_hand(specialization_cards)
	expect(specialized.specialization_stat == &"graphics" and specialized.score_additions[ProjectState.CoreScore.GRAPHICS] == 45 and specialized.score_additions[ProjectState.CoreScore.TECHNOLOGY] == 15 and specialized.score_additions[ProjectState.CoreScore.DESIGN] == 6 and specialized.scope_addition == 8, "Contract primary-Core Specialization multiplies primary and secondary scores by 1.50 while Scope stays printed")


func _verify_offer_and_navigation() -> void:
	var project := release(0)
	var run := new_run(12345)
	expect(not run.is_primitive_contract_offer_available(), "Offer is unavailable before a released game enters Studio")
	var studio := load("res://scenes/phases/studio_phase.tscn").instantiate() as StudioPhase
	root.add_child(studio)
	expect(studio.setup(project, run, snapshots), "Studio registers the first release")
	var before := run_snapshot(run, project)
	var frozen := project_snapshot(project)
	expect(run.is_primitive_contract_offer_available() and not studio.get_node("%Contracts").disabled, "One-shot offer becomes available after Studio entry")
	studio.get_node("%Contracts").pressed.emit()
	await process_frame
	var detail := studio.get_node("ContractDetail") as PanelContainer
	expect(detail.visible and run_snapshot(run, project) == before and project_snapshot(project) == frozen, "Opening contract details is passive")
	(detail.find_child("CloseContractDetailButton", true, false) as Button).pressed.emit()
	expect(run_snapshot(run, project) == before and studio.get_node("%Dashboard").visible, "Closing contract details returns to Studio for free")
	var accepted: Array[ContractState] = []
	studio.contract_requested.connect(func(_source: StudioPhase, state: ContractState): accepted.append(state))
	studio.get_node("%Contracts").pressed.emit()
	(detail.find_child("AcceptContractButton", true, false) as Button).pressed.emit()
	expect(accepted.size() == 1 and accepted[0] == run.get_primitive_contract(), "Acceptance creates and publishes one authoritative ContractState")
	var state := accepted[0]
	expect(state != project and state.get_scope() == 0 and state.get_successful_hand_count() == 0 and state.get_priority_distribution() == _priorities(25, 25, 25, 25), "ContractState is separate and starts at locked values")
	expect(state.get_eligible_feature_ids().size() == 27 and run_snapshot(run, project) == before and project_snapshot(project) == frozen, "Acceptance is zero-cost and snapshots 27 Primitive Features")
	expect(not run.is_primitive_contract_offer_available() and run.accept_primitive_contract() == null, "Accepted offer cannot be accepted twice")
	studio.queue_free()
	await process_frame


func _verify_redraw_and_priorities() -> void:
	var project := release(0)
	var run := new_run()
	var studio := load("res://scenes/phases/studio_phase.tscn").instantiate() as StudioPhase
	root.add_child(studio)
	studio.setup(project, run, snapshots)
	run.consume_redraw(2)
	var state := run.accept_primitive_contract()
	var phase := load("res://scenes/phases/contract_phase.tscn").instantiate() as ContractPhase
	phase.setup(state, run)
	root.add_child(phase)
	await process_frame
	expect(run.get_available_redraws() == 2, "Contract entry does not refresh shared redraws")
	var initial_cards := phase.get_candidate_cards()
	var initial_feature_ids: Dictionary = {}
	var valid_pool := initial_cards.size() == 7
	for card in initial_cards:
		valid_pool = valid_pool and card.card_type in [&"feature", &"pass"] and card.phase != CardData.PHASE_BETA
		if card.card_type == &"feature":
			valid_pool = valid_pool and not initial_feature_ids.has(card.id)
			initial_feature_ids[card.id] = true
	expect(valid_pool, "Each draw has seven ledger-backed Design/Alpha Features or Core Passes with no duplicate finite Feature")
	var fixture: Array[CardData] = [database.get_card(&"text"), database.get_card(&"graphics_pass"), database.get_card(&"sound_pass"), database.get_card(&"technology_pass"), database.get_card(&"design_pass"), database.get_card(&"sprites"), database.get_card(&"scrolling")]
	phase.call("_publish_candidate_pool", fixture)
	var children: Array[Node] = []
	children.assign(phase.get("_candidate_row").get_children())
	(children[0] as CardView).input_button.pressed.emit()
	(children[1] as CardView).input_button.pressed.emit()
	var types_before := [(children[0] as CardView).card_data.card_type, (children[1] as CardView).card_data.card_type]
	expect(phase.redraw_selected_cards([0.0, 0.0], [0.0, 0.0]), "Selected Feature and Pass redraw atomically")
	children.assign(phase.get("_candidate_row").get_children())
	expect((children[0] as CardView).card_data.card_type == types_before[0] and (children[1] as CardView).card_data.card_type == types_before[1] and run.get_available_redraws() == 0, "Redraw is type-preserving and consumes one allowance per card")
	var pool_before := _card_ids(phase.get_candidate_cards())
	var snapshot_before := run_snapshot(run, project)
	expect(not phase.commit_priority_distribution(state.get_priority_distribution()) and run_snapshot(run, project) == snapshot_before, "Unchanged priority commit costs nothing")
	expect(not phase.commit_priority_distribution(_priorities(50, 50, 50, 50)) and run_snapshot(run, project) == snapshot_before, "Invalid priority commit costs nothing")
	var changed := _priorities(50, 20, 15, 15)
	expect(phase.commit_priority_distribution(changed), "Valid changed priorities commit")
	expect(run.get_completed_run_cycles() == snapshot_before[1] + 1 and run.get_available_redraws() == 1 and state.get_priority_distribution() == changed, "Priority commit advances once and restores one redraw")
	expect(_card_ids(phase.get_candidate_cards()) == pool_before and run.get_released_game_sales(project.get_release_id()).earned_cycles == 1, "Priority commit preserves current draw and integrates with sales earning")
	var weighted_pass: CardData = phase.call("_draw_one", &"pass", {}, 0.49, 0.0)
	expect(weighted_pass != null and weighted_pass.primary_stat == &"graphics", "Committed priorities control later redraw category weighting")
	phase.queue_free()
	studio.queue_free()
	await process_frame


func _verify_two_hand_completion() -> void:
	var project := release(751)
	var frozen := project_snapshot(project)
	var run := new_run()
	var studio := load("res://scenes/phases/studio_phase.tscn").instantiate() as StudioPhase
	root.add_child(studio)
	studio.setup(project, run, snapshots)
	var state := run.accept_primitive_contract()
	var phase := load("res://scenes/phases/contract_phase.tscn").instantiate() as ContractPhase
	phase.setup(state, run)
	root.add_child(phase)
	await process_frame
	var first_pool: Array[CardData] = [database.get_card(&"text"), database.get_card(&"graphics_pass"), database.get_card(&"sound_pass"), database.get_card(&"technology_pass"), database.get_card(&"design_pass"), database.get_card(&"sprites"), database.get_card(&"scrolling")]
	phase.call("_publish_candidate_pool", first_pool)
	_select_first(phase, 4)
	var rejected_before := run_snapshot(run, project)
	(phase.get_selected_candidate_views()[0] as CardView).input_button.pressed.emit()
	expect(not phase.call("_play_selected_hand") and run_snapshot(run, project) == rejected_before and state.get_successful_hand_count() == 0, "Incomplete hand rejects without run or contract mutation")
	_select_first(phase, 4)
	expect(phase.call("_play_selected_hand"), "First contract hand succeeds")
	expect(state.get_successful_hand_count() == 1 and state.is_feature_exhausted(&"text") and not state.is_feature_exhausted(&"graphics_pass"), "Features exhaust locally while Passes remain renewable")
	expect(not _card_ids(phase.get_candidate_cards()).has(&"text") and run.get_completed_run_cycles() == 1, "Second draw excludes exhausted Feature and first hand advances once")
	var reconstructed := load("res://scenes/phases/contract_phase.tscn").instantiate() as ContractPhase
	reconstructed.setup(state, run)
	root.add_child(reconstructed)
	await process_frame
	expect(reconstructed.get_contract_state() == state and state.get_successful_hand_count() == 1 and reconstructed.get_candidate_cards().size() == 7, "Phase reconstruction reuses ContractState and rebuilds only phase-local candidates")
	reconstructed.queue_free()
	_select_first(phase, 4)
	var selected := phase.call("_selected_cards") as Array[CardData]
	var plan := state.plan_hand(selected)
	var expected_payout: int = plan.payout_cents
	expect(phase.call("_play_selected_hand"), "Second hand completes the contract")
	var result := state.get_result()
	expect(state.is_completed() and state.is_payout_committed() and state.get_successful_hand_count() == 2 and result.get_payout_cents() == expected_payout, "Second hand commits one immutable result and payout guard")
	var completion_text: String = phase.get("_completion_stats").text
	expect(completion_text.contains("Final Scope") and completion_text.contains("Graphics") and completion_text.contains("Sound") and completion_text.contains("Technology") and completion_text.contains("Design") and completion_text.contains("Completion") and completion_text.contains("Exact Payout"), "Completion view shows Scope, every Core Score, percentage and exact payout")
	expect(run.get_completed_run_cycles() == 2 and run.get_cash_cents() == expected_payout + 525174 and run.get_released_game_sales(project.get_release_id()).settled_cents == 525174, "Completing hand pays contract before the shared boundary settles earned sales")
	expect(project_snapshot(project) == frozen, "Contract never mutates frozen ProjectState")
	var completed_snapshot := run_snapshot(run, project)
	expect(not phase.call("_play_selected_hand") and run_snapshot(run, project) == completed_snapshot, "Repeated completion callback cannot repay or advance")
	var dismissed := [0]
	phase.completion_dismissed.connect(func(_source: ContractPhase): dismissed[0] += 1)
	(phase.get("_completion_panel").find_child("DismissCompletionButton", true, false) as Button).pressed.emit()
	expect(dismissed[0] == 1 and run_snapshot(run, project) == completed_snapshot, "Completion dismissal is passive")
	var return_studio := load("res://scenes/phases/studio_phase.tscn").instantiate() as StudioPhase
	root.add_child(return_studio)
	expect(return_studio.setup(project, run, snapshots) and return_studio.get_node("%Contracts").disabled, "Studio re-entry preserves completion and removes the one-shot offer")
	expect(run_snapshot(run, project) == completed_snapshot and project_snapshot(project) == frozen, "Studio reconstruction preserves cash, calendar, redraws, sales and frozen project")
	return_studio.queue_free()
	phase.queue_free()
	studio.queue_free()
	await process_frame


func _verify_overflow_rollback() -> void:
	var project := release(0)
	var run := new_run(RunState.MAX_SIGNED_INT - 1)
	var studio := load("res://scenes/phases/studio_phase.tscn").instantiate() as StudioPhase
	root.add_child(studio)
	studio.setup(project, run, snapshots)
	var state := run.accept_primitive_contract()
	var phase := load("res://scenes/phases/contract_phase.tscn").instantiate() as ContractPhase
	phase.setup(state, run)
	root.add_child(phase)
	await process_frame
	_select_first(phase, 4)
	expect(phase.call("_play_selected_hand"), "Non-completing hand can commit at near-maximum cash")
	_select_first(phase, 4)
	var before := run_snapshot(run, project)
	var scope_before := state.get_scope()
	var exhausted_before := state.get_exhausted_feature_ids()
	expect(not phase.call("_play_selected_hand"), "Completing payout overflow rejects")
	expect(run_snapshot(run, project) == before and state.get_successful_hand_count() == 1 and state.get_scope() == scope_before and state.get_exhausted_feature_ids() == exhausted_before and not state.is_completed(), "Overflow rollback preserves contract, cash, calendar, redraws and sales")
	phase.queue_free()
	studio.queue_free()
	await process_frame


func _verify_gameplay_transition() -> void:
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	game.project_state = ProjectState.new(30) # Existing-project fixture; first-run setup is tested separately.
	root.add_child(game)
	await process_frame
	var project := release(0)
	var run := new_run()
	var old_phase: Control = game.get("_active_phase")
	game.get_node("%PhaseRoot").remove_child(old_phase)
	old_phase.queue_free()
	game.set("project_state", project)
	game.set("run_state", run)
	var studio := load("res://scenes/phases/studio_phase.tscn").instantiate() as StudioPhase
	studio.setup(project, run, game.get_snapshot_database())
	studio.contract_requested.connect(Callable(game, "_on_contract_requested"))
	game.get_node("%PhaseRoot").add_child(studio)
	game.set("_active_phase", studio)
	game.get_node("%GameplayHUD").set_phase(studio)
	var passive_before := run_snapshot(run, project)
	studio.get_node("%Contracts").pressed.emit()
	(studio.get_node("ContractDetail").find_child("AcceptContractButton", true, false) as Button).pressed.emit()
	await process_frame
	var active: Control = game.get("_active_phase")
	expect(active is ContractPhase and game.get("active_contract_state") == run.get_primitive_contract(), "Gameplay retains accepted ContractState and enters ContractPhase")
	_select_first(active as ContractPhase, 4)
	(active as ContractPhase).call("_play_selected_hand")
	_select_first(active as ContractPhase, 4)
	(active as ContractPhase).call("_play_selected_hand")
	var completed_before_dismiss := run_snapshot(run, project)
	((active as ContractPhase).get("_completion_panel").find_child("DismissCompletionButton", true, false) as Button).pressed.emit()
	await process_frame
	active = game.get("_active_phase")
	expect(active is StudioPhase and (active as StudioPhase).get_project_state() == project and (active as StudioPhase).get_run_state() == run, "Completion dismissal returns through Gameplay to the same Studio dashboard state")
	expect(run_snapshot(run, project) == completed_before_dismiss and passive_before[1] + 2 == run.get_completed_run_cycles(), "Gameplay navigation is passive and exactly two hands advance exactly two cycles")
	game.queue_free()
	await process_frame


func _select_first(phase: ContractPhase, count: int) -> void:
	for child in phase.get("_candidate_row").get_children():
		if phase.get_selected_candidate_views().size() >= count: break
		if child is CardView and not child.is_selected(): child.input_button.pressed.emit()


func _card_ids(cards: Array[CardData]) -> Array[StringName]:
	var result: Array[StringName] = []
	for card in cards: result.append(card.id)
	return result


func _scores(value: int) -> Dictionary:
	return {ProjectState.CoreScore.GRAPHICS: value, ProjectState.CoreScore.SOUND: value, ProjectState.CoreScore.TECHNOLOGY: value, ProjectState.CoreScore.DESIGN: value}


func _priorities(graphics: int, sound: int, technology: int, design: int) -> Dictionary:
	return {ProjectState.CoreScore.GRAPHICS: graphics, ProjectState.CoreScore.SOUND: sound, ProjectState.CoreScore.TECHNOLOGY: technology, ProjectState.CoreScore.DESIGN: design}
