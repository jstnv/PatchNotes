## Focused authoritative Beta QA-state verification.
## Run with: godot --headless --path . --script res://scripts/debug/verify_beta_qa_state.gd
extends SceneTree

const BETA_SCENE := preload("res://scenes/phases/beta_phase.tscn")

var _failures := 0


func _initialize() -> void:
	await _verify_beta_entry_and_zero_state()
	await _verify_discovery()
	await _verify_fixing()
	await _verify_full_lifecycle_and_invalid_inputs()
	await _verify_beta_persistence_and_concealment()
	_finish()


func _verify_beta_entry_and_zero_state() -> void:
	var state := _make_finalized_state(0, 0)
	var before := _state_snapshot(state)
	var beta := BETA_SCENE.instantiate() as BetaPhase
	root.add_child(beta)
	await process_frame
	_expect(beta.setup(state), "Beta accepts the exact authoritatively Alpha-finalized ProjectState")
	_expect(_state_snapshot(state) == before and state.get_current_cycle() == 0, "Loading Beta mutates no Bug state and consumes zero cycles")
	_expect(state.get_hidden_bugs() == 0 and state.get_known_bugs() == 0 and state.get_remaining_bugs() == 0, "Zero-Bug project enters Beta with zero Hidden, Known, and Remaining Bugs")
	_expect((beta.get_node("%KnownBugsLabel") as Label).text == "Known Bugs: 0", "Beta initially displays authoritative Known Bugs as zero")
	beta.queue_free()
	await process_frame

	var invalid_beta := BETA_SCENE.instantiate() as BetaPhase
	root.add_child(invalid_beta)
	await process_frame
	_expect(not invalid_beta.setup(ProjectState.new(30)), "Beta rejects a ProjectState that has not finalized Alpha")
	invalid_beta.queue_free()
	await process_frame


func _verify_discovery() -> void:
	var state := _make_finalized_state(6, 4)
	var emissions := [0]
	state.values_changed.connect(func() -> void: emissions[0] += 1)
	_expect(state.discover_bugs(3) == 3, "Partial discovery reports the actual three Bugs moved")
	_expect(state.get_hidden_bugs() == 7 and state.get_known_bugs() == 3 and state.get_remaining_bugs() == 10, "Partial discovery moves Hidden 10 to Hidden 7, Known 3, Remaining 10")
	_expect(emissions[0] == 1, "One successful nonzero discovery emits exactly once")

	var clamp_state := _make_finalized_state(2, 2)
	var clamp_emissions := [0]
	clamp_state.values_changed.connect(func() -> void: clamp_emissions[0] += 1)
	_expect(clamp_state.discover_bugs(99) == 4, "Discovery clamps and reports the four available Hidden Bugs")
	_expect(clamp_state.get_hidden_bugs() == 0 and clamp_state.get_known_bugs() == 4 and clamp_state.get_remaining_bugs() == 4, "Clamped discovery conserves all four Remaining Bugs")
	_expect(clamp_emissions[0] == 1, "Clamped nonzero discovery is one authoritative transaction")
	_expect(clamp_state.discover_bugs(1) == 0 and clamp_emissions[0] == 1, "Repeated discovery from zero Hidden Bugs is a signal-free no-op")


func _verify_fixing() -> void:
	var state := _make_finalized_state(4, 3)
	_expect(state.discover_bugs(5) == 5, "Fixing fixture discovers five Bugs")
	var emissions := [0]
	state.values_changed.connect(func() -> void: emissions[0] += 1)
	_expect(state.fix_known_bugs(2) == 2, "Partial fixing reports two Known Bugs removed")
	_expect(state.get_hidden_bugs() == 2 and state.get_known_bugs() == 3 and state.get_remaining_bugs() == 5, "Partial fixing leaves Hidden unchanged and reduces Remaining by two")
	_expect(emissions[0] == 1, "One successful nonzero fixing transaction emits exactly once")
	_expect(state.fix_known_bugs(99) == 3, "Fixing clamps and reports the three available Known Bugs")
	_expect(state.get_hidden_bugs() == 2 and state.get_known_bugs() == 0 and state.get_remaining_bugs() == 2, "Clamped fixing discards excess strength and protects Hidden Bugs")

	var hidden_only := _make_finalized_state(2, 2)
	var hidden_snapshot := _state_snapshot(hidden_only)
	var hidden_emissions := [0]
	hidden_only.values_changed.connect(func() -> void: hidden_emissions[0] += 1)
	_expect(hidden_only.fix_known_bugs(10) == 0, "Fixing with zero Known Bugs removes nothing")
	_expect(_state_snapshot(hidden_only) == hidden_snapshot and hidden_emissions[0] == 0, "Hidden-only Bugs are protected by a signal-free fixing no-op")


func _verify_full_lifecycle_and_invalid_inputs() -> void:
	var state := _make_finalized_state(5, 3)
	var remaining_before := state.get_remaining_bugs()
	_expect(state.discover_bugs(6) == 6, "Full lifecycle discovers six of eight Hidden Bugs")
	_expect(state.get_hidden_bugs() == 2 and state.get_known_bugs() == 6 and state.get_remaining_bugs() == remaining_before, "Discovery decreases Hidden exactly as Known increases and conserves Remaining")
	_expect(state.fix_known_bugs(4) == 4, "Full lifecycle fixes four Known Bugs")
	_expect(state.get_hidden_bugs() == 2 and state.get_known_bugs() == 2 and state.get_remaining_bugs() == remaining_before - 4, "Fixing reduces Remaining exactly by the actual fixed amount")

	var invalid_inputs: Array = [-1, "3", 3.0, 1.5, INF, NAN, null, true, []]
	var before := _state_snapshot(state)
	var emissions := [0]
	state.values_changed.connect(func() -> void: emissions[0] += 1)
	for invalid: Variant in invalid_inputs:
		_expect(state.discover_bugs(invalid) == -1, "Malformed discovery request is rejected: %s" % str(invalid))
		_expect(state.fix_known_bugs(invalid) == -1, "Malformed fixing request is rejected: %s" % str(invalid))
	_expect(_state_snapshot(state) == before and emissions[0] == 0, "All invalid requests are atomic and emit no misleading notification")
	_expect(state.discover_bugs(0) == 0 and state.fix_known_bugs(0) == 0, "Zero discovery and fixing requests are accepted no-ops")
	_expect(_state_snapshot(state) == before and emissions[0] == 0, "Zero requests mutate nothing and emit nothing")


func _verify_beta_persistence_and_concealment() -> void:
	var state := _make_finalized_state(7, 3)
	var beta := BETA_SCENE.instantiate() as BetaPhase
	root.add_child(beta)
	await process_frame
	_expect(beta.setup(state), "First Beta shell loads finalized QA state")
	var label := beta.get_node("%KnownBugsLabel") as Label
	_expect(state.discover_bugs(4) == 4 and label.text == "Known Bugs: 4", "Successful discovery refreshes the Beta Known Bug display synchronously")
	_expect(state.fix_known_bugs(1) == 1 and label.text == "Known Bugs: 3", "Successful fixing refreshes the Beta Known Bug display synchronously")
	var persistent_snapshot := _state_snapshot(state)
	beta.queue_free()
	await process_frame

	var reconstructed := BETA_SCENE.instantiate() as BetaPhase
	root.add_child(reconstructed)
	await process_frame
	_expect(reconstructed.setup(state), "Reconstructed Beta shell accepts the same finalized ProjectState")
	_expect(_state_snapshot(state) == persistent_snapshot and (reconstructed.get_node("%KnownBugsLabel") as Label).text == "Known Bugs: 3", "Beta reconstruction preserves Hidden and Known Bugs instead of resetting them")
	var visible_text := ""
	for node: Node in _descendants(reconstructed):
		if node is Label:
			visible_text += " " + (node as Label).text.to_lower()
	var concealed_terms := ["hidden", "remaining", "pressure", "generated", "total bugs"]
	_expect(concealed_terms.all(func(term: String) -> bool: return term not in visible_text), "Normal Beta UI conceals Hidden, Remaining, pressure, contribution, and generated totals")
	_expect("known bugs: 3" in visible_text and "beta phase" in visible_text, "Beta shell displays only its phase identity and authoritative Known Bugs")
	reconstructed.queue_free()
	await process_frame


func _make_finalized_state(design_hidden: int, alpha_hidden: int) -> ProjectState:
	var state := ProjectState.new(30)
	_expect(state.finalize_design_bugs(false, design_hidden, [&"text"], [&"sprites"]), "Fixture finalizes Design Hidden Bugs")
	_expect(state.finalize_alpha(alpha_hidden, [&"controls"], [&"enemies"]), "Fixture adds Alpha Hidden Bugs without rerolling Design")
	return state


func _state_snapshot(state: ProjectState) -> Array:
	return [
		state.get_hidden_bugs(), state.get_known_bugs(), state.get_remaining_bugs(),
		state.get_alpha_hidden_bugs_generated(), state.has_design_bug_finalization(), state.has_alpha_finalization(),
		state.get_current_cycle(), state.get_current_scope(), state.get_required_scope(),
		state.get_accumulated_bug_pressure(), state.get_accumulated_alpha_bug_pressure(),
		state.get_implemented_design_feature_ids(), state.get_unimplemented_design_feature_ids(),
		state.get_implemented_alpha_feature_ids(), state.get_unimplemented_alpha_feature_ids(),
	]


func _descendants(node: Node) -> Array[Node]:
	var result: Array[Node] = [node]
	for child: Node in node.get_children():
		result.append_array(_descendants(child))
	return result


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
		return
	_failures += 1
	push_error("FAIL: %s" % description)


func _finish() -> void:
	if _failures == 0:
		print("Beta QA state verification passed.")
	quit(_failures)
