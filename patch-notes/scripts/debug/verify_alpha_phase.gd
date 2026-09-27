	## Separately invoked Alpha priority-allocation verification.
## Run with: godot --headless --path . --script res://scripts/debug/verify_alpha_phase.gd
extends SceneTree

const ALPHA_PHASE_SCENE := preload("res://scenes/phases/alpha_phase.tscn")
const CARD_VIEW_SCENE := preload("res://scenes/cards/card_view.tscn")
const CATEGORIES: Array[ProjectState.CoreScore] = [
	ProjectState.CoreScore.GRAPHICS,
	ProjectState.CoreScore.SOUND,
	ProjectState.CoreScore.TECHNOLOGY,
	ProjectState.CoreScore.DESIGN,
]

var _failures := 0


func _verify_project_state_alpha_transactions() -> void:
	var state := ProjectState.new(30)
	var emissions := [0]
	state.values_changed.connect(func() -> void: emissions[0] += 1)
	var additions: Dictionary[ProjectState.CoreScore, int] = {
		ProjectState.CoreScore.GRAPHICS: 3,
		ProjectState.CoreScore.DESIGN: 2,
	}
	_expect(state.add_alpha_production(additions, 2, 0.5), "ProjectState accepts one valid atomic Alpha production transaction")
	_expect(state.get_core_score(ProjectState.CoreScore.GRAPHICS) == 3 and state.get_core_score(ProjectState.CoreScore.DESIGN) == 2 and state.get_current_scope() == 2 and state.get_accumulated_alpha_bug_pressure() == 0.5, "Valid Alpha transaction commits scores, Scope, and separate pressure together")
	_expect(state.get_accumulated_bug_pressure() == 0.0 and emissions[0] == 1, "Alpha transaction leaves Design pressure unchanged and emits exactly once")
	for invalid_pressure: Variant in [-1.0, NAN, INF, -INF, &"invalid"]:
		var before := _state_snapshot(state)
		var emissions_before: int = emissions[0]
		_expect(not state.add_alpha_production(additions, 2, invalid_pressure), "Invalid Alpha pressure is rejected atomically: %s" % invalid_pressure)
		_expect(_state_snapshot(state) == before and emissions[0] == emissions_before, "Rejected Alpha transaction mutates nothing and emits nothing")
	var negative_scores: Dictionary[ProjectState.CoreScore, int] = {ProjectState.CoreScore.SOUND: -1}
	var empty_scores: Dictionary[ProjectState.CoreScore, int] = {}
	var before_negative := _state_snapshot(state)
	var emissions_before_negative: int = emissions[0]
	_expect(not state.add_alpha_production(negative_scores, 0, 0.0) and not state.add_alpha_production(empty_scores, -1, 0.0), "Negative Alpha scores and Scope are rejected")
	_expect(_state_snapshot(state) == before_negative and emissions[0] == emissions_before_negative, "Rejected negative Alpha transactions remain atomic")


func _initialize() -> void:
	_verify_project_state_alpha_transactions()
	var state := ProjectState.new(30)
	var alpha := ALPHA_PHASE_SCENE.instantiate() as AlphaPhase
	alpha.setup(state)
	root.add_child(alpha)
	await process_frame
	var state_before := _state_snapshot(state)
	var value_emissions := [0]
	var cycle_emissions := [0]
	var priority_emissions := [0]
	state.values_changed.connect(func() -> void: value_emissions[0] += 1)
	state.cycle_changed.connect(func() -> void: cycle_emissions[0] += 1)
	alpha.priorities_changed.connect(func() -> void: priority_emissions[0] += 1)

	_expect(alpha.get("_phase_state") == AlphaPhase.PhaseState.PLANNING, "Alpha initializes in Planning")
	_expect(state.get_accumulated_alpha_bug_pressure() == 0.0 and state.get_accumulated_bug_pressure() == 0.0, "Fresh ProjectState initializes separate Design and Alpha pressure at 0.0")
	_expect(alpha.get_node("%AlphaBugPressureValue").text == "Alpha Bug Pressure: 0.00", "Alpha pressure display initializes at exactly 0.00")
	_expect(alpha.find_children("*Hidden*").is_empty(), "Alpha UI does not expose concealed Hidden Bugs")
	_expect(alpha.get("_candidate_cards").is_empty() and alpha.get_node("%HandContainer").get_child_count() == 0, "Alpha Planning creates no candidates or CardViews")
	_expect(alpha.get_node("%BeginAlphaButton").visible and not alpha.get_node("%BeginAlphaButton").disabled, "Begin Alpha is visible and usable in Planning")
	_expect(alpha.get_node("%PlayAlphaHandButton").text == "Implement" and alpha.get_node("%PlayAlphaHandButton").disabled, "Alpha resolution placeholder is visibly disabled")
	_expect(alpha.get_node("%HostPlaytestButton").text == "Host Playtest" and alpha.get_node("%HostPlaytestButton").disabled, "Host Playtest is visible but unavailable during Planning")
	_expect(_values(alpha) == [25, 25, 25, 25] and alpha.get_available_priority() == 0, "Alpha initializes independently at 25 / 25 / 25 / 25")
	_verify_controls(alpha)
	(alpha.get_node("%SoundPriority") as VSlider).value = 15.0
	_expect(_values(alpha) == [25, 15, 25, 25] and alpha.get_available_priority() == 10, "Lowering changes only Sound and frees allocation")
	_expect(priority_emissions[0] == 1, "One slider adjustment emits exactly once")
	_expect(alpha.set_priority(ProjectState.CoreScore.GRAPHICS, 35), "Raising Graphics can spend available allocation")
	_expect(_values(alpha) == [35, 15, 25, 25] and alpha.get_available_priority() == 0, "Raising changes only Graphics and consumes allocation")
	_expect(alpha.set_priority(ProjectState.CoreScore.GRAPHICS, 50), "Over-budget request is handled safely")
	_expect(_values(alpha) == [35, 15, 25, 25], "Over-budget request clamps to the highest fitting value")
	_expect(alpha.set_priority(ProjectState.CoreScore.TECHNOLOGY, -100), "Below-range numeric request is normalized")
	_expect(_values(alpha) == [35, 15, 5, 25] and alpha.get_available_priority() == 20, "Below-range request clamps to 5 without redistribution")
	_expect(alpha.set_priority(ProjectState.CoreScore.DESIGN, 27.5), "Non-step numeric request is normalized")
	_expect(alpha.get_priority(ProjectState.CoreScore.DESIGN) == 30, "Exact half-step snaps upward")
	_expect(alpha.set_priority(ProjectState.CoreScore.TECHNOLOGY, 12.4), "Numeric request below half-step normalizes")
	_expect(alpha.get_priority(ProjectState.CoreScore.TECHNOLOGY) == 10, "Nearest-step normalization rounds 12.4 to 10")

	var before_invalid := alpha.get_priority_distribution()
	var emissions_before_invalid: int = priority_emissions[0]
	_expect(not alpha.set_priority(999, 25), "Invalid Core category is rejected")
	_expect(not alpha.set_priority(ProjectState.CoreScore.GRAPHICS, &"invalid"), "Nonnumeric request is rejected")
	_expect(not alpha.set_priority(ProjectState.CoreScore.GRAPHICS, NAN), "Nonfinite request is rejected")
	_expect(alpha.get_priority_distribution() == before_invalid and priority_emissions[0] == emissions_before_invalid, "Rejected requests mutate and emit nothing")
	var current_graphics := alpha.get_priority(ProjectState.CoreScore.GRAPHICS)
	_expect(alpha.set_priority(ProjectState.CoreScore.GRAPHICS, current_graphics), "No-op request is accepted")
	_expect(priority_emissions[0] == emissions_before_invalid, "No-op emits nothing")
	var returned_distribution := alpha.get_priority_distribution()
	returned_distribution[ProjectState.CoreScore.GRAPHICS] = 5
	_expect(alpha.get_priority(ProjectState.CoreScore.GRAPHICS) == current_graphics, "Distribution getter is defensive")

	for index in range(80):
		var category := CATEGORIES[index % CATEGORIES.size()]
		var requested := -20.0 + float((index * 13) % 91)
		_expect(alpha.set_priority(category, requested), "Repeated numeric adjustment %d succeeds" % index)
		_verify_distribution(alpha, "Repeated adjustment %d preserves allocation invariants" % index)
		_verify_control_values(alpha)

	_verify_weighted_alpha_boundary(alpha, state, state_before, value_emissions, cycle_emissions)
	await _verify_alpha_specialization_resolution()
	await _verify_alpha_balanced_production_calculation()
	await _verify_alpha_balanced_production_resolution()
	await _verify_host_playtest()
	await _verify_host_playtest_replacement_failure()
	await _verify_post_hand_redeal_failure()

	_expect(alpha.get("_project_state") == state, "Alpha retains the exact injected ProjectState")
	alpha.queue_free()
	await process_frame
	_finish()


func _verify_weighted_alpha_boundary(alpha: AlphaPhase, state: ProjectState, state_before: Array, value_emissions: Array, cycle_emissions: Array) -> void:
	_expect(alpha.call("_load_source_definitions"), "Alpha source definitions load through CardDatabase")
	var features: Array = alpha.get("_available_features")
	var passes: Array = alpha.get("_pass_definitions")
	_expect(features.size() == 14, "Current ledger supplies exactly 14 eligible Alpha Features")
	_expect(passes.size() == 4, "Alpha explicitly authorizes all four existing Core Pass definitions")
	var feature_ids: Dictionary[StringName, bool] = {}
	var features_valid := true
	for card: CardData in features:
		features_valid = features_valid and not card.id.is_empty() and not feature_ids.has(card.id) and card.phase == CardData.PHASE_ALPHA and card.card_type == &"feature" and not card.renewable
		feature_ids[card.id] = true
	_expect(features_valid and feature_ids.size() == 14, "Alpha Feature IDs are stable, unique, phase-correct, and nonrenewable")
	_expect(not passes.any(func(card: CardData) -> bool: return card.id == &"gameplay_pass"), "No generic Gameplay Pass enters Alpha")
	_expect(passes.all(func(card: CardData) -> bool: return card.phase == CardData.PHASE_DESIGN and card.card_type == &"pass" and card.renewable), "Design-phase Core Passes remain unchanged and are Alpha-authorized locally")

	var snapshot: Dictionary[ProjectState.CoreScore, int] = {
		ProjectState.CoreScore.GRAPHICS: 15,
		ProjectState.CoreScore.SOUND: 20,
		ProjectState.CoreScore.TECHNOLOGY: 40,
		ProjectState.CoreScore.DESIGN: 25,
	}
	var dual_score: CardData = features.filter(func(card: CardData) -> bool: return not card.secondary_stat.is_empty())[0]
	var expected_weight: float = snapshot[alpha.CORE_SCORE_BY_STAT[dual_score.primary_stat]] * dual_score.primary_value + snapshot[alpha.CORE_SCORE_BY_STAT[dual_score.secondary_stat]] * dual_score.secondary_value
	_expect(alpha.call("_calculate_candidate_weight", dual_score, snapshot) == expected_weight, "Alpha Feature weight uses both printed score contributions")
	var pass_card: CardData = passes[0]
	var expected_pass_weight: float = snapshot[alpha.CORE_SCORE_BY_STAT[pass_card.primary_stat]] * pass_card.primary_value
	_expect(alpha.call("_calculate_candidate_weight", pass_card, snapshot) == expected_pass_weight, "Alpha Pass weight uses matching priority and printed definition value")
	var fixture := CardData.new()
	fixture.primary_stat = dual_score.primary_stat
	fixture.primary_value = dual_score.primary_value
	fixture.secondary_stat = dual_score.secondary_stat
	fixture.secondary_value = dual_score.secondary_value
	fixture.scope = 999
	fixture.department = &"ignored"
	_expect(alpha.call("_calculate_candidate_weight", fixture, snapshot) == expected_weight, "Department and Scope do not affect Alpha weight")
	var primary_only: CardData = features.filter(func(card: CardData) -> bool: return card.secondary_stat.is_empty())[0]
	var primary_only_expected: float = snapshot[alpha.CORE_SCORE_BY_STAT[primary_only.primary_stat]] * primary_only.primary_value
	_expect(alpha.call("_calculate_candidate_weight", primary_only, snapshot) == primary_only_expected, "Missing secondary score contributes zero weight")
	var simple_story: CardData = features.filter(func(card: CardData) -> bool: return card.id == &"simple_story")[0]
	var enemies: CardData = features.filter(func(card: CardData) -> bool: return card.id == &"enemies")[0]
	var music: CardData = features.filter(func(card: CardData) -> bool: return card.id == &"music")[0]
	_expect(_approximately_equal(alpha.call("_calculate_feature_alpha_bug_pressure", simple_story), 2.0 / 18.0), "Simple Story contributes exactly 2/18 Alpha pressure")
	_expect(_approximately_equal(alpha.call("_calculate_feature_alpha_bug_pressure", enemies), 10.0 / 18.0), "Enemies contributes exactly 10/18 Alpha pressure")
	_expect(_approximately_equal(alpha.call("_calculate_feature_alpha_bug_pressure", music), 14.0 / 18.0), "Music contributes exactly 14/18 Alpha pressure")

	var boundary_entries: Array[Dictionary] = [
		{&"card": passes[0], &"weight": 10.0},
		{&"card": passes[1], &"weight": 20.0},
		{&"card": passes[2], &"weight": 30.0},
		{&"card": passes[3], &"weight": 40.0},
	]
	_expect(alpha.call("_select_weighted_entry", boundary_entries, 0.10) == passes[1], "Alpha exact cumulative boundary uses Design's following half-open interval")
	for index in range(4):
		var prior := 0.0
		for prior_index in range(index):
			prior += float(boundary_entries[prior_index].weight)
		var roll := (prior + float(boundary_entries[index].weight) * 0.5) / 100.0
		_expect(alpha.call("_select_weighted_entry", boundary_entries, roll) == passes[index], "Controlled Alpha roll selects interval %d" % index)

	var controlled_rolls: Array[float] = [0.0, 0.17, 0.34, 0.51, 0.68, 0.85, 0.99]
	var first_build: Dictionary = alpha.call("_build_weighted_candidate_definitions", snapshot, controlled_rolls)
	var reversed_features := features.duplicate()
	reversed_features.reverse()
	var reversed_passes := passes.duplicate()
	reversed_passes.reverse()
	alpha.set("_available_features", reversed_features)
	alpha.set("_pass_definitions", reversed_passes)
	var reordered_build: Dictionary = alpha.call("_build_weighted_candidate_definitions", snapshot, controlled_rolls)
	_expect(first_build.valid and reordered_build.valid and _card_ids(first_build.cards) == _card_ids(reordered_build.cards), "Lexical ID ordering makes controlled Alpha deals deterministic")
	alpha.set("_available_features", [] as Array[CardData])
	alpha.set("_pass_definitions", passes)
	var all_pass_build: Dictionary = alpha.call("_build_weighted_candidate_definitions", snapshot, [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0] as Array[float])
	_expect(all_pass_build.valid and all_pass_build.cards.size() == 7 and all_pass_build.cards.all(func(card: CardData) -> bool: return card == all_pass_build.cards[0]), "Pass definitions draw with replacement through seven distinct candidate slots")
	alpha.set("_available_features", features)
	var malformed := features.duplicate()
	malformed.append(features[0])
	alpha.set("_available_features", malformed)
	var invalid_build: Dictionary = alpha.call("_build_weighted_candidate_definitions", snapshot, controlled_rolls)
	_expect(not invalid_build.valid and alpha.get_node("%HandContainer").get_child_count() == 0, "Duplicate Feature input cannot produce a partial visible pool")
	alpha.set("_available_features", features)

	var invalid_rolls: Array[float] = [NAN, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	_expect(not alpha.begin_alpha(invalid_rolls), "A failed initial deal remains rejected")
	_expect(alpha.get("_phase_state") == AlphaPhase.PhaseState.PLANNING and alpha.get_node("%BeginAlphaButton").visible and alpha.get_node("%HandContainer").get_child_count() == 0, "Failed Begin Alpha stays in Planning with no partial pool")
	_expect(_state_snapshot(state) == state_before and value_emissions[0] == 0 and cycle_emissions[0] == 0, "Failed Alpha deal mutates no authoritative state or cycle")

	# Restore a known valid allocation; Begin snapshots this complete distribution once.
	for category: ProjectState.CoreScore in CATEGORIES:
		alpha.set_priority(category, 5)
	for category: ProjectState.CoreScore in CATEGORIES:
		alpha.set_priority(category, 25)
	var begin_snapshot := alpha.get_priority_distribution()
	var duplicate_pass_rolls: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	_expect(alpha.begin_alpha(duplicate_pass_rolls), "Begin Alpha builds one complete deterministic seven-candidate pool")
	_expect(not alpha.begin_alpha(duplicate_pass_rolls), "Begin Alpha can succeed only once")
	_expect(alpha.get("_phase_state") == AlphaPhase.PhaseState.ACTIVE_DEVELOPMENT and not alpha.get_node("%BeginAlphaButton").visible, "Successful Begin Alpha enters Active Development and retires its control")
	var candidates: Array = alpha.get("_candidate_cards")
	var views := alpha.get_node("%HandContainer").get_children()
	_expect(candidates.size() == 7 and views.size() == 7, "Begin Alpha creates exactly seven candidate CardViews")
	var drawn_feature_ids: Dictionary[StringName, bool] = {}
	var no_duplicate_features := true
	for card: CardData in candidates:
		if card.card_type == &"feature":
			no_duplicate_features = no_duplicate_features and not drawn_feature_ids.has(card.id)
			drawn_feature_ids[card.id] = true
	_expect(no_duplicate_features, "Alpha Features draw without replacement within a pool")
	_expect(views.all(func(view: CardView) -> bool: return view.size == Vector2(240, 336)), "All Alpha candidates retain 240x336 CardView bounds")
	_expect(views.any(func(view: CardView) -> bool: return view.department_label.visible), "Alpha CardViews display established Department labels")
	_expect(views.all(func(view: CardView) -> bool: return view.artwork_fallback.visible), "Missing Alpha artwork uses CardView's existing fallback")

	var candidate_ids := _instance_ids(views)
	for index in range(4):
		(views[index] as CardView).card_pressed.emit(views[index])
		if index < 3:
			_expect((alpha.get_node("%PlayAlphaHandButton") as Button).disabled, "Play Alpha Hand remains disabled with %d selections" % (index + 1))
	_expect(alpha.get_selected_candidate_count() == 4 and views.slice(0, 4).all(func(view: CardView) -> bool: return view.is_selected()), "Four Alpha candidate instances select independently with existing visuals")
	_expect(not (alpha.get_node("%PlayAlphaHandButton") as Button).disabled, "Play Alpha Hand enables with exactly four valid instances")
	_expect((views[2] as CardView).card_data == (views[3] as CardView).card_data and views[2] != views[3] and (views[2] as CardView).is_selected() and (views[3] as CardView).is_selected(), "Duplicate Pass draws create independently selectable CardViews")
	(views[4] as CardView).card_pressed.emit(views[4])
	_expect(alpha.get_selected_candidate_count() == 4 and not (views[4] as CardView).is_selected(), "A fifth Alpha selection preserves the original four")
	(views[0] as CardView).card_pressed.emit(views[0])
	_expect(alpha.get_selected_candidate_count() == 3 and not (views[0] as CardView).is_selected(), "Selected Alpha candidate toggles off independently")
	_expect((alpha.get_node("%PlayAlphaHandButton") as Button).disabled, "Deselecting one candidate disables Play Alpha Hand")
	(views[0] as CardView).card_pressed.emit(views[0])
	var selection_before: Array = alpha.get("_selected_card_views").duplicate()
	alpha.set_priority(ProjectState.CoreScore.SOUND, 5)
	_expect(_card_ids(alpha.get("_candidate_cards")) == _card_ids(candidates) and _instance_ids(alpha.get_node("%HandContainer").get_children()) == candidate_ids, "Post-deal slider changes do not alter candidate order or identity")
	_expect(alpha.get("_selected_card_views") == selection_before, "Post-deal slider changes preserve Alpha selection")
	_expect(begin_snapshot == {ProjectState.CoreScore.GRAPHICS: 25, ProjectState.CoreScore.SOUND: 25, ProjectState.CoreScore.TECHNOLOGY: 25, ProjectState.CoreScore.DESIGN: 25}, "Begin Alpha uses the intended deal-time priority snapshot")

	var malformed_card: CardData = (views[0] as CardView).card_data
	var printed_primary := malformed_card.primary_value
	malformed_card.primary_value = -1
	_expect(not alpha.host_playtest() and state.get_current_cycle() == 0 and alpha.get_pending_playtest_categories().is_empty(), "Malformed active Alpha pool rejects Host Playtest without spending a cycle or queuing corrective Passes")
	(alpha.get_node("%PlayAlphaHandButton") as Button).pressed.emit()
	malformed_card.primary_value = printed_primary
	_expect(_state_snapshot(state) == state_before and value_emissions[0] == 0 and cycle_emissions[0] == 0, "Malformed Alpha card resolves no scores, Scope, pressure, signal, or cycle")
	_expect(alpha.get("_candidate_cards").size() == 7 and alpha.get_selected_candidate_count() == 4 and not (alpha.get_node("%PlayAlphaHandButton") as Button).disabled, "Malformed resolution preserves the pool, four selections, and enabled action")

	var old_views := views.duplicate()
	(alpha.get_node("%PlayAlphaHandButton") as Button).pressed.emit()
	_expect(state.get_core_score(ProjectState.CoreScore.DESIGN) == 7 and state.get_core_score(ProjectState.CoreScore.TECHNOLOGY) == 1, "Alpha hand aggregates repeated printed primary and secondary production without synergy")
	_expect(state.get_core_score(ProjectState.CoreScore.GRAPHICS) == 0 and state.get_core_score(ProjectState.CoreScore.SOUND) == 0, "Unproduced Core Scores remain unchanged")
	_expect(state.get_current_scope() == 2, "Alpha Scope equals the exact printed Scope sum")
	_expect(_approximately_equal(state.get_accumulated_alpha_bug_pressure(), 4.0 / 18.0), "Multiple Alpha Features sum fractional pressure without per-Feature rounding")
	_expect(state.get_accumulated_bug_pressure() == 0.0, "Alpha production leaves accumulated Design Bug Pressure unchanged")
	_expect(state.get_hidden_bugs() == 0, "Alpha production leaves existing Hidden Bugs unchanged")
	_expect(value_emissions[0] == 1 and cycle_emissions[0] == 1 and state.get_current_cycle() == 1, "Successful Alpha transaction emits once and advances exactly one cycle")
	_expect(alpha.get_node("%AlphaBugPressureValue").text == "Alpha Bug Pressure: 0.22", "Alpha pressure display updates through values_changed at two decimals")
	_expect(_approximately_equal(state.get_accumulated_alpha_bug_pressure(), 4.0 / 18.0), "Display formatting preserves authoritative fractional precision")
	_expect(alpha.get("_exhausted_feature_ids").has(&"character_backstories") and alpha.get("_exhausted_feature_ids").has(&"controls"), "Selected Alpha Features exhaust only after success")
	_expect(not alpha.get("_available_features").any(func(card: CardData) -> bool: return card.id in [&"character_backstories", &"controls"]), "Exhausted Alpha Features leave the available pool")
	_expect(alpha.get("_available_features").any(func(card: CardData) -> bool: return card.id == &"simple_story"), "Unselected Alpha Features remain available")
	_expect(alpha.get("_candidate_cards").size() == 7 and alpha.get_node("%HandContainer").get_child_count() == 7 and alpha.get_selected_candidate_count() == 0, "Successful Alpha action clears selection and deals seven replacements")
	_expect(not alpha.get("_candidate_cards").any(func(card: CardData) -> bool: return alpha.get("_exhausted_feature_ids").has(card.id)), "Exhausted Alpha Features never enter the replacement pool")
	var after_first_action := _state_snapshot(state)
	(old_views[0] as CardView).card_pressed.emit(old_views[0])
	(alpha.get_node("%PlayAlphaHandButton") as Button).pressed.emit()
	_expect(_state_snapshot(state) == after_first_action, "Stale CardView and repeated Play activation cannot resolve again")

	alpha.call("_clear_candidate_pool")
	alpha.set("_available_features", [] as Array[CardData])
	_expect(alpha.call("_deal_next_candidate_pool", duplicate_pass_rolls), "Alpha can deal a seven-Pass pool after Features run out")
	var pass_views := alpha.get_node("%HandContainer").get_children()
	_expect(pass_views.size() == 7 and pass_views.all(func(view: CardView) -> bool: return view.card_data.card_type == &"pass"), "No-Feature Alpha pool contains seven renewable Pass instances")
	for index in range(4):
		(pass_views[index] as CardView).card_pressed.emit(pass_views[index])
	var pressure_before_passes := state.get_accumulated_alpha_bug_pressure()
	var pressure_text_before: String = alpha.get_node("%AlphaBugPressureValue").text
	(alpha.get_node("%PlayAlphaHandButton") as Button).pressed.emit()
	_expect(state.get_core_score(ProjectState.CoreScore.DESIGN) == 19, "Four matching Passes specialize their aggregated printed +8 to +12")
	_expect(state.get_current_scope() == 2 and _approximately_equal(state.get_accumulated_alpha_bug_pressure(), pressure_before_passes), "Pass-only Alpha hand adds zero Scope and exactly 0.0 pressure")
	_expect(alpha.get_node("%AlphaBugPressureValue").text == pressure_text_before, "Pass-only action leaves Alpha pressure display unchanged")
	_expect(alpha.get("_exhausted_feature_ids").size() == 2, "Passes never exhaust")
	_expect(state.get_current_cycle() == 2 and cycle_emissions[0] == 2 and value_emissions[0] == 2, "Second successful Alpha hand advances exactly one additional cycle and signal")


func _verify_alpha_specialization_resolution() -> void:
	var state := ProjectState.new(30)
	var alpha := ALPHA_PHASE_SCENE.instantiate() as AlphaPhase
	alpha.setup(state)
	root.add_child(alpha)
	await process_frame
	_expect(alpha.call("_load_source_definitions"), "Alpha Specialization fixture loads authoritative definitions")
	var features: Array = alpha.get("_available_features")
	var passes: Array = alpha.get("_pass_definitions")
	var design_features: Array[CardData] = []
	for id: StringName in [&"simple_story", &"dialogue", &"character_backstories", &"multiple_endings"]:
		design_features.append(features.filter(func(card: CardData) -> bool: return card.id == id)[0])
	var base_scores: Dictionary[ProjectState.CoreScore, int] = {
		ProjectState.CoreScore.DESIGN: 9,
		ProjectState.CoreScore.TECHNOLOGY: 2,
	}
	var specialized: Dictionary = alpha.call("_calculate_final_action_production", {
		&"cards": design_features,
		&"score_additions": base_scores,
	})
	_expect(specialized.specialization_stat == &"design", "Four same-primary Alpha Features qualify by primary Core Score")
	_expect(specialized.score_additions == {ProjectState.CoreScore.DESIGN: 14, ProjectState.CoreScore.TECHNOLOGY: 3}, "Specialization multiplies full primary and secondary aggregates then nearest-rounds per Core Score")
	_expect(alpha.call("_build_specialization_debug_message", specialized.specialization_stat, specialized.score_additions) == "Alpha Specialization hit: Design Specialization! Added scores: Technology +3, Design +14", "Alpha debug output identifies Specialization and final score additions")
	var rounding_cards: Array[CardData] = []
	for value in [1, 1, 1, 2]:
		var fixture := CardData.new()
		fixture.primary_stat = &"graphics"
		fixture.primary_value = value
		rounding_cards.append(fixture)
	var rounding_result: Dictionary = alpha.call("_calculate_final_action_production", {
		&"cards": rounding_cards,
		&"score_additions": {ProjectState.CoreScore.GRAPHICS: 5, ProjectState.CoreScore.SOUND: 1},
	})
	_expect(rounding_result.score_additions == {ProjectState.CoreScore.GRAPHICS: 8, ProjectState.CoreScore.SOUND: 2}, "Nearest rounding occurs after full-hand per-score aggregation, including a secondary aggregate")

	var design_pass: CardData = passes.filter(func(card: CardData) -> bool: return card.id == &"design_pass")[0]
	var sound_pass: CardData = passes.filter(func(card: CardData) -> bool: return card.id == &"sound_pass")[0]
	var with_matching_pass: Array[CardData] = [design_features[0], design_features[1], design_pass, design_pass]
	var matching_result: Dictionary = alpha.call("_calculate_final_action_production", {
		&"cards": with_matching_pass,
		&"score_additions": {ProjectState.CoreScore.DESIGN: 8},
	})
	_expect(matching_result.specialization_stat == &"design" and matching_result.score_additions[ProjectState.CoreScore.DESIGN] == 12, "Matching and duplicate Pass instances participate separately in Alpha Specialization")
	var mixed_cards: Array[CardData] = [design_features[0], design_features[1], design_pass, sound_pass]
	var mixed_scores: Dictionary[ProjectState.CoreScore, int] = {ProjectState.CoreScore.DESIGN: 6, ProjectState.CoreScore.SOUND: 2}
	var mixed_result: Dictionary = alpha.call("_calculate_final_action_production", {
		&"cards": mixed_cards,
		&"score_additions": mixed_scores,
	})
	_expect(mixed_result.specialization_stat.is_empty() and mixed_result.score_additions == mixed_scores, "A nonmatching Pass invalidates Specialization and preserves base aggregates")

	alpha.set("_phase_state", AlphaPhase.PhaseState.ACTIVE_DEVELOPMENT)
	_set_exact_candidates(alpha, design_features)
	var views := alpha.get_node("%HandContainer").get_children()
	for view: CardView in views:
		view.card_pressed.emit(view)
	var base_action: Dictionary = alpha.call("_validate_and_calculate_base_action")
	_expect(base_action.scope == 5 and _approximately_equal(base_action.alpha_bug_pressure, 16.0 / 18.0), "Specialized base action retains printed Scope and unmultiplied Alpha pressure")
	var value_emissions := [0]
	var cycle_emissions := [0]
	state.values_changed.connect(func() -> void: value_emissions[0] += 1)
	state.cycle_changed.connect(func() -> void: cycle_emissions[0] += 1)
	(alpha.get_node("%PlayAlphaHandButton") as Button).pressed.emit()
	_expect(state.get_core_score(ProjectState.CoreScore.DESIGN) == 14 and state.get_core_score(ProjectState.CoreScore.TECHNOLOGY) == 3, "Resolved same-primary Feature hand commits specialized primary and secondary totals")
	_expect(state.get_current_scope() == 5 and _approximately_equal(state.get_accumulated_alpha_bug_pressure(), 16.0 / 18.0), "Specialization changes neither Scope nor Alpha Bug Pressure")
	_expect(state.get_accumulated_bug_pressure() == 0.0 and state.get_hidden_bugs() == 0, "Alpha Specialization changes neither Design pressure nor Hidden Bugs")
	_expect(alpha.get_workspace().synergy_notification.banner.visible and alpha.get_workspace().synergy_notification.title_label.text == "Design Specialization!", "Successful Alpha specialization displays an in-game notification")
	_expect(alpha.get("_exhausted_feature_ids").size() == 4 and not alpha.get("_available_features").any(func(card: CardData) -> bool: return card.id in [&"simple_story", &"dialogue", &"character_backstories", &"multiple_endings"]), "Specialized Features exhaust through the existing lifecycle")
	_expect(state.get_current_cycle() == 1 and value_emissions[0] == 1 and cycle_emissions[0] == 1, "Specialized action commits atomically and advances exactly one cycle")
	_expect(alpha.get("_candidate_cards").size() == 7 and alpha.get_selected_candidate_count() == 0, "Specialized action preserves seven-card replacement and selection clearing")
	alpha.queue_free()
	await process_frame


func _verify_alpha_balanced_production_calculation() -> void:
	var graphics := ProjectState.CoreScore.GRAPHICS
	var sound := ProjectState.CoreScore.SOUND
	var technology := ProjectState.CoreScore.TECHNOLOGY
	var design := ProjectState.CoreScore.DESIGN
	var state := ProjectState.new(30)
	var alpha := ALPHA_PHASE_SCENE.instantiate() as AlphaPhase
	alpha.setup(state)
	root.add_child(alpha)
	await process_frame

	_expect(alpha.call("_are_core_scores_balanced", {graphics: 8, sound: 10, technology: 10, design: 12}), "Alpha Balanced uses inclusive exact 0.80A and 1.20A boundaries")
	_expect(not alpha.call("_are_core_scores_balanced", {graphics: 8, sound: 11, technology: 11, design: 11}), "A provisional score slightly below Alpha's lower boundary fails")
	_expect(not alpha.call("_are_core_scores_balanced", {graphics: 9, sound: 9, technology: 9, design: 12}), "A provisional score slightly above Alpha's upper boundary fails")

	var cards: Array[CardData] = [
		_make_fixture(&"balanced_graphics", &"feature", &"graphics", 3, &"sound", 1, 1),
		_make_fixture(&"balanced_sound", &"feature", &"sound", 2, &"graphics", 2, 1),
		_make_fixture(&"balanced_technology", &"feature", &"technology", 3, &"design", 2, 1),
		_make_fixture(&"balanced_sound_pass", &"pass", &"sound", 2, &"", 0, 0),
	]
	var base_scores: Dictionary[ProjectState.CoreScore, int] = {graphics: 5, sound: 5, technology: 3, design: 2}
	var qualifying_current: Dictionary[ProjectState.CoreScore, int] = {graphics: 3, sound: 3, technology: 5, design: 6}
	state.add_core_scores_and_scope(qualifying_current, 0)
	var qualifying: Dictionary = alpha.call("_calculate_final_action_production", {
		&"cards": cards,
		&"score_additions": base_scores,
	})
	_expect(qualifying.provisional_scores == {graphics: 8, sound: 8, technology: 8, design: 8}, "Alpha provisional totals include cumulative Design carryover plus unmodified current-action base production")
	_expect(qualifying.specialization_stat.is_empty() and qualifying.balanced_production, "A mixed Alpha Feature-and-Pass action activates Balanced Production from cumulative totals")
	_expect(qualifying.score_additions == {graphics: 6, sound: 6, technology: 4, design: 2}, "Alpha Balanced aggregates primary, secondary, and Pass production per Core Score before x1.20 nearest rounding")
	_expect(qualifying.score_additions[design] == 2 and qualifying.score_additions[technology] == 4, "Alpha Balanced nearest-rounds aggregate 2 to 2 and aggregate 3 to 4")
	_expect(alpha.call("_build_balanced_production_debug_message", qualifying.score_additions) == "Alpha Balanced Production hit! Added scores: Graphics +6, Sound +6, Technology +4, Design +2", "Alpha Balanced feedback identifies activation and deterministic final gains")

	var unbalanced_state := ProjectState.new(30)
	alpha.setup(unbalanced_state)
	var same_hand_unbalanced: Dictionary = alpha.call("_calculate_final_action_production", {
		&"cards": cards,
		&"score_additions": base_scores,
	})
	_expect(not same_hand_unbalanced.balanced_production and same_hand_unbalanced.score_additions == base_scores, "The same Alpha hand fails from different historical totals, proving the hand alone is not evaluated")

	alpha.setup(state)
	var reversed_cards := cards.duplicate()
	reversed_cards.reverse()
	var reversed_result: Dictionary = alpha.call("_calculate_final_action_production", {
		&"cards": reversed_cards,
		&"score_additions": base_scores,
	})
	_expect(reversed_result.balanced_production and reversed_result.score_additions == qualifying.score_additions, "Alpha Balanced qualification and reward are independent of selection order")

	var pass_only_cards: Array[CardData] = [
		_make_fixture(&"graphics_pass_fixture", &"pass", &"graphics", 2, &"", 0, 0),
		_make_fixture(&"sound_pass_fixture", &"pass", &"sound", 2, &"", 0, 0),
		_make_fixture(&"technology_pass_fixture", &"pass", &"technology", 2, &"", 0, 0),
		_make_fixture(&"design_pass_fixture", &"pass", &"design", 2, &"", 0, 0),
	]
	var pass_only: Dictionary = alpha.call("_calculate_final_action_production", {
		&"cards": pass_only_cards,
		&"score_additions": {graphics: 2, sound: 2, technology: 2, design: 2},
	})
	_expect(pass_only.specialization_stat.is_empty() and not pass_only.balanced_production and not pass_only.balanced_eligible, "A balanced all-Pass Alpha action cannot trigger Balanced Production")

	var matching_cards: Array[CardData] = [
		_make_fixture(&"both_1_a", &"feature", &"graphics", 1, &"sound", 1, 0),
		_make_fixture(&"both_1_b", &"feature", &"graphics", 1, &"", 0, 0),
		_make_fixture(&"both_1_c", &"feature", &"graphics", 1, &"", 0, 0),
		_make_fixture(&"both_2", &"feature", &"graphics", 2, &"", 0, 0),
	]
	var precedence_state := ProjectState.new(30)
	precedence_state.add_core_scores_and_scope({graphics: 0, sound: 4, technology: 5, design: 5}, 0)
	alpha.setup(precedence_state)
	var precedence: Dictionary = alpha.call("_calculate_final_action_production", {
		&"cards": matching_cards,
		&"score_additions": {graphics: 5, sound: 1},
	})
	_expect(precedence.balanced_eligible and precedence.provisional_scores == {graphics: 5, sound: 5, technology: 5, design: 5}, "Alpha Balanced eligibility uses unmodified base production even when Specialization also qualifies")
	_expect(precedence.specialization_stat == &"graphics" and not precedence.balanced_production, "Alpha Specialization takes precedence over an eligible Balanced result")
	_expect(precedence.score_additions == {graphics: 8, sound: 2}, "Alpha precedence applies only x1.50, never stacked x1.80 or sequential multipliers")
	_expect(alpha.call("_build_specialization_debug_message", precedence.specialization_stat, precedence.score_additions) == "Alpha Specialization hit: Graphics Specialization! Added scores: Graphics +8, Sound +2", "Precedence feedback reports Specialization as the applied winner")

	alpha.queue_free()
	await process_frame


func _verify_alpha_balanced_production_resolution() -> void:
	var state := ProjectState.new(30)
	var alpha := ALPHA_PHASE_SCENE.instantiate() as AlphaPhase
	alpha.setup(state)
	root.add_child(alpha)
	await process_frame
	_expect(alpha.call("_load_source_definitions"), "Alpha Balanced lifecycle fixture loads authoritative definitions")
	var features: Array[CardData] = []
	var used_primary_stats: Dictionary[StringName, bool] = {}
	for card: CardData in alpha.get("_available_features"):
		if not used_primary_stats.has(card.primary_stat):
			features.append(card)
			used_primary_stats[card.primary_stat] = true
		if features.size() == 3:
			break
	var pass_card: CardData = alpha.get("_pass_definitions")[0]
	var cards: Array[CardData] = [features[0], features[1], features[2], pass_card]
	alpha.set("_phase_state", AlphaPhase.PhaseState.ACTIVE_DEVELOPMENT)
	_set_exact_candidates(alpha, cards)
	for view: CardView in alpha.get_node("%HandContainer").get_children():
		view.card_pressed.emit(view)
	var base_action: Dictionary = alpha.call("_validate_and_calculate_base_action")
	_expect(base_action.valid and base_action.cards.size() == 4, "Alpha Balanced lifecycle action validates four current candidate instances")
	var target := 10
	for category: ProjectState.CoreScore in CATEGORIES:
		target = maxi(target, base_action.score_additions.get(category, 0) + 5)
	var historical_scores: Dictionary[ProjectState.CoreScore, int] = {}
	for category: ProjectState.CoreScore in CATEGORIES:
		historical_scores[category] = target - base_action.score_additions.get(category, 0)
	_expect(state.add_core_scores_and_scope(historical_scores, 0, 1.25), "Alpha Balanced fixture seeds cumulative Design-era project scores and Design Bug Pressure")
	_expect(state.finalize_design_bugs(false, 7, [&"text"] as Array[StringName], [] as Array[StringName]), "Alpha Balanced fixture stores existing finalized Hidden Bugs")
	var expected_additions: Dictionary[ProjectState.CoreScore, int] = {}
	for category: ProjectState.CoreScore in CATEGORIES:
		expected_additions[category] = roundi(base_action.score_additions.get(category, 0) * AlphaPhase.ALPHA_BALANCED_PRODUCTION_MULTIPLIER)
	var final_action: Dictionary = alpha.call("_calculate_final_action_production", base_action)
	_expect(final_action.specialization_stat.is_empty() and final_action.balanced_production, "Balanced Production is the winning synergy for the controlled Alpha lifecycle action")
	_expect(final_action.provisional_scores.values().all(func(value: int) -> bool: return value == target), "Earlier project production participates in the real Alpha provisional balance test")
	var design_pressure_before := state.get_accumulated_bug_pressure()
	var hidden_bugs_before := state.get_hidden_bugs()
	var available_before: Array = alpha.get("_available_features").duplicate()
	var values_emitted := [0]
	var cycles_emitted := [0]
	state.values_changed.connect(func() -> void: values_emitted[0] += 1)
	state.cycle_changed.connect(func() -> void: cycles_emitted[0] += 1)
	(alpha.get_node("%PlayAlphaHandButton") as Button).pressed.emit()
	for category: ProjectState.CoreScore in CATEGORIES:
		_expect(state.get_core_score(category) == historical_scores[category] + expected_additions[category], "Alpha Balanced commits the expected final %s aggregate" % ProjectState.CoreScore.keys()[category].capitalize())
	_expect(state.get_current_scope() == base_action.scope, "Alpha Balanced leaves printed Scope unchanged")
	_expect(_approximately_equal(state.get_accumulated_alpha_bug_pressure(), base_action.alpha_bug_pressure), "Alpha Balanced leaves printed-value fractional Alpha Bug Pressure unchanged")
	_expect(_approximately_equal(state.get_accumulated_bug_pressure(), design_pressure_before) and state.get_hidden_bugs() == hidden_bugs_before, "Alpha Balanced changes neither Design Bug Pressure nor finalized Hidden Bugs")
	_expect(values_emitted[0] == 1 and cycles_emitted[0] == 1 and state.get_current_cycle() == 1, "Alpha Balanced commits atomically and advances exactly one cycle")
	for feature: CardData in features:
		_expect(alpha.get("_exhausted_feature_ids").has(feature.id) and not alpha.get("_available_features").has(feature), "Played Alpha Balanced Feature exhausts: %s" % feature.id)
	_expect(not alpha.get("_exhausted_feature_ids").has(pass_card.id), "Played Alpha Balanced Pass remains renewable")
	_expect(available_before.any(func(card: CardData) -> bool: return card not in features and alpha.get("_available_features").has(card)), "An unselected Alpha Feature remains available after Balanced resolution")
	_expect(alpha.get("_candidate_cards").size() == 7 and alpha.get_node("%HandContainer").get_child_count() == 7 and alpha.get_selected_candidate_count() == 0, "Alpha Balanced preserves seven weighted replacements and clears selection")
	var after_success := _state_snapshot(state)
	(alpha.get_node("%PlayAlphaHandButton") as Button).pressed.emit()
	_expect(_state_snapshot(state) == after_success, "Repeated Alpha Balanced resolution is stale-safe and changes nothing")

	alpha.queue_free()
	await process_frame


func _verify_host_playtest() -> void:
	var graphics := ProjectState.CoreScore.GRAPHICS
	var sound := ProjectState.CoreScore.SOUND
	var technology := ProjectState.CoreScore.TECHNOLOGY
	var design := ProjectState.CoreScore.DESIGN
	var state := ProjectState.new(30)
	var alpha := ALPHA_PHASE_SCENE.instantiate() as AlphaPhase
	alpha.setup(state)
	root.add_child(alpha)
	await process_frame
	var planning_state := _state_snapshot(state)
	_expect(not alpha.host_playtest(), "Host Playtest rejects Planning activation")
	_expect(_state_snapshot(state) == planning_state and alpha.get_pending_playtest_categories().is_empty(), "Rejected Planning Playtest consumes no cycle and queues nothing")

	_expect(state.add_alpha_production({graphics: 10, sound: 5, technology: 7, design: 5}, 0, 0.0), "Playtest fixture seeds authoritative cumulative Design carryover scores")
	for category: ProjectState.CoreScore in CATEGORIES:
		alpha.set_priority(category, 5)
	alpha.set_priority(graphics, 20)
	alpha.set_priority(sound, 20)
	alpha.set_priority(technology, 20)
	alpha.set_priority(design, 40)
	var priorities_at_playtest := alpha.get_priority_distribution()
	_expect(alpha.begin_alpha([0.11, 0.23, 0.37, 0.49, 0.61, 0.73, 0.89] as Array[float]), "Host Playtest fixture enters Active Development with seven candidates")
	var views := alpha.get_node("%HandContainer").get_children()
	for index in range(4):
		(views[index] as CardView).card_pressed.emit(views[index])
	var candidate_ids_before := _instance_ids(views)
	var candidate_cards_before: Array = alpha.get("_candidate_cards").duplicate()
	var selections_before: Array = alpha.get("_selected_card_views").duplicate()
	var exhaustion_before: Dictionary = alpha.get("_exhausted_feature_ids").duplicate()
	var production_before := _production_state_snapshot(state)
	var cycle_before := state.get_current_cycle()
	var play_enabled_before: bool = not (alpha.get_node("%PlayAlphaHandButton") as Button).disabled
	_expect(alpha.host_playtest(), "Host Playtest succeeds during valid Active Development without requiring a separate hand")
	_expect(state.get_current_cycle() == cycle_before + 1, "Successful Host Playtest advances exactly one authoritative cycle")
	_expect(_production_state_snapshot(state) == production_before, "Host Playtest produces no scores, Scope, Bug Pressure, Hidden Bugs, or finalization changes")
	_expect(alpha.get_pending_playtest_categories() == [design, sound], "Two lowest scores use higher Alpha priority to queue Design then Sound")
	_expect(_instance_ids(alpha.get_node("%HandContainer").get_children()) == candidate_ids_before and alpha.get("_candidate_cards") == candidate_cards_before, "Host Playtest preserves visible candidate identity and order")
	_expect(alpha.get("_selected_card_views") == selections_before and not (alpha.get_node("%PlayAlphaHandButton") as Button).disabled == play_enabled_before, "Host Playtest preserves selection and Play Hand availability")
	_expect(alpha.get("_exhausted_feature_ids") == exhaustion_before and alpha.get_priority_distribution() == priorities_at_playtest, "Host Playtest preserves Feature lifecycle and priorities")
	_expect(alpha.get_node("%HostPlaytestButton").disabled and alpha.get_node("%HostPlaytestButton").text == "Playtest Pending", "Pending Playtest state is exposed through the existing action-button boundary")
	_expect(alpha.call("_format_corrective_pass_names", alpha.get_pending_playtest_categories()) == "Design Pass, Sound Pass", "Host Playtest feedback names queued Passes deterministically")

	alpha.set_priority(design, 5)
	alpha.set_priority(sound, 50)
	state.add_alpha_production({graphics: 20, sound: 30}, 0, 0.0)
	_expect(alpha.get_pending_playtest_categories() == [design, sound], "Queued corrective categories are snapshots unaffected by later priority and score changes")
	var pending_cycle := state.get_current_cycle()
	_expect(not alpha.host_playtest() and state.get_current_cycle() == pending_cycle and alpha.get_pending_playtest_categories() == [design, sound], "A pending Playtest rejects stacking without spending a cycle or replacing its snapshot")
	(views[0] as CardView).card_pressed.emit(views[0])
	var incomplete_state := _state_snapshot(state)
	(alpha.get_node("%PlayAlphaHandButton") as Button).pressed.emit()
	_expect(_state_snapshot(state) == incomplete_state and alpha.get_pending_playtest_categories() == [design, sound], "Incomplete Alpha production does not consume a pending Playtest")
	(views[0] as CardView).card_pressed.emit(views[0])

	var saved_features: Array = alpha.get("_available_features").duplicate()
	alpha.set("_available_features", [] as Array[CardData])
	var five_rolls: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
	var weighted_five: Dictionary = alpha.call("_build_weighted_candidate_definitions", alpha.get_priority_distribution(), five_rolls, 5)
	var corrective_build: Dictionary = alpha.call("_build_corrective_candidate_definitions", alpha.get_priority_distribution(), five_rolls)
	alpha.set("_available_features", saved_features)
	var design_pass: CardData = alpha.call("_get_pass_for_category", design)
	var sound_pass: CardData = alpha.call("_get_pass_for_category", sound)
	_expect(corrective_build.valid and corrective_build.cards.size() == 7 and corrective_build.cards[0] == design_pass and corrective_build.cards[1] == sound_pass, "Corrective construction prepends the two queued public Pass definitions")
	_expect(corrective_build.cards.slice(2) == weighted_five.cards, "Corrective construction fills exactly five remaining slots in existing weighted draw order")
	_expect(corrective_build.cards.slice(2).has(design_pass), "A guaranteed Pass definition remains eligible for an ordinary weighted duplicate")

	var production_cycle_before := state.get_current_cycle()
	(alpha.get_node("%PlayAlphaHandButton") as Button).pressed.emit()
	_expect(state.get_current_cycle() == production_cycle_before + 1, "The successful production hand advances one additional cycle while injection advances none")
	_expect(alpha.get("_candidate_cards").size() == 7 and alpha.get_node("%HandContainer").get_child_count() == 7, "The corrective replacement publishes exactly seven candidates")
	_expect(alpha.get("_candidate_cards")[0] == design_pass and alpha.get("_candidate_cards")[1] == sound_pass, "The first two replacement candidates match the queued corrective order")
	var replacement_views := alpha.get_node("%HandContainer").get_children()
	_expect(replacement_views[0] != replacement_views[1] and (replacement_views[0] as CardView).card_data == design_pass and (replacement_views[1] as CardView).card_data == sound_pass, "Injected Passes are distinct CardView candidate instances")
	_expect(design_pass.renewable and sound_pass.renewable and design_pass.primary_value == 2 and sound_pass.primary_value == 2 and design_pass.scope == 0 and sound_pass.scope == 0, "Injected Passes retain ordinary renewable +2, zero-Scope definitions")
	_expect(alpha.get_pending_playtest_categories().is_empty() and not alpha.get_node("%HostPlaytestButton").disabled and alpha.get_node("%HostPlaytestButton").text == "Host Playtest", "Successful complete corrective deal consumes pending state and re-enables Playtest")
	(replacement_views[0] as CardView).card_pressed.emit(replacement_views[0])
	(replacement_views[1] as CardView).card_pressed.emit(replacement_views[1])
	_expect(alpha.get_selected_candidate_count() == 2 and (replacement_views[0] as CardView).is_selected() and (replacement_views[1] as CardView).is_selected(), "Injected Pass candidate instances select independently through normal CardView behavior")
	var injected_specialization: Dictionary = alpha.call("_calculate_final_action_production", {
		&"cards": [design_pass, design_pass, design_pass, design_pass] as Array[CardData],
		&"score_additions": {design: 8},
	})
	_expect(injected_specialization.specialization_stat == &"design" and injected_specialization.score_additions[design] == 12, "Injected Pass definitions participate normally in Alpha Specialization")
	var balanced_state := ProjectState.new(30)
	balanced_state.add_alpha_production({graphics: 3, sound: 3, technology: 5, design: 6}, 0, 0.0)
	alpha.setup(balanced_state)
	var balanced_cards: Array[CardData] = [
		_make_fixture(&"playtest_graphics", &"feature", &"graphics", 3, &"sound", 1, 1),
		_make_fixture(&"playtest_sound", &"feature", &"sound", 2, &"graphics", 2, 1),
		_make_fixture(&"playtest_technology", &"feature", &"technology", 3, &"design", 2, 1),
		sound_pass,
	]
	var injected_balanced: Dictionary = alpha.call("_calculate_final_action_production", {
		&"cards": balanced_cards,
		&"score_additions": {graphics: 5, sound: 5, technology: 3, design: 2},
	})
	_expect(injected_balanced.balanced_production and injected_balanced.score_additions == {graphics: 6, sound: 6, technology: 4, design: 2}, "Injected Pass definitions participate normally in Alpha Balanced Production")

	alpha.queue_free()
	await process_frame


func _verify_host_playtest_replacement_failure() -> void:
	var state := ProjectState.new(30)
	var alpha := ALPHA_PHASE_SCENE.instantiate() as AlphaPhase
	alpha.setup(state)
	root.add_child(alpha)
	await process_frame
	_expect(alpha.call("_load_source_definitions"), "Playtest replacement-failure fixture loads Alpha sources")
	var features: Array = alpha.get("_available_features")
	var passes: Array = alpha.get("_pass_definitions")
	alpha.set("_phase_state", AlphaPhase.PhaseState.ACTIVE_DEVELOPMENT)
	var candidates: Array[CardData] = [features[0], features[1], features[2], features[3], passes[0], passes[1], passes[2]]
	_set_exact_candidates(alpha, candidates)
	for index in range(4):
		var view := alpha.get_node("%HandContainer").get_child(index) as CardView
		view.card_pressed.emit(view)
	_expect(alpha.host_playtest() and alpha.get_pending_playtest_categories() == [ProjectState.CoreScore.GRAPHICS, ProjectState.CoreScore.SOUND], "Equal score and priority ties queue Graphics then Sound through fixed Core order")
	alpha.set("_pass_definitions", passes.slice(0, 3))
	(alpha.get_node("%PlayAlphaHandButton") as Button).pressed.emit()
	_expect(state.get_current_cycle() == 2 and state.get_current_scope() > 0 and state.get_accumulated_alpha_bug_pressure() > 0.0, "Failed corrective replacement preserves committed production plus Playtest and production cycles")
	_expect(alpha.get("_exhausted_feature_ids").size() == 4, "Failed corrective replacement preserves committed Feature exhaustion")
	_expect(alpha.get("_candidate_cards").is_empty() and alpha.get_node("%HandContainer").get_child_count() == 0, "Failed corrective replacement publishes no partial pool")
	_expect(alpha.get_pending_playtest_categories() == [ProjectState.CoreScore.GRAPHICS, ProjectState.CoreScore.SOUND], "Failed corrective replacement preserves the queued Playtest snapshot")
	var cycle_after_failure := state.get_current_cycle()
	_expect(not alpha.host_playtest() and state.get_current_cycle() == cycle_after_failure, "Invalid empty-pool state cannot spend another Playtest cycle")

	alpha.queue_free()
	await process_frame


func _make_fixture(id: StringName, card_type: StringName, primary_stat: StringName, primary_value: int, secondary_stat: StringName, secondary_value: int, scope: int) -> CardData:
	var card := CardData.new()
	card.id = id
	card.card_type = card_type
	card.primary_stat = primary_stat
	card.primary_value = primary_value
	card.secondary_stat = secondary_stat
	card.secondary_value = secondary_value
	card.scope = scope
	card.renewable = card_type == &"pass"
	return card


func _card_ids(cards: Array) -> Array[StringName]:
	var ids: Array[StringName] = []
	for card: CardData in cards:
		ids.append(card.id)
	return ids


func _verify_post_hand_redeal_failure() -> void:
	var state := ProjectState.new(30)
	var alpha := ALPHA_PHASE_SCENE.instantiate() as AlphaPhase
	alpha.setup(state)
	root.add_child(alpha)
	await process_frame
	_expect(alpha.call("_load_source_definitions"), "Post-hand failure fixture loads Alpha sources")
	var features: Array = alpha.get("_available_features")
	var passes: Array = alpha.get("_pass_definitions")
	alpha.set("_phase_state", AlphaPhase.PhaseState.ACTIVE_DEVELOPMENT)
	_set_exact_candidates(alpha, [features[0], features[1], features[2], features[3]] as Array[CardData])
	var views := alpha.get_node("%HandContainer").get_children()
	for view: CardView in views:
		view.card_pressed.emit(view)
	alpha.set("_pass_definitions", passes.slice(0, 3))
	(alpha.get_node("%PlayAlphaHandButton") as Button).pressed.emit()
	_expect(state.get_current_cycle() == 1 and state.get_current_scope() > 0 and state.get_accumulated_alpha_bug_pressure() > 0.0, "Post-hand redeal failure preserves committed Alpha production and one cycle")
	_expect(alpha.get("_exhausted_feature_ids").size() == 4, "Post-hand redeal failure preserves committed Feature exhaustion")
	_expect(alpha.get("_candidate_cards").is_empty() and alpha.get_node("%HandContainer").get_child_count() == 0, "Post-hand redeal failure leaves a safe empty pool without rollback")
	alpha.queue_free()
	await process_frame


func _set_exact_candidates(alpha: AlphaPhase, cards: Array[CardData]) -> void:
	alpha.call("_clear_candidate_pool")
	alpha.set("_candidate_cards", cards.duplicate())
	for card: CardData in cards:
		var view := CARD_VIEW_SCENE.instantiate() as CardView
		view.set_card(card)
		view.card_pressed.connect(Callable(alpha, "_on_card_pressed"))
		alpha.get_node("%HandContainer").add_child(view)


func _instance_ids(views: Array) -> Array[int]:
	var ids: Array[int] = []
	for view: CardView in views:
		ids.append(view.get_instance_id())
	return ids


func _verify_controls(alpha: AlphaPhase) -> void:
	for node_name: StringName in [&"GraphicsPriority", &"SoundPriority", &"TechnologyPriority", &"DesignPriority"]:
		var slider := alpha.get_node("%%%s" % node_name) as VSlider
		_expect(slider != null and slider.min_value == 5.0 and slider.max_value == 50.0 and slider.step == 5.0, "%s uses 5-50 bounds in five-point steps" % node_name)
	var panel := alpha.get_node("PriorityOverlay/ModalBlocker/PriorityDialog/Content/PriorityPanel") as PanelContainer
	_expect(panel.size.x <= 1008.0 and panel.size.y <= 463.0, "Corrected Alpha allocation panel fits the established phase bounds")
	_verify_distribution(alpha, "Initial Alpha allocation uses the complete budget")
	_verify_control_values(alpha)


func _verify_control_values(alpha: AlphaPhase) -> void:
	var values := _values(alpha)
	var sliders := [alpha.get_node("%GraphicsPriority"), alpha.get_node("%SoundPriority"), alpha.get_node("%TechnologyPriority"), alpha.get_node("%DesignPriority")]
	var labels := [alpha.get_node("%GraphicsPriorityValue"), alpha.get_node("%SoundPriorityValue"), alpha.get_node("%TechnologyPriorityValue"), alpha.get_node("%DesignPriorityValue")]
	for index in range(CATEGORIES.size()):
		_expect(int(sliders[index].value) == values[index] and labels[index].text == str(values[index]), "Alpha slider and allocation label %d match internal state" % index)
	_expect(alpha.get_node("%AvailablePriority").text == "Available Priority: %d" % alpha.get_available_priority(), "Alpha available-priority label derives from allocation state")


func _verify_distribution(alpha: AlphaPhase, description: String) -> void:
	var distribution := alpha.get_priority_distribution()
	var total := 0
	var valid := distribution.size() == CATEGORIES.size()
	for category: ProjectState.CoreScore in CATEGORIES:
		var value: int = distribution.get(category, 0)
		total += value
		valid = valid and value >= 5 and value <= 50 and value % 5 == 0
	_expect(valid and total <= 100 and alpha.get_available_priority() == 100 - total, description)


func _values(alpha: AlphaPhase) -> Array[int]:
	return [alpha.get_priority(ProjectState.CoreScore.GRAPHICS), alpha.get_priority(ProjectState.CoreScore.SOUND), alpha.get_priority(ProjectState.CoreScore.TECHNOLOGY), alpha.get_priority(ProjectState.CoreScore.DESIGN)]


func _state_snapshot(state: ProjectState) -> Array:
	return [state.get_core_score(ProjectState.CoreScore.GRAPHICS), state.get_core_score(ProjectState.CoreScore.SOUND), state.get_core_score(ProjectState.CoreScore.TECHNOLOGY), state.get_core_score(ProjectState.CoreScore.DESIGN), state.get_current_scope(), state.get_required_scope(), state.get_accumulated_bug_pressure(), state.get_accumulated_alpha_bug_pressure(), state.get_current_cycle(), state.was_perfect_production(), state.get_hidden_bugs(), state.get_implemented_design_feature_ids(), state.get_unimplemented_design_feature_ids()]


func _production_state_snapshot(state: ProjectState) -> Array:
	var snapshot := _state_snapshot(state)
	snapshot.remove_at(8)
	return snapshot


func _approximately_equal(a: float, b: float) -> bool:
	return absf(a - b) <= 0.000001


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
		return
	_failures += 1
	push_error("FAIL: %s" % description)


func _finish() -> void:
	if _failures == 0:
		print("Alpha priority verification passed.")
	quit(_failures)
