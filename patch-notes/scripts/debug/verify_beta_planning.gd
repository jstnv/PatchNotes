## Focused Beta planning, weighted candidate, and selection verification.
## Run with: godot --headless --path . --script res://scripts/debug/verify_beta_planning.gd
extends SceneTree

const BETA_SCENE := preload("res://scenes/phases/beta_phase.tscn")
const CARD_DATABASE_SCRIPT := preload("res://scripts/cards/card_database.gd")
const CARD_VIEW_SCENE := preload("res://scenes/cards/card_view.tscn")

var _failures := 0
var _database: Node


func _initialize() -> void:
	_database = CARD_DATABASE_SCRIPT.new()
	_database.name = "CardDatabase"
	root.add_child(_database)
	await process_frame
	_verify_priority_allocator()
	_verify_weight_boundaries()
	await _verify_planning_and_begin()
	await _verify_finite_depletion_and_display()
	_finish()


func _verify_priority_allocator() -> void:
	var allocation := BetaPriorityAllocation.new()
	var defaults := allocation.get_distribution()
	_expect(defaults == _distribution(35, 35, 30), "Beta priorities default independently to QA 35, Marketing 35, Insider 30")
	defaults[CardData.BETA_CATEGORY_QA] = 5
	_expect(allocation.get_priority(CardData.BETA_CATEGORY_QA) == 35, "Priority getter returns a defensive distribution copy")
	var emissions := [0]
	allocation.allocation_changed.connect(func() -> void: emissions[0] += 1)
	_expect(allocation.set_distribution(_distribution(50, 25, 25)), "Exact-total step-aligned Beta allocation is accepted")
	_expect(emissions[0] == 1 and allocation.get_distribution() == _distribution(50, 25, 25), "Valid allocation commits atomically and emits once")
	for invalid: Dictionary in [
		_distribution(35, 35, 25), _distribution(55, 25, 20), _distribution(0, 50, 50),
		_distribution(34, 36, 30), {CardData.BETA_CATEGORY_QA: 35.0, CardData.BETA_CATEGORY_MARKETING: 35, CardData.BETA_CATEGORY_INSIDER: 30},
		{CardData.BETA_CATEGORY_QA: NAN, CardData.BETA_CATEGORY_MARKETING: 35, CardData.BETA_CATEGORY_INSIDER: 30},
		{CardData.BETA_CATEGORY_QA: "35", CardData.BETA_CATEGORY_MARKETING: 35, CardData.BETA_CATEGORY_INSIDER: 30},
		{CardData.BETA_CATEGORY_QA: null, CardData.BETA_CATEGORY_MARKETING: 35, CardData.BETA_CATEGORY_INSIDER: 30},
		{CardData.BETA_CATEGORY_QA: true, CardData.BETA_CATEGORY_MARKETING: 35, CardData.BETA_CATEGORY_INSIDER: 30},
		{CardData.BETA_CATEGORY_QA: [], CardData.BETA_CATEGORY_MARKETING: 35, CardData.BETA_CATEGORY_INSIDER: 30},
	]:
		var before := allocation.get_distribution()
		var emissions_before: int = emissions[0]
		_expect(not allocation.set_distribution(invalid), "Malformed Beta allocation rejects")
		_expect(allocation.get_distribution() == before and emissions[0] == emissions_before, "Rejected allocation mutates nothing and emits nothing")


func _verify_weight_boundaries() -> void:
	var beta := BETA_SCENE.instantiate() as BetaPhase
	root.add_child(beta)
	var categories: Array[Dictionary] = [
		{&"value": CardData.BETA_CATEGORY_QA, &"weight": 35},
		{&"value": CardData.BETA_CATEGORY_MARKETING, &"weight": 35},
		{&"value": CardData.BETA_CATEGORY_INSIDER, &"weight": 30},
	]
	_expect(beta.call("_select_weighted_value", categories, 0.0) == CardData.BETA_CATEGORY_QA, "Category roll starts in QA's 35% interval")
	_expect(beta.call("_select_weighted_value", categories, 0.35) == CardData.BETA_CATEGORY_MARKETING, "Exact 35% boundary belongs to Marketing")
	_expect(beta.call("_select_weighted_value", categories, 0.70) == CardData.BETA_CATEGORY_INSIDER, "Exact 70% boundary belongs to Insider")
	_expect(beta.call("_select_weighted_value", categories, 0.999999) == CardData.BETA_CATEGORY_INSIDER, "Final category absorbs residual error")
	var debug := _database.get_card(&"debug") as CardData
	var search := _database.get_card(&"search_for_bugs") as CardData
	var qa_entries: Array[Dictionary] = [{&"value": debug, &"weight": 2}, {&"value": search, &"weight": 1}]
	_expect(beta.call("_select_weighted_value", qa_entries, 0.0) == debug and beta.call("_select_weighted_value", qa_entries, 2.0 / 3.0) == search, "QA uses Debug 2 to Search 1 half-open weighting")
	var definitions: Array[CardData] = _database.get_cards_by_phase(CardData.PHASE_BETA)
	var same_category_rolls: Array[float] = [0.4, 0.4, 0.4, 0.4, 0.4, 0.4, 0.4]
	var same_definition_rolls: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	var default_deal: Dictionary = beta.call("_build_candidate_definitions", definitions, _distribution(35, 35, 30), same_category_rolls, same_definition_rolls)
	var qa_biased_deal: Dictionary = beta.call("_build_candidate_definitions", definitions, _distribution(50, 25, 25), same_category_rolls, same_definition_rolls)
	_expect((default_deal.cards[0] as CardData).beta_category == CardData.BETA_CATEGORY_MARKETING and (qa_biased_deal.cards[0] as CardData).beta_category == CardData.BETA_CATEGORY_QA, "Increasing QA priority expands QA's category interval without using card values or counts")
	var incomplete: Array[CardData] = definitions.slice(0, 8)
	_expect(not str(beta.call("_get_source_validation_error", incomplete)).is_empty(), "Incomplete Beta definitions reject before pool construction")
	beta.queue_free()


func _verify_planning_and_begin() -> void:
	var state := _make_finalized_state(4, 2)
	state.discover_bugs(2)
	var before := _state_snapshot(state)
	var beta := BETA_SCENE.instantiate() as BetaPhase
	root.add_child(beta)
	await process_frame
	_expect(beta.setup(state), "Beta accepts the finalized shared ProjectState")
	_expect(beta.get("_phase_state") == BetaPhase.PhaseState.PLANNING, "Beta enters Planning")
	_expect((beta.get_node("%HandContainer") as Container).get_child_count() == 0 and beta.get_selected_candidate_count() == 0, "Planning shows no candidates and has no selection")
	_expect((beta.get_node("%KnownBugsLabel") as Label).text == "Known Bugs: 2", "Planning displays Known Bugs")
	_expect(_conceals_bug_state(beta), "Planning conceals Hidden and Remaining Bugs and pressure")
	var foreign := CARD_VIEW_SCENE.instantiate() as CardView
	beta.call("_on_card_pressed", foreign)
	_expect(beta.get_selected_candidate_count() == 0, "Planning rejects foreign candidate selection")
	foreign.free()
	beta.call("_update_priority_draft", CardData.BETA_CATEGORY_QA, 30.0)
	_expect(not beta.begin_beta(), "Begin rejects an allocation not totaling 100")
	_expect(beta.get("_phase_state") == BetaPhase.PhaseState.PLANNING and beta.get_node("%HandContainer").get_child_count() == 0, "Failed Begin leaves Planning with no partial pool")
	_expect(_state_snapshot(state) == before, "Failed Begin mutates no project or Bug state")
	beta.call("_update_priority_draft", CardData.BETA_CATEGORY_QA, 35.0)
	var category_rolls: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	var definition_rolls: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	_expect(beta.begin_beta(category_rolls, definition_rolls), "Valid Begin publishes the complete controlled pool")
	_expect(beta.get("_phase_state") == BetaPhase.PhaseState.ACTIVE_DEVELOPMENT and beta.get_node("%HandContainer").get_child_count() == 7, "Begin enters Active Development with exactly seven views")
	var cards: Array = beta.get("_candidate_cards")
	_expect(cards.all(func(card: CardData) -> bool: return card.id == &"debug"), "Renewable Debug can fill all seven QA slots with replacement")
	var views: Array = beta.get("_candidate_views")
	var instance_ids := {}
	for view: CardView in views:
		instance_ids[view.get_instance_id()] = true
	_expect(instance_ids.size() == 7, "Duplicate definitions have seven distinct candidate-instance identities")
	_expect(_state_snapshot(state) == before, "Begin and dealing consume zero cycles and preserve all project and Bug state")
	for index in range(4):
		beta.call("_on_card_pressed", views[index])
	_expect(beta.get_selected_candidate_count() == 4 and views.slice(0, 4).all(func(view: CardView) -> bool: return view.is_selected()), "Four duplicate-definition instances select independently")
	beta.call("_on_card_pressed", views[4])
	_expect(beta.get_selected_candidate_count() == 4 and not views[4].is_selected(), "Fifth selection rejects without disturbing the existing four")
	beta.call("_on_card_pressed", views[1])
	_expect(beta.get_selected_candidate_count() == 3 and not views[1].is_selected(), "Selected instance toggles off without reordering candidates")
	var selected_copy := beta.get_selected_candidate_views()
	selected_copy.clear()
	_expect(beta.get_selected_candidate_count() == 3, "Selected-candidate query returns a defensive array")
	var order_before: Array = views.map(func(view: CardView) -> int: return view.get_instance_id())
	_expect(beta.set_priority_distribution(_distribution(50, 25, 25)), "Valid Active priority redistribution commits")
	var order_after: Array = (beta.get("_candidate_views") as Array).map(func(view: CardView) -> int: return view.get_instance_id())
	_expect(order_after == order_before and beta.get_selected_candidate_count() == 3, "Active priority edits neither reroll nor reset selection")
	_expect(not beta.begin_beta(category_rolls, definition_rolls) and beta.get_node("%HandContainer").get_child_count() == 7, "Repeated Begin cannot create another pool")
	_expect(_state_snapshot(state) == before, "Selection, deselection, priority editing, and repeated Begin consume zero cycles and mutate no project state")
	beta.setup(state)
	_expect(beta.get_node("%HandContainer").get_child_count() == 7 and beta.get_selected_candidate_count() == 3, "Repeated setup reconstructs display without duplicating or resetting local pool state")
	beta.queue_free()
	await process_frame


func _verify_finite_depletion_and_display() -> void:
	var state := _make_finalized_state(0, 0)
	var beta := BETA_SCENE.instantiate() as BetaPhase
	root.add_child(beta)
	await process_frame
	beta.setup(state)
	var category_rolls: Array[float] = [0.9, 0.9, 0.9, 0.9, 0.9, 0.9, 0.9]
	var definition_rolls: Array[float] = [0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0.3]
	_expect(beta.begin_beta(category_rolls, definition_rolls), "Finite-depletion controlled deal succeeds by renormalizing remaining categories")
	var cards: Array = beta.get("_candidate_cards")
	var first_three_ids: Array = cards.slice(0, 3).map(func(card: CardData) -> StringName: return card.id)
	_expect(first_three_ids == [&"playtest_rival_games", &"predict_market_trends", &"study_competition"], "Insider finite definitions draw without replacement in controlled order")
	_expect(cards.slice(3).all(func(card: CardData) -> bool: return card.beta_category != CardData.BETA_CATEGORY_INSIDER), "Empty Insider category receives zero weight for remaining slots")
	var finite_ids: Array = cards.filter(func(card: CardData) -> bool: return not card.renewable).map(func(card: CardData) -> StringName: return card.id)
	var unique_finite_ids := {}
	for id: StringName in finite_ids:
		unique_finite_ids[id] = true
	_expect(unique_finite_ids.size() == finite_ids.size(), "Finite definitions appear at most once within one pool")
	var later_deal: Dictionary = beta.call("_build_candidate_definitions", _database.get_cards_by_phase(CardData.PHASE_BETA), _distribution(35, 35, 30), category_rolls, definition_rolls)
	_expect(later_deal.valid and (later_deal.cards[0] as CardData).id == &"playtest_rival_games", "Dealing and selection do not exhaust finite definitions for a later pool")
	var views: Array = beta.get("_candidate_views")
	for view: CardView in views:
		var card := view.card_data
		_expect((view.get_node("%CardName") as Label).text == card.card_name, "Beta CardView shows its card name")
		_expect((view.get_node("%PrimaryScoreValue") as Label).text == "V%d" % card.beta_value, "Beta CardView shows printed Beta value without fake production")
		_expect((view.get_node("%PrimaryScoreType") as Label).text.to_lower() == str(card.beta_category), "Beta CardView shows category")
		_expect(not (view.get_node("%SecondaryScore") as Control).visible and not view.get_node("Scope").visible, "Beta CardView hides fake secondary production and Scope anatomy")
		_expect((view.get_node("%Department") as Label).text.contains("Finite") or (view.get_node("%Department") as Label).text.contains("Renewable"), "Beta CardView visibly states lifecycle")
	_expect(_state_snapshot(state)[0] == 0, "Finite dealing and display advance no cycle")
	beta.queue_free()
	await process_frame


func _distribution(qa: Variant, marketing: Variant, insider: Variant) -> Dictionary:
	return {CardData.BETA_CATEGORY_QA: qa, CardData.BETA_CATEGORY_MARKETING: marketing, CardData.BETA_CATEGORY_INSIDER: insider}


func _make_finalized_state(design_hidden: int, alpha_hidden: int) -> ProjectState:
	var state := ProjectState.new(30)
	state.finalize_design_bugs(false, design_hidden, [&"text"], [&"sprites"])
	state.finalize_alpha(alpha_hidden, [&"controls"], [&"enemies"])
	return state


func _state_snapshot(state: ProjectState) -> Array:
	return [state.get_current_cycle(), state.get_current_scope(), state.get_hidden_bugs(), state.get_known_bugs(), state.get_remaining_bugs(), state.get_accumulated_bug_pressure(), state.get_accumulated_alpha_bug_pressure(), state.get_implemented_design_feature_ids(), state.get_implemented_alpha_feature_ids()]


func _conceals_bug_state(beta: Node) -> bool:
	var text := ""
	for node: Node in _descendants(beta):
		if node is Label:
			text += " " + (node as Label).text.to_lower()
	return "hidden" not in text and "remaining" not in text and "pressure" not in text


func _descendants(node: Node) -> Array[Node]:
	var result: Array[Node] = [node]
	for child: Node in node.get_children():
		result.append_array(_descendants(child))
	return result


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: " + description)
	else:
		_failures += 1
		push_error("FAIL: " + description)


func _finish() -> void:
	if _failures == 0:
		print("Beta planning and selection verification passed.")
	quit(_failures)
