extends SceneTree

func _initialize() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	if args.size()!=2: quit(2);return
	var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var codec:=preload("res://scripts/market/rival_world_checkpoint.gd").new()
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var world: RivalWorld=codec.restore(source.world,source.player,StudioCheckpoint.new().hydrate(source.player),catalog)
	if world==null: push_error(codec.error);quit(1);return
	var player:=StudioCheckpoint.new().capture(world.player)
	var current:=codec.capture(world)
	var expected: Dictionary=source.world.duplicate(true)
	expected.source_identity=current.source_identity
	if expected!=current or player!=source.player:
		push_error("Actual campaign save changed during restoration");quit(1);return
	var coordinator:=CheckpointCoordinator.new()
	coordinator.rival_catalog=catalog
	root.add_child(coordinator)
	player.rival_world=current
	var result:=coordinator.store.save(player)
	var saved:=coordinator.store.inspect()
	if result.status!=&"saved" or saved.status!=&"valid": push_error(str(result));quit(1);return
	FileAccess.open(args[1],FileAccess.WRITE).store_string(JSON.stringify({"result":result,"input_sha256":FileAccess.get_sha256(args[0]),"saved_sha256":FileAccess.get_sha256(str(result.path)),"player_cycle":world.player.get_completed_run_cycles(),"market_rows":preload("res://queries/market_release_index.gd").query(world).rows.size()},"\t"))
	coordinator.free()
	print("ACTUAL_CAMPAIGN_NATIVE_SAVE PASS: cycle ",world.cycle)
	quit(0)
