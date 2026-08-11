## Separately invoked Design Phase verification.
## Run with: godot --headless --path . --script res://scripts/debug/verify_design_phase.gd
extends SceneTree

const GAMEPLAY_SCENE := preload("res://scenes/gameplay.tscn")
const CARD_DATABASE_SCRIPT := preload("res://scripts/cards/card_database.gd")
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
	var gameplay := GAMEPLAY_SCENE.instantiate()
	root.add_child(gameplay)
	await process_frame
	await process_frame
	var design_phase := gameplay.get_node("%PhaseRoot").get_child(0)
	_verify_initial_state(design_phase, gameplay.project_state)
	_verify_selection(design_phase, gameplay.project_state)
	_verify_pool_compositions(design_phase, gameplay.project_state, database)
	_verify_specialization_calculation(design_phase)
	_verify_specialized_success(design_phase)
	var failed_state := _reset_project_state(design_phase)
	_verify_atomic_failure(design_phase, failed_state, database)
	var base_state := _reset_project_state(design_phase)
	_verify_atomic_success(design_phase, base_state, database)
	_verify_pass_only_hand(design_phase, base_state, database)
	_finish()


func _verify_ledger(database: Node) -> void:
	_expect(database.call(&"get_card_count") == 31, "Exactly 31 definitions load")
	var design_cards: Array = database.call(&"get_cards_by_phase", CardData.PHASE_DESIGN)
	var alpha_cards: Array = database.call(&"get_cards_by_phase", CardData.PHASE_ALPHA)
	_expect(design_cards.size() == 17, "Design eligibility contains 17 definitions")
	_expect(alpha_cards.size() == 14, "Alpha eligibility remains 14 definitions")
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
	_expect(design_phase.get("_candidate_cards").size() == 7, "Initial candidate pool has seven instances")
	_expect(design_phase.get_node("%HandContainer").get_child_count() == 7, "Seven CardViews are visible")
	_verify_candidate_pool(design_phase, 7, 0, "Initial seven-Feature pool")
	var views := design_phase.get_node("%HandContainer").get_children()
	for index in range(views.size()):
		var view := views[index] as CardView
		_expect(view.size == Vector2(240, 336), "Candidate %d retains 240x336 bounds" % (index + 1))
		if index > 0:
			var previous := views[index - 1] as CardView
			_expect(previous.get_rect().intersection(view.get_rect()).get_area() == 0.0, "Candidate %d does not overlap its neighbor" % (index + 1))
	var candidate_scroll := design_phase.get_node("PhaseLayout/CandidateScroll") as ScrollContainer
	_expect(candidate_scroll.size.x >= 1008.0 and candidate_scroll.get_h_scroll_bar().max_value > candidate_scroll.size.x, "Horizontal scrolling keeps all seven candidates accessible")
	_expect(design_phase.get_node("%PlayCardButton").text == "Play Hand", "Play control names the complete hand action")


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
	_verify_candidate_pool(design_phase, 7, 0, "Seven Features")
	_set_pool(design_phase, features.slice(0, 5))
	_verify_candidate_pool(design_phase, 5, 2, "Five Features")
	_set_pool(design_phase, features.slice(0, 3))
	_verify_candidate_pool(design_phase, 3, 4, "Three Features")
	_set_pool(design_phase, [])
	_verify_candidate_pool(design_phase, 0, 7, "No Features")
	var pass_views := design_phase.get_node("%HandContainer").get_children()
	(pass_views[0] as CardView).set_card(database.call(&"get_card", &"graphics_pass"))
	(pass_views[1] as CardView).set_card(database.call(&"get_card", &"graphics_pass"))
	design_phase.get("_candidate_cards")[0] = (pass_views[0] as CardView).card_data
	design_phase.get("_candidate_cards")[1] = (pass_views[1] as CardView).card_data
	_expect(pass_views[0] != pass_views[1] and (pass_views[0] as CardView).card_data == (pass_views[1] as CardView).card_data, "Duplicate Pass definitions use distinct runtime CardView instances")
	_expect(project_state.get_current_cycle() == 0, "Controlled dealing consumes no time")


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
	_expect(specialized.score_additions[ProjectState.CoreScore.GRAPHICS] == 27, "Primary +2, +3, +5, and +7 round individually to +3, +5, +8, and +11")
	_expect(specialized.score_additions[ProjectState.CoreScore.TECHNOLOGY] == 14 and specialized.score_additions[ProjectState.CoreScore.SOUND] == 5 and specialized.score_additions[ProjectState.CoreScore.DESIGN] == 8, "Differing valid secondary stats neither invalidate the trigger nor miss per-card rounding")
	_expect(specialized.scope == 10, "Specialization leaves Scope as the exact unmodified sum")

	var reversed_cards := graphics_cards.duplicate()
	reversed_cards.reverse()
	var reversed := _calculate_hand(design_phase, reversed_cards)
	_expect(reversed.specialization_stat == specialized.specialization_stat and reversed.score_additions == specialized.score_additions and reversed.scope == specialized.scope, "Selection order does not change Specialization or its result")

	var sound_card := _make_fixture(&"sound_fixture", &"sound", 2, &"technology", 2, 0)
	var three_one: Array[CardData] = [graphics_cards[0], graphics_cards[1], graphics_cards[2], sound_card]
	_expect(_calculate_hand(design_phase, three_one).specialization_stat.is_empty(), "A 3-1 primary-stat split does not trigger")
	var two_two: Array[CardData] = [graphics_cards[0], graphics_cards[1], sound_card, _make_fixture(&"sound_fixture_2", &"sound", 3, &"technology", 3, 0)]
	_expect(_calculate_hand(design_phase, two_two).specialization_stat.is_empty(), "A 2-2 primary-stat split does not trigger")

	var matching_secondaries: Array[CardData] = [
		_make_fixture(&"mixed_graphics", &"graphics", 2, &"design", 2, 0),
		_make_fixture(&"mixed_sound", &"sound", 2, &"design", 2, 0),
		_make_fixture(&"mixed_technology", &"technology", 2, &"design", 2, 0),
		_make_fixture(&"mixed_design", &"design", 2, &"design", 2, 0),
	]
	var secondary_only := _calculate_hand(design_phase, matching_secondaries)
	_expect(secondary_only.specialization_stat.is_empty(), "Matching secondary stats alone do not trigger Specialization")
	_expect(secondary_only.score_additions[ProjectState.CoreScore.DESIGN] == 10, "Nonspecialized mixed hand resolves unmodified primary and secondary scores")


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
	_expect(_values(project_state) == [27, 5, 14, 8, 10], "Specialized hand commits its final adjusted aggregate")
	_expect(emissions[0] == 1, "Specialized hand emits values_changed exactly once")
	_expect(project_state.get_current_cycle() == 1, "Specialization adds no extra cycles")
	for card in cards:
		_expect(design_phase.get("_exhausted_card_ids").has(card.id), "Successful specialized Feature exhausts once: %s" % card.id)


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
	var cycle_before := project_state.get_current_cycle()
	var old_views := design_phase.get_node("%HandContainer").get_children()
	(design_phase.get_node("%PlayCardButton") as Button).pressed.emit()
	_expect(_values(project_state) == before, "Malformed specialized hand applies no base score, bonus, or Scope")
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
	_expect(_values(project_state) == [7, 0, 4, 5, 4], "Four cards aggregate primary, secondary, repeated score, and Scope correctly")
	_expect(emissions[0] == 1, "Complete hand commits through one values_changed emission")
	_expect(project_state.get_current_cycle() == 1, "Complete four-card hand advances exactly one cycle")
	_expect(design_phase.get("_exhausted_card_ids").has(&"split_screen") and design_phase.get("_exhausted_card_ids").has(&"text"), "Every selected Feature is exhausted")
	_expect(not design_phase.get("_exhausted_card_ids").has(&"graphics_pass"), "Pass definitions are never exhausted")
	var retained_features: Array = design_phase.get("_available_features").duplicate()
	retained_features.append_array(design_phase.get("_candidate_cards"))
	_expect(retained_features.has(database.call(&"get_card", &"sprites")), "Unselected Feature remains available or is redealt")
	_expect(design_phase.get("_selected_card_views").is_empty() and (design_phase.get_node("%PlayCardButton") as Button).disabled, "Successful play clears selections and disables Play")
	_expect(design_phase.get_node("%HandContainer").get_child_count() == 7, "Successful play deals seven new candidates")
	(old_views[0] as CardView).card_pressed.emit(old_views[0])
	(design_phase.get_node("%PlayCardButton") as Button).pressed.emit()
	_expect(project_state.get_current_cycle() == 1 and _values(project_state) == [7, 0, 4, 5, 4], "Stale activation cannot replay the previous hand")


func _verify_pass_only_hand(design_phase: Node, project_state: ProjectState, database: Node) -> void:
	var graphics_pass: CardData = database.call(&"get_card", &"graphics_pass")
	var cards: Array[CardData] = [graphics_pass, graphics_pass, graphics_pass, graphics_pass, graphics_pass, graphics_pass, graphics_pass]
	_set_exact_candidates(design_phase, cards)
	_select_first(design_phase, 4)
	var scope_before := project_state.get_current_scope()
	(design_phase.get_node("%PlayCardButton") as Button).pressed.emit()
	_expect(project_state.get_core_score(ProjectState.CoreScore.GRAPHICS) == 19, "Four matching +2 Pass instances trigger Specialization and contribute +12")
	_expect(project_state.get_current_scope() == scope_before, "Pass-only hand adds 0 Scope")
	_expect(project_state.get_current_cycle() == 2, "Pass-only hand advances one cycle; two hands equal one month")
	_verify_candidate_pool(design_phase, 0, 7, "Post-play no-Feature pool")
	_expect(not design_phase.get("_exhausted_card_ids").has(&"graphics_pass"), "Specialized Passes do not exhaust")


func _calculate_hand(design_phase: Node, cards: Array[CardData]) -> Dictionary:
	_set_exact_candidates(design_phase, cards)
	_select_first(design_phase, 4)
	return design_phase.call("_validate_and_aggregate_selected_hand")


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


func _finish() -> void:
	if _failures == 0:
		print("DesignPhase verification passed.")
	quit(_failures)
