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
		if preload("res://scripts/awards/award_receipts.gd").missing_world(next):return "Awarded Studio requires its global annual ledger"
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
## Retained only between a completed title read and the subsequent Continue.
var cache_store: StudioCheckpointStore
var verified_source: Dictionary={}
var verified_payload: PackedByteArray=[]
var verified_catalog: PackedByteArray=[]
var verified_identity: String=""
func start(path: String,definitions: RefCounted, prior_cache: StudioCheckpointStore = null) -> void:
	directory=path;catalog=preload("res://scripts/market/rival_opening_loader.gd").copy_catalog(definitions)
	cache_store=null
	if prior_cache!=null and prior_cache.get_script()==preload("res://scripts/persistence/studio_checkpoint_store.gd") and prior_cache.directory==ProjectSettings.globalize_path(path).simplify_path():
		cache_store=prior_cache
	_task=WorkerThreadPool.add_task(_read.bind(self),false,"Inspect saved Studio")
func poll() -> bool:
	if _task==-2:return true
	if _task<0:error="Read worker did not start";return true
	if not WorkerThreadPool.is_task_completed(_task):return false
	WorkerThreadPool.wait_for_task_completion(_task);_task=-2;return true
func _read(_lifetime: RefCounted) -> void:
	var validator:=ReadValidator.new();validator.rival_catalog=catalog
	var store:=cache_store
	if store==null:store=StudioCheckpointStore.new(directory,validator._validate_payload)
	else:store.validator=validator._validate_payload
	store.capture_verified_source=true
	inspected=store.inspect()
	store.validator=Callable()
	if inspected.status!=&"valid":cache_store=null;error=str(inspected.get("reason",inspected.status));return
	if var_to_bytes(inspected.payload)!=validator.accepted_bytes:cache_store=null;error="Validated read payload changed";return
	cache_store=store
	verified_source=store._last_verified_source.duplicate()
	verified_payload=validator.accepted_bytes
	verified_catalog=validator._catalog_content()
	verified_identity=preload("res://scripts/simulation/development_replay.gd").source_identity()
	candidate=validator.candidate;player_payload=validator.player_payload;player=validator.player;world=validator.world

## The title owns this detached result exclusively. A writer lease must be held
## by the caller. Any changed generation, exact bytes, catalog or code falls
## back to the ordinary strict read and hydration.
func matches_current_generation(store: StudioCheckpointStore,definitions: RefCounted) -> bool:
	if store==null or store._writer==null:return false
	return _matches_directory(store.directory,definitions)

## Only a caller that already owns the lease may start this detached check.
func _matches_directory(path: String,definitions: RefCounted) -> bool:
	if _task!=-2 or definitions==null or player==null or inspected.get("status")!=&"valid":return false
	var store:=StudioCheckpointStore.new(path)
	if cache_store==null or store.directory!=directory or cache_store.directory!=directory:return false
	if verified_source.is_empty() or verified_payload.is_empty() or verified_catalog.is_empty() or verified_identity.is_empty():return false
	if inspected.payload.has("rival_world") and world==null:return false
	if var_to_bytes(inspected.payload)!=verified_payload:return false
	if preload("res://scripts/simulation/development_replay.gd").source_identity()!=verified_identity:return false
	var context:=preload("res://scripts/persistence/checkpoint_write_validator.gd").new()
	context.rival_catalog=preload("res://scripts/market/rival_opening_loader.gd").copy_catalog(definitions)
	if context._catalog_content()!=verified_catalog:return false
	var generations:=store._generations()
	if not store._scan_error.is_empty() or generations.is_empty():return false
	var sequence: int=verified_source.get("sequence",0)
	if generations[-1]!=sequence or inspected.get("sequence")!=sequence:return false
	var expected_path:=store._path(sequence)
	if verified_source.get("path")!=expected_path:return false
	var source: Variant=verified_source.get("bytes")
	if not source is PackedByteArray or source.is_empty() or source.size()>CheckpointCodec.LIMIT:return false
	var file:=FileAccess.open(expected_path,FileAccess.READ)
	if file==null or file.get_length()!=source.size():return false
	var current:=file.get_buffer(file.get_length());file.close()
	return current==source
