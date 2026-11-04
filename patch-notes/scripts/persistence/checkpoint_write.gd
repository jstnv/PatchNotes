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
var previous_player: Dictionary = {}
var previous_world: Dictionary = {}
var _validator: RefCounted
var _phase_lock:=Mutex.new()
var _superseded:=false
var _publishing:=false

## Newer Studio mutations can discard obsolete preparation, never publication.
func supersede() -> void:
	_phase_lock.lock()
	if not _publishing:_superseded=true
	_phase_lock.unlock()

func _begin_publication() -> bool:
	_phase_lock.lock()
	var current:=not _superseded
	if current:_publishing=true
	_phase_lock.unlock()
	return current

func start() -> Error:
	_validator=Validator.new()
	_validator.rival_catalog=catalog
	store.validator=_validator._validate_payload
	# Full history validation can be CPU-heavy. It must yield scheduling priority
	# to input/rendering and the synchronous authoritative action, while explicit
	# departure/Quit still waits for the same complete durable result.
	return thread.start(_write,Thread.PRIORITY_LOW)

func _write() -> Dictionary:
	var adapter:=StudioCheckpoint.new()
	# Most saves change player state and cannot reuse the Awards presentation
	# payload. Check those cheap necessary conditions before hashing every
	# gameplay source; full encoding still hashes at its original later boundary.
	var payload: Dictionary=_presentation_payload(WorldCodec.Replay.source_identity()) if _presentation_candidate() else {}
	if payload.is_empty():payload=adapter.encode_snapshot(player)
	if payload.is_empty(): return {"status":&"invalid","reason":adapter.error}
	if not world.is_empty() and not payload.has("rival_world"):
		var codec:=WorldCodec.new()
		var encoded: Dictionary=codec.encode_snapshot(world,true)
		if encoded.is_empty(): return {"status":&"invalid","reason":codec.error}
		payload["rival_world"]=encoded
		_validator._publishing_source_identity=encoded.source_identity
	elif payload.has("rival_world"):_validator._publishing_source_identity=payload.rival_world.source_identity
	# Encode/validation errors above still surface. From this atomic transition
	# onward this generation must finish, even if a newer mutation arrives.
	if not _begin_publication():return {"status":&"superseded"}
	if not replacing and payload==previous_payload:
		return {"status":&"unchanged","payload":payload}
	var result:=store.replace_run(payload) if replacing else store.save(payload)
	if result.status==&"saved": result["payload"]=payload
	return result

func _presentation_candidate() -> bool:
	if world.is_empty() or previous_player.is_empty() or previous_world.is_empty() or not previous_payload.get("rival_world") is Dictionary:return false
	if var_to_bytes(player)!=var_to_bytes(previous_player):return false
	if not world.get("annual_awards") is Dictionary or not previous_world.get("annual_awards") is Dictionary:return false
	return not world.annual_awards.get("entries",[]).is_empty()

func _presentation_payload(source: String) -> Dictionary:
	if previous_player.is_empty() or previous_world.is_empty() or not previous_payload.get("rival_world") is Dictionary:return {}
	if previous_payload.rival_world.get("source_identity")!=source or previous_payload.get("content_revision")!=StudioCheckpoint.new().revision():return {}
	if var_to_bytes(player)!=var_to_bytes(previous_player):return {}
	var ledger:=preload("res://scripts/awards/annual_awards_ledger.gd")
	if not world.get("annual_awards") is Dictionary or not previous_world.get("annual_awards") is Dictionary:return {}
	if world.annual_awards.get("entries",[]).is_empty():return {}
	var current_identity: Dictionary=ledger.presentation_identity(world.annual_awards)
	var prior_identity: Dictionary=ledger.presentation_identity(previous_world.annual_awards)
	if current_identity.is_empty() or prior_identity.is_empty():return {}
	var current:=world.duplicate();current.annual_awards=current_identity
	var prior:=previous_world.duplicate();prior.annual_awards=prior_identity
	if var_to_bytes(current)!=var_to_bytes(prior):return {}
	var codec:=CheckpointCodec.new()
	var encoded: Variant=codec.encode(world.annual_awards,ledger.schema())
	if not codec.error.is_empty():return {}
	var payload:=previous_payload.duplicate(true)
	payload.rival_world.annual_awards=encoded
	return payload

func join() -> Dictionary:
	return thread.wait_to_finish()
