extends SceneTree
func _initialize() -> void:
	await process_frame
	var pair: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_AWARDS_UI_FIXTURE")))
	var adapter:=StudioCheckpoint.new()
	var codec=load("res://scripts/market/rival_world_checkpoint.gd").new()
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	var run:=adapter.hydrate(pair.player)
	var world=codec.restore(pair.world,pair.player,run,catalog)
	assert(world!=null,codec.error)
	var payload:=adapter.capture(run)
	payload["rival_world"]=codec.capture(world)
	var store:=StudioCheckpointStore.new("user://wire-regression")
	var nodes:=store._wire_nodes(payload)
	var ok:=nodes>0
	if not ok:push_error("Actual writer DTO must fit the unchanged strict wire-proof subset")
	if ok:
		var copy=store._wire_copy(payload)
		var source:=CheckpointCodec.new().envelope(payload)
		var parsed:=CheckpointCodec.new().open_envelope(source)
		ok=store._same_typed_payload(copy,parsed) and store._same_typed_payload(payload,parsed)
		if not ok:push_error("Producer, trusted parse proof and actual strict parser have identical types and values")
	print("AWARDS_WIRE nodes=%d pass=%s source=%s"%[nodes,ok,payload.rival_world.source_identity])
	quit(0 if ok else 1)
