## Focused deterministic Primitive Month 1 Units-Sold verification.
extends SceneTree

const LAUNCH_SCENE := preload("res://scenes/phases/launch_phase.tscn")
const EPSILON := 0.0000001

var _database: PrimitiveSnapshotDatabase
var _failures := 0


func _initialize() -> void:
	await process_frame
	_database = PrimitiveSnapshotDatabase.new()
	_expect(_database.load_ledgers(), "Primitive snapshot ledgers load")
	_verify_formula_examples()
	_verify_all_market_multipliers_and_isolation()
	_verify_preflight_atomicity_and_one_shot()
	await _verify_ui_and_reconstruction()
	if _failures == 0:
		print("Primitive Units-Sold verification passed.")
	quit(_failures)


func _launch_state(final_review: float, marketing_output: int, forecast_id: StringName, competitor_id: StringName = &"fast_follower", cycles: int = 12, reveal_forecast: bool = false, reveal_competitor: bool = false) -> ProjectState:
	var state := ProjectState.new(30)
	state.initialize_snapshots(competitor_id, forecast_id)
	state.add_scope(30)
	state.add_marketing_output(marketing_output)
	state.finalize_design_bugs(false, 0, [&"text"], [])
	state.finalize_alpha(0, [], [])
	if reveal_forecast:
		state.reveal_market_forecast_snapshot()
	if reveal_competitor:
		state.reveal_competitor_snapshot()
	for unused in range(cycles):
		state.advance_cycle()
	state.finalize_beta()
	var ratios: Dictionary[ProjectState.CoreScore, float] = {}
	var review := ReviewResult.new(PrimitiveReviewCalculator.get_baseline_profile(), ratios, 0.0, 0.0, 0.0, final_review, 1.0, 0, 0.0, 1.0, 50, 0.0, final_review, final_review)
	state.commit_review_result(review)
	state.commit_awareness_result(PrimitiveAwarenessCalculator.calculate(state))
	state.commit_launch_market_context_result(PrimitiveLaunchMarketContextCalculator.calculate(state, _database))
	return state


func _calculate(final_review: float, marketing_output: int, forecast_id: StringName) -> UnitsSoldResult:
	return PrimitiveUnitsSoldCalculator.calculate(_launch_state(final_review, marketing_output, forecast_id))


func _verify_formula_examples() -> void:
	var baseline := _calculate(7.0, 0, &"stable_market")
	_expect(baseline != null and baseline.get_formula_id() == &"primitive_units_sold_v1" and baseline.get_sales_period() == &"month_1", "Result uses the locked Primitive Month 1 profile")
	_expect(baseline.get_base_monthly_demand() == 500 and baseline.get_final_review_tenths() == 70 and baseline.get_quality_baseline_tenths() == 70, "Base demand 500 and exact Review/7 quality inputs are preserved")
	_expect(baseline.get_total_awareness() == 100 and baseline.get_awareness_numerator() == 300 and baseline.get_awareness_scale() == 200, "Zero Marketing preserves committed Awareness 100 and multiplier 1.50")
	_expect(baseline.get_launch_decay_basis_points() == 10000 and baseline.get_market_demand_basis_points() == 10000, "Month 1 decay and stable market are exact 1.00 basis-point factors")
	_expect(_equal(baseline.get_pre_rounding_units(), 750.0) and baseline.get_final_units_sold() == 750, "7.0 Review, 1.50 Awareness, and Stable Market produce exactly 750 units")
	var representative := _calculate(8.0, 25, &"market_surge")
	_expect(_equal(representative.get_pre_rounding_units(), 1067.8571428571427) and representative.get_final_units_sold() == 1067, "8.0 Review, 1.625 Awareness, and 1.15 market floor 1067.857... to 1067")
	var zero_review := _calculate(0.0, 0, &"market_boom")
	_expect(zero_review.get_exact_numerator() == 0 and zero_review.get_final_units_sold() == 0, "Zero Review produces zero Month 1 units with no minimum guarantee")
	var maximum_review := _calculate(10.0, 100, &"market_boom")
	_expect(_equal(maximum_review.get_pre_rounding_units(), 1857.142857142857) and maximum_review.get_final_units_sold() == 1857, "Maximum valid Review with Awareness 2.00 and Market Boom floors once to 1857")
	var below_integer := _calculate(7.0, 0, &"market_crash")
	_expect(_equal(below_integer.get_pre_rounding_units(), 562.5) and below_integer.get_final_units_sold() == 562, "Final floor occurs after the complete fractional product")


func _verify_all_market_multipliers_and_isolation() -> void:
	var expected := {&"market_crash": [7500, 562], &"market_slump": [9000, 675], &"stable_market": [10000, 750], &"market_surge": [11500, 862], &"market_boom": [13000, 975]}
	for forecast_id: StringName in expected:
		var result := _calculate(7.0, 0, forecast_id)
		_expect(result.get_market_demand_basis_points() == expected[forecast_id][0] and result.get_final_units_sold() == expected[forecast_id][1], "%s applies exact basis points and one final floor" % forecast_id)
	var concealed := _launch_state(7.0, 25, &"market_surge", &"reckless_upstart", 8, false, false)
	var revealed := _launch_state(7.0, 25, &"market_surge", &"obsessive_polisher", 25, true, true)
	var concealed_result := PrimitiveUnitsSoldCalculator.calculate(concealed)
	var revealed_result := PrimitiveUnitsSoldCalculator.calculate(revealed)
	_expect(concealed_result.get_final_units_sold() == revealed_result.get_final_units_sold(), "Forecast reveal state and competitor timing do not change sales")
	_expect(not concealed.is_market_forecast_snapshot_revealed() and not concealed.is_competitor_snapshot_revealed(), "Sales calculation does not reveal concealed snapshots")


func _verify_preflight_atomicity_and_one_shot() -> void:
	var unfinished := ProjectState.new(30)
	_expect(PrimitiveUnitsSoldCalculator.calculate(unfinished) == null and not unfinished.has_units_sold_result(), "Missing launch prerequisites reject without mutation")
	var invalid_review := _launch_state(7.0, 0, &"stable_market")
	invalid_review.get_review_result().set("_final_review", NAN)
	_expect(PrimitiveUnitsSoldCalculator.calculate(invalid_review) == null and not invalid_review.has_units_sold_result(), "Nonfinite Review rejects atomically")
	var invalid_awareness := _launch_state(7.0, 0, &"stable_market")
	invalid_awareness.get_awareness_result().set("_awareness_multiplier", INF)
	_expect(PrimitiveUnitsSoldCalculator.calculate(invalid_awareness) == null and not invalid_awareness.has_units_sold_result(), "Nonfinite Awareness rejects atomically")
	var overflow := _launch_state(10.0, 0, &"market_boom")
	overflow.get_awareness_result().set("_total_awareness", ProjectState.MAX_SIGNED_INT)
	_expect(PrimitiveUnitsSoldCalculator.calculate(overflow) == null and not overflow.has_units_sold_result(), "Overflowing Awareness input rejects atomically")
	var state := _launch_state(8.0, 25, &"market_surge")
	var review := state.get_review_result()
	var awareness := state.get_awareness_result()
	var context := state.get_launch_market_context_result()
	var before := [state.get_marketing_output(), state.get_current_cycle(), state.is_competitor_snapshot_revealed(), state.is_market_forecast_snapshot_revealed()]
	var result := PrimitiveUnitsSoldCalculator.calculate(state)
	_expect(state.commit_units_sold_result(result), "Valid Month 1 sales result commits once")
	_expect(PrimitiveUnitsSoldCalculator.calculate(state) == null and not state.commit_units_sold_result(result) and state.get_units_sold_result() == result, "Repeated calculation and commit cannot replace the result")
	_expect(state.get_review_result() == review and state.get_awareness_result() == awareness and state.get_launch_market_context_result() == context and before == [state.get_marketing_output(), state.get_current_cycle(), state.is_competitor_snapshot_revealed(), state.is_market_forecast_snapshot_revealed()], "Sales preserves every source result, Marketing, cycles, and reveal flags")
	var other := _launch_state(7.0, 0, &"market_crash")
	_expect(not other.commit_units_sold_result(result) and not other.has_units_sold_result(), "A result from different committed inputs rejects atomically")


func _verify_ui_and_reconstruction() -> void:
	var state := _launch_state(8.0, 25, &"market_surge", &"fast_follower", 13, false, false)
	state.commit_units_sold_result(PrimitiveUnitsSoldCalculator.calculate(state))
	var run := RunState.new()
	run.initialize_cash(4321)
	var launch := LAUNCH_SCENE.instantiate() as LaunchPhase
	root.add_child(launch)
	await process_frame
	_expect(launch.setup(state, run, _database), "LaunchPhase reads the committed Month 1 sales result")
	var visible := _visible_text(launch)
	_expect(visible.contains("Month 1 Units Sold: 1067") and visible.contains("Revenue and remaining release results pending"), "Launch UI shows the accurate period and updated pending status")
	_expect(not visible.contains("Market Surge") and not visible.contains("Fast Follower") and not visible.contains("Hidden") and not visible.contains("Remaining Bugs") and not visible.contains("$"), "Sales UI does not reveal concealed inputs, Bugs, revenue, or cash")
	var reconstructed := LAUNCH_SCENE.instantiate() as LaunchPhase
	root.add_child(reconstructed)
	await process_frame
	_expect(reconstructed.setup(state, run, _database) and _visible_text(reconstructed) == visible and state.get_units_sold_result().get_final_units_sold() == 1067, "Launch reconstruction reuses the same immutable result")
	_expect(reconstructed.get_project_state() == state and reconstructed.get_run_state() == run and run.get_cash() == 4321 and state.get_current_cycle() == 13, "Reconstruction preserves exact state identities, cash, and cycles")
	launch.queue_free()
	reconstructed.queue_free()
	await process_frame


func _visible_text(node: Node) -> String:
	var texts: Array[String] = []
	for child: Node in node.get_node("Layout").get_children():
		if child is Label and child.visible:
			texts.append((child as Label).text)
	return " | ".join(texts)


func _equal(a: float, b: float) -> bool:
	return absf(a - b) <= EPSILON


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		_failures += 1
		push_error("FAIL: %s" % description)
