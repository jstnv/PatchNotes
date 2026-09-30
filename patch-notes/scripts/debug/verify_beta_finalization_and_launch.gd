## Focused Beta finalization and Launch-boundary verification.
extends SceneTree

const BETA_SCENE := preload("res://scenes/phases/beta_phase.tscn")
const GAMEPLAY_SCENE := preload("res://scenes/gameplay.tscn")

var _snapshots: PrimitiveSnapshotDatabase
var _failures := 0


func _initialize() -> void:
	await process_frame
	_snapshots = PrimitiveSnapshotDatabase.new()
	_snapshots.load_ledgers()
	await _verify_planning_and_immediate_launch()
	await _verify_warnings_cancel_and_confirm()
	await _verify_selection_independence()
	await _verify_gameplay_transition()
	if _failures == 0:
		print("Beta finalization and Launch-boundary verification passed.")
	quit(_failures)


func _make_state(scope: int = 0, hidden: int = 4, marketing: int = 0) -> ProjectState:
	var state := ProjectState.new(30)
	state.initialize_snapshots(&"fast_follower", &"market_surge")
	state.add_scope(scope)
	state.add_marketing_output(marketing)
	state.finalize_design_bugs(false, hidden, [&"text"] as Array[StringName], [&"sprites"] as Array[StringName])
	state.finalize_alpha(0, [&"controls"] as Array[StringName], [&"enemies"] as Array[StringName])
	return state


func _make_beta(state: ProjectState, cash: int = 1000, begin: bool = true) -> Dictionary:
	var run := RunState.new()
	run.initialize_cash(cash)
	var beta := BETA_SCENE.instantiate() as BetaPhase
	root.add_child(beta)
	await process_frame
	beta.setup(state, run, _snapshots)
	beta.authorize_launch()
	if begin:
		beta.begin_beta([0.05, 0.15, 0.40, 0.50, 0.80, 0.85, 0.90], [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7])
	return {&"beta": beta, &"run": run, &"state": state}


func _verify_planning_and_immediate_launch() -> void:
	var planning := await _make_beta(_make_state(30, 0, 1), 321, false)
	_expect(not planning.beta.request_launch(), "Planning rejects Launch")
	_expect(not planning.state.has_beta_finalization() and planning.state.get_current_cycle() == 0 and planning.run.get_cash() == 321, "Planning rejection consumes no cycle or cash")
	planning.beta.queue_free()
	await process_frame

	var fixture := await _make_beta(_make_state(30, 3, 1), 777)
	var state: ProjectState = fixture.state
	var beta: BetaPhase = fixture.beta
	var emissions := [0]
	beta.launch_requested.connect(func() -> void: emissions[0] += 1)
	var cycles := state.get_current_cycle()
	_expect(beta.request_launch(), "No-risk Launch finalizes immediately without a dialog")
	_expect(state.has_beta_finalization() and state.is_launch_ready() and emissions[0] == 1, "Immediate Launch finalizes and emits exactly once")
	_expect(state.get_current_cycle() == cycles and fixture.run.get_cash() == 777, "Launch costs zero cycles and zero cash")
	_expect(state.get_hidden_bugs() == 3 and state.get_remaining_bugs() == 3 and state.get_marketing_output() == 1, "Final launch inputs remain authoritative and unconverted")
	_expect(not beta.request_launch() and emissions[0] == 1, "Repeated Launch cannot finalize or emit twice")
	_expect(not state.add_scope(1) and not state.add_marketing_output(1) and state.discover_bugs(1) == -1 and not state.advance_cycle(), "Post-Beta project mutation is frozen")
	_expect((beta.get_node("%HandContainer") as Container).get_child_count() == 0 and beta.get("_phase_state") == BetaPhase.PhaseState.FINALIZED, "Beta retirement removes candidates without resolving them")
	beta.queue_free()
	await process_frame


func _verify_warnings_cancel_and_confirm() -> void:
	var state := _make_state(24, 5, 0)
	state.discover_bugs(3)
	var fixture := await _make_beta(state, 1000)
	var beta: BetaPhase = fixture.beta
	for index in range(4):
		beta.call("_on_card_pressed", beta.get("_candidate_views")[index])
	_expect(beta.host_playtest(), "Warning fixture queues a pending Host Playtest correction")
	var before := _snapshot(fixture)
	_expect(not beta.request_launch() and beta.get("_launch_confirmation_pending"), "Risky Launch opens one confirmation instead of finalizing")
	var warning: String = beta.get_node("%LaunchWarningDialog").dialog_text
	_expect(warning.contains("24 / 30") and warning.contains("Scope shortfall: 6") and warning.contains("Known Bugs remaining: 3") and warning.contains("No Marketing activity"), "Combined dialog reports all three knowable warnings exactly")
	_expect(not warning.contains("Hidden") and not warning.contains("Remaining Bugs") and not warning.contains("Fast Follower") and not warning.contains("Market Surge"), "Warning reveals no concealed Bugs or snapshots")
	_expect(not beta.request_launch(), "Repeated activation cannot create another confirmation")
	_expect(beta.cancel_launch_for_verification(), "Cancel returns to Active Development")
	_expect(_snapshot(fixture) == before and not state.has_beta_finalization(), "Cancel preserves project, run, pending, pool, selection, priorities, feedback, and cycle")
	_expect(not beta.request_launch(), "Risky Launch can be requested again after Cancel")
	var cash_before: int = fixture.run.get_cash()
	var cycle_before := state.get_current_cycle()
	_expect(beta.confirm_launch_for_verification(), "Confirm allows under-Scope, Known-Bug, zero-Marketing Launch")
	_expect(state.has_beta_finalization() and state.get_current_scope() == 24 and state.get_required_scope() == 30 and state.get_known_bugs() == 3 and state.get_hidden_bugs() == 2, "Confirmed launch preserves Scope and internal Bug inputs")
	_expect(state.get_marketing_output() == 0 and fixture.run.get_cash() == cash_before and state.get_current_cycle() == cycle_before, "Confirm performs no Awareness conversion and costs zero cash/cycles")
	_expect(beta.get_pending_corrective_pass_ids().is_empty(), "Successful finalization discards pending corrective Passes without refund or injection")
	beta.queue_free()
	await process_frame


func _verify_selection_independence() -> void:
	for count in range(5):
		var fixture := await _make_beta(_make_state(30, 0, 1), 0)
		var beta: BetaPhase = fixture.beta
		for index in range(count):
			beta.call("_on_card_pressed", beta.get("_candidate_views")[index])
		var exhausted: Array[StringName] = fixture.state.get_exhausted_beta_card_ids()
		_expect(beta.request_launch(), "Launch accepts %d selected cards" % count)
		_expect(fixture.state.get_exhausted_beta_card_ids() == exhausted and fixture.state.get_current_cycle() == 0, "Selection %d resolves no cards, exhausts nothing, and costs no cycle" % count)
		beta.queue_free()
		await process_frame


func _verify_gameplay_transition() -> void:
	var gameplay := GAMEPLAY_SCENE.instantiate()
	var state := _make_state(30, 1, 1)
	var run := RunState.new()
	run.initialize_cash(4321)
	gameplay.project_state = state
	gameplay.run_state = run
	gameplay.set_review_variance_roll_for_verification(50)
	root.add_child(gameplay)
	await process_frame
	var old_phase: Control = gameplay.get("_active_phase")
	gameplay.get_node("%PhaseRoot").remove_child(old_phase)
	old_phase.queue_free()
	var beta := BETA_SCENE.instantiate() as BetaPhase
	beta.setup(state, run, gameplay.get_snapshot_database())
	beta.authorize_launch()
	beta.launch_requested.connect(Callable(gameplay, "_on_beta_launch_requested").bind(beta))
	gameplay.get_node("%PhaseRoot").add_child(beta)
	gameplay.set("_active_phase", beta)
	beta.begin_beta([0.05, 0.15, 0.40, 0.50, 0.80, 0.85, 0.90], [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7])
	_expect(run.consume_redraw(4), "Launch fixture spends its Beta redraw bank")
	var run_cycles_before := run.get_completed_run_cycles()
	_expect(beta.request_launch(), "Authoritative Gameplay Beta finalizes")
	await process_frame
	var active: Control = gameplay.get("_active_phase")
	_expect(active is StudioPhase and gameplay.get_node("%PhaseRoot").get_child_count() == 1, "Gameplay automatically enters Studio after launch results")
	_expect((active as StudioPhase).get_project_state() == state and (active as StudioPhase).get_run_state() == run and run.get_cash() == 4321, "Automatic Studio entry preserves the exact ProjectState, RunState, and cash")
	_expect(run.get_available_redraws() == 4 and run.get_completed_run_cycles() == run_cycles_before, "Successful Studio entry refills redraws without advancing time")
	_expect(state.has_review_result() and state.get_review_result().get_variance_roll() == 50, "Gameplay commits exactly the controlled one-shot Review result before Launch presentation")
	_expect(state.has_awareness_result() and state.get_awareness_result().get_marketing_output_used() == state.get_marketing_output(), "Gameplay commits Awareness exactly once from frozen Marketing Output")
	_expect(state.has_launch_market_context_result() and state.get_launch_market_context_result().get_player_launch_cycle() == state.get_current_cycle(), "Gameplay commits launch market context exactly once from frozen state")
	_expect(state.has_units_sold_result() and state.get_units_sold_result().get_sales_period() == &"month_1", "Gameplay commits Month 1 units sold exactly once from prior launch results")
	_expect(state.has_month_one_sales_revenue_result() and state.get_month_one_sales_revenue_result().get_earned_sales_cycle_count() == 0, "Gameplay commits the projected Month 1 sales/revenue foundation without earning sales at Launch")
	_expect(not active.get_node("%SummaryPanel").visible and active.get_node_or_null("%ContinueButton") == null, "Studio needs no continuation confirmation and starts with release stats hidden")
	active.open_summary()
	var text := (active.get_node("%ReviewLabel") as Label).text + (active.get_node("%EarnedLabel") as Label).text
	_expect(not text.contains("Hidden") and not text.contains("Remaining") and text.contains("Final Review:") and text.contains("Earned: 0"), "Post Game Summaries opens the committed results")
	gameplay.queue_free()
	await process_frame


func _snapshot(fixture: Dictionary) -> Array:
	var beta: BetaPhase = fixture.beta
	var state: ProjectState = fixture.state
	var pool_ids: Array[StringName] = []
	var pool_instances: Array[int] = []
	var selected: Array[int] = []
	for card: CardData in beta.get("_candidate_cards"):
		pool_ids.append(card.id)
	for view: CardView in beta.get("_candidate_views"):
		pool_instances.append(view.get_instance_id())
	for view: CardView in beta.get_selected_candidate_views():
		selected.append(view.get_instance_id())
	return [state.get_hidden_bugs(), state.get_known_bugs(), state.get_remaining_bugs(), state.get_marketing_output(), fixture.run.get_cash(), state.get_current_cycle(), state.get_current_scope(), state.get_exhausted_beta_card_ids(), state.is_competitor_snapshot_revealed(), state.is_market_forecast_snapshot_revealed(), beta.get_priority_distribution(), beta.get_pending_corrective_pass_ids(), pool_ids, pool_instances, selected, beta.get_node("%ActionFeedbackLabel").text]


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		_failures += 1
		push_error("FAIL: %s" % description)
