extends SceneTree
func _initialize() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	var payload: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[1]+"/pre-support.json"))
	var adapter := StudioCheckpoint.new()
	assert(adapter.validate(payload).is_empty(),adapter.error)
	var store := StudioCheckpointStore.new(args[0]+"/seed",adapter.validate)
	var result := store.save(payload)
	assert(result.status == &"saved",str(result))
	assert(FileAccess.get_file_as_string(result.path).length() > 0)
	store.release_writer()
	FileAccess.open(args[0]+"/seed-result.json",FileAccess.WRITE).store_string(JSON.stringify({"path":result.path,"sha256":FileAccess.get_sha256(result.path),"source":preload("res://scripts/simulation/development_replay.gd").source_identity(),"scope":"Unmodified legal compiled pre-support payload; only Store allocates generation sequence."},"\t"))
	quit()
