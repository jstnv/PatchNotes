extends SceneTree

var failures := 0
var snapshots := PrimitiveSnapshotDatabase.new()
var database: Node


func _initialize() -> void:
	call_deferred("_verify")


func check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: " + label)
	else:
		failures += 1
		push_error("FAIL: " + label)


func release(total_units: int = 0, scope: int = 30, required_scope: int = 30) -> ProjectState:
	var project := ProjectState.new(required_scope)
	project.add_scope(scope) # Qualified by default; under-Scope cases have their own verifier.
	project.initialize_snapshots(&"fast_follower", &"stable_market")
	project.finalize_design_bugs(false, 0, [&"text"], [])
	project.finalize_alpha(0, [], [])
	project.finalize_beta()
	project.commit_review_result(ReviewResult.new(PrimitiveReviewCalculator.get_baseline_profile(), {}, 0.0, 0.0, 0.0, 7.0, 1.0, 0, 0.0, 1.0, 50, 0.0, 7.0, 7.0))
	project.commit_awareness_result(PrimitiveAwarenessCalculator.calculate(project))
	project.commit_launch_market_context_result(PrimitiveLaunchMarketContextCalculator.calculate(project, snapshots))
	project.set("_units_sold_result", UnitsSoldResult.new(&"primitive_units_sold_v1", &"month_1", 500, 70, 70, 100, 200, 300, 10000, 10000, total_units, 1, float(total_units), total_units))
	project.commit_month_one_sales_revenue_result(PrimitiveMonthOneSalesRevenueCalculator.calculate(project))
	return project


func new_run(cents: int = 0) -> RunState:
	var run := RunState.new()
	run.initialize_cash_cents(cents)
	return run


func snapshot(run: RunState, projects: Array[ProjectState]) -> Array:
	var sales: Array = []
	for project in projects:
		sales.append(run.get_released_game_sales(project.get_release_id()))
	return [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_available_redraws(),
		run.get_sidestreet_offer_ids(), run.get_sidestreet_completion_history(), sales]


func fixture_cards(first: bool) -> Array[CardData]:
	var ids: Array[StringName] = []
	ids.assign([&"text", &"graphics_pass", &"sound_pass", &"technology_pass", &"design_pass", &"sprites", &"scrolling"] if first else [&"sprites", &"graphics_pass", &"sound_pass", &"technology_pass", &"design_pass", &"enemies", &"levels"])
	var cards: Array[CardData] = []
	for id in ids:
		cards.append(database.get_card(id))
	return cards


func select_first_four(phase: ContractPhase) -> void:
	for child in phase.get("_candidate_row").get_children():
		if phase.get_selected_candidate_views().size() == 4:
			break
		(child as CardView).input_button.pressed.emit()


func complete_contract(run: RunState, state: ContractState, check_finite: bool = false) -> Dictionary:
	var phase := load("res://scenes/phases/contract_phase.tscn").instantiate() as ContractPhase
	check(phase.setup(state, run), "Authoritative ContractState opens in ContractPhase")
	root.add_child(phase)
	await process_frame
	phase.call("_publish_candidate_pool", fixture_cards(true))
	select_first_four(phase)
	var initial_cash := run.get_cash_cents()
	var initial_cycle := run.get_completed_run_cycles()
	check(phase.call("_play_selected_hand"), "First hand commits through the shared productive cycle")
	check(run.get_completed_run_cycles() == initial_cycle + 1 and run.get_cash_cents() == initial_cash and state.get_successful_hand_count() == 1, "Hand one advances once and pays no SideStreet cash") if state.get_contract_id() == ContractState.SIDESTREET_CONTRACT_ID else null
	if check_finite:
		var reused: Array[CardData] = [database.get_card(&"text"), database.get_card(&"graphics_pass"), database.get_card(&"sound_pass"), database.get_card(&"technology_pass")]
		check(state.is_feature_exhausted(&"text") and state.plan_hand(reused).is_empty() and not state.is_feature_exhausted(&"graphics_pass"), "Feature is finite while Core Pass remains renewable")
	phase.call("_publish_candidate_pool", fixture_cards(false))
	select_first_four(phase)
	var selected: Array[CardData] = phase.call("_selected_cards")
	var plan := state.plan_hand(selected)
	check(not plan.is_empty(), "Second hand has a legal seven-candidate draw and four-card play")
	var before := run.get_completed_run_cycles()
	check(phase.call("_play_selected_hand"), "Second hand commits payout and completion")
	check(run.get_completed_run_cycles() == before + 1 and state.is_completed() and state.is_payout_committed(), "Exactly two successful hands complete")
	var completion_text: String = phase.get("_completion_stats").text
	check(completion_text.contains("Final Scope") and completion_text.contains("Graphics") and completion_text.contains("Sound") and completion_text.contains("Technology") and completion_text.contains("Design") and completion_text.contains("Completion") and completion_text.contains(CashFormatter.format_exact_cents(state.get_result().get_payout_cents())), "Completion view shows Scope, four Core scores, percent and exact payout")
	var result := {"plan": plan, "phase": phase}
	return result


func _verify() -> void:
	snapshots.load_ledgers()
	database = root.get_node("CardDatabase")
	root.size = Vector2i(1152, 648)
	_verify_formula()
	await _verify_early_offer_and_studio()
	await _verify_two_queued_offers_and_starwave()
	await _verify_partial_priority_and_queue()
	await _verify_sales_boundary()
	await _verify_overflow()
	print("SideStreet contract verification: %d failures" % failures)
	quit(failures)


func _verify_formula() -> void:
	var zero := {0: 0, 1: 0, 2: 0, 3: 0}
	var half := {0: 6, 1: 6, 2: 6, 3: 6}
	var full := {0: 12, 1: 12, 2: 12, 3: 12}
	check(ContractState.calculate_sidestreet_completion(0, zero).payout_cents == 0 and ContractState.calculate_sidestreet_completion(6, half).payout_cents == 60000 and ContractState.calculate_sidestreet_completion(12, full).payout_cents == 120000, "Zero, half and full payout are 0, 60000 and 120000 exact cents")
	check(ContractState.calculate_sidestreet_completion(1, zero).payout_cents == 5000 and ContractState.calculate_sidestreet_completion(0, {0: 1, 1: 0, 2: 0, 3: 0}).payout_cents == 1250, "Scope and Core odd numerator floor exactly in integer cents")
	check(ContractState.calculate_sidestreet_completion(999, {0: 999, 1: 999, 2: 999, 3: 999}).payout_cents == 120000, "Overproduction caps at the publisher investment")


func _verify_early_offer_and_studio() -> void:
	var run := new_run(12345)
	var game := release(0)
	check(run.register_release(game) and run.get_sidestreet_offer_ids().size() == 1 and not run.is_sidestreet_offer_available(), "First release creates one dormant entitlement before SideStreet unlock")
	var before := snapshot(run, [game])
	check(run.register_release(game) and snapshot(run, [game]) == before, "Repeated release registration is idempotent")
	var ironclad := run.accept_primitive_contract()
	var completed := await complete_contract(run, ironclad)
	(completed.phase as ContractPhase).queue_free()
	check(run.is_sidestreet_offer_available() and run.get_completed_contract_count() == 1, "Ironclad second hand unlocks the early first-release offer")
	var studio := load("res://scenes/phases/studio_phase.tscn").instantiate() as StudioPhase
	check(studio.setup(game, run, snapshots), "Studio reconstructs release and unlocked offer")
	root.add_child(studio)
	await process_frame
	var passive := snapshot(run, [game])
	studio.get_node("%Contracts").pressed.emit()
	var detail := studio.get_node("ContractDetail") as PanelContainer
	check(detail.visible and (detail.find_child("ContractDetailText", true, false) as Label).text.contains("SideStreet Games"), "Studio displays SideStreet cash-only detail")
	(detail.find_child("CloseContractDetailButton", true, false) as Button).pressed.emit()
	check(snapshot(run, [game]) == passive, "Offer browsing and dismissal preserve cash, calendar, redraws and sales")
	var offer := run.get_next_sidestreet_offer()
	var state := run.accept_sidestreet_offer(offer.offer_id)
	check(state != null and state.get_contract_id() == ContractState.SIDESTREET_CONTRACT_ID and state.get_source_release_id() == game.get_release_id() and run.owns_contract_state(state), "Acceptance creates separate release-linked ContractState")
	check(snapshot(run, [game]) == passive and run.accept_sidestreet_offer(offer.offer_id) == null, "Acceptance costs zero cash and cycles; duplicate acceptance rejects")
	var completed_side := await complete_contract(run, state, true)
	var payout: int = completed_side.plan.payout_cents
	var history := run.get_sidestreet_completion_history()
	check(history.size() == 1 and history.has(offer.offer_id) and history[offer.offer_id].payout_cents == payout and state.get_result().get_upfront_cents() == 0, "Completion records one immutable offer result with zero upfront")
	check(run.get_completed_contract_count() == 2 and not run.is_sidestreet_offer_available(), "First SideStreet offer is exhausted for this release")
	var frozen := snapshot(run, [game])
	check(not (completed_side.phase as ContractPhase).call("_play_selected_hand") and snapshot(run, [game]) == frozen, "Repeated completion callback cannot repay or advance")
	(completed_side.phase as ContractPhase).queue_free()
	studio.queue_free()
	await process_frame


func _verify_two_queued_offers_and_starwave() -> void:
	var run := new_run()
	var first := release(0)
	var second := release(0)
	check(first.get_release_id() != second.get_release_id() and run.register_release(first) and run.register_release(second) and run.get_sidestreet_offer_ids().size() == 2, "Two distinct releases queue two immutable offer IDs before Ironclad")
	check(not run.get_unlocked_publisher_ids().has(PublisherCatalog.STARWAVE), "Two releases without contracts cannot unlock Starwave")
	var iron := await complete_contract(run, run.accept_primitive_contract())
	(iron.phase as ContractPhase).queue_free()
	check(run.is_sidestreet_offer_available() and run.get_next_sidestreet_offer().release_id == first.get_release_id(), "Unlock exposes oldest pending release offer")
	var first_offer := run.get_next_sidestreet_offer()
	var first_side := await complete_contract(run, run.accept_sidestreet_offer(first_offer.offer_id))
	(first_side.phase as ContractPhase).queue_free()
	check(run.get_completed_contract_count() == 2 and not run.get_unlocked_publisher_ids().has(PublisherCatalog.STARWAVE) and run.get_next_sidestreet_offer().release_id == second.get_release_id(), "One SideStreet completion does not unlock Starwave and leaves second offer pending")
	var second_offer := run.get_next_sidestreet_offer()
	var second_side := await complete_contract(run, run.accept_sidestreet_offer(second_offer.offer_id))
	(second_side.phase as ContractPhase).queue_free()
	check(run.get_completed_contract_count() == 3 and run.get_sidestreet_completion_history().size() == 2 and run.get_unlocked_publisher_ids().has(PublisherCatalog.STARWAVE), "Two releases and three distinct committed completions unlock Starwave")
	check(run.get_pending_publisher_notifications().count(PublisherCatalog.STARWAVE) == 1, "Starwave notification queues once after the third distinct completion")
	check(run.accept_sidestreet_offer(first_offer.offer_id) == null and run.accept_sidestreet_offer(second_offer.offer_id) == null and not run.is_sidestreet_offer_available(), "Completed offers never repeat")
	await process_frame


func _verify_overflow() -> void:
	var run := new_run()
	var game := release(0)
	run.register_release(game)
	var iron := await complete_contract(run, run.accept_primitive_contract())
	(iron.phase as ContractPhase).queue_free()
	var offer := run.get_next_sidestreet_offer()
	var side := run.accept_sidestreet_offer(offer.offer_id)
	var phase := load("res://scenes/phases/contract_phase.tscn").instantiate() as ContractPhase
	phase.setup(side, run)
	root.add_child(phase)
	await process_frame
	phase.call("_publish_candidate_pool", fixture_cards(true))
	select_first_four(phase)
	check(phase.call("_play_selected_hand"), "Overflow fixture completes SideStreet hand one")
	phase.call("_publish_candidate_pool", fixture_cards(false))
	select_first_four(phase)
	var selected: Array[CardData] = phase.call("_selected_cards")
	var plan := side.plan_hand(selected)
	var required_cash: int = RunState.MAX_SIGNED_INT - plan.remainder_cents + 1
	check(run.add_cash_cents(required_cash - run.get_cash_cents()), "Overflow fixture reaches one cent beyond payout capacity")
	var before := snapshot(run, [game])
	check(not phase.call("_play_selected_hand") and snapshot(run, [game]) == before and side.get_successful_hand_count() == 1 and not side.is_completed(), "Overflow rejects hand two without cash, Contract, history, calendar, redraw or sales mutation")
	phase.queue_free()
	await process_frame


func _verify_sales_boundary() -> void:
	var run := new_run()
	var first := release(0)
	run.register_release(first)
	var iron := await complete_contract(run, run.accept_primitive_contract())
	(iron.phase as ContractPhase).queue_free()
	var second := release(751)
	check(run.register_release(second) and run.get_completed_run_cycles() == 2, "Second release enters at the month boundary with independent sales history")
	var frozen_review := second.get_review_result()
	var frozen_revenue := second.get_month_one_sales_revenue_result()
	var offer := run.get_next_sidestreet_offer()
	var cash_before := run.get_cash_cents()
	var first_settled_before: int = run.get_released_game_sales(first.get_release_id()).settled_cents
	var side := await complete_contract(run, run.accept_sidestreet_offer(offer.offer_id))
	var payout: int = side.plan.payout_cents
	var sales := run.get_released_game_sales(second.get_release_id())
	var first_settled_after: int = run.get_released_game_sales(first.get_release_id()).settled_cents
	check(run.get_completed_run_cycles() == 4 and sales.earned_cycles == 2 and sales.settled_cents > 0, "SideStreet second hand reaches normal Month 1 settlement")
	check(run.get_cash_cents() == cash_before + payout + sales.settled_cents + first_settled_after - first_settled_before, "Contract payout and every release's earned sales settle exactly once at the shared boundary")
	check(second.get_review_result() == frozen_review and second.get_month_one_sales_revenue_result() == frozen_revenue, "Contract leaves second ProjectState review and forecast frozen")
	(side.phase as ContractPhase).queue_free()
	await process_frame


func _verify_partial_priority_and_queue() -> void:
	var run := new_run()
	var first := release(0)
	run.register_release(first)
	var iron := await complete_contract(run, run.accept_primitive_contract())
	(iron.phase as ContractPhase).queue_free()
	var offer := run.get_next_sidestreet_offer()
	var side := run.accept_sidestreet_offer(offer.offer_id)
	run.consume_redraw(2)
	var phase := load("res://scenes/phases/contract_phase.tscn").instantiate() as ContractPhase
	check(phase.setup(side, run), "Partial SideStreet state opens for priority and redraw checks")
	root.add_child(phase)
	await process_frame
	check(run.get_available_redraws() == 2 and phase.get_candidate_cards().size() == 7, "SideStreet entry preserves shared redraws and draws seven candidates")
	var second := release(0)
	check(run.register_release(second) and run.get_sidestreet_offer_ids().size() == 2 and not run.is_sidestreet_offer_available(), "New release queues its offer while SideStreet is active")
	check(run.accept_sidestreet_offer(run.get_next_sidestreet_offer().offer_id) == null, "Queued offer cannot be accepted over an active Contract")
	var before := snapshot(run, [first, second])
	check(not phase.call("_play_selected_hand") and snapshot(run, [first, second]) == before and side.get_successful_hand_count() == 0, "Incomplete hand rejects without mutation")
	check(not phase.commit_priority_distribution(side.get_priority_distribution()) and not phase.commit_priority_distribution({0: 50, 1: 50, 2: 50, 3: 50}) and snapshot(run, [first, second]) == before, "Unchanged and invalid SideStreet priority commits cost nothing")
	var draw_before := phase.get_candidate_cards().map(func(card: CardData): return card.id)
	check(phase.commit_priority_distribution({0: 40, 1: 20, 2: 20, 3: 20}) and run.get_completed_run_cycles() == before[1] + 1 and side.get_priority_distribution()[0] == 40, "Changed SideStreet priority costs one productive cycle")
	check(phase.get_candidate_cards().map(func(card: CardData): return card.id) == draw_before, "Priority change affects later draws, not the current seven")
	var reconstruction_before := snapshot(run, [first, second])
	var reconstructed := load("res://scenes/phases/contract_phase.tscn").instantiate() as ContractPhase
	check(reconstructed.setup(side, run), "SideStreet phase reconstruction reuses the accepted ContractState")
	root.add_child(reconstructed)
	await process_frame
	check(reconstructed.get_contract_state() == side and reconstructed.get_candidate_cards().size() == 7 and snapshot(run, [first, second]) == reconstruction_before, "Reconstruction does not refresh redraws, advance or pay")
	reconstructed.queue_free()
	phase.call("_publish_candidate_pool", fixture_cards(true))
	var first_view := phase.get("_candidate_row").get_child(0) as CardView
	first_view.input_button.pressed.emit()
	var redraws_before := run.get_available_redraws()
	check(phase.redraw_selected_cards([0.0], [0.0]) and run.get_available_redraws() == redraws_before - 1 and phase.get_candidate_cards()[0].card_type == &"feature", "SideStreet redraw consumes shared allowance and preserves Feature class")
	check(side.get_successful_hand_count() == 0 and run.get_sidestreet_completion_history().is_empty() and not run.get_unlocked_publisher_ids().has(PublisherCatalog.STARWAVE), "Partial Contract cannot pay, count, or unlock Starwave")
	phase.queue_free()
	await process_frame
