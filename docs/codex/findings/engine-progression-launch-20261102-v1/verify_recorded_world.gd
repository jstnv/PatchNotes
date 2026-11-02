extends SceneTree
const Campaign=preload("res://scripts/simulation/campaign_session.gd")
const Trial=preload("res://scripts/market/rival_trial.gd")
const WorldCodec=preload("res://scripts/market/rival_world_checkpoint.gd")
var checks:=0
var failures:=0
var ticks:=0
func check(ok:bool,label:String)->bool:
	checks+=1;print("PASS: " if ok else "FAIL: ",label)
	if not ok:failures+=1
	return ok
func _initialize()->void:go.call_deferred()
func integers(value:Variant)->Variant:
	if value is float and value==floor(value):return int(value)
	if value is Array:
		var result:Array=[]
		for item in value:result.append(integers(item))
		return result
	if value is Dictionary:
		var result:Dictionary={}
		for key in value:
			result[key]=StringName(value[key]) if key in ["engine_id","feature_id","entry_id","branch","node_id"] and value[key] is String else integers(value[key])
		return result
	return value
func go()->void:
	await process_frame
	var input:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_CONTRACT_FIXTURE")))
	var adapter:=StudioCheckpoint.new()
	var initial:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(input.initial))
	var run:=adapter.hydrate(initial)
	if not check(run!=null and run.get_completed_run_cycles()==0 and run.get_released_game_ids().is_empty(),"Recorded fresh Studio before any games"):quit(1);return
	var id:StringName=run.get_proprietary_engine_state().engines.keys()[0]
	check(run.get_engine_feature_state().engines[id].capacity==25 and run.get_proprietary_engine_row(id).branch_progress.is_empty() and run.get_proprietary_engine_row(id).challenge_progress.is_empty(),"Recorded25-Scope engine has no injected progression")
	var creation_receipts:Array=run._studio_finance.actions.filter(func(row:Dictionary)->bool:return row.source_id==run.get_proprietary_engine_row(id).receipt_id)
	check(creation_receipts.size()==1 and creation_receipts[0].direct_delta==-10000,"Exact real100-dollar creation receipt retained")
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	var world:=Trial.create_world(run,catalog)
	if not check(world!=null and world.studios.size()==8,"Actual canonical eight-rival world"):quit(1);return
	run.calendar_changed.connect(func():
		var tick:Dictionary=world.advance_committed_player_cycle(Trial.policies(world),Trial.ZERO_STEPS)
		if tick.ok:ticks+=1
		check(tick.ok,"Every productive player cycle commits all rivals"))
	var snapshots:=PrimitiveSnapshotDatabase.new();snapshots.load_ledgers()
	var session:=Campaign.new();check(session.initialize(run,catalog,snapshots),"Canonical campaign initialized")
	var records:Array=integers(JSON.parse_string(FileAccess.get_file_as_string(input.trace)))
	var consumed:=0;var purchases:=0
	for row:Dictionary in records:
		if not row.get("ok",true):continue
		var result:Dictionary
		if row.kind=="purchase_engine_skill":result=run.purchase_engine_skill(row.quote);purchases+=1
		else:result=session.execute(session.command(StringName(row.kind),row.payload))
		if not check(result.get("ok",false),"Recorded legal command "+str(consumed)+" "+row.kind+": "+str(result.get("error",""))):break
		consumed+=1
		if not check(run.get_cash_cents()==int(row.cash) and run.get_completed_run_cycles()==int(row.cycle),"Recorded exact cash/cycle boundary"):break
		if run.get_engine_feature_state().engines[id].capacity==35:break
	check(run.get_engine_feature_state().engines[id].capacity==35 and purchases==8 and session.in_studio,"Normal recorded gameplay reaches35 Scope through eight paid nodes at Studio")
	check(ticks==run.get_completed_run_cycles() and ticks==world.cycle,"Eight rivals advance for the entire recorded career")
	var saved:=adapter.capture(run);var codec:=WorldCodec.new();var world_saved:=codec.capture(world)
	check(not saved.is_empty() and not world_saved.is_empty(),"Full progressed player/world captures at Studio-only boundary")
	var loaded:=adapter.hydrate(saved);var cold:=codec.restore(world_saved,saved,loaded,catalog)
	check(cold!=null and adapter.capture(loaded)==saved and codec.capture(cold)==world_saved,"Exact current cold Continue retains all actors, nodes, Scope, finance, history and RNG")
	var out:=OS.get_environment("PN_CONTRACT_REPORT").get_base_dir()
	FileAccess.open(out.path_join("final-world-pair.json"),FileAccess.WRITE).store_string(JSON.stringify({"player":saved,"world":world_saved}))
	FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"world_studios":world.studios.size(),"rival_ticks":ticks,"cycle":run.get_completed_run_cycles(),"cash":run.get_cash_cents(),"nodes_purchased":purchases,"commands_replayed":consumed}))
	quit(1 if failures else 0)
