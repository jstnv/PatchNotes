## One worker-owned strict inspection and hydration. Read-only; caller holds
## the writer lease and attaches a complete result on the main thread only.
extends RefCounted
class ReadValidator extends "res://scripts/persistence/checkpoint_write_validator.gd":
	var accepted_bytes:=PackedByteArray()
	var candidate: Dictionary
	var player_payload: Dictionary
	var player: RunState
	var world: RivalWorld
	func _validate_payload(payload: Dictionary) -> String:
		var next:=_market_compatible_payload(payload)
		if next.is_empty():return "Invalid pre-market migration payload"
		var p: Dictionary=next.duplicate(true);p.erase("rival_world")
		var r: RunState=adapter.hydrate(p)
		if r==null:return adapter.error
		var w: RivalWorld
		if next.has("rival_world"):
			if not next.rival_world is Dictionary or rival_catalog==null:return "Rival definitions unavailable for validation"
			var codec:=preload("res://scripts/market/rival_world_checkpoint.gd").new()
			w=codec.restore(next.rival_world,p,r,rival_catalog)
			if w==null:return codec.error
		accepted_bytes=var_to_bytes(payload);candidate=next;player_payload=p;player=r;world=w
		return ""
var directory: String
var catalog: RefCounted
var inspected: Dictionary={}
var candidate: Dictionary={}
var player_payload: Dictionary={}
var player: RunState
var world: RivalWorld
var error:=""
var _task:=-1
func start(path: String,definitions: RefCounted) -> void:
	directory=path;catalog=preload("res://scripts/market/rival_opening_loader.gd").copy_catalog(definitions)
	_task=WorkerThreadPool.add_task(_read.bind(self),false,"Inspect saved Studio")
func poll() -> bool:
	if _task==-2:return true
	if _task<0:error="Read worker did not start";return true
	if not WorkerThreadPool.is_task_completed(_task):return false
	WorkerThreadPool.wait_for_task_completion(_task);_task=-2;return true
func _read(_lifetime: RefCounted) -> void:
	var validator:=ReadValidator.new();validator.rival_catalog=catalog
	var store:=StudioCheckpointStore.new(directory,validator._validate_payload)
	inspected=store.inspect()
	if inspected.status!=&"valid":error=str(inspected.get("reason",inspected.status));return
	if var_to_bytes(inspected.payload)!=validator.accepted_bytes:error="Validated read payload changed";return
	candidate=validator.candidate;player_payload=validator.player_payload;player=validator.player;world=validator.world
