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
		offer=run.get_feature_store_offer(id)
		if offer.is_empty():offer=run.get_primitive_reserve_offer(id)
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
	return {"feature_id":id,"engine_id":engine,"implementation_version":1,"entry_id":identity,"base_cents":base,"total_cents":total,"down_cents":down,"due_cents":due-saving,"saving_cents":saving,"nominal_cents":due,"discount_percent":percent,"actions":1,"completed":1 if implemented else 0,"paid_cents":0 if entry.is_empty() else int(entry.deposit_cents)+(0 if entry.payment==null else int(entry.payment.paid_cents)),"remaining_actions":0 if implemented else 1,"remaining_cents":due-saving,"queued":queued,"head":head,"unlocked":offer.get("unlocked",false),"can_admit":editable and entry.is_empty() and not Model.has_feature(state,engine,id) and FeatureStoreCatalog.is_active(id) and not run.needs_starter_selection() and offer.get("unlocked",false) and blocked.is_empty() and run.get_cash_cents()>=down,"can_research":editable and head and check_action and run.can_complete_productive_cycle(-(due-saving)),"cycle":run.get_completed_run_cycles(),"cash_cents":run.get_cash_cents(),"revision":run._studio_finance.get("actions",[]).size(),"queue_size":queue.size(),"resourceful_window":run._released_games.size()}

static func admit(run: RefCounted,supplied: Dictionary) -> bool:
	if not available(run) or not supplied.get("feature_id") is StringName or not supplied.get("engine_id") is StringName:return false
	var current:=quote(run,supplied.feature_id,supplied.engine_id)
	if current!=supplied or not current.can_admit:return false
	var plan: Dictionary=StudioFinanceLedger.plan(run._studio_finance,current.cycle,run.get_cash_cents(),-int(current.down_cents),&"store",0,0,false,StringName(str(current.entry_id)+":admit")) if run._first_studio_economy else {"cash_cents":run.get_cash_cents()-int(current.down_cents),"ledger":run._studio_finance}
	if plan.is_empty():return false
	var state: Dictionary=run.get_engine_feature_state()
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
	for entry: Dictionary in state.entries:
		if entry.id!=current.entry_id:continue
		entry.payment={"cycle":current.cycle+1,"paid_cents":current.due_cents,"discount_percent":current.discount_percent,"saving_cents":current.saving_cents,"window":current.resourceful_window}
		state.engines[current.engine_id].implemented.append(current.feature_id)
		var apply:=func() -> bool:
			run._engine_features=state
			if current.engine_id==&"legacy_engine":run._owned_features[current.feature_id]=true
			if current.saving_cents>0:run._resourceful_claims[run._released_games.size()]=current.entry_id
			return true
		return run.complete_productive_action(apply,-int(current.due_cents),current.cycle,&"",&"store",StringName(str(current.entry_id)+":complete"))
	return false

static func configuration(run: RefCounted,engine: StringName,target_override: Variant=null) -> Dictionary:
	var state: Dictionary=run.get_engine_feature_state()
	if not state.engines.has(engine) or state.engines[engine].kind!=&"proprietary":return {}
	var record: Dictionary=state.engines[engine]
	var desired: Array[StringName]=[]
	if target_override==null:desired.assign(record.committed+record.staged)
	elif target_override is Array and Model.unique_ids(target_override):desired.assign(target_override)
	else:return {}
	for id: StringName in desired:
		if id not in record.implemented:return {}
	var target: Array[StringName]=FeatureStoreCatalog.future_supply(desired,run._feature_offers)
	var removed: Array[StringName]=[];var added: Array[StringName]=[];var base:=0
	for id: StringName in record.committed:
		if id not in target:removed.append(id);base+=Model.base_price(id,run._feature_definitions,run._feature_offers)
	for id: StringName in target:
		if id not in record.committed:added.append(id)
	var fee: int=base/10+int(base%10!=0)
	return {"engine_id":engine,"target":target,"staged":record.staged.duplicate(),"removed":removed,"added":added,"base_cents":base,"cost_cents":fee,"revision":record.revision,"cycle":run.get_completed_run_cycles(),"cash_cents":run.get_cash_cents(),"finance_revision":run._studio_finance.get("actions",[]).size(),"requires_respec":not removed.is_empty(),"can_commit":not run.needs_starter_selection() and not (engine==&"legacy_engine" and has_legacy_pending(run)) and (not removed.is_empty() or not added.is_empty()) and run.can_complete_productive_cycle(-fee)}

static func commit_configuration(run: RefCounted,supplied: Dictionary,respec: bool=false) -> bool:
	if not available(run) or not supplied.get("engine_id") is StringName:return false
	var current:=configuration(run,supplied.engine_id,supplied.get("target") if respec else null)
	if current!=supplied or not current.get("can_commit",false) or (current.requires_respec and not respec):return false
	var state: Dictionary=run.get_engine_feature_state();var next_revision: int=int(current.revision)+1
	var id:=StringName("%s:engine-config:%s:%d"%[run._bank_run_id,current.engine_id,next_revision])
	state.configurations.append({"id":id,"engine_id":current.engine_id,"revision":next_revision,"cycle":current.cycle+1,"cost_cents":current.cost_cents,"base_cents":current.base_cents,"added":current.added.duplicate(),"removed":current.removed.duplicate(),"target":current.target.duplicate()})
	state.engines[current.engine_id].committed=current.target.duplicate();state.engines[current.engine_id].staged.clear();state.engines[current.engine_id].revision=next_revision
	var apply:=func() -> bool:run._engine_features=state;return true
	return run.complete_productive_action(apply,-int(current.cost_cents),current.cycle,&"",&"store",id)

static func has_legacy_pending(run: RefCounted) -> bool:
	for entry: Dictionary in run._feature_research:
		if entry.payments.size()<entry.actions:return true
	return false
