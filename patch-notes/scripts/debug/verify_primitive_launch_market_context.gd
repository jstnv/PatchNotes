## Focused deterministic Primitive Launch Market Context verification.
extends SceneTree

const LAUNCH_SCENE := preload("res://scenes/phases/launch_phase.tscn")

var _database: PrimitiveSnapshotDatabase
var _failures := 0


func _initialize() -> void:
	await process_frame
	_database = PrimitiveSnapshotDatabase.new()
	_expect(_database.load_ledgers(), "Primitive snapshot ledgers load")
	_verify_forecast_and_competitor_rosters()
	_verify_timing_boundaries()
	_verify_atomicity_and_one_shot()
	await _verify_visibility_and_reconstruction()
	if _failures == 0:
		print("Primitive Launch Market Context verification passed.")
	quit(_failures)


func _launch_state(competitor_id: StringName, forecast_id: StringName, cycles: int, reveal_competitor: bool = false, reveal_forecast: bool = false) -> ProjectState:
	var state := ProjectState.new(30)
	state.initialize_snapshots(competitor_id, forecast_id)
	for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
		state.add_core_score(category, 20)
	state.add_scope(30)
	state.add_marketing_output(25)
	state.finalize_design_bugs(false, 2, [], [])
	state.finalize_alpha(0, [], [])
	if reveal_competitor:
		state.reveal_competitor_snapshot()
	if reveal_forecast:
		state.reveal_market_forecast_snapshot()
	for unused in range(cycles):
		state.advance_cycle()
	state.finalize_beta()
	state.commit_review_result(PrimitiveReviewCalculator.calculate(state, 50))
	state.commit_awareness_result(PrimitiveAwarenessCalculator.calculate(state))
	return state


func _verify_forecast_and_competitor_rosters() -> void:
	var forecasts := {&"market_crash": 7500, &"market_slump": 9000, &"stable_market": 10000, &"market_surge": 11500, &"market_boom": 13000}
	for id: StringName in forecasts:
		var state := _launch_state(&"fast_follower", id, 12)
		var result := PrimitiveLaunchMarketContextCalculator.calculate(state, _database)
		_expect(result != null and result.get_forecast_id_for_authority() == id and result.get_forecast_multiplier_basis_points() == forecasts[id], "%s resolves to exact authoritative basis points" % id)
		_expect(state.get_assigned_market_forecast_snapshot_id_for_authority() == id, "%s resolution never rerolls its snapshot" % id)
	var competitors := {&"reckless_upstart": 10, &"fast_follower": 12, &"established_rival": 16, &"obsessive_polisher": 20}
	for id: StringName in competitors:
		var result := PrimitiveLaunchMarketContextCalculator.calculate(_launch_state(id, &"stable_market", competitors[id]), _database)
		_expect(result != null and result.get_competitor_target_cycle() == competitors[id], "%s resolves to target cycle %d" % [id, competitors[id]])


func _verify_timing_boundaries() -> void:
	var before := PrimitiveLaunchMarketContextCalculator.calculate(_launch_state(&"fast_follower", &"market_surge", 11), _database)
	var on_target := PrimitiveLaunchMarketContextCalculator.calculate(_launch_state(&"fast_follower", &"market_surge", 12), _database)
	var after := PrimitiveLaunchMarketContextCalculator.calculate(_launch_state(&"fast_follower", &"market_surge", 13), _database)
	_expect(before.get_cycle_delta() == -1 and before.get_timing_relation() == LaunchMarketContextResult.TimingRelation.BEFORE_TARGET, "Cycle below target resolves negative BEFORE_TARGET context")
	_expect(on_target.get_cycle_delta() == 0 and on_target.get_timing_relation() == LaunchMarketContextResult.TimingRelation.ON_TARGET, "Cycle equal to target resolves ON_TARGET context")
	_expect(after.get_cycle_delta() == 1 and after.get_timing_relation() == LaunchMarketContextResult.TimingRelation.AFTER_TARGET, "Cycle above target resolves positive AFTER_TARGET context")
	_expect(not before.has_competitor_consequence() and not before.has_combined_release_modifier(), "Undefined competitor consequence creates neither neutral nor combined modifier")


func _verify_atomicity_and_one_shot() -> void:
	var unfinished := ProjectState.new(30)
	_expect(PrimitiveLaunchMarketContextCalculator.calculate(unfinished, _database) == null and not unfinished.has_launch_market_context_result(), "Missing finalization and launch results reject atomically")
	var unknown := _launch_state(&"fast_follower", &"market_surge", 7)
	unknown.set("_market_forecast_snapshot_id", &"unknown_forecast")
	_expect(PrimitiveLaunchMarketContextCalculator.calculate(unknown, _database) == null and not unknown.has_launch_market_context_result(), "Unknown snapshot ID rejects atomically")
	var partial := _launch_state(&"fast_follower", &"market_surge", 7)
	partial.set("_competitor_snapshot_id", StringName())
	_expect(PrimitiveLaunchMarketContextCalculator.calculate(partial, _database) == null and not partial.has_launch_market_context_result(), "Partial snapshot assignment rejects atomically")
	var state := _launch_state(&"established_rival", &"market_boom", 9)
	var review := state.get_review_result()
	var awareness := state.get_awareness_result()
	var before := [state.get_current_cycle(), state.get_marketing_output(), state.is_competitor_snapshot_revealed(), state.is_market_forecast_snapshot_revealed()]
	var result := PrimitiveLaunchMarketContextCalculator.calculate(state, _database)
	_expect(state.commit_launch_market_context_result(result), "Valid context commits exactly once")
	_expect(PrimitiveLaunchMarketContextCalculator.calculate(state, _database) == null and not state.commit_launch_market_context_result(result) and state.get_launch_market_context_result() == result, "Repeated resolution cannot replace the committed result")
	_expect(state.get_review_result() == review and state.get_awareness_result() == awareness and before == [state.get_current_cycle(), state.get_marketing_output(), state.is_competitor_snapshot_revealed(), state.is_market_forecast_snapshot_revealed()], "Resolution preserves Review, Awareness, Marketing, cycles, and reveal flags")


func _verify_visibility_and_reconstruction() -> void:
	var run := RunState.new()
	run.initialize_cash(4321)
	var concealed := _launch_state(&"reckless_upstart", &"market_boom", 8)
	concealed.commit_launch_market_context_result(PrimitiveLaunchMarketContextCalculator.calculate(concealed, _database))
	var concealed_launch := LAUNCH_SCENE.instantiate() as LaunchPhase
	root.add_child(concealed_launch)
	await process_frame
	_expect(concealed_launch.setup(concealed, run, _database), "LaunchPhase accepts a committed market context")
	var concealed_text := _visible_text(concealed_launch)
	_expect(not concealed_text.contains("Reckless") and not concealed_text.contains("Market Boom") and not concealed_text.contains("1.30") and not concealed_text.contains("Cycle 10"), "Concealed launch UI exposes no snapshot content")
	var revealed := _launch_state(&"fast_follower", &"market_surge", 14, true, true)
	revealed.commit_launch_market_context_result(PrimitiveLaunchMarketContextCalculator.calculate(revealed, _database))
	var revealed_launch := LAUNCH_SCENE.instantiate() as LaunchPhase
	root.add_child(revealed_launch)
	await process_frame
	_expect(revealed_launch.setup(revealed, run, _database), "Revealed launch context displays through immutable ledgers")
	var revealed_text := _visible_text(revealed_launch)
	_expect(revealed_text.contains("Market Surge") and revealed_text.contains("×1.15") and revealed_text.contains("Fast Follower") and revealed_text.contains("Cycle 12"), "Previously revealed facts display with exact market multiplier and rival target")
	_expect(revealed_text.contains("Review:") and revealed_text.contains("Awareness:") and revealed_text.contains("Sales and release results pending"), "Existing Review, Awareness, and pending-sales presentation remains")
	var reconstructed := LAUNCH_SCENE.instantiate() as LaunchPhase
	root.add_child(reconstructed)
	await process_frame
	_expect(reconstructed.setup(revealed, run, _database) and _visible_text(reconstructed) == revealed_text and revealed.get_launch_market_context_result() != null, "Launch reconstruction reuses the same committed context")
	_expect(run.get_cash() == 4321 and revealed.get_current_cycle() == 14, "Resolution and reconstruction consume zero cash and zero cycles")
	concealed_launch.queue_free()
	revealed_launch.queue_free()
	reconstructed.queue_free()
	await process_frame


func _visible_text(node: Node) -> String:
	var texts: Array[String] = []
	for child: Node in node.get_node("Layout").get_children():
		if child is Label and child.visible:
			texts.append((child as Label).text)
	return " | ".join(texts)


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		_failures += 1
		push_error("FAIL: %s" % description)
