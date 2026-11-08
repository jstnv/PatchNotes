## Quotes/plans over RunState's existing atomic cash/calendar transaction seam.
extends RefCounted
const Model=preload("res://scripts/engines/engine_feature_state.gd")

static func available(run: RefCounted) -> bool:
	return run.can_mutate_checkpoint() and not run._feature_purchase_in_progress and not run._productive_cycle_in_progress and not run._publishing_cycle and not run._preparing_project

static func pending(run: RefCounted) -> Array:
	var result: Array=[]
	for entry: Dictionary in run._feature_research:
		if entry.payments.size()<entry.actions:
			var old:=entry.duplicate(true);old.engine_id=&"legacy_engine";result.append(old)
	for entry: Dictionary in run.get_engine_feature_state().entries:
		if entry.payment==null:result.append({"id":entry.id,"engine_id":entry.engine_id,"feature_id":entry.feature_id,"base_cents":entry.base_cents,"actions":1,"admitted_cycle":entry.admitted_cycle,"payments":[]})
	return result

static func discount(run: RefCounted,offer: Dictionary) -> int:
	var credits:=0
	for parent: StringName in offer.get("parents",[]):credits+=run.get_feature_familiarity(parent)
	return mini(credits,8)*10

## Implementation and activation are separate: a replaced parent remains
## enabled for dependency checks even when normalization removes it from draws.
static func activation_quote(run: RefCounted,id: StringName,engine: StringName,state_override: Variant=null,graph_override: Dictionary={}) -> Dictionary:
	var state: Dictionary=state_override if state_override is Dictionary else run.get_engine_feature_state()
	if state.get("version",0)<Model.VERSION:state=Model.migrate(state,run._feature_offers)
	if state.is_empty() or not state.engines.has(engine):return {}
	var row: Dictionary=state.engines[engine]
	if row.kind!=&"proprietary" or id not in row.implemented or not FeatureStoreCatalog.is_active(id):return {}
	var graph: Dictionary=graph_override if not graph_override.is_empty() else FeatureStoreCatalog.graph(run._feature_definitions,run._feature_offers)
	if graph.has("error") or not graph.parents.has(id):return {}
	var enabled: bool=id in row.enabled
	var children: Array[StringName]=[]
	var parents: Array[StringName]=[]
	var linked_children_count:=0
	for child: StringName in graph.parents:
		if FeatureStoreCatalog.is_active(child) and id in graph.parents[child]:linked_children_count+=1
	for child: StringName in row.enabled:
		if FeatureStoreCatalog.is_active(child) and graph.parents.has(child) and id in graph.parents[child]:children.append(child)
	for parent: StringName in graph.parents[id]:
		if parent not in row.enabled:parents.append(parent)
	var pool: Array[StringName]=[];pool.assign(row.enabled)
	if not enabled:pool.append(id)
	pool=Model.normalize(pool,run._feature_offers)
	var scope:=0
	for feature: StringName in pool:
		if not run._feature_definitions.has(feature):return {}
		scope+=int(run._feature_definitions[feature].scope)
	var scope_blocked: bool=not enabled and scope>int(row.capacity)
	# Quotes are read-only: checkpoint_before_mutation may flush a save and
	# belongs to set_active, never to a Store refresh for every visible node.
	var ready: bool=run.checkpoint_mutations_allowed and not run._feature_purchase_in_progress and not run._productive_cycle_in_progress and not run._publishing_cycle and not run._preparing_project
	var can_toggle: bool=ready and (children.is_empty() if enabled else parents.is_empty() and not scope_blocked)
	return {"feature_id":id,"engine_id":engine,"enabled":enabled,"active_children":children,"linked_children_count":linked_children_count,"inactive_parents":parents,"projected_scope":scope,"scope_capacity":int(row.capacity),"scope_blocked":scope_blocked,"can_toggle":can_toggle}

static func set_active(run: RefCounted,supplied: Dictionary) -> bool:
	if not available(run) or not supplied.get("feature_id") is StringName or not supplied.get("engine_id") is StringName:return false
	var current:=activation_quote(run,supplied.feature_id,supplied.engine_id)
	if current.is_empty() or current!=supplied or not current.can_toggle:return false
	var state: Dictionary=run.get_engine_feature_state()
	if state.version<Model.VERSION:state=Model.migrate(state,run._feature_offers)
	if state.is_empty():return false
	var row: Dictionary=state.engines[current.engine_id]
	if current.enabled:row.enabled.erase(current.feature_id)
	else:row.enabled.append(current.feature_id)
	row.committed=Model.normalize(row.enabled,run._feature_offers)
	if not Model.valid(state,run._feature_definitions,run._feature_offers,run._studio_finance if run._first_studio_economy else {},run._completed_run_cycles,run._bank_run_id):return false
	run._feature_purchase_in_progress=true;run._engine_features=state
	run.engines_changed.emit();run.features_changed.emit();run._feature_purchase_in_progress=false
	return true

static func quote(run: RefCounted,id: StringName,engine: StringName,check_action: bool=true,offer_override: Dictionary={},pending_override: Variant=null,blocked_override: Variant=null,state_override: Variant=null,graph_override: Dictionary={}) -> Dictionary:
	var state: Dictionary=state_override if state_override is Dictionary else run.get_engine_feature_state()
	if not state.engines.has(engine):return {}
	# Old paid queues retain their original half-base deposit/installment math.
	if engine==&"legacy_engine":
		for old: Dictionary in run._feature_research:
			if old.feature_id==id and old.payments.size()<old.actions:
				var legacy: Dictionary=run._get_legacy_feature_research_quote(id,check_action)
				legacy.engine_id=engine;legacy.implementation_version=0;return legacy
	var offer: Dictionary=offer_override
	if offer.is_empty():
		offer=run.get_feature_store_offer(id,engine)
		if offer.is_empty():offer=run.get_primitive_reserve_offer(id,engine)
	if offer.is_empty():return {}
	# Prerequisites belong to the quoted engine, even when a FIFO head on A is
	# completed while browsing B. Familiarity remains the Studio ledger.
	offer=offer.duplicate(true)
	var graph: Dictionary=graph_override if not graph_override.is_empty() else FeatureStoreCatalog.graph(run._feature_definitions,run._feature_offers)
	if graph.has("error"):return {}
	var parents: Array=graph.parents[id];var missing:=false
	for parent: StringName in parents:
		if not Model.has_feature(state,engine,parent):missing=true
	var count:=0
	for feature: StringName in state.engines[engine].implemented:
		if run._feature_definitions[feature].get("department","")=="gameplay":count+=1
	offer.parents=parents
	offer.unlocked=not missing and count>=int(run._feature_definitions[id].get("gameplay_features_required",0)) and offer.get("year_reached",true) and offer.get("era_qualified",true)
	var queue: Array=pending(run) if pending_override==null else pending_override
	var entry: Dictionary={}
	for item: Dictionary in state.entries:
		if item.engine_id==engine and item.feature_id==id:entry=item;break
	var percent: int=discount(run,offer)
	if not entry.is_empty():percent=maxi(percent,int(entry.admission_discount))
	var base: int=Model.base_price(id,run._feature_definitions,run._feature_offers)
	var total: int=Model.discounted(base,percent)
	var down: int=total/2+total%2 if entry.is_empty() else int(entry.deposit_cents)
	var implemented: bool=Model.has_feature(state,engine,id)
	var due: int=0 if implemented else maxi(0,total-down)
	var saving: int=run.resourceful_saving(due)
	var queued: bool=not entry.is_empty() and entry.payment==null
	var head: bool=queued and not queue.is_empty() and queue[0].id==entry.id
	var blocked: String=run.get_financial_block_reason() if blocked_override==null else blocked_override
	var editable: bool=state.engines[engine].kind==&"proprietary"
	var identity: StringName=StringName("%s:implementation:%s:%s"%[run._bank_run_id,engine,id])
	return {"feature_id":id,"engine_id":engine,"implementation_version":1,"entry_id":identity,"base_cents":base,"total_cents":total,"down_cents":down,"due_cents":due-saving,"saving_cents":saving,"nominal_cents":due,"discount_percent":percent,"actions":1,"completed":1 if implemented else 0,"paid_cents":0 if entry.is_empty() else int(entry.deposit_cents)+(0 if entry.payment==null else int(entry.payment.paid_cents)),"remaining_actions":0 if implemented else 1,"remaining_cents":due-saving,"queued":queued,"head":head,"unlocked":offer.get("unlocked",false),"can_admit":editable and entry.is_empty() and not run.owns_feature(id,engine) and FeatureStoreCatalog.is_active(id) and offer.get("unlocked",false) and blocked.is_empty() and run.get_cash_cents()>=down,"can_research":editable and head and check_action and run.can_complete_productive_cycle(-(due-saving)),"cycle":run.get_completed_run_cycles(),"cash_cents":run.get_cash_cents(),"revision":run._studio_finance.get("actions",[]).size(),"queue_size":queue.size(),"resourceful_window":run._released_games.size()}

static func admit(run: RefCounted,supplied: Dictionary) -> bool:
	if not available(run) or not supplied.get("feature_id") is StringName or not supplied.get("engine_id") is StringName:return false
	var current:=quote(run,supplied.feature_id,supplied.engine_id)
	if current!=supplied or not current.can_admit:return false
	var plan: Dictionary=StudioFinanceLedger.plan(run._studio_finance,current.cycle,run.get_cash_cents(),-int(current.down_cents),&"store",0,0,false,StringName(str(current.entry_id)+":admit")) if run._first_studio_economy else {"cash_cents":run.get_cash_cents()-int(current.down_cents),"ledger":run._studio_finance}
	if plan.is_empty():return false
	var state: Dictionary=run.get_engine_feature_state()
	if state.version<Model.VERSION:state=Model.migrate(state,run._feature_offers)
	if state.is_empty():return false
	state.entries.append({"id":current.entry_id,"engine_id":current.engine_id,"feature_id":current.feature_id,"base_cents":current.base_cents,"admitted_cycle":current.cycle,"deposit_cents":current.down_cents,"admission_discount":current.discount_percent,"payment":null})
	run._feature_purchase_in_progress=true;run._engine_features=state;run._cash_cents=plan.cash_cents;run._studio_finance=plan.ledger
	run.cash_changed.emit();run.finance_changed.emit();run.features_changed.emit();run._feature_purchase_in_progress=false
	return true

static func complete(run: RefCounted,supplied: Dictionary) -> bool:
	if not available(run) or not supplied.get("feature_id") is StringName or not supplied.get("engine_id") is StringName or not supplied.get("can_research",false):return false
	if supplied.get("implementation_version")==0:return run._research_legacy_feature(supplied)
	var current:=quote(run,supplied.feature_id,supplied.engine_id,false)
	var comparison:=supplied.duplicate(true);comparison.can_research=false
	if comparison!=current or not current.head:return false
	var state: Dictionary=run.get_engine_feature_state()
	if state.version<Model.VERSION:state=Model.migrate(state,run._feature_offers)
	if state.is_empty():return false
	for entry: Dictionary in state.entries:
		if entry.id!=current.entry_id:continue
		entry.payment={"cycle":current.cycle+1,"paid_cents":current.due_cents,"discount_percent":current.discount_percent,"saving_cents":current.saving_cents,"window":current.resourceful_window}
		state.engines[current.engine_id].implemented.append(current.feature_id)
		var row: Dictionary=state.engines[current.engine_id]
		var graph:=FeatureStoreCatalog.graph(run._feature_definitions,run._feature_offers)
		if graph.has("error") or not graph.parents.has(current.feature_id):return false
		var parents_active:=true
		for parent: StringName in graph.parents[current.feature_id]:
			if parent not in row.enabled:parents_active=false
		var enabled: Array[StringName]=[];enabled.assign(row.enabled);enabled.append(current.feature_id)
		var pool:=Model.normalize(enabled,run._feature_offers)
		var scope:=0
		for feature: StringName in pool:scope+=int(run._feature_definitions[feature].scope)
		if parents_active and scope<=int(row.capacity):row.enabled=enabled;row.committed=pool
		var apply:=func() -> bool:
			run._engine_features=state
			if current.engine_id==&"legacy_engine":run._owned_features[current.feature_id]=true
			if current.saving_cents>0:run._resourceful_claims[run._released_games.size()]=current.entry_id
			return true
		return run.complete_productive_action(apply,-int(current.due_cents),current.cycle,&"",&"store",StringName(str(current.entry_id)+":complete"))
	return false
