extends SceneTree
func _initialize() -> void:
	await process_frame
	var pair: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_CONTRACT_FIXTURE")))
	var adapter:=StudioCheckpoint.new()
	var codec=load("res://scripts/market/rival_world_checkpoint.gd").new()
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	var run:=adapter.hydrate(pair.player)
	var world=codec.restore(pair.world,pair.player,run,catalog)
	assert(world!=null,codec.error)
	var report: Array=[]
	for i in 2:
		var row: Dictionary={}
		var start:=Time.get_ticks_msec()
		var player:=adapter.snapshot(run)
		var native: Dictionary=codec.snapshot(world,adapter)
		row.snapshot=Time.get_ticks_msec()-start
		start=Time.get_ticks_msec()
		var payload:=adapter.encode_snapshot(player)
		row.player_encode=Time.get_ticks_msec()-start
		start=Time.get_ticks_msec()
		payload["rival_world"]=codec.encode_snapshot(native)
		row.world_encode=Time.get_ticks_msec()-start
		var validator=load("res://scripts/persistence/checkpoint_write_validator.gd").new()
		validator.rival_catalog=catalog;validator._publishing_source_identity=payload.rival_world.source_identity
		start=Time.get_ticks_msec()
		assert(validator._validate_payload(payload).is_empty())
		row.validate=Time.get_ticks_msec()-start
		start=Time.get_ticks_msec()
		var c:=CheckpointCodec.new();var text:=c.envelope(payload)
		row.envelope=Time.get_ticks_msec()-start
		start=Time.get_ticks_msec()
		var nodes:=StudioCheckpointStore._wire_nodes(payload)
		row.wire_nodes=Time.get_ticks_msec()-start
		start=Time.get_ticks_msec()
		var ordered: Dictionary=StudioCheckpointStore._wire_copy(payload)
		row.wire_copy=Time.get_ticks_msec()-start
		start=Time.get_ticks_msec()
		assert(nodes>0 and StudioCheckpointStore._same_typed_payload(ordered,payload))
		row.same_type=Time.get_ticks_msec()-start
		start=Time.get_ticks_msec()
		c.open_envelope(text)
		row.strict_parse=Time.get_ticks_msec()-start
		report.append(row)
		world.advance_awards_stage()
	print("AWARDS_PIPELINE ",report)
	FileAccess.open(OS.get_environment("PN_CONTRACT_REPORT"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	quit()
