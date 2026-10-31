extends SceneTree
const Codec:=preload("res://scripts/market/rival_world_checkpoint.gd")
const Trial:=preload("res://scripts/market/rival_trial.gd")
const Replay:=preload("res://scripts/simulation/development_replay.gd")
var issues: Array=[]
var world: RivalWorld
func arg(prefix: String) -> String:
	for value in OS.get_cmdline_user_args():
		if value.begins_with(prefix):return value.trim_prefix(prefix)
	return ""
func advance() -> void:
	var report:=world.advance_committed_player_cycle(Trial.policies(world),Trial.ZERO_STEPS)
	if not report.ok:issues.append(report)
func _initialize() -> void:
	await process_frame
	var original: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(arg("--fixture=")));var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog();var adapter:=StudioCheckpoint.new();var player:=adapter.hydrate(original.player);var codec:=Codec.new()
	if original.source_identity!=Replay.source_identity():issues.append("Continuation source mismatch")
	if player==null:issues.append(adapter.error)
	else:world=codec.restore(original.world,original.player,player,catalog)
	if world==null:issues.append(codec.error)
	if issues.is_empty():
		player.calendar_changed.connect(advance)
		if not player.complete_productive_action():issues.append("Actual next cycle rejected")
		if adapter.capture(player)!=original.next_player:issues.append("Cold player finance/history/RNG mismatch")
		if codec.capture(world)!=original.next_world:issues.append("Cold eight-owner policies/actions/finance/history/RNG/Market mismatch")
	var report:={"source":Replay.source_identity(),"issues":issues,"cycle":world.cycle if world!=null else -1};FileAccess.open(arg("--output="),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"));print("QUALITY_NEXT "+JSON.stringify(report));quit(0 if issues.is_empty() else 1)
