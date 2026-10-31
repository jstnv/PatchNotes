## Phase1 data only. Definitions, familiarity, finance and project physics live
## in their existing authoritative systems; this registry contains IDs/receipts.
extends RefCounted
const VERSION:=1
const KINDS: Array[StringName]=[&"public",&"rival_licensed",&"proprietary"]
const LEGACY:=&"legacy_engine"

static func create(owned: Array[StringName],engines: Array[StringName],studio: StringName,offers: Dictionary={}) -> Dictionary:
	var state: Dictionary={"version":VERSION,"engines":{},"entries":[],"configurations":[]}
	for id: StringName in engines:
		var listing: Dictionary=preload("res://scripts/engines/engine_marketplace.gd").find(id)
		var kind: StringName=&"proprietary" if id==LEGACY or listing.get("creator_id")==studio else &"rival_licensed"
		add_record(state,id,"Built-in Engine" if id==LEGACY else str(listing.get("name",id)),kind,ProjectState.MAX_SIGNED_INT if id==LEGACY else int(listing.get("max_scope",25)),owned,"legacy-access-v1")
		state.engines[id].committed=FeatureStoreCatalog.future_supply(owned,offers)
	return state

static func add_record(state: Dictionary,id: StringName,label: String,kind: StringName,capacity: int,library: Array[StringName],origin: String="declared-v1") -> bool:
	if id.is_empty() or state.engines.has(id) or label.strip_edges().is_empty() or label.length()>80 or kind not in KINDS or capacity<1:return false
	if not unique_ids(library):return false
	state.engines[id]={"name":label,"kind":kind,"capacity":capacity,"origin":origin,"initial":library.duplicate(),"implemented":library.duplicate(),"committed":library.duplicate(),"staged":[] as Array[StringName],"revision":0}
	return true

static func unique_ids(ids: Array) -> bool:
	var seen: Dictionary={}
	for id: Variant in ids:
		if not id is StringName or id.is_empty() or seen.has(id):return false
		seen[id]=true
	return true

static func has_feature(state: Dictionary,engine: StringName,id: StringName) -> bool:
	return state.engines.has(engine) and id in state.engines[engine].implemented

static func stage(state: Dictionary,engine: StringName,ids: Array[StringName],definitions: Dictionary,offers: Dictionary) -> bool:
	if not state.engines.has(engine) or not unique_ids(ids):return false
	var record: Dictionary=state.engines[engine]
	if record.kind!=&"proprietary":return false
	for id: StringName in ids:
		if id not in record.implemented or id in record.committed or not definitions.has(id) or not FeatureStoreCatalog.is_active(id):return false
	record.staged=ids.duplicate()
	return true

static func supply(state: Dictionary,engine: StringName,offers: Dictionary) -> Array[StringName]:
	if not state.engines.has(engine):return []
	var ids: Array[StringName]=[];ids.assign(state.engines[engine].committed)
	return FeatureStoreCatalog.future_supply(ids,offers)

static func discounted(base: int,discount: int) -> int:
	if base<0:return -1
	var percent: int=100-clampi(discount,0,80)
	return (base/100)*percent+((base%100)*percent)/100

static func base_price(id: StringName,definitions: Dictionary,offers: Dictionary) -> int:
	if not definitions.has(id):return -1
	return int(offers[id].base_price_cents) if offers.has(id) else (int(definitions[id].scope)+1)*15000

static func valid(state: Dictionary,definitions: Dictionary,offers: Dictionary,ledger: Dictionary={},cycle: int=-1,studio: StringName=&"") -> bool:
	if state.size()!=4 or state.get("version")!=VERSION or not state.get("engines") is Dictionary or state.engines.is_empty() or state.engines.size()>128 or not state.get("entries") is Array or not state.get("configurations") is Array:return false
	var implemented: Dictionary={};var configured: Dictionary={};var revisions: Dictionary={}
	var graph:=FeatureStoreCatalog.graph(definitions,offers)
	if graph.has("error"):return false
	var available_at: Dictionary={}
	for id: Variant in state.engines:
		var row: Variant=state.engines[id]
		if not id is StringName or id.is_empty() or not row is Dictionary or row.size()!=9 or row.get("kind") not in KINDS or not row.get("name") is String or row.name.is_empty() or row.name.length()>80 or not row.get("capacity") is int or row.capacity<1 or not row.get("revision") is int or row.revision<0 or row.get("origin") not in ["legacy-access-v1","declared-v1"]:return false
		for key: String in ["initial","implemented","committed","staged"]:
			if not row.get(key) is Array or not unique_ids(row[key]):return false
			for feature: StringName in row[key]:
				if not definitions.has(feature):return false
		if row.kind!=&"proprietary" and (not row.staged.is_empty() or row.revision!=0 or row.initial!=row.implemented or normalize(row.initial,offers)!=row.committed):return false
		for feature: StringName in row.committed+row.staged:
			if feature not in row.implemented:return false
		for feature: StringName in row.staged:
			if feature in row.committed or not FeatureStoreCatalog.is_active(feature):return false
		implemented[id]=row.initial.duplicate();configured[id]=normalize(row.initial,offers);revisions[id]=0
		available_at[id]={}
		for feature: StringName in row.initial:available_at[id][feature]=0
	var receipts: Dictionary={}
	for action: Dictionary in ledger.get("actions",[]):
		var key: StringName=action.source_id
		if not receipts.has(key):receipts[key]=[]
		receipts[key].append(action)
	var seen: Dictionary={};var waiting:=false;var last_admission:=-1;var last_payment:=-1
	for entry: Variant in state.entries:
		if not entry is Dictionary or entry.size()!=8 or not state.engines.has(entry.get("engine_id")) or state.engines[entry.engine_id].kind!=&"proprietary" or not definitions.has(entry.get("feature_id")) or entry.feature_id in implemented[entry.engine_id] or seen.has(entry.get("id")):return false
		if not entry.id is StringName or entry.id!=StringName("%s:implementation:%s:%s"%[studio,entry.engine_id,entry.feature_id]) or entry.base_cents!=base_price(entry.feature_id,definitions,offers) or entry.admission_discount<0 or entry.admission_discount>80 or entry.admission_discount%10!=0 or entry.admitted_cycle<last_admission or (cycle>=0 and entry.admitted_cycle>cycle):return false
		if not FeatureStoreCatalog.is_active(entry.feature_id):return false
		for parent: StringName in graph.parents[entry.feature_id]:
			if not available_at[entry.engine_id].has(parent) or available_at[entry.engine_id][parent]>entry.admitted_cycle:return false
		last_admission=entry.admitted_cycle;seen[entry.id]=true
		var total: int=discounted(entry.base_cents,entry.admission_discount)
		if entry.deposit_cents!=total/2+total%2:return false
		if not ledger.is_empty() and not receipt(receipts,StringName(str(entry.id)+":admit"),entry.admitted_cycle,-int(entry.deposit_cents),false):return false
		if entry.payment==null:waiting=true;continue
		var payment: Variant=entry.payment
		if waiting or not payment is Dictionary or payment.size()!=5 or payment.discount_percent<entry.admission_discount or payment.discount_percent>80 or payment.discount_percent%10!=0 or payment.cycle<=entry.admitted_cycle or payment.cycle<=last_payment or (cycle>=0 and payment.cycle>cycle):return false
		last_payment=payment.cycle
		var due: int=maxi(0,discounted(entry.base_cents,payment.discount_percent)-int(entry.deposit_cents))
		if payment.saving_cents<0 or payment.saving_cents>mini(10000,due) or payment.paid_cents!=due-int(payment.saving_cents):return false
		if not ledger.is_empty() and not receipt(receipts,StringName(str(entry.id)+":complete"),payment.cycle,-int(payment.paid_cents),true):return false
		implemented[entry.engine_id].append(entry.feature_id)
		available_at[entry.engine_id][entry.feature_id]=payment.cycle
	var configuration_cycles: Dictionary={}
	for event: Variant in state.configurations:
		if not event is Dictionary or event.size()!=9 or not state.engines.has(event.get("engine_id")) or state.engines[event.engine_id].kind!=&"proprietary":return false
		var engine: StringName=event.engine_id;var previous: Array[StringName]=[];previous.assign(configured[engine])
		if event.revision!=int(revisions[engine])+1 or event.id!=StringName("%s:engine-config:%s:%d"%[studio,engine,event.revision]) or event.cycle<=int(configuration_cycles.get(engine,-1)) or (cycle>=0 and event.cycle>cycle):return false
		configuration_cycles[engine]=event.cycle
		for key: String in ["target","added","removed"]:
			if not event.get(key) is Array or not unique_ids(event[key]):return false
		if normalize(event.target,offers)!=event.target:return false
		var removed: Array[StringName]=[];var added: Array[StringName]=[]
		for feature: StringName in previous:
			if feature not in event.target:removed.append(feature)
		for feature: StringName in event.target:
			if feature not in implemented[engine] or available_at[engine][feature]>event.cycle:return false
			if feature not in previous:added.append(feature)
		var base:=0
		for feature: StringName in removed:base+=base_price(feature,definitions,offers)
		if removed!=event.removed or added!=event.added or event.base_cents!=base or event.cost_cents!=(base/10+int(base%10!=0)) or (removed.is_empty() and added.is_empty()):return false
		if not ledger.is_empty() and not receipt(receipts,event.id,event.cycle,-int(event.cost_cents),true):return false
		configured[engine]=event.target.duplicate();revisions[engine]=event.revision
	for engine: StringName in state.engines:
		if state.engines[engine].implemented!=implemented[engine] or state.engines[engine].committed!=configured[engine] or state.engines[engine].revision!=revisions[engine]:return false
	return true

static func receipt(proofs: Dictionary,id: StringName,cycle: int,delta: int,productive: bool) -> bool:
	var rows: Array=proofs.get(id,[])
	if rows.size()!=1:return false
	var action: Dictionary=rows[0]
	return action.kind==&"store" and action.cycle==cycle and action.direct_delta==delta and action.productive==productive

static func normalize(ids: Array,offers: Dictionary) -> Array[StringName]:
	var typed: Array[StringName]=[];typed.assign(ids)
	return FeatureStoreCatalog.future_supply(typed,offers)

static func bindings_valid(state: Dictionary,entitlements: Dictionary,owned: Dictionary,studio: StringName) -> bool:
	var registered: Array[StringName]=[]
	for id: StringName in state.engines:
		if id!=LEGACY and preload("res://scripts/engines/engine_marketplace.gd").find(id).is_empty():registered.append(id)
	if not preload("res://scripts/engines/engine_entitlements.gd").valid(entitlements,registered) or entitlements.studio_id!=studio:return false
	var ids: Array=entitlements.owned_ids+entitlements.licensed_ids
	if ids.size()!=state.engines.size() or not state.engines.has(LEGACY):return false
	if state.engines[LEGACY].implemented.size()!=owned.size():return false
	for id: StringName in owned:
		if not owned[id] or id not in state.engines[LEGACY].implemented:return false
	for id: StringName in ids:
		if not state.engines.has(id):return false
		var row: Dictionary=state.engines[id]
		if id in entitlements.licensed_ids and row.kind!=&"rival_licensed":return false
		if id in entitlements.owned_ids and row.kind not in [&"proprietary",&"public"]:return false
		var listing:=preload("res://scripts/engines/engine_marketplace.gd").find(id)
		var capacity: int=ProjectState.MAX_SIGNED_INT if id==LEGACY else int(listing.get("max_scope",20))
		if row.capacity!=capacity:return false
	return true
