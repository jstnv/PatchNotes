extends SceneTree
const Replay:=preload("res://scripts/simulation/development_replay.gd")
class Measured extends "res://scripts/market/rival_world_checkpoint.gd":
	var times: Dictionary={}
	func _read(payload: Dictionary,player: Dictionary,identity: String="") -> Dictionary:
		var t:=Time.get_ticks_usec();var v:=super._read(payload,player,identity);times.read=Time.get_ticks_usec()-t;return v
	func _validate_projected_archive(adapter: StudioCheckpoint,run: Dictionary,archive: Array,dev: Dictionary,offset: int) -> bool:
		var t:=Time.get_ticks_usec();var v:=super._validate_projected_archive(adapter,run,archive,dev,offset);times.archive=int(times.get("archive",0))+Time.get_ticks_usec()-t;return v
	func _validate_frozen_market(player: Dictionary,encoded: Array,decoded: Array,cycle: int,origin: Dictionary) -> bool:
		var t:=Time.get_ticks_usec();var v:=super._validate_frozen_market(player,encoded,decoded,cycle,origin);times.frozen=Time.get_ticks_usec()-t;return v
	func _book_matches_owners(market: Dictionary,rows: Array) -> bool:
		var t:=Time.get_ticks_usec();var v:=super._book_matches_owners(market,rows);times.book=Time.get_ticks_usec()-t;return v
	func _check_history_and_legacy(world: RivalWorld,history: Array) -> bool:
		var t:=Time.get_ticks_usec();var v:=super._check_history_and_legacy(world,history);times.history=int(times.get("history",0))+Time.get_ticks_usec()-t;return v
func arg(prefix: String) -> String:
	for value in OS.get_cmdline_user_args():
		if value.begins_with(prefix):return value.trim_prefix(prefix)
	return ""
func _initialize() -> void:
	await process_frame
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(arg("--fixture=")))
	var p: Dictionary=data.get("player",data.get("fixture",{}).get("player",{}));var w: Dictionary=data.get("world",data.get("fixture",{}).get("world",{}));var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog();var adapter:=StudioCheckpoint.new();var t:=Time.get_ticks_usec();var player:=adapter.hydrate(p);var player_us:=Time.get_ticks_usec()-t;var codec:=Measured.new();t=Time.get_ticks_usec();var world:=codec.restore(w,p,player,catalog)
	var report:={"source":Replay.source_identity(),"player_us":player_us,"restore_us":Time.get_ticks_usec()-t,"parts_us":codec.times,"ok":world!=null,"error":codec.error,"cycle":world.cycle if world!=null else -1};FileAccess.open(arg("--output="),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("RESTORE_PROFILE "+JSON.stringify(report));quit(0 if world!=null else 1)
