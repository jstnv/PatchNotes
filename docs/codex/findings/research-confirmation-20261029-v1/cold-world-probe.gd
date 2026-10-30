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
	if input.has("rival_world"):
		var player:=input.duplicate(true);player.erase("rival_world")
		source={"player":player,"world":input.rival_world}
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
	for index in before.studios.size():
		if not before.studios[index].run.run.has("store_era_receipts"): after.studios[index].run.run.erase("store_era_receipts")
	check(JSON.parse_string(JSON.stringify(before))==JSON.parse_string(JSON.stringify(after)),"Every persisted rival action, finance, RNG, archive and ownership field survives")
	var player_saved := StudioCheckpoint.new().capture(run)
	var prior: Dictionary=source.player.duplicate(true);prior.sequence="1";prior.content_revision=StudioCheckpoint.new().revision()
	var player_projection:=player_saved.duplicate(true)
	if not prior.run.has("store_era_receipts"): player_projection.run.erase("store_era_receipts")
	check(JSON.stringify(prior)==JSON.stringify(player_projection),"Every persisted player field survives")
	var corrupted := saved.duplicate(true);corrupted.source_identity="unverified-source"
	check(not codec.validate(corrupted,player_saved).is_empty(),"Unverified source still rejects")
	if source.world.source_identity in WorldCodec.QUIT_PRESENTATION_PREDECESSORS+WorldCodec.STORE_NAVIGATION_PREDECESSORS+WorldCodec.GRID_PREDECESSOR_SOURCES+WorldCodec.AUDIO_PREDECESSOR_SOURCES+WorldCodec.TECH_ROW_PRESENTATION_PREDECESSORS+WorldCodec.GAMEPLAY_RESTORATION_PREDECESSORS+WorldCodec.RESEARCH_CONFIRMATION_PREDECESSORS:
		var wrong_pair: Dictionary = source.player.duplicate(true)
		wrong_pair.content_revision = StudioCheckpoint.new()._rules_revision(StudioCheckpoint.PRE_ERA_RULES)
		check(not codec.validate(source.world,wrong_pair).is_empty(),"Presentation predecessor cannot pair with older Studio rules")
		var wrong_rival: Dictionary = source.world.duplicate(true)
		wrong_rival.studios[0].run.content_revision = wrong_pair.content_revision
		check(not codec.validate(wrong_rival,source.player).is_empty(),"Presentation predecessor cannot pair with older rival rules")
	if source.world.source_identity in WorldCodec.RESEARCH_CONFIRMATION_PREDECESSORS:
		var wrong_pair: Dictionary = source.player.duplicate(true)
		wrong_pair.content_revision = StudioCheckpoint.new().pre_gameplay_revision()
		check(not codec.validate(source.world,wrong_pair).is_empty(),"Research presentation predecessor rejects pre-Gameplay player catalog")
		var wrong_rival: Dictionary = source.world.duplicate(true)
		wrong_rival.studios[0].run.content_revision = wrong_pair.content_revision
		check(not codec.validate(wrong_rival,source.player).is_empty(),"Research presentation predecessor rejects pre-Gameplay rival catalog")
	if source.world.source_identity in WorldCodec.GRID_PREDECESSOR_SOURCES+WorldCodec.RESEARCH_PERFORMANCE_PREDECESSORS+WorldCodec.QUIT_PRESENTATION_PREDECESSORS+WorldCodec.STORE_NAVIGATION_PREDECESSORS:
		var wrong_current: Dictionary=source.player.duplicate(true)
		wrong_current.content_revision=StudioCheckpoint.new().revision()
		check(not codec.validate(source.world,wrong_current).is_empty(),"Pre-grid world cannot pair with current-catalog player bytes")
	if source.world.source_identity in WorldCodec.STORE_ROOT_PRESENTATION_PREDECESSORS:
		var wrong_pair: Dictionary=source.player.duplicate(true)
		wrong_pair.content_revision=StudioCheckpoint.new().pre_grid_revision()
		check(not codec.validate(source.world,wrong_pair).is_empty(),"Root presentation predecessor rejects older player catalog")
		var wrong_rival: Dictionary=source.world.duplicate(true)
		wrong_rival.studios[0].run.content_revision=wrong_pair.content_revision
		check(not codec.validate(wrong_rival,source.player).is_empty(),"Root presentation predecessor rejects older rival catalog")
	var output := {"player":player_saved,"world":saved,"digest":Replay.digest(saved)}
	FileAccess.open(args[1],FileAccess.WRITE).store_string(JSON.stringify(output,"\t"))
	print("Fresh world restore: %d failures"%failures);quit(failures)
