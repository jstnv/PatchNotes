extends RefCounted

## One worker owns this Store, detached DTOs and validator until join. No Nodes,
## callbacks into gameplay, shared mutable catalogs or live RNGs are allowed.
const WorldCodec := preload("res://scripts/market/rival_world_checkpoint.gd")
const Validator := preload("res://scripts/persistence/checkpoint_write_validator.gd")
var thread := Thread.new()
var store: StudioCheckpointStore
var player: Dictionary
var world: Dictionary
var catalog: RefCounted
var replacing := false
var revision := 0
var previous_payload: Dictionary = {}
var _validator: RefCounted

func start() -> Error:
	_validator=Validator.new()
	_validator.rival_catalog=catalog
	store.validator=_validator._validate_payload
	return thread.start(_write)

func _write() -> Dictionary:
	var adapter:=StudioCheckpoint.new()
	var payload:=adapter.encode_snapshot(player)
	if payload.is_empty(): return {"status":&"invalid","reason":adapter.error}
	if not world.is_empty():
		var codec:=WorldCodec.new()
		var encoded: Dictionary=codec.encode_snapshot(world)
		if encoded.is_empty(): return {"status":&"invalid","reason":codec.error}
		payload["rival_world"]=encoded
		_validator._publishing_source_identity=encoded.source_identity
	if not replacing and payload==previous_payload:
		return {"status":&"unchanged","payload":payload}
	var result:=store.replace_run(payload) if replacing else store.save(payload)
	if result.status==&"saved": result["payload"]=payload
	return result

func join() -> Dictionary:
	return thread.wait_to_finish()
