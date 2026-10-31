extends SceneTree
func _initialize() -> void:
	await process_frame
	var source=preload("res://scripts/simulation/development_replay.gd").source_identity()
	assert(source=="d7295bdcea8bd5093115b42ddba4913f4d7125ff6f697bf5945dc8c62fca0e09",source)
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	var s=preload("res://scripts/simulation/run_factory.gd").create_fresh_session({"schema_version":1,"studio_id":"previous_engine_menu","studio_name":"Previous build","specialty":"action","traits":[],"seed":"4417"},catalog)
	var w=preload("res://scripts/market/rival_trial.gd").create_world(s.run,catalog);assert(w!=null)
	var adapter=StudioCheckpoint.new();var player=adapter.capture(s.run);assert(not player.is_empty(),adapter.error)
	var codec=preload("res://scripts/market/rival_world_checkpoint.gd").new();var world=codec.capture(w);assert(not world.is_empty(),codec.error)
	FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"player":player,"world":world}));quit(0)
