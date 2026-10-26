extends SceneTree
const WorldCodec := preload("res://scripts/market/rival_world_checkpoint.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
var failures := 0
func check(value: bool,label: String) -> void:
	if value: print("PASS: ",label)
	else: failures+=1;push_error("FAIL: "+label)
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size()!=2: quit(2);return
	var input: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var source: Dictionary=input
	if input.has("payload_utf8"):
		var raw := CheckpointCodec.new().open_envelope(JSON.stringify(input))
		var player := raw.duplicate(true);player.erase("rival_world")
		source={"player":player,"world":raw.rival_world}
	var run := StudioCheckpoint.new().hydrate(source.player)
	check(run!=null,"Player schema restores exact finance, traits and RNG")
	if run==null: quit(1);return
	var codec := WorldCodec.new()
	var world := codec.restore(source.world,source.player,run,root.get_node("CardDatabase").get_development_catalog())
	check(world!=null,"World restores from unmodified file "+codec.error)
	if world==null: quit(1);return
	var saved := codec.capture(world)
	var before: Dictionary=source.world.duplicate(true);before.erase("source_identity")
	for row: Dictionary in before.studios: row.run.content_revision=StudioCheckpoint.new().revision()
	var after: Dictionary=saved.duplicate(true);after.erase("source_identity")
	check(JSON.parse_string(JSON.stringify(before))==JSON.parse_string(JSON.stringify(after)),"Every persisted rival action, finance, RNG, archive and ownership field survives")
	var player_saved := StudioCheckpoint.new().capture(run)
	var prior: Dictionary=source.player.duplicate(true);prior.sequence="1";prior.content_revision=StudioCheckpoint.new().revision()
	check(JSON.stringify(prior)==JSON.stringify(player_saved),"Every persisted player field survives")
	var corrupted := saved.duplicate(true);corrupted.source_identity="unverified-source"
	check(not codec.validate(corrupted,player_saved).is_empty(),"Unverified source still rejects")
	var output := {"player":player_saved,"world":saved,"digest":Replay.digest(saved)}
	FileAccess.open(args[1],FileAccess.WRITE).store_string(JSON.stringify(output,"\t"))
	print("Fresh world restore: %d failures"%failures);quit(failures)
