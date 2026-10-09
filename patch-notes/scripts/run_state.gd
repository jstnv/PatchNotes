class_name RunState
extends RefCounted

const MAX_SIGNED_INT: int = 9223372036854775807

signal cash_changed
signal calendar_changed
signal redraws_changed
signal features_changed
signal sales_changed
signal contracts_changed
signal publishers_changed
signal finance_changed
signal employees_changed

const CENTS_PER_DOLLAR := 100
const MAX_REDRAWS := 4
const START_YEAR := 1980
const FIRST_STUDIO_CASH_CENTS := 550000
const POST_LAUNCH_CAMPAIGN_COST_CENTS := 10000
const GUARANTEED_PRIMITIVE_IDS = StudioSpecialties.COMMON_IDS

var _cash_cents := 0
var _cash_initialized := false
var _completed_run_cycles := 0
var _available_redraws := MAX_REDRAWS
var _owned_features: Dictionary = {}
var _feature_definitions: Dictionary = {}
var _feature_offers: Dictionary = {}
var _familiarity: Dictionary = {}
# Retain project identity: reconstruction and phase changes cannot mint credits.
var _credited_projects: Dictionary = {}
var _feature_purchase_in_progress := false
var _feature_research: Array = []
var _resourceful_claims: Dictionary = {}
var _released_games: Dictionary = {}
var _release_metadata: Dictionary = {}
var _productive_cycle_in_progress := false
var _committing_cycle_cash := false
var _publishing_cycle := false
var _primitive_contract: ContractState
var _ironclad_completion_committed := false
var _sidestreet_entitlements: Dictionary = {}
var _sidestreet_results: Dictionary = {}
var _pending_contract_completion: ContractState
var _unlocked_publishers: Dictionary = {}
var _pending_publisher_notifications: Array[StringName] = []
var _seen_tutorial_topics: Dictionary = {}
var _studio_name := ""
var _studio_specialty: StringName = &""
var _studio_traits: Dictionary = {}
var _lean_savings: Dictionary = {}
var _first_studio_economy := false
var _starter_selection_confirmed := false
var _first_tutorial_project_id: StringName
var _first_game_tutorial: FirstGameTutorial
var _studio_finance: Dictionary = {}
var _bank_run_id: StringName = &""
var _employees: Dictionary = EmployeeRoster.create(&"")
var random_streams := RunRandom.new()
var next_project_serial := 1
var checkpoint_mutations_allowed := true
var studio_departure_guard: Callable
var checkpoint_before_mutation: Callable
var _publisher_offers: Dictionary = {}
var _promotion_awards: Dictionary = {}
var _promotion_consumed: Dictionary = {}

func can_mutate_checkpoint() -> bool:
	return checkpoint_mutations_allowed and (not checkpoint_before_mutation.is_valid() or checkpoint_before_mutation.call())


## Arm only at the successful first-project creation boundary, never on a view.
func begin_first_game_tutorial(project: ProjectState) -> bool:
	if not needs_starter_selection() or project == null or not project.has_predevelopment_identity() or project.get_current_cycle() != 0 or not _released_games.is_empty() or _first_game_tutorial != null:
		return false
	_first_tutorial_project_id = project.get_release_id()
	_first_game_tutorial = FirstGameTutorial.new()
	return true


func get_first_game_tutorial(project: ProjectState) -> FirstGameTutorial:
	if project == null or project.get_release_id() != _first_tutorial_project_id: return null
	return _first_game_tutorial

## Legacy no-trait fixture/capture creation. New player flow uses create_studio.
func set_studio_name(value: String, specialty: StringName = &"") -> bool:
	return _commit_studio_creation(value, specialty, {})


func create_studio(value: String, specialty: StringName, background: StringName, secondary_ids: Array) -> bool:
	var selection := StudioTraits.evaluate(background, secondary_ids)
	if not selection.valid: return false
	return _commit_studio_creation(value, specialty, selection)


func create_studio_with_traits(value: String, specialty: StringName, trait_ids: Array) -> bool:
	var selection := StudioTraits.evaluate_traits(trait_ids)
	if not selection.valid: return false
	return _commit_studio_creation(value, specialty, selection)


func get_studio_traits() -> Dictionary:
	return _studio_traits.duplicate(true)


## Value checkpoint for eventual save integration, not a durable loader.
func get_studio_creation_snapshot() -> Dictionary:
	return {"name": _studio_name, "specialty_id": _studio_specialty,
		"traits": get_studio_traits(), "base_funding_cents": FIRST_STUDIO_CASH_CENTS,
		"confirmation_committed": not _studio_name.is_empty()}


func _commit_studio_creation(value: String, specialty: StringName, selection: Dictionary) -> bool:
	if not can_mutate_checkpoint(): return false
	var cleaned := value.strip_edges()
	if not _studio_name.is_empty() or not _studio_specialty.is_empty() or cleaned.is_empty() or cleaned.length() > 80 or _feature_purchase_in_progress or _productive_cycle_in_progress or _publishing_cycle or not _cash_initialized or _cash_cents != 0 or _completed_run_cycles != 0 or not _released_games.is_empty():
		return false
	var preview := StudioSpecialties.preview(specialty)
	if preview.is_empty(): return false
	var guaranteed: Dictionary = {}
	for id: StringName in preview.ids:
		if not _feature_definitions.has(id):
			return false
		guaranteed[id] = true
	var finance := StudioFinanceLedger.create(FIRST_STUDIO_CASH_CENTS, 51500 if StudioTraits.is_active(selection, &"expensive_lease") else 50000)
	var point_cash := int(selection.get("point_cash_cents", 0))
	if point_cash > 0:
		var receipt := StudioFinanceLedger.plan(finance, 0, FIRST_STUDIO_CASH_CENTS,
			point_cash, &"financing_in", 0, 0, false, &"studio_trait_unspent_points_v1")
		if receipt.is_empty(): return false
		finance = receipt.ledger
	var family_cash := int(selection.get("family_funding_cents", 0))
	if family_cash > 0:
		var receipt := StudioFinanceLedger.plan(finance, 0, FIRST_STUDIO_CASH_CENTS + point_cash,
			family_cash, &"financing_in", 0, 0, false, &"studio_trait_family_funding_v1")
		if receipt.is_empty(): return false
		finance = receipt.ledger
	if finance.is_empty(): return false
	_owned_features = guaranteed
	_cash_cents = FIRST_STUDIO_CASH_CENTS + point_cash + family_cash
	_studio_traits = selection.duplicate(true)
	_first_studio_economy = true
	_studio_name = cleaned
	_studio_specialty = specialty
	_studio_finance = finance
	_bank_run_id = StringName(Crypto.new().generate_random_bytes(16).hex_encode())
	_employees = EmployeeRoster.create(_bank_run_id)
	cash_changed.emit()
	features_changed.emit()
	finance_changed.emit()
	return true


## Historical expenses are available only for studios created with this ledger.
func get_studio_finance_report() -> Dictionary:
	return StudioFinanceLedger.report(_studio_finance, _completed_run_cycles, _cash_cents)


func get_outstanding_expenses() -> Dictionary:
	return StudioFinanceLedger.outstanding(_studio_finance, _completed_run_cycles)


func get_studio_finance_snapshot() -> Dictionary:
	return _studio_finance.duplicate(true)


func get_bank_quote(principal: Variant, months: Variant) -> Dictionary:
	if not _first_studio_economy: return {}
	return StudioFinanceLedger.bank_quote(_studio_finance, principal, months, _bank_run_id)


func get_bank_payoff_quote(loan_id: StringName) -> Dictionary:
	return StudioFinanceLedger.payoff_quote(_studio_finance, loan_id)


func accept_bank_loan(quote: Dictionary) -> bool:
	if not can_mutate_checkpoint(): return false
	if not _bank_action_available(): return false
	return _commit_bank_plan(StudioFinanceLedger.accept_loan(_studio_finance, quote, _bank_run_id))


func pay_off_bank_loan(quote: Dictionary) -> bool:
	if not can_mutate_checkpoint(): return false
	if not _bank_action_available(): return false
	return _commit_bank_plan(StudioFinanceLedger.pay_off(_studio_finance, quote))


func _bank_action_available() -> bool:
	return _first_studio_economy and not _productive_cycle_in_progress and not _publishing_cycle and not _feature_purchase_in_progress and _pending_contract_completion == null and _studio_finance.get("cash_cents") == _cash_cents and _studio_finance.get("last_cycle") == _completed_run_cycles


func _commit_bank_plan(plan: Dictionary) -> bool:
	if plan.is_empty(): return false
	_studio_finance = plan.ledger
	_cash_cents = plan.cash_cents
	_publishing_cycle = true
	cash_changed.emit()
	finance_changed.emit()
	_publishing_cycle = false
	return true


## Hidden, derived from immutable committed release IDs. Reopening/re-registering
## a release cannot create another sample; incomplete games are never samples.
func get_development_pacing() -> Dictionary:
	var releases: Dictionary = {}
	for id: StringName in _released_games:
		releases[id] = _release_metadata.get(id, {})
	return FeatureSpendingGuidance.pacing(releases)


## Owned means eligible for a future project's supply, not just an unlocked
## Store branch. Preview adds only the selected new Feature, without ownership.
func get_feature_spending_advice(purchase_id: StringName = &"") -> Dictionary:
	var ids := get_owned_feature_ids()
	var path := get_feature_acquisition_quote(purchase_id)
	if not path.available: return path
	for step: Dictionary in path.steps:
		if not ids.has(step.id): ids.append(step.id)
	var price: int = path.price_cents
	var purchase_cycles: int = path.cycles
	var cards: Array[CardData] = []
	var unpriced := 0
	for id: StringName in ids:
		if not _feature_definitions.has(id): return {"available": false}
		var entry: Dictionary = _feature_definitions[id]
		if _feature_offers.has(id):
			unpriced += 1
			continue
		# Reuse the actual charge path; no parallel play-price formula.
		var card := CardData.new()
		card.id = id
		card.card_type = StringName(entry.type)
		card.phase = StringName(entry.phase)
		card.primary_value = int(entry.primary_value)
		card.secondary_value = int(entry.secondary_value)
		card.scope = int(entry.scope)
		cards.append(card)
	var play_cost := primitive_feature_hand_cost_cents(cards)
	# This advice covers a fresh project and its full unused cap.
	play_cost -= lean_discount(play_cost, &"next_project_advice")
	var pool := {"available": play_cost >= 0, "known_play_cost_cents": play_cost,
		"unpriced_count": unpriced, "feature_count": ids.size()}
	var advice := FeatureSpendingGuidance.estimate(get_development_pacing(), pool,
		get_studio_finance_report(), _completed_run_cycles, get_cash_cents(), price, purchase_cycles, get_studio_finance_snapshot())
	advice["acquisition"] = path
	return advice


## Current quotes only. Never purchases or assumes an ancestor is already owned.
func get_feature_acquisition_quote(id: StringName = &"") -> Dictionary:
	var path := {"available":true,"steps":[],"price_cents":0,"cycles":0,"requirements":[]}
	var pending: Array[StringName] = []
	var seen: Dictionary = {}
	while not id.is_empty():
		if seen.has(id) or not _feature_definitions.has(id): return {"available":false,"reason":"Acquisition quote unavailable for this Feature."}
		seen[id] = true
		pending.push_front(id)
		var offer := get_feature_store_offer(id)
		id = StringName(offer.get("parent", &""))
	var saving_available := resourceful_saving(10000) > 0
	for feature: StringName in pending:
		var offer := get_feature_store_offer(feature)
		var primitive := offer.is_empty()
		if primitive: offer = get_primitive_reserve_offer(feature)
		if offer.is_empty(): return {"available":false,"reason":"Current acquisition price unavailable."}
		var owned := owns_feature(feature)
		var cost := 0 if owned else int(offer.price_cents)
		var cycles := 0 if owned or (primitive and offer.initial) else 1
		var research := {}
		if not owned and not (primitive and offer.initial):
			research = get_feature_research_quote(feature)
			cost = int(research.remaining_cents) + (0 if research.queued else int(research.down_cents))
			cycles = research.remaining_actions
			var projected_saving := resourceful_saving(int(FeatureResearch.payment(research.base_cents,research.actions,research.actions-1,research.discount_percent).due_cents))
			if not saving_available:
				cost += projected_saving
				research.remaining_cents += projected_saving
				research.due_cents += int(research.saving_cents)
				research.saving_cents = 0
			elif projected_saving > 0: saving_available = false
		if cost > MAX_SIGNED_INT - int(path.price_cents): return {"available":false,"reason":"Acquisition quote exceeds the supported range."}
		var status := "Owned" if owned else "Available" if (offer.can_purchase if primitive else offer.unlocked and not needs_starter_selection()) else "Locked / unavailable now"
		if not owned and not offer.affordable: status += "; insufficient cash"
		path.steps.append({"id":feature,"name":offer.name,"owned":owned,"price_cents":cost,"cycles":cycles,"status":status,"research":research})
		path.price_cents += cost
		path.cycles += cycles
		if not primitive and not owned:
			if needs_starter_selection() and not path.requirements.has("Later Features require the first game's completion."): path.requirements.append("Later Features require the first game's completion.")
			if not offer.unlocked and StringName(offer.parent).is_empty(): path.requirements.append(offer.prerequisite)
	return path


func get_financial_block_reason() -> String:
	if not _first_studio_economy: return ""
	if _studio_finance.get("cash_cents", -1) != _cash_cents or _studio_finance.get("last_cycle", -1) != _completed_run_cycles:
		return "Financial history is unavailable; production cannot be committed safely."
	var unpaid := StudioFinanceLedger.get_unpaid(_studio_finance)
	if unpaid < 0: return "Financial history is unavailable; production cannot be committed safely."
	if unpaid == 0: return ""
	return "Unpaid bills: %s. Further production must clear all overdue bills. You can still launch, browse Finances, or use an available income action that clears the balance." % CashFormatter.format_exact_cents(unpaid)

func get_studio_name() -> String:
	return _studio_name

func get_studio_specialty() -> StringName:
	return _studio_specialty


func uses_first_studio_economy() -> bool:
	return _first_studio_economy


func needs_starter_selection() -> bool:
	return _first_studio_economy and not _starter_selection_confirmed


func get_starter_pool_summary() -> Dictionary:
	if not _first_studio_economy:
		return {}
	var scope := 0
	var count := 0
	for id: StringName in _owned_features:
		if _feature_offers.has(id):
			continue
		scope += int(_feature_definitions[id].scope)
		count += 1
	return {"scope": scope, "count": count}


func get_primitive_reserve_offer(id: StringName) -> Dictionary:
	if not _first_studio_economy or not _feature_definitions.has(id) or _feature_offers.has(id):
		return {}
	var entry: Dictionary = _feature_definitions[id]
	var scope := int(entry.scope)
	if scope < 1 or scope > 3:
		return {}
	var price := (scope + 1) * 15000
	var initial := needs_starter_selection()
	var base_price := price
	if initial: price -= resourceful_saving(price)
	return {"id": id, "name": entry.name, "phase": entry.phase, "scope": scope,
		"base_price_cents":base_price,"price_cents": price, "owned": owns_feature(id), "affordable": _cash_initialized and _cash_cents >= price,
		"initial": initial, "can_purchase": not owns_feature(id) and _cash_initialized and _cash_cents >= price}


func purchase_starter_feature(id: StringName) -> bool:
	if not can_mutate_checkpoint(): return false
	if not needs_starter_selection() or _feature_purchase_in_progress or _productive_cycle_in_progress or _publishing_cycle:
		return false
	var offer := get_primitive_reserve_offer(id)
	if offer.is_empty() or not offer.can_purchase:
		return false
	_feature_purchase_in_progress = true
	var was_blocked := is_blocking_signals()
	set_block_signals(true)
	if not spend_cash_cents(offer.price_cents, &"store", id):
		set_block_signals(was_blocked)
		_feature_purchase_in_progress = false
		return false
	if resourceful_saving(int(offer.base_price_cents)) > 0: _resourceful_claims[_released_games.size()] = id
	_owned_features[id] = true
	set_block_signals(was_blocked)
	cash_changed.emit()
	finance_changed.emit()
	features_changed.emit()
	_feature_purchase_in_progress = false
	return true


func finalize_starter_selection() -> bool:
	if not can_mutate_checkpoint(): return false
	if not needs_starter_selection() or _feature_purchase_in_progress or _productive_cycle_in_progress or _publishing_cycle:
		return false
	_starter_selection_confirmed = true
	return true


func purchase_primitive_reserve_feature(id: StringName) -> bool:
	return admit_feature_research(get_feature_research_quote(id))


func primitive_feature_hand_cost_cents(cards: Array[CardData], project_id: StringName = &"") -> int:
	if not _first_studio_economy:
		return 0
	var total := 0
	for card: CardData in cards:
		if card == null:
			return -1
		if card.card_type == &"pass":
			continue
		if card.card_type != &"feature" or card.phase not in [CardData.PHASE_DESIGN, CardData.PHASE_ALPHA] or card.primary_value < 0 or card.secondary_value < 0 or card.scope < 0:
			return -1
		if not _feature_definitions.has(card.id):
			return -1
		# Later Feature classes have no locked play price in this milestone.
		if _feature_offers.has(card.id):
			continue
		var printed := card.primary_value + card.secondary_value + (2 * card.scope)
		if printed < 0 or printed > (MAX_SIGNED_INT - total) / 1000:
			return -1
		total += printed * 1000
	return total - lean_discount(total, project_id)

## Presentation-only progress: no calendar, cash or production mutation.
func visit_guidance_tip(key: StringName) -> bool:
	if key == &"" or _seen_tutorial_topics.has(key):
		return false
	_seen_tutorial_topics[key] = true
	return true


## Preserve the existing presentation API for callers that track topic visits.
func visit_tutorial_topic(topic: StringName) -> bool:
	return visit_guidance_tip(topic)


func _init() -> void:
	for entry: Dictionary in FeatureStoreCatalog.starting_features():
		var id := StringName(entry.id)
		_owned_features[id] = true
		_feature_definitions[id] = entry
	for entry: Dictionary in FeatureStoreCatalog.entries():
		var id := StringName(entry.id)
		_feature_definitions[id] = entry
		_feature_offers[id] = entry


func owns_feature(id: StringName) -> bool:
	return _owned_features.has(id)


func get_owned_feature_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(_owned_features.keys())
	return result


func get_feature_familiarity(id: StringName) -> int:
	return _familiarity.get(id, 0)


## Called only after committed Design/Alpha production, never draw/selection.
## Contract familiarity is an open design decision, not a permanent exclusion.
func record_resolved_feature(project: ProjectState, id: StringName, phase: StringName) -> bool:
	if _publishing_cycle:
		return false
	if project == null or phase not in [CardData.PHASE_DESIGN, CardData.PHASE_ALPHA] or not owns_feature(id):
		return false
	if StringName(_feature_definitions[id].phase) != phase:
		return false
	var credited: Dictionary = _credited_projects.get(project.get_release_id(), {})
	if credited.has(id):
		return false
	credited[id] = true
	_credited_projects[project.get_release_id()] = credited
	_familiarity[id] = get_feature_familiarity(id) + 1
	features_changed.emit()
	return true


func get_feature_store_offer(id: StringName) -> Dictionary:
	if not _feature_offers.has(id):
		return {}
	var entry: Dictionary = _feature_offers[id]
	var parent := StringName(entry.purchase_parent)
	var required := int(entry.gameplay_features_required)
	var gameplay_owned := 0
	for owned_id: StringName in _owned_features:
		if _feature_definitions[owned_id].get("department", "") == "gameplay":
			gameplay_owned += 1
	var unlocked := (parent.is_empty() or owns_feature(parent)) and gameplay_owned >= required
	var discount := mini(get_feature_familiarity(parent), 5) * 10 if not parent.is_empty() and required == 0 else 0
	var base_price := int(entry.base_price_cents)
	var price: int = (base_price / 100) * (100 - discount)
	var prerequisite := "New root"
	if not parent.is_empty():
		prerequisite = "Own " + str(_feature_definitions[parent].name)
	elif required > 0:
		prerequisite = "Own %d distinct Gameplay Features (%d owned)" % [required, gameplay_owned]
	return {"id": id, "name": entry.name, "parent": parent, "prerequisite": prerequisite,
		"owned": owns_feature(id), "unlocked": unlocked, "base_price_cents": base_price,
		"discount_percent": discount, "price_cents": price,
		"affordable": _cash_initialized and _cash_cents >= price}


func purchase_feature(id: StringName) -> bool:
	return admit_feature_research(get_feature_research_quote(id))


func resourceful_saving(price: int) -> int:
	return mini(10000,price) if price > 0 and StudioTraits.is_active(_studio_traits,&"resourceful") and not _resourceful_claims.has(_released_games.size()) else 0


func get_feature_research_queue() -> Array:
	var pending: Array = []
	for entry: Dictionary in _feature_research:
		if entry.payments.size() < entry.actions: pending.append(entry.duplicate(true))
	return pending


func get_feature_research_quote(id: StringName) -> Dictionary:
	var offer := get_feature_store_offer(id)
	var primitive := offer.is_empty()
	if primitive: offer = get_primitive_reserve_offer(id)
	if offer.is_empty(): return {}
	var base: int = offer.base_price_cents
	var entry: Dictionary = {}
	for candidate: Dictionary in _feature_research:
		if candidate.feature_id == id: entry = candidate
	var queued: bool = not entry.is_empty() and entry.payments.size() < entry.actions
	var actions: int = entry.get("actions",1)
	var done: int = entry.get("payments",[]).size()
	var discount: int = offer.get("discount_percent",0)
	var arithmetic := FeatureResearch.payment(base,actions,mini(done,actions-1),discount)
	if arithmetic.is_empty(): return {}
	var saving := resourceful_saving(arithmetic.due_cents) if done == actions-1 else 0
	var remaining := 0
	for index in range(done,actions): remaining += int(FeatureResearch.payment(base,actions,index,discount).due_cents)
	if done < actions: remaining -= resourceful_saving(int(FeatureResearch.payment(base,actions,actions-1,discount).due_cents))
	var paid := 0 if entry.is_empty() else int(arithmetic.down_cents)
	for installment: Dictionary in entry.get("payments",[]): paid += int(installment.paid_cents)
	var pending := get_feature_research_queue()
	var head: bool = queued and not pending.is_empty() and pending[0].feature_id == id
	var unlocked: bool = primitive or offer.get("unlocked",false)
	return {"feature_id":id,"entry_id":StringName("%s:research:%s" % [_bank_run_id,id]),
		"base_cents":base,"down_cents":arithmetic.down_cents,"due_cents":arithmetic.due_cents-saving,"saving_cents":saving,
		"nominal_cents":arithmetic.nominal_cents,"discount_percent":discount,"actions":actions,"completed":done,
		"paid_cents":paid,"remaining_actions":actions-done,"remaining_cents":remaining,"queued":queued,"head":head,"unlocked":unlocked,
		"can_admit":not needs_starter_selection() and not offer.owned and unlocked and not queued and _cash_initialized and _cash_cents>=arithmetic.down_cents and get_financial_block_reason().is_empty(),
		"can_research":head and can_complete_productive_cycle(-int(arithmetic.due_cents-saving)),
		"cycle":_completed_run_cycles,"cash_cents":_cash_cents,"revision":_studio_finance.get("actions",[]).size(),"queue_size":_feature_research.size(),"resourceful_window":_released_games.size()}


func admit_feature_research(quote: Dictionary) -> bool:
	if not can_mutate_checkpoint() or _feature_purchase_in_progress or _productive_cycle_in_progress or _publishing_cycle: return false
	if quote.is_empty() or typeof(quote.get("feature_id")) != TYPE_STRING_NAME: return false
	if quote != get_feature_research_quote(quote.get("feature_id",&"")) or not quote.can_admit: return false
	var plan := StudioFinanceLedger.plan(_studio_finance,_completed_run_cycles,_cash_cents,-int(quote.down_cents),&"store",0,0,false,StringName(str(quote.entry_id)+":admit")) if _first_studio_economy else {"cash_cents":_cash_cents-int(quote.down_cents),"ledger":_studio_finance}
	if plan.is_empty(): return false
	_feature_purchase_in_progress = true
	_feature_research.append({"id":quote.entry_id,"feature_id":quote.feature_id,"base_cents":quote.base_cents,"actions":1,"admitted_cycle":_completed_run_cycles,"payments":[]})
	_cash_cents = plan.cash_cents
	_studio_finance = plan.ledger
	cash_changed.emit()
	finance_changed.emit()
	features_changed.emit()
	_feature_purchase_in_progress = false
	return true


func research_feature(quote: Dictionary) -> bool:
	if not can_mutate_checkpoint() or _feature_purchase_in_progress or _productive_cycle_in_progress or _publishing_cycle: return false
	if quote.is_empty() or typeof(quote.get("feature_id")) != TYPE_STRING_NAME: return false
	if quote != get_feature_research_quote(quote.get("feature_id",&"")) or not quote.can_research: return false
	var commit := func() -> bool:
		for entry: Dictionary in _feature_research:
			if entry.id != quote.entry_id: continue
			entry.payments.append({"cycle":_completed_run_cycles+1,"nominal_cents":quote.nominal_cents,"discount_percent":quote.discount_percent,"paid_cents":quote.due_cents,"saving_cents":quote.saving_cents,"window":quote.resourceful_window})
			if quote.saving_cents > 0: _resourceful_claims[_released_games.size()] = quote.entry_id
			if entry.payments.size() == entry.actions: _owned_features[entry.feature_id] = true
			return true
		return false
	return complete_productive_action(commit,-int(quote.due_cents),quote.cycle,&"",&"store",StringName("%s:%d" % [quote.entry_id,quote.completed]))


## The new-run boundary supplies the locked starting amount explicitly. The
## current prototype Gameplay boundary uses $0; future funding may revise it.
func initialize_cash(starting_cash: Variant) -> bool:
	if typeof(starting_cash) != TYPE_INT or starting_cash < 0 or starting_cash > MAX_SIGNED_INT / CENTS_PER_DOLLAR:
		push_warning("Starting cash must be a nonnegative whole-dollar integer.")
		return false
	return initialize_cash_cents(starting_cash * CENTS_PER_DOLLAR)


func initialize_cash_cents(starting_cash_cents: Variant) -> bool:
	if _productive_cycle_in_progress or _publishing_cycle:
		return false
	if _cash_initialized:
		push_warning("Run cash has already been initialized.")
		return false
	if typeof(starting_cash_cents) != TYPE_INT or starting_cash_cents < 0:
		push_warning("Starting cash cents must be a nonnegative integer.")
		return false
	_cash_cents = starting_cash_cents
	_cash_initialized = true
	cash_changed.emit()
	return true


func is_cash_initialized() -> bool:
	return _cash_initialized


## Legacy whole-dollar view. Existing gameplay uses dollar-aligned mutations;
## financial detail and future settlement must use get_cash_cents().
## Returns -1 while cash is intentionally uninitialized.
func get_cash() -> int:
	return _cash_cents / CENTS_PER_DOLLAR if _cash_initialized else -1


func get_cash_cents() -> int:
	return _cash_cents if _cash_initialized else -1


## Adds already-calculated income. Card resolution remains outside RunState.
func add_cash(amount: Variant) -> bool:
	if typeof(amount) != TYPE_INT or amount < 0 or amount > MAX_SIGNED_INT / CENTS_PER_DOLLAR:
		push_warning("Cash additions must be nonnegative whole-dollar integers.")
		return false
	return add_cash_cents(amount * CENTS_PER_DOLLAR)


func add_cash_cents(amount_cents: Variant, kind: StringName = &"other_income", source_id: StringName = &"") -> bool:
	if not can_mutate_checkpoint(): return false
	if _publishing_cycle or (_productive_cycle_in_progress and not _committing_cycle_cash):
		return false
	if not _cash_initialized:
		push_warning("Run cash must be initialized before income is added.")
		return false
	if typeof(amount_cents) != TYPE_INT or amount_cents < 0:
		push_warning("Cash-cent additions must be nonnegative integers.")
		return false
	if amount_cents == 0:
		return true
	if amount_cents > MAX_SIGNED_INT - _cash_cents:
		push_warning("Cash overflowed.")
		return false
	if _first_studio_economy and not _committing_cycle_cash:
		var plan := StudioFinanceLedger.plan(_studio_finance, _completed_run_cycles, _cash_cents, amount_cents, kind, 0, 0, false, source_id)
		if plan.is_empty(): return false
		_cash_cents = plan.cash_cents
		_studio_finance = plan.ledger
		finance_changed.emit()
	else:
		_cash_cents += amount_cents
	cash_changed.emit()
	return true


## Atomically spends an already-calculated whole-dollar cost.
func spend_cash(amount: Variant) -> bool:
	if typeof(amount) != TYPE_INT or amount < 0 or amount > MAX_SIGNED_INT / CENTS_PER_DOLLAR:
		push_warning("Cash costs must be nonnegative whole-dollar integers.")
		return false
	return spend_cash_cents(amount * CENTS_PER_DOLLAR)


func spend_cash_cents(amount_cents: Variant, kind: StringName = &"other_expense", source_id: StringName = &"") -> bool:
	if not can_mutate_checkpoint(): return false
	if _publishing_cycle or (_productive_cycle_in_progress and not _committing_cycle_cash):
		return false
	if not _cash_initialized:
		push_warning("Run cash must be initialized before spending.")
		return false
	if typeof(amount_cents) != TYPE_INT or amount_cents < 0:
		push_warning("Cash-cent costs must be nonnegative integers.")
		return false
	if amount_cents > _cash_cents:
		push_warning("Run cash cannot cover this cost.")
		return false
	if amount_cents == 0:
		return true
	if _first_studio_economy and not _committing_cycle_cash:
		var plan := StudioFinanceLedger.plan(_studio_finance, _completed_run_cycles, _cash_cents, -amount_cents, kind, 0, 0, false, source_id)
		if plan.is_empty(): return false
		_cash_cents = plan.cash_cents
		_studio_finance = plan.ledger
		finance_changed.emit()
	else:
		_cash_cents -= amount_cents
	cash_changed.emit()
	return true


func get_completed_run_cycles() -> int:
	return _completed_run_cycles


func get_available_redraws() -> int:
	return _available_redraws


func can_consume_redraw(count: int = 1) -> bool:
	return not _productive_cycle_in_progress and count > 0 and _available_redraws >= count


func consume_redraw(count: int = 1) -> bool:
	if not can_mutate_checkpoint(): return false
	if _publishing_cycle:
		return false
	if not can_consume_redraw(count):
		return false
	_available_redraws -= count
	redraws_changed.emit()
	return true


func refresh_redraws() -> void:
	if _productive_cycle_in_progress or _publishing_cycle:
		return
	if _available_redraws == MAX_REDRAWS:
		return
	_available_redraws = MAX_REDRAWS
	redraws_changed.emit()


func get_current_month() -> int:
	return (_completed_run_cycles / 2) + 1


func get_current_year() -> int:
	return START_YEAR + _completed_run_cycles / 24


func get_current_half() -> int:
	return (_completed_run_cycles % 2) + 1


func get_calendar_label() -> String:
	var half_label := "First Half" if get_current_half() == 1 else "Second Half"
	return "%d · Month %d, %s" % [get_current_year(), get_current_month(), half_label]


func can_advance_calendar_cycle() -> bool:
	return can_complete_productive_cycle()


## A free phase exit validates current state, not a hypothetical paid cycle.
## Keep capacity/reentrancy/provenance guards; do not earn sales or service rent.
func can_transition_without_productive_cycle() -> bool:
	if _productive_cycle_in_progress or _publishing_cycle or _feature_purchase_in_progress or _pending_contract_completion != null or _completed_run_cycles < 0 or _completed_run_cycles == MAX_SIGNED_INT or _available_redraws < 0 or _available_redraws > MAX_REDRAWS or _cash_cents < 0:
		return false
	for id: StringName in _released_games:
		if not _cash_initialized or not _released_games[id] is Dictionary or _released_games[id].get("release_id") != id or not ReleasedGameSales.is_valid(_released_games[id]):
			return false
	return not _first_studio_economy or get_studio_finance_report().get("available", false)


func will_next_cycle_cross_month_boundary() -> bool:
	return _completed_run_cycles < MAX_SIGNED_INT and get_current_half() == 2


## Compatibility entry point. All consequences use the same transaction below.
func advance_calendar_cycle() -> bool:
	return complete_productive_action()


func can_register_release(project: ProjectState) -> bool:
	if _productive_cycle_in_progress or project == null or not _cash_initialized or not project.is_launch_ready() or not project.has_month_one_sales_revenue_result():
		return false
	var id := project.get_release_id()
	var projection := project.get_month_one_sales_revenue_result()
	var checked := PrimitiveMonthOneSalesRevenueCalculator.calculate_for_total_units(projection.get_total_month_one_units())
	if id.is_empty() or checked == null or checked.get_projected_month_one_net_cents() != projection.get_projected_month_one_net_cents():
		return false
	var expected_record := _create_release_sales_record(project)
	if expected_record.is_empty():
		return false
	if _released_games.has(id):
		if not ReleasedGameSales.is_valid(_released_games[id]) or _released_games[id].total_units != projection.get_total_month_one_units() or not _release_metadata.has(id):
			return false
		var metadata: Dictionary = _release_metadata[id]
		return metadata.base_name == project.get_base_name() and metadata.genre == project.get_genre_id() and metadata.theme == project.get_theme_id() and metadata.genre_ratios == project.get_genre_ratios() and _released_games[id].get("review_tenths", -1) == expected_record.get("review_tenths", -1) and _released_games[id].get("launch_awareness", -1) == expected_record.get("launch_awareness", -1) and _released_games[id].get("market_bp", -1) == expected_record.get("market_bp", -1)
	return project.get_awareness_result().get_promotion_awards()==get_pending_promotion_awards()


func _create_release_sales_record(project: ProjectState) -> Dictionary:
	if project == null or project.get_review_result() == null or project.get_awareness_result() == null or project.get_launch_market_context_result() == null:
		return {}
	return ReleasedGameSales.create(project.get_release_id(), project.get_month_one_sales_revenue_result().get_total_month_one_units(),
		roundi(project.get_review_result().get_final_review() * 10.0), project.get_awareness_result().get_total_awareness(),
		project.get_launch_market_context_result().get_forecast_multiplier_basis_points())


func register_release(project: ProjectState) -> bool:
	if not can_mutate_checkpoint(): return false
	if _publishing_cycle:
		return false
	if not can_register_release(project):
		return false
	var id := project.get_release_id()
	if _released_games.has(id):
		return true
	var year := get_current_year()
	var title := _resolve_release_title(project.get_base_name(), year)
	var record := _create_release_sales_record(project)
	record.base_name = project.get_base_name()
	record.release_title = title
	record.release_year = year
	_released_games[id] = record
	_release_metadata[id] = {"base_name": project.get_base_name(), "genre": project.get_genre_id(),
		"theme": project.get_theme_id(), "genre_ratios": project.get_genre_ratios(),
		"release_title": title, "release_year": year, "release_cycle": _completed_run_cycles,
		"review": _capture_release_review(project)}
	for offer_id: StringName in project.get_awareness_result().get_promotion_awards():
		_promotion_consumed[offer_id] = id
	# Qualification is captured only on the first committed registration. Existing
	# entitlements (including legacy under-Scope offers) are never re-evaluated.
	if project.get_current_scope() >= project.get_required_scope():
		_sidestreet_entitlements[id] = {"offer_id": StringName("%s:%s" % [ContractState.SIDESTREET_CONTRACT_ID, id]), "state": null}
	_refresh_publisher_unlocks()
	sales_changed.emit()
	return true

func _capture_release_review(project: ProjectState) -> Dictionary:
	var review := project.get_review_result()
	var awareness := project.get_awareness_result()
	var units := project.get_units_sold_result()
	var revenue := project.get_month_one_sales_revenue_result()
	var context := project.get_launch_market_context_result()
	var cores: Array[int] = []
	var standards: Array[int] = []
	for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
		cores.append(project.get_core_score(category))
		standards.append(review.get_standard(category))
	return {"final_review": review.get_final_review(), "production_rating": review.get_production_rating(),
		"scope_completion": review.get_scope_completion(), "scope": project.get_current_scope(),
		"required_scope": project.get_required_scope(), "development_cycles": project.get_current_cycle(),
		"cores": cores, "standards": standards, "remaining_bugs": project.get_remaining_bugs(),
		"awareness": awareness.get_total_awareness(), "launch_marketing": awareness.get_launch_marketing(),
		"projected_units": units.get_final_units_sold(), "projected_gross_cents": revenue.get_projected_month_one_gross_cents(),
		"projected_net_cents": revenue.get_projected_month_one_net_cents(),
		"forecast_id": context.get_forecast_id_for_authority() if context.was_forecast_revealed_at_launch() else &"",
		"forecast_multiplier": context.get_forecast_multiplier_text() if context.was_forecast_revealed_at_launch() else "",
		"competitor_id": context.get_competitor_id_for_authority() if context.was_competitor_revealed_at_launch() else &"",
		"competitor_target_cycle": context.get_competitor_target_cycle() if context.was_competitor_revealed_at_launch() else -1}


func get_released_game_sales(release_id: StringName) -> Dictionary:
	return _released_games.get(release_id, {}).duplicate(true)


func get_released_game_monthly_report(release_id: StringName) -> Dictionary:
	if not _release_metadata.has(release_id) or not _released_games.has(release_id): return {}
	var release_cycle: Variant = _release_metadata[release_id].get("release_cycle", null)
	if typeof(release_cycle) != TYPE_INT or release_cycle < 0: return {}
	return ReleasedGameMonthlyReport.build(_released_games[release_id], release_cycle)


## An offer is anchored to the current release-age cycle, not the calendar month.
func get_post_launch_campaign_offer(release_id: StringName) -> Dictionary:
	if not _released_games.has(release_id):
		return {}
	var record: Dictionary = _released_games[release_id]
	var eligible := ReleasedGameSales.can_campaign(record)
	return {"release_id": release_id, "price_cents": POST_LAUNCH_CAMPAIGN_COST_CENTS,
		"eligible": eligible, "affordable": _cash_initialized and _cash_cents >= POST_LAUNCH_CAMPAIGN_COST_CENTS,
		"can_purchase": eligible and can_complete_productive_cycle(-POST_LAUNCH_CAMPAIGN_COST_CENTS, release_id)}


func purchase_post_launch_campaign(release_id: StringName, expected_cycle: int) -> bool:
	if not can_mutate_checkpoint(): return false
	if expected_cycle != _completed_run_cycles or get_post_launch_campaign_offer(release_id).get("can_purchase", false) != true:
		return false
	return complete_productive_action(Callable(), -POST_LAUNCH_CAMPAIGN_COST_CENTS, expected_cycle, release_id, &"campaign", release_id)


func get_release_metadata(release_id: StringName) -> Dictionary:
	return _release_metadata.get(release_id, {}).duplicate(true)


func get_released_game_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_released_games.keys())
	return ids


func get_project_display_name(project: ProjectState) -> String:
	if project == null or project.get_base_name().is_empty():
		return "Post Game Summary"
	var id := project.get_release_id()
	if _release_metadata.has(id):
		return get_released_game_display_name(id)
	# Unreleased projects show their base name; reading never resolves a title.
	return project.get_base_name()


func get_released_game_display_name(id: StringName) -> String:
	var metadata := get_release_metadata(id)
	if metadata.is_empty() or str(metadata.get("release_title", "")).is_empty():
		return "Post Game Summary"
	return metadata.release_title


## Called once at launch registration, never while browsing or reconstructing.
func _resolve_release_title(base_name: String, release_year: int) -> String:
	if base_name.is_empty():
		return ""
	for other_id: StringName in _release_metadata:
		if _release_metadata[other_id].base_name == base_name:
			return "%s (%d)" % [base_name, release_year]
	return base_name


func is_primitive_contract_offer_available() -> bool:
	return not _released_games.is_empty() and _primitive_contract == null and get_active_contract() == null and not _productive_cycle_in_progress and not _publishing_cycle


func get_ironclad_advance_cents() -> int:
	return 55000 if StudioTraits.is_active(_studio_traits,&"publisher_connections") else 40000


func accept_primitive_contract() -> ContractState:
	if not can_mutate_checkpoint(): return null
	if studio_departure_guard.is_valid() and not studio_departure_guard.call(): return null
	if not is_primitive_contract_offer_available():
		return null
	if not _cash_initialized or _cash_cents > MAX_SIGNED_INT - get_ironclad_advance_cents():
		return null
	var accepted := ContractState.new(_primitive_contract_eligible_ids())
	accepted._publisher_connections = StudioTraits.is_active(_studio_traits,&"publisher_connections")
	if not accepted.commit_upfront():
		return null
	# Block observers until both ownership and the exact-cent guarantee commit.
	var was_blocked := is_blocking_signals()
	set_block_signals(true)
	_primitive_contract = accepted
	if not add_cash_cents(accepted.get_advance_cents(), &"publisher_receipt", accepted.get_offer_id()):
		_primitive_contract = null
		set_block_signals(was_blocked)
		return null
	set_block_signals(was_blocked)
	cash_changed.emit()
	contracts_changed.emit()
	finance_changed.emit()
	return _primitive_contract


func get_primitive_contract() -> ContractState:
	return _primitive_contract


func get_active_contract() -> ContractState:
	for offer: Dictionary in _publisher_offers.values():
		var state: ContractState = offer.state
		if state!=null and not state.is_completed(): return state
	if _primitive_contract != null and not _primitive_contract.is_completed():
		return _primitive_contract
	for release_id: StringName in _sidestreet_entitlements:
		var state: ContractState = _sidestreet_entitlements[release_id].state
		if state != null and not state.is_completed():
			return state
	return null


func owns_contract_state(state: ContractState) -> bool:
	for offer: Dictionary in _publisher_offers.values():
		if offer.state==state and state!=null: return true
	if state == null:
		return false
	if _primitive_contract == state:
		return true
	for entitlement: Dictionary in _sidestreet_entitlements.values():
		if entitlement.state == state:
			return true
	return false


func get_next_sidestreet_offer() -> Dictionary:
	if not _unlocked_publishers.has(PublisherCatalog.SIDESTREET):
		return {}
	for release_id: StringName in _sidestreet_entitlements:
		var entitlement: Dictionary = _sidestreet_entitlements[release_id]
		if entitlement.state == null:
			return {"offer_id": entitlement.offer_id, "release_id": release_id}
	return {}


func get_sidestreet_offer_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for entitlement: Dictionary in _sidestreet_entitlements.values():
		result.append(entitlement.offer_id)
	return result


func get_sidestreet_completion_history() -> Dictionary:
	return _sidestreet_results.duplicate(true)


func is_sidestreet_offer_available() -> bool:
	return get_active_contract() == null and not get_next_sidestreet_offer().is_empty() and not _productive_cycle_in_progress and not _publishing_cycle


func accept_sidestreet_offer(offer_id: StringName) -> ContractState:
	if not can_mutate_checkpoint(): return null
	if studio_departure_guard.is_valid() and not studio_departure_guard.call(): return null
	if not is_sidestreet_offer_available() or offer_id.is_empty():
		return null
	var next := get_next_sidestreet_offer()
	if next.offer_id != offer_id:
		return null
	var release_id: StringName = next.release_id
	var accepted := ContractState.new(_primitive_contract_eligible_ids(), ContractState.SIDESTREET_CONTRACT_ID, offer_id, release_id)
	if not accepted.commit_upfront():
		return null
	var entitlement: Dictionary = _sidestreet_entitlements[release_id]
	entitlement.state = accepted
	_sidestreet_entitlements[release_id] = entitlement
	contracts_changed.emit()
	return accepted


func _primitive_contract_eligible_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for entry: Dictionary in FeatureStoreCatalog.starting_features():
		var id := StringName(entry.id)
		if owns_feature(id) and StringName(entry.phase) in [CardData.PHASE_DESIGN, CardData.PHASE_ALPHA]:
			ids.append(id)
	return ids


## Called only as the direct-effects callback of the central productive cycle.
func commit_contract_hand(state: ContractState, cards: Array[CardData], expected_payment_cents: int) -> bool:
	if not _productive_cycle_in_progress or get_active_contract() != state or not owns_contract_state(state):
		return false
	var plan := state.plan_hand(cards)
	if plan.is_empty() or plan.remainder_cents != expected_payment_cents:
		return false
	if plan.completing and _publisher_offers.has(state.get_offer_id()) and _promotion_awards.has(state.get_offer_id()): return false
	if state.get_contract_id() == ContractState.SIDESTREET_CONTRACT_ID and plan.completing:
		if _sidestreet_results.has(state.get_offer_id()) or not _sidestreet_entitlements.has(state.get_source_release_id()):
			return false
		var entitlement: Dictionary = _sidestreet_entitlements[state.get_source_release_id()]
		if entitlement.offer_id != state.get_offer_id() or entitlement.state != state:
			return false
	if not state.commit_hand(cards, expected_payment_cents):
		return false
	if state.is_completed():
		_pending_contract_completion = state
	return true


func _record_paid_contract_completion() -> void:
	var state := _pending_contract_completion
	if state == null:
		return
	_pending_contract_completion = null
	if _publisher_offers.has(state.get_offer_id()):
		_promotion_awards[state.get_offer_id()] = state.get_result().get_promotion()
		return
	if state == _primitive_contract:
		_ironclad_completion_committed = true
		return
	var result := state.get_result()
	var cores: Dictionary = {}
	for category: ProjectState.CoreScore in PriorityAllocation.CORE_CATEGORIES:
		cores[category] = result.get_core_score_half_units(category)
	_sidestreet_results[state.get_offer_id()] = {"offer_id": state.get_offer_id(), "release_id": state.get_source_release_id(),
		"scope": result.get_scope(), "core_half_units": cores, "completion_numerator": result.get_completion_numerator(),
		"payout_cents": result.get_payout_cents()}


func get_completed_contract_count() -> int:
	var ironclad := 1 if _ironclad_completion_committed else 0
	var trials := 0
	for offer: Dictionary in _publisher_offers.values():
		var state: ContractState = offer.state
		if state!=null and state.is_completed() and state.is_payout_committed(): trials += 1
	return ironclad + _sidestreet_results.size() + trials


func get_unlocked_publisher_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(_unlocked_publishers.keys())
	return ids


func get_pending_publisher_notifications() -> Array[StringName]:
	return _pending_publisher_notifications.duplicate()


## Presentation-only acknowledgment. Studio consumes these once when a banner
## is shown; opening or reconstructing a browser never grants an unlock.
func take_pending_publisher_notifications() -> Array[StringName]:
	var pending := _pending_publisher_notifications.duplicate()
	_pending_publisher_notifications.clear()
	return pending


func get_publisher_status(id: StringName) -> Dictionary:
	for entry: Dictionary in PublisherCatalog.entries():
		if entry.id != id:
			continue
		var released := _released_games.size()
		var contracts := get_completed_contract_count()
		var requirement := ""
		match id:
			PublisherCatalog.IRONCLAD:
				requirement = "Release your first game (%d / 1)." % released
			PublisherCatalog.SIDESTREET:
				requirement = "Complete the Ironclad Contract (%d / 1)." % int(_ironclad_completion_committed)
			PublisherCatalog.CROWN_QUILL:
				requirement = "Release any game with Final Review 7.0 or higher."
			PublisherCatalog.NEON_CIRCUIT:
				requirement = "Release any game with committed Total Awareness 125 or higher."
			PublisherCatalog.STARWAVE:
				requirement = "Release at least two games (%d / 2) and complete at least three contracts (%d / 3)." % [released, contracts]
		var availability: String = entry.availability
		if id in [PublisherCatalog.CROWN_QUILL, PublisherCatalog.NEON_CIRCUIT]:
			for offer: Dictionary in _publisher_offers.values():
				if offer.publisher_id != id: continue
				var state: ContractState = offer.state
				if state == null:
					availability = "Contract available from Contracts. This one-time offer does not expire."
					if get_active_contract() != null:
						availability = "Contract pending. Finish the active Contract first; this offer does not expire."
				elif state.is_completed() and state.is_payout_committed():
					availability = "One-time Contract completed. Cash and Promotion have been awarded."
				else:
					availability = "Contract in progress. Resume it from Contracts."
				break
		return {"id": id, "name": entry.name, "personality": entry.personality,
			"availability": availability, "unlocked": _unlocked_publishers.has(id),
			"requirement": requirement}
	return {}


func _refresh_publisher_unlocks() -> bool:
	var changed := false
	for entry: Dictionary in PublisherCatalog.entries():
		var id: StringName = entry.id
		if _unlocked_publishers.has(id) or not _meets_publisher_requirement(id):
			continue
		_unlocked_publishers[id] = true
		if id in [PublisherCatalog.CROWN_QUILL,PublisherCatalog.NEON_CIRCUIT]:
			var offer_id := StringName("%s:%s:first" % [_bank_run_id,id])
			var source: StringName
			for release_id: StringName in _release_metadata:
				var frozen: Dictionary = _release_metadata[release_id].review
				if (id==PublisherCatalog.CROWN_QUILL and frozen.final_review>=7.0) or (id==PublisherCatalog.NEON_CIRCUIT and frozen.awareness>=125):
					source = release_id
					break
			_publisher_offers[offer_id] = {"publisher_id":id,"source_release_id":source,"state":null}
		_pending_publisher_notifications.append(id)
		changed = true
	if changed:
		publishers_changed.emit()
	return changed


func _meets_publisher_requirement(id: StringName) -> bool:
	match id:
		PublisherCatalog.IRONCLAD:
			return not _released_games.is_empty()
		PublisherCatalog.SIDESTREET:
			return _ironclad_completion_committed
		PublisherCatalog.CROWN_QUILL:
			for metadata: Dictionary in _release_metadata.values():
				var snapshot: Dictionary = metadata.get("review", {})
				if float(snapshot.get("final_review", -1.0)) >= 7.0:
					return true
		PublisherCatalog.NEON_CIRCUIT:
			for metadata: Dictionary in _release_metadata.values():
				var snapshot: Dictionary = metadata.get("review", {})
				if int(snapshot.get("awareness", -1)) >= 125:
					return true
		PublisherCatalog.STARWAVE:
			return _released_games.size() >= 2 and get_completed_contract_count() >= 3
	return false


func can_complete_productive_cycle(direct_cash_delta_cents: int = 0, campaign_release_id: StringName = &"") -> bool:
	return not _plan_productive_cycle(direct_cash_delta_cents, campaign_release_id).is_empty()


func _plan_productive_cycle(direct_cash_delta_cents: int, campaign_release_id: StringName = &"", finance_kind: StringName = &"", source_id: StringName = &"") -> Dictionary:
	if _productive_cycle_in_progress or _feature_purchase_in_progress or _pending_contract_completion != null or _completed_run_cycles < 0 or _completed_run_cycles == MAX_SIGNED_INT or _available_redraws < 0 or _available_redraws > MAX_REDRAWS:
		return {}
	if not campaign_release_id.is_empty() and (direct_cash_delta_cents != -POST_LAUNCH_CAMPAIGN_COST_CENTS or not _released_games.has(campaign_release_id) or not ReleasedGameSales.can_campaign(_released_games[campaign_release_id])):
		return {}
	if direct_cash_delta_cents != 0 and not _cash_initialized:
		return {}
	if direct_cash_delta_cents < -_cash_cents or direct_cash_delta_cents > MAX_SIGNED_INT - _cash_cents:
		return {}
	var cash_after_action := _cash_cents + direct_cash_delta_cents
	var next_records: Dictionary = {}
	var payable := 0
	var earned := 0
	for id: StringName in _released_games:
		if not _cash_initialized or not _released_games[id] is Dictionary or _released_games[id].get("release_id") != id:
			return {}
		var next := ReleasedGameSales.next_cycle(_released_games[id], _completed_run_cycles + 1, will_next_cycle_cross_month_boundary(), id == campaign_release_id)
		if next.is_empty():
			return {}
		var release_payable: int = next.settled_cents - _released_games[id].settled_cents
		if release_payable > MAX_SIGNED_INT - payable:
			return {}
		payable += release_payable
		var release_earned: int = next.entitlement_cents - _released_games[id].entitlement_cents
		if release_earned < 0 or release_earned > MAX_SIGNED_INT - earned: return {}
		earned += release_earned
		next_records[id] = next
	if payable > MAX_SIGNED_INT - cash_after_action:
		return {}
	var finance_plan: Dictionary = {}
	if _first_studio_economy:
		if finance_kind.is_empty():
			finance_kind = &"campaign" if not campaign_release_id.is_empty() else (&"other_expense" if direct_cash_delta_cents < 0 else (&"other_income" if direct_cash_delta_cents > 0 else &"calendar"))
		finance_plan = StudioFinanceLedger.plan(_studio_finance, _completed_run_cycles + 1, _cash_cents, direct_cash_delta_cents, finance_kind, earned, payable, true, source_id)
		if finance_plan.is_empty(): return {}
	return {"records": next_records, "payable": payable, "finance": finance_plan}


## The direct-effects callback must be synchronous and atomic on false, using
## its phase's validated transaction. Direct cash delta is applied HERE, not
## inside the callback. All fallible run consequences preflight
## BEFORE that callback. expected_cycle lets delayed callers reject replays.
## All release records preflight together; settlement sums checked integer cents.
## Direct effects -> income/spend -> calendar/sales settlement -> due rent and
## oldest arrears -> report -> notifications. No await can split this boundary.
func complete_productive_action(direct_effects: Callable = Callable(), direct_cash_delta_cents: int = 0, expected_cycle: int = -1, campaign_release_id: StringName = &"", finance_kind: StringName = &"", source_id: StringName = &"") -> bool:
	if not can_mutate_checkpoint(): return false
	if _publishing_cycle:
		return false
	if expected_cycle != -1 and expected_cycle != _completed_run_cycles:
		return false
	var plan := _plan_productive_cycle(direct_cash_delta_cents, campaign_release_id, finance_kind, source_id)
	if plan.is_empty():
		return false
	var cash_before := _cash_cents
	var redraws_before := _available_redraws
	var familiarity_before := _familiarity.duplicate()
	var ownership_before := _owned_features.duplicate()
	var publishers_before := _unlocked_publishers.duplicate()
	var completed_contracts_before := get_completed_contract_count()
	var employees_before := _employees.duplicate(true)
	_productive_cycle_in_progress = true
	# Publish run notifications only after cash and sales have committed together.
	var was_blocked := is_blocking_signals()
	set_block_signals(true)
	if direct_effects.is_valid() and not direct_effects.call():
		_pending_contract_completion = null
		set_block_signals(was_blocked)
		_productive_cycle_in_progress = false
		return false
	_committing_cycle_cash = true
	if direct_cash_delta_cents > 0:
		add_cash_cents(direct_cash_delta_cents)
	elif direct_cash_delta_cents < 0:
		spend_cash_cents(-direct_cash_delta_cents)
	# Cash is now committed; only then publish a distinct completion record.
	_record_paid_contract_completion()
	_completed_run_cycles += 1
	_available_redraws = mini(MAX_REDRAWS, _available_redraws + 1)
	_released_games = plan.records
	if plan.payable > 0:
		add_cash_cents(plan.payable)
	if not plan.finance.is_empty():
		spend_cash_cents(plan.finance.bills_paid_cents)
		_studio_finance = plan.finance.ledger
	_refresh_publisher_unlocks()
	_committing_cycle_cash = false
	set_block_signals(was_blocked)
	_productive_cycle_in_progress = false
	_publishing_cycle = true
	if _cash_cents != cash_before:
		cash_changed.emit()
	if not plan.finance.is_empty():
		finance_changed.emit()
	if _available_redraws != redraws_before:
		redraws_changed.emit()
	if _familiarity != familiarity_before or _owned_features != ownership_before:
		features_changed.emit()
	if _unlocked_publishers != publishers_before:
		publishers_changed.emit()
	if get_completed_contract_count() != completed_contracts_before:
		contracts_changed.emit()
	if not _released_games.is_empty():
		sales_changed.emit()
	calendar_changed.emit()
	if _employees != employees_before: employees_changed.emit()
	_publishing_cycle = false
	return true


func get_employees() -> Dictionary:
	return _employees.duplicate(true)


func get_production_hire_quote() -> Dictionary:
	if not _first_studio_economy or _released_games.is_empty() or not EmployeeRoster.valid(_employees) or not _employees.employees.is_empty(): return {}
	return StudioFinanceLedger.hire_quote(_studio_finance,_bank_run_id)


func hire_production_specialist(quote: Dictionary) -> bool:
	if not can_mutate_checkpoint(): return false
	if not _bank_action_available() or quote.is_empty() or quote != get_production_hire_quote(): return false
	var finance := StudioFinanceLedger.hire_employee(_studio_finance,quote,_bank_run_id)
	var roster := EmployeeRoster.hire(_employees,quote.employee_id,_completed_run_cycles)
	if finance.is_empty() or roster.is_empty(): return false
	_studio_finance = finance.ledger
	_cash_cents = finance.cash_cents
	_employees = roster
	_publishing_cycle = true
	cash_changed.emit()
	finance_changed.emit()
	employees_changed.emit()
	_publishing_cycle = false
	return true


func plan_employee_hand(project: ProjectState, phase: StringName, cards: Array, before: Dictionary, proposed: Dictionary = {}) -> Dictionary:
	if project == null or not EmployeeRoster.valid(_employees): return {}
	if _employees.employees.is_empty(): return {"before":_employees.duplicate(true),"after":_employees.duplicate(true),"cycle":_completed_run_cycles} if proposed.is_empty() else {}
	var roster := EmployeeRoster.plan_hand(_employees,project.get_release_id(),phase,project.get_current_cycle(),_completed_run_cycles,cards,before,proposed)
	if roster.is_empty(): return {}
	return {"before":_employees.duplicate(true),"after":roster,"cycle":_completed_run_cycles}


func can_commit_employee_hand(plan: Dictionary) -> bool:
	return not plan.is_empty() and plan.get("before") == _employees and plan.get("cycle") == _completed_run_cycles


## Called only inside the already preflighted production callback.
func commit_employee_hand(plan: Dictionary) -> void:
	_employees = plan.after


func trait_launch_awareness(raw: int) -> int:
	return StudioTraits.launch_awareness(_studio_traits, raw, _released_games.is_empty())


func lean_discount(normal_cents: int, project_id: StringName) -> int:
	if normal_cents <= 0 or project_id.is_empty() or not StudioTraits.is_active(_studio_traits, &"lean_production"): return 0
	return mini(normal_cents / 10, maxi(0, 10000 - int(_lean_savings.get(project_id, 0))))

func get_lean_savings() -> Dictionary:
	return _lean_savings.duplicate(true)

func get_pending_publisher_offer_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id: StringName in _publisher_offers:
		if _publisher_offers[id].state==null: ids.append(id)
	return ids

func get_pending_promotion_awards() -> Dictionary:
	var pending := {}
	for id: StringName in _promotion_awards:
		if not _promotion_consumed.has(id): pending[id] = _promotion_awards[id]
	return pending

func get_pending_promotion() -> int:
	var total := 0
	for points: int in get_pending_promotion_awards().values():
		if points<0 or points>MAX_SIGNED_INT-total: return -1
		total += points
	return total

func get_release_promotion(release: StringName) -> int:
	var total := 0
	for id: StringName in _promotion_consumed:
		if _promotion_consumed[id]==release: total += int(_promotion_awards[id])
	return total

func get_pending_contract_choices() -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	if get_active_contract()!=null: return choices
	if is_primitive_contract_offer_available(): choices.append({"offer_id":ContractState.CONTRACT_ID,"label":"Ironclad Interactive"})
	if _unlocked_publishers.has(PublisherCatalog.SIDESTREET):
		for release: StringName in _sidestreet_entitlements:
			var offer: Dictionary = _sidestreet_entitlements[release]
			if offer.state==null: choices.append({"offer_id":offer.offer_id,"label":"SideStreet — "+get_released_game_display_name(release)})
	for id: StringName in get_pending_publisher_offer_ids():
		choices.append({"offer_id":id,"label":PublisherCatalog.name_for(_publisher_offers[id].publisher_id)})
	return choices

func get_publisher_contract_offer(id: StringName) -> Dictionary:
	if not _publisher_offers.has(id) or _publisher_offers[id].state!=null or get_active_contract()!=null: return {}
	var offer: Dictionary = _publisher_offers[id]
	var eligible := _primitive_contract_eligible_ids()
	var kind := PublisherTrialTerms.contract_id(offer.publisher_id)
	return {"offer_id":id,"publisher_id":offer.publisher_id,"source_release_id":offer.source_release_id,"eligible":eligible,"focus":PublisherTrialTerms.focus(eligible) if kind==PublisherTrialTerms.NEON else -1,"terms":PublisherTrialTerms.terms(kind),"cycle":_completed_run_cycles,"finance_revision":_studio_finance.get("actions",[]).size()}

func accept_publisher_contract(quote: Dictionary) -> ContractState:
	if not can_mutate_checkpoint() or _publishing_cycle or _productive_cycle_in_progress: return null
	if studio_departure_guard.is_valid() and not studio_departure_guard.call(): return null
	if typeof(quote.get("offer_id"))!=TYPE_STRING_NAME: return null
	var current := get_publisher_contract_offer(quote.offer_id)
	if current.is_empty() or current!=quote: return null
	var kind := PublisherTrialTerms.contract_id(quote.publisher_id)
	var eligible: Array[StringName] = []
	eligible.assign(quote.eligible)
	var accepted := ContractState.new(eligible,kind,quote.offer_id,quote.source_release_id)
	if not accepted.freeze_trial(quote.focus) or not accepted.commit_upfront(): return null
	var was_blocked := is_blocking_signals()
	set_block_signals(true)
	_publisher_offers[quote.offer_id].state = accepted
	var advance := accepted.get_advance_cents()
	if advance>0 and not add_cash_cents(advance,&"publisher_receipt",quote.offer_id):
		_publisher_offers[quote.offer_id].state = null
		set_block_signals(was_blocked)
		return null
	set_block_signals(was_blocked)
	_publishing_cycle = true
	if advance>0:
		cash_changed.emit()
		finance_changed.emit()
	contracts_changed.emit()
	_publishing_cycle = false
	return accepted

func commit_lean_saving(project_id: StringName, expected_saved: int, saving: int) -> bool:
	if not _productive_cycle_in_progress or project_id.is_empty() or int(_lean_savings.get(project_id, 0)) != expected_saved or saving < 0 or saving > 10000 - expected_saved: return false
	if saving > 0: _lean_savings[project_id] = expected_saved + saving
	return true
