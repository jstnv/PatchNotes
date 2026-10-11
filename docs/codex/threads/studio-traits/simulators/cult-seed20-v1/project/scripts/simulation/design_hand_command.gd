## Scene-free Design hand command. Construct with explicit phase inventory and
## existing ProjectState/RunState. The caller owns planning/phase transitions.
## execute() is synchronous; presentation consumes its result after commit.
extends RefCounted

const ProductionHand := preload("res://scripts/simulation/production_hand.gd")
const WEIGHTED_CANDIDATE_MATH := preload("res://scripts/phases/weighted_candidate_math.gd")
const CANDIDATE_POOL_SIZE := 7
const SELECTED_HAND_SIZE := 4
const BUG_PRESSURE_DENOMINATOR := 18.0
const CORE_SCORE_BY_STAT := {&"graphics":0, &"sound":1, &"technology":2, &"design":3}
var _project_state: ProjectState
var _run_state: RunState
var _deal_rng: RandomNumberGenerator
var _available_features: Array[CardData] = []
var _pass_definitions: Array[CardData] = []
var _candidate_cards: Array[CardData] = []
var _exhausted_card_ids: Dictionary[StringName, bool] = {}
var priorities: Dictionary = {}
var candidate_ids: Array[int] = []
var next_candidate_id := 0
var revision := 0
var active := false
var finalization_requested := false
var _executing := false

func get_priority_distribution() -> Dictionary:
	return priorities.duplicate()

func _get_first_game_tutorial() -> FirstGameTutorial:
	return _run_state.get_first_game_tutorial(_project_state) if _run_state != null else null

func command(ids: Array[int], employee_priorities: Dictionary = {}) -> Dictionary:
	return {"schema_version":1, "type":&"play_design_hand", "project_id":_project_state.get_release_id(), "revision":revision, "project_cycle":_project_state.get_current_cycle(), "run_cycle":_run_state.get_completed_run_cycles() if _run_state != null else -1, "candidate_ids":ids.duplicate(), "employee_priorities":employee_priorities.duplicate()}

func reject(reason: String) -> Dictionary:
	return {"ok":false, "error":reason, "events":[]}

func execute(request: Dictionary) -> Dictionary:
	if _executing: return reject("Command already executing")
	_executing = true
	var result := _execute(request)
	_executing = false
	return result

func _execute(request: Dictionary) -> Dictionary:
	if request.get("schema_version") != 1 or request.get("type") != &"play_design_hand": return reject("Unsupported command")
	for field in ["schema_version", "revision", "project_cycle", "run_cycle"]:
		if typeof(request.get(field)) != TYPE_INT: return reject("Malformed command counters")
	if not active or finalization_requested or _project_state == null or _deal_rng == null or not _project_state.can_advance_cycle(): return reject("Design is not active")
	if request.get("project_id") != _project_state.get_release_id(): return reject("Wrong project")
	if _run_state != null and not _run_state.can_advance_calendar_cycle(): return reject("Calendar cannot advance")
	if request.get("revision", -1) != revision or request.get("project_cycle", -1) != _project_state.get_current_cycle() or request.get("run_cycle", -2) != (_run_state.get_completed_run_cycles() if _run_state != null else -1): return reject("Stale command")
	var ids: Variant = request.get("candidate_ids")
	if not ids is Array or ids.size() != SELECTED_HAND_SIZE or candidate_ids.size() != _candidate_cards.size(): return reject("Select four current instances")
	var selected: Array[CardData] = []
	var seen := {}
	var selected_features := {}
	for id in ids:
		if not id is int or seen.has(id) or not candidate_ids.has(id): return reject("Duplicate or stale candidate")
		seen[id] = true
		var card := _candidate_cards[candidate_ids.find(id)]
		if card == null or _exhausted_card_ids.has(card.id): return reject("Unavailable candidate")
		if card.card_type not in [&"feature", &"pass"] or not _get_weighted_definition_validation_error(card, card.card_type).is_empty(): return reject("Illegal Design candidate")
		if card.card_type == &"feature":
			if selected_features.has(card.id): return reject("Duplicate finite Feature")
			selected_features[card.id] = true
		selected.append(card)
	var base_hand := calculate_base(selected)
	if not base_hand.valid: return reject("Invalid production")
	var employee_priorities: Variant = request.get("employee_priorities", {})
	if not employee_priorities is Dictionary: return reject("Invalid employee choice")
	var play_cost := 0
	if _run_state != null:
		play_cost = _run_state.primitive_feature_hand_cost_cents(selected, _project_state.get_release_id())
		if play_cost < 0 or _run_state.get_cash_cents() < play_cost: return reject("Unaffordable hand")
	var lean_before := int(_run_state.get_lean_savings().get(_project_state.get_release_id(), 0)) if _run_state != null else 0
	var normal_cost := _run_state.primitive_feature_hand_cost_cents(selected) if _run_state != null else 0
	var lean_saving := normal_cost - play_cost
	var employee_plan := {}
	if _run_state != null:
		employee_plan = _run_state.plan_employee_hand(_project_state, &"design", selected, priorities, employee_priorities)
		if employee_plan.is_empty(): return reject("Employee plan rejected")
	elif not employee_priorities.is_empty(): return reject("No employee roster")
	var refill_priorities: Dictionary = employee_priorities if not employee_priorities.is_empty() else priorities
	var records: Array = []
	for card in selected: records.append({&"primary_stat":card.primary_stat})
	var final_action := ProductionHand.calculate(records, base_hand.score_additions, base_hand.has_feature)
	if not final_action.specialization_stat.is_empty():
		for category in ProjectState.CoreScore.values():
			if not final_action.score_additions.has(category): final_action.score_additions[category] = 0
	var streams_before := _run_state.random_streams.snapshot() if _run_state != null else {}
	var rng_before := _deal_rng.state
	var retained: Array[CardData] = []
	var retained_ids: Array[int] = []
	for index in range(candidate_ids.size()):
		if candidate_ids[index] not in ids:
			retained.append(_candidate_cards[index])
			retained_ids.append(candidate_ids[index])
	var tutorial := _get_first_game_tutorial()
	var refill: Dictionary
	if tutorial != null and tutorial.stage == FirstGameTutorial.Stage.FIRST_HAND:
		var costs := {}
		for card in _available_features: costs[card.id] = _run_state.primitive_feature_hand_cost_cents([card] as Array[CardData], _project_state.get_release_id())
		refill = tutorial.plan_deal(_available_features, _pass_definitions, refill_priorities, _run_state.get_cash_cents()-play_cost, costs, _deal_rng, retained, true)
	else:
		refill = _build_weighted_candidate_definitions(refill_priorities, [], SELECTED_HAND_SIZE)
	if not refill.get("valid", false):
		_deal_rng.state = rng_before
		return reject("Refill rejected")
	var events: Array[Dictionary] = []
	var additions: Dictionary[ProjectState.CoreScore, int] = final_action.score_additions
	var commit := func() -> bool:
		if _run_state != null and (not _run_state.can_commit_employee_hand(employee_plan) or int(_run_state.get_lean_savings().get(_project_state.get_release_id(), 0)) != lean_before): return false
		if not _project_state.add_core_scores_and_scope(additions, base_hand.scope, base_hand.bug_pressure): return false
		events.append({"type":"production", "scores":additions.duplicate(), "scope":base_hand.scope, "bug_pressure":base_hand.bug_pressure})
		if not employee_priorities.is_empty(): priorities = employee_priorities.duplicate()
		if _run_state != null:
			_run_state.commit_employee_hand(employee_plan)
			_run_state.commit_lean_saving(_project_state.get_release_id(), lean_before, lean_saving)
		for card in selected:
			if card.card_type == &"feature" and not card.renewable:
				_exhausted_card_ids[card.id] = true
				if _run_state != null: _run_state.record_resolved_feature(_project_state, card.id, CardData.PHASE_DESIGN)
				events.append({"type":"feature_exhausted", "id":card.id})
		_candidate_cards.assign(retained)
		candidate_ids.assign(retained_ids)
		if tutorial != null: tutorial.record_successful_hand()
		_project_state.advance_cycle()
		events.append({"type":"project_cycle", "cycle":_project_state.get_current_cycle()})
		return true
	if not (_run_state.complete_productive_action(commit, -play_cost, request.run_cycle, &"", &"feature_play", _project_state.get_release_id()) if _run_state != null else commit.call()):
		_deal_rng.state = rng_before
		return reject("Productive transaction rejected")
	if _run_state != null: events.append({"type":"productive_cycle", "cycle":_run_state.get_completed_run_cycles(), "cash_cents":_run_state.get_cash_cents(), "play_cost_cents":play_cost})
	for card in refill.cards:
		_candidate_cards.append(card)
		candidate_ids.append(next_candidate_id)
		next_candidate_id += 1
	for card in refill.selected_features: _available_features.erase(card)
	if refill.has("tutorial_stat"): tutorial.record_deal(refill.tutorial_stat)
	revision += 1
	events.append({"type":"refill", "candidate_ids":candidate_ids.duplicate()})
	return {"ok":true, "events":events, "base_hand":base_hand, "final_action":final_action, "refill":refill, "rng_before":rng_before, "rng_after":_deal_rng.state, "streams_before":streams_before, "streams_after":_run_state.random_streams.snapshot() if _run_state != null else {}}


func calculate_base(cards: Array[CardData]) -> Dictionary:
	for card in cards:
		if card == null: return _invalid_base_hand("Null card")
		var validation_error := _get_card_validation_error(card)
		if not validation_error.is_empty(): return _invalid_base_hand(validation_error)

	var score_additions: Dictionary[ProjectState.CoreScore, int] = {}
	var contributions: Array[Dictionary] = []
	var total_scope := 0
	var action_bug_pressure := 0.0
	var has_feature := false
	for card in cards:
		var primary_category: ProjectState.CoreScore = CORE_SCORE_BY_STAT[card.primary_stat]
		var contribution := {
			&"primary_category": primary_category,
			&"primary_value": card.primary_value,
			&"has_secondary": not card.secondary_stat.is_empty(),
			&"secondary_category": ProjectState.CoreScore.GRAPHICS,
			&"secondary_value": card.secondary_value,
		}
		score_additions[primary_category] = score_additions.get(primary_category, 0) + card.primary_value
		total_scope += card.scope
		has_feature = has_feature or card.card_type == &"feature"

		if contribution.has_secondary:
			var secondary_category: ProjectState.CoreScore = CORE_SCORE_BY_STAT[card.secondary_stat]
			contribution.secondary_category = secondary_category
			score_additions[secondary_category] = score_additions.get(secondary_category, 0) + card.secondary_value
		contributions.append(contribution)
		if card.card_type == &"feature":
			action_bug_pressure += _calculate_feature_bug_pressure(card)

	return {
		&"valid": true,
		&"cards": cards,
		&"score_additions": score_additions,
		&"scope": total_scope,
		&"bug_pressure": action_bug_pressure,
		&"has_feature": has_feature,
		&"contributions": contributions,
	}


func _build_weighted_candidate_definitions(priority_snapshot: Dictionary, controlled_rolls: Array[float] = [], candidate_count: int = CANDIDATE_POOL_SIZE) -> Dictionary:
	var validation_error := _get_deal_input_validation_error(priority_snapshot)
	if not validation_error.is_empty():
		return {&"valid": false, &"error": validation_error}
	if not controlled_rolls.is_empty() and controlled_rolls.size() != candidate_count:
		return {&"valid": false, &"error": "Controlled deal must match the number of new candidates."}
	for roll: float in controlled_rolls:
		if not is_finite(roll) or roll < 0.0 or roll >= 1.0:
			return {&"valid": false, &"error": "Weighted deal rolls must be finite values in [0, 1)."}
	var tutorial := _get_first_game_tutorial()
	if candidate_count == CANDIDATE_POOL_SIZE and tutorial != null and tutorial.needs_scripted_deal():
		var costs: Dictionary = {}
		for card: CardData in _available_features:
			costs[card.id] = _run_state.primitive_feature_hand_cost_cents([card] as Array[CardData], _project_state.get_release_id())
		var guided := tutorial.plan_deal(_available_features, _pass_definitions, priority_snapshot, _run_state.get_cash_cents(), costs, _deal_rng)
		return guided if not guided.is_empty() else {&"valid": false, &"error": "Could not prepare the first-game guided pool."}

	var remaining_features: Array[CardData] = _available_features.duplicate()
	var selected_cards: Array[CardData] = []
	var selected_features: Array[CardData] = []
	for slot in range(candidate_count):
		var entries: Array[Dictionary] = []
		for card: CardData in remaining_features + _pass_definitions:
			var weight := _calculate_candidate_weight(card, priority_snapshot)
			if not is_finite(weight) or weight < 0.0:
				return {&"valid": false, &"error": "Candidate '%s' produced an invalid weight." % card.id}
			if weight > 0.0:
				entries.append({&"card": card, &"weight": weight})
		entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.card.id) < str(b.card.id))
		var roll := controlled_rolls[slot] if not controlled_rolls.is_empty() else _deal_rng.randf()
		var selected := _select_weighted_entry(entries, roll)
		if selected == null:
			return {&"valid": false, &"error": "Slot %d had no positive finite selectable weight." % (slot + 1)}
		selected_cards.append(selected)
		if selected.card_type == &"feature":
			selected_features.append(selected)
			remaining_features.erase(selected)
	return {&"valid": true, &"cards": selected_cards, &"selected_features": selected_features}


func _select_weighted_entry(entries: Array[Dictionary], roll: float) -> CardData:
	return WEIGHTED_CANDIDATE_MATH.select_weighted_entry(entries, roll)


func _calculate_candidate_weight(card: CardData, priority_snapshot: Dictionary) -> float:
	return WEIGHTED_CANDIDATE_MATH.calculate_printed_score_weight(card, priority_snapshot, CORE_SCORE_BY_STAT)


func _get_deal_input_validation_error(priority_snapshot: Dictionary) -> String:
	if priority_snapshot.size() != PriorityAllocation.CORE_CATEGORIES.size():
		return "Priority snapshot must contain all four Core categories."
	var priority_total := 0
	for category: ProjectState.CoreScore in PriorityAllocation.CORE_CATEGORIES:
		if not priority_snapshot.has(category) or typeof(priority_snapshot[category]) != TYPE_INT:
			return "Priority snapshot contains a missing or malformed category."
		var value: int = priority_snapshot[category]
		if value < PriorityAllocation.MIN_PRIORITY or value > PriorityAllocation.MAX_PRIORITY or value % PriorityAllocation.PRIORITY_STEP != 0:
			return "Priority snapshot contains an out-of-range or non-step value."
		priority_total += value
	if priority_total > PriorityAllocation.MAX_TOTAL_PRIORITY:
		return "Priority snapshot exceeds the allocation budget."

	var feature_ids: Dictionary[StringName, bool] = {}
	for card: CardData in _available_features:
		var error := _get_weighted_definition_validation_error(card, &"feature")
		if not error.is_empty():
			return error
		if feature_ids.has(card.id):
			return "Available Design Feature IDs must be unique: %s" % card.id
		if _exhausted_card_ids.has(card.id):
			return "Exhausted Design Feature cannot remain available: %s" % card.id
		feature_ids[card.id] = true
	if _pass_definitions.size() != 4:
		return "Weighted Design dealing requires exactly four Core Pass definitions."
	var pass_categories: Dictionary[ProjectState.CoreScore, bool] = {}
	var pass_ids: Dictionary[StringName, bool] = {}
	for card: CardData in _pass_definitions:
		var error := _get_weighted_definition_validation_error(card, &"pass")
		if not error.is_empty():
			return error
		var category: ProjectState.CoreScore = CORE_SCORE_BY_STAT[card.primary_stat]
		if pass_categories.has(category) or pass_ids.has(card.id):
			return "Weighted Design dealing requires one Pass per Core category."
		pass_categories[category] = true
		pass_ids[card.id] = true
	return ""


func _get_weighted_definition_validation_error(card: CardData, expected_type: StringName) -> String:
	if card == null or card.id.is_empty():
		return "Weighted candidate definitions require stable nonempty IDs."
	if card.phase != CardData.PHASE_DESIGN or card.card_type != expected_type:
		return "Candidate '%s' has an invalid Design phase or type." % card.id
	if (expected_type == &"feature" and card.renewable) or (expected_type == &"pass" and not card.renewable):
		return "Candidate '%s' has invalid renewability." % card.id
	var production_error := _get_card_validation_error(card)
	if not production_error.is_empty():
		return production_error
	if expected_type == &"pass" and (not card.secondary_stat.is_empty() or card.secondary_value != 0):
		return "Core Pass '%s' cannot have a secondary weighted score." % card.id
	return ""


func _calculate_feature_bug_pressure(card: CardData) -> float:
	var total_printed_raw_score := card.primary_value
	if not card.secondary_stat.is_empty():
		total_printed_raw_score += card.secondary_value
	return (float(total_printed_raw_score) * float(card.scope)) / BUG_PRESSURE_DENOMINATOR


func _get_card_validation_error(card: CardData) -> String:
	if card.primary_stat.is_empty():
		return "Card '%s' has no primary stat." % card.id
	if not CORE_SCORE_BY_STAT.has(card.primary_stat):
		return "Card '%s' has an invalid primary stat: %s" % [card.id, card.primary_stat]
	if card.primary_value < 0:
		return "Card '%s' has a negative primary value." % card.id
	if card.scope < 0:
		return "Card '%s' has negative Scope." % card.id
	if card.secondary_stat.is_empty():
		if card.secondary_value != 0:
			return "Card '%s' has a secondary value without a secondary stat." % card.id
		return ""
	if not CORE_SCORE_BY_STAT.has(card.secondary_stat):
		return "Card '%s' has an invalid secondary stat: %s" % [card.id, card.secondary_stat]
	if card.secondary_value < 0:
		return "Card '%s' has a negative secondary value." % card.id
	return ""


func _invalid_base_hand(message: String) -> Dictionary:
	push_warning(message)
	return {
		&"valid": false,
		&"cards": [] as Array[CardData],
		&"score_additions": {},
		&"scope": 0,
		&"bug_pressure": 0.0,
		&"has_feature": false,
		&"contributions": [] as Array[Dictionary],
	}
