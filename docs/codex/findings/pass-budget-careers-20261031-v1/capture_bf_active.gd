extends SceneTree
func _initialize() -> void:
	await process_frame
	var source:=preload("res://scripts/simulation/development_replay.gd").source_identity()
	assert(source=="bf3dffde495d7149a9556091c4434c06af9db8b7c16ac27b6415378c0590b4f3")
	var input: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	var p: Dictionary=input.duplicate(true);p.erase("rival_world")
	var adapter:=StudioCheckpoint.new();var run:=adapter.hydrate(p)
	assert(run!=null)
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var codec:=preload("res://scripts/market/rival_world_checkpoint.gd").new()
	var world: RivalWorld=codec.restore(input.rival_world,p,run,catalog)
	assert(world!=null and run.complete_productive_action())
	var result:=world.advance_committed_player_cycle(preload("res://scripts/market/rival_trial.gd").policies(world),64)
	assert(result.ok)
	var w: Dictionary=codec.capture(world);assert(w.source_identity==source)
	assert(w.studios.any(func(row):return row.development!=null))
	FileAccess.open(OS.get_cmdline_user_args()[1],FileAccess.WRITE).store_string(JSON.stringify({"player":adapter.capture(run),"world":w},"\t"))
	print("GENUINE_BF_ACTIVE ",source);quit()
