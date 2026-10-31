extends SceneTree
const Codec=preload("res://scripts/market/rival_world_checkpoint.gd")
const Replay=preload("res://scripts/simulation/development_replay.gd")
const Info=preload("res://scripts/ui/studio_rival_info.gd")
const Trial=preload("res://scripts/market/rival_trial.gd")
var failures: Array=[]
var checks:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func _initialize() -> void:
	await process_frame
	var original: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("C:/Users/64jus/OneDrive/Documents/GitHub/PatchNotes/sims/quality-canonical-native96-20261030-v1/report.json"))
	var adapter:=StudioCheckpoint.new();var player:=adapter.hydrate(original.player);var codec:=Codec.new()
	check(player!=null,"Genuine prior late player checkpoint hydrates: "+adapter.error)
	if player!=null:
		var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
		var world:=codec.restore(original.world,original.player,player,catalog)
		check(world!=null,"Genuine prior late world checkpoint hydrates: "+codec.error)
		if world!=null:
			check(adapter.capture(player)==original.player,"Late player finance/history/RNG stay exact")
			var expected: Dictionary=original.world.duplicate(true);expected.source_identity=Replay.source_identity()
			check(codec.capture(world)==expected,"Late world stays exact except current code source header")
			var before: Variant=Replay.freeze([adapter.capture(player),codec.capture(world)])
			var rows:=Info.rows(world);var total:=0
			for row: Dictionary in rows:
				var games: Array=world.live_releases.values().filter(func(game):return game.studio_id==row.id)
				check(row.games.size()==games.size() and row.fans==world.studios[row.id].run.get_fans() and row.cash_cents==world.studios[row.id].run.get_cash_cents(),"Rival Info reflects actual late live releases, Fans and cash")
				total+=row.games.size()
			check(total==world.live_releases.size() and total>0,"All real post-start Market releases appear once")
			check(before==Replay.freeze([adapter.capture(player),codec.capture(world)]),"Rival Info projection is read-only")
	var output:=OS.get_cmdline_user_args()[0].trim_prefix("--output=")
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"source":Replay.source_identity()}))
	print("LATE_STUDIO_INFO ",checks," ",failures);quit(0 if failures.is_empty() else 1)
