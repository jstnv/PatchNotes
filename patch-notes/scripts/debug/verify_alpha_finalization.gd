## Focused Alpha completion/finalization verification.
## Run with: godot --headless --path . --script res://scripts/debug/verify_alpha_finalization.gd
extends SceneTree

const ALPHA_SCENE := preload("res://scenes/phases/alpha_phase.tscn")
const CARD_DATABASE_SCRIPT := preload("res://scripts/cards/card_database.gd")

var _failures := 0


func _initialize() -> void:
	var database := CARD_DATABASE_SCRIPT.new()
	database.name = "CardDatabase"
	root.add_child(database)
	await process_frame
	_verify_project_state_finalization_boundary()
	await _verify_planning_rejection()
	await _verify_scope_paths()
	await _verify_warning_cancel_and_pending_playtest()
	await _verify_conversion_math()
	await _verify_played_feature_history()
	await _verify_atomic_history_and_retirement(database)
	await _verify_failed_finalization_preserves_pending()
	_finish()


func _verify_project_state_finalization_boundary() -> void:
	var state := ProjectState.new(30)
	var emissions := [0]
	state.values_changed.connect(func() -> void: emissions[0] += 1)
	_expect(not state.finalize_alpha(1, [], []), "ProjectState rejects Alpha finalization before Design finalizes")
	_expect(not state.has_alpha_finalization() and state.get_hidden_bugs() == 0 and emissions[0] == 0, "Rejected pre-Design Alpha finalization stores and emits nothing")
	_expect(state.finalize_design_bugs(false, 5, [&"text"], [&"sprites"]), "ProjectState boundary fixture stores Design finalization")
	var before := _state_snapshot(state)
	var emissions_before: int = emissions[0]
	_expect(not state.finalize_alpha(-1, [&"controls"], [&"enemies"]), "ProjectState rejects negative Alpha Hidden Bugs")
	_expect(not state.finalize_alpha(1, [&"controls"], [&"controls"]), "ProjectState rejects overlapping Alpha Feature histories")
	_expect(_state_snapshot(state) == before and emissions[0] == emissions_before, "Invalid authoritative Alpha finalizations remain atomic")
	_expect(state.finalize_alpha(2, [&"controls"], [&"enemies"]), "ProjectState commits valid Alpha finalization atomically")
	var committed := _state_snapshot(state)
	_expect(state.get_hidden_bugs() == 7 and state.get_alpha_hidden_bugs_generated() == 2 and emissions[0] == emissions_before + 1, "ProjectState adds Alpha contribution to existing Design Bugs and emits once")
	_expect(not state.finalize_alpha(3, [], []) and _state_snapshot(state) == committed, "ProjectState one-shot boundary rejects double addition and history replacement")


func _verify_planning_rejection() -> void:
	var fixture := await _make_fixture(30, 0, 0.0, 4, false)
	var alpha: AlphaPhase = fixture.alpha
	var state: ProjectState = fixture.state
	var before := _state_snapshot(state)
	_expect(not alpha.request_proceed_to_beta(), "Planning rejects Proceed to Beta before Begin Alpha")
	_expect(_state_snapshot(state) == before and state.get_current_cycle() == 0, "Planning rejection changes no authoritative state and consumes no cycle")
	_expect((alpha.get_node("%ProceedToBetaButton") as Button).disabled, "Proceed to Beta is unavailable during Planning")
	alpha.queue_free()
	await process_frame


func _verify_scope_paths() -> void:
	for scope in [30, 32]:
		var fixture := await _make_fixture(30, scope, 0.0, 4, true)
		var alpha: AlphaPhase = fixture.alpha
		var state: ProjectState = fixture.state
		var cycles_before := state.get_current_cycle()
		_expect(alpha.request_proceed_to_beta(), "Scope %d / 30 finalizes immediately without warning" % scope)
		_expect(state.has_alpha_finalization() and alpha.get("_phase_state") == AlphaPhase.PhaseState.FINALIZED, "Scope %d finalizes Alpha exactly once" % scope)
		_expect(state.get_current_scope() == scope and state.get_required_scope() == 30, "Scope %d remains authoritative and unclamped" % scope)
		_expect(state.get_current_cycle() == cycles_before and not alpha.get_node("%UnderScopeDialog").visible, "Immediate Alpha finalization consumes zero cycles and opens no warning")
		alpha.queue_free()
		await process_frame


func _verify_warning_cancel_and_pending_playtest() -> void:
	var fixture := await _make_fixture(30, 24, 0.5, 6, true, true)
	var alpha: AlphaPhase = fixture.alpha
	var state: ProjectState = fixture.state
	var views := alpha.get_node("%HandContainer").get_children()
	(views[0] as CardView).card_pressed.emit(views[0])
	(views[1] as CardView).card_pressed.emit(views[1])
	alpha.set_priority(ProjectState.CoreScore.GRAPHICS, 40)
	_expect(alpha.host_playtest(), "Under-Scope fixture queues one Host Playtest before warning")
	var before := _complete_fixture_snapshot(alpha, state)
	var pending_before := alpha.get_pending_playtest_categories()
	_expect(not alpha.request_proceed_to_beta(), "First under-Scope Proceed activation warns instead of finalizing")
	var warning: ConfirmationDialog = alpha.get_node("%UnderScopeDialog")
	_expect(warning.visible and "24 / 30" in warning.dialog_text and "Scope shortfall: 6" in warning.dialog_text and "reduce the final review" in warning.dialog_text, "Under-Scope warning reports actual Scope, required Scope, exact shortfall, and review consequence")
	_expect(not alpha.request_proceed_to_beta(), "Repeated under-Scope activation does not create another warning callback")
	alpha.call("_on_under_scope_canceled")
	warning.hide()
	_expect(_complete_fixture_snapshot(alpha, state) == before and alpha.get_pending_playtest_categories() == pending_before, "Cancel preserves scores, Scope, pressure, Bugs, histories, pool, selection, priorities, lifecycle, pending Playtest, and cycles")

	_expect(not alpha.request_proceed_to_beta(), "Under-Scope Proceed can reopen one warning after cancellation")
	var cycles_before_confirm := state.get_current_cycle()
	alpha.call("_on_under_scope_confirmed")
	_expect(state.has_alpha_finalization() and state.get_current_scope() == 24 and state.get_required_scope() == 30, "Under-Scope confirmation finalizes while preserving actual and required Scope")
	_expect(state.get_current_cycle() == cycles_before_confirm, "Under-Scope confirmation consumes zero cycles and applies no review penalty")
	_expect(alpha.get_pending_playtest_categories().is_empty(), "Successful Alpha finalization discards pending corrective categories without injection or refund")
	alpha.queue_free()
	await process_frame


func _verify_conversion_math() -> void:
	var fixture := await _make_fixture(30, 0, 3.4, 7, true)
	var alpha: AlphaPhase = fixture.alpha
	var down: Dictionary = alpha.call("_calculate_alpha_finalization", 0.4, 0.5)
	var up: Dictionary = alpha.call("_calculate_alpha_finalization", 0.399999, 0.5)
	_expect(down.rounded == 3 and up.rounded == 4, "Controlled stochastic rounding produces floor at the fraction boundary and floor plus one below it")
	var boundary_cases := [
		[0.0, -2], [0.079999, -2], [0.08, -1], [0.249999, -1],
		[0.25, 0], [0.749999, 0], [0.75, 1], [0.919999, 1], [0.92, 2], [0.999999, 2],
	]
	for boundary in boundary_cases:
		_expect(alpha.call("_get_alpha_bug_variance", boundary[0]) == boundary[1], "Variance boundary %.6f maps to %+d" % boundary)
	alpha.queue_free()
	await process_frame
	var zero_fixture := await _make_fixture(30, 0, 0.0, 7, true)
	var zero_alpha: AlphaPhase = zero_fixture.alpha
	var clamped: Dictionary = zero_alpha.call("_calculate_alpha_finalization", 0.0, 0.0)
	_expect(clamped.rounded == 0 and clamped.variance == -2 and clamped.generated == 0, "Zero Alpha pressure clamps a negative intermediate contribution to zero")
	zero_alpha.queue_free()
	await process_frame


func _verify_played_feature_history() -> void:
	var fixture := await _make_fixture(30, 30, 0.0, 2, true)
	var alpha: AlphaPhase = fixture.alpha
	var state: ProjectState = fixture.state
	var views := alpha.get_node("%HandContainer").get_children()
	var played_ids: Array[StringName] = []
	for index in range(4):
		var view := views[index] as CardView
		_expect(view.card_data.card_type == &"feature", "History fixture selects an Alpha Feature through the live candidate pool")
		played_ids.append(view.card_data.id)
		view.card_pressed.emit(view)
	(alpha.get_node("%PlayAlphaHandButton") as Button).pressed.emit()
	var replacement_views := alpha.get_node("%HandContainer").get_children()
	var visible_unplayed_id := &""
	for node: Node in replacement_views:
		var view := node as CardView
		if view.card_data.card_type == &"feature":
			visible_unplayed_id = view.card_data.id
			view.card_pressed.emit(view)
			break
	_expect(not visible_unplayed_id.is_empty(), "History fixture leaves one dealt and selected Feature unplayed")
	_expect(alpha.call("_finalize_alpha", 0.999999, 0.5), "History fixture finalizes after one successful Alpha production action")
	var implemented := state.get_implemented_alpha_feature_ids()
	var unimplemented := state.get_unimplemented_alpha_feature_ids()
	_expect(played_ids.all(func(id: StringName) -> bool: return id in implemented), "Successfully played and exhausted Alpha Features persist as implemented stable IDs")
	_expect(visible_unplayed_id in unimplemented and visible_unplayed_id not in implemented, "Dealt and selected but unplayed Alpha Feature persists as unimplemented")
	_expect(implemented.size() + unimplemented.size() == 14, "Played-history finalization partitions all 14 authoritative Alpha Features exactly once")
	alpha.queue_free()
	await process_frame


func _verify_atomic_history_and_retirement(database: Node) -> void:
	var fixture := await _make_fixture(30, 30, 3.4, 7, true)
	var alpha: AlphaPhase = fixture.alpha
	var state: ProjectState = fixture.state
	var design_implemented := state.get_implemented_design_feature_ids()
	var design_unimplemented := state.get_unimplemented_design_feature_ids()
	var alpha_features: Array[CardData] = []
	alpha_features.assign(database.call(&"get_cards_by_phase_and_types", CardData.PHASE_ALPHA, [&"feature"] as Array[StringName]))
	var visible_ids: Array[StringName] = []
	for card: CardData in alpha.get("_candidate_cards"):
		visible_ids.append(card.id)
	var lifecycle_features := alpha_features.filter(func(card: CardData) -> bool: return card.id not in visible_ids)
	var implemented_ids: Array[StringName] = [lifecycle_features[0].id, lifecycle_features[1].id]
	implemented_ids.sort_custom(func(a: StringName, b: StringName) -> bool: return str(a) < str(b))
	var exhausted_ids: Dictionary = alpha.get("_exhausted_feature_ids")
	exhausted_ids[implemented_ids[0]] = true
	exhausted_ids[implemented_ids[1]] = true
	for card: CardData in lifecycle_features.slice(0, 2):
		alpha.get("_available_features").erase(card)
	var candidate_count_before: int = alpha.get("_candidate_cards").size()
	var cycles_before := state.get_current_cycle()
	var emissions := [0]
	var completions := [0]
	state.values_changed.connect(func() -> void: emissions[0] += 1)
	alpha.proceed_to_beta_requested.connect(func() -> void: completions[0] += 1)
	_expect(alpha.call("_finalize_alpha", 0.2, 0.8), "Controlled Alpha finalization commits successfully")
	_expect(state.get_alpha_hidden_bugs_generated() == 5 and state.get_hidden_bugs() == 12, "Alpha rounded Bugs plus one variance add to existing Design Hidden Bugs exactly once")
	_expect(state.get_implemented_alpha_feature_ids() == implemented_ids and state.get_unimplemented_alpha_feature_ids().size() == 12, "Alpha history stores exhausted Feature IDs and all other 12 authoritative Alpha Features as unimplemented")
	_expect(state.get_implemented_alpha_feature_ids().all(func(id: StringName) -> bool: return (database.call(&"get_card", id) as CardData).card_type == &"feature"), "Alpha history excludes Pass definitions")
	_expect(state.get_implemented_design_feature_ids() == design_implemented and state.get_unimplemented_design_feature_ids() == design_unimplemented, "Alpha finalization preserves Design Feature history unchanged")
	_expect(state.was_perfect_production() and state.get_accumulated_alpha_bug_pressure() == 3.4, "Design Perfect Production is neither reapplied nor allowed to modify fractional Alpha pressure")
	_expect(emissions[0] == 1 and completions[0] == 1 and state.get_current_cycle() == cycles_before, "Authoritative finalization emits once, requests one transition, and consumes zero cycles")
	_expect(alpha.get("_candidate_cards").size() == candidate_count_before and alpha.get_node("%HandContainer").get_child_count() == candidate_count_before, "Alpha retirement does not redraw, inject, exhaust, or replace the visible pool")
	_expect(alpha.get("_phase_state") == AlphaPhase.PhaseState.FINALIZED and (alpha.get_node("%PlayAlphaHandButton") as Button).disabled and (alpha.get_node("%HostPlaytestButton") as Button).disabled and (alpha.get_node("%ProceedToBetaButton") as Button).disabled, "Alpha retirement disables production, Playtest, and Proceed actions")
	var finalized_snapshot := _state_snapshot(state)
	_expect(not alpha.call("_finalize_alpha", 0.0, 0.99) and not alpha.request_proceed_to_beta(), "Repeated and stale Alpha finalization calls are rejected")
	_expect(_state_snapshot(state) == finalized_snapshot and emissions[0] == 1 and completions[0] == 1, "Repeated callbacks cannot reroll, double-add Bugs, replace history, or emit another transition")
	_expect(not alpha.set_priority(ProjectState.CoreScore.GRAPHICS, 50), "Retired Alpha priority controls reject mutation")
	var history_copy := state.get_implemented_alpha_feature_ids()
	history_copy.clear()
	_expect(state.get_implemented_alpha_feature_ids() == implemented_ids, "Alpha history getters return mutation-safe copies")
	alpha.queue_free()
	await process_frame


func _verify_failed_finalization_preserves_pending() -> void:
	var fixture := await _make_fixture(30, 30, 0.5, 3, true, true)
	var alpha: AlphaPhase = fixture.alpha
	var state: ProjectState = fixture.state
	_expect(alpha.host_playtest(), "Failure fixture queues a corrective Playtest")
	var pending := alpha.get_pending_playtest_categories()
	var before := _state_snapshot(state)
	var exhausted_ids: Dictionary = alpha.get("_exhausted_feature_ids")
	exhausted_ids[&"not_an_alpha_feature"] = true
	_expect(not alpha.call("_finalize_alpha", 0.0, 0.5), "Invalid Alpha Feature history rejects finalization")
	_expect(_state_snapshot(state) == before and alpha.get_pending_playtest_categories() == pending and alpha.get("_phase_state") == AlphaPhase.PhaseState.ACTIVE_DEVELOPMENT, "Failed finalization atomically preserves state, pending Playtest, lifecycle, and active phase")
	alpha.queue_free()
	await process_frame


func _make_fixture(required_scope: int, scope: int, alpha_pressure: float, design_bugs: int, active: bool, _begin_with_pool: bool = false) -> Dictionary:
	var state := ProjectState.new(required_scope)
	_expect(state.finalize_design_bugs(true, design_bugs, [&"text"] as Array[StringName], [&"sprites"] as Array[StringName]), "Fixture stores finalized Design state")
	if scope != 0 or alpha_pressure != 0.0:
		_expect(state.add_alpha_production({} as Dictionary[ProjectState.CoreScore, int], scope, alpha_pressure), "Fixture stores Alpha Scope and pressure")
	var alpha := ALPHA_SCENE.instantiate() as AlphaPhase
	root.add_child(alpha)
	alpha.setup(state)
	await process_frame
	if active:
		_expect(alpha.begin_alpha([0.05, 0.15, 0.25, 0.35, 0.45, 0.55, 0.65]), "Fixture begins Alpha through the public lifecycle")
	return {&"alpha": alpha, &"state": state}


func _complete_fixture_snapshot(alpha: AlphaPhase, state: ProjectState) -> Array:
	return [
		_state_snapshot(state),
		alpha.get("_candidate_cards").duplicate(),
		alpha.get_node("%HandContainer").get_children().map(func(node: Node) -> int: return node.get_instance_id()),
		alpha.get("_selected_card_views").duplicate(),
		alpha.get_priority_distribution(),
		alpha.get("_available_features").duplicate(),
		alpha.get("_exhausted_feature_ids").duplicate(),
		alpha.get("_phase_state"),
	]


func _state_snapshot(state: ProjectState) -> Array:
	return [
		state.get_core_score(ProjectState.CoreScore.GRAPHICS),
		state.get_core_score(ProjectState.CoreScore.SOUND),
		state.get_core_score(ProjectState.CoreScore.TECHNOLOGY),
		state.get_core_score(ProjectState.CoreScore.DESIGN),
		state.get_current_scope(), state.get_required_scope(),
		state.get_accumulated_bug_pressure(), state.get_accumulated_alpha_bug_pressure(),
		state.get_current_cycle(), state.was_perfect_production(), state.get_hidden_bugs(),
		state.get_known_bugs(), state.get_remaining_bugs(),
		state.has_alpha_finalization(), state.get_alpha_hidden_bugs_generated(),
		state.get_implemented_design_feature_ids(), state.get_unimplemented_design_feature_ids(),
		state.get_implemented_alpha_feature_ids(), state.get_unimplemented_alpha_feature_ids(),
	]


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
		return
	_failures += 1
	push_error("FAIL: %s" % description)


func _finish() -> void:
	if _failures == 0:
		print("Alpha finalization verification passed.")
	quit(_failures)
