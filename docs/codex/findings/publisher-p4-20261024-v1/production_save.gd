## Read-only validation of the original safely backed-up latest player slot.
extends SceneTree
func _initialize() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	var path := args[1]+"/checkpoint.126.json"
	var before := FileAccess.get_sha256(path)
	var codec := CheckpointCodec.new()
	var payload := codec.open_envelope(FileAccess.get_file_as_string(path))
	assert(codec.error.is_empty(),codec.error)
	var coordinator := CheckpointCoordinator.new()
	coordinator.rival_catalog = root.get_node("CardDatabase").get_development_catalog()
	var reason := coordinator._validate_payload(payload)
	assert(reason.is_empty(),reason)
	var candidate := coordinator._market_compatible_payload(payload)
	var player := candidate.duplicate(true)
	player.erase("rival_world")
	var run := coordinator.adapter.hydrate(player)
	assert(run != null,coordinator.adapter.error)
	assert(run._support_deals.is_empty() and run._support_rights.is_empty() and run._support_assessments.is_empty())
	var world: RivalWorld
	if candidate.has("rival_world"):
		var world_codec := preload("res://scripts/market/rival_world_checkpoint.gd").new()
		world = world_codec.restore(candidate.rival_world,player,run,coordinator.rival_catalog)
		assert(world != null,world_codec.error)
		for owner: RunState in preload("res://scripts/legacy/legacy_world.gd").runs(world).values():
			assert(owner._support_deals.is_empty() and owner._support_rights.is_empty() and owner._support_assessments.is_empty())
	assert(FileAccess.get_sha256(path) == before)
	FileAccess.open(args[0]+"/production-save-result.json",FileAccess.WRITE).store_string(JSON.stringify({"pass":true,"original_generation":"126","input_sha256":before,"run_cycle":run.get_completed_run_cycles(),"world":world!=null,"support_backfill":false,"scope":"Read-only original latest generation, through production Coordinator/schema/world validators. No writer acquired or bytes changed."},"\t"))
	coordinator.free()
	quit()
