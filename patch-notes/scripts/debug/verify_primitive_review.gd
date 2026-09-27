## Focused deterministic Primitive Review verification.
extends SceneTree

const LAUNCH_SCENE := preload("res://scenes/phases/launch_phase.tscn")
const EPSILON := 0.000001

var _failures := 0


func _initialize() -> void:
	await process_frame
	_verify_anchors_and_cap()
	_verify_imbalance_and_population_deviation()
	_verify_scope_and_bugs()
	_verify_variance_and_rounding()
	await _verify_one_shot_exclusions_and_ui()
	if _failures == 0:
		print("Primitive Review verification passed.")
	quit(_failures)


func _state(scores: Array[int], scope: int = 30, hidden: int = 0, known: int = 0, required_scope: int = 30, marketing: int = 0, cycles: int = 0, competitor: StringName = &"fast_follower", forecast: StringName = &"market_surge", reveal_snapshots: bool = false) -> ProjectState:
	var state := ProjectState.new(required_scope)
	state.initialize_snapshots(competitor, forecast)
	for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
		state.add_core_score(category, scores[category])
	state.add_scope(scope)
	state.add_marketing_output(marketing)
	state.finalize_design_bugs(false, hidden + known, [], [])
	if known > 0:
		state.discover_bugs(known)
	state.finalize_alpha(0, [], [])
	if reveal_snapshots:
		state.reveal_competitor_snapshot()
		state.reveal_market_forecast_snapshot()
	for unused in range(cycles):
		state.advance_cycle()
	state.finalize_beta()
	return state


func _review(scores: Array[int], scope: int = 30, hidden: int = 0, known: int = 0, roll: int = 50, required_scope: int = 30) -> ReviewResult:
	return PrimitiveReviewCalculator.calculate(_state(scores, scope, hidden, known, required_scope), roll)


func _verify_anchors_and_cap() -> void:
	var baseline := _review([20, 20, 20, 20])
	_expect(baseline.get_profile_id() == &"primitive_b_baseline" and baseline.get_standards().values() == [20, 20, 20, 20], "Primitive B profile is immutable 20/20/20/20")
	_expect(_equal(baseline.get_production_rating(), 8.0) and _equal(baseline.get_final_review(), 8.0), "Exact standards with complete Scope, zero Bugs, and zero variance score 8.0")
	var exceptional := _review([25, 25, 25, 25])
	_expect(_equal(exceptional.get_production_rating(), 10.0) and _equal(exceptional.get_final_review(), 10.0), "Four capped 1.25 ratios score 10.0")
	var capped := _review([200, 100, 50, 26])
	for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
		_expect(_equal(capped.get_normalized_ratio(category), 1.25), "Ratio above 1.25 caps for category %d" % category)
	var zero := _review([0, 0, 0, 0], 30, 0, 0, 99)
	_expect(_equal(zero.get_production_rating(), 0.0) and _equal(zero.get_final_review(), 0.5), "Zero production remains bounded after positive variance")


func _verify_imbalance_and_population_deviation() -> void:
	var balanced := _review([15, 15, 15, 15])
	var imbalanced := _review([25, 25, 5, 5])
	_expect(_equal(balanced.get_average_ratio(), imbalanced.get_average_ratio()) and imbalanced.get_production_rating() < balanced.get_production_rating(), "Equal average with greater imbalance lowers Production Rating")
	_expect(_equal(imbalanced.get_core_deviation(), 0.5), "Core Deviation uses population division by four")


func _verify_scope_and_bugs() -> void:
	var complete := _review([20, 20, 20, 20], 30)
	var scope_24 := _review([20, 20, 20, 20], 24)
	var scope_27 := _review([20, 20, 20, 20], 27)
	var overscope_state := _state([20, 20, 20, 20], 35)
	var overscope := PrimitiveReviewCalculator.calculate(overscope_state, 50)
	_expect(_equal(complete.get_scope_completion(), 1.0) and _equal(scope_24.get_scope_completion(), 0.8) and _equal(scope_27.get_scope_completion(), 0.9), "Scope Completion is exact and proportional")
	_expect(overscope_state.get_current_scope() == 35 and _equal(overscope.get_scope_completion(), 1.0), "Scope overshoot is preserved but grants no Review bonus")
	var invalid := _state([20, 20, 20, 20], 0, 0, 0, 0)
	_expect(PrimitiveReviewCalculator.calculate(invalid, 50) == null and not invalid.has_review_result(), "Required Scope zero rejects atomically")
	for bugs in [0, 3, 6, 15, 30]:
		var result := _review([20, 20, 20, 20], 30, bugs)
		var expected: float = maxf(0.25, 1.0 - (float(bugs) / 30.0))
		_expect(_equal(result.get_bug_multiplier(), expected), "Remaining Bugs %d use the locked density and floor" % bugs)
	var hidden := _review([20, 20, 20, 20], 30, 6, 0)
	var split := _review([20, 20, 20, 20], 30, 3, 3)
	_expect(_equal(hidden.get_final_review(), split.get_final_review()) and _equal(hidden.get_bug_density_for_authority(), split.get_bug_density_for_authority()), "Hidden/Known split and discovery do not change equal Remaining-Bug Review")


func _verify_variance_and_rounding() -> void:
	var boundaries := {0: -0.5, 9: -0.5, 10: -0.25, 29: -0.25, 30: 0.0, 69: 0.0, 70: 0.25, 89: 0.25, 90: 0.5, 99: 0.5}
	for roll: int in boundaries:
		_expect(_equal(PrimitiveReviewCalculator.variance_for_roll(roll), boundaries[roll]), "Variance roll %d maps to %+.2f" % [roll, boundaries[roll]])
	_expect(_equal(PrimitiveReviewCalculator.round_half_up_one_decimal(5.12), 5.1) and _equal(PrimitiveReviewCalculator.round_half_up_one_decimal(5.15), 5.2), "Final rounding is explicit nonnegative half-up")
	_expect(_equal(PrimitiveReviewCalculator.round_half_up_one_decimal(-1.0), 0.0) and _equal(PrimitiveReviewCalculator.round_half_up_one_decimal(11.0), 10.0), "Final Review clamps to 0.0 through 10.0")


func _verify_one_shot_exclusions_and_ui() -> void:
	var state := _state([20, 20, 20, 20], 30, 2, 1, 30, 99, 7, &"reckless_upstart", &"market_boom")
	var run := RunState.new()
	run.initialize_cash(12345)
	var before := [state.get_core_score(ProjectState.CoreScore.GRAPHICS), state.get_current_scope(), state.get_hidden_bugs(), state.get_known_bugs(), state.get_marketing_output(), state.get_current_cycle(), state.get_assigned_competitor_snapshot_id_for_authority(), state.get_assigned_market_forecast_snapshot_id_for_authority(), run.get_cash()]
	var result := PrimitiveReviewCalculator.calculate(state, 70)
	_expect(state.commit_review_result(result), "ProjectState commits one typed immutable Review result")
	state.commit_awareness_result(PrimitiveAwarenessCalculator.calculate(state))
	var database := PrimitiveSnapshotDatabase.new()
	database.load_ledgers()
	state.commit_launch_market_context_result(PrimitiveLaunchMarketContextCalculator.calculate(state, database))
	state.commit_units_sold_result(PrimitiveUnitsSoldCalculator.calculate(state))
	_expect(not state.commit_review_result(PrimitiveReviewCalculator.calculate(state, 0)) and state.get_review_result() == result and result.get_variance_roll() == 70, "Repeated requests cannot reroll or overwrite Review")
	_expect(before == [state.get_core_score(ProjectState.CoreScore.GRAPHICS), state.get_current_scope(), state.get_hidden_bugs(), state.get_known_bugs(), state.get_marketing_output(), state.get_current_cycle(), state.get_assigned_competitor_snapshot_id_for_authority(), state.get_assigned_market_forecast_snapshot_id_for_authority(), run.get_cash()], "Review costs zero cash/cycles and preserves every frozen launch input")
	var comparison := PrimitiveReviewCalculator.calculate(_state([20, 20, 20, 20], 30, 2, 1, 30, 0, 0, &"obsessive_polisher", &"market_crash", true), 70)
	_expect(_equal(result.get_final_review(), comparison.get_final_review()), "Marketing, cash-independent snapshot identity, reveal-independent state, and cycles do not affect Review")
	var launch := LAUNCH_SCENE.instantiate() as LaunchPhase
	root.add_child(launch)
	await process_frame
	_expect(launch.setup(state, run, database), "LaunchPhase reads the committed Review result")
	var visible := (launch.get_node("%ReviewLabel") as Label).text + (launch.get_node("%ProductionRatingLabel") as Label).text + (launch.get_node("%ScopeCompletionLabel") as Label).text + (launch.get_node("%BugMultiplierLabel") as Label).text + (launch.get_node("%VarianceLabel") as Label).text + (launch.get_node("Layout/Status") as Label).text
	_expect(visible.contains("Review:") and visible.contains("Production Rating") and visible.contains("Scope Completion") and visible.contains("Bug Multiplier") and visible.contains("+0.25") and visible.contains("release results pending"), "Launch UI displays the permitted Review breakdown")
	_expect(not visible.contains("Hidden") and not visible.contains("Remaining Bugs") and not visible.contains("Reckless") and not visible.contains("Market Boom") and not visible.contains("$"), "Launch UI conceals Bugs, snapshots, and cash results")
	var reconstruction := LAUNCH_SCENE.instantiate() as LaunchPhase
	root.add_child(reconstruction)
	await process_frame
	_expect(reconstruction.setup(state, run, database) and (reconstruction.get_node("%ReviewLabel") as Label).text == (launch.get_node("%ReviewLabel") as Label).text and state.get_review_result() == result, "Launch reconstruction preserves the same one-shot result without recalculation")
	launch.queue_free()
	reconstruction.queue_free()
	await process_frame


func _equal(a: float, b: float) -> bool:
	return absf(a - b) <= EPSILON


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		_failures += 1
		push_error("FAIL: %s" % description)
