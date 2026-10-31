## Normal12-Scope careers. Explicit test policy; no granted money/Features.
extends SceneTree
const Factory=preload("res://scripts/simulation/run_factory.gd")
const Finite=preload("res://scripts/simulation/finite_fixture_policy.gd")
const Replay=preload("res://scripts/simulation/development_replay.gd")
var issues: Array=[]
var checks:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:issues.append(message);push_error(message)
func arg(prefix: String,fallback: String="") -> String:
	for value: String in OS.get_cmdline_user_args():
		if value.begins_with(prefix):return value.trim_prefix(prefix)
	return fallback
func owned_scope(run: RunState) -> int:
	var total:=0
	for id: StringName in run.get_future_project_feature_ids():total+=int(run._feature_definitions[id].scope)
	return total
func loan(run: RunState) -> Dictionary:
	for months in [24,36]:
		var quote:=run.get_bank_quote(150000,months)
		if quote.get("accepted",false):return {"type":&"bank_borrow","payload":{"quote":quote}}
	return {}
func recovery(session: RefCounted) -> Dictionary:
	var view: Dictionary=session.observation()
	for offer: Dictionary in view.studio_actions.contract_offers:
		var payload:=offer.duplicate(true)
		if payload.kind==&"sidestreet_brief":pass
		return {"type":&"accept_contract","payload":payload}
	for row: Dictionary in view.studio_actions.contract_search:
		if row.work==&"cash" and not row.quote.is_empty():return {"type":&"search_contracts","payload":{"quote":row.quote}}
	return loan(session.run)
func choose(session: RefCounted,policy: Callable,memory: Dictionary) -> Dictionary:
	var run: RunState=session.run;var view: Dictionary=session.observation()
	if view.phase==&"contract":
		var current: Dictionary=view.contract
		if current.completed:return {"type":&"dismiss_contract"}
		var kind: StringName=&"begin" if current.candidates.is_empty() else &"play"
		var payload: Dictionary={}
		if kind==&"play":payload.candidate_ids=current.candidates.slice(0,4).map(func(card):return int(card.token))
		return {"type":&"contract","payload":{"request":session.contract.command(kind,payload)}}
	if run.get_cash_cents()<100000 and memory.get("loan_project",-1)!=view.releases.size():
		var bridge:=loan(run)
		if not bridge.is_empty():memory.loan_project=view.releases.size();return bridge
	if view.phase==&"studio":
		var queue:=run.get_feature_research_queue()
		if not queue.is_empty():
			var quote:=run.get_feature_research_quote(queue[0].feature_id)
			if quote.get("can_research",false):return {"type":&"research","payload":{"quote":quote}}
			return recovery(session)
		var target:=mini(30,12+4*view.releases.size())
		if view.releases.size()>0 and owned_scope(run)<target:
			var best: Dictionary={};var rate:=INF
			for id: StringName in run._feature_definitions:
				if run.owns_feature(id) or not FeatureStoreCatalog.is_active(id):continue
				var card: Dictionary=run._feature_definitions[id]
				if int(card.get("scope",0))<=0 or card.get("phase","") not in ["design","alpha"]:continue
				if run._feature_offers.get(id,{}).has("replaces_id"):continue
				var quote:=run.get_feature_research_quote(id)
				if not quote.get("can_admit",false):continue
				var cost: int=int(quote.down_cents)+int(quote.remaining_cents)
				var value:=float(cost)/float(mini(int(card.scope),target-owned_scope(run)))
				if value<rate and run.get_cash_cents()>=cost+200000:rate=value;best=quote
			if not best.is_empty():return {"type":&"admit_research","payload":{"quote":best}}
			var work:=recovery(session)
			if not work.is_empty():return work
		var cards: Array[CardData]=[]
		for id: StringName in run.get_future_project_feature_ids():
			var card: CardData=session.catalog.get_card(id)
			if card!=null:cards.append(card)
		var reserve: int=run.primitive_feature_hand_cost_cents(cards)+int(run._studio_finance.monthly_rent_cents)*6
		if view.releases.size()>0 and run.get_cash_cents()<reserve:
			var work:=recovery(session)
			if not work.is_empty():return work
	return policy.call(view)
func audit(before: Dictionary,after: Dictionary,choice: Dictionary) -> Dictionary:
	var result: Dictionary={}
	if before.phase not in ["design","alpha"] or choice.get("type")!=&"development" or choice.payload.request.type!=&"play":return result
	var current: Dictionary=before.development;var printed:=0;var passes:=0
	for card: Dictionary in current.candidates:
		if int(card.token) not in choice.payload.request.payload.candidate_ids:continue
		if card.type=="pass":passes+=1
		else:
			if card.has("core_contributions"):
				for entry: Dictionary in card.core_contributions:printed+=int(entry.value)
			else:printed+=int(card.primary_value)+int(card.secondary_value)
	var got: Dictionary=after.development.pass_budget;var prior: Dictionary=current.pass_budget
	check(got.version==1 and got.printed==prior.printed+printed and got.spent==prior.spent+passes,"Exact successful hand counter delta")
	check(got.spent<=2+int(got.printed)/8 and got.remaining>=0,"Cumulative2/K8 cannot overspend")
	return {"phase":before.phase,"project":before.project_id,"feature_core":printed,"passes":passes,"printed":got.printed,"spent":got.spent,"remaining":got.remaining}
func _initialize() -> void:
	await process_frame
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var input: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(arg("--input=")))
	var rows: Array=[]
	for row: Dictionary in input.rows:
		var session: RefCounted=Factory.create_fresh_session(row.recipe,catalog)
		var cold_count:=0;var boundary_count:=0
		for index in range(row.commands.size()):
			var command: Dictionary=bytes_to_var(Marshalls.base64_to_raw(row.commands[index].command))
			var result: Dictionary=session.execute(command)
			check(result.ok and compact_digest(session)==row.commands[index].state,"Final-source recorded persistent state/RNG "+str(index))
			if not result.ok:break
			if session.in_studio and session.run.get_active_contract()==null:
				var before:=compact_digest(session);var envelope: Dictionary=JSON.parse_string(JSON.stringify(session.export_checkpoint()))
				var cold: RefCounted=Factory.create({"checkpoint":envelope},catalog)
				check(cold!=null and compact_digest(cold)==before,"Final-source Studio JSON Continue exact")
				if cold==null:break
				session=cold;cold_count+=1
			else:
				check(session.export_checkpoint().is_empty(),"Active player cannot publish Continue");boundary_count+=1
		check(session.run.get_released_game_ids().size()==8,"Eight recorded releases on final source")
		rows.append({"genre":row.recipe.specialty,"seed":row.recipe.seed,"commands":row.commands.size(),"Studio_continues":cold_count,"active_rejections":boundary_count,"releases":session.run.get_released_game_ids().size(),"cycle":session.run.get_completed_run_cycles()})
		print("FINAL_CAREER_REPLAY ",rows.back())
	FileAccess.open(arg("--output="),FileAccess.WRITE).store_string(JSON.stringify({"source":Replay.source_identity(),"checks":checks,"failures":issues,"rows":rows},"\t"));print("FINAL_REPLAY ",checks," failures=",issues.size());quit(0 if issues.is_empty() else 1)

## Compact command-replay authority: all persistent Run fields, actual project/
## hand DTOs, Contract instances/tokens and RNG; immutable definitions are pinned
## by the separate source manifest. This is not an accepted player save format.
func plain(value: Variant) -> Variant:
	if value is StringName:return str(value)
	if value is Array:
		var result: Array=[]
		for item: Variant in value:result.append(plain(item))
		return result
	if value is Dictionary:
		var result: Dictionary={}
		var keys: Array=value.keys();keys.sort_custom(func(a,b):return str(a)<str(b))
		for key: Variant in keys:result[plain(key)]=plain(value[key])
		return result
	if value is Object:return plain(Replay.freeze(value))
	return value
func compact_digest(session: RefCounted) -> String:
	var run: Dictionary={}
	for field: String in StudioCheckpoint.FIELDS+StudioCheckpoint.SUPPORT_FIELDS:run[field]=session.run.get(field)
	run.engine_entitlements=session.run.get_engine_entitlements()
	run.rng=session.run.random_streams.snapshot();run.serial=session.run.next_project_serial
	run.first_game_tutorial=session.run._first_game_tutorial
	run.contract=session.run._primitive_contract;run.sidestreet=session.run._sidestreet_entitlements;run.briefs=session.run._sidestreet_briefs;run.publisher=session.run._publisher_offers
	var development: Variant=null
	if not session.in_studio and session.contract==null:development=preload("res://scripts/market/rival_world_checkpoint.gd").new()._snapshot_development(session)
	var contract: Variant=null
	if session.contract!=null:contract=[session.contract.observation(),session.contract.sequence,session.contract.next_id]
	var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(var_to_bytes(plain([session.sequence,session.in_studio,run,development,contract])));return hash.finish().hex_encode()
