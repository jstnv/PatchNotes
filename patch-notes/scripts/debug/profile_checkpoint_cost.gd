extends SceneTree
const Replay := preload("res://scripts/simulation/development_replay.gd")
func _initialize() -> void:
	await process_frame
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../docs/codex/findings/campaign-latency-20261025-v1/actions-after-v1.result.json"))
	var adapter:=StudioCheckpoint.new()
	var codec: RefCounted=load("res://scripts/market/rival_world_checkpoint.gd").new()
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	var player:=adapter.hydrate(data.player)
	assert(player!=null,adapter.error)
	var operations: Dictionary={"source_identity":func():return Replay.source_identity(),
		"rules_hash":func():return adapter._rules_revision(StudioCheckpoint.RULES),
		"decode_player":func():return adapter._decode_payload(data.player),
		"validate_player":func():return adapter.validate(data.player),
		"hydrate_player":func():return adapter.hydrate(data.player),
		"read_world":func():return codec._read(data.world,data.player),
		"restore_world":func():return codec.restore(data.world,data.player,player,catalog)}
	var times: Dictionary={}
	for key: String in operations:
		var start:=Time.get_ticks_usec()
		operations[key].call()
		times[key]=(Time.get_ticks_usec()-start)/1000.0
	assert(codec.error.is_empty(),codec.error)
	print(JSON.stringify(times))
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(times))
	quit()
