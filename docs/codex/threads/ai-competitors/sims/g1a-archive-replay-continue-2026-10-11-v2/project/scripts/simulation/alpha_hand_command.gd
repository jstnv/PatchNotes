## Scene-free Alpha hand command. Construct with explicit phase inventory and
## existing ProjectState/RunState. The caller owns planning/phase transitions.
## execute() is synchronous; presentation consumes its result after commit.
extends RefCounted

const ProductionHand := preload("res://scripts/simulation/production_hand.gd")
const WEIGHTED_CANDIDATE_MATH := preload("res://scripts/phases/weighted_candidate_math.gd")
const CANDIDATE_POOL_SIZE := 7
const SELECTED_HAND_SIZE := 4
const ALPHA_BUG_PRESSURE_DENOMINATOR := 18.0
const CORE_SCORE_BY_STAT := {&"graphics":0, &"sound":1, &"technology":2, &"design":3}
const ALPHA_DEPARTMENTS: Array[StringName] = [&"story", &"gameplay", &"world_design", &"audio"]
var _pending_playtest_categories: Array[ProjectState.CoreScore] = []
var _project_state: ProjectState
var _run_state: RunState
var _deal_rng: RandomNumberGenerator
var _available_features: Array[CardData] = []
var _pass_definitions: Array[CardData] = []
var _candidate_cards: Array[CardData] = []
var _exhausted_feature_ids: Dictionary[StringName, bool] = {}
var priorities: Dictionary = {}
var candidate_ids: Array[int] = []
var next_candidate_id := 0
var revision := 0
var active := false
var _executing := false

func get_priority_distribution() -> Dictionary:
	return priorities.duplicate()

func command(ids: Array[int], employee_priorities: Dictionary = {}) -> Dictionary:
	return {"schema_version":1, "type":&"play_alpha_hand", "project_id":_project_state.get_release_id(), "revision":revision, "project_cycle":_project_state.get_current_cycle(), "run_cycle":_run_state.get_completed_run_cycles() if _run_state != null else -1, "candidate_ids":ids.duplicate(), "employee_priorities":employee_priorities.duplicate()}

func reject(reason: String) -> Dictionary:
	return {"ok":false, "error":reason, "events":[]}

func execute(request: Dictionary) -> Dictionary:
	if _executing: return reject("Command already executing")
	_executing = true
	var result := _execute(request)
	_executing = false
	return result

func _execute(request: Dictionary) -> Dictionary:
	if request.get("schema_version") != 1 or request.get("type") != &"play_alpha_hand": return reject("Unsupported command")
	for field in ["schema_version", "revision", "project_cycle", "run_cycle"]:
		if typeof(request.get(field)) != TYPE_INT: return reject("Malformed command counters")
	if not active or _project_state == null or _deal_rng == null or not _project_state.can_advance_cycle(): return reject("Alpha is not active")
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
		if card == null or _exhausted_feature_ids.has(card.id): return reject("Unavailable candidate")
		if card.card_type == &"feature":
			if not _get_feature_validation_error(card).is_empty() or not _available_features.has(card): return reject("Illegal Alpha Feature")
			if selected_features.has(card.id): return reject("Duplicate finite Feature")
			selected_features[card.id] = true
		elif card.card_type == &"pass":
			if not _get_pass_validation_error(card).is_empty() or not _pass_definitions.has(card): return reject("Unauthorized Alpha Pass")
		else: return reject("Illegal Alpha candidate")
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
		employee_plan = _run_state.plan_employee_hand(_project_state, &"alpha", selected, priorities, employee_priorities)
		if employee_plan.is_empty(): return reject("Employee plan rejected")
	elif not employee_priorities.is_empty(): return reject("No employee roster")
	var refill_priorities: Dictionary = employee_priorities if not employee_priorities.is_empty() else priorities
	var final_action := _calculate_final_action_production(base_hand)
	var streams_before := _run_state.random_streams.snapshot() if _run_state != null else {}
	var rng_before := _deal_rng.state
	var retained: Array[CardData] = []
	var retained_ids: Array[int] = []
	for index in range(candidate_ids.size()):
		if candidate_ids[index] not in ids:
			retained.append(_candidate_cards[index])
			retained_ids.append(candidate_ids[index])
	# Played and retained finite Features cannot be drawn by this refill.
	var excluded: Array[StringName] = []
	for card in _candidate_cards:
		if not card.renewable: excluded.append(card.id)
	var refill := _build_corrective_candidate_definitions(refill_priorities, [], SELECTED_HAND_SIZE, excluded) if not _pending_playtest_categories.is_empty() else _build_weighted_candidate_definitions(refill_priorities, [], SELECTED_HAND_SIZE, excluded)
	if not refill.get("valid", false):
		_deal_rng.state = rng_before
		return reject("Refill rejected")
	var events: Array[Dictionary] = []
	var additions: Dictionary[ProjectState.CoreScore, int] = final_action.score_additions
	var commit := func() -> bool:
		if _run_state != null and (not _run_state.can_commit_employee_hand(employee_plan) or int(_run_state.get_lean_savings().get(_project_state.get_release_id(), 0)) != lean_before): return false
		if not _project_state.add_alpha_production(additions, base_hand.scope, base_hand.alpha_bug_pressure): return false
		events.append({"type":"production", "scores":additions.duplicate(), "scope":base_hand.scope, "alpha_bug_pressure":base_hand.alpha_bug_pressure})
		if not employee_priorities.is_empty(): priorities = employee_priorities.duplicate()
		if _run_state != null:
			_run_state.commit_employee_hand(employee_plan)
			_run_state.commit_lean_saving(_project_state.get_release_id(), lean_before, lean_saving)
		for card in selected:
			if card.card_type == &"feature" and not card.renewable:
				_exhausted_feature_ids[card.id] = true
				if _run_state != null: _run_state.record_resolved_feature(_project_state, card.id, CardData.PHASE_ALPHA)
				_available_features.erase(card)
				events.append({"type":"feature_exhausted", "id":card.id})
		_candidate_cards.assign(retained)
		candidate_ids.assign(retained_ids)
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
	_pending_playtest_categories.clear()
	revision += 1
	events.append({"type":"refill", "candidate_ids":candidate_ids.duplicate()})
	return {"ok":true, "events":events, "base_hand":base_hand, "final_action":final_action, "refill":refill, "rng_before":rng_before, "rng_after":_deal_rng.state, "streams_before":streams_before, "streams_after":_run_state.random_streams.snapshot() if _run_state != null else {}}



func calculate_base(selected: Array[CardData]) -> Dictionary:
	if selected.size() != SELECTED_HAND_SIZE:
		return _invalid_action("A complete Alpha action requires four current candidate instances.")
	var score_additions: Dictionary[ProjectState.CoreScore, int] = {}
	var scope_amount := 0
	var alpha_bug_pressure := 0.0
	var cards: Array[CardData] = []
	var seen_feature_ids: Dictionary[StringName, bool] = {}
	for card: CardData in selected:
		if card == null or not _candidate_cards.has(card):
			return _invalid_action("Alpha selection contains stale or missing CardData.")
		var validation_error := ""
		if card.card_type == &"feature":
			validation_error = _get_feature_validation_error(card)
			if validation_error.is_empty() and (not _available_features.has(card) or _exhausted_feature_ids.has(card.id)):
				validation_error = "Alpha Feature '%s' is not currently available." % card.id
			if validation_error.is_empty() and seen_feature_ids.has(card.id):
				validation_error = "Alpha Feature '%s' appears more than once in the action." % card.id
			seen_feature_ids[card.id] = true
		elif card.card_type == &"pass":
			validation_error = _get_pass_validation_error(card)
			if validation_error.is_empty() and not _pass_definitions.has(card):
				validation_error = "Pass '%s' is not authorized for Alpha." % card.id
		else:
			validation_error = "Card '%s' has an invalid Alpha action type." % card.id
		if not validation_error.is_empty():
			return _invalid_action(validation_error)

		cards.append(card)
		var primary_category: ProjectState.CoreScore = CORE_SCORE_BY_STAT[card.primary_stat]
		score_additions[primary_category] = score_additions.get(primary_category, 0) + card.primary_value
		if not card.secondary_stat.is_empty():
			var secondary_category: ProjectState.CoreScore = CORE_SCORE_BY_STAT[card.secondary_stat]
			score_additions[secondary_category] = score_additions.get(secondary_category, 0) + card.secondary_value
		scope_amount += card.scope
		if card.card_type == &"feature":
			alpha_bug_pressure += _calculate_feature_alpha_bug_pressure(card)
	return {
		&"valid": true,
		&"cards": cards,
		&"score_additions": score_additions,
		&"scope": scope_amount,
		&"alpha_bug_pressure": alpha_bug_pressure,
	}

func _build_corrective_candidate_definitions(priority_snapshot: Dictionary, controlled_rolls: Array[float] = [], candidate_count: int = CANDIDATE_POOL_SIZE, excluded_ids: Array[StringName] = []) -> Dictionary:
	if _pending_playtest_categories.size() != 2 or _pending_playtest_categories[0] == _pending_playtest_categories[1]:
		return {&"valid": false, &"error": "A corrective Alpha deal requires two distinct queued Core categories."}
	var injected_cards: Array[CardData] = []
	for category: ProjectState.CoreScore in _pending_playtest_categories:
		var pass_card := _get_pass_for_category(category)
		if pass_card == null:
			return {&"valid": false, &"error": "A queued corrective Core Pass is unavailable."}
		injected_cards.append(pass_card)
	var weighted_deal := _build_weighted_candidate_definitions(priority_snapshot, controlled_rolls, candidate_count - injected_cards.size(), excluded_ids)
	if not weighted_deal.valid:
		return weighted_deal
	var cards := injected_cards.duplicate()
	cards.append_array(weighted_deal.cards)
	return {&"valid": true, &"cards": cards}

func _build_weighted_candidate_definitions(priority_snapshot: Dictionary, controlled_rolls: Array[float] = [], candidate_count: int = CANDIDATE_POOL_SIZE, excluded_ids: Array[StringName] = []) -> Dictionary:
	var validation_error := _get_deal_input_validation_error(priority_snapshot, controlled_rolls, candidate_count)
	if not validation_error.is_empty():
		return {&"valid": false, &"error": validation_error}
	var remaining_features := _available_features.filter(func(card: CardData): return card.id not in excluded_ids)
	var selected_cards: Array[CardData] = []
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
			remaining_features.erase(selected)
	return {&"valid": true, &"cards": selected_cards}

func _select_weighted_entry(entries: Array[Dictionary], roll: float) -> CardData:
	return WEIGHTED_CANDIDATE_MATH.select_weighted_entry(entries, roll)

func _calculate_candidate_weight(card: CardData, priority_snapshot: Dictionary) -> float:
	return WEIGHTED_CANDIDATE_MATH.calculate_printed_score_weight(card, priority_snapshot, CORE_SCORE_BY_STAT)

func _get_deal_input_validation_error(priority_snapshot: Dictionary, controlled_rolls: Array[float], candidate_count: int = CANDIDATE_POOL_SIZE) -> String:
	if candidate_count < 1 or candidate_count > CANDIDATE_POOL_SIZE:
		return "Alpha candidate count must be between one and seven."
	if priority_snapshot.size() != PriorityAllocation.CORE_CATEGORIES.size():
		return "Priority snapshot must contain all four Core categories."
	var total_priority := 0
	for category: ProjectState.CoreScore in PriorityAllocation.CORE_CATEGORIES:
		if not priority_snapshot.has(category) or typeof(priority_snapshot[category]) != TYPE_INT:
			return "Priority snapshot contains a missing or malformed category."
		var value: int = priority_snapshot[category]
		if value < PriorityAllocation.MIN_PRIORITY or value > PriorityAllocation.MAX_PRIORITY or value % PriorityAllocation.PRIORITY_STEP != 0:
			return "Priority snapshot contains an out-of-range or non-step value."
		total_priority += value
	if total_priority > PriorityAllocation.MAX_TOTAL_PRIORITY:
		return "Priority snapshot exceeds the allocation budget."
	if not controlled_rolls.is_empty():
		if controlled_rolls.size() != candidate_count:
			return "A controlled Alpha deal requires exactly %d rolls." % candidate_count
		for roll: float in controlled_rolls:
			if not is_finite(roll) or roll < 0.0 or roll >= 1.0:
				return "Controlled Alpha rolls must be finite values in [0, 1)."

	var feature_ids: Dictionary[StringName, bool] = {}
	for card: CardData in _available_features:
		var error := _get_feature_validation_error(card)
		if not error.is_empty():
			return error
		if feature_ids.has(card.id):
			return "Alpha Feature IDs must be unique: %s" % card.id
		if _exhausted_feature_ids.has(card.id):
			return "Exhausted Alpha Feature cannot remain available: %s" % card.id
		feature_ids[card.id] = true
	if _pass_definitions.size() != 4:
		return "Alpha requires exactly four Core Pass definitions."
	var pass_categories: Dictionary[ProjectState.CoreScore, bool] = {}
	var pass_ids: Dictionary[StringName, bool] = {}
	for card: CardData in _pass_definitions:
		var error := _get_pass_validation_error(card)
		if not error.is_empty():
			return error
		var category: ProjectState.CoreScore = CORE_SCORE_BY_STAT[card.primary_stat]
		if pass_categories.has(category) or pass_ids.has(card.id):
			return "Alpha requires one unique Pass per Core category."
		pass_categories[category] = true
		pass_ids[card.id] = true
	return ""

func _get_pass_for_category(category: ProjectState.CoreScore) -> CardData:
	for card: CardData in _pass_definitions:
		if CORE_SCORE_BY_STAT.get(card.primary_stat, -1) == category:
			return card
	return null

func _get_feature_validation_error(card: CardData) -> String:
	if card == null or card.id.is_empty():
		return "Alpha Features require stable nonempty IDs."
	if card.phase != CardData.PHASE_ALPHA or card.card_type != &"feature" or card.renewable:
		return "Candidate '%s' is not a nonrenewable Alpha Feature." % card.id
	if card.department not in ALPHA_DEPARTMENTS:
		return "Alpha Feature '%s' has an invalid department." % card.id
	if card.scope < 0:
		return "Alpha Feature '%s' has negative Scope." % card.id
	return _get_printed_score_validation_error(card)

func _get_pass_validation_error(card: CardData) -> String:
	if card == null or card.id.is_empty():
		return "Core Passes require stable nonempty IDs."
	if card.phase != CardData.PHASE_DESIGN or card.card_type != &"pass" or not card.renewable:
		return "Candidate '%s' is not an Alpha-authorized Core Pass." % card.id
	if not card.department.is_empty() or card.scope != 0 or not card.secondary_stat.is_empty() or card.secondary_value != 0:
		return "Core Pass '%s' has invalid Alpha pool fields." % card.id
	return _get_printed_score_validation_error(card)

func _get_printed_score_validation_error(card: CardData) -> String:
	if not CORE_SCORE_BY_STAT.has(card.primary_stat) or card.primary_value < 0:
		return "Candidate '%s' has an invalid primary score." % card.id
	if card.secondary_stat.is_empty():
		if card.secondary_value != 0:
			return "Candidate '%s' has a secondary value without a stat." % card.id
	elif not CORE_SCORE_BY_STAT.has(card.secondary_stat) or card.secondary_value < 0:
		return "Candidate '%s' has an invalid secondary score." % card.id
	return ""

func _calculate_final_action_production(base_action: Dictionary) -> Dictionary:
	var records: Array = []
	for card: CardData in base_action.cards:
		records.append({&"primary_stat": card.primary_stat})
	var has_feature: bool = base_action.cards.any(func(card: CardData) -> bool: return card.card_type == &"feature")
	var result := ProductionHand.calculate(records, base_action.score_additions, has_feature)
	result[&"provisional_scores"] = _calculate_provisional_core_scores(base_action.score_additions)
	return result

func _calculate_provisional_core_scores(base_additions: Dictionary) -> Dictionary[ProjectState.CoreScore, int]:
	var provisional_scores: Dictionary[ProjectState.CoreScore, int] = {}
	for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
		provisional_scores[category] = _project_state.get_core_score(category) + base_additions.get(category, 0)
	return provisional_scores

func _calculate_feature_alpha_bug_pressure(card: CardData) -> float:
	var raw_score := card.primary_value
	if not card.secondary_stat.is_empty():
		raw_score += card.secondary_value
	return (float(raw_score) * float(card.scope)) / ALPHA_BUG_PRESSURE_DENOMINATOR

func _invalid_action(message: String) -> Dictionary:
	push_warning(message)
	return {
		&"valid": false,
		&"cards": [] as Array[CardData],
		&"score_additions": {},
		&"scope": 0,
		&"alpha_bug_pressure": 0.0,
	}

