extends SceneTree
const Codec:=preload("res://scripts/market/rival_world_checkpoint.gd")
const Replay:=preload("res://scripts/simulation/development_replay.gd")
var failures: Array=[]
var checks:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func _initialize() -> void:
	await process_frame
	var args:=OS.get_cmdline_user_args();var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]));var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var adapter:=StudioCheckpoint.new();var player:=adapter.hydrate(source.player)
	check(player!=null,"previous player hydrates: "+adapter.error)
	if player==null:quit(1);return
	var codec:=Codec.new();var world:=codec.restore(source.world,source.player,player,catalog)
	check(world!=null,"previous world hydrates: "+codec.error)
	if world==null:quit(1);return
	var p:=adapter.capture(player)
	for field in source.player.run:check(p.run[field]==source.player.run[field],"preserved player field "+str(field))
	check(player._calendar_start_year==1980 and player._rival_founder_profile.is_empty() and player._historical_close_cycle==-1 and player._closed_historical_ids.is_empty(),"new calendar/closure defaults only")
	var saved:=codec.capture(world)
	check(not saved.is_empty(),"migrated world saves: "+codec.error)
	for old: Dictionary in source.world.studios:
		var id:=StringName(old.id);var run: RunState=world.studios[id].run
		check(run._rival_founder_profile.is_empty() and run._calendar_start_year==1980,"old rival remains legacy")
		var fresh: Dictionary={}
		for row: Dictionary in saved.studios:
			if row.id==old.id:fresh=row
		for field in old.run.run:check(fresh.run.run[field]==old.run.run[field],"preserved rival field "+str(field))
		check(fresh.development==old.development and fresh.archive==old.archive,"active work/archive exact")
	check(saved.market==source.world.market and saved.history==source.world.history,"old Market/history exact")
	var bad: Dictionary=source.world.duplicate(true);bad.source_identity="unknown";check(codec.restore(bad,source.player,player,catalog)==null,"unknown world rejects")
	var result:={"checks":checks,"failures":failures,"source":Replay.source_identity(),"old_source":source.world.source_identity,"saved":saved,"player":p}
	FileAccess.open(args[1],FileAccess.WRITE).store_string(JSON.stringify(result,"\t"));print("QUALITY_LEGACY "+JSON.stringify({"checks":checks,"failures":failures}));quit(0 if failures.is_empty() else 1)
