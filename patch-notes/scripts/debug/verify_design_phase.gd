## Separately invoked Design Phase verification.
## Run with: godot --headless --path . --script res://scripts/debug/verify_design_phase.gd
extends SceneTree

const GAMEPLAY_SCENE := preload("res://scenes/gameplay.tscn")
const ALPHA_PHASE_SCENE := preload("res://scenes/phases/alpha_phase.tscn")
const CARD_DATABASE_SCRIPT := preload("res://scripts/cards/card_database.gd")
const FLOAT_TOLERANCE := 0.000001
const PASS_IDS: Array[StringName] = [&"graphics_pass", &"sound_pass", &"technology_pass", &"design_pass"]
const EXPECTED_PASS_STATS := {
	&"graphics_pass": &"graphics",
	&"sound_pass": &"sound",
	&"technology_pass": &"technology",
	&"design_pass": &"design",
}

var _failures := 0


func _initialize() -> void:
	var database := CARD_DATABASE_SCRIPT.new()
	database.name = "CardDatabase"
	root.add_child(database)
	await process_frame

	_verify_ledger(database)
	_verify_project_state_bug_pressure_transactions()
	_verify_project_state_design_finalization()
	var gameplay := GAMEPLAY_SCENE.instantiate()
	gameplay.project_state = ProjectState.new(30) # Existing-project fixture; first-run setup is tested separately.
	root.add_child(gameplay)
	await process_frame
	await process_frame
	var design_phase := gameplay.get_node("%PhaseRoot").get_child(0)
	var gameplay_transition := Callable(gameplay, "_on_design_proceed_to_alpha_requested").bind(design_phase)
	if design_phase.proceed_to_alpha_requested.is_connected(gameplay_transition):
		design_phase.proceed_to_alpha_requested.disconnect(gameplay_transition)
	_verify_initial_state(design_phase, gameplay.project_state)
	await _verify_design_priorities(design_phase, gameplay.project_state, database)
	_verify_bug_pressure_display_formatting(design_phase)
	_verify_selection(design_phase, gameplay.project_state)
	_verify_pool_compositions(design_phase, gameplay.project_state, database)
	_verify_bug_pressure_calculation(design_phase, database)
	_verify_specialization_calculation(design_phase)
	_verify_balanced_production(design_phase)
	_verify_specialized_success(design_phase)
	_verify_balanced_success(design_phase)
	_verify_balanced_pass_success(design_phase, database)
	_verify_two_action_bug_pressure_accumulation(design_phase, database)
	var failed_state := _reset_project_state(design_phase)
	_verify_atomic_failure(design_phase, failed_state, database)
	var base_state := _reset_project_state(design_phase)
	_verify_atomic_success(design_phase, base_state, database)
	_verify_post_hand_deal_failure(design_phase, base_state, database)
	_verify_pass_only_hand(design_phase, base_state, database)
	_verify_perfect_production_and_hidden_bugs(design_phase)
	_verify_feature_history_finalization(design_phase, database)
	_verify_design_finalization(design_phase, database)
	_finish()


func _verify_ledger(database: Node) -> void:
	_expect(database.call(&"get_card_count") == 40, "Exactly 40 definitions load after the nine-card Primitive Beta expansion")
	var design_cards: Array = database.call(&"get_cards_by_phase", CardData.PHASE_DESIGN)
	var alpha_cards: Array = database.call(&"get_cards_by_phase", CardData.PHASE_ALPHA)
	var beta_cards: Array = database.call(&"get_cards_by_phase", CardData.PHASE_BETA)
	_expect(design_cards.size() == 17, "Design eligibility contains 17 definitions")
	_expect(alpha_cards.size() == 14, "Alpha eligibility remains 14 definitions")
	_expect(beta_cards.size() == 9, "Beta eligibility contains only the nine Primitive Beta definitions")
	var all_ids: Array[StringName] = []
	for card: CardData in database.call(&"get_all_cards"):
		all_ids.append(card.id)
	_expect(not all_ids.has(&"gameplay_pass"), "No generic gameplay_pass definition remains")
	var passes: Array = database.call(&"get_cards_by_phase_and_types", CardData.PHASE_DESIGN, [&"pass"] as Array[StringName])
	_expect(passes.size() == 4, "Exactly four Design Pass definitions exist")
	for pass_id in PASS_IDS:
		var card: CardData = database.call(&"get_card", pass_id)
		_expect(card != null, "Pass definition exists: %s" % pass_id)
		if card == null:
			continue
		_expect(card.card_type == &"pass" and card.phase == CardData.PHASE_DESIGN, "%s is a Design Pass" % pass_id)
		_expect(card.primary_stat == EXPECTED_PASS_STATS[pass_id] and card.primary_value == 2, "%s has its matching Core Score +2" % pass_id)
		_expect(card.secondary_stat.is_empty() and card.secondary_value == 0, "%s has no secondary effect" % pass_id)
		_expect(card.scope == 0 and card.department.is_empty() and card.renewable, "%s is renewable with 0 Scope and no department" % pass_id)
	var feature_count := 0
	for card: CardData in design_cards:
		if card.card_type == &"feature":
			feature_count += 1
	_expect(feature_count == 13, "All 13 Design Features remain present")


func _verify_initial_state(design_phase: Node, project_state: ProjectState) -> void:
	_expect(design_phase.get("_project_state") == project_state, "DesignPhase receives Gameplay's ProjectState instance")
	_expect(_values(project_state) == [0, 0, 0, 0, 0], "Initialization changes no project values")
	_expect(project_state.get_current_cycle() == 0, "Initialization changes no cycles")
	_expect(_approximately_equal(project_state.get_accumulated_bug_pressure(), 0.0), "Bug Pressure initializes to 0.0 through its public getter")
	_expect(design_phase.get_node("%BugPressureValue").text == "Bug Pressure: 0.00", "Initial Bug Pressure display reads 0.00")
	_expect(design_phase.get("_phase_state") == DesignPhase.PhaseState.PLANNING, "Fresh Design begins in Planning")
	_expect(design_phase.get("_candidate_cards").is_empty(), "Planning deals no candidates")
	_expect(design_phase.get_node("%HandContainer").get_child_count() == 0, "Planning creates no CardViews")
	_expect(design_phase.get_node("%BeginDesignButton").visible and not design_phase.get_node("%BeginDesignButton").disabled, "Begin Design is visible and available in Planning")
	_expect(design_phase.get_node("%PlayCardButton").text == "Implement", "Play control names the complete hand action")
	_expect(design_phase.get_node("%PlayCardButton").disabled, "Play Hand is disabled in Planning")
	_expect(design_phase.get_node("%ProceedToAlphaButton").text == "Proceed to Alpha" and not design_phase.get_node("%ProceedToAlphaButton").disabled, "Proceed to Alpha is visible and initially interactable")
	_expect(not design_phase.get_node("PhaseLayout/ProjectStatDisplay").is_visible_in_tree(), "Old phase stat row is superseded by the persistent shell header")


func _verify_design_priorities(design_phase: DesignPhase, project_state: ProjectState, database: Node) -> void:
	if design_phase.get_workspace().overlay.visible:
		design_phase.get_workspace().overlay.cancel()
	var categories: Array[ProjectState.CoreScore] = [
		ProjectState.CoreScore.GRAPHICS,
		ProjectState.CoreScore.SOUND,
		ProjectState.CoreScore.TECHNOLOGY,
		ProjectState.CoreScore.DESIGN,
	]
	var state_before := _project_state_snapshot(project_state)
	var candidates_before: Array = design_phase.get("_candidate_cards").duplicate()
	var project_value_emissions := [0]
	var project_cycle_emissions := [0]
	var priority_emissions := [0]
	project_state.values_changed.connect(func() -> void: project_value_emissions[0] += 1)
	project_state.cycle_changed.connect(func() -> void: project_cycle_emissions[0] += 1)
	design_phase.priorities_changed.connect(func() -> void: priority_emissions[0] += 1)

	_expect(_priority_values(design_phase) == [25, 25, 25, 25], "Design priorities initialize at 25 / 25 / 25 / 25")
	_verify_priority_controls(design_phase, categories)
	(design_phase.get_node("%SoundPriority") as VSlider).value = 15.0
	_expect(_priority_values(design_phase) == [25, 15, 25, 25] and design_phase.get_available_priority() == 10, "Lowering Sound changes only Sound and frees ten priority")
	_expect(priority_emissions[0] == 1, "One Design slider adjustment emits priorities_changed exactly once")
	var comparison_alpha := ALPHA_PHASE_SCENE.instantiate() as AlphaPhase
	comparison_alpha.setup(project_state)
	root.add_child(comparison_alpha)
	await process_frame
	_expect(comparison_alpha.set_priority(ProjectState.CoreScore.SOUND, 15), "Alpha accepts the same comparison request")
	_expect(design_phase.get_priority_distribution() == comparison_alpha.get_priority_distribution(), "Design and Alpha share identical allocation mathematics")
	comparison_alpha.queue_free()
	await process_frame
	_expect(design_phase.set_priority(ProjectState.CoreScore.GRAPHICS, 35), "Design can spend available priority")
	_expect(_priority_values(design_phase) == [35, 15, 25, 25] and design_phase.get_available_priority() == 0, "Raising Graphics changes only Graphics and consumes available priority")
	_expect(design_phase.set_priority(ProjectState.CoreScore.GRAPHICS, 50), "Over-budget increase is handled safely")
	_expect(_priority_values(design_phase) == [35, 15, 25, 25], "Over-budget increase clamps to the highest fitting value without redistribution")
	_expect(design_phase.set_priority(ProjectState.CoreScore.TECHNOLOGY, -10), "Below-range numeric request clamps safely")
	_expect(_priority_values(design_phase) == [35, 15, 5, 25] and design_phase.get_available_priority() == 20, "Below-range request clamps to 5 and changes no other category")
	_expect(design_phase.set_priority(ProjectState.CoreScore.DESIGN, 27.5), "Numeric non-step request normalizes safely")
	_expect(design_phase.get_priority(ProjectState.CoreScore.DESIGN) == 30, "Exact half-step snaps upward to 30")
	_verify_priority_distribution(design_phase, categories, "Design allocations preserve bounds, steps, and budget")

	var before_rejected := design_phase.get_priority_distribution()
	var emissions_before_rejected: int = priority_emissions[0]
	_expect(not design_phase.set_priority(999, 25), "Design rejects an invalid Core category")
	_expect(not design_phase.set_priority(ProjectState.CoreScore.GRAPHICS, &"invalid"), "Design rejects a malformed priority value")
	_expect(design_phase.get_priority_distribution() == before_rejected, "Rejected Design requests do not mutate priorities")
	_expect(priority_emissions[0] == emissions_before_rejected, "Rejected Design requests emit nothing")
	var graphics_before_noop := design_phase.get_priority(ProjectState.CoreScore.GRAPHICS)
	_expect(design_phase.set_priority(ProjectState.CoreScore.GRAPHICS, graphics_before_noop), "Design accepts a no-op request")
	_expect(priority_emissions[0] == emissions_before_rejected, "Design no-op emits nothing")
	var returned_distribution := design_phase.get_priority_distribution()
	returned_distribution[ProjectState.CoreScore.GRAPHICS] = 5
	_expect(design_phase.get_priority(ProjectState.CoreScore.GRAPHICS) == graphics_before_noop, "Design distribution getter returns a defensive copy")

	for index in range(32):
		var category := categories[index % categories.size()]
		var requested := 5 + ((index * 13) % 46)
		_expect(design_phase.set_priority(category, requested), "Repeated Design priority adjustment %d succeeds" % index)
		_verify_priority_distribution(design_phase, categories, "Repeated Design adjustment %d preserves invariants" % index)
		_verify_priority_control_values(design_phase)

	_expect(design_phase.get("_candidate_cards") == candidates_before, "Priority changes do not reroll or alter visible Design candidates")
	_expect(_project_state_snapshot(project_state) == state_before, "Priority changes preserve every authoritative project value")
	_expect(project_value_emissions[0] == 0 and project_cycle_emissions[0] == 0, "Priority changes emit no ProjectState signal and advance no cycle")
	_verify_weighted_dealing(design_phase, project_state, database)
	# The shared priority-commit milestone locks phase activation to an exact
	# 100-point distribution. Restore a valid planning allocation after the
	# normalization fuzz coverage above.
	_expect(design_phase.set_priority_distribution({
		ProjectState.CoreScore.GRAPHICS: 25,
		ProjectState.CoreScore.SOUND: 25,
		ProjectState.CoreScore.TECHNOLOGY: 25,
		ProjectState.CoreScore.DESIGN: 25,
	}), "Design planning distribution restores 25 / 25 / 25 / 25 before Begin")
	var priorities_before_begin := design_phase.get_priority_distribution()
	_expect(design_phase.begin_design(), "Begin Design succeeds once from Planning")
	await process_frame
	_expect(not design_phase.begin_design(), "Begin Design is idempotent")
	_expect(design_phase.get("_phase_state") == DesignPhase.PhaseState.ACTIVE_DEVELOPMENT, "Begin Design enters Active Development")
	_expect(design_phase.get_priority_distribution() == priorities_before_begin, "Begin Design preserves the current allocation")
	_expect(design_phase.get("_candidate_cards").size() == 7 and design_phase.get_node("%HandContainer").get_child_count() == 7, "Begin Design deals exactly seven candidates")
	_verify_weighted_candidate_pool(design_phase, "First priority-weighted Design pool")
	_expect(project_value_emissions[0] == 0 and project_cycle_emissions[0] == 0 and _project_state_snapshot(project_state) == state_before, "Begin Design is cycle-free and mutates no ProjectState value")
	_expect(not design_phase.get_node("%BeginDesignButton").visible, "Begin Design retires after activation")
	var active_candidates: Array = design_phase.get("_candidate_cards").duplicate()
	var play_state_before: bool = design_phase.get_node("%PlayCardButton").disabled
	design_phase.set_priority(ProjectState.CoreScore.SOUND, 5)
	_expect(design_phase.get("_candidate_cards") == active_candidates, "Active priority changes preserve candidate identity and order")
	_expect(design_phase.get_node("%PlayCardButton").disabled == play_state_before, "Active priority changes preserve Play-button state")
	var views := design_phase.get_node("%HandContainer").get_children()
	(views[0] as CardView).input_button.pressed.emit()
	var selected_during_adjustment: Array = design_phase.get("_selected_card_views").duplicate()
	var selected_play_state: bool = design_phase.get_node("%PlayCardButton").disabled
	design_phase.set_priority(ProjectState.CoreScore.DESIGN, 5)
	_expect(design_phase.get("_selected_card_views") == selected_during_adjustment and design_phase.get_node("%PlayCardButton").disabled == selected_play_state, "Active priority changes preserve selected candidates and Play state")
	(views[0] as CardView).input_button.pressed.emit()
	for index in range(views.size()):
		_expect((views[index] as CardView).size == Vector2(240, 336), "Active candidate %d retains 240x336 bounds" % (index + 1))
	var candidate_scroll := design_phase.get_node("Workspace/Regions/CandidateScroll") as ScrollContainer
	_expect(design_phase.get_node("%HandContainer") is CardFan and candidate_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "Seven-card pool uses the shared fan without horizontal scrolling")
	_expect(design_phase.get_node("%ProceedToAlphaButton").visible and design_phase.get_node("%PlayCardButton").visible, "Active Play Hand and Proceed controls remain accessible")


func _verify_weighted_dealing(design_phase: DesignPhase, project_state: ProjectState, database: Node) -> void:
	var design_features: Array[CardData] = []
	design_features.assign(database.call(&"get_cards_by_phase_and_types", CardData.PHASE_DESIGN, [&"feature"] as Array[StringName]))
	var passes: Array[CardData] = []
	passes.assign(database.call(&"get_cards_by_phase_and_types", CardData.PHASE_DESIGN, [&"pass"] as Array[StringName]))
	design_phase.set("_available_features", design_features.duplicate())
	design_phase.set("_pass_definitions", passes.duplicate())
	design_phase.set("_exhausted_card_ids", {})
	var snapshot: Dictionary[ProjectState.CoreScore, int] = {
		ProjectState.CoreScore.GRAPHICS: 15,
		ProjectState.CoreScore.SOUND: 20,
		ProjectState.CoreScore.TECHNOLOGY: 40,
		ProjectState.CoreScore.DESIGN: 25,
	}
	var sprites: CardData = database.call(&"get_card", &"sprites")
	var split_screen: CardData = database.call(&"get_card", &"split_screen")
	var sound_pass: CardData = database.call(&"get_card", &"sound_pass")
	_expect(design_phase.call("_calculate_candidate_weight", sprites, snapshot) == 105.0, "Feature weight uses printed primary value and matching priority only")
	_expect(design_phase.call("_calculate_candidate_weight", split_screen, snapshot) == 285.0, "Dual-score Feature weight includes printed primary and secondary contributions")
	_expect(design_phase.call("_calculate_candidate_weight", sound_pass, snapshot) == float(snapshot[ProjectState.CoreScore.SOUND] * sound_pass.primary_value), "Pass weight uses its matching priority and printed definition value")
	var weight_fixture := CardData.new()
	weight_fixture.primary_stat = sprites.primary_stat
	weight_fixture.primary_value = sprites.primary_value
	weight_fixture.secondary_stat = sprites.secondary_stat
	weight_fixture.secondary_value = sprites.secondary_value
	weight_fixture.scope = 999
	weight_fixture.department = &"ignored_department"
	_expect(design_phase.call("_calculate_candidate_weight", weight_fixture, snapshot) == design_phase.call("_calculate_candidate_weight", sprites, snapshot), "Scope and department do not contribute to candidate weight")
	var dominant_sound_snapshot := snapshot.duplicate()
	dominant_sound_snapshot[ProjectState.CoreScore.SOUND] = 50
	_expect(design_phase.call("_calculate_candidate_weight", sound_pass, dominant_sound_snapshot) > design_phase.call("_calculate_candidate_weight", sound_pass, snapshot), "Dominant Sound priority increases the matching Sound Pass weight")

	var boundary_entries: Array[Dictionary] = [
		{&"card": passes[0], &"weight": 10.0},
		{&"card": passes[1], &"weight": 20.0},
		{&"card": passes[2], &"weight": 30.0},
		{&"card": passes[3], &"weight": 40.0},
	]
	for index in range(boundary_entries.size()):
		var prior_weight := 0.0
		for prior_index in range(index):
			prior_weight += boundary_entries[prior_index].weight
		var midpoint_roll: float = (prior_weight + float(boundary_entries[index].weight) * 0.5) / 100.0
		_expect(design_phase.call("_select_weighted_entry", boundary_entries, midpoint_roll) == boundary_entries[index].card, "Controlled roll selects weighted interval %d" % index)
	_expect(design_phase.call("_select_weighted_entry", boundary_entries, 0.10) == boundary_entries[1].card, "Exact cumulative boundary selects the following half-open interval")
	_expect(design_phase.call("_select_weighted_entry", boundary_entries, NAN) == null, "Nonfinite roll cannot select an entry")
	var invalid_entries: Array[Dictionary] = [{&"card": passes[0], &"weight": INF}]
	_expect(design_phase.call("_select_weighted_entry", invalid_entries, 0.0) == null, "Nonfinite weight cannot select an entry")

	var controlled_rolls: Array[float] = [0.0, 0.17, 0.34, 0.51, 0.68, 0.85, 0.99]
	var first_build: Dictionary = design_phase.call("_build_weighted_candidate_definitions", snapshot, controlled_rolls)
	_expect(first_build.valid and first_build.cards.size() == 7, "Controlled weighted builder produces seven definitions")
	var feature_ids: Dictionary[StringName, bool] = {}
	var feature_unique := true
	for card: CardData in first_build.cards:
		if card.card_type == &"feature":
			feature_unique = feature_unique and not feature_ids.has(card.id)
			feature_ids[card.id] = true
		_expect(card.phase == CardData.PHASE_DESIGN and card.card_type in [&"feature", &"pass"], "Weighted pool contains only eligible Design definitions")
	_expect(feature_unique, "Feature definitions are selected without replacement within one pool")
	var reversed_features := design_features.duplicate()
	reversed_features.reverse()
	var reversed_passes := passes.duplicate()
	reversed_passes.reverse()
	design_phase.set("_available_features", reversed_features)
	design_phase.set("_pass_definitions", reversed_passes)
	var reordered_build: Dictionary = design_phase.call("_build_weighted_candidate_definitions", snapshot, controlled_rolls)
	_expect(reordered_build.valid and _card_ids(reordered_build.cards) == _card_ids(first_build.cards), "Stable lexical ID ordering makes controlled deals independent of database iteration order")
	design_phase.set("_available_features", design_features.duplicate())
	design_phase.set("_pass_definitions", passes.duplicate())
	var saved_snapshot := snapshot.duplicate()
	design_phase.set_priority(ProjectState.CoreScore.GRAPHICS, 5)
	var repeated_build: Dictionary = design_phase.call("_build_weighted_candidate_definitions", saved_snapshot, controlled_rolls)
	_expect(repeated_build.valid and _card_ids(repeated_build.cards) == _card_ids(first_build.cards), "A deal-time priority snapshot remains immutable across slider changes")

	design_phase.set("_available_features", [] as Array[CardData])
	design_phase.set("_pass_definitions", passes.duplicate())
	var state_before_pass_deal := _project_state_snapshot(project_state)
	_expect(design_phase.call("_deal_next_candidate_pool", [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0] as Array[float]), "All-Pass controlled deal succeeds with Features exhausted")
	_expect(design_phase.get("_candidate_cards").size() == 7 and design_phase.get("_candidate_cards").all(func(card: CardData) -> bool: return card.card_type == &"pass"), "No-Feature state produces seven renewable Pass instances")
	var pass_views := design_phase.get_node("%HandContainer").get_children()
	var view_ids: Dictionary[int, bool] = {}
	for view: CardView in pass_views:
		view_ids[view.get_instance_id()] = true
	_expect(view_ids.size() == 7 and design_phase.get("_candidate_cards")[0] == design_phase.get("_candidate_cards")[1], "Duplicate Pass definitions create seven distinct selectable CardViews")
	_expect(_project_state_snapshot(project_state) == state_before_pass_deal, "Weighted dealing itself mutates no ProjectState value")
	design_phase.call("_clear_candidate_pool")

	var malformed := CardData.new()
	malformed.id = &"malformed_weight_fixture"
	malformed.phase = CardData.PHASE_DESIGN
	malformed.card_type = &"feature"
	malformed.primary_stat = &"invalid"
	malformed.primary_value = 1
	design_phase.set("_available_features", [malformed] as Array[CardData])
	design_phase.set("_pass_definitions", passes.duplicate())
	var before_failed_deal := _project_state_snapshot(project_state)
	_expect(not design_phase.call("_deal_next_candidate_pool", controlled_rolls), "Invalid weighted input rejects the complete deal")
	_expect(design_phase.get("_candidate_cards").is_empty() and design_phase.get_node("%HandContainer").get_child_count() == 0, "Invalid weighted input creates no partial candidate pool")
	_expect(_project_state_snapshot(project_state) == before_failed_deal, "Failed weighted deal mutates no ProjectState value")
	design_phase.set("_available_features", [] as Array[CardData])
	design_phase.set("_pass_definitions", [] as Array[CardData])
	design_phase.set("_exhausted_card_ids", {})


func _verify_weighted_candidate_pool(design_phase: DesignPhase, description: String) -> void:
	var candidates: Array = design_phase.get("_candidate_cards")
	var feature_ids: Dictionary[StringName, bool] = {}
	var valid := candidates.size() == 7
	for card: CardData in candidates:
		valid = valid and card.phase == CardData.PHASE_DESIGN and card.card_type in [&"feature", &"pass"]
		if card.card_type == &"feature":
			valid = valid and not feature_ids.has(card.id)
			feature_ids[card.id] = true
	_expect(valid, "%s contains seven valid definitions with unique Features" % description)


func _card_ids(cards: Array) -> Array[StringName]:
	var ids: Array[StringName] = []
	for card: CardData in cards:
		ids.append(card.id)
	return ids


func _verify_priority_controls(phase: DesignPhase, categories: Array[ProjectState.CoreScore]) -> void:
	for node_name: StringName in [&"GraphicsPriority", &"SoundPriority", &"TechnologyPriority", &"DesignPriority"]:
		var slider := phase.get_node("%%%s" % node_name) as VSlider
		_expect(slider != null and slider.min_value == 5.0 and slider.max_value == 50.0 and slider.step == 5.0, "%s uses 5-50 bounds in five-point steps" % node_name)
	var priority_panel := phase.get_node("PriorityOverlay/ModalBlocker/PriorityDialog/Content/PriorityPanel") as PanelContainer
	var priority_columns := phase.get_node("PriorityOverlay/ModalBlocker/PriorityDialog/Content/PriorityPanel/PriorityLayout").get_children()
	_expect(priority_panel.size.x <= 1008.0 and priority_panel.size.y >= 72.0, "Compact Design priority panel fits the established phase width")
	_expect(priority_columns.size() == 4 and not priority_panel.is_visible_in_tree(), "Four vertical priority controls remain inside the closed modal")
	_expect(not phase.get_node("PhaseLayout").visible, "Legacy horizontal HUD is not exposed")
	_verify_priority_distribution(phase, categories, "Initial Design priority allocation uses the complete budget")
	_verify_priority_control_values(phase)


func _verify_priority_distribution(phase: DesignPhase, categories: Array[ProjectState.CoreScore], description: String) -> void:
	var distribution := phase.get_priority_distribution()
	var total := 0
	var valid_values := distribution.size() == categories.size()
	for category: ProjectState.CoreScore in categories:
		var value: int = distribution.get(category, 0)
		total += value
		valid_values = valid_values and value >= 5 and value <= 50 and value % 5 == 0
	_expect(total <= 100 and phase.get_available_priority() == 100 - total and valid_values, description)


func _verify_priority_control_values(phase: DesignPhase) -> void:
	var values := _priority_values(phase)
	var sliders := [phase.get_node("%GraphicsPriority"), phase.get_node("%SoundPriority"), phase.get_node("%TechnologyPriority"), phase.get_node("%DesignPriority")]
	var labels := [phase.get_node("%GraphicsPriorityValue"), phase.get_node("%SoundPriorityValue"), phase.get_node("%TechnologyPriorityValue"), phase.get_node("%DesignPriorityValue")]
	for index in range(values.size()):
		_expect(int(sliders[index].value) == values[index] and labels[index].text == str(values[index]), "Design priority slider and label %d match internal state" % index)
	_expect(phase.get_node("%DesignAvailablePriority").text == "Available Priority: %d" % phase.get_available_priority(), "Design available-priority display derives from allocation state")


func _priority_values(phase: Node) -> Array[int]:
	return [
		phase.get_priority(ProjectState.CoreScore.GRAPHICS),
		phase.get_priority(ProjectState.CoreScore.SOUND),
		phase.get_priority(ProjectState.CoreScore.TECHNOLOGY),
		phase.get_priority(ProjectState.CoreScore.DESIGN),
	]


func _project_state_snapshot(project_state: ProjectState) -> Array:
	return [
		project_state.get_core_score(ProjectState.CoreScore.GRAPHICS),
		project_state.get_core_score(ProjectState.CoreScore.SOUND),
		project_state.get_core_score(ProjectState.CoreScore.TECHNOLOGY),
		project_state.get_core_score(ProjectState.CoreScore.DESIGN),
		project_state.get_current_scope(),
		project_state.get_required_scope(),
		project_state.get_accumulated_bug_pressure(),
		project_state.get_current_cycle(),
		project_state.was_perfect_production(),
		project_state.get_hidden_bugs(),
		project_state.get_implemented_design_feature_ids(),
		project_state.get_unimplemented_design_feature_ids(),
	]


func _verify_project_state_bug_pressure_transactions() -> void:
	var graphics := ProjectState.CoreScore.GRAPHICS
	var additions: Dictionary[ProjectState.CoreScore, int] = {graphics: 1}
	var project_state := ProjectState.new(30)
	var emissions := [0]
	project_state.values_changed.connect(func() -> void: emissions[0] += 1)
	_expect(project_state.add_core_scores_and_scope(additions, 1), "Existing score-and-Scope batch caller remains compatible")
	_expect(_values(project_state) == [1, 0, 0, 0, 1] and _approximately_equal(project_state.get_accumulated_bug_pressure(), 0.0), "Compatible batch call leaves Bug Pressure at 0.0")
	_expect(emissions[0] == 1, "Compatible batch call retains one-signal behavior")

	for invalid_pressure: float in [-1.0, NAN, INF, -INF]:
		var before := _values(project_state)
		var pressure_before := project_state.get_accumulated_bug_pressure()
		var emissions_before: int = emissions[0]
		_expect(not project_state.add_core_scores_and_scope(additions, 1, invalid_pressure), "Invalid Bug Pressure transaction is rejected: %s" % invalid_pressure)
		_expect(_values(project_state) == before and _approximately_equal(project_state.get_accumulated_bug_pressure(), pressure_before) and emissions[0] == emissions_before, "Rejected Bug Pressure transaction is fully atomic")

	var overflow_state := ProjectState.new(30)
	var maximum_finite := 1.7976931348623157e308
	_expect(overflow_state.add_core_scores_and_scope({}, 0, maximum_finite), "A finite Bug Pressure transaction can reach a finite accumulated value")
	var overflow_emissions := [0]
	overflow_state.values_changed.connect(func() -> void: overflow_emissions[0] += 1)
	_expect(not overflow_state.add_core_scores_and_scope(additions, 1, maximum_finite), "Transaction producing nonfinite accumulated Bug Pressure is rejected")
	_expect(_values(overflow_state) == [0, 0, 0, 0, 0] and overflow_state.get_accumulated_bug_pressure() == maximum_finite and overflow_emissions[0] == 0, "Overflow rejection mutates no scores, Scope, Bug Pressure, or signals")
	_expect(_approximately_equal(ProjectState.new(30).get_accumulated_bug_pressure(), 0.0), "A fresh project-state reset restores Bug Pressure to 0.0")


func _verify_project_state_design_finalization() -> void:
	var fresh := ProjectState.new(30)
	_expect(not fresh.has_design_bug_finalization() and not fresh.was_perfect_production() and fresh.get_hidden_bugs() == 0, "Fresh ProjectState is distinguishably unfinalized with safe Design Bug defaults")
	_expect(fresh.get_implemented_design_feature_ids().is_empty() and fresh.get_unimplemented_design_feature_ids().is_empty(), "Fresh ProjectState Design Feature history begins empty")
	var emissions := [0]
	fresh.values_changed.connect(func() -> void: emissions[0] += 1)
	_expect(fresh.finalize_design_bugs(true, 0, [&"text"], [&"sprites"]), "A zero-Hidden-Bug Perfect result and Feature history store successfully")
	_expect(fresh.has_design_bug_finalization() and fresh.was_perfect_production() and fresh.get_hidden_bugs() == 0, "Finalized zero Hidden Bugs is distinguishable from unfinalized state")
	_expect(emissions[0] == 1, "Design Bug finalization emits one authoritative values_changed signal")
	var implemented_copy := fresh.get_implemented_design_feature_ids()
	implemented_copy.append(&"external_mutation")
	var unimplemented_copy := fresh.get_unimplemented_design_feature_ids()
	unimplemented_copy.clear()
	_expect(fresh.get_implemented_design_feature_ids() == [&"text"] and fresh.get_unimplemented_design_feature_ids() == [&"sprites"], "Feature-history getters return defensive copies")
	_expect(not fresh.finalize_design_bugs(false, 7, [], []), "Repeated Design Bug finalization is rejected")
	_expect(fresh.was_perfect_production() and fresh.get_hidden_bugs() == 0 and emissions[0] == 1, "Repeated finalization neither overwrites nor emits again")
	for invalid_result in [[1, 2], [true, -1], [true, 1.5]]:
		var invalid_state := ProjectState.new(30)
		var invalid_emissions := [0]
		invalid_state.values_changed.connect(func() -> void: invalid_emissions[0] += 1)
		_expect(not invalid_state.finalize_design_bugs(invalid_result[0], invalid_result[1], [], []), "Invalid Design finalization input is rejected")
		_expect(not invalid_state.has_design_bug_finalization() and invalid_state.get_hidden_bugs() == 0 and invalid_emissions[0] == 0, "Invalid Design finalization stores nothing and emits nothing")
	var invalid_histories := [
		[[&"text", &"text"], []],
		[[&"text"], [&"text"]],
		[[&""], []],
		[[1], []],
		["not_an_array", []],
	]
	for invalid_history in invalid_histories:
		var invalid_state := ProjectState.new(30)
		_expect(not invalid_state.finalize_design_bugs(true, 4, invalid_history[0], invalid_history[1]), "Structurally invalid Feature history rejects complete finalization")
		_expect(not invalid_state.has_design_bug_finalization() and not invalid_state.was_perfect_production() and invalid_state.get_hidden_bugs() == 0 and invalid_state.get_implemented_design_feature_ids().is_empty() and invalid_state.get_unimplemented_design_feature_ids().is_empty(), "Invalid history stores no Perfect, Hidden Bug, or Feature-history result")


func _verify_bug_pressure_display_formatting(design_phase: Node) -> void:
	var original_project_state: ProjectState = design_phase.get("_project_state")
	var cases := [
		[3.0 / 18.0, "Bug Pressure: 0.17"],
		[14.0 / 18.0, "Bug Pressure: 0.78"],
		[1.5, "Bug Pressure: 1.50"],
		[2.4444, "Bug Pressure: 2.44"],
	]
	for test_case in cases:
		var project_state := ProjectState.new(30)
		project_state.add_core_scores_and_scope({}, 0, test_case[0])
		design_phase.call("setup", project_state)
		_expect(design_phase.get_node("%BugPressureValue").text == test_case[1], "Bug Pressure display formats %.6f as %s" % [test_case[0], test_case[1]])
		_expect(_approximately_equal(project_state.get_accumulated_bug_pressure(), test_case[0]), "Display formatting does not alter authoritative Bug Pressure")
	design_phase.call("setup", original_project_state)


func _verify_selection(design_phase: Node, project_state: ProjectState) -> void:
	var views := design_phase.get_node("%HandContainer").get_children()
	var play_button := design_phase.get_node("%PlayCardButton") as Button
	var cycle_before := project_state.get_current_cycle()
	for index in range(4):
		(views[index] as CardView).input_button.pressed.emit()
		_expect(design_phase.get("_selected_card_views").size() == index + 1, "Candidate %d selects independently" % (index + 1))
		_expect(play_button.disabled == (index < 3), "Play state is correct with %d selections" % (index + 1))
	_expect(_selected_view_count(design_phase) == 4, "Four selection outlines are visible")
	(views[4] as CardView).input_button.pressed.emit()
	_expect(design_phase.get("_selected_card_views").size() == 4 and _selected_view_count(design_phase) == 4, "A fifth selection preserves the original four")
	(views[1] as CardView).input_button.pressed.emit()
	_expect(design_phase.get("_selected_card_views").size() == 3 and play_button.disabled, "A selected candidate can be deselected")
	(views[1] as CardView).input_button.pressed.emit()
	_expect(design_phase.get("_selected_card_views").size() == 4 and not play_button.disabled, "A deselected candidate can be reselected")
	_expect(project_state.get_current_cycle() == cycle_before, "Selection, deselection, and fifth attempt consume no time")
	design_phase.call("_clear_selection")


func _verify_pool_compositions(design_phase: Node, project_state: ProjectState, database: Node) -> void:
	var features := _cards(database, [&"text", &"sprites", &"4_color_palette", &"8_bit_sound", &"8_bit_music", &"keyboard_and_mouse", &"controller"])
	_set_pool(design_phase, features)
	_verify_weighted_candidate_pool(design_phase, "Seven-Feature availability")
	_set_pool(design_phase, features.slice(0, 5))
	_expect(_candidate_type_count(design_phase, &"feature") <= 5 and _candidate_type_count(design_phase, &"pass") >= 2, "Five available Features still produce seven candidates through renewable Pass entries")
	_set_pool(design_phase, features.slice(0, 3))
	_expect(_candidate_type_count(design_phase, &"feature") <= 3 and _candidate_type_count(design_phase, &"pass") >= 4, "Three available Features still produce seven candidates through renewable Pass entries")
	_set_pool(design_phase, [])
	_verify_candidate_pool(design_phase, 0, 7, "No Features")
	var pass_views := design_phase.get_node("%HandContainer").get_children()
	(pass_views[0] as CardView).set_card(database.call(&"get_card", &"graphics_pass"))
	(pass_views[1] as CardView).set_card(database.call(&"get_card", &"graphics_pass"))
	design_phase.get("_candidate_cards")[0] = (pass_views[0] as CardView).card_data
	design_phase.get("_candidate_cards")[1] = (pass_views[1] as CardView).card_data
	_expect(pass_views[0] != pass_views[1] and (pass_views[0] as CardView).card_data == (pass_views[1] as CardView).card_data, "Duplicate Pass definitions use distinct runtime CardView instances")
	_expect(project_state.get_current_cycle() == 0, "Controlled dealing consumes no time")


func _candidate_type_count(design_phase: Node, card_type: StringName) -> int:
	var count := 0
	for card: CardData in design_phase.get("_candidate_cards"):
		if card.card_type == card_type:
			count += 1
	return count


func _verify_specialization_calculation(design_phase: Node) -> void:
	for specialization_stat: StringName in [&"graphics", &"sound", &"technology", &"design"]:
		var category_cards: Array[CardData] = []
		for index in range(4):
			category_cards.append(_make_fixture(
				StringName("%s_specialization_%d" % [specialization_stat, index]),
				specialization_stat,
				2,
				&"",
				0,
				0,
			))
		var category_result := _calculate_hand(design_phase, category_cards)
		var category: ProjectState.CoreScore = DesignPhase.CORE_SCORE_BY_STAT[specialization_stat]
		_expect(category_result.specialization_stat == specialization_stat and category_result.score_additions[category] == 12, "Four matching cards trigger exactly one %s Specialization" % specialization_stat.capitalize())

	var graphics_cards: Array[CardData] = [
		_make_fixture(&"graphics_2", &"graphics", 2, &"technology", 2, 1),
		_make_fixture(&"graphics_3", &"graphics", 3, &"sound", 3, 2),
		_make_fixture(&"graphics_5", &"graphics", 5, &"design", 5, 3),
		_make_fixture(&"graphics_7", &"graphics", 7, &"technology", 7, 4),
	]
	var specialized := _calculate_hand(design_phase, graphics_cards)
	_expect(specialized.valid and specialized.specialization_stat == &"graphics", "Four matching primary stats trigger exactly one Graphics Specialization")
	_expect(specialized.base_hand.score_additions[ProjectState.CoreScore.GRAPHICS] == 17, "Validated base aggregate preserves unmodified primary production")
	_expect(specialized.base_hand.score_additions[ProjectState.CoreScore.TECHNOLOGY] == 9 and specialized.base_hand.score_additions[ProjectState.CoreScore.SOUND] == 3 and specialized.base_hand.score_additions[ProjectState.CoreScore.DESIGN] == 5, "Validated base aggregate includes every unmodified secondary contribution")
	_expect(specialized.base_hand.scope == 10 and specialized.base_hand.has_feature, "Validated base result reports printed Scope and Feature presence")
	_expect(specialized.base_hand.cards.size() == 4 and specialized.base_hand.contributions.size() == 4, "Validated base result retains four cards and per-card contribution detail")
	_expect(specialized.score_additions[ProjectState.CoreScore.GRAPHICS] == 26, "Specialization aggregates primary production before multiplying 17 by 1.50 and nearest-rounding to 26")
	_expect(specialized.score_additions[ProjectState.CoreScore.TECHNOLOGY] == 14 and specialized.score_additions[ProjectState.CoreScore.SOUND] == 5 and specialized.score_additions[ProjectState.CoreScore.DESIGN] == 8, "Differing valid secondary stats aggregate by Core Score before the Specialization multiplier and nearest rounding")
	_expect(specialized.scope == 10, "Specialization leaves Scope as the exact unmodified sum")
	_expect(design_phase.call("_build_specialization_debug_message", specialized.specialization_stat, specialized.score_additions) == "Specialization hit: Graphics Specialization! Added scores: Graphics +26, Sound +5, Technology +14, Design +8", "Specialization debug output identifies the hit and final added scores")

	var rounding_discriminator: Array[CardData] = [
		_make_fixture(&"aggregate_1_a", &"graphics", 1, &"", 0, 0),
		_make_fixture(&"aggregate_1_b", &"graphics", 1, &"", 0, 0),
		_make_fixture(&"aggregate_1_c", &"graphics", 1, &"", 0, 0),
		_make_fixture(&"aggregate_2", &"graphics", 2, &"", 0, 0),
	]
	var discriminator_result := _calculate_hand(design_phase, rounding_discriminator)
	_expect(discriminator_result.base_hand.score_additions[ProjectState.CoreScore.GRAPHICS] == 5 and discriminator_result.score_additions[ProjectState.CoreScore.GRAPHICS] == 8, "Specialization nearest-rounds aggregate 5 x 1.50 to 8 rather than ceiling-rounding per card to 9")

	var reversed_cards := graphics_cards.duplicate()
	reversed_cards.reverse()
	var reversed := _calculate_hand(design_phase, reversed_cards)
	_expect(reversed.specialization_stat == specialized.specialization_stat and reversed.score_additions == specialized.score_additions and reversed.scope == specialized.scope, "Selection order does not change Specialization or its result")

	var sound_card := _make_fixture(&"sound_fixture", &"sound", 2, &"technology", 2, 0)
	var three_one: Array[CardData] = [graphics_cards[0], graphics_cards[1], graphics_cards[2], sound_card]
	_expect(_calculate_hand(design_phase, three_one).specialization_stat.is_empty(), "A 3-1 primary-stat split does not trigger")
	var two_two: Array[CardData] = [graphics_cards[0], graphics_cards[1], sound_card, _make_fixture(&"sound_fixture_2", &"sound", 3, &"technology", 3, 0)]
	_expect(_calculate_hand(design_phase, two_two).specialization_stat.is_empty(), "A 2-2 primary-stat split does not trigger")
	var two_one_one: Array[CardData] = [graphics_cards[0], graphics_cards[1], sound_card, _make_fixture(&"technology_fixture", &"technology", 3, &"design", 3, 0)]
	_expect(_calculate_hand(design_phase, two_one_one).specialization_stat.is_empty(), "A 2-1-1 primary-stat split does not trigger")

	var matching_secondaries: Array[CardData] = [
		_make_fixture(&"mixed_graphics", &"graphics", 2, &"design", 2, 0),
		_make_fixture(&"mixed_sound", &"sound", 2, &"design", 2, 0),
		_make_fixture(&"mixed_technology", &"technology", 2, &"design", 2, 0),
		_make_fixture(&"mixed_design", &"design", 2, &"design", 2, 0),
	]
	var secondary_only := _calculate_hand(design_phase, matching_secondaries)
	_expect(secondary_only.specialization_stat.is_empty(), "Matching secondary stats alone do not trigger Specialization")
	_expect(secondary_only.score_additions[ProjectState.CoreScore.DESIGN] == 10, "Nonspecialized mixed hand resolves unmodified primary and secondary scores")
	_expect(secondary_only.score_additions == secondary_only.base_hand.score_additions, "Nonspecialized final production exactly equals base production")

	var project_state: ProjectState = design_phase.get("_project_state")
	var values_before := _values(project_state)
	var cycle_before := project_state.get_current_cycle()
	var candidates_before: Array = design_phase.get("_candidate_cards").duplicate()
	var selections_before: Array = design_phase.get("_selected_card_views").duplicate()
	var exhausted_before: Dictionary = design_phase.get("_exhausted_card_ids").duplicate()
	var emissions := [0]
	project_state.values_changed.connect(func() -> void: emissions[0] += 1)
	var recalculated_base: Dictionary = design_phase.call("_validate_and_calculate_base_action")
	_expect(recalculated_base.valid, "Controlled selected hand can calculate validated base production independently")
	_expect(_values(project_state) == values_before and project_state.get_current_cycle() == cycle_before and emissions[0] == 0, "Base calculation does not mutate ProjectState or emit state signals")
	_expect(design_phase.get("_candidate_cards") == candidates_before and design_phase.get("_selected_card_views") == selections_before and design_phase.get("_exhausted_card_ids") == exhausted_before, "Base calculation does not mutate candidates, selections, or lifecycle")


func _verify_bug_pressure_calculation(design_phase: Node, database: Node) -> void:
	var text: CardData = database.call(&"get_card", &"text")
	var sprites: CardData = database.call(&"get_card", &"sprites")
	var split_screen: CardData = database.call(&"get_card", &"split_screen")
	_expect(_approximately_equal(design_phase.call("_calculate_feature_bug_pressure", text), 3.0 / 18.0), "Text contributes fractional printed Bug Pressure of 3/18")
	_expect(_approximately_equal(design_phase.call("_calculate_feature_bug_pressure", sprites), 14.0 / 18.0), "Sprites contributes fractional printed Bug Pressure of 14/18")
	_expect(_approximately_equal(design_phase.call("_calculate_feature_bug_pressure", split_screen), 1.5), "Split Screen includes printed primary and valid secondary values for 1.5 Bug Pressure")
	var cards: Array[CardData] = [text, sprites, split_screen, database.call(&"get_card", &"graphics_pass")]
	var result := _calculate_hand(design_phase, cards)
	_expect(_approximately_equal(result.base_hand.bug_pressure, (3.0 / 18.0) + (14.0 / 18.0) + 1.5), "Multiple Features sum fractional Bug Pressure without per-Feature rounding while Passes add 0.0")


func _verify_specialized_success(design_phase: Node) -> void:
	var project_state := _reset_project_state(design_phase)
	var cards: Array[CardData] = [
		_make_fixture(&"specialized_2", &"graphics", 2, &"technology", 2, 1),
		_make_fixture(&"specialized_3", &"graphics", 3, &"sound", 3, 2),
		_make_fixture(&"specialized_5", &"graphics", 5, &"design", 5, 3),
		_make_fixture(&"specialized_7", &"graphics", 7, &"technology", 7, 4),
	]
	_set_exact_candidates(design_phase, cards)
	_select_first(design_phase, 4)
	var emissions := [0]
	project_state.values_changed.connect(func() -> void: emissions[0] += 1)
	(design_phase.get_node("%PlayCardButton") as Button).pressed.emit()
	design_phase.get_workspace().hand_motion.cancel() # Timing is covered by verify_card_motion; this suite checks transactions.
	_expect(_values(project_state) == [26, 5, 14, 8, 10], "Specialized hand commits its aggregate-then-nearest-rounded production")
	_expect(_approximately_equal(project_state.get_accumulated_bug_pressure(), 102.0 / 18.0), "Specialization accumulates Bug Pressure from printed values without its production multiplier")
	_expect(emissions[0] == 1, "Specialized hand emits values_changed exactly once")
	_expect(project_state.get_current_cycle() == 1, "Specialization adds no extra cycles")
	_expect(design_phase.get_workspace().synergy_notification.banner.visible and design_phase.get_workspace().synergy_notification.title_label.text == "Graphics Specialization!", "Successful Design specialization displays an in-game notification")
	for card in cards:
		_expect(design_phase.get("_exhausted_card_ids").has(card.id), "Successful specialized Feature exhausts once: %s" % card.id)


func _verify_balanced_production(design_phase: Node) -> void:
	var graphics := ProjectState.CoreScore.GRAPHICS
	var sound := ProjectState.CoreScore.SOUND
	var technology := ProjectState.CoreScore.TECHNOLOGY
	var design := ProjectState.CoreScore.DESIGN
	_expect(design_phase.call("_are_core_scores_balanced", {graphics: 8, sound: 10, technology: 10, design: 12}), "Inclusive lower and upper Balanced boundaries qualify")
	_expect(not design_phase.call("_are_core_scores_balanced", {graphics: 8, sound: 11, technology: 11, design: 11}), "A score just below the lower Balanced boundary fails")
	_expect(not design_phase.call("_are_core_scores_balanced", {graphics: 9, sound: 9, technology: 9, design: 12}), "A score just above the upper Balanced boundary fails")
	_expect(design_phase.call("_are_core_scores_balanced", {graphics: 8, sound: 8, technology: 8, design: 9}), "Balanced mean uses fractional division without integer truncation")

	var project_state := _reset_project_state(design_phase)
	var current: Dictionary[ProjectState.CoreScore, int] = {graphics: 3, sound: 3, technology: 5, design: 6}
	project_state.add_core_scores_and_scope(current, 0)
	var cards: Array[CardData] = [
		_make_fixture(&"balanced_graphics", &"graphics", 2, &"sound", 1, 1),
		_make_fixture(&"balanced_sound", &"sound", 4, &"graphics", 3, 1),
		_make_fixture(&"balanced_technology", &"technology", 3, &"", 0, 1),
		_make_fixture(&"balanced_design", &"design", 2, &"", 0, 1),
	]
	var values_before := _values(project_state)
	var result := _calculate_hand(design_phase, cards)
	_expect(result.base_hand.score_additions == {graphics: 5, sound: 5, technology: 3, design: 2}, "Balanced base aggregate includes secondary contributions normally")
	_expect(result.provisional_scores == {graphics: 8, sound: 8, technology: 8, design: 8}, "Provisional scores equal cumulative scores plus unmodified base production")
	_expect(_values(project_state) == values_before, "Provisional and synergy calculation does not mutate ProjectState or Scope")
	_expect(result.balanced_production and result.score_additions == {graphics: 6, sound: 6, technology: 4, design: 2}, "Balanced example aggregates per Core Score, multiplies by 1.20, and rounds to nearest integer")
	_expect(result.scope == 4, "Balanced Production leaves printed Scope unmodified")

	var reversed := cards.duplicate()
	reversed.reverse()
	var reversed_result := _calculate_hand(design_phase, reversed)
	_expect(reversed_result.balanced_production and reversed_result.score_additions == result.score_additions, "Selection order does not affect Balanced eligibility or production")

	var pass_card := _make_fixture(&"balanced_pass", &"sound", 4, &"graphics", 3, 0)
	pass_card.card_type = &"pass"
	pass_card.renewable = true
	var pass_assisted: Array[CardData] = [cards[0], pass_card, cards[2], cards[3]]
	_expect(_calculate_hand(design_phase, pass_assisted).balanced_production, "A Pass-assisted action with a Feature can trigger Balanced Production")
	for card in pass_assisted:
		card.card_type = &"pass"
		card.renewable = true
	_expect(not _calculate_hand(design_phase, pass_assisted).balanced_production, "A Pass-only action cannot trigger Balanced Production even when totals are balanced")

	var nonqualifying: Array[CardData] = [
		_make_fixture(&"unbalanced_graphics", &"graphics", 5, &"", 0, 0),
		_make_fixture(&"unbalanced_sound", &"sound", 1, &"", 0, 0),
		_make_fixture(&"unbalanced_technology", &"technology", 1, &"", 0, 0),
		_make_fixture(&"unbalanced_design", &"design", 1, &"", 0, 99),
	]
	var nonqualifying_result := _calculate_hand(design_phase, nonqualifying)
	_expect(not nonqualifying_result.balanced_production and nonqualifying_result.score_additions == nonqualifying_result.base_hand.score_additions, "A nonqualifying mixed hand uses unmodified base production regardless of Scope")

	project_state = _reset_project_state(design_phase)
	var balancing_current: Dictionary[ProjectState.CoreScore, int] = {graphics: 0, sound: 14, technology: 8, design: 12}
	project_state.add_core_scores_and_scope(balancing_current, 0)
	var specialized_cards: Array[CardData] = [
		_make_fixture(&"both_2", &"graphics", 2, &"technology", 2, 0),
		_make_fixture(&"both_3", &"graphics", 3, &"sound", 3, 0),
		_make_fixture(&"both_5", &"graphics", 5, &"design", 5, 0),
		_make_fixture(&"both_7", &"graphics", 7, &"technology", 7, 0),
	]
	var both := _calculate_hand(design_phase, specialized_cards)
	_expect(both.balanced_eligible and both.provisional_scores == {graphics: 17, sound: 17, technology: 17, design: 17}, "Balanced eligibility uses base production even when Specialization qualifies")
	_expect(both.specialization_stat == &"graphics" and not both.balanced_production, "Specialization takes precedence when both synergies qualify")
	_expect(both.score_additions == {graphics: 26, technology: 14, sound: 5, design: 8}, "Specialization and Balanced multipliers never stack")


func _verify_balanced_success(design_phase: Node) -> void:
	var project_state := _reset_project_state(design_phase)
	var current: Dictionary[ProjectState.CoreScore, int] = {
		ProjectState.CoreScore.GRAPHICS: 3,
		ProjectState.CoreScore.SOUND: 3,
		ProjectState.CoreScore.TECHNOLOGY: 5,
		ProjectState.CoreScore.DESIGN: 6,
	}
	project_state.add_core_scores_and_scope(current, 0)
	var cards: Array[CardData] = [
		_make_fixture(&"commit_graphics", &"graphics", 2, &"sound", 1, 1),
		_make_fixture(&"commit_sound", &"sound", 4, &"graphics", 3, 1),
		_make_fixture(&"commit_technology", &"technology", 3, &"", 0, 1),
		_make_fixture(&"commit_design", &"design", 2, &"", 0, 1),
	]
	_set_exact_candidates(design_phase, cards)
	_select_first(design_phase, 4)
	var emissions := [0]
	project_state.values_changed.connect(func() -> void: emissions[0] += 1)
	(design_phase.get_node("%PlayCardButton") as Button).pressed.emit()
	design_phase.get_workspace().hand_motion.cancel() # Timing is covered by verify_card_motion; this suite checks transactions.
	_expect(_values(project_state) == [9, 9, 9, 8, 4], "Balanced success adds only adjusted current production and unmodified Scope")
	_expect(_approximately_equal(project_state.get_accumulated_bug_pressure(), 15.0 / 18.0), "Balanced success accumulates fractional Bug Pressure from unadjusted printed values")
	_expect(design_phase.get_node("%BugPressureValue").text == "Bug Pressure: 0.83", "Successful Feature action refreshes the Bug Pressure label through values_changed")
	_expect(emissions[0] == 1, "Balanced success commits through one values_changed emission")
	_expect(project_state.get_current_cycle() == 1, "Balanced success advances exactly one cycle")
	_expect(design_phase.get_workspace().synergy_notification.title_label.text == "Balanced Production!", "Balanced Design action displays its synergy")
	for card in cards:
		_expect(design_phase.get("_exhausted_card_ids").has(card.id), "Balanced success preserves Feature exhaustion: %s" % card.id)
	_expect(design_phase.get("_selected_card_views").is_empty() and design_phase.get_node("%HandContainer").get_child_count() == 7, "Balanced success clears selection and replaces the candidate pool")


func _verify_balanced_pass_success(design_phase: Node, database: Node) -> void:
	var project_state := _reset_project_state(design_phase)
	var cards: Array[CardData] = [
		database.call(&"get_card", &"4_color_palette"),
		database.call(&"get_card", &"sound_pass"),
		database.call(&"get_card", &"technology_pass"),
		database.call(&"get_card", &"design_pass"),
	]
	_set_exact_candidates(design_phase, cards)
	_select_first(design_phase, 4)
	var base_hand: Dictionary = design_phase.call("_validate_and_calculate_base_action")
	var final_action: Dictionary = design_phase.call("_calculate_final_action_production", base_hand)
	_expect(final_action.balanced_production and final_action.score_additions == {
		ProjectState.CoreScore.GRAPHICS: 2,
		ProjectState.CoreScore.SOUND: 2,
		ProjectState.CoreScore.TECHNOLOGY: 2,
		ProjectState.CoreScore.DESIGN: 2,
	}, "One Feature plus three real Passes triggers Balanced; each +2 aggregate remains +2 after nearest rounding")
	var emissions := [0]
	project_state.values_changed.connect(func() -> void: emissions[0] += 1)
	(design_phase.get_node("%PlayCardButton") as Button).pressed.emit()
	design_phase.get_workspace().hand_motion.cancel() # Timing is covered by verify_card_motion; this suite checks transactions.
	_expect(_values(project_state) == [2, 2, 2, 2, 1], "Pass-assisted Balanced action commits adjusted production and normal Feature Scope")
	_expect(_approximately_equal(project_state.get_accumulated_bug_pressure(), 2.0 / 18.0), "Feature-plus-Pass action accumulates only the Feature's fractional Bug Pressure")
	_expect(
		design_phase.get_node("%GraphicsValue").text == "Graphics: 2"
		and design_phase.get_node("%SoundValue").text == "Sound: 2"
		and design_phase.get_node("%TechnologyValue").text == "Technology: 2"
		and design_phase.get_node("%DesignValue").text == "Design: 2"
		and design_phase.get_node("%ScopeValue").text == "Scope: 1 / 30",
		"Pass-assisted Balanced gains and Scope refresh in the visible stat display",
	)
	_expect(emissions[0] == 1 and project_state.get_current_cycle() == 1, "Pass-assisted Balanced action commits once and advances exactly one cycle")
	_expect(design_phase.get("_exhausted_card_ids").has(&"4_color_palette"), "Pass-assisted Balanced action exhausts its Feature")
	_expect(
		not design_phase.get("_exhausted_card_ids").has(&"sound_pass")
		and not design_phase.get("_exhausted_card_ids").has(&"technology_pass")
		and not design_phase.get("_exhausted_card_ids").has(&"design_pass"),
		"Pass-assisted Balanced action does not exhaust Passes",
	)


func _verify_two_action_bug_pressure_accumulation(design_phase: Node, database: Node) -> void:
	var project_state := _reset_project_state(design_phase)
	var pass_cards: Array[CardData] = [
		database.call(&"get_card", &"sound_pass"),
		database.call(&"get_card", &"technology_pass"),
		database.call(&"get_card", &"design_pass"),
	]
	var first_hand: Array[CardData] = [database.call(&"get_card", &"4_color_palette")]
	first_hand.append_array(pass_cards)
	_set_exact_candidates(design_phase, first_hand)
	_select_first(design_phase, 4)
	(design_phase.get_node("%PlayCardButton") as Button).pressed.emit()
	design_phase.get_workspace().hand_motion.cancel() # Timing is covered by verify_card_motion; this suite checks transactions.
	var first_pressure := project_state.get_accumulated_bug_pressure()
	_expect(_approximately_equal(first_pressure, 2.0 / 18.0), "First successful action retains fractional Bug Pressure across its redeal and cycle advancement")
	_expect(design_phase.get_node("%BugPressureValue").text == "Bug Pressure: 0.11", "First successful Feature action displays its fractional Bug Pressure")
	var second_hand: Array[CardData] = [database.call(&"get_card", &"text")]
	second_hand.append_array(pass_cards)
	_set_exact_candidates(design_phase, second_hand)
	_select_first(design_phase, 4)
	(design_phase.get_node("%PlayCardButton") as Button).pressed.emit()
	design_phase.get_workspace().hand_motion.cancel() # Timing is covered by verify_card_motion; this suite checks transactions.
	_expect(_approximately_equal(project_state.get_accumulated_bug_pressure(), 5.0 / 18.0), "Two successful actions accumulate fractional Feature Bug Pressure correctly")
	_expect(design_phase.get_node("%BugPressureValue").text == "Bug Pressure: 0.28", "Multiple Feature actions display their accumulated Bug Pressure")
	_expect(project_state.get_current_cycle() == 2, "Two Bug Pressure-producing actions still advance exactly two cycles")


func _verify_atomic_failure(design_phase: Node, project_state: ProjectState, database: Node) -> void:
	var malformed := CardData.new()
	malformed.id = &"malformed_fixture"
	malformed.card_name = "Malformed Fixture"
	malformed.card_type = &"feature"
	malformed.phase = CardData.PHASE_DESIGN
	malformed.primary_stat = &"graphics"
	malformed.primary_value = 2
	malformed.secondary_stat = &""
	malformed.secondary_value = 1
	malformed.scope = 1
	malformed.renewable = false
	var cards: Array[CardData] = [malformed, database.call(&"get_card", &"text"), database.call(&"get_card", &"sprites"), database.call(&"get_card", &"graphics_pass")]
	_set_exact_candidates(design_phase, cards)
	_select_first(design_phase, 4)
	var before := _values(project_state)
	var bug_pressure_before := project_state.get_accumulated_bug_pressure()
	var cycle_before := project_state.get_current_cycle()
	var old_views := design_phase.get_node("%HandContainer").get_children()
	(design_phase.get_node("%PlayCardButton") as Button).pressed.emit()
	design_phase.get_workspace().hand_motion.cancel() # Timing is covered by verify_card_motion; this suite checks transactions.
	_expect(_values(project_state) == before, "Malformed specialized hand applies no base score, bonus, or Scope")
	_expect(_approximately_equal(project_state.get_accumulated_bug_pressure(), bug_pressure_before), "Malformed hand adds no Bug Pressure")
	_expect(design_phase.get_node("%BugPressureValue").text == "Bug Pressure: %.2f" % bug_pressure_before, "Malformed hand leaves the Bug Pressure display unchanged")
	_expect(project_state.get_current_cycle() == cycle_before, "Malformed hand consumes no time")
	_expect(design_phase.get("_candidate_cards") == cards and design_phase.get("_selected_card_views").size() == 4, "Malformed hand preserves candidates and selections")
	_expect(not (design_phase.get_node("%PlayCardButton") as Button).disabled and design_phase.get_node("%HandContainer").get_children() == old_views, "Malformed hand preserves Play state and CardViews")


func _verify_atomic_success(design_phase: Node, project_state: ProjectState, database: Node) -> void:
	var cards: Array[CardData] = [
		database.call(&"get_card", &"split_screen"),
		database.call(&"get_card", &"text"),
		database.call(&"get_card", &"graphics_pass"),
		database.call(&"get_card", &"graphics_pass"),
		database.call(&"get_card", &"sprites"),
	]
	_set_exact_candidates(design_phase, cards)
	_select_first(design_phase, 4)
	var old_views := design_phase.get_node("%HandContainer").get_children()
	var emissions := [0]
	project_state.values_changed.connect(func() -> void: emissions[0] += 1)
	(design_phase.get_node("%PlayCardButton") as Button).pressed.emit()
	design_phase.get_workspace().hand_motion.cancel() # Timing is covered by verify_card_motion; this suite checks transactions.
	_expect(_values(project_state) == [7, 0, 4, 5, 4], "Four cards aggregate primary, secondary, repeated score, and Scope correctly")
	_expect(_approximately_equal(project_state.get_accumulated_bug_pressure(), 5.0 / 3.0), "Successful mixed action atomically accumulates every selected Feature's fractional Bug Pressure")
	_expect(emissions[0] == 1, "Complete hand commits through one values_changed emission")
	_expect(project_state.get_current_cycle() == 1, "Complete four-card hand advances exactly one cycle")
	_expect(design_phase.get("_exhausted_card_ids").has(&"split_screen") and design_phase.get("_exhausted_card_ids").has(&"text"), "Every selected Feature is exhausted")
	_expect(not design_phase.get("_exhausted_card_ids").has(&"graphics_pass"), "Pass definitions are never exhausted")
	_expect(not design_phase.get("_candidate_cards").any(func(card: CardData) -> bool: return design_phase.get("_exhausted_card_ids").has(card.id)), "Exhausted Features never appear in the next weighted pool")
	var retained_features: Array = design_phase.get("_available_features").duplicate()
	retained_features.append_array(design_phase.get("_candidate_cards"))
	_expect(retained_features.has(database.call(&"get_card", &"sprites")), "Unselected Feature remains available or is redealt")
	_expect(design_phase.get("_selected_card_views").is_empty() and (design_phase.get_node("%PlayCardButton") as Button).disabled, "Successful play clears selections and disables Play")
	_expect(design_phase.get_node("%HandContainer").get_child_count() == 7, "Successful play deals seven new candidates")
	(old_views[0] as CardView).card_pressed.emit(old_views[0])
	(design_phase.get_node("%PlayCardButton") as Button).pressed.emit()
	design_phase.get_workspace().hand_motion.cancel() # Timing is covered by verify_card_motion; this suite checks transactions.
	_expect(project_state.get_current_cycle() == 1 and _values(project_state) == [7, 0, 4, 5, 4], "Stale activation cannot replay the previous hand")


func _verify_post_hand_deal_failure(design_phase: Node, restore_state: ProjectState, database: Node) -> void:
	var project_state := _reset_project_state(design_phase)
	var feature: CardData = database.call(&"get_card", &"4_color_palette")
	var cards: Array[CardData] = [
		feature,
		database.call(&"get_card", &"graphics_pass"),
		database.call(&"get_card", &"sound_pass"),
		database.call(&"get_card", &"technology_pass"),
	]
	_set_exact_candidates(design_phase, cards)
	_select_first(design_phase, 4)
	var passes: Array[CardData] = []
	passes.assign(database.call(&"get_cards_by_phase_and_types", CardData.PHASE_DESIGN, [&"pass"] as Array[StringName]))
	design_phase.set("_pass_definitions", passes.slice(0, 3))
	(design_phase.get_node("%PlayCardButton") as Button).pressed.emit()
	design_phase.get_workspace().hand_motion.cancel() # Timing is covered by verify_card_motion; this suite checks transactions.
	_expect(_values(project_state) == [4, 2, 2, 0, 1] and project_state.get_current_cycle() == 1, "Post-hand deal failure preserves the committed scores, Scope, and one cycle")
	_expect(design_phase.get("_exhausted_card_ids").has(feature.id), "Post-hand deal failure preserves committed Feature exhaustion")
	_expect(design_phase.get("_candidate_cards").is_empty() and design_phase.get_node("%HandContainer").get_child_count() == 0, "Post-hand deal failure leaves a safe empty pool rather than a partial pool")
	design_phase.set("_pass_definitions", passes)
	design_phase.call("setup", restore_state)


func _verify_pass_only_hand(design_phase: Node, project_state: ProjectState, database: Node) -> void:
	var graphics_pass: CardData = database.call(&"get_card", &"graphics_pass")
	var cards: Array[CardData] = [graphics_pass, graphics_pass, graphics_pass, graphics_pass, graphics_pass, graphics_pass, graphics_pass]
	_set_exact_candidates(design_phase, cards)
	# This fixture expects an exhausted Feature supply; do not inherit undealt
	# Features from the preceding mixed-hand fixture's randomized replacement.
	(design_phase.get("_available_features") as Array).clear()
	_select_first(design_phase, 4)
	var scope_before := project_state.get_current_scope()
	var bug_pressure_before := project_state.get_accumulated_bug_pressure()
	var bug_pressure_text_before: String = design_phase.get_node("%BugPressureValue").text
	var base_hand: Dictionary = design_phase.call("_validate_and_calculate_base_action")
	_expect(base_hand.valid and not base_hand.has_feature, "Pass-only base result reports no Feature presence")
	(design_phase.get_node("%PlayCardButton") as Button).pressed.emit()
	design_phase.get_workspace().hand_motion.cancel() # Timing is covered by verify_card_motion; this suite checks transactions.
	_expect(project_state.get_core_score(ProjectState.CoreScore.GRAPHICS) == 19, "Four matching +2 Pass instances trigger Specialization and contribute +12")
	_expect(project_state.get_current_scope() == scope_before, "Pass-only hand adds 0 Scope")
	_expect(_approximately_equal(project_state.get_accumulated_bug_pressure(), bug_pressure_before), "Duplicate Pass-only hand adds exactly 0.0 Bug Pressure and preserves prior accumulation")
	_expect(design_phase.get_node("%BugPressureValue").text == bug_pressure_text_before, "Pass-only action leaves the displayed Bug Pressure unchanged")
	_expect(project_state.get_current_cycle() == 2, "Pass-only hand advances one cycle; two hands equal one month")
	_verify_candidate_pool(design_phase, 0, 7, "Post-play no-Feature pool")
	_expect(not design_phase.get("_exhausted_card_ids").has(&"graphics_pass"), "Specialized Passes do not exhaust")


func _verify_perfect_production_and_hidden_bugs(design_phase: Node) -> void:
	var graphics := ProjectState.CoreScore.GRAPHICS
	var sound := ProjectState.CoreScore.SOUND
	var technology := ProjectState.CoreScore.TECHNOLOGY
	var design := ProjectState.CoreScore.DESIGN
	_expect(design_phase.call("_are_core_scores_perfect", {graphics: 19, sound: 20, technology: 20, design: 21}), "Perfect Production includes exact 0.95A and 1.05A boundaries")
	_expect(not design_phase.call("_are_core_scores_perfect", {graphics: 18, sound: 20, technology: 20, design: 21}), "A score just below the Perfect lower boundary fails")
	_expect(not design_phase.call("_are_core_scores_perfect", {graphics: 19, sound: 20, technology: 20, design: 22}), "A score just above the Perfect upper boundary fails")
	_expect(design_phase.call("_are_core_scores_perfect", {graphics: 20, sound: 20, technology: 20, design: 21}), "Perfect Production uses a fractional four-score mean")
	_expect(design_phase.call("_are_core_scores_perfect", {graphics: 0, sound: 0, technology: 0, design: 0}), "Literal all-zero distribution qualifies for Perfect Production")

	var perfect_state := ProjectState.new(30)
	var equal_scores: Dictionary[ProjectState.CoreScore, int] = {graphics: 10, sound: 10, technology: 10, design: 10}
	perfect_state.add_core_scores_and_scope(equal_scores, 19, 10.0)
	design_phase.call("setup", perfect_state)
	var perfect_values_before := _values(perfect_state)
	var perfect_cycle_before := perfect_state.get_current_cycle()
	var perfect_result: Dictionary = design_phase.call("_calculate_design_finalization", 0.5, 0.5)
	_expect(perfect_result.perfect_production and _approximately_equal(perfect_result.adjusted_bug_pressure, 8.0), "Perfect Production below Required Scope applies the 0.80 finalization modifier")
	_expect(_approximately_equal(perfect_state.get_accumulated_bug_pressure(), 10.0) and perfect_state.get_current_scope() == 19, "Perfect calculation preserves historical Bug Pressure and Scope")
	_expect(_values(perfect_state) == perfect_values_before and perfect_state.get_current_cycle() == perfect_cycle_before, "Perfect calculation changes no Core Scores and advances no cycle")
	_expect(perfect_result.hidden_bugs == 8, "Integer adjusted Bug Pressure receives no stochastic increment")

	var nonperfect_state := ProjectState.new(30)
	var lopsided_scores: Dictionary[ProjectState.CoreScore, int] = {graphics: 1, sound: 2, technology: 3, design: 20}
	nonperfect_state.add_core_scores_and_scope(lopsided_scores, 32, 7.6)
	design_phase.call("setup", nonperfect_state)
	var incremented: Dictionary = design_phase.call("_calculate_design_finalization", 0.599999, 0.5)
	var not_incremented: Dictionary = design_phase.call("_calculate_design_finalization", 0.6, 0.5)
	_expect(not incremented.perfect_production and _approximately_equal(incremented.adjusted_bug_pressure, 7.6), "Non-Perfect finalization above Required Scope uses accumulated Bug Pressure unchanged")
	_expect(incremented.hidden_bugs == 8, "Fractional pressure increments when stochastic roll is below the fraction")
	_expect(not_incremented.hidden_bugs == 7, "Fractional pressure does not increment when stochastic roll equals the fraction")
	_expect(_approximately_equal(nonperfect_state.get_accumulated_bug_pressure(), 7.6) and nonperfect_state.get_current_scope() == 32, "Hidden Bug calculation mutates neither historical pressure nor Scope overshoot")

	var variance_cases := [
		[0.079999, -2], [0.08, -1], [0.249999, -1], [0.25, 0],
		[0.749999, 0], [0.75, 1], [0.919999, 1], [0.92, 2], [0.999999, 2],
	]
	for variance_case in variance_cases:
		_expect(design_phase.call("_get_bug_variance", variance_case[0]) == variance_case[1], "Variance roll %.6f maps to modifier %d" % variance_case)
	var low_variance: Dictionary = design_phase.call("_calculate_design_finalization", 0.6, 0.0)
	var high_variance: Dictionary = design_phase.call("_calculate_design_finalization", 0.6, 0.99)
	_expect(high_variance.hidden_bugs - low_variance.hidden_bugs == 4, "Stochastic rounding and bounded variance consume independently controlled rolls")
	var clamp_state := ProjectState.new(30)
	design_phase.call("setup", clamp_state)
	var clamped: Dictionary = design_phase.call("_calculate_design_finalization", 0.5, 0.0)
	_expect(clamped.perfect_production and clamped.hidden_bugs == 0, "All-zero Perfect finalization clamps negative variance to zero Hidden Bugs")
	_expect(not design_phase.call("_calculate_design_finalization", NAN, 0.5).valid and not design_phase.call("_calculate_design_finalization", 0.5, 1.0).valid, "Invalid controlled rolls fail finalization calculation")


func _verify_feature_history_finalization(design_phase: Node, database: Node) -> void:
	var definitions: Array[CardData] = []
	definitions.assign(database.call(&"get_cards_by_phase_and_types", CardData.PHASE_DESIGN, [&"feature"] as Array[StringName]))
	var all_ids: Array[StringName] = []
	for card in definitions:
		all_ids.append(card.id)
	all_ids.sort_custom(func(a: StringName, b: StringName) -> bool: return str(a) < str(b))
	var original_exhausted: Dictionary = design_phase.get("_exhausted_card_ids").duplicate()

	var exhausted: Dictionary = design_phase.get("_exhausted_card_ids")
	exhausted.clear()
	var immediate_state := _reset_project_state(design_phase)
	design_phase.set("_finalization_requested", false)
	(design_phase.get_node("%ProceedToAlphaButton") as Button).disabled = false
	_set_exact_candidates(design_phase, definitions.slice(0, 4))
	(design_phase.get_node("%ProceedToAlphaButton") as Button).pressed.emit()
	_expect(immediate_state.get_implemented_design_feature_ids().is_empty() and immediate_state.get_unimplemented_design_feature_ids() == all_ids, "Proceeding immediately stores zero implemented and all 13 Design Features unimplemented")
	_expect(immediate_state.get_unimplemented_design_feature_ids().size() == 13, "Immediate finalization partition totals all 13 current Design Features")

	exhausted.clear()
	exhausted[definitions[0].id] = true
	exhausted[definitions[1].id] = true
	var partial: Dictionary = design_phase.call("_build_design_feature_history")
	_expect(partial.valid and partial.implemented_ids.size() == 2 and partial.unimplemented_ids.size() == 11, "Partial lifecycle partitions played Features from every remaining Feature")
	_expect(_is_lexically_sorted(partial.implemented_ids) and _is_lexically_sorted(partial.unimplemented_ids), "Finalized Feature partition ordering is deterministic")
	var original_partial := partial.duplicate(true)
	var reversed_candidates := definitions.slice(2, 6)
	reversed_candidates.reverse()
	design_phase.set("_finalization_requested", false)
	_set_exact_candidates(design_phase, reversed_candidates)
	_select_first(design_phase, 3)
	var reordered: Dictionary = design_phase.call("_build_design_feature_history")
	_expect(reordered.implemented_ids == original_partial.implemented_ids and reordered.unimplemented_ids == original_partial.unimplemented_ids, "Candidate and selection order do not change the Feature partition")
	for selected_view: CardView in design_phase.get("_selected_card_views"):
		_expect(reordered.unimplemented_ids.has(selected_view.card_data.id), "Selected-but-unplayed Feature remains unimplemented")

	var invalid_exhausted_id := &"graphics_pass"
	exhausted[invalid_exhausted_id] = true
	_expect(not design_phase.call("_build_design_feature_history").valid, "A Pass ID in implemented lifecycle rejects semantic finalization")
	var invalid_history_state := _reset_project_state(design_phase)
	design_phase.set("_finalization_requested", false)
	(design_phase.get_node("%ProceedToAlphaButton") as Button).disabled = false
	var invalid_value_emissions := [0]
	var invalid_proceed_emissions := [0]
	invalid_history_state.values_changed.connect(func() -> void: invalid_value_emissions[0] += 1)
	design_phase.proceed_to_alpha_requested.connect(func() -> void: invalid_proceed_emissions[0] += 1)
	(design_phase.get_node("%ProceedToAlphaButton") as Button).pressed.emit()
	_expect(not invalid_history_state.has_design_bug_finalization() and not design_phase.get("_finalization_requested"), "Invalid semantic history leaves authoritative result empty and Design active")
	_expect(invalid_value_emissions[0] == 0 and invalid_proceed_emissions[0] == 0, "Invalid semantic history emits neither authoritative nor Proceed signal")
	exhausted.erase(invalid_exhausted_id)
	_expect(not design_phase.call("_is_valid_design_feature_history", [&"missing_feature"], all_ids, definitions), "An invalid implemented ID rejects semantic history validation")
	_expect(not design_phase.call("_is_valid_design_feature_history", [], [&"missing_feature"], definitions), "An invalid unimplemented ID rejects semantic history validation")

	exhausted.clear()
	for id in all_ids:
		exhausted[id] = true
	var all_state := _reset_project_state(design_phase)
	design_phase.set("_finalization_requested", false)
	(design_phase.get_node("%ProceedToAlphaButton") as Button).disabled = false
	var pass_candidates: Array[CardData] = [
		database.call(&"get_card", &"graphics_pass"),
		database.call(&"get_card", &"sound_pass"),
		database.call(&"get_card", &"technology_pass"),
		database.call(&"get_card", &"design_pass"),
	]
	_set_exact_candidates(design_phase, pass_candidates)
	(design_phase.get_node("%ProceedToAlphaButton") as Button).pressed.emit()
	_expect(all_state.get_implemented_design_feature_ids() == all_ids and all_state.get_unimplemented_design_feature_ids().is_empty(), "Finalization after all 13 Features stores all implemented and none unimplemented")
	_expect(not all_state.get_implemented_design_feature_ids().has(&"graphics_pass"), "Pass-only candidate state adds no Pass to persistent Feature history")
	for id in all_state.get_implemented_design_feature_ids():
		var card: CardData = database.call(&"get_card", id)
		_expect(card != null and card.phase == CardData.PHASE_DESIGN and card.card_type == &"feature", "Stored history ID resolves publicly to a Design Feature: %s" % id)

	exhausted.clear()
	for id in original_exhausted:
		exhausted[id] = true


func _verify_design_finalization(design_phase: Node, database: Node) -> void:
	design_phase.get("_exhausted_card_ids").clear()
	var rejected_state := ProjectState.new(30)
	rejected_state.finalize_design_bugs(false, 1, [], [])
	design_phase.call("setup", rejected_state)
	design_phase.set("_finalization_requested", false)
	(design_phase.get_node("%ProceedToAlphaButton") as Button).disabled = false
	var rejected_signal_count := [0]
	var rejected_value_signals := [0]
	var rejected_cycle_signals := [0]
	var rejected_values_before := _values(rejected_state)
	var rejected_candidates_before: Array = design_phase.get("_candidate_cards").duplicate()
	var rejected_selections_before: Array = design_phase.get("_selected_card_views").duplicate()
	design_phase.proceed_to_alpha_requested.connect(func() -> void: rejected_signal_count[0] += 1)
	rejected_state.values_changed.connect(func() -> void: rejected_value_signals[0] += 1)
	rejected_state.cycle_changed.connect(func() -> void: rejected_cycle_signals[0] += 1)
	(design_phase.get_node("%ProceedToAlphaButton") as Button).pressed.emit()
	_expect(not design_phase.get("_finalization_requested") and not design_phase.get_node("%ProceedToAlphaButton").disabled, "Failed authoritative storage leaves Design active and Proceed available")
	_expect(rejected_signal_count[0] == 0, "Failed authoritative storage emits no Proceed signal")
	_expect(rejected_value_signals[0] == 0 and rejected_cycle_signals[0] == 0 and _values(rejected_state) == rejected_values_before, "Failed finalization emits no state signals and mutates no authoritative values")
	_expect(design_phase.get("_candidate_cards") == rejected_candidates_before and design_phase.get("_selected_card_views") == rejected_selections_before, "Failed finalization preserves candidates and selections")

	var overshoot_state := ProjectState.new(30)
	overshoot_state.add_scope(32)
	design_phase.call("setup", overshoot_state)
	design_phase.set("_finalization_requested", false)
	(design_phase.get_node("%ProceedToAlphaButton") as Button).disabled = false
	var overshoot_passes: Array[CardData] = [
		database.call(&"get_card", &"graphics_pass"),
		database.call(&"get_card", &"sound_pass"),
		database.call(&"get_card", &"technology_pass"),
		database.call(&"get_card", &"design_pass"),
	]
	_set_exact_candidates(design_phase, overshoot_passes)
	_select_first(design_phase, 4)
	(design_phase.get_node("%PlayCardButton") as Button).pressed.emit()
	design_phase.get_workspace().hand_motion.cancel() # Timing is covered by verify_card_motion; this suite checks transactions.
	_expect(overshoot_state.get_current_scope() == 32 and overshoot_state.get_current_cycle() == 1, "A complete hand remains playable above Required Scope without clamping overshoot")

	var cards: Array[CardData] = [
		database.call(&"get_card", &"text"),
		database.call(&"get_card", &"graphics_pass"),
		database.call(&"get_card", &"sound_pass"),
		database.call(&"get_card", &"technology_pass"),
	]
	var scope_cases := [19, 30, 32]
	var selection_counts := [0, 2, 4]
	for case_index in range(scope_cases.size()):
		var project_state := ProjectState.new(30)
		var initial_additions: Dictionary[ProjectState.CoreScore, int] = {
			ProjectState.CoreScore.GRAPHICS: 1,
			ProjectState.CoreScore.SOUND: 2,
			ProjectState.CoreScore.TECHNOLOGY: 3,
			ProjectState.CoreScore.DESIGN: 4,
		}
		project_state.add_core_scores_and_scope(initial_additions, scope_cases[case_index], 0.25)
		design_phase.call("setup", project_state)
		design_phase.set("_finalization_requested", false)
		(design_phase.get_node("%ProceedToAlphaButton") as Button).disabled = false
		_set_exact_candidates(design_phase, cards)
		_select_first(design_phase, selection_counts[case_index])
		var play_button := design_phase.get_node("%PlayCardButton") as Button
		_expect(not design_phase.get("_finalization_requested"), "Scope %d / 30 does not automatically finalize Design" % scope_cases[case_index])
		_expect(play_button.disabled == (selection_counts[case_index] != 4), "Play Hand at Scope %d depends only on complete selection" % scope_cases[case_index])

		var values_before := _values(project_state)
		var pressure_before := project_state.get_accumulated_bug_pressure()
		var cycle_before := project_state.get_current_cycle()
		var candidates_before: Array = design_phase.get("_candidate_cards").duplicate()
		var selections_before: Array = design_phase.get("_selected_card_views").duplicate()
		var available_before: Array = design_phase.get("_available_features").duplicate()
		var exhausted_before: Dictionary = design_phase.get("_exhausted_card_ids").duplicate()
		var text_exhausted_before := exhausted_before.has(&"text")
		var pass_exhausted_before := exhausted_before.has(&"graphics_pass")
		var finalization_emissions := [0]
		var value_emissions := [0]
		var cycle_emissions := [0]
		var storage_preceded_signal := [false]
		design_phase.proceed_to_alpha_requested.connect(func() -> void:
			finalization_emissions[0] += 1
			storage_preceded_signal[0] = project_state.has_design_bug_finalization()
		)
		project_state.values_changed.connect(func() -> void: value_emissions[0] += 1)
		project_state.cycle_changed.connect(func() -> void: cycle_emissions[0] += 1)

		(design_phase.get_node("%ProceedToAlphaButton") as Button).pressed.emit()
		var hidden_bugs_after_first := project_state.get_hidden_bugs()
		var implemented_after_first := project_state.get_implemented_design_feature_ids()
		var unimplemented_after_first := project_state.get_unimplemented_design_feature_ids()
		(design_phase.get_node("%ProceedToAlphaButton") as Button).pressed.emit()
		play_button.pressed.emit()
		var first_view := design_phase.get_node("%HandContainer").get_child(0) as CardView
		first_view.card_pressed.emit(first_view)

		_expect(finalization_emissions[0] == 1, "Proceed at Scope %d emits finalization exactly once" % scope_cases[case_index])
		_expect(storage_preceded_signal[0] and project_state.has_design_bug_finalization(), "Authoritative finalized result is stored before Proceed emits")
		_expect(project_state.get_hidden_bugs() == hidden_bugs_after_first, "Repeated Proceed activation does not reroll or overwrite Hidden Bugs")
		_expect(project_state.get_implemented_design_feature_ids() == implemented_after_first and project_state.get_unimplemented_design_feature_ids() == unimplemented_after_first, "Repeated Proceed activation cannot overwrite persistent Feature history")
		_expect(implemented_after_first.size() + unimplemented_after_first.size() == 13, "Successful finalization stores a complete 13-Feature partition atomically")
		_expect(design_phase.get("_finalization_requested") and design_phase.get_node("%ProceedToAlphaButton").disabled and play_button.disabled, "Proceed freezes only necessary Design controls")
		_expect(_values(project_state) == values_before and _approximately_equal(project_state.get_accumulated_bug_pressure(), pressure_before), "Proceed preserves scores, Scope %d, and fractional Bug Pressure" % scope_cases[case_index])
		_expect(project_state.get_current_cycle() == cycle_before and cycle_emissions[0] == 0, "Proceed at Scope %d advances no cycle" % scope_cases[case_index])
		_expect(value_emissions[0] == 1, "Proceed at Scope %d emits one authoritative ProjectState values_changed signal" % scope_cases[case_index])
		_expect(design_phase.get("_candidate_cards") == candidates_before and design_phase.get("_selected_card_views") == selections_before, "Proceed preserves candidates and current selections without resolving them")
		_expect(design_phase.get("_available_features") == available_before and design_phase.get("_exhausted_card_ids") == exhausted_before, "Proceed preserves available and exhausted Feature identities")
		_expect(design_phase.get("_exhausted_card_ids").has(&"text") == text_exhausted_before and design_phase.get("_exhausted_card_ids").has(&"graphics_pass") == pass_exhausted_before, "Proceed changes exhaustion status for neither selected Features nor Passes")


func _calculate_hand(design_phase: Node, cards: Array[CardData]) -> Dictionary:
	_set_exact_candidates(design_phase, cards)
	_select_first(design_phase, 4)
	var base_hand: Dictionary = design_phase.call("_validate_and_calculate_base_action")
	if not base_hand.valid:
		return {
			&"valid": false,
			&"base_hand": base_hand,
			&"specialization_stat": &"",
			&"balanced_production": false,
			&"balanced_eligible": false,
			&"provisional_scores": {},
			&"score_additions": {},
			&"scope": 0,
		}
	var final_action: Dictionary = design_phase.call("_calculate_final_action_production", base_hand)
	return {
		&"valid": true,
		&"base_hand": base_hand,
		&"specialization_stat": final_action.specialization_stat,
		&"balanced_production": final_action.balanced_production,
		&"balanced_eligible": final_action.balanced_eligible,
		&"provisional_scores": final_action.provisional_scores,
		&"score_additions": final_action.score_additions,
		&"scope": base_hand.scope,
	}


func _make_fixture(id: StringName, primary_stat: StringName, primary_value: int, secondary_stat: StringName, secondary_value: int, scope: int) -> CardData:
	var card := CardData.new()
	card.id = id
	card.card_name = str(id)
	card.card_type = &"feature"
	card.phase = CardData.PHASE_DESIGN
	card.primary_stat = primary_stat
	card.primary_value = primary_value
	card.secondary_stat = secondary_stat
	card.secondary_value = secondary_value
	card.scope = scope
	card.renewable = false
	return card


func _reset_project_state(design_phase: Node) -> ProjectState:
	var project_state := ProjectState.new(30)
	design_phase.call("setup", project_state)
	return project_state


func _set_pool(design_phase: Node, features: Array) -> void:
	design_phase.call("_clear_candidate_pool")
	var available: Array = design_phase.get("_available_features")
	available.assign(features)
	var exhausted: Dictionary = design_phase.get("_exhausted_card_ids")
	exhausted.clear()
	design_phase.call("_deal_next_candidate_pool")


func _set_exact_candidates(design_phase: Node, cards: Array[CardData]) -> void:
	design_phase.call("_clear_candidate_pool")
	var candidates: Array = design_phase.get("_candidate_cards")
	candidates.assign(cards)
	var container := design_phase.get_node("%HandContainer")
	for card in cards:
		var view: CardView = design_phase.CARD_VIEW_SCENE.instantiate()
		view.set_card(card)
		view.card_pressed.connect(Callable(design_phase, "_on_card_pressed"))
		container.add_child(view)


func _select_first(design_phase: Node, count: int) -> void:
	var views := design_phase.get_node("%HandContainer").get_children()
	for index in range(count):
		(views[index] as CardView).input_button.pressed.emit()


func _verify_candidate_pool(design_phase: Node, feature_count: int, pass_count: int, description: String) -> void:
	var candidates: Array = design_phase.get("_candidate_cards")
	_expect(candidates.size() == 7 and design_phase.get_node("%HandContainer").get_child_count() == 7, "%s contains seven instances" % description)
	var actual_features := 0
	var actual_passes := 0
	var feature_ids: Dictionary[StringName, bool] = {}
	for card: CardData in candidates:
		_expect(card.phase == CardData.PHASE_DESIGN, "%s excludes Alpha cards" % description)
		if card.card_type == &"feature":
			actual_features += 1
			_expect(not feature_ids.has(card.id), "%s has no duplicate Feature definition" % description)
			feature_ids[card.id] = true
		elif card.card_type == &"pass":
			actual_passes += 1
	_expect(actual_features == feature_count and actual_passes == pass_count, "%s has %d Features and %d Passes" % [description, feature_count, pass_count])


func _cards(database: Node, ids: Array[StringName]) -> Array[CardData]:
	var result: Array[CardData] = []
	for id in ids:
		result.append(database.call(&"get_card", id))
	return result


func _selected_view_count(design_phase: Node) -> int:
	var count := 0
	for child in design_phase.get_node("%HandContainer").get_children():
		if (child as CardView).is_selected():
			count += 1
	return count


func _values(project_state: ProjectState) -> Array[int]:
	return [
		project_state.get_core_score(ProjectState.CoreScore.GRAPHICS),
		project_state.get_core_score(ProjectState.CoreScore.SOUND),
		project_state.get_core_score(ProjectState.CoreScore.TECHNOLOGY),
		project_state.get_core_score(ProjectState.CoreScore.DESIGN),
		project_state.get_current_scope(),
	]


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
		return
	_failures += 1
	push_error("FAIL: %s" % description)


func _approximately_equal(actual: float, expected: float) -> bool:
	return abs(actual - expected) <= FLOAT_TOLERANCE


func _is_lexically_sorted(values: Array) -> bool:
	for index in range(1, values.size()):
		if str(values[index - 1]) > str(values[index]):
			return false
	return true


func _finish() -> void:
	if _failures == 0:
		print("DesignPhase verification passed.")
	quit(_failures)
