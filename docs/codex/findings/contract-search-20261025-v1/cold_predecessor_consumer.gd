extends SceneTree
const Codec=preload("res://scripts/market/rival_world_checkpoint.gd")
const Replay=preload("res://scripts/simulation/development_replay.gd")
var checks:=0
var failures:=0
var output: String
var input: String
func expect(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func compare_player(old: Dictionary,now: Dictionary,active: bool) -> void:
	var codec:=CheckpointCodec.new()
	var before: Variant=codec.decode(old,StudioCheckpoint.PreSearchSchema.root(true,active))
	expect(codec.error.is_empty(),"Actual predecessor decodes through preserved closed schema")
	var after: Variant=codec.decode(now,CheckpointSchema.root(true,active))
	expect(codec.error.is_empty(),"Migrated owner decodes through current closed schema")
	if before==null or after==null:return
	expect(before.rng==after.rng,"Every mechanical RNG stream remains exact")
	var a: Dictionary=before.run;var b: Dictionary=after.run
	expect(b.contract_search==RunState.ContractSearch.from_legacy(a),"Migration adds only actual recorded legacy rights and empty Search history")
	b.erase("contract_search")
	var old_fin: Dictionary=a.studio_finance;var new_fin: Dictionary=b.studio_finance
	expect(old_fin.obligations==new_fin.obligations and old_fin.credit==new_fin.credit and old_fin.bank_loans==new_fin.bank_loans and old_fin.education==new_fin.education,"Issued bills, age, payments, credit, Bank and education remain exact")
	expect(new_fin.actions.slice(0,old_fin.actions.size())==old_fin.actions and new_fin.transactions.slice(0,old_fin.transactions.size())==old_fin.transactions and new_fin.monthly_rows.slice(0,old_fin.monthly_rows.size())==old_fin.monthly_rows,"All historical finance actions, receipts and monthly rows remain exact")
	var old_employees: Array=old_fin.employees;var new_employees: Array=new_fin.employees.duplicate(true)
	for e: Dictionary in new_employees:
		expect(not e.has("wage_changes"),"Ordinary predecessor Continue does not activate held trial wages")
	expect(new_employees==old_employees and new_fin.cash_cents==old_fin.cash_cents and new_fin.last_cycle==old_fin.last_cycle,"Employee identities, cash and calendar do not change")
	a.erase("studio_finance");b.erase("studio_finance")
	expect(a==b,"Every other original owner field remains exact")
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--input="):input=arg.trim_prefix("--input=")
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
	var raw: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(input));var digest:=Replay.digest(raw)
	var adapter:=StudioCheckpoint.new();var codec:=Codec.new()
	expect(codec.validate(raw.world,raw.player).is_empty(),"Actual preceding world/source/content pair validates: "+codec.error)
	var player:=adapter.hydrate(raw.player)
	expect(player!=null,"Old player hydrates: "+adapter.error)
	if player==null:quit(1);return
	var world:=codec.restore(raw.world,raw.player,player,root.get_node("CardDatabase").get_development_catalog())
	expect(world!=null,"Populated active-rival world cold-restores: "+codec.error)
	if world==null:quit(1);return
	var now: Dictionary=codec.capture(world)
	expect(not now.is_empty(),"Current migrated world serializes with strict provenance")
	compare_player(raw.player,adapter.capture(player),false)
	for i in range(raw.world.studios.size()):compare_player(raw.world.studios[i].run,now.studios[i].run,not raw.world.studios[i].development.is_empty())
	for field in ["cycle","history","market","legacy","market_origin"]:
		expect(raw.world.get(field)==now.get(field),"Existing world field remains exact: "+field)
	var restored:=codec.restore(now,adapter.capture(player),adapter.hydrate(adapter.capture(player)),root.get_node("CardDatabase").get_development_catalog())
	expect(restored!=null and codec.capture(restored)==now,"Repeated cold restoration does not duplicate wage migration or Search grants")
	var bad: Dictionary=raw.world.duplicate(true);bad.source_identity="0".repeat(64)
	expect(not codec.validate(bad,raw.player).is_empty(),"Unknown world sources still reject")
	expect(Replay.digest(raw)==digest,"Actual predecessor evidence is never rewritten")
	if not output.is_empty():FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"pass":failures==0,"checks":checks,"failures":failures,"source":Replay.source_identity(),"old_source":raw.world.source_identity,"player":adapter.capture(player),"world":now},"	"))
	print("COLD_EMPLOYEE_SEARCH_MIGRATION checks=%d failures=%d"%[checks,failures]);quit(failures)
