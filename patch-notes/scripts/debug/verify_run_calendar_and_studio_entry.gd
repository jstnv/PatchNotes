## Focused run calendar and Studio release-summary verification.
extends SceneTree

const STUDIO_SCENE := preload("res://scenes/phases/studio_phase.tscn")
var _failures := 0


func _initialize() -> void:
	_verify_calendar()
	await _verify_studio_summary(false)
	await _verify_studio_summary(true)
	if _failures == 0:
		print("Run calendar and automatic Studio entry verification passed.")
	quit(_failures)


func _verify_calendar() -> void:
	var run := RunState.new()
	_expect(run.get_completed_run_cycles() == 0 and run.get_current_month() == 1 and run.get_current_half() == 1 and run.get_calendar_label() == "1980 · Month 1, First Half", "New run begins at Month 1 first half with zero completed cycles")
	var signals := [0]
	run.calendar_changed.connect(func() -> void: signals[0] += 1)
	_expect(not run.will_next_cycle_cross_month_boundary() and run.advance_calendar_cycle(), "First successful run cycle advances once without crossing a month")
	_expect(run.get_completed_run_cycles() == 1 and run.get_calendar_label() == "1980 · Month 1, Second Half" and signals[0] == 1, "One cycle reaches Month 1 second half")
	_expect(run.will_next_cycle_cross_month_boundary() and run.advance_calendar_cycle(), "Second successful cycle reports and crosses the month boundary")
	_expect(run.get_completed_run_cycles() == 2 and run.get_calendar_label() == "1980 · Month 2, First Half" and signals[0] == 2, "Two cycles reach Month 2 first half")
	run.set("_completed_run_cycles", RunState.MAX_SIGNED_INT)
	_expect(not run.can_advance_calendar_cycle() and not run.advance_calendar_cycle() and run.get_completed_run_cycles() == RunState.MAX_SIGNED_INT and signals[0] == 2, "Calendar overflow rejects without mutation or signal")


func _verify_studio_summary(revealed: bool) -> void:
	var fixture := _launch_fixture(revealed)
	var state: ProjectState = fixture.state
	var run: RunState = fixture.run
	var database: PrimitiveSnapshotDatabase = fixture.database
	var before := [run.get_completed_run_cycles(), run.get_cash_cents(), state.get_current_cycle()]
	var studio := STUDIO_SCENE.instantiate() as StudioPhase
	root.add_child(studio)
	_expect(studio.setup(state, run, database), "Studio accepts complete committed launch results")
	_expect(not studio.get_node("%SummaryPanel").visible, "Summary is hidden on Studio entry")
	studio.open_summary()
	await process_frame
	var text := _visible_text(studio)
	_expect(text.contains("Month 2, Second Half") and text.contains("Projected Month 1 Units: 750") and text.contains("Projected Month 1 Net: $5244.75"), "Studio displays calendar and exact projected release totals")
	_expect(text.contains("Earned: 0 / 2 Month 1 cycles · Lifetime 0 units") and text.contains("Settled Revenue: $0.00"), "Studio clearly distinguishes projected from earned and settled values")
	_expect(before == [run.get_completed_run_cycles(), run.get_cash_cents(), state.get_current_cycle()], "Studio entry costs zero calendar/project cycles and zero cash")
	_expect(studio.get_project_state() == state and studio.get_run_state() == run, "Studio preserves exact ProjectState and RunState identities")
	if revealed:
		_expect(text.contains("Fast Follower") and text.contains("Stable Market"), "Studio displays only previously revealed snapshot facts")
	else:
		_expect(not text.contains("Fast Follower") and not text.contains("Stable Market") and not text.contains("Hidden") and not text.contains("Remaining Bugs"), "Studio preserves snapshot and Bug concealment")
	var rebuilt := STUDIO_SCENE.instantiate() as StudioPhase
	root.add_child(rebuilt)
	_expect(rebuilt.setup(state, run, database), "Studio reconstructs from committed results")
	rebuilt.open_summary()
	_expect(_visible_text(rebuilt) == text, "Opening a reconstructed summary reuses committed results without time or cash mutation")
	studio.queue_free()
	rebuilt.queue_free()
	await process_frame


func _launch_fixture(revealed: bool) -> Dictionary:
	var database := PrimitiveSnapshotDatabase.new()
	database.load_ledgers()
	var state := ProjectState.new(30)
	state.initialize_snapshots(&"fast_follower", &"stable_market")
	state.finalize_design_bugs(false, 0, [], [])
	state.finalize_alpha(0, [], [])
	if revealed:
		state.reveal_competitor_snapshot()
		state.reveal_market_forecast_snapshot()
	state.finalize_beta()
	var review := ReviewResult.new(PrimitiveReviewCalculator.get_baseline_profile(), {}, 0.0, 0.0, 0.0, 7.0, 1.0, 0, 0.0, 1.0, 50, 0.0, 7.0, 7.0)
	state.commit_review_result(review)
	state.commit_awareness_result(PrimitiveAwarenessCalculator.calculate(state))
	state.commit_launch_market_context_result(PrimitiveLaunchMarketContextCalculator.calculate(state, database))
	state.commit_units_sold_result(PrimitiveUnitsSoldCalculator.calculate(state))
	state.commit_month_one_sales_revenue_result(PrimitiveMonthOneSalesRevenueCalculator.calculate(state))
	var run := RunState.new()
	run.initialize_cash(0)
	for unused in range(3): run.advance_calendar_cycle()
	return {&"state": state, &"run": run, &"database": database}


func _visible_text(node: Node) -> String:
	var result := ""
	if node is Label and node.is_visible_in_tree(): result += (node as Label).text + "\n"
	for child: Node in node.get_children(): result += _visible_text(child)
	return result


func _expect(condition: bool, description: String) -> void:
	if condition: print("PASS: %s" % description)
	else:
		_failures += 1
		push_error("FAIL: %s" % description)
