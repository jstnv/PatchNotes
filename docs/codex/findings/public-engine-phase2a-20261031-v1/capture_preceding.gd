extends SceneTree
func _initialize() -> void:
	await process_frame
	var source=preload("res://scripts/simulation/development_replay.gd").source_identity()
	assert(source=="46036810d92d20c22d3e08f554de308c1352673ce8d525764b007a0288370d33",source)
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	var s=preload("res://scripts/simulation/run_factory.gd").create_fresh_session({"schema_version":1,"studio_id":"previous_engine_menu","studio_name":"Previous build","specialty":"action","traits":[],"seed":"4417"},catalog)
	var w=preload("res://scripts/market/rival_trial.gd").create_world(s.run,catalog);assert(w!=null)
	var adapter=StudioCheckpoint.new();var player=adapter.capture(s.run);assert(not player.is_empty(),adapter.error)
	var codec=preload("res://scripts/market/rival_world_checkpoint.gd").new();var world=codec.capture(w);assert(not world.is_empty(),codec.error)
	FileAccess.open(OS.get_cmdline_user_args()[0].trim_prefix("--output="),FileAccess.WRITE).store_string(JSON.stringify({"player":player,"world":world}));quit(0)
