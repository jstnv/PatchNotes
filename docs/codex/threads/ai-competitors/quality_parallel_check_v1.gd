extends SceneTree
const Replay:=preload("res://scripts/simulation/development_replay.gd")
const Codec:=preload("res://scripts/market/rival_world_checkpoint.gd")
const Trial:=preload("res://scripts/market/rival_trial.gd")
var issues: Array=[]
var checks:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:issues.append(label);push_error(label)
func arg(prefix: String) -> String:
	for v in OS.get_cmdline_user_args():
		if v.begins_with(prefix):return v.trim_prefix(prefix)
	return ""
func _initialize() -> void:
	await process_frame
	var certificate: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://certified/rival-opening-5607-v1.json"))
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var adapter:=StudioCheckpoint.new();var worlds: Array[RivalWorld]=[]
	for i in range(2):
		var p: Dictionary=certificate.fixture.player;var player:=adapter.hydrate(p)
		var codec:=Codec.new();var world:=codec.restore(certificate.fixture.world,p,player,catalog,"0d8e6b57ddaa3c2a71c05af7ba92a4a4495cad5da80c7dad38b4b038f991fc99")
		check(world!=null,"Independent trusted v12 opening imports")
		if world==null:finish([]);return
		check(player.add_cash(10000000),"Explicit player-only CPU solvency funds")
		world.parallel_careers=i==1;worlds.append(world)
	var ids: Array=worlds[1].studios.keys()
	check(worlds[1]._parallel_safe(ids,Trial.policies(worlds[1])),"Exact detached careers qualify for scheduler")
	var timings: Array=[]
	for cycle in range(20):
		var results: Array=[];var us: Array=[]
		for world: RivalWorld in worlds:
			check(world.player.complete_productive_action(),"Real player calendar commits")
			var start:=Time.get_ticks_usec();var report:=world.advance_committed_player_cycle(Trial.policies(world),Trial.ZERO_STEPS);us.append(Time.get_ticks_usec()-start);results.append(report)
			check(report.ok,"Ordinary owner actions and settlement")
		check(var_to_bytes(results[0])==var_to_bytes(results[1]),"Ordered events/results/RNG match cycle"+str(cycle))
		check(var_to_bytes(Codec.new().snapshot(worlds[0]))==var_to_bytes(Codec.new().snapshot(worlds[1])),"All actor state/finance/history/policy/Market match cycle"+str(cycle))
		check(var_to_bytes(adapter.snapshot(worlds[0].player))==var_to_bytes(adapter.snapshot(worlds[1].player)),"Player state/RNG exact cycle"+str(cycle))
		timings.append({"cycle":cycle+1,"serial_us":us[0],"parallel_us":us[1]});print("PARALLEL_TICK "+JSON.stringify(timings[-1]))
		if not issues.is_empty():break
	finish(timings)
func finish(timings: Array) -> void:
	var report:={"source":Replay.source_identity(),"checks":checks,"issues":issues,"timings":timings};FileAccess.open(arg("--output="),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("QUALITY_PARALLEL "+JSON.stringify(report));quit(0 if issues.is_empty() else 1)
