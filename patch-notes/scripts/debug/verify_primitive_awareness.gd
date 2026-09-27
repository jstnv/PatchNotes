## Focused deterministic Primitive Awareness verification.
extends SceneTree

const LAUNCH_SCENE := preload("res://scenes/phases/launch_phase.tscn")
const EPSILON := 0.0000001

var _failures := 0


func _initialize() -> void:
	await process_frame
	_verify_formula_examples()
	_verify_preflight_and_atomicity()
	await _verify_one_shot_isolation_and_ui()
	if _failures == 0:
		print("Primitive Awareness verification passed.")
	quit(_failures)


func _launch_state(marketing_output: int, competitor: StringName = &"fast_follower", forecast: StringName = &"market_surge", reveal: bool = false) -> ProjectState:
	var state := ProjectState.new(30)
	state.initialize_snapshots(competitor, forecast)
	for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
		state.add_core_score(category, 20)
	state.add_scope(30)
	state.add_marketing_output(marketing_output)
	state.finalize_design_bugs(false, 3, [], [])
	state.finalize_alpha(0, [], [])
	if reveal:
		state.reveal_competitor_snapshot()
		state.reveal_market_forecast_snapshot()
	state.finalize_beta()
	state.commit_review_result(PrimitiveReviewCalculator.calculate(state, 50))
	return state


func _verify_formula_examples() -> void:
	var examples := {0: [100, 1.5], 1: [101, 1.505], 25: [125, 1.625], 100: [200, 2.0], 300: [400, 3.0]}
	for marketing: int in examples:
		var state := _launch_state(marketing)
		var result := PrimitiveAwarenessCalculator.calculate(state)
		_expect(result != null and result.get_formula_id() == &"primitive_awareness_v1", "Marketing %d produces the locked profile" % marketing)
		_expect(result.get_marketing_output_used() == marketing and result.get_launch_marketing() == marketing and result.get_current_launch_marketing() == marketing, "Marketing %d converts exactly through month-one Launch Marketing" % marketing)
		_expect(result.get_launch_marketing_decay_basis_points() == 10000 and result.get_organic_awareness() == 100 and result.get_existing_fans() == 0 and result.get_fan_awareness() == 0, "Marketing %d uses exact Primitive constants" % marketing)
		_expect(result.get_total_awareness() == examples[marketing][0] and _equal(result.get_awareness_multiplier(), examples[marketing][1]), "Marketing %d produces exact Total Awareness and multiplier" % marketing)
		_expect(state.get_marketing_output() == marketing, "Marketing Output %d remains independently preserved" % marketing)
	_expect(PrimitiveAwarenessCalculator.calculate(_launch_state(500)).get_total_awareness() == 600, "No undocumented Awareness cap exists")


func _verify_preflight_and_atomicity() -> void:
	var unfinished := ProjectState.new(30)
	_expect(PrimitiveAwarenessCalculator.calculate(unfinished) == null and not unfinished.has_awareness_result(), "Missing Beta finalization rejects without partial state")
	var missing_review := ProjectState.new(30)
	missing_review.initialize_snapshots(&"fast_follower", &"market_surge")
	missing_review.finalize_design_bugs(false, 0, [], [])
	missing_review.finalize_alpha(0, [], [])
	missing_review.finalize_beta()
	_expect(PrimitiveAwarenessCalculator.calculate(missing_review) == null, "Missing Review result rejects Awareness")
	var overflow := _launch_state(0)
	overflow.set("_marketing_output", ProjectState.MAX_SIGNED_INT)
	_expect(PrimitiveAwarenessCalculator.calculate(overflow) == null and not overflow.has_awareness_result(), "Marketing overflow rejects atomically")
	var invalid_commit := _launch_state(4)
	var invalid := AwarenessResult.new(&"wrong_profile", 4, 4, 10000, 4, 100, 0, 2500, 10000, 0, 104, 200, 1.52)
	_expect(not invalid_commit.commit_awareness_result(invalid) and not invalid_commit.has_awareness_result(), "Invalid formula profile cannot partially commit")


func _verify_one_shot_isolation_and_ui() -> void:
	var state := _launch_state(25, &"reckless_upstart", &"market_boom", false)
	var run := RunState.new()
	run.initialize_cash(4321)
	var review := state.get_review_result()
	var before := [state.get_marketing_output(), state.get_hidden_bugs(), state.get_known_bugs(), state.get_remaining_bugs(), state.get_current_cycle(), state.get_assigned_competitor_snapshot_id_for_authority(), state.get_assigned_market_forecast_snapshot_id_for_authority(), state.is_competitor_snapshot_revealed(), state.is_market_forecast_snapshot_revealed(), run.get_cash()]
	var result := PrimitiveAwarenessCalculator.calculate(state)
	_expect(state.commit_awareness_result(result), "ProjectState commits one immutable Awareness result")
	var database := PrimitiveSnapshotDatabase.new()
	database.load_ledgers()
	state.commit_launch_market_context_result(PrimitiveLaunchMarketContextCalculator.calculate(state, database))
	state.commit_units_sold_result(PrimitiveUnitsSoldCalculator.calculate(state))
	_expect(not state.commit_awareness_result(PrimitiveAwarenessCalculator.calculate(state)) and state.get_awareness_result() == result, "Repeated Awareness requests cannot apply Marketing twice or replace the result")
	_expect(state.get_review_result() == review and _equal(review.get_final_review(), 4.4), "Awareness commit preserves the exact rebalanced ReviewResult")
	_expect(before == [state.get_marketing_output(), state.get_hidden_bugs(), state.get_known_bugs(), state.get_remaining_bugs(), state.get_current_cycle(), state.get_assigned_competitor_snapshot_id_for_authority(), state.get_assigned_market_forecast_snapshot_id_for_authority(), state.is_competitor_snapshot_revealed(), state.is_market_forecast_snapshot_revealed(), run.get_cash()], "Awareness costs zero cycles/cash and preserves all frozen inputs and snapshots")
	var other := _launch_state(200, &"obsessive_polisher", &"market_crash", true)
	_expect(_equal(other.get_review_result().get_final_review(), review.get_final_review()), "Different Marketing and snapshot knowledge do not change Review")
	var launch := LAUNCH_SCENE.instantiate() as LaunchPhase
	root.add_child(launch)
	await process_frame
	_expect(launch.setup(state, run, database), "LaunchPhase reads committed Review, Awareness, and launch-context results")
	var visible := _visible_text(launch)
	_expect(visible.contains("Awareness: 125") and visible.contains("Launch Marketing: 25") and visible.contains("Review: 4.4") and visible.contains("Revenue and remaining release results pending"), "Launch UI displays Awareness, Marketing input, Review, and pending release status")
	_expect(not visible.contains("Hidden") and not visible.contains("Remaining Bugs") and not visible.contains("Reckless") and not visible.contains("Market Boom") and not visible.contains("$") and not visible.contains("Fans"), "Launch UI conceals Bugs, snapshots, cash revenue, and deferred fan results")
	var reconstructed := LAUNCH_SCENE.instantiate() as LaunchPhase
	root.add_child(reconstructed)
	await process_frame
	_expect(reconstructed.setup(state, run, database) and _visible_text(reconstructed) == visible and state.get_awareness_result() == result, "Launch reconstruction displays the same Awareness without recalculation")
	launch.queue_free()
	reconstructed.queue_free()
	await process_frame


func _visible_text(launch: LaunchPhase) -> String:
	var texts: Array[String] = []
	for child: Node in launch.get_node("Layout").get_children():
		if child is Label:
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
