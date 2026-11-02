class_name RunState
extends RefCounted

const ContractSearch := preload("res://scripts/contracts/contract_search.gd")
const MAX_SIGNED_INT: int = 9223372036854775807

signal cash_changed
signal calendar_changed
signal redraws_changed
signal features_changed
signal sales_changed
signal contracts_changed
signal publishers_changed
signal finance_changed
signal fans_changed
signal employees_changed
signal engines_changed

const CENTS_PER_DOLLAR := 100
const MAX_REDRAWS := 4
const Calendar := preload("res://scripts/calendar/calendar_clock.gd")
const START_YEAR := 1980
const FIRST_STUDIO_CASH_CENTS := 550000
const POST_LAUNCH_CAMPAIGN_COST_CENTS := 10000
const GUARANTEED_PRIMITIVE_IDS = StudioSpecialties.COMMON_IDS
const EngineEntitlements := preload("res://scripts/engines/engine_entitlements.gd")
const EngineFeatures := preload("res://scripts/engines/engine_feature_state.gd")
const EngineFeatureActions := preload("res://scripts/engines/engine_feature_actions.gd")
const ProprietaryEngines := preload("res://scripts/engines/proprietary_engine_state.gd")

var _cash_cents := 0
var _cash_initialized := false
var _completed_run_cycles := 0
var _calendar: Dictionary = {} # Missing context is the verified historical2-cycle clock.
var _rival_founder_profile: StringName = &""
var _calendar_start_year := START_YEAR # Private projection test: player and prelude use distinct epochs.
var _closed_historical_ids: Dictionary = {} # Only populated by typed c72 admission in this candidate.
var _historical_close_cycle := -1
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
var _engine_entitlements: Dictionary = {}
var _engine_features: Dictionary = {} # Empty only for explicit lazy legacy migration.
var _release_engine_ids: Dictionary = {}
var _engine_royalty_receipts: Dictionary = {}
var _proprietary_engines: Dictionary = ProprietaryEngines.empty()

func get_engine_entitlements() -> Dictionary:
	return _engine_entitlements.duplicate(true) if not _engine_entitlements.is_empty() else EngineEntitlements.create(_bank_run_id)

func get_selected_engine_id() -> StringName:
	return StringName(get_engine_entitlements().get("selected_engine_id", EngineEntitlements.LEGACY_ID))

func get_engine_feature_state() -> Dictionary:
	if not _engine_features.is_empty():return _engine_features.duplicate(true)
	var entitlements:=get_engine_entitlements();var ids:=EngineEntitlements.accessible_ids(entitlements)
	if entitlements.is_empty():ids.assign([EngineEntitlements.LEGACY_ID]) # Unnamed primitive models, never a created Studio.
	var owned: Array[StringName]=[];owned.assign(_owned_features.keys())
	return EngineFeatures.create(owned,ids,_bank_run_id,_feature_offers)

func get_proprietary_engine_state() -> Dictionary:
	return _proprietary_engines.duplicate(true)

func get_proprietary_engine_row(engine: StringName) -> Dictionary:
	return _proprietary_engines.get("engines",{}).get(engine,{}).duplicate(true)

func get_engine_skill_quote(engine: StringName,branch: StringName) -> Dictionary:
	if not _first_studio_economy or not EngineFeatureActions.available(self) or not _proprietary_engines.engines.has(engine):return {}
	var row: Dictionary=_proprietary_engines.engines[engine]
	var next: Dictionary=ProprietaryEngines.node(branch,ProprietaryEngines.generation(row,branch)+1)
	if next.is_empty() or int(row.challenge_progress.get(branch,0))<int(next.threshold) or get_cash_cents()<int(next.cost_cents):return {}
	return {"engine_id":engine,"branch":branch,"node_id":next.id,"cost_cents":next.cost_cents,"cash_cents":_cash_cents,"cycle":_completed_run_cycles,"finance_revision":_studio_finance.actions.size()}

func purchase_engine_skill(quote: Dictionary) -> Dictionary:
	if quote.is_empty() or quote!=get_engine_skill_quote(StringName(quote.get("engine_id",&"")),StringName(quote.get("branch",&""))):return {"ok":false,"error":"Skill purchase is unavailable or unaffordable"}
	var state:=get_proprietary_engine_state()
	var features:=get_engine_feature_state()
	var row: Dictionary=state.engines[quote.engine_id]
	if not ProprietaryEngines.purchase(row,quote.branch):return {"ok":false,"error":"Challenge incomplete"}
	features.engines[quote.engine_id].capacity=ProprietaryEngines.CAPACITY+5*ProprietaryEngines.milestone(row)
	var receipt:=StringName("engine-skill:%s:%s"%[quote.engine_id,quote.node_id])
	var finance: Dictionary=StudioFinanceLedger.plan(_studio_finance,_completed_run_cycles,_cash_cents,-int(quote.cost_cents),&"other_expense",0,0,false,receipt)
	if finance.is_empty() or not ProprietaryEngines.valid(state,_bank_run_id,get_engine_entitlements(),features,finance.ledger,_completed_run_cycles):return {"ok":false,"error":"Skill purchase validation failed"}
	_proprietary_engines=state;_engine_features=features;_studio_finance=finance.ledger;_cash_cents=finance.cash_cents
	_feature_purchase_in_progress=true;cash_changed.emit();finance_changed.emit();engines_changed.emit();features_changed.emit();_feature_purchase_in_progress=false
	return {"ok":true,"node_id":quote.node_id,"capacity":features.engines[quote.engine_id].capacity}

func credit_engine_skill_feature(project: ProjectState,card: CardData) -> void:
	if project==null or card==null or card.card_type!=&"feature" or not _proprietary_engines.engines.has(project.get_engine_id()):return
	var row: Dictionary=_proprietary_engines.engines[project.get_engine_id()]
	ProprietaryEngines.credit(row,card.core_contributions())
	engines_changed.emit()

func _registered_engine_ids() -> Array[StringName]:
	var ids: Array[StringName]=[]
	for id: StringName in _engine_features.get("engines",{}):
		if id!=&"legacy_engine" and preload("res://scripts/engines/engine_marketplace.gd").find(id).is_empty():ids.append(id)
	return ids

## Code-owned foundation seam; creation economics/UI belong to Phase2.
func _register_proprietary_engine(id: StringName,label: String) -> bool:
	if not EngineFeatureActions.available(self) or id==&"legacy_engine" or not preload("res://scripts/engines/engine_marketplace.gd").find(id).is_empty():return false
	var state:=get_engine_feature_state()
	if state.engines.size()>=128 or not EngineFeatures.add_record(state,id,label,&"proprietary",20,[] as Array[StringName]):return false
	var entitlement:=get_engine_entitlements();entitlement.owned_ids.append(id)
	_engine_features=state;_engine_entitlements=entitlement
	_feature_purchase_in_progress=true;engines_changed.emit();features_changed.emit();_feature_purchase_in_progress=false;return true

func get_proprietary_engine_creation_quote(label: String) -> Dictionary:
	var clean:=label.strip_edges()
	if not _first_studio_economy or not EngineFeatureActions.available(self) or clean.is_empty() or clean.length()>80 or get_cash_cents()<ProprietaryEngines.COST_CENTS:return {}
	var state:=get_proprietary_engine_state()
	var features:=get_engine_feature_state()
	if not ProprietaryEngines.valid(state,_bank_run_id,get_engine_entitlements(),features,_studio_finance,_completed_run_cycles) or features.engines.size()>=128:return {}
	var id:=ProprietaryEngines.next_id(state,_bank_run_id)
	if features.engines.has(id) or not preload("res://scripts/engines/engine_marketplace.gd").find(id).is_empty():return {}
	return {"id":id,"name":clean,"cost_cents":ProprietaryEngines.COST_CENTS,"cycle":_completed_run_cycles,"cash_cents":_cash_cents,"finance_revision":_studio_finance.actions.size(),"next_serial":state.next_serial}

func create_proprietary_engine(quote: Dictionary) -> Dictionary:
	if quote.is_empty() or not quote.get("name") is String or quote!=get_proprietary_engine_creation_quote(quote.name):return {"ok":false,"error":"Engine creation is unavailable or unaffordable"}
	var state:=get_proprietary_engine_state()
	var features:=get_engine_feature_state()
	var access:=get_engine_entitlements()
	var id: StringName=quote.id
	var record: Dictionary=ProprietaryEngines.record(id,_bank_run_id,quote.name,_completed_run_cycles)
	var finance: Dictionary=StudioFinanceLedger.plan(_studio_finance,_completed_run_cycles,_cash_cents,-ProprietaryEngines.COST_CENTS,&"other_expense",0,0,false,record.receipt_id)
	if finance.is_empty() or not EngineFeatures.add_record(features,id,quote.name,&"proprietary",ProprietaryEngines.CAPACITY,[] as Array[StringName],ProprietaryEngines.ORIGIN):return {"ok":false,"error":"Engine creation could not be settled"}
	state.engines[id]=record
	state.next_serial+=1
	access.owned_ids.append(id)
	if not ProprietaryEngines.valid(state,_bank_run_id,access,features,finance.ledger,_completed_run_cycles):return {"ok":false,"error":"Engine creation validation failed"}
	_feature_purchase_in_progress=true
	_cash_cents=finance.cash_cents;_studio_finance=finance.ledger
	_engine_features=features;_engine_entitlements=access;_proprietary_engines=state
	cash_changed.emit();finance_changed.emit();engines_changed.emit();features_changed.emit()
	_feature_purchase_in_progress=false
	return {"ok":true,"engine_id":id,"cost_cents":ProprietaryEngines.COST_CENTS}

func stage_engine_features(ids: Array[StringName],engine: StringName=&"") -> bool:
	return false

func get_engine_configuration_quote(engine: StringName=&"",target: Variant=null) -> Dictionary:
	return {}

func commit_engine_configuration(quote: Dictionary,respec: bool=false) -> bool:
	return false

func get_selected_engine_capacity() -> int:
	return int(get_engine_feature_state().engines[get_selected_engine_id()].capacity)

func _sync_legacy_engine_grant(id: StringName) -> void:
	if _engine_features.is_empty() or not _engine_features.engines.has(&"legacy_engine"):return
	var record: Dictionary=_engine_features.engines[&"legacy_engine"]
	for field: String in ["initial","implemented"]:
		if id not in record[field]:record[field].append(id)
	var library: Array[StringName]=[];library.assign(record.initial)
	record.committed=FeatureStoreCatalog.future_supply(library,_feature_offers)

func valid_engine_state() -> bool:
	var entitlements := get_engine_entitlements()
	if not EngineEntitlements.valid(entitlements,_registered_engine_ids()) or entitlements.studio_id != _bank_run_id: return false
	if entitlements.version==2 and _engine_features.is_empty():return false
	if not _engine_features.is_empty() and not EngineFeatures.valid(_engine_features,_feature_definitions,_feature_offers,_studio_finance if _first_studio_economy else {},_completed_run_cycles,_bank_run_id):return false
	if not _engine_features.is_empty() and not EngineFeatures.bindings_valid(_engine_features,entitlements,_owned_features,_bank_run_id):return false
	if not ProprietaryEngines.valid(_proprietary_engines,_bank_run_id,entitlements,get_engine_feature_state(),_studio_finance,_completed_run_cycles):return false
	if entitlements.version==2:
		for id: StringName in _released_games:
			if not _release_engine_ids.has(id):return false
	for release_id: StringName in _release_engine_ids:
		var engine_id: StringName = _release_engine_ids[release_id]
		if not _released_games.has(release_id) or engine_id not in EngineEntitlements.accessible_ids(entitlements): return false
	return true

func select_engine(engine_id: StringName) -> bool:
	var current := get_engine_entitlements()
	if not EngineEntitlements.valid(current,_registered_engine_ids()) or engine_id not in EngineEntitlements.accessible_ids(current): return false
	if not EngineFeatureActions.available(self): return false
	current.selected_engine_id = engine_id
	_engine_entitlements = current
	_feature_purchase_in_progress=true
	engines_changed.emit()
	features_changed.emit()
	_feature_purchase_in_progress=false
	return true
## Private trial runtime provider. The shared world owns the committed month.
var _market_provider: Callable = Callable()
var _market_committed_candidate: Dictionary = {}
var _release_metadata: Dictionary = {}
var _store_era_receipts: Dictionary = {"version":1,"assignments":{}}
const StoreEra := preload("res://scripts/cards/store_era_eligibility.gd")
var _productive_cycle_in_progress := false
var _committing_cycle_cash := false
var _publishing_cycle := false
var _preparing_project := false
var _cycle_plan: Dictionary = {}
var _pending_relationship_plan: Dictionary = {}
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
var _founding_roster_version := 1 # Missing historical metadata means the original grant.
var _studio_traits: Dictionary = {}
var _lean_savings: Dictionary = {}
var _first_studio_economy := false
var _starter_selection_confirmed := false
var _first_tutorial_project_id: StringName
var _first_game_tutorial: FirstGameTutorial
var _studio_finance: Dictionary = {}
var _fanbase: Dictionary = StudioFanbase.create()

func get_fans() -> int: return int(_fanbase.fans)

func get_fanbase_history() -> Array: return _fanbase.months.duplicate(true)

func get_fanbase_snapshot() -> Dictionary: return _fanbase.duplicate(true)

var _bank_run_id: StringName = &""
var _employees: Dictionary = EmployeeRoster.create(&"")
var _contract_search: Dictionary = ContractSearch.create(&"")
var random_streams := RunRandom.new()
var next_project_serial := 1
var checkpoint_mutations_allowed := true
var studio_departure_guard: Callable
## Studio mutations can coalesce with an owned background save; departure still
## requires the latest durable checkpoint through studio_departure_guard.
var studio_action_guard: Callable
var checkpoint_before_mutation: Callable
var _publisher_offers: Dictionary = {}
var _promotion_awards: Dictionary = {}
var _promotion_consumed: Dictionary = {}
const RelationshipLedger := preload("res://scripts/contracts/publisher_relationships.gd")
const RelationshipRules := preload("res://scripts/contracts/publisher_relationship_rules.gd")
const Commission := preload("res://scripts/contracts/publisher_commission_trial.gd")
const Support := preload("res://scripts/contracts/publisher_support.gd")
var _support_deals: Dictionary = {}
var _support_rights: Dictionary = {}
var _support_assessments: Dictionary = {}
var _commission_deals: Dictionary = {}
var _sidestreet_briefs: Dictionary = {}
var _publisher_relationships: Dictionary = {}
var _relationship_commit_in_progress := false
signal publisher_relationships_changed

func get_publisher_relationships() -> Dictionary:
	var resolver := func(request: Dictionary) -> Dictionary: return RelationshipRules.resolve(self,request)
	return RelationshipLedger.reconstruct(_publisher_relationships,_bank_run_id,_completed_run_cycles,resolver)

## Internal producer seam; P1 has no enabled producer. No UI-provided amounts.
func commit_publisher_relationship_event(request: Dictionary) -> bool:
	if _relationship_commit_in_progress or _productive_cycle_in_progress or _publishing_cycle or _committing_cycle_cash or _feature_purchase_in_progress or get_active_contract() != null: return false
	_relationship_commit_in_progress = true
	if not can_mutate_checkpoint():
		_relationship_commit_in_progress = false
		return false
	var resolver := func(source: Dictionary) -> Dictionary: return RelationshipRules.resolve(self,source)
	var planned := RelationshipLedger.plan(_publisher_relationships,_bank_run_id,request,_completed_run_cycles,resolver)
	if planned.is_empty():
		_relationship_commit_in_progress = false
		return false
	if planned.changed:
		_publisher_relationships = planned.ledger
		publisher_relationships_changed.emit()
	_relationship_commit_in_progress = false
	return true


func can_mutate_checkpoint() -> bool:
	return not _preparing_project and checkpoint_mutations_allowed and (not checkpoint_before_mutation.is_valid() or checkpoint_before_mutation.call())


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
	var proposed_run_id := StringName(Crypto.new().generate_random_bytes(16).hex_encode())
	var starting_calendar:=Calendar.fresh()
	var finance := StudioFinanceLedger.create(FIRST_STUDIO_CASH_CENTS, StudioFinanceLedger.starting_rent_cents(StudioTraits.is_active(selection, &"expensive_lease")),starting_calendar)
	for trait_id: StringName in [&"college_dropout",&"graduate"]:
		if StudioTraits.is_active(selection,trait_id):
			var opened := StudioFinanceLedger.open_education(finance,proposed_run_id,trait_id)
			if opened.is_empty(): return false
			finance = opened.ledger
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
	var initial_fans := StudioFanbase.create(StudioTraits.starting_fans(selection),starting_calendar)
	_owned_features = guaranteed
	_cash_cents = FIRST_STUDIO_CASH_CENTS + point_cash + family_cash
	_studio_traits = selection.duplicate(true)
	_fanbase = initial_fans
	_first_studio_economy = true
	_studio_name = cleaned
	_studio_specialty = specialty
	_founding_roster_version = StudioSpecialties.ROSTER_VERSION
	_studio_finance = finance
	_calendar = starting_calendar
	_bank_run_id = proposed_run_id
	_engine_entitlements = EngineEntitlements.create_public(_bank_run_id)
	var engine_ids:=EngineEntitlements.accessible_ids(_engine_entitlements)
	_engine_features = EngineFeatures.create([] as Array[StringName],engine_ids,_bank_run_id,_feature_offers)
	_employees = EmployeeRoster.create(_bank_run_id)
	_contract_search = ContractSearch.create(_bank_run_id)
	_publisher_relationships = RelationshipLedger.create(_bank_run_id)
	fans_changed.emit()
	cash_changed.emit()
	features_changed.emit()
	finance_changed.emit()
	return true


## Historical expenses are available only for studios created with this ledger.
func get_studio_finance_report() -> Dictionary:
	return StudioFinanceLedger.report(_studio_finance, _completed_run_cycles, _cash_cents)


## Detached read bundle with the same gates as the individual public getters.
## Ledger validation is shared only within this synchronous observation.
func get_studio_action_finance_observation() -> Dictionary:
	var result:=StudioFinanceLedger.action_observation(_studio_finance,_completed_run_cycles,_cash_cents,_bank_run_id,false)
	result.hire_quote=get_production_hire_quote()
	return result


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

func get_education_payoff_quote() -> Dictionary:
	return StudioFinanceLedger.education_payoff_quote(_studio_finance)

func pay_off_education(quote: Dictionary) -> bool:
	if not can_mutate_checkpoint() or not _bank_action_available(): return false
	return _commit_bank_plan(StudioFinanceLedger.pay_off_education(_studio_finance,quote))


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
	ids=FeatureStoreCatalog.future_supply(ids,_feature_offers)
	var price: int = path.price_cents
	var purchase_cycles: int = path.cycles
	var cards: Array[CardData] = []
	var unpriced := 0
	for id: StringName in ids:
		if not _feature_definitions.has(id): return {"available": false}
		var entry: Dictionary = _feature_definitions[id]
		if _feature_offers.has(id):
			if not _feature_offers[id].has("play_cost_cents"): unpriced += 1
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
	var graph := FeatureStoreCatalog.graph(_feature_definitions, _feature_offers)
	if graph.has("error"): return {"available":false,"reason":graph.error}
	var needed_parents: Dictionary = graph.parents.duplicate(true)
	# A direct grant or legacy-owned child never incurs retroactive parent costs.
	for owned: StringName in get_owned_feature_ids(): needed_parents[owned] = []
	var traversal := FeatureStoreCatalog.ordered_ancestors([] if id.is_empty() else [id], needed_parents)
	if traversal.has("error"): return {"available":false,"reason":traversal.error}
	var pending: Array[StringName] = traversal.order
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
		if not owned:
			if not primitive and needs_starter_selection() and not path.requirements.has("Later Features require the first game's completion."): path.requirements.append("Later Features require the first game's completion.")
			if not offer.unlocked and not path.requirements.has(offer.prerequisite): path.requirements.append(offer.prerequisite)
	return path


func get_financial_block_reason() -> String:
	if not _first_studio_economy: return ""
	if _studio_finance.get("cash_cents", -1) != _cash_cents or _studio_finance.get("last_cycle", -1) != _completed_run_cycles:
		return "Financial history is unavailable; production cannot be committed safely."
	var unpaid := StudioFinanceLedger.get_blocking_unpaid(_studio_finance)
	if unpaid < 0: return "Financial history is unavailable; production cannot be committed safely."
	if unpaid == 0: return ""
	return "Unpaid bills: %s. Further production must clear all overdue bills. You can still launch, browse Finances, or use an available income action that clears the balance." % CashFormatter.format_exact_cents(unpaid)

func get_studio_name() -> String:
	return _studio_name

func get_studio_specialty() -> StringName:
	return _studio_specialty

func get_founding_roster_version() -> int:
	return _founding_roster_version


func uses_first_studio_economy() -> bool:
	return _first_studio_economy


func needs_starter_selection() -> bool:
	return _first_studio_economy and not _starter_selection_confirmed


func get_starter_pool_summary() -> Dictionary:
	if not _first_studio_economy:
		return {}
	if get_selected_engine_id()==preload("res://scripts/engines/public_action_engine.gd").ID:
		return {"scope":27,"count":preload("res://scripts/engines/public_action_engine.gd").LIBRARY.size()}
	var scope := 0
	var count := 0
	for id: StringName in _owned_features:
		if _feature_offers.has(id):
			continue
		scope += int(_feature_definitions[id].scope)
		count += 1
	return {"scope": scope, "count": count}


func get_primitive_reserve_offer(id: StringName,engine: StringName=&"") -> Dictionary:
	if not _first_studio_economy or not _feature_definitions.has(id) or _feature_offers.has(id) or not FeatureStoreCatalog.is_active(id):
		return {}
	var graph := FeatureStoreCatalog.graph(_feature_definitions, _feature_offers)
	if graph.has("error"): return {}
	return _primitive_reserve_offer(id,graph,engine)


func _primitive_reserve_offer(id: StringName, graph: Dictionary,engine: StringName=&"") -> Dictionary:
	if not _first_studio_economy or not _feature_definitions.has(id) or _feature_offers.has(id) or not FeatureStoreCatalog.is_active(id): return {}
	var parents: Array = graph.parents[id]
	var missing: Array[StringName] = []
	var names: Array[String] = []
	for parent: StringName in parents:
		names.append(str(_feature_definitions[parent].name))
		if not owns_feature(parent,engine): missing.append(parent)
	var entry: Dictionary = _feature_definitions[id]
	var scope := int(entry.scope)
	if scope < 1 or scope > 3:
		return {}
	var price := (scope + 1) * 15000
	var starter_engine:=engine.is_empty() or (engine==&"legacy_engine" and get_selected_engine_id()==&"legacy_engine")
	var initial := needs_starter_selection() and starter_engine
	var base_price := price
	if initial: price -= resourceful_saving(price)
	return {"id": id, "name": entry.name, "phase": entry.phase, "scope": scope,
		"base_price_cents":base_price,"price_cents": price, "owned": owns_feature(id,engine), "affordable": _cash_initialized and _cash_cents >= price,
		"parents": parents, "missing_parents": missing, "unlocked": missing.is_empty(),
		"prerequisite": "Own " + " AND ".join(names) if not names.is_empty() else "Primitive reserve",
		"grant_exception": owns_feature(id,engine) and not missing.is_empty(),
		"initial": initial, "can_purchase": starter_engine and FeatureStoreCatalog.is_active(id) and not owns_feature(id,engine) and missing.is_empty() and _cash_initialized and _cash_cents >= price}


func purchase_starter_feature(id: StringName) -> bool:
	if get_selected_engine_id()!=&"legacy_engine":return false
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
	_sync_legacy_engine_grant(id)
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


func _debug_feature_ids(engine: StringName) -> Array[StringName]:
	var result: Array[StringName]=[]
	# Metadata capability is absent from ordinary Script-variable snapshots/DTOs.
	var grants: Dictionary=get_meta(&"debug_feature_grants",{})
	if not grants.has(engine):return result
	var state: Dictionary=_engine_features if not _engine_features.is_empty() else get_engine_feature_state()
	if state.engines.get(engine,{}).get("kind")!=&"proprietary":return result
	result.assign(grants[engine])
	return result

func owns_feature(id: StringName,engine: StringName=&"") -> bool:
	var selected:=get_selected_engine_id() if engine.is_empty() else engine
	var implemented: bool=_owned_features.has(id) if _engine_features.is_empty() else EngineFeatures.has_feature(_engine_features,selected,id)
	return implemented or id in _debug_feature_ids(selected)

func get_owned_feature_ids(engine: StringName=&"") -> Array[StringName]:
	var selected:=get_selected_engine_id() if engine.is_empty() else engine
	var result: Array[StringName] = []
	result.assign(_owned_features.keys() if _engine_features.is_empty() else _engine_features.engines[selected].implemented)
	for id: StringName in _debug_feature_ids(selected):
		if id not in result:result.append(id)
	return result

func get_future_project_feature_ids(engine: StringName=&"") -> Array[StringName]:
	var selected:=get_selected_engine_id() if engine.is_empty() else engine
	if _engine_features.is_empty() or not _debug_feature_ids(selected).is_empty():
		return FeatureStoreCatalog.future_supply(get_owned_feature_ids(selected),_feature_offers)
	return EngineFeatures.supply(_engine_features,selected,_feature_offers)


func get_feature_familiarity(id: StringName) -> int:
	return _familiarity.get(id, 0)


## Called only after committed Design/Alpha production, never draw/selection.
## Contract familiarity is an open design decision, not a permanent exclusion.
func record_resolved_feature(project: ProjectState, id: StringName, phase: StringName) -> bool:
	if _publishing_cycle:
		return false
	if project == null or phase not in [CardData.PHASE_DESIGN, CardData.PHASE_ALPHA] or (id not in project.get_feature_supply_ids() if project.has_predevelopment_identity() else not owns_feature(id)):
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


func get_store_era_status(era_year: int) -> Dictionary:
	var receipt: StringName = _store_era_receipts.assignments.get(era_year,&"")
	var reached := era_year in StoreEra.ERAS and get_current_year() >= era_year
	return {"year_reached":reached,"receipt_id":receipt,"eligible":reached and not receipt.is_empty()}


func get_feature_store_offer(id: StringName,engine: StringName=&"") -> Dictionary:
	if not _feature_offers.has(id): return {}
	var graph := FeatureStoreCatalog.graph(_feature_definitions, _feature_offers)
	if graph.has("error"): return {}
	return _feature_store_offer(id,graph,engine)


func _feature_store_offer(id: StringName, graph: Dictionary,engine: StringName=&"") -> Dictionary:
	if not _feature_offers.has(id): return {}
	var entry: Dictionary = _feature_offers[id]
	var parents: Array = graph.parents[id]
	var parent: StringName = parents[0] if not parents.is_empty() else &""
	var missing: Array[StringName] = []
	var contributions: Array = []
	var names: Array[String] = []
	var credits := 0
	for required_parent: StringName in parents:
		var count := get_feature_familiarity(required_parent)
		var parent_name := str(_feature_definitions[required_parent].name)
		credits += count
		names.append(parent_name)
		if not owns_feature(required_parent,engine): missing.append(required_parent)
		contributions.append({"id":required_parent,"name":parent_name,"owned":owns_feature(required_parent,engine),"credits":count})
	var required := int(entry.get("gameplay_features_required", 0))
	var gameplay_owned := 0
	for owned_id: StringName in get_owned_feature_ids(engine):
		if _feature_definitions[owned_id].get("department", "") == "gameplay": gameplay_owned += 1
	var year_reached := get_current_year() >= int(entry.get("min_year",_calendar_start_year))
	var era_qualified: bool = not entry.has("era_year") or not get_store_era_status(int(entry.era_year)).receipt_id.is_empty()
	var unlocked: bool = missing.is_empty() and gameplay_owned >= required and year_reached and era_qualified
	var discount := mini(credits, 8) * 10
	var base_price := int(entry.base_price_cents)
	# Exact integer cents, without multiplying a potentially large base first.
	var price: int = (base_price / 100) * (100 - discount) + ((base_price % 100) * (100 - discount)) / 100
	var prerequisite := "New root"
	if not parents.is_empty(): prerequisite = "Own " + " AND ".join(names)
	elif required > 0: prerequisite = "Own %d distinct Gameplay Features (%d owned)" % [required, gameplay_owned]
	var offer := {"id":id,"name":entry.name,"parent":parent,"parents":parents.duplicate(),"missing_parents":missing,
		"parent_contributions":contributions,"parent_credits":credits,"prerequisite":prerequisite,
		"owned":owns_feature(id,engine),"unlocked":unlocked,"base_price_cents":base_price,
		"discount_percent":discount,"price_cents":price,"affordable":_cash_initialized and _cash_cents >= price}
	if entry.has("min_year") or entry.has("era_year"):
		offer.merge({"min_year":int(entry.get("min_year",START_YEAR)),"era_year":int(entry.get("era_year",0)),"year_reached":year_reached,"era_qualified":era_qualified})
	return offer


func purchase_feature(id: StringName) -> bool:
	return admit_feature_research(get_feature_research_quote(id))


func resourceful_saving(price: int) -> int:
	return mini(10000,price) if price > 0 and StudioTraits.is_active(_studio_traits,&"resourceful") and not _resourceful_claims.has(_released_games.size()) else 0


func get_feature_research_queue() -> Array:
	return EngineFeatureActions.pending(self)

func get_feature_research_quote(id: StringName,engine: StringName=&"") -> Dictionary:
	return EngineFeatureActions.quote(self,id,get_selected_engine_id() if engine.is_empty() else engine)


func _get_feature_research_quote(id: StringName, check_action: bool) -> Dictionary:
	return EngineFeatureActions.quote(self,id,get_selected_engine_id(),check_action)

func _get_legacy_feature_research_quote(id: StringName, check_action: bool) -> Dictionary:
	if FeatureStoreCatalog.graph(_feature_definitions, _feature_offers).has("error"): return {}
	var offer := get_feature_store_offer(id)
	var primitive := offer.is_empty()
	if primitive: offer = get_primitive_reserve_offer(id)
	if offer.is_empty(): return {}
	offer=offer.duplicate(true);offer.discount_percent=mini(int(offer.get("discount_percent",0)),50)
	return _feature_research_quote(id,offer,get_feature_research_queue(),null,check_action)


## One synchronous UI read; no snapshot survives a command or bypasses its
## ordinary quote/finance validation. Graph and bill status are shared only
## within this call, instead of rebuilding them separately for every map node.
func get_feature_store_view(engine: StringName=&"") -> Dictionary:
	var engine_state:=get_engine_feature_state()
	if engine.is_empty():engine=get_selected_engine_id()
	if not engine_state.engines.has(engine):return {"error":"Engine unavailable"}
	var graph := FeatureStoreCatalog.graph(_feature_definitions,_feature_offers)
	if graph.has("error"): return graph
	var pending := get_feature_research_queue()
	var blocked := get_financial_block_reason()
	var result := {"offers":{},"reserves":{},"quotes":{},"financial_block_reason":blocked}
	for id: StringName in _feature_definitions:
		var offer := _feature_store_offer(id,graph,engine)
		var reserve := _primitive_reserve_offer(id,graph,engine) if offer.is_empty() else {}
		result.offers[id]=offer
		result.reserves[id]=reserve
		var available: Dictionary=reserve if offer.is_empty() else offer
		result.quotes[id]={} if available.is_empty() else EngineFeatureActions.quote(self,id,engine,true,available,pending,blocked,engine_state,graph)
	return result


func _feature_research_quote(id: StringName, offer: Dictionary, pending: Array, blocked: Variant, check_action: bool = true) -> Dictionary:
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
	var head: bool = queued and not pending.is_empty() and pending[0].feature_id == id
	var unlocked: bool = offer.get("unlocked",false)
	return {"feature_id":id,"entry_id":StringName("%s:research:%s" % [_bank_run_id,id]),
		"base_cents":base,"down_cents":arithmetic.down_cents,"due_cents":arithmetic.due_cents-saving,"saving_cents":saving,
		"nominal_cents":arithmetic.nominal_cents,"discount_percent":discount,"actions":actions,"completed":done,
		"paid_cents":paid,"remaining_actions":actions-done,"remaining_cents":remaining,"queued":queued,"head":head,"unlocked":unlocked,
		"can_admit":FeatureStoreCatalog.is_active(id) and not needs_starter_selection() and not offer.owned and unlocked and not queued and _cash_initialized and _cash_cents>=arithmetic.down_cents and (get_financial_block_reason().is_empty() if blocked==null else blocked.is_empty()),
		"can_research":head and check_action and can_complete_productive_cycle(-int(arithmetic.due_cents-saving)),
		"cycle":_completed_run_cycles,"cash_cents":_cash_cents,"revision":_studio_finance.get("actions",[]).size(),"queue_size":_feature_research.size(),"resourceful_window":_released_games.size()}


func admit_feature_research(quote: Dictionary) -> bool:
	return EngineFeatureActions.admit(self,quote)

func research_feature(quote: Dictionary) -> bool:
	return EngineFeatureActions.complete(self,quote)

func _research_legacy_feature(quote: Dictionary) -> bool:
	if not can_mutate_checkpoint() or _feature_purchase_in_progress or _productive_cycle_in_progress or _publishing_cycle: return false
	if quote.is_empty() or typeof(quote.get("feature_id")) != TYPE_STRING_NAME: return false
	if typeof(quote.get("can_research")) != TYPE_BOOL or not quote.can_research: return false
	# Compare every fresh quote fact and require the actual FIFO head. The full
	# money/sales/bill preflight runs once inside complete_productive_action,
	# before its direct-effects callback. Do not compute that same plan here
	# merely to discard it as a Boolean. Forged permission still cannot spend.
	var current: Dictionary = EngineFeatureActions.quote(self,quote.feature_id,&"legacy_engine",false)
	var supplied := quote.duplicate(true)
	supplied.can_research=false
	if current.is_empty() or not current.head or supplied != current: return false
	var commit := func() -> bool:
		for entry: Dictionary in _feature_research:
			if entry.id != quote.entry_id: continue
			entry.payments.append({"cycle":_completed_run_cycles+1,"nominal_cents":quote.nominal_cents,"discount_percent":quote.discount_percent,"paid_cents":quote.due_cents,"saving_cents":quote.saving_cents,"window":quote.resourceful_window})
			if quote.saving_cents > 0: _resourceful_claims[_released_games.size()] = quote.entry_id
			if entry.payments.size() == entry.actions:
				_owned_features[entry.feature_id] = true
				_sync_legacy_engine_grant(entry.feature_id)
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


func consume_redraw(count: int = 1, publish: Callable = Callable()) -> bool:
	if not can_mutate_checkpoint(): return false
	if _publishing_cycle:
		return false
	if not can_consume_redraw(count):
		return false
	_available_redraws -= count
	# Contract prepares replacements first, then publishes only after the debit
	# succeeds. Observers still see the new pool at redraws_changed.
	if publish.is_valid():
		_publishing_cycle = true
		publish.call()
		redraws_changed.emit()
		_publishing_cycle = false
		return true
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
	return Calendar.month(_completed_run_cycles,_calendar)

func get_calendar_profile() -> Dictionary:
	return _calendar.duplicate(true)

## After trusted legacy hydration only. Add timing context without replaying
## an action or changing a balance, historical stamp, project cycle or RNG.
func adopt_calendar() -> bool:
	if not _calendar.is_empty():return true
	var target:=Calendar.upgrade({},_completed_run_cycles)
	var finance:=StudioFinanceLedger.adopt_calendar(_studio_finance,target)
	if finance.is_empty():return false
	var records:=_released_games.duplicate(true)
	var fans:=_fanbase.duplicate(true)
	fans.calendar=target.duplicate(true)
	for id: StringName in records:
		if _closed_historical_ids.has(id):continue
		records[id]=ReleasedGameSales.adopt_calendar(records[id],target)
		if records[id].is_empty() or not fans.releases.has(id):return false
		fans.releases[id].neutral=ReleasedGameSales.adopt_calendar(fans.releases[id].neutral,target)
		if fans.releases[id].neutral.is_empty():return false
	_calendar=target;_studio_finance=finance;_released_games=records;_fanbase=fans
	return true


func get_current_year() -> int:
	return Calendar.year(_completed_run_cycles,_calendar_start_year,_calendar)


func get_current_half() -> int:
	# Retain the old public half-month query; Week1-4 presentation uses Clock.
	return int(Calendar.position(_completed_run_cycles,_calendar).quarter)/2+1


func get_calendar_label() -> String:
	return Calendar.label(_completed_run_cycles,_calendar_start_year,_calendar)


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
	return _completed_run_cycles < MAX_SIGNED_INT and Calendar.is_boundary(_completed_run_cycles+1,_calendar)


## Compatibility entry point. All consequences use the same transaction below.
func advance_calendar_cycle() -> bool:
	return complete_productive_action()


func has_pending_commission() -> bool:
	for deal: Dictionary in _commission_deals.values():
		if deal.result == null: return true
	return false

func has_unlaunched_support() -> bool:
	for id: StringName in _support_deals:
		if not _released_games.has(id): return true
	return false

func get_support_quote(base_name: String = "", genre: StringName = &"", theme: StringName = &"") -> Dictionary:
	if _preparing_project or not checkpoint_mutations_allowed or not _first_studio_economy or not _unlocked_publishers.has(&"sidestreet") or _released_games.is_empty() or _bank_run_id.is_empty() or next_project_serial == MAX_SIGNED_INT or get_active_contract() != null or has_pending_commission() or has_unlaunched_support() or _productive_cycle_in_progress or _publishing_cycle or _feature_purchase_in_progress or _relationship_commit_in_progress: return {}
	if not PrimitivePredevelopment.validation_error(base_name,genre,theme).is_empty() or get_publisher_relationships().is_empty(): return {}
	var source: StringName = get_released_game_ids()[-1]
	var eligible := Support.eligibility(Support.data(self),_support_deals,_publisher_relationships.events.size(),_completed_run_cycles,source)
	if eligible.is_empty(): return {}
	var amounts := Support.amounts(eligible.acceptance_investment_bp)
	if amounts.is_empty() or not can_complete_productive_cycle(amounts.funding_cents): return {}
	var prepared := PrimitivePredevelopment.prepare_project(base_name,genre,theme,self)
	if prepared == null: return {}
	var id := StringName("%s:project:%d" % [_bank_run_id,next_project_serial])
	var quote := {"version":1,"studio_id":_bank_run_id,"publisher_id":&"sidestreet","quote_id":StringName(str(id)+":support"),"project_id":id,"source_release_id":source,"accept_cycle":_completed_run_cycles,"relationship_boundary":_publisher_relationships.events.size(),"finance_revision":_studio_finance.actions.size(),"base_name":base_name.strip_edges(),"genre":genre,"theme":theme}
	quote.merge(eligible)
	quote.required_scope = prepared.get_required_scope()
	quote.merge(amounts)
	return quote

func can_bind_support_quote(quote: Dictionary, project: ProjectState) -> bool:
	return project != null and Support.valid_terms(quote,_bank_run_id) and project.get_release_id() == quote.project_id and project.get_required_scope() == quote.required_scope and quote == get_support_quote(project.get_base_name(),project.get_genre_id(),project.get_theme_id())

func _bind_support(quote: Dictionary) -> bool:
	if not _productive_cycle_in_progress or _publishing_cycle or has_unlaunched_support() or has_pending_commission() or _support_deals.has(quote.project_id) or _commission_deals.has(quote.project_id): return false
	_support_deals[quote.project_id] = quote.duplicate(true)
	return true

func get_support_marketing(project: ProjectState) -> int:
	return int(_support_deals[project.get_release_id()].marketing_points) if project != null and _support_deals.has(project.get_release_id()) else 0

func get_support_history() -> Dictionary:
	return {"deals":_support_deals.duplicate(true),"rights":_support_rights.duplicate(true),"assessments":_support_assessments.duplicate(true)}

func get_commission_quote(base_name: String = "", genre: StringName = &"", theme: StringName = &"") -> Dictionary:
	if has_unlaunched_support(): return {}
	if base_name.is_empty() or _bank_run_id.is_empty() or not _first_studio_economy or _released_games.is_empty() or has_pending_commission() or get_active_contract() != null or _productive_cycle_in_progress or _publishing_cycle or _feature_purchase_in_progress or _relationship_commit_in_progress or next_project_serial == MAX_SIGNED_INT: return {}
	if not PrimitivePredevelopment.validation_error(base_name,genre,theme).is_empty(): return {}
	var standing := get_publisher_relationships()
	if standing.is_empty() or standing[&"sidestreet"].reputation_bp < 2000: return {}
	var invitation:=ContractSearch.invitation(self)
	if invitation.is_empty():return {}
	var project := PrimitivePredevelopment.prepare_project(base_name,genre,theme,self)
	if project == null or project.get_required_scope() <= 0: return {}
	var id := StringName("%s:project:%d" % [_bank_run_id,next_project_serial])
	return {"version":2,"search_offer_id":invitation.offer_id,"studio_id":_bank_run_id,"publisher_id":&"sidestreet","quote_id":StringName(str(id)+":commission"),"project_id":id,"source_release_id":get_released_game_ids()[-1],"accept_cycle":_completed_run_cycles,"base_name":project.get_base_name(),"genre":genre,"theme":theme,"required_scope":project.get_required_scope(),"fee_cents":Commission.FEE,"review_target_tenths":60,"owner":&"publisher"}

func can_bind_commission_quote(quote: Dictionary, project: ProjectState) -> bool:
	if project == null or not Commission.valid_terms(quote,_bank_run_id): return false
	return quote == get_commission_quote(project.get_base_name(),project.get_genre_id(),project.get_theme_id()) and project.get_release_id() == quote.project_id and project.get_required_scope() == quote.required_scope

func _bind_commission(quote: Dictionary) -> bool:
	if not _productive_cycle_in_progress or _publishing_cycle or has_pending_commission() or _commission_deals.has(quote.project_id): return false
	if quote.get("version")==2:
		var invitation:=ContractSearch.invitation(self)
		if invitation.is_empty() or invitation.offer_id!=quote.search_offer_id:return false
		_contract_search.offers[quote.search_offer_id].project_id=quote.project_id
	_commission_deals[quote.project_id] = {"terms":quote.duplicate(true),"result":null}
	return true

func _plan_commission_release(project: ProjectState) -> Dictionary:
	var id := project.get_release_id()
	if not _commission_deals.has(id): return {"applicable":false}
	var deal: Dictionary = _commission_deals[id].duplicate(true)
	if deal.result != null: return {}
	var meta := {"base_name":project.get_base_name(),"genre":project.get_genre_id(),"theme":project.get_theme_id(),"release_cycle":_completed_run_cycles,"review":_capture_release_review(project),"owner":&"publisher","publisher_id":&"sidestreet","commission_quote_id":deal.terms.quote_id}
	deal.result = Commission.result(deal.terms,meta,id)
	if deal.result.is_empty(): return {}
	var finance := StudioFinanceLedger.plan(_studio_finance,_completed_run_cycles,_cash_cents,deal.result.fee_paid_cents,&"publisher_receipt",0,0,false,deal.terms.quote_id)
	if finance.is_empty(): return {}
	var staged := Commission.data(self).duplicate(true)
	staged.commission_deals[id] = deal
	staged.release_metadata[id] = meta
	staged.released_games[id] = _create_release_sales_record(project)
	staged.studio_finance = finance.ledger
	var request := Commission.request_for(staged,id)
	if request.is_empty(): return {}
	var resolver := func(source: Dictionary) -> Dictionary:
		return Commission.resolve(staged,source) if source.get("kind") == Commission.KIND else RelationshipRules.resolve(self,source)
	var relationship := RelationshipLedger.plan(_publisher_relationships,_bank_run_id,request,_completed_run_cycles,resolver)
	if relationship.is_empty(): return {}
	return {"applicable":true,"deal":deal,"finance":finance.ledger,"relationships":relationship.ledger}

func get_commission_deals() -> Dictionary:
	return _commission_deals.duplicate(true)


func can_register_release(project: ProjectState) -> bool:
	if _productive_cycle_in_progress or project == null or not _cash_initialized or not project.is_launch_ready() or not project.has_month_one_sales_revenue_result():
		return false
	var id := project.get_release_id()
	if _support_deals.has(id):
		var terms: Dictionary = _support_deals[id]
		if not Support.valid_terms(terms,_bank_run_id) or _commission_deals.has(id) or project.get_required_scope() != terms.required_scope or project.get_base_name() != terms.base_name or project.get_genre_id() != terms.genre or project.get_theme_id() != terms.theme:
			return false
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
	if _plan_commission_release(project).is_empty(): return false
	return project.get_awareness_result().get_promotion_awards()==get_pending_promotion_awards() and project.get_awareness_result().get_existing_fans()==get_fans()


func _create_release_sales_record(project: ProjectState) -> Dictionary:
	if project == null or project.get_review_result() == null or project.get_awareness_result() == null or project.get_launch_market_context_result() == null:
		return {}
	return ReleasedGameSales.create(project.get_release_id(), project.get_month_one_sales_revenue_result().get_total_month_one_units(),
		roundi(project.get_review_result().get_final_review() * 10.0), project.get_awareness_result().get_total_awareness(),
		project.get_launch_market_context_result().get_forecast_multiplier_basis_points(),
		_historical_close_cycle if _historical_close_cycle>0 else 0,Calendar.fresh() if not _calendar.is_empty() else {},_calendar)


## Release planning reuses the arithmetic owner on detached containers. The
## resulting field set is committed before Project or Run observers can fire.
const RELEASE_FIELDS := ["_employees","_store_era_receipts","_released_games","_release_engine_ids","_fanbase","_release_metadata","_commission_deals","_support_rights","_studio_finance","_cash_cents","_publisher_relationships","_promotion_consumed","_sidestreet_entitlements","_unlocked_publishers","_pending_publisher_notifications","_publisher_offers","_sidestreet_briefs"]

func plan_release(project: ProjectState) -> Dictionary:
	if _publishing_cycle or _productive_cycle_in_progress or not can_register_release(project): return {}
	var fence := preload("res://scripts/simulation/transaction_projection.gd")
	var probe := RunState.new()
	fence.copy_fields(self,probe)
	probe.checkpoint_before_mutation = Callable()
	probe.studio_departure_guard = Callable()
	probe.studio_action_guard = Callable()
	probe.set_block_signals(true)
	if not probe._register_release_unpublished(project): return {}
	var fields := {}
	for field: String in RELEASE_FIELDS: fields[field] = probe.get(field)
	return {"before":fence.fingerprint(self),"project":fence.fingerprint(project),"fields":fields,"changed":not _released_games.has(project.get_release_id()),"cash_changed":probe._cash_cents != _cash_cents,"finance_changed":probe._studio_finance != _studio_finance,"standing_changed":probe._publisher_relationships != _publisher_relationships,"publishers_changed":probe._unlocked_publishers != _unlocked_publishers}

func can_commit_release_plan(project: ProjectState, plan: Dictionary) -> bool:
	var fence := preload("res://scripts/simulation/transaction_projection.gd")
	return not plan.is_empty() and not _publishing_cycle and not _productive_cycle_in_progress and plan.before == fence.fingerprint(self) and plan.project == fence.fingerprint(project)

## Internal infallible seam: caller validates the plan immediately beforehand.
func commit_release_fields(plan: Dictionary) -> void:
	_publishing_cycle = true
	for field: String in RELEASE_FIELDS: set(field,plan.fields[field])

func publish_release_plan(plan: Dictionary) -> void:
	if plan.changed:
		employees_changed.emit()
		if plan.cash_changed: cash_changed.emit()
		if plan.finance_changed: finance_changed.emit()
		if plan.standing_changed: publisher_relationships_changed.emit()
		if plan.publishers_changed: publishers_changed.emit()
		contracts_changed.emit()
		sales_changed.emit()
		fans_changed.emit()
	_publishing_cycle = false

func register_release(project: ProjectState) -> bool:
	if _publishing_cycle or _productive_cycle_in_progress: return false
	if not can_mutate_checkpoint(): return false
	var plan := plan_release(project)
	if not can_commit_release_plan(project,plan): return false
	commit_release_fields(plan)
	publish_release_plan(plan)
	return true

func _register_release_unpublished(project: ProjectState) -> bool:
	if not can_mutate_checkpoint(): return false
	if _publishing_cycle:
		return false
	if not can_register_release(project):
		return false
	var id := project.get_release_id()
	if _released_games.has(id):
		return true
	var commission := _plan_commission_release(project)
	if commission.is_empty(): return false
	var year := get_current_year()
	var title := _resolve_release_title(project.get_base_name(), year)
	var record := _create_release_sales_record(project)
	var next_fans := StudioFanbase.register_release(_fanbase, record, project.get_awareness_result().get_existing_fans())
	if next_fans.is_empty(): return false
	record.base_name = project.get_base_name()
	record.release_title = title
	record.release_year = year
	var cash_before := _cash_cents
	var publishers_before := _unlocked_publishers.duplicate()
	var was_blocked := is_blocking_signals()
	_publishing_cycle = true
	set_block_signals(true)
	_released_games[id] = record
	_release_engine_ids[id] = project.get_engine_id()
	if _support_deals.has(id): _support_rights[id] = Support.empty_rights()
	_fanbase = next_fans
	_release_metadata[id] = {"base_name": project.get_base_name(), "genre": project.get_genre_id(),
		"theme": project.get_theme_id(), "genre_ratios": project.get_genre_ratios(),
		"release_title": title, "release_year": year, "release_cycle": _completed_run_cycles,
		"review": _capture_release_review(project)}
	if commission.applicable:
		_commission_deals[id] = commission.deal
		_studio_finance = commission.finance
		_cash_cents = _studio_finance.cash_cents
		_publisher_relationships = commission.relationships
		_release_metadata[id].merge({"owner":&"publisher","publisher_id":&"sidestreet","commission_quote_id":commission.deal.terms.quote_id})
	_store_era_receipts = StoreEra.from_releases(_release_metadata)
	if uses_employee_courses() and _employees.employees.values().any(func(e):return e.has("career")):
		var career_release:=EmployeeRoster.Career.release(_employees,id,_completed_run_cycles)
		if career_release.is_empty():return false
		_employees=career_release
		_sync_employee_raises()
	for offer_id: StringName in project.get_awareness_result().get_promotion_awards():
		_promotion_consumed[offer_id] = id
	# Qualification is captured only on the first committed registration. Existing
	# entitlements (including legacy under-Scope offers) are never re-evaluated.
	_refresh_publisher_unlocks()
	set_block_signals(was_blocked)
	if _cash_cents != cash_before: cash_changed.emit()
	if commission.applicable:
		finance_changed.emit()
		publisher_relationships_changed.emit()
	if _unlocked_publishers != publishers_before: publishers_changed.emit()
	sales_changed.emit()
	fans_changed.emit()
	_publishing_cycle = false
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
	var frozen := {"final_review": review.get_final_review(), "production_rating": review.get_production_rating(),
		"scope_completion": review.get_scope_completion(), "scope": project.get_current_scope(),
		"required_scope": project.get_required_scope(), "development_cycles": project.get_current_cycle(),
		"cores": cores, "standards": standards, "remaining_bugs": project.get_remaining_bugs(),
		"awareness": awareness.get_total_awareness(), "launch_marketing": awareness.get_launch_marketing(),
		"launch_fans": awareness.get_existing_fans(), "fan_awareness": awareness.get_fan_awareness(),
		"projected_units": units.get_final_units_sold(), "projected_gross_cents": revenue.get_projected_month_one_gross_cents(),
		"projected_net_cents": revenue.get_projected_month_one_net_cents(),
		"forecast_id": context.get_forecast_id_for_authority() if context.was_forecast_revealed_at_launch() else &"",
		"forecast_multiplier": context.get_forecast_multiplier_text() if context.was_forecast_revealed_at_launch() else "",
		"competitor_id": context.get_competitor_id_for_authority() if context.was_competitor_revealed_at_launch() else &"",
		"competitor_target_cycle": context.get_competitor_target_cycle() if context.was_competitor_revealed_at_launch() else -1}
	if not project.get_market_details().is_empty(): frozen.market=project.get_market_details()
	return frozen


func get_released_game_sales(release_id: StringName) -> Dictionary:
	return _released_games.get(release_id, {}).duplicate(true)


func get_released_game_monthly_report(release_id: StringName) -> Dictionary:
	if not _release_metadata.has(release_id) or not _released_games.has(release_id): return {}
	var release_cycle: Variant = _release_metadata[release_id].get("release_cycle", null)
	if typeof(release_cycle) != TYPE_INT or release_cycle < 0: return {}
	var report := ReleasedGameMonthlyReport.build(_released_games[release_id], release_cycle)
	if report.is_empty(): return {}
	var publisher_owned := _commission_deals.has(release_id)
	report.owner = &"publisher" if publisher_owned else &"studio"
	report.studio_net_cents = 0 if publisher_owned else report.net_cents
	report.studio_settled_cents = 0 if publisher_owned else report.settled_cents
	if _support_deals.has(release_id):
		var rights: Dictionary = _support_rights[release_id]
		report.studio_net_cents = rights.studio_earned_cents
		report.studio_settled_cents = rights.studio_settled_cents
		report.support = {"terms":_support_deals[release_id].duplicate(true),"rights":rights.duplicate(true),"assessment":_support_assessments.get(release_id,{}).duplicate(true)}
	# The earning record remains post-platform. Report Studio proceeds after the
	# same cumulative engine royalty already used by the finance settlement.
	var engine_id: StringName=_release_engine_ids.get(release_id,&"legacy_engine")
	if engine_id in get_engine_entitlements().get("licensed_ids",[]) or engine_id==preload("res://scripts/engines/public_action_engine.gd").ID:
		var engine:=preload("res://scripts/engines/engine_marketplace.gd").terms_for_record(engine_id,_engine_features.get("engines",{}).get(engine_id,{}))
		if engine.is_empty():return {}
		var rate: int=engine.royalty_basis_points
		report.engine_royalty_basis_points=rate
		report.studio_net_cents-=preload("res://scripts/engines/engine_royalty.gd").cumulative(report.studio_net_cents,rate)
		report.studio_settled_cents-=preload("res://scripts/engines/engine_royalty.gd").cumulative(report.studio_settled_cents,rate)
	return report


## An offer is anchored to the current release-age cycle, not the calendar month.
func get_post_launch_campaign_offer(release_id: StringName) -> Dictionary:
	if _commission_deals.has(release_id): return {}
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
	if not accepted.freeze_challenge() or not accepted.commit_upfront():
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
	for offer: Dictionary in _sidestreet_briefs.values():
		var brief: ContractState = offer.state
		if brief != null and not brief.is_completed(): return brief
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
	for offer: Dictionary in _sidestreet_briefs.values():
		if offer.state == state and state != null: return true
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


func get_sidestreet_brief_offer() -> Dictionary:
	if not _unlocked_publishers.has(PublisherCatalog.SIDESTREET): return {}
	for offer: Dictionary in _sidestreet_briefs.values():
		if offer.state == null:
			return {"offer_id":offer.offer_id,"publisher_id":PublisherCatalog.SIDESTREET,
				"source_release_id":offer.source_release_id,"required_hands":2,
				"cash_cents":0,"advance_cents":0,"promotion":0}
	return {}


func accept_sidestreet_brief(offer_id: StringName) -> ContractState:
	if not can_mutate_checkpoint() or _publishing_cycle or _productive_cycle_in_progress: return null
	if studio_departure_guard.is_valid() and not studio_departure_guard.call(): return null
	var offered := get_sidestreet_brief_offer()
	if offered.is_empty() or offered.offer_id != offer_id or get_active_contract() != null: return null
	var accepted := ContractState.new(_primitive_contract_eligible_ids(),ContractDefinitions.SIDESTREET_BRIEF,offer_id,offered.source_release_id)
	if not accepted.freeze_challenge() or not accepted.commit_upfront(): return null
	_sidestreets_brief_set_state(offer_id,accepted)
	contracts_changed.emit()
	return accepted


func _sidestreets_brief_set_state(offer_id: StringName, state: ContractState) -> void:
	var offer: Dictionary = _sidestreet_briefs[offer_id]
	offer.state = state
	_sidestreet_briefs[offer_id] = offer


func _issue_sidestreet_brief(source_release_id: StringName) -> void:
	if not _contract_search.intro_offer_id.is_empty():return
	if source_release_id.is_empty() or not _released_games.has(source_release_id): return
	for offer: Dictionary in _sidestreet_briefs.values():
		if offer.state == null or not offer.state.is_completed() or offer.source_release_id == source_release_id: return
	var offer_id := StringName("%s:sidestreet-brief:%s" % [_bank_run_id,source_release_id])
	if _sidestreet_briefs.has(offer_id): return
	_sidestreet_briefs[offer_id] = {"offer_id":offer_id,"source_release_id":source_release_id,"state":null}
	_contract_search.intro_offer_id=offer_id
	contracts_changed.emit()


func get_next_sidestreet_offer() -> Dictionary:
	if not _unlocked_publishers.has(PublisherCatalog.SIDESTREET):
		return {}
	for release_id: StringName in _sidestreet_entitlements:
		var entitlement: Dictionary = _sidestreet_entitlements[release_id]
		if entitlement.state == null:
			return {"offer_id":entitlement.offer_id,"release_id":&"","entitlement_id":release_id} if not ContractSearch.source(self,entitlement.offer_id,&"cash").is_empty() else {"offer_id":entitlement.offer_id,"release_id":release_id}
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
	if not accepted.freeze_challenge() or not accepted.commit_upfront():
		return null
	var key: StringName=next.get("entitlement_id",release_id)
	var entitlement: Dictionary = _sidestreet_entitlements[key]
	entitlement.state = accepted
	_sidestreet_entitlements[key] = entitlement
	contracts_changed.emit()
	return accepted


func _primitive_contract_eligible_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for entry: Dictionary in FeatureStoreCatalog.starting_features():
		var id := StringName(entry.id)
		if id in get_future_project_feature_ids() and StringName(entry.phase) in [CardData.PHASE_DESIGN, CardData.PHASE_ALPHA]:
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
		if _sidestreet_results.has(state.get_offer_id()) or _cash_entitlement_key(state.get_offer_id()).is_empty():
			return false
		var entitlement: Dictionary = _sidestreet_entitlements[_cash_entitlement_key(state.get_offer_id())]
		if entitlement.offer_id != state.get_offer_id() or entitlement.state != state:
			return false
	var relationship := {"applicable":false}
	if plan.completing and state.get_contract_id() == ContractDefinitions.SIDESTREET_BRIEF:
		relationship = _plan_finishing_brief(state,cards,expected_payment_cents)
		if relationship.is_empty(): return false
	if not state.commit_hand(cards, expected_payment_cents):
		return false
	if relationship.applicable: _pending_relationship_plan = relationship.ledger
	if state.is_completed():
		_pending_contract_completion = state
	return true


func _record_paid_contract_completion() -> void:
	var state := _pending_contract_completion
	if state == null:
		return
	_pending_contract_completion = null
	if state.get_contract_id() == ContractDefinitions.SIDESTREET_BRIEF: return
	if _publisher_offers.has(state.get_offer_id()):
		if state.get_contract_id()!=PublisherTrialTerms.STARWAVE or state.get_result().get_promotion() > 0:
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
	var searched:=ContractSearch.source(self,state.get_offer_id(),&"cash")
	if not searched.is_empty():_sidestreet_results[state.get_offer_id()].search_receipt_id=searched.receipt_id
	if result.get_promotion() > 0: _promotion_awards[state.get_offer_id()] = result.get_promotion()


func get_completed_contract_count() -> int:
	var ironclad := 1 if _ironclad_completion_committed else 0
	var trials := 0
	for offer: Dictionary in _publisher_offers.values():
		var state: ContractState = offer.state
		if state!=null and state.is_completed() and state.is_payout_committed(): trials += 1
	return ironclad + _sidestreet_results.size() + trials


func get_released_game_engine_id(id: StringName) -> StringName:
	return _release_engine_ids.get(id,&"") if _released_games.has(id) else &""


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
		if id in [PublisherCatalog.CROWN_QUILL, PublisherCatalog.NEON_CIRCUIT, PublisherCatalog.STARWAVE]:
			for offer: Dictionary in _publisher_offers.values():
				if offer.publisher_id != id: continue
				var state: ContractState = offer.state
				if state == null:
					availability = "Contract available from Contracts. This one-time offer does not expire."
					if get_active_contract() != null:
						availability = "Contract pending. Finish the active Contract first; this offer does not expire."
				elif state.is_completed() and state.is_payout_committed():
					availability = "One-time Contract completed. Cash has been awarded; this offer grants no Promotion." if id==PublisherCatalog.STARWAVE else "One-time Contract completed. Cash and Promotion have been awarded."
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
		if id == PublisherCatalog.SIDESTREET and not _released_games.is_empty():
			_issue_sidestreet_brief(_released_games.keys()[-1])
		if id in [PublisherCatalog.CROWN_QUILL,PublisherCatalog.NEON_CIRCUIT,PublisherCatalog.STARWAVE]:
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


## Free contract work may continue in arrears; actual settlement still runs.
func can_complete_contract_hand(state: ContractState,plan: Dictionary) -> bool:
	if state==null or state!=get_active_contract() or state.is_completed() or plan.is_empty():return false
	return not _preflight_productive_cycle(int(plan.remainder_cents),&"",&"contract_receipt" if plan.remainder_cents>0 else &"contract_hand",state.get_offer_id()).is_empty()

func can_complete_productive_cycle(direct_cash_delta_cents: int = 0, campaign_release_id: StringName = &"") -> bool:
	return not _preflight_productive_cycle(direct_cash_delta_cents, campaign_release_id).is_empty()


func _preflight_productive_cycle(direct_cash_delta_cents: int, campaign_release_id: StringName = &"", finance_kind: StringName = &"", source_id: StringName = &"") -> Dictionary:
	# Preserve custom/historical overrides and their original signatures. Only
	# the exact ordinary Run can decline retention of a speculative result.
	if get_script()!=RunState:return _plan_productive_cycle(direct_cash_delta_cents,campaign_release_id,finance_kind,source_id)
	return _plan_productive_cycle_for_result_proof(direct_cash_delta_cents,campaign_release_id,finance_kind,source_id,false)


func _plan_productive_cycle(direct_cash_delta_cents: int, campaign_release_id: StringName = &"", finance_kind: StringName = &"", source_id: StringName = &"") -> Dictionary:
	return _plan_productive_cycle_for_result_proof(direct_cash_delta_cents,campaign_release_id,finance_kind,source_id)


func _plan_productive_cycle_for_result_proof(direct_cash_delta_cents: int, campaign_release_id: StringName = &"", finance_kind: StringName = &"", source_id: StringName = &"", remember_finance_result: bool = true) -> Dictionary:
	if finance_kind==&"rival_wait" and (_rival_founder_profile!=&"rival-founder-active-1977-v2" or source_id!=_bank_run_id or direct_cash_delta_cents!=0 or not campaign_release_id.is_empty()):return {}
	if finance_kind in [&"contract_hand",&"contract_receipt"]:
		var contract:=get_active_contract()
		if contract==null or contract.is_completed() or source_id!=contract.get_offer_id():return {}
	if _productive_cycle_in_progress or _feature_purchase_in_progress or _pending_contract_completion != null or _completed_run_cycles < 0 or _completed_run_cycles == MAX_SIGNED_INT or _available_redraws < 0 or _available_redraws > MAX_REDRAWS:
		return {}
	if not campaign_release_id.is_empty() and (direct_cash_delta_cents != -POST_LAUNCH_CAMPAIGN_COST_CENTS or not _released_games.has(campaign_release_id) or not ReleasedGameSales.can_campaign(_released_games[campaign_release_id]) or _commission_deals.has(campaign_release_id)):
		return {}
	if direct_cash_delta_cents != 0 and not _cash_initialized:
		return {}
	if direct_cash_delta_cents < -_cash_cents or direct_cash_delta_cents > MAX_SIGNED_INT - _cash_cents:
		return {}
	var cash_after_action := _cash_cents + direct_cash_delta_cents
	var market: Dictionary = preload("res://scripts/market/market_transaction_trial.gd").neutral()
	if _market_provider.is_valid():
		market = _market_provider.call(_bank_run_id,_completed_run_cycles+1)
		if not preload("res://scripts/market/market_transaction_trial.gd").valid(market): return {}
	if remember_finance_result:return _plan_cycle_records(direct_cash_delta_cents,campaign_release_id,finance_kind,source_id,market,cash_after_action)
	return _plan_cycle_records_for_result_proof(direct_cash_delta_cents,campaign_release_id,finance_kind,source_id,market,cash_after_action,false)


func _plan_cycle_records(direct_cash_delta_cents: int,campaign_release_id: StringName,finance_kind: StringName,source_id: StringName,market: Dictionary,cash_after_action: int) -> Dictionary:
	return _plan_cycle_records_for_result_proof(direct_cash_delta_cents,campaign_release_id,finance_kind,source_id,market,cash_after_action)


func _plan_cycle_records_for_result_proof(direct_cash_delta_cents: int,campaign_release_id: StringName,finance_kind: StringName,source_id: StringName,market: Dictionary,cash_after_action: int,remember_finance_result: bool=true) -> Dictionary:
	# Cache only sales/Fan calculations, not a financial decision. Every guard,
	# provider read, cash overflow check and full finance plan still runs. The
	# key contains all typed inputs read by _plan_sales_cycle. Support's wider
	# assessment path deliberately computes afresh.
	var cache := preload("res://scripts/simulation/productive_cycle_plan_cache.gd")
	var key:=PackedByteArray()
	var sales: Dictionary={}
	if _support_deals.is_empty():
		key=var_to_bytes([campaign_release_id,_completed_run_cycles,_cash_initialized,
			_market_provider.is_valid(),market,_bank_run_id,_released_games,_release_metadata,
			_commission_deals,_support_rights,_support_assessments,_fanbase,_closed_historical_ids,_release_engine_ids,_calendar])
		sales=cache.read(key)
	if sales.is_empty():
		sales=_plan_sales_cycle(campaign_release_id,market)
		if not key.is_empty():cache.remember(key,sales)
	if sales.is_empty():return {}
	var next_records: Dictionary=sales.records
	var payable: int=sales.payable
	var earned: int=sales.earned
	var fan_plan: Dictionary=sales.fans
	var support_rights: Dictionary=sales.support_rights
	var support_assessments: Dictionary=sales.support_assessments
	if payable > MAX_SIGNED_INT - cash_after_action:
		return {}
	var finance_plan: Dictionary = {}
	if _first_studio_economy:
		if finance_kind.is_empty():
			finance_kind = &"campaign" if not campaign_release_id.is_empty() else (&"other_expense" if direct_cash_delta_cents < 0 else (&"other_income" if direct_cash_delta_cents > 0 else &"calendar"))
		finance_plan = StudioFinanceLedger.plan(_studio_finance, _completed_run_cycles + 1, _cash_cents, direct_cash_delta_cents, finance_kind, earned, payable, true, source_id,remember_finance_result)
		if finance_plan.is_empty(): return {}
	var relationships := _publisher_relationships.duplicate(true)
	if support_assessments != _support_assessments:
		var prospective := RunState.new()
		preload("res://scripts/simulation/transaction_projection.gd").copy_fields(self,prospective)
		prospective._completed_run_cycles += 1
		prospective._released_games = next_records
		prospective._support_rights = support_rights
		prospective._support_assessments = support_assessments
		prospective._studio_finance = finance_plan.ledger
		for id: StringName in support_assessments:
			if _support_assessments.has(id): continue
			var request := Support.request_for(prospective,id)
			var resolver := func(source: Dictionary) -> Dictionary: return RelationshipRules.resolve(prospective,source)
			var award := RelationshipLedger.plan(relationships,_bank_run_id,request,prospective._completed_run_cycles,resolver)
			if award.is_empty(): return {}
			relationships = award.ledger
	return {"records":next_records,"payable":payable,"finance":finance_plan,"fans":fan_plan,"market":market,"support_rights":support_rights,"support_assessments":support_assessments,"relationships":relationships}


func _plan_sales_cycle(campaign_release_id: StringName,market: Dictionary) -> Dictionary:
	var next_records: Dictionary = {}
	var payable := 0
	var earned := 0
	var entitlements:=get_engine_entitlements()
	var licensed_engine_ids: Array = entitlements.get("licensed_ids",[])
	var support_rights := _support_rights.duplicate(true)
	var support_assessments := _support_assessments.duplicate(true)
	for id: StringName in _released_games:
		if entitlements.get("version",1)==2 and not _release_engine_ids.has(id):return {}
		if not _cash_initialized or not _released_games[id] is Dictionary or _released_games[id].get("release_id") != id:
			return {}
		if _closed_historical_ids.has(id):
			if id == campaign_release_id: return {}
			next_records[id] = _released_games[id].duplicate(true)
			continue
		var factor: Dictionary=preload("res://scripts/market/market_transaction_trial.gd").neutral_factor()
		if _market_provider.is_valid():
			if not _release_metadata.has(id): return {}
			var metadata: Dictionary=_release_metadata[id]
			factor=preload("res://scripts/market/market_transaction_trial.gd").sales_factor(market,str(_bank_run_id),str(id),str(metadata.genre),str(metadata.theme))
			if factor.is_empty(): return {}
		var next := ReleasedGameSales.next_cycle(_released_games[id], _completed_run_cycles + 1, will_next_cycle_cross_month_boundary(), id == campaign_release_id, int(factor.factor_bp), str(factor.snapshot_id),factor)
		if next.is_empty():
			return {}
		if _commission_deals.has(id):
			next_records[id] = next
			continue
		var release_payable: int = next.settled_cents - _released_games[id].settled_cents
		var release_earned: int = next.entitlement_cents - _released_games[id].entitlement_cents
		var studio_settled_before: int = _released_games[id].settled_cents
		var studio_settled_after: int = next.settled_cents
		var studio_earned_before: int = _released_games[id].entitlement_cents
		var studio_earned_after: int = next.entitlement_cents
		if _support_deals.has(id):
			if not support_rights.has(id): return {}
			var old: Dictionary = support_rights[id]
			var rights := Support.advance_rights(_support_deals[id].budget_cents,old,next.entitlement_cents,next.total_earned_cycles,will_next_cycle_cross_month_boundary())
			if rights.is_empty(): return {}
			release_payable = rights.studio_settled_cents-old.studio_settled_cents
			release_earned = rights.studio_earned_cents-old.studio_earned_cents
			studio_settled_before = old.studio_settled_cents
			studio_settled_after = rights.studio_settled_cents
			studio_earned_before = old.studio_earned_cents
			studio_earned_after = rights.studio_earned_cents
			support_rights[id] = rights
			if next.total_earned_cycles == 6:
				if support_assessments.has(id): return {}
				support_assessments[id] = Support.assessment(roundi(float(_release_metadata[id].review.final_review)*10.0),next.earned_units)
		var engine_id: StringName = _release_engine_ids.get(id,&"legacy_engine")
		if engine_id in licensed_engine_ids or engine_id==preload("res://scripts/engines/public_action_engine.gd").ID:
			var engine: Dictionary = preload("res://scripts/engines/engine_marketplace.gd").terms_for_record(engine_id,_engine_features.get("engines",{}).get(engine_id,{}))
			if engine.is_empty() or studio_settled_after < studio_settled_before or studio_earned_after < studio_earned_before: return {}
			var rate: int=engine.royalty_basis_points
			release_payable -= preload("res://scripts/engines/engine_royalty.gd").increment(studio_settled_before,studio_settled_after,rate)
			release_earned -= preload("res://scripts/engines/engine_royalty.gd").increment(studio_earned_before,studio_earned_after,rate)
		if release_payable > MAX_SIGNED_INT - payable:
			return {}
		payable += release_payable
		if release_earned < 0 or release_earned > MAX_SIGNED_INT - earned: return {}
		earned += release_earned
		next_records[id] = next
	var fan_plan := StudioFanbase.plan(_fanbase, _released_games, next_records, _completed_run_cycles + 1, _closed_historical_ids)
	if fan_plan.is_empty(): return {}
	return {"records":next_records,"payable":payable,"earned":earned,"fans":fan_plan,"support_rights":support_rights,"support_assessments":support_assessments}


## Auditable external payments, reconstructed from persisted settlement counters
## and release engine identity. These are cumulative receipts, not another cash
## mutation path; observing or restoring them cannot charge a second royalty.
func get_engine_royalty_payments() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	var public_engine:=preload("res://scripts/engines/public_action_engine.gd").definition()
	for id: StringName in _release_engine_ids:
		if _release_engine_ids[id]!=public_engine.id or not _released_games.has(id) or _commission_deals.has(id):continue
		var sales: Dictionary=_released_games[id]
		var basis: int=_support_rights[id].studio_settled_cents if _support_rights.has(id) else sales.settled_cents
		var paid:=preload("res://scripts/engines/engine_royalty.gd").cumulative(basis,int(public_engine.royalty_basis_points))
		if paid<=0:continue
		result.append({"receipt_id":StringName("public-engine:%s:%s"%[_bank_run_id,id]),"release_id":id,
			"engine_id":public_engine.id,"provider_id":public_engine.creator_id,"provider_kind":&"external_public_engine",
			"post_platform_cents":basis,"basis_points":public_engine.royalty_basis_points,"paid_cents":paid,
			"last_settlement_cycle":sales.last_settlement_run_cycle})
	return result


## The direct-effects callback must be synchronous and atomic on false, using
## its phase's validated transaction. Direct cash delta is applied HERE, not
## inside the callback. All fallible run consequences preflight
## BEFORE that callback. expected_cycle lets delayed callers reject replays.
## All release records preflight together; settlement sums checked integer cents.
## Direct effects -> income/spend -> calendar/sales settlement -> due rent and
## oldest arrears -> report -> notifications. No await can split this boundary.
func complete_productive_action(direct_effects: Callable = Callable(), direct_cash_delta_cents: int = 0, expected_cycle: int = -1, campaign_release_id: StringName = &"", finance_kind: StringName = &"", source_id: StringName = &"") -> bool:
	if finance_kind==&"rival_wait" and direct_effects.is_valid():return false
	if _publishing_cycle or _productive_cycle_in_progress: return false
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
	var engine_features_before:=_engine_features.duplicate(true)
	var publishers_before := _unlocked_publishers.duplicate()
	var relationships_before := _publisher_relationships.duplicate(true)
	var completed_contracts_before := get_completed_contract_count()
	var employees_before := _employees.duplicate(true)
	var briefs_before := _sidestreet_briefs.duplicate(true)
	_cycle_plan = plan
	_pending_relationship_plan = {}
	_productive_cycle_in_progress = true
	# Publish run notifications only after cash and sales have committed together.
	var was_blocked := is_blocking_signals()
	set_block_signals(true)
	if direct_effects.is_valid() and not direct_effects.call():
		_pending_contract_completion = null
		_cycle_plan = {}
		_pending_relationship_plan = {}
		set_block_signals(was_blocked)
		_productive_cycle_in_progress = false
		return false
	_committing_cycle_cash = true
	# The outer guard and finance plan already validated every cent. Public cash
	# methods would re-enter a fallible save guard after direct effects committed.
	_cash_cents = plan.finance.cash_cents if not plan.finance.is_empty() else cash_before + direct_cash_delta_cents + int(plan.payable)
	_record_paid_contract_completion()
	_completed_run_cycles += 1
	_available_redraws = mini(MAX_REDRAWS, _available_redraws + 1)
	_released_games = plan.records
	_support_rights = plan.support_rights
	_support_assessments = plan.support_assessments
	_publisher_relationships = plan.relationships
	_market_committed_candidate = plan.market.duplicate(true)
	var previous_fans := get_fans()
	_fanbase = plan.fans
	if not plan.finance.is_empty():
		_studio_finance = plan.finance.ledger
	_sync_employee_raises()
	if not _pending_relationship_plan.is_empty(): _publisher_relationships = _pending_relationship_plan
	_pending_relationship_plan = {}
	_cycle_plan = {}
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
	if _familiarity != familiarity_before or _owned_features != ownership_before or _engine_features!=engine_features_before:
		features_changed.emit()
	if _unlocked_publishers != publishers_before:
		publishers_changed.emit()
	if _publisher_relationships != relationships_before:
		publisher_relationships_changed.emit()
	if get_completed_contract_count() != completed_contracts_before or _sidestreet_briefs != briefs_before or _publisher_relationships != relationships_before:
		contracts_changed.emit()
	if not _released_games.is_empty():
		sales_changed.emit()
	if get_fans() != previous_fans or Calendar.is_boundary(_completed_run_cycles,_calendar):
		fans_changed.emit()
	calendar_changed.emit()
	if _employees != employees_before: employees_changed.emit()
	_publishing_cycle = false
	return true


func get_employees() -> Dictionary:
	return _employees.duplicate(true)


## Public policy/menu facts omit mechanical RNG and unresolved Design searches.
func get_employee_observation() -> Dictionary:
	var result:=get_employees()
	result.erase("events")
	for employee: Dictionary in result.get("employees",{}).values():
		if employee.type==&"qa":
			employee.erase("rng_seed");employee.erase("rng_state");employee.erase("pending_design")
	return result

func get_employee_hire_quote(role: StringName) -> Dictionary:
	if role==&"project_manager" and not uses_employee_courses():return {}
	if not uses_employee_trial():
		if role!=&"production" or not _first_studio_economy or _released_games.is_empty() or not EmployeeRoster.valid(_employees) or not _employees.employees.is_empty():return {}
		return StudioFinanceLedger.hire_quote(_studio_finance,_bank_run_id)
	if not _first_studio_economy or _released_games.size()<2 or not EmployeeRoster.valid(_employees): return {}
	if _employees.employees.values().any(func(e):return e.type==role):return {}
	return StudioFinanceLedger.specialist_hire_quote(_studio_finance,_bank_run_id,role)

func get_production_hire_quote() -> Dictionary: return get_employee_hire_quote(&"production")

func hire_production_specialist(quote: Dictionary) -> bool: return hire_specialist(quote)

func hire_specialist(quote: Dictionary) -> bool:
	if not can_mutate_checkpoint() or not _bank_action_available() or quote.is_empty() or quote!=get_employee_hire_quote(quote.get("role",&"production")): return false
	var finance := StudioFinanceLedger.hire_employee(_studio_finance,quote,_bank_run_id)
	var roster := EmployeeRoster.hire_specialist(_employees,quote.role,_completed_run_cycles) if uses_employee_trial() else EmployeeRoster.hire(_employees,quote.employee_id,_completed_run_cycles)
	if finance.is_empty() or roster.is_empty(): return false
	_studio_finance=finance.ledger;_cash_cents=finance.cash_cents;_employees=roster
	_publishing_cycle=true;cash_changed.emit();finance_changed.emit();employees_changed.emit();_publishing_cycle=false
	return true

func get_qa_course_quote(course: StringName) -> Dictionary:
	if not uses_employee_trial() or not EmployeeRoster.valid(_employees) or not _first_studio_economy or _released_games.size()<2 or course not in [&"mixed",&"pure"] or _cash_cents<15000 or StudioFinanceLedger.get_unpaid(_studio_finance)!=0: return {}
	for e: Dictionary in _employees.employees.values():
		if e.type==&"qa" and not e.courses.has(course):
			return {"type":&"course","employee_id":e.employee_id,"course":course,"receipt_id":StringName("%s:course:%s"%[e.employee_id,course]),"revision":_studio_finance.actions.size(),"fee_cents":15000,"rules_version":2}
	return {}

func get_employee_course_quote(id: StringName, course: StringName) -> Dictionary:
	var employee: Dictionary=_employees.employees.get(id,{})
	if employee.is_empty():return {}
	if employee.type==&"qa":return get_qa_course_quote(course)
	if not uses_employee_courses() or not EmployeeRoster.valid(_employees) or not _first_studio_economy or _released_games.size()<2 or _cash_cents<15000 or StudioFinanceLedger.get_unpaid(_studio_finance)!=0:return {}
	if course not in EmployeeRoster.Career.course_ids(employee.type) or EmployeeRoster.Career.next_course(employee)!=course:return {}
	return {"type":&"course","employee_id":id,"course":course,"receipt_id":StringName("%s:course:%s"%[id,course]),"revision":_studio_finance.actions.size(),"fee_cents":15000,"rules_version":3}

func get_employee_course_quotes() -> Array:
	var result: Array=[]
	for employee: Dictionary in _employees.employees.values():
		for course: StringName in EmployeeRoster.Career.course_ids(employee.type):
			var quote:=get_employee_course_quote(employee.employee_id,course)
			if not quote.is_empty():result.append(quote)
	return result

func purchase_employee_course(quote: Dictionary) -> bool:
	if quote.get("rules_version")==2:return purchase_qa_course(quote)
	if not can_mutate_checkpoint() or not _bank_action_available() or quote.is_empty() or quote!=get_employee_course_quote(quote.get("employee_id",&""),quote.get("course",&"")):return false
	var roster:=EmployeeRoster.Career.enroll(_employees,quote.employee_id,quote.course,_completed_run_cycles)
	var finance:=StudioFinanceLedger.course_payment(_studio_finance,quote)
	if roster.is_empty() or finance.is_empty():return false
	_employees=roster;_studio_finance=finance.ledger;_cash_cents=finance.cash_cents
	_publishing_cycle=true;cash_changed.emit();finance_changed.emit();employees_changed.emit();_publishing_cycle=false
	return true

func purchase_qa_course(quote: Dictionary) -> bool:
	if not can_mutate_checkpoint() or not _bank_action_available() or quote.is_empty() or quote!=get_qa_course_quote(quote.get("course",&"")): return false
	var roster:=EmployeeRoster.buy_course(_employees,quote.employee_id,quote.course,_completed_run_cycles)
	var finance:=StudioFinanceLedger.course_payment(_studio_finance,quote)
	if roster.is_empty() or finance.is_empty(): return false
	_employees=roster;_studio_finance=finance.ledger;_cash_cents=finance.cash_cents
	_publishing_cycle=true;cash_changed.emit();finance_changed.emit();employees_changed.emit();_publishing_cycle=false
	return true

## Prospective schedules retain every already-issued $10 bill and payment.
func migrate_employee_wages() -> void:
	if not uses_employee_trial():return
	for payroll: Dictionary in _studio_finance.employees:
		if StudioFinanceLedger.payroll_wage(payroll,StudioFinanceLedger.MAX_INT,_calendar)>=100000: continue
		var receipt:=StringName("%s:wages-v2"%payroll.employee_id)
		var step:=StudioFinanceLedger.schedule_payroll(_studio_finance,payroll.employee_id,100000,StudioFinanceLedger.payroll_due_cycle(payroll,int(payroll.issued),_calendar),receipt)
		assert(not step.is_empty(),"Validated legacy payroll migration must succeed")
		_studio_finance=step.ledger

func _sync_employee_raises() -> void:
	# Non-economy scenarios have no payroll journal; ordinary profiles retain
	# their original employee rules while the new wage package is held.
	if not uses_employee_trial():return
	for payroll: Dictionary in _studio_finance.employees:
		var e: Dictionary=_employees.employees.get(payroll.employee_id,{})
		if e.get("type")!=&"qa" and not e.has("career"): continue
		var desired:=EmployeeRoster.Career.wage(e) if e.has("career") else EmployeeRoster.qa_wage(e)
		if StudioFinanceLedger.payroll_wage(payroll,StudioFinanceLedger.MAX_INT,_calendar)>=desired: continue
		var due:=Calendar.month_end(Calendar.month(_completed_run_cycles,_calendar)+1,_calendar)
		var step:=StudioFinanceLedger.schedule_payroll(_studio_finance,e.employee_id,desired,due,StringName("%s:raise:%d"%[e.employee_id,desired]))
		assert(not step.is_empty(),"Committed QA raise must schedule once")
		_studio_finance=step.ledger


func plan_employee_hand(project: ProjectState, phase: StringName, cards: Array, before: Dictionary, proposed: Dictionary = {}) -> Dictionary:
	if project == null or not EmployeeRoster.valid(_employees): return {}
	if _employees.employees.is_empty(): return {"before":_employees.duplicate(true),"after":_employees.duplicate(true),"cycle":_completed_run_cycles} if proposed.is_empty() else {}
	var roster := EmployeeRoster.plan_hand(_employees,project.get_release_id(),phase,project.get_current_cycle(),_completed_run_cycles,cards,before,proposed)
	if roster.is_empty(): return {}
	var discoveries:=0
	var first_stat: StringName=cards[0].primary_stat
	var specialization: bool=cards.size()==4 and cards.all(func(card):return card.primary_stat==first_stat)
	var count: int=cards.filter(func(card):return card.card_type==&"feature").size() if specialization else 0
	if count>0:
		for e: Dictionary in roster.employees.values():
			if e.type!=&"qa" or not e.trained: continue
			var rng:=RandomNumberGenerator.new();rng.seed=e.rng_seed;rng.state=e.rng_state
			for i in range(count):
				if rng.randi_range(1,100)<=EmployeeRoster.QA.PROC_PERCENT: discoveries+=1
			roster=EmployeeRoster.qa_proc(roster,project.get_release_id(),project.get_current_cycle(),_completed_run_cycles,phase,count)
			if roster.is_empty():return {}
	if uses_employee_courses() and roster.employees.values().any(func(e):return e.has("career")):
		roster=EmployeeRoster.Career.hand(roster,project.get_release_id(),phase,project.get_current_cycle(),_completed_run_cycles+1,EmployeeRoster.Career.facts(cards),before)
		if roster.is_empty():return {}
	return {"before":_employees.duplicate(true),"after":roster,"cycle":_completed_run_cycles,"qa_discoveries":discoveries if phase==&"alpha" else 0}


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
	var brief := get_sidestreet_brief_offer()
	if not brief.is_empty(): choices.append({"offer_id":brief.offer_id,"label":"SideStreet — Reputation Brief (no cash)"})
	if is_primitive_contract_offer_available(): choices.append({"offer_id":ContractState.CONTRACT_ID,"label":"Ironclad Interactive"})
	if _unlocked_publishers.has(PublisherCatalog.SIDESTREET):
		for release: StringName in _sidestreet_entitlements:
			var offer: Dictionary = _sidestreet_entitlements[release]
			if offer.state==null: choices.append({"offer_id":offer.offer_id,"label":"SideStreet — Found cash work" if not ContractSearch.source(self,offer.offer_id,&"cash").is_empty() else "SideStreet — "+get_released_game_display_name(release)})
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
	if not accepted.freeze_trial(quote.focus) or not accepted.freeze_challenge() or not accepted.commit_upfront(): return null
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

## Resolve prospective committed facts before touching the real Contract hand.
## The actual central cycle plan supplies the exact second-hand finance action.
func _plan_finishing_brief(state: ContractState, cards: Array[CardData], payment: int) -> Dictionary:
	if _cycle_plan.is_empty() or _cycle_plan.finance.is_empty() or not _sidestreet_briefs.has(state.get_offer_id()): return {}
	var projection := preload("res://scripts/simulation/transaction_projection.gd")
	var finishing := ContractState.new()
	projection.copy_fields(state,finishing)
	if not finishing.commit_hand(cards,payment) or not finishing.is_completed(): return {}
	var prospective := RunState.new()
	projection.copy_fields(self,prospective)
	prospective._sidestreet_briefs[state.get_offer_id()].state = finishing
	prospective._completed_run_cycles += 1
	prospective._studio_finance = _cycle_plan.finance.ledger
	prospective._released_games = _cycle_plan.records
	prospective._support_rights = _cycle_plan.support_rights
	prospective._support_assessments = _cycle_plan.support_assessments
	prospective._publisher_relationships = _cycle_plan.relationships
	var request := RelationshipRules.request_for(prospective,state.get_offer_id())
	if request.is_empty(): return {}
	var resolver := func(source: Dictionary) -> Dictionary: return RelationshipRules.resolve(prospective,source)
	var planned := RelationshipLedger.plan(prospective._publisher_relationships,_bank_run_id,request,prospective._completed_run_cycles,resolver)
	return {} if planned.is_empty() else {"applicable":true,"ledger":planned.ledger}

func plan_qa_beta_hand(project: ProjectState,cards: Array,discovered: int,fixed: int,priorities: Dictionary={}) -> Dictionary:
	var before:=_employees.duplicate(true)
	var search: int=cards.filter(func(c):return c.id==&"search_for_bugs").size()
	var debug: int=cards.filter(func(c):return c.id==&"debug").size()
	var state:=before.duplicate(true)
	if _employees.employees.values().any(func(e):return e.type==&"qa"):
		state=EmployeeRoster.qa_beta_hand(state,project.get_release_id(),project.get_current_cycle(),_completed_run_cycles+1,search,debug,discovered,fixed)
	if state.is_empty():return {}
	if uses_employee_courses() and state.employees.values().any(func(e):return e.has("career")):
		var weights: Dictionary=BetaPriorityAllocation.new().get_distribution() if priorities.is_empty() else priorities
		state=EmployeeRoster.Career.hand(state,project.get_release_id(),&"beta",project.get_current_cycle(),_completed_run_cycles+1,EmployeeRoster.Career.facts(cards),weights)
	return {} if state.is_empty() else {"before":before,"after":state,"cycle":_completed_run_cycles}


func resolve_qa_design_leads(project: ProjectState) -> int:
	var pending:=0
	var has_leads:=false
	for e: Dictionary in _employees.employees.values():
		if e.type==&"qa":
			has_leads=has_leads or e.pending_design.has(project.get_release_id())
			pending+=int(e.pending_design.get(project.get_release_id(),0))
	if not has_leads:return 0
	var found:=project.discover_bugs(pending)
	var state:=EmployeeRoster.qa_finalize(_employees,project.get_release_id(),project.get_current_cycle(),_completed_run_cycles)
	assert(not state.is_empty());_employees=state
	return found

func _cash_entitlement_key(offer_id: StringName) -> StringName:
	for key: StringName in _sidestreet_entitlements:
		if _sidestreet_entitlements[key].offer_id==offer_id:return key
	return &""

func can_browse_contract_search() -> bool:
	return _first_studio_economy and _unlocked_publishers.has(&"sidestreet")

func contract_search_blocker(publisher: StringName,work: StringName) -> String:
	if publisher!=&"sidestreet" or work not in ContractSearch.WORK_TYPES:return "No approved search template"
	if not can_browse_contract_search():return "Unlock SideStreet first"
	if get_active_contract()!=null or has_pending_commission() or has_unlaunched_support():return "Finish your active work first"
	if ContractSearch.pending(self,work):return "Existing work of this type is still pending"
	var standing:=get_publisher_relationships()
	if standing.is_empty():return "Relationship history unavailable"
	if work==&"commission":
		if standing[&"sidestreet"].reputation_bp<2000:return "Requires SideStreet Reputation 20"
		if _released_games.is_empty():return "Requires a released game"
	if _productive_cycle_in_progress or _publishing_cycle or _preparing_project or not can_mutate_checkpoint():return "Studio action unavailable"
	if not can_complete_productive_cycle():return "Cannot afford the next productive cycle and due bills"
	return ""

func get_contract_search_quote(publisher: StringName,work: StringName) -> Dictionary:
	if not contract_search_blocker(publisher,work).is_empty() or _contract_search.receipts.size()>=MAX_SIGNED_INT-1:return {}
	return {"rules_version":1,"owner":_bank_run_id,"publisher_id":publisher,"work":work,"template_id":ContractSearch.template(work),"terms":ContractSearch.terms(work),"ordinal":_contract_search.receipts.size()+1,"before_cycle":_completed_run_cycles,"finance_revision":_studio_finance.actions.size(),"relationship_revision":_publisher_relationships.events.size(),"standing_bp":get_publisher_relationships()[publisher].reputation_bp}

func search_contracts(quote: Dictionary) -> bool:
	if typeof(quote.get("publisher_id"))!=TYPE_STRING_NAME or typeof(quote.get("work"))!=TYPE_STRING_NAME:return false
	if quote.is_empty() or quote!=get_contract_search_quote(quote.get("publisher_id",&""),quote.get("work",&"")):return false
	var guard:=studio_action_guard if studio_action_guard.is_valid() else studio_departure_guard
	if guard.is_valid() and not guard.call():return false
	var plan:=ContractSearch.plan(_contract_search,quote)
	var initial:=_contract_search.duplicate(true)
	var commit:=func() -> bool:
		if _contract_search!=initial:return false
		_contract_search=plan.state
		if quote.work==&"cash":_sidestreet_entitlements[plan.offer_id]={"offer_id":plan.offer_id,"state":null}
		elif quote.work==&"brief":_sidestreet_briefs[plan.offer_id]={"offer_id":plan.offer_id,"source_release_id":&"","state":null}
		return true
	if not complete_productive_action(commit,0,_completed_run_cycles,&"",&"contract_search",plan.receipt.receipt_id):return false
	_publishing_cycle=true
	contracts_changed.emit()
	_publishing_cycle=false
	return true

func get_contract_search_catalog() -> Array:
	var rows: Array=[]
	for work: StringName in ContractSearch.WORK_TYPES:
		rows.append({"publisher_id":&"sidestreet","work":work,"terms":ContractSearch.terms(work),"blocker":contract_search_blocker(&"sidestreet",work),"quote":get_contract_search_quote(&"sidestreet",work)})
	return rows

func get_contract_search_state() -> Dictionary:return _contract_search.duplicate(true)

## Explicit trial activation: simulator opt-in or the unlocked Studio employee menu.
func uses_employee_trial() -> bool:return EmployeeRoster.trial_active(_employees)
func uses_employee_courses() -> bool:return EmployeeRoster.Career.active(_employees)
func activate_employee_trial() -> bool:
	if not can_mutate_checkpoint() or _productive_cycle_in_progress or _publishing_cycle:return false
	if uses_employee_courses():return false
	var next:=_employees.duplicate(true) if uses_employee_trial() else EmployeeRoster.activate_trial(_employees,_completed_run_cycles)
	if next.is_empty():return false
	next=EmployeeRoster.Career.enable(next,_completed_run_cycles)
	if next.is_empty():return false
	_employees=next;migrate_employee_wages();_sync_employee_raises()
	_publishing_cycle=true;finance_changed.emit();employees_changed.emit();_publishing_cycle=false
	return true
