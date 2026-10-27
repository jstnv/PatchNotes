extends SceneTree
func _initialize()->void:
	await process_frame
	var adapter:=StudioCheckpoint.new()
	var payload:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_EXPORT_INPUT")))
	var store:=StudioCheckpointStore.new("user://saves/studio",adapter.validate)
	var result:=store.save(payload)
	print("SEED_EXPORT ",result)
	store.release_writer()
	quit(0 if result.status==&"saved" else 1)
