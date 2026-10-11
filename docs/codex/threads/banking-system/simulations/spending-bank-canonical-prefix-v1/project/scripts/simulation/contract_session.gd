## Shared Contract draw/actions. ContractState and RunState retain all scoring,
## payout, Promotion and calendar authority. No presentation or policy dependency.
extends RefCounted
const CANDIDATE_COUNT := 7
const HAND_SIZE := 4
var _state: ContractState
var _run: RunState
var catalog: RefCounted
var _rng: RandomNumberGenerator
var cards: Array[CardData] = []
var candidate_ids: Array[int] = []
var next_id := 0
var sequence := 0
var _busy := false

func _init(state: ContractState,run: RunState,definitions: RefCounted) -> void:
	_state = state
	_run = run
	catalog = definitions
	_rng = run.random_streams.stream(&"contract_deal")

func reject(error: String) -> Dictionary:
	return {"ok":false,"error":error,"events":[]}

func command(kind: StringName,payload: Dictionary = {}) -> Dictionary:
	return {"schema_version":1,"offer_id":_state.get_offer_id(),"run_cycle":_run.get_completed_run_cycles(),"hand_count":_state.get_successful_hand_count(),"sequence":sequence,"type":kind,"payload":payload.duplicate(true)}

func execute(request: Dictionary,readiness: Callable = Callable(),publication: Callable = Callable()) -> Dictionary:
	if _busy or sequence >= RunState.MAX_SIGNED_INT or _state == null or not _run.owns_contract_state(_state): return reject("Contract unavailable")
	for field in ["schema_version","sequence","run_cycle","hand_count"]:
		if not request.get(field) is int: return reject("Malformed counter")
	for field in ["offer_id","type"]:
		if not request.get(field) is String and not request.get(field) is StringName: return reject("Malformed identity")
	if not request.get("payload") is Dictionary: return reject("Malformed payload")
	if request.schema_version != 1 or request.sequence != sequence or request.run_cycle != _run.get_completed_run_cycles() or request.hand_count != _state.get_successful_hand_count() or request.offer_id != _state.get_offer_id(): return reject("Stale Contract command")
	if _state.is_completed() or _run.get_active_contract() != _state: return reject("Contract completed or inactive")
	_busy = true
	var before := _run.random_streams.snapshot()
	var result := _execute(StringName(request.type),request.payload,readiness,publication)
	if result.ok:
		sequence += 1
		result.sequence = sequence
		result.rng_before = before
		result.rng_after = _run.random_streams.snapshot()
	_busy = false
	return result

func _execute(kind: StringName,payload: Dictionary,readiness: Callable,publication: Callable) -> Dictionary:
	if kind == &"begin":
		if not cards.is_empty() or not payload.is_empty(): return reject("Contract already dealt")
		var before := _rng.state
		var deal := _build_candidate_pool()
		if deal.is_empty() or (readiness.is_valid() and not readiness.call(deal)):
			_rng.state = before
			return reject("Initial Contract draw rejected")
		publish_initial(deal)
		if publication.is_valid(): publication.call(deal)
		return {"ok":true,"events":[{"type":"contract_dealt","candidate_ids":candidate_ids.duplicate()}]}
	if not valid_pool(): return reject("Invalid Contract pool")
	if kind == &"priorities":
		if payload.size() != 1 or not payload.get("distribution") is Dictionary: return reject("Missing priorities")
		if not commit_priorities(payload.distribution): return reject("Contract priorities rejected")
		return {"ok":true,"events":[{"type":"contract_priorities"},{"type":"productive_cycle"}]}
	if kind not in [&"play",&"redraw"] or payload.size() != 1 or not payload.get("candidate_ids") is Array: return reject("Unsupported Contract command")
	var slots: Array[int] = []
	for id: Variant in payload.candidate_ids:
		if not id is int or id not in candidate_ids or candidate_ids.find(id) in slots: return reject("Invalid candidate token")
		slots.append(candidate_ids.find(id))
	if kind == &"redraw": return redraw(slots,[],[],readiness,publication)
	if slots.size() != HAND_SIZE: return reject("Four candidates required")
	var selected: Array[CardData] = []
	for slot in slots: selected.append(cards[slot])
	var plan := _state.plan_hand(selected)
	if plan.is_empty() or not _run.can_complete_productive_cycle(plan.remainder_cents): return reject("Contract hand rejected")
	var before := _rng.state
	var replacements: Array[CardData] = []
	if not plan.completing:
		var reserved: Dictionary = {}
		for id: StringName in plan.exhausted_ids: reserved[id] = true
		for slot in range(cards.size()):
			if slot not in slots and not cards[slot].renewable: reserved[cards[slot].id] = true
		replacements = _build_candidate_pool(reserved,[],[],HAND_SIZE)
		if replacements.is_empty() or (readiness.is_valid() and not readiness.call(replacements)):
			_rng.state = before
			return reject("Contract refill rejected")
	var commit := func() -> bool: return _run.commit_contract_hand(_state,selected,plan.remainder_cents)
	if not _run.complete_productive_action(commit,plan.remainder_cents,_run.get_completed_run_cycles(),&"",&"publisher_receipt" if plan.remainder_cents > 0 else &"contract_hand",_state.get_offer_id()):
		_rng.state = before
		return reject("Contract cycle rejected")
	if not plan.completing:
		var retained: Array[CardData] = []
		var retained_ids: Array[int] = []
		for slot in range(cards.size()):
			if slot not in slots:
				retained.append(cards[slot])
				retained_ids.append(candidate_ids[slot])
		cards = retained
		candidate_ids = retained_ids
		_append(replacements)
	if publication.is_valid(): publication.call(replacements)
	var events: Array = [{"type":"contract_hand","plan":plan.duplicate(true)},{"type":"productive_cycle"}]
	if plan.completing: events.append({"type":"contract_completed","offer_id":_state.get_offer_id()})
	return {"ok":true,"events":events,"replacements":replacements}

func publish_initial(deal: Array[CardData]) -> void:
	cards.clear()
	candidate_ids.clear()
	_append(deal)

func _append(additions: Array[CardData]) -> void:
	for card in additions:
		cards.append(card)
		candidate_ids.append(next_id)
		next_id += 1

func valid_pool() -> bool:
	if cards.size() != CANDIDATE_COUNT or candidate_ids.size() != cards.size(): return false
	var seen: Dictionary = {}
	for card in cards:
		if card == null or catalog.get_card(card.id) != card: return false
		if card.card_type == &"feature":
			if not _state.is_feature_eligible(card.id) or _state.is_feature_exhausted(card.id) or seen.has(card.id): return false
			seen[card.id] = true
		elif card.id not in ContractState.PASS_IDS: return false
	return true

func commit_priorities(distribution: Dictionary) -> bool:
	if _state == null or not _state.can_commit_priorities(distribution) or not _run.can_complete_productive_cycle(): return false
	var commit := func() -> bool: return _state.commit_priorities(distribution)
	return _run.complete_productive_action(commit,0,_run.get_completed_run_cycles(),&"",&"priority_change",_state.get_offer_id())

func redraw(slots: Array[int],category_rolls: Array[float] = [],definition_rolls: Array[float] = [],readiness: Callable = Callable(),publication: Callable = Callable()) -> Dictionary:
	var count := slots.size()
	if _state == null or _state.is_completed() or count == 0 or not _run.can_consume_redraw(count): return reject("Contract redraw unavailable")
	if (not category_rolls.is_empty() and category_rolls.size() != count) or (not definition_rolls.is_empty() and definition_rolls.size() != count): return reject("Invalid redraw rolls")
	var seen: Dictionary = {}
	for slot in slots:
		if slot < 0 or slot >= cards.size() or seen.has(slot): return reject("Invalid redraw slots")
		seen[slot] = true
	var before := _rng.state
	var reserved: Dictionary = {}
	var replacements: Array[CardData] = []
	for card in cards:
		if card.card_type == &"feature": reserved[card.id] = true
	for index in range(count):
		var old := cards[slots[index]]
		var category_roll := category_rolls[index] if not category_rolls.is_empty() else _rng.randf()
		var definition_roll := definition_rolls[index] if not definition_rolls.is_empty() else _rng.randf()
		var replacement := _draw_one(old.card_type,reserved,category_roll,definition_roll,old.id)
		if replacement == null:
			_rng.state = before
			return reject("No redraw replacement")
		replacements.append(replacement)
		if replacement.card_type == &"feature": reserved[replacement.id] = true
	if readiness.is_valid() and not readiness.call(replacements):
		_rng.state = before
		return reject("Redraw presentation unavailable")
	var publish := func() -> void:
		for index in range(count):
			cards[slots[index]] = replacements[index]
			candidate_ids[slots[index]] = next_id
			next_id += 1
		if publication.is_valid(): publication.call(replacements)
	if not _run.consume_redraw(count,publish):
		_rng.state = before
		return reject("Redraw debit rejected")
	return {"ok":true,"events":[{"type":"contract_redraw","candidate_ids":candidate_ids.duplicate()}],"replacements":replacements}

func observation() -> Dictionary:
	var candidates: Array = []
	for index in range(cards.size()):
		var card := cards[index]
		candidates.append({"token":candidate_ids[index],"definition":card.id,"primary_stat":card.primary_stat,"primary_value":card.primary_value,"secondary_stat":card.secondary_stat,"secondary_value":card.secondary_value,"scope":card.scope,"renewable":card.renewable})
	var scores: Dictionary = {}
	for category in range(4): scores[category] = _state.get_core_score_half_units(category)
	return {"offer_id":_state.get_offer_id(),"hand_count":_state.get_successful_hand_count(),"required_hands":_state.get_required_hands(),"run_cycle":_run.get_completed_run_cycles(),"sequence":sequence,"candidates":candidates,"completed":_state.is_completed(),"priorities":_state.get_priority_distribution(),"scope":_state.get_scope(),"core_half_units":scores}


func _build_candidate_pool(extra_exhausted: Dictionary = {}, category_rolls: Array[float] = [], definition_rolls: Array[float] = [], candidate_count: int = CANDIDATE_COUNT) -> Array[CardData]:
	if (not category_rolls.is_empty() and category_rolls.size() != candidate_count) or (not definition_rolls.is_empty() and definition_rolls.size() != candidate_count):
		return []
	var cards: Array[CardData] = []
	var rng_before:=_rng.state
	var reserved: Dictionary = extra_exhausted.duplicate()
	for slot in range(candidate_count):
		var category_roll := category_rolls[slot] if not category_rolls.is_empty() else _rng.randf()
		var definition_roll := definition_rolls[slot] if not definition_rolls.is_empty() else _rng.randf()
		var card := _draw_one(&"", reserved, category_roll, definition_roll)
		if card == null:
			_rng.state=rng_before
			return []
		cards.append(card)
		if card.card_type == &"feature": reserved[card.id] = true
	return cards


func _draw_one(type_filter: StringName, reserved_features: Dictionary, category_roll: float, definition_roll: float, excluded_id: StringName = &"") -> CardData:
	if not is_finite(category_roll) or category_roll < 0.0 or category_roll >= 1.0 or not is_finite(definition_roll) or definition_roll < 0.0 or definition_roll >= 1.0:
		return null
	var by_category: Dictionary = {}
	for category: ProjectState.CoreScore in PriorityAllocation.CORE_CATEGORIES: by_category[category] = []
	var database: RefCounted = catalog
	if database == null: return null
	for id in _state.get_eligible_feature_ids():
		if reserved_features.has(id) or _state.is_feature_exhausted(id) or id == excluded_id: continue
		var card: CardData = database.get_card(id)
		if card != null and (type_filter.is_empty() or type_filter == &"feature"):
			by_category[ContractState.CORE_BY_STAT[card.primary_stat]].append(card)
	for id in ContractState.PASS_IDS:
		if id == excluded_id: continue
		var pass_card: CardData = database.get_card(id)
		if pass_card != null and (type_filter.is_empty() or type_filter == &"pass"):
			by_category[ContractState.CORE_BY_STAT[pass_card.primary_stat]].append(pass_card)
	var available_categories: Array[ProjectState.CoreScore] = []
	var total_weight := 0
	var priorities := _state.get_priority_distribution()
	for category: ProjectState.CoreScore in PriorityAllocation.CORE_CATEGORIES:
		if not by_category[category].is_empty():
			available_categories.append(category)
			total_weight += priorities[category]
	if total_weight <= 0: return null
	var target := category_roll * total_weight
	var cumulative := 0
	var chosen := available_categories[-1]
	for category in available_categories:
		cumulative += priorities[category]
		if target < cumulative:
			chosen = category
			break
	var definitions: Array = by_category[chosen]
	definitions.sort_custom(func(a: CardData, b: CardData) -> bool: return str(a.id) < str(b.id))
	return definitions[mini(floori(definition_roll * definitions.size()), definitions.size() - 1)]


