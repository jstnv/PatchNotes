extends SceneTree
func _initialize() -> void: execute.call_deferred()
func execute() -> void:
	var run := RunState.new()
	run.initialize_cash(0)
	if not run.create_studio_with_traits("Retained P1 Studio",&"sports",[&"graduate"]): quit(2); return
	var catalog: RefCounted = root.get_node("CardDatabase").get_development_catalog()
	var world: RivalWorld = preload("res://scripts/market/rival_trial.gd").create_world(run,catalog)
	var player := StudioCheckpoint.new().capture(run)
	var codec := preload("res://scripts/market/rival_world_checkpoint.gd").new()
	var rivals := codec.capture(world)
	if player.is_empty() or rivals.is_empty() or not codec.validate(rivals,player).is_empty(): quit(2);return
	var record := {"source":preload("res://scripts/simulation/development_replay.gd").source_identity(),"revision":StudioCheckpoint.new().revision(),"player":player,"world":rivals}
	FileAccess.open(OS.get_cmdline_user_args()[0],FileAccess.WRITE).store_string(JSON.stringify(record,"\t"))
	print("P1_FIXTURE_WRITTEN ",record.source)
	quit(0)
