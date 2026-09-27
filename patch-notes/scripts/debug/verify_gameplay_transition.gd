## Separately invoked Gameplay Design-to-Alpha transition verification.
## Run with: godot --headless --path . --script res://scripts/debug/verify_gameplay_transition.gd
extends SceneTree

const GAMEPLAY_SCENE := preload("res://scenes/gameplay.tscn")
const CARD_DATABASE_SCRIPT := preload("res://scripts/cards/card_database.gd")

var _failures := 0


func _initialize() -> void:
	var database := CARD_DATABASE_SCRIPT.new()
	database.name = "CardDatabase"
	root.add_child(database)
	await process_frame

	await _verify_successful_transition(database, 19, 0)
	await _verify_successful_transition(database, 30, 2)
	await _verify_successful_transition(database, 32, 4)
	await _verify_failed_instantiation()
	await _verify_alpha_to_beta_transition()
	await _verify_failed_beta_instantiation()
	_finish()


func _verify_successful_transition(database: Node, scope: int, selection_count: int) -> void:
	var gameplay := GAMEPLAY_SCENE.instantiate()
	gameplay.project_state = ProjectState.new(30) # Existing-project fixture; first-run setup is tested separately.
	root.add_child(gameplay)
	await process_frame
	await process_frame
	var phase_root := gameplay.get_node("%PhaseRoot")
	var design_phase := phase_root.get_child(0)
	_dismiss_initial_priority_menu(design_phase)
	_expect(design_phase is DesignPhase and phase_root.get_child_count() == 1, "Gameplay starts with Design as its only active phase")
	_expect(gameplay.get("_active_phase") == design_phase, "Gameplay tracks the startup Design phase")

	var additions: Dictionary[ProjectState.CoreScore, int] = {
		ProjectState.CoreScore.GRAPHICS: 4,
		ProjectState.CoreScore.SOUND: 4,
		ProjectState.CoreScore.TECHNOLOGY: 4,
		ProjectState.CoreScore.DESIGN: 4,
	}
	gameplay.project_state.add_core_scores_and_scope(additions, scope, 1.5)
	if selection_count > 0:
		_expect(design_phase.begin_design(), "Active-development transition fixture begins Design explicitly")
		await process_frame
	var views := design_phase.get_node("%HandContainer").get_children()
	for index in range(selection_count):
		(views[index] as CardView).input_button.pressed.emit()
	var selected_before: Array = design_phase.get("_selected_card_views").duplicate()
	var old_candidate: CardView = views[0] as CardView if not views.is_empty() else null
	var state_before := _state_snapshot(gameplay.project_state)
	var value_emissions := [0]
	var cycle_emissions := [0]
	gameplay.project_state.values_changed.connect(func() -> void: value_emissions[0] += 1)
	gameplay.project_state.cycle_changed.connect(func() -> void: cycle_emissions[0] += 1)

	(design_phase.get_node("%ProceedToAlphaButton") as Button).pressed.emit()
	var finalized_snapshot := _state_snapshot(gameplay.project_state)
	_expect(gameplay.project_state.has_design_bug_finalization(), "Gameplay transitions only after authoritative Design finalization")
	_expect(value_emissions[0] == 1 and cycle_emissions[0] == 0, "Finalization emits once and scene replacement emits no extra state or cycle signal")
	_expect(finalized_snapshot.slice(0, 9) == state_before.slice(0, 9), "Transition preserves scores, Scope, Required Scope, both Bug Pressures, and cycle")
	_expect(design_phase.get("_selected_card_views") == selected_before, "Proceed does not resolve selected cards before replacement")
	if selection_count == 0:
		_expect(views.is_empty() and gameplay.project_state.get_current_cycle() == 0, "Immediate Proceed from Planning deals no candidates and consumes zero cycles")
		_expect(gameplay.project_state.get_implemented_design_feature_ids().is_empty() and gameplay.project_state.get_unimplemented_design_feature_ids().size() == 13, "Immediate Planning finalization stores zero implemented and all Design Features unimplemented")

	_expect(phase_root.get_child_count() == 1 and phase_root.get_child(0) is AlphaPhase, "Alpha becomes the only active phase after Proceed")
	var alpha_phase := phase_root.get_child(0) as AlphaPhase
	_expect(gameplay.get("_active_phase") == alpha_phase and alpha_phase.get("_project_state") == gameplay.project_state, "Alpha receives Gameplay's existing ProjectState instance")
	_expect(alpha_phase.get_node("PhaseLayout/AlphaLabel").text == "Alpha Phase", "Alpha priority phase visibly identifies itself")
	_expect(alpha_phase.get_priority_distribution().values().reduce(func(total: int, value: int) -> int: return total + value, 0) == 100 and alpha_phase.get_available_priority() == 0, "Transitioned Alpha initializes its independent 25 / 25 / 25 / 25 allocation")
	_expect(alpha_phase.get_node("%GraphicsPriority") is VSlider and alpha_phase.get_node("%AvailablePriority").text == "Available Priority: 0", "Corrected Alpha allocation controls appear after the real transition")
	_expect(alpha_phase.get("_phase_state") == AlphaPhase.PhaseState.PLANNING and alpha_phase.get("_candidate_cards").is_empty(), "Transitioned Alpha begins in Planning with zero candidates")
	_expect(alpha_phase.get_node("%BeginAlphaButton").visible and alpha_phase.get_node("%PlayAlphaHandButton").disabled, "Transitioned Alpha exposes Begin Alpha and no resolution action")
	_expect(design_phase.get_parent() == null, "Finalized Design is removed from PhaseRoot")
	_expect(gameplay.project_state.get_implemented_design_feature_ids().size() + gameplay.project_state.get_unimplemented_design_feature_ids().size() == 13, "Finalized Design Feature history survives scene replacement")
	var history_copy: Array[StringName] = gameplay.project_state.get_unimplemented_design_feature_ids()
	history_copy.clear()
	_expect(gameplay.project_state.get_implemented_design_feature_ids().size() + gameplay.project_state.get_unimplemented_design_feature_ids().size() == 13, "Feature-history getters remain mutation-safe after transition")
	for id in gameplay.project_state.get_implemented_design_feature_ids() + gameplay.project_state.get_unimplemented_design_feature_ids():
		var card: CardData = database.call(&"get_card", id)
		_expect(card != null and card.phase == CardData.PHASE_DESIGN and card.card_type == &"feature", "Persisted transition history contains only Design Features")

	if old_candidate != null:
		old_candidate.card_pressed.emit(old_candidate)
	design_phase.proceed_to_alpha_requested.emit()
	_expect(_state_snapshot(gameplay.project_state) == finalized_snapshot and phase_root.get_child_count() == 1 and phase_root.get_child(0) == alpha_phase, "Stale Design inputs and signals cannot mutate state or create another Alpha")
	_expect(scope == gameplay.project_state.get_current_scope(), "Transition preserves requested Scope case exactly: %d" % scope)
	gameplay.queue_free()
	await process_frame


func _verify_failed_instantiation() -> void:
	var gameplay := GAMEPLAY_SCENE.instantiate()
	gameplay.project_state = ProjectState.new(30) # Existing-project fixture; first-run setup is tested separately.
	root.add_child(gameplay)
	await process_frame
	await process_frame
	var phase_root := gameplay.get_node("%PhaseRoot")
	var design_phase := phase_root.get_child(0)
	_dismiss_initial_priority_menu(design_phase)
	var transition_callable := Callable(gameplay, "_on_design_proceed_to_alpha_requested").bind(design_phase)
	design_phase.proceed_to_alpha_requested.disconnect(transition_callable)
	(design_phase.get_node("%ProceedToAlphaButton") as Button).pressed.emit()
	var finalized_snapshot := _state_snapshot(gameplay.project_state)
	var value_emissions := [0]
	var cycle_emissions := [0]
	gameplay.project_state.values_changed.connect(func() -> void: value_emissions[0] += 1)
	gameplay.project_state.cycle_changed.connect(func() -> void: cycle_emissions[0] += 1)
	var replaced: bool = gameplay.call("_replace_design_with_alpha", design_phase, PackedScene.new())
	_expect(not replaced and phase_root.get_child_count() == 1 and phase_root.get_child(0) == design_phase, "Failed Alpha instantiation keeps finalized Design under PhaseRoot")
	_expect(_state_snapshot(gameplay.project_state) == finalized_snapshot and value_emissions[0] == 0 and cycle_emissions[0] == 0, "Failed replacement mutates no ProjectState value or signal")
	gameplay.queue_free()
	await process_frame


func _verify_alpha_to_beta_transition() -> void:
	var gameplay := GAMEPLAY_SCENE.instantiate()
	gameplay.project_state = ProjectState.new(30) # Existing-project fixture; first-run setup is tested separately.
	root.add_child(gameplay)
	await process_frame
	await process_frame
	var phase_root := gameplay.get_node("%PhaseRoot")
	var design_phase := phase_root.get_child(0) as DesignPhase
	_dismiss_initial_priority_menu(design_phase)
	(design_phase.get_node("%ProceedToAlphaButton") as Button).pressed.emit()
	var alpha_phase := phase_root.get_child(0) as AlphaPhase
	alpha_phase.get_workspace().overlay.cancel()
	_expect(alpha_phase != null and alpha_phase.begin_alpha([0.05, 0.15, 0.25, 0.35, 0.45, 0.55, 0.65]), "Alpha-to-Beta fixture enters Active Alpha through Gameplay")
	gameplay.project_state.add_scope(30)
	var state_identity: ProjectState = gameplay.project_state
	var cycles_before: int = state_identity.get_current_cycle()
	var design_history_before := [state_identity.get_implemented_design_feature_ids(), state_identity.get_unimplemented_design_feature_ids()]
	_expect(alpha_phase.call("_finalize_alpha", 0.0, 0.5), "Alpha finalization requests the Gameplay Beta transition")
	alpha_phase.proceed_to_beta_requested.emit()
	_expect(phase_root.get_child_count() == 1 and phase_root.get_child(0) is BetaPhase, "Repeated Alpha completion signals cannot create duplicate Beta phases")
	await process_frame
	_expect(phase_root.get_child_count() == 1 and phase_root.get_child(0) is BetaPhase, "Gameplay replaces Alpha with the Beta placeholder as its only active phase")
	var beta_phase := phase_root.get_child(0) as BetaPhase
	_expect(gameplay.get("_active_phase") == beta_phase and beta_phase.get("_project_state") == state_identity and gameplay.project_state == state_identity, "Beta receives the exact existing ProjectState instance")
	_expect(state_identity.has_alpha_finalization() and state_identity.get_implemented_alpha_feature_ids().is_empty() and state_identity.get_unimplemented_alpha_feature_ids().size() == 14, "Finalized Alpha history survives scene replacement")
	_expect(state_identity.get_known_bugs() == 0 and state_identity.get_remaining_bugs() == state_identity.get_hidden_bugs(), "Beta entry preserves all unresolved Bugs as Hidden and initializes Known Bugs at zero")
	_expect([state_identity.get_implemented_design_feature_ids(), state_identity.get_unimplemented_design_feature_ids()] == design_history_before, "Design history survives the Alpha-to-Beta replacement unchanged")
	_expect(state_identity.get_current_cycle() == cycles_before, "Alpha finalization and Beta replacement consume zero cycles")
	_expect(beta_phase.get_node("PhaseLayout/BetaLabel").text == "Beta Phase" and beta_phase.get_node("%KnownBugsLabel").text == "Known Bugs: 0 | Fixed Bugs: 0", "Beta active shell displays public Bug counts without Hidden or Remaining Bug disclosure")
	gameplay.queue_free()
	await process_frame


func _verify_failed_beta_instantiation() -> void:
	var gameplay := GAMEPLAY_SCENE.instantiate()
	gameplay.project_state = ProjectState.new(30) # Existing-project fixture; first-run setup is tested separately.
	root.add_child(gameplay)
	await process_frame
	await process_frame
	var phase_root := gameplay.get_node("%PhaseRoot")
	var design_phase := phase_root.get_child(0) as DesignPhase
	_dismiss_initial_priority_menu(design_phase)
	(design_phase.get_node("%ProceedToAlphaButton") as Button).pressed.emit()
	var alpha_phase := phase_root.get_child(0) as AlphaPhase
	alpha_phase.get_workspace().overlay.cancel()
	alpha_phase.proceed_to_beta_requested.disconnect(Callable(gameplay, "_on_alpha_proceed_to_beta_requested").bind(alpha_phase))
	_expect(alpha_phase.begin_alpha([0.05, 0.15, 0.25, 0.35, 0.45, 0.55, 0.65]), "Failed-Beta fixture enters valid Active Alpha")
	_expect(alpha_phase.call("_finalize_alpha", 0.0, 0.5), "Failed-Beta fixture finalizes Alpha authoritatively")
	var finalized_snapshot := _state_snapshot(gameplay.project_state)
	var replaced: bool = gameplay.call("_replace_alpha_with_beta", alpha_phase, PackedScene.new())
	_expect(not replaced and phase_root.get_child_count() == 1 and phase_root.get_child(0) == alpha_phase, "Failed Beta instantiation keeps the finalized Alpha source under PhaseRoot")
	_expect(_state_snapshot(gameplay.project_state) == finalized_snapshot, "Failed Beta replacement cannot alter finalized ProjectState data")
	gameplay.queue_free()
	await process_frame


func _state_snapshot(project_state: ProjectState) -> Array:
	return [
		project_state.get_core_score(ProjectState.CoreScore.GRAPHICS),
		project_state.get_core_score(ProjectState.CoreScore.SOUND),
		project_state.get_core_score(ProjectState.CoreScore.TECHNOLOGY),
		project_state.get_core_score(ProjectState.CoreScore.DESIGN),
		project_state.get_current_scope(),
		project_state.get_required_scope(),
		project_state.get_accumulated_bug_pressure(),
		project_state.get_accumulated_alpha_bug_pressure(),
		project_state.get_current_cycle(),
		project_state.was_perfect_production(),
		project_state.get_hidden_bugs(),
		project_state.get_known_bugs(),
		project_state.get_remaining_bugs(),
		project_state.get_implemented_design_feature_ids(),
		project_state.get_unimplemented_design_feature_ids(),
		project_state.has_alpha_finalization(),
		project_state.get_alpha_hidden_bugs_generated(),
		project_state.get_implemented_alpha_feature_ids(),
		project_state.get_unimplemented_alpha_feature_ids(),
	]


func _dismiss_initial_priority_menu(design_phase: DesignPhase) -> void:
	if design_phase != null and design_phase.get_workspace().overlay.visible:
		design_phase.get_workspace().overlay.cancel()


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
		return
	_failures += 1
	push_error("FAIL: %s" % description)


func _finish() -> void:
	if _failures == 0:
		print("Gameplay transition verification passed.")
	quit(_failures)
