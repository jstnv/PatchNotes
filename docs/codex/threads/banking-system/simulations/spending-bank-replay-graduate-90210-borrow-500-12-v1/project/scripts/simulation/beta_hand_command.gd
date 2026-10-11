## One synchronous Beta hand, independent of scenes and presentation clocks.
## Setup supplies authoritative immutable definitions and current phase inventory.
extends RefCounted

const CANDIDATE_POOL_SIZE := 7
const SELECTED_HAND_SIZE := 4
const QA_SPECIALIZATION_MULTIPLIER := 1.5
const MARKETING_SPECIALIZATION_MULTIPLIER := 1.5
const BALANCED_OPERATIONS_MULTIPLIER := 1.25
const PLAYTEST_RIVAL_PAYOUT_CENTS := 100000
const CORE_SCORE_BY_STAT := {
	&"graphics": ProjectState.CoreScore.GRAPHICS,
	&"sound": ProjectState.CoreScore.SOUND,
	&"technology": ProjectState.CoreScore.TECHNOLOGY,
	&"design": ProjectState.CoreScore.DESIGN,
}
const PASS_ID_BY_CORE_SCORE := {
	ProjectState.CoreScore.GRAPHICS: &"graphics_pass",
	ProjectState.CoreScore.SOUND: &"sound_pass",
	ProjectState.CoreScore.TECHNOLOGY: &"technology_pass",
	ProjectState.CoreScore.DESIGN: &"design_pass",
}
const FINITE_IDS: Array[StringName] = [&"press_interview", &"playtest_rival_games", &"study_competition", &"predict_market_trends"]


var _project_state: ProjectState
var _run_state: RunState
var _snapshot_database: PrimitiveSnapshotDatabase
var _definitions_by_id: Dictionary[StringName, CardData] = {}
var _beta_definitions: Array[CardData] = []
var _candidate_cards: Array[CardData] = []
var _pending_corrective_pass_ids: Array[StringName] = []
var _deal_rng: RandomNumberGenerator
var _insight_rng: RandomNumberGenerator
var priorities: Dictionary = {}
var candidate_ids: Array[int] = []
var injected_candidate_ids: Array[int] = []
var next_candidate_id := 0
var revision := 0
var active := false
var launch_confirmation_pending := false
var _executing := false

func get_priority_distribution() -> Dictionary:
	return priorities.duplicate()

func command(ids: Array[int]) -> Dictionary:
	return {"schema_version":1, "type":&"play_beta_hand", "project_id":_project_state.get_release_id(), "revision":revision, "project_cycle":_project_state.get_current_cycle(), "run_cycle":_run_state.get_completed_run_cycles(), "candidate_ids":ids.duplicate()}

func reject(reason: String) -> Dictionary:
	return {"ok":false,"error":reason,"events":[]}

## Optional readiness callback accepts only replacement definitions. It must not
## mutate gameplay. The live adapter uses it to allocate views before commit;
## headless execution needs no callback. False restores both mechanical RNGs.
## Controlled rolls preserve existing verifier hooks, outside normal commands.
func execute(request: Dictionary, insight_rolls: Array[int] = [], replacement_category_rolls: Array[float] = [], replacement_definition_rolls: Array[float] = [], readiness: Callable = Callable()) -> Dictionary:
	if _executing: return reject("Command already executing")
	_executing = true
	var result := _execute(request,insight_rolls,replacement_category_rolls,replacement_definition_rolls,readiness)
	_executing = false
	return result

func _execute(request: Dictionary, insight_rolls: Array[int], replacement_category_rolls: Array[float], replacement_definition_rolls: Array[float], readiness: Callable) -> Dictionary:
	if request.get("schema_version") != 1 or request.get("type") != &"play_beta_hand": return reject("Unsupported command")
	for field in ["schema_version","revision","project_cycle","run_cycle"]:
		if typeof(request.get(field)) != TYPE_INT: return reject("Malformed command counters")
	if not active or launch_confirmation_pending or _project_state == null or _run_state == null or _snapshot_database == null or _deal_rng == null or _insight_rng == null: return reject("Beta is not active")
	if not _project_state.has_alpha_finalization() or not _run_state.is_cash_initialized(): return reject("Beta is not initialized")
	if request.get("project_id") != _project_state.get_release_id(): return reject("Wrong project")
	if request.get("revision",-1) != revision or request.get("project_cycle",-1) != _project_state.get_current_cycle() or request.get("run_cycle",-1) != _run_state.get_completed_run_cycles(): return reject("Stale command")
	var ids: Variant = request.get("candidate_ids")
	if not ids is Array or ids.size() != SELECTED_HAND_SIZE or candidate_ids.size() != CANDIDATE_POOL_SIZE or _candidate_cards.size() != CANDIDATE_POOL_SIZE: return reject("Select four current candidates")
	var seen := {}
	var selected_ids: Array[int] = []
	for id in ids:
		if not id is int or seen.has(id) or not candidate_ids.has(id): return reject("Duplicate or stale candidate")
		seen[id] = true
		selected_ids.append(id)
	var streams_before := _run_state.random_streams.snapshot()
	var deal_before := _deal_rng.state
	var insight_before := _insight_rng.state
	var preflight := _build_hand_preflight(selected_ids,insight_rolls,replacement_category_rolls,replacement_definition_rolls)
	if not preflight.valid:
		_deal_rng.state = deal_before
		_insight_rng.state = insight_before
		return reject(preflight.error)
	if readiness.is_valid() and not readiness.call(preflight.next_cards.duplicate()):
		_deal_rng.state = deal_before
		_insight_rng.state = insight_before
		return reject("Output preparation rejected")
	var events: Array[Dictionary] = []
	var resolved := [0,0]
	var commit := func() -> bool:
		if not preflight.corrective_score_additions.is_empty():
			if not _project_state.add_core_scores_and_scope(preflight.corrective_score_additions,0): return false
			events.append({"type":"corrective_production","scores":preflight.corrective_score_additions.duplicate()})
		for requested: int in preflight.search_requests:
			var actual := _project_state.discover_bugs(requested)
			resolved[0] += actual
			events.append({"type":"search","requested":requested,"actual":actual})
		for requested: int in preflight.debug_requests:
			var actual := _project_state.fix_known_bugs(requested)
			resolved[1] += actual
			events.append({"type":"debug","requested":requested,"actual":actual})
		if preflight.marketing_gain > 0:
			_project_state.add_marketing_output(preflight.marketing_gain)
			events.append({"type":"marketing","amount":preflight.marketing_gain})
		if preflight.reveal_competitor:
			_project_state.reveal_competitor_snapshot()
			events.append({"type":"competitor_revealed"})
		if preflight.reveal_forecast:
			_project_state.reveal_market_forecast_snapshot()
			events.append({"type":"forecast_revealed"})
		_project_state.exhaust_beta_cards(preflight.finite_ids)
		for id in preflight.finite_ids: events.append({"type":"finite_exhausted","id":id})
		_project_state.advance_cycle()
		events.append({"type":"project_cycle","cycle":_project_state.get_current_cycle()})
		return true
	if not _run_state.complete_productive_action(commit,preflight.cash_gain_cents,request.run_cycle,&"",&"beta_income",_project_state.get_release_id()):
		_deal_rng.state = deal_before
		_insight_rng.state = insight_before
		return reject("Productive transaction rejected")
	events.append({"type":"productive_cycle","cycle":_run_state.get_completed_run_cycles(),"cash_cents":_run_state.get_cash_cents(),"income_cents":preflight.cash_gain_cents})
	var retained: Array[CardData] = []
	var retained_ids: Array[int] = []
	for index in range(candidate_ids.size()):
		var id := candidate_ids[index]
		if id in selected_ids: injected_candidate_ids.erase(id)
		else:
			retained.append(_candidate_cards[index])
			retained_ids.append(id)
	_candidate_cards.assign(retained)
	candidate_ids.assign(retained_ids)
	for index in range(preflight.next_cards.size()):
		_candidate_cards.append(preflight.next_cards[index])
		candidate_ids.append(next_candidate_id)
		if index < preflight.injected_corrective_count: injected_candidate_ids.append(next_candidate_id)
		next_candidate_id += 1
	if not preflight.consumed_pending_ids.is_empty(): _pending_corrective_pass_ids.clear()
	revision += 1
	events.append({"type":"refill","candidate_ids":candidate_ids.duplicate(),"injected_candidate_ids":injected_candidate_ids.duplicate()})
	return {"ok":true,"events":events,"preflight":preflight,"discovered":resolved[0],"fixed":resolved[1],"deal_rng_before":deal_before,"deal_rng_after":_deal_rng.state,"insight_rng_before":insight_before,"insight_rng_after":_insight_rng.state,"streams_before":streams_before,"streams_after":_run_state.random_streams.snapshot()}

func _build_hand_preflight(selected_ids: Array[int], insight_rolls: Array[int], replacement_category_rolls: Array[float], replacement_definition_rolls: Array[float]) -> Dictionary:
	var competitor_id := _project_state.get_assigned_competitor_snapshot_id_for_authority()
	var forecast_id := _project_state.get_assigned_market_forecast_snapshot_id_for_authority()
	if not _snapshot_database.has_competitor(competitor_id) or not _snapshot_database.has_forecast(forecast_id):
		return _invalid_play("Assigned project snapshots are missing or unknown.")
	var groups := {&"search": [] as Array[CardData], &"debug": [] as Array[CardData], &"marketing": [] as Array[CardData], &"playtest": [] as Array[CardData], &"study": [] as Array[CardData], &"predict": [] as Array[CardData]}
	var finite_ids: Array[StringName] = []
	var selected_cards: Array[CardData] = []
	var corrective_score_additions: Dictionary[ProjectState.CoreScore, int] = {}
	for id: int in selected_ids:
		var card := _candidate_cards[candidate_ids.find(id)]
		if card == null or _definitions_by_id.get(card.id) != card:
			return _invalid_play("A selected definition is not an authoritative Primitive Beta card.")
		if injected_candidate_ids.has(id):
			if not _is_valid_corrective_pass(card):
				return _invalid_play("An injected corrective Pass is malformed.")
			var category: ProjectState.CoreScore = CORE_SCORE_BY_STAT[card.primary_stat]
			corrective_score_additions[category] = corrective_score_additions.get(category, 0) + card.primary_value
			selected_cards.append(card)
			continue
		if card.phase != CardData.PHASE_BETA or card.card_type != &"beta" or card.scope != 0:
			return _invalid_play("A selected definition is not an authoritative Primitive Beta card.")
		if not card.renewable:
			if not FINITE_IDS.has(card.id) or finite_ids.has(card.id) or _project_state.is_beta_card_exhausted(card.id):
				return _invalid_play("A selected finite definition is invalid or exhausted.")
			finite_ids.append(card.id)
		selected_cards.append(card)
		match card.id:
			&"search_for_bugs": groups.search.append(card)
			&"debug": groups.debug.append(card)
			&"sign_flippers", &"posters", &"press_release", &"press_interview": groups.marketing.append(card)
			&"playtest_rival_games": groups.playtest.append(card)
			&"study_competition": groups.study.append(card)
			&"predict_market_trends": groups.predict.append(card)
			_: return _invalid_play("A selected Beta definition has no base resolver.")
	for category: ProjectState.CoreScore in corrective_score_additions:
		if corrective_score_additions[category] > ProjectState.MAX_SIGNED_INT - _project_state.get_core_score(category):
			return _invalid_play("Corrective Pass production would overflow.")
	var hidden := _project_state.get_hidden_bugs()
	var known := _project_state.get_known_bugs()
	var qa_specialization := _qualifies_for_qa_specialization(selected_cards)
	var marketing_specialization := _qualifies_for_marketing_specialization(selected_cards)
	var balanced_operations := not qa_specialization and not marketing_specialization and _qualifies_for_balanced_operations(selected_cards)
	var search_requests: Array[int] = []
	for card: CardData in groups.search:
		var final_value: float = card.beta_value * QA_SPECIALIZATION_MULTIPLIER if qa_specialization else card.beta_value
		var request := int(floor((1.0 + final_value) + (hidden * 0.15 * final_value)))
		if balanced_operations:
			request = int(ceil(request * BALANCED_OPERATIONS_MULTIPLIER))
		var actual := mini(request, hidden)
		search_requests.append(request)
		hidden -= actual
		known += actual
	var debug_requests: Array[int] = []
	for card: CardData in groups.debug:
		var final_value: float = card.beta_value * QA_SPECIALIZATION_MULTIPLIER if qa_specialization else card.beta_value
		var request := int(floor(1.0 + final_value))
		if balanced_operations:
			request = int(ceil(request * BALANCED_OPERATIONS_MULTIPLIER))
		debug_requests.append(request)
		known -= mini(request, known)
	var marketing_gain := 0
	for card: CardData in groups.marketing:
		marketing_gain += card.beta_value
	if marketing_specialization:
		marketing_gain = int(floor(marketing_gain * MARKETING_SPECIALIZATION_MULTIPLIER))
	elif balanced_operations:
		marketing_gain = int(ceil(marketing_gain * BALANCED_OPERATIONS_MULTIPLIER))
	if marketing_gain > ProjectState.MAX_SIGNED_INT - _project_state.get_marketing_output():
		return _invalid_play("Marketing Output would overflow.")
	var cash_gain: int = groups.playtest.size() * 1000
	var cash_gain_cents: int = groups.playtest.size() * PLAYTEST_RIVAL_PAYOUT_CENTS
	if cash_gain_cents > RunState.MAX_SIGNED_INT - _run_state.get_cash_cents():
		return _invalid_play("Run cash would overflow.")
	var cursor := [0]
	var competitor_revealed := _project_state.is_competitor_snapshot_revealed()
	var forecast_revealed := _project_state.is_market_forecast_snapshot_revealed()
	var rival_attempted := false
	var rival_gained := false
	var forecast_attempted := false
	var forecast_gained := false
	for card: CardData in groups.playtest:
		if not competitor_revealed:
			rival_attempted = true
			var chance := card.beta_value * 10
			if balanced_operations:
				chance = mini(100, int(ceil(chance * BALANCED_OPERATIONS_MULTIPLIER)))
			if _next_insight_roll(insight_rolls, cursor) < chance:
				competitor_revealed = true
				rival_gained = true
	for card: CardData in groups.study:
		if not competitor_revealed:
			rival_attempted = true
			var chance := card.beta_value * 15
			if balanced_operations:
				chance = mini(100, int(ceil(chance * BALANCED_OPERATIONS_MULTIPLIER)))
			if _next_insight_roll(insight_rolls, cursor) < chance:
				competitor_revealed = true
				rival_gained = true
	for card: CardData in groups.predict:
		if not forecast_revealed:
			forecast_attempted = true
			var chance := card.beta_value * 15
			if balanced_operations:
				chance = mini(100, int(ceil(chance * BALANCED_OPERATIONS_MULTIPLIER)))
			if _next_insight_roll(insight_rolls, cursor) < chance:
				forecast_revealed = true
				forecast_gained = true
	if not insight_rolls.is_empty() and cursor[0] != insight_rolls.size():
		return _invalid_play("Controlled insight rolls must match the rolls actually required.")
	var projected_exhausted := _project_state.get_exhausted_beta_card_ids()
	projected_exhausted.append_array(finite_ids)
	for index in range(candidate_ids.size()):
		var card := _candidate_cards[index]
		if candidate_ids[index] not in selected_ids and not card.renewable and card.id not in projected_exhausted:
			projected_exhausted.append(card.id)
	if not _project_state.can_advance_cycle():
		return _invalid_play("The project cycle cannot advance safely.")
	if not _run_state.can_complete_productive_cycle(cash_gain_cents):
		return _invalid_play("The run calendar cannot advance safely.")
	var definitions: Array[CardData] = []
	definitions.assign(_beta_definitions)
	var replacement := _build_replacement_candidate_definitions(definitions, get_priority_distribution(), replacement_category_rolls, replacement_definition_rolls, projected_exhausted)
	if not replacement.valid:
		return _invalid_play("A complete replacement pool could not be prepared.")
	return {&"valid": true, &"qa_specialization": qa_specialization, &"marketing_specialization": marketing_specialization, &"balanced_operations": balanced_operations, &"corrective_score_additions": corrective_score_additions, &"search_requests": search_requests, &"debug_requests": debug_requests, &"marketing_gain": marketing_gain, &"cash_gain": cash_gain, &"cash_gain_cents": cash_gain_cents, &"reveal_competitor": competitor_revealed and not _project_state.is_competitor_snapshot_revealed(), &"reveal_forecast": forecast_revealed and not _project_state.is_market_forecast_snapshot_revealed(), &"rival_attempted": rival_attempted, &"rival_gained": rival_gained, &"forecast_attempted": forecast_attempted, &"forecast_gained": forecast_gained, &"finite_ids": finite_ids, &"next_cards": replacement.cards, &"injected_corrective_count": replacement.injected_count, &"consumed_pending_ids": replacement.consumed_pending_ids}

func _qualifies_for_qa_specialization(cards: Array[CardData]) -> bool:
	if cards.size() < 2:
		return false
	for card: CardData in cards:
		if card == null or card.beta_category != CardData.BETA_CATEGORY_QA:
			return false
	return true

func _qualifies_for_marketing_specialization(cards: Array[CardData]) -> bool:
	if cards.size() < 2:
		return false
	for card: CardData in cards:
		if card == null or card.beta_category != CardData.BETA_CATEGORY_MARKETING:
			return false
	return true

func _qualifies_for_balanced_operations(cards: Array[CardData]) -> bool:
	if cards.size() != SELECTED_HAND_SIZE:
		return false
	var counts := {
		CardData.BETA_CATEGORY_QA: 0,
		CardData.BETA_CATEGORY_MARKETING: 0,
		CardData.BETA_CATEGORY_INSIDER: 0,
	}
	for card: CardData in cards:
		if card == null or not counts.has(card.beta_category):
			return false
		counts[card.beta_category] += 1
	for count: int in counts.values():
		if count < 1 or count > 2:
			return false
	return true

func _is_valid_corrective_pass(card: CardData) -> bool:
	return (
		card != null
		and PASS_ID_BY_CORE_SCORE.values().has(card.id)
		and card.phase == CardData.PHASE_DESIGN
		and card.card_type == &"pass"
		and card.renewable
		and card.scope == 0
		and CORE_SCORE_BY_STAT.has(card.primary_stat)
		and PASS_ID_BY_CORE_SCORE[CORE_SCORE_BY_STAT[card.primary_stat]] == card.id
		and card.primary_value == 2
		and card.secondary_stat.is_empty()
		and card.secondary_value == 0
	)

func _next_insight_roll(controlled: Array[int], cursor: Array) -> int:
	if controlled.is_empty():
		return _insight_rng.randi_range(0, 99)
	if cursor[0] >= controlled.size() or controlled[cursor[0]] < 0 or controlled[cursor[0]] >= 100:
		return 100
	var roll := controlled[cursor[0]]
	cursor[0] += 1
	return roll

func _invalid_play(message: String) -> Dictionary:
	return {&"valid": false, &"error": message}

func _build_replacement_candidate_definitions(definitions: Array[CardData], priorities: Dictionary, category_rolls: Array[float], definition_rolls: Array[float], excluded_ids: Array[StringName]) -> Dictionary:
	if _pending_corrective_pass_ids.is_empty():
		var ordinary := _build_candidate_definitions(definitions, priorities, category_rolls, definition_rolls, excluded_ids, SELECTED_HAND_SIZE)
		ordinary[&"injected_count"] = 0
		ordinary[&"consumed_pending_ids"] = [] as Array[StringName]
		return ordinary
	if _pending_corrective_pass_ids.size() != 2 or _pending_corrective_pass_ids[0] == _pending_corrective_pass_ids[1]:
		return _invalid_deal("A Beta Host Playtest correction requires two distinct Pass IDs.")
	var cards: Array[CardData] = []
	for id: StringName in _pending_corrective_pass_ids:
		var pass_card: CardData = _definitions_by_id.get(id)
		if not _is_valid_corrective_pass(pass_card):
			return _invalid_deal("A queued corrective Core Pass is unavailable.")
		cards.append(pass_card)
	var ordinary := _build_candidate_definitions(definitions, priorities, category_rolls, definition_rolls, excluded_ids, SELECTED_HAND_SIZE - cards.size())
	if not ordinary.valid:
		return ordinary
	cards.append_array(ordinary.cards)
	return {&"valid": true, &"cards": cards, &"injected_count": 2, &"consumed_pending_ids": _pending_corrective_pass_ids.duplicate()}

func _build_candidate_definitions(definitions: Array[CardData], priorities: Dictionary, category_rolls: Array[float] = [], definition_rolls: Array[float] = [], excluded_ids: Array[StringName] = [], candidate_count: int = CANDIDATE_POOL_SIZE) -> Dictionary:
	if not BetaPriorityAllocation.is_valid_distribution(priorities):
		return _invalid_deal("Invalid committed Beta priority distribution.")
	if candidate_count < 1 or candidate_count > CANDIDATE_POOL_SIZE:
		return _invalid_deal("Beta candidate count must be between one and seven.")
	if (not category_rolls.is_empty() and category_rolls.size() != candidate_count) or (not definition_rolls.is_empty() and definition_rolls.size() != candidate_count):
		return _invalid_deal("Controlled Beta deals require exactly %d category and definition rolls." % candidate_count)
	for roll: float in category_rolls + definition_rolls:
		if not is_finite(roll) or roll < 0.0 or roll >= 1.0:
			return _invalid_deal("Controlled Beta rolls must be finite values in [0, 1).")
	var available_by_category := _group_definitions(definitions, excluded_ids)
	var selected: Array[CardData] = []
	for slot in range(candidate_count):
		var category_entries: Array[Dictionary] = []
		for category: StringName in BetaPriorityAllocation.CATEGORIES:
			var available: Array = available_by_category[category]
			if not available.is_empty():
				category_entries.append({&"value": category, &"weight": priorities[category]})
		var category_roll := category_rolls[slot] if not category_rolls.is_empty() else _deal_rng.randf()
		var category: StringName = _select_weighted_value(category_entries, category_roll)
		if category.is_empty():
			return _invalid_deal("No eligible Beta category for slot %d." % (slot + 1))
		var definition_entries: Array[Dictionary] = []
		var category_definitions: Array = available_by_category[category]
		category_definitions.sort_custom(func(a: CardData, b: CardData) -> bool: return str(a.id) < str(b.id))
		for card: CardData in category_definitions:
			definition_entries.append({&"value": card, &"weight": _get_definition_weight(card)})
		var definition_roll := definition_rolls[slot] if not definition_rolls.is_empty() else _deal_rng.randf()
		var card := _select_weighted_value(definition_entries, definition_roll) as CardData
		if card == null:
			return _invalid_deal("No eligible Beta definition for slot %d." % (slot + 1))
		selected.append(card)
		if not card.renewable:
			category_definitions.erase(card)
	return {&"valid": true, &"cards": selected}

func _select_weighted_value(entries: Array[Dictionary], roll: float) -> Variant:
	if not is_finite(roll) or roll < 0.0 or roll >= 1.0 or entries.is_empty():
		return null
	var total := 0.0
	for entry: Dictionary in entries:
		if not entry.has(&"value") or not entry.has(&"weight"):
			return null
		var weight := float(entry.weight)
		if not is_finite(weight) or weight <= 0.0:
			return null
		total += weight
	var target := roll * total
	var cumulative := 0.0
	for index in range(entries.size()):
		cumulative += float(entries[index].weight)
		if target < cumulative or index == entries.size() - 1:
			return entries[index].value
	return null

func _group_definitions(definitions: Array[CardData], excluded_ids: Array[StringName] = []) -> Dictionary:
	var grouped := {}
	for category: StringName in BetaPriorityAllocation.CATEGORIES:
		grouped[category] = [] as Array[CardData]
	for card: CardData in definitions:
		if not excluded_ids.has(card.id):
			(grouped[card.beta_category] as Array[CardData]).append(card)
	return grouped

func _get_definition_weight(card: CardData) -> float:
	if card.beta_category == CardData.BETA_CATEGORY_QA and card.qa_operation == CardData.QA_OPERATION_DEBUG:
		return 2.0
	return 1.0

func _get_source_validation_error(definitions: Array[CardData]) -> String:
	if definitions.size() != 9:
		return "Beta requires exactly nine Primitive definitions."
	var counts := {CardData.BETA_CATEGORY_QA: 0, CardData.BETA_CATEGORY_MARKETING: 0, CardData.BETA_CATEGORY_INSIDER: 0}
	var ids: Dictionary[StringName, bool] = {}
	for card: CardData in definitions:
		if card == null or card.id.is_empty() or card.phase != CardData.PHASE_BETA or card.card_type != &"beta" or not counts.has(card.beta_category) or card.beta_value < 0 or card.scope != 0 or ids.has(card.id):
			return "Beta source definitions are malformed or duplicated."
		if card.beta_category == CardData.BETA_CATEGORY_QA and not CardData.is_valid_qa_operation(card.qa_operation):
			return "A QA source definition has an invalid operation."
		if card.beta_category != CardData.BETA_CATEGORY_QA and not card.qa_operation.is_empty():
			return "A non-QA source definition contains a QA operation."
		ids[card.id] = true
		counts[card.beta_category] += 1
	if counts[CardData.BETA_CATEGORY_QA] != 2 or counts[CardData.BETA_CATEGORY_MARKETING] != 4 or counts[CardData.BETA_CATEGORY_INSIDER] != 3:
		return "Beta source definitions do not match the locked category counts."
	return ""

func _invalid_deal(message: String) -> Dictionary:
	return {&"valid": false, &"error": message, &"cards": [] as Array[CardData]}

