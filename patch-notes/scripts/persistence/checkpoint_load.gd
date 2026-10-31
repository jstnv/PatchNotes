extends RefCounted

## One validated restore, advanced by UI frames or drained by synchronous tools.
## No writes, gameplay callbacks or partially attached player/world state.
const LABELS := ["Checking saved Studio…", "Restoring Studio…", "Restoring market…", "Preparing Studio…"]
var stage := 0
var done := false
var restored: RunState
var inspected: Dictionary = {}
var _owner: Node
var _candidate: Dictionary = {}
var _player_payload: Dictionary = {}
var _run: RunState
var _world: RivalWorld

func _init(coordinator: Node) -> void:
	_owner = coordinator

func label() -> String:
	return LABELS[mini(stage, LABELS.size() - 1)]

func advance() -> void:
	if done: return
	match stage:
		0:
			if not _owner.store.acquire():
				_reject("Another Patch Notes process owns the save slot. Close it before continuing.")
				_owner.status_changed.emit()
				return
			inspected = _owner.store.inspect()
			if inspected.status != &"valid":
				_reject(str(inspected.get("reason", inspected.status)), false)
				return
		1:
			_candidate = _owner._market_compatible_payload(inspected.payload)
			if _candidate.is_empty():
				_reject("Pre-market Continue migration rejected")
				return
			_player_payload = _candidate.duplicate(true)
			_player_payload.erase("rival_world")
			_run = _owner.adapter.hydrate(_player_payload)
			if _run == null:
				_reject(_owner.adapter.error)
				return
		2:
			if _candidate.has("rival_world"):
				if _owner.rival_catalog == null:
					_reject("Rival definitions unavailable for Continue")
					return
				var codec: RefCounted = load("res://scripts/market/rival_world_checkpoint.gd").new()
				_world = codec.restore(_candidate.rival_world, _player_payload, _run, _owner.rival_catalog)
				if _world == null:
					_reject("Rival world Continue rejected: " + codec.error)
					return
		3:
			_owner.last_payload = inspected.payload.duplicate(true)
			_owner.last_payload.sequence = "1"
			_owner.failure = ""
			_owner.pending = false
			_owner.attach(_run)
			_owner.rival_world = _world
			if _world!=null: _owner.attach_rivals(_world,_owner.rival_catalog)
			restored = _run
			done = true
	stage += 1

func _reject(reason: String, block_mutations: bool = true) -> void:
	# Invalid disk input belongs to recovery; it must not disable an explicit
	# New Run after Cancel. Retain the pre-existing mutation-lock semantics.
	if block_mutations: _owner.failure = reason
	done = true

var _read_job: RefCounted
func advance_async() -> void:
	if done:return
	if stage!=0:
		advance();return
	if _read_job==null:
		if not _owner.store.acquire():
			_reject("Another Patch Notes process owns the save slot. Close it before continuing.");_owner.status_changed.emit();return
		if _owner.rival_catalog==null:_reject("Rival definitions unavailable for Continue");return
		_read_job=preload("res://scripts/persistence/checkpoint_read_job.gd").new()
		_read_job.start(_owner.store.directory,_owner.rival_catalog)
		return
	if not _read_job.poll():return
	inspected=_read_job.inspected
	if inspected.get("status")!=&"valid" or _read_job.player==null:
		_reject(_read_job.error,false);return
	_candidate=_read_job.candidate;_player_payload=_read_job.player_payload
	_run=_read_job.player;_world=_read_job.world;_read_job=null
	stage=3
