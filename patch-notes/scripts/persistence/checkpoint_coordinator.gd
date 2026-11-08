class_name CheckpointCoordinator
extends Node

signal status_changed
var adapter := StudioCheckpoint.new()
var store: StudioCheckpointStore
var run: RunState
var rival_world: RivalWorld
var rival_catalog: RefCounted
var in_studio := false
var pending := false
var failure := ""
var last_payload: Dictionary = {}
## Process-local UI token; only durable publications increment it, never loads.
var completed_saves := 0
var replace_on_save := false
var _migration_input := ""
var _migration_output: Dictionary = {}
var _publishing_source_identity := ""
## Gameplay opts in; tools retain their explicit synchronous durability API.
var background_saves := false
## Explicit developer sandbox: preserve the durable normal Studio and never
## publish cheated state. A new Gameplay scene resets this process-local flag.
var debug_session:=false
var _write_job: RefCounted
var _change_revision := 0
var _write_catalog: RefCounted
var _exiting := false
var _last_write_player: Dictionary={}
var _last_write_world: Dictionary={}
## Dirty state alone never starts a write. Only a checkpoint boundary requests one.
var _save_requested := false

func _notify_status() -> void:
	# UI children may already be gone during scene teardown. The writer still
	# joins and publishes, but must not call back into disappearing controls.
	if not _exiting: status_changed.emit()

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS

func is_saving() -> bool:
	if debug_session:return false
	return _write_job!=null or (background_saves and _save_requested and pending and failure.is_empty() and in_studio and run!=null and run.get_active_contract()==null)

func _process(_delta: float) -> void:
	if _write_job!=null and not _write_job.thread.is_alive():
		_finish_write()
		if _save_requested and pending and failure.is_empty(): _request_save.call_deferred()

func _request_save() -> void:
	if debug_session:return
	if not _save_requested: return
	if not background_saves:
		flush()
		return
	if _exiting or _write_job!=null or not pending or not failure.is_empty() or not in_studio or run==null or run.get_active_contract()!=null: return
	_save_requested = false
	if not store.acquire():
		_failed("Another Patch Notes process owns the save slot.")
		return
	var player:=adapter.snapshot(run)
	if player.is_empty():
		_failed(adapter.error)
		return
	var world: Dictionary={}
	if rival_world!=null:
		var codec:=preload("res://scripts/market/rival_world_checkpoint.gd").new()
		world=codec.snapshot(rival_world,adapter)
		if world.is_empty():
			_failed(codec.error)
			return
	var job:=preload("res://scripts/persistence/checkpoint_write.gd").new()
	job.store=store
	job.player=player
	job.world=world
	job.catalog=_write_catalog
	job.replacing=replace_on_save
	job.revision=_change_revision
	job.previous_payload=last_payload
	job.previous_player=_last_write_player
	job.previous_world=_last_write_world
	_write_job=job
	var error:=job.start()
	if error!=OK:
		_write_job=null
		store.validator=_validate_payload
		_failed("Could not start the save worker: "+str(error))
		return
	_notify_status()

func _finish_write() -> void:
	if _write_job==null: return
	var revision: int=_write_job.revision
	var completed_job: RefCounted=_write_job
	var result: Dictionary=completed_job.join()
	_write_job=null
	store.validator=_validate_payload
	if result.status==&"superseded":
		# No publication occurred; keep all durable receipts and replacement intent.
		pending=true
		_notify_status()
		return
	if result.status not in [&"saved",&"unchanged"]:
		_failed(str(result.get("reason",result.status)))
		return
	last_payload=result.payload
	_last_write_player=completed_job.player
	_last_write_world=completed_job.world
	replace_on_save=false
	pending=revision!=_change_revision
	if not pending: _save_requested = false
	failure=""
	run.checkpoint_mutations_allowed=true
	if result.status == &"saved": completed_saves += 1
	_notify_status()

func wait_saved() -> bool:
	if debug_session:return true
	if not background_saves: return flush()
	if not failure.is_empty(): return false
	# Explicit boundary (Studio entry, Main Menu, Quit or Retry) drains current work.
	while in_studio and run != null and run.get_active_contract() == null and (pending or _write_job != null):
		_save_requested = pending
		_request_save()
		if not await wait_for_requested_save(): return false
	return failure.is_empty()

func wait_for_requested_save() -> bool:
	# Production departure may finish a Studio-entry write, but cannot request one.
	while is_saving():
		await get_tree().process_frame
	return failure.is_empty()

func retry_background() -> bool:
	failure=""
	pending=true
	return await wait_saved()

func _init() -> void:
	store = StudioCheckpointStore.new("user://saves/studio",_validate_payload)

func _validate_payload(payload: Dictionary) -> String:
	var candidate := _market_compatible_payload(payload)
	if candidate.is_empty(): return "Invalid pre-market migration payload"
	if preload("res://scripts/awards/award_receipts.gd").missing_world(candidate): return "Awarded Studio requires its global annual ledger"
	if not candidate.has("rival_world"): return adapter.validate(candidate)
	if not candidate.rival_world is Dictionary: return "Malformed rival world field"
	var player_payload := candidate.duplicate(true)
	player_payload.erase("rival_world")
	var restored := adapter.hydrate(player_payload)
	if restored==null: return adapter.error
	if rival_catalog==null: return "Rival definitions unavailable for validation"
	var codec: RefCounted=load("res://scripts/market/rival_world_checkpoint.gd").new()
	if codec.restore(candidate.rival_world,player_payload,restored,rival_catalog,_publishing_source_identity)==null: return codec.error
	return ""

func _market_compatible_payload(payload: Dictionary) -> Dictionary:
	if payload.get("content_revision")==adapter.revision(): return payload.duplicate(true)
	var key:=JSON.stringify(payload).sha256_text()
	if key==_migration_input and not _migration_output.is_empty(): return _migration_output.duplicate(true)
	var migration: RefCounted=load("res://scripts/market/market_save_migration_trial.gd").new()
	if not payload.has("rival_world"):
		var player_only: Dictionary=migration.upgrade_store_player(payload)
		if not player_only.is_empty() and migration.error.is_empty():
			_migration_input=key;_migration_output=player_only.duplicate(true)
		return player_only
	if not payload.rival_world is Dictionary or payload.rival_world.has("market"): return payload.duplicate(true)
	var player := payload.duplicate(true)
	player.erase("rival_world")
	var upgraded: Dictionary=migration.upgrade_pair(player,payload.rival_world,rival_catalog)
	if upgraded.is_empty(): return {}
	var combined: Dictionary=upgraded.player
	combined.rival_world=upgraded.world
	_migration_input=key;_migration_output=combined.duplicate(true)
	return combined

func attach_rivals(world: RivalWorld, definitions: RefCounted) -> bool:
	if world == null or definitions == null or world.player != run or world.cycle != run.get_completed_run_cycles(): return false
	_last_write_player={};_last_write_world={}
	rival_world = world
	rival_catalog = definitions
	# Give the worker its own definition values;
	# no main-thread UI/catalog object is ever handed to background validation.
	var base: Array[CardData]=[]
	var extra: Array[CardData]=[]
	for card: CardData in definitions.cards.values():
		var copy:=CardData.new()
		for property: Dictionary in card.get_property_list():
			if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
				var field: Variant=card.get(property.name)
				copy.set(property.name,field.duplicate(true) if field is Dictionary or field is Array else field)
		if card in definitions.primitive: base.append(copy)
		else: extra.append(copy)
	_write_catalog=preload("res://scripts/simulation/development_catalog.gd").new(base,extra)
	return true

func attach(value: RunState) -> void:
	if _write_job!=null: flush()
	_save_requested = false
	_last_write_player={};_last_write_world={}
	# Bind/load pays the catalog hash once; autosaves reuse this current identity.
	# Worker validation still rechecks the executable data before publication.
	adapter.revision()
	if run!=null:
		for signal_name in [&"cash_changed",&"calendar_changed",&"features_changed",&"sales_changed",&"contracts_changed",&"finance_changed",&"employees_changed",&"engines_changed",&"publisher_relationships_changed",&"studio_notice_state_changed"]:
			if run.is_connected(signal_name,_changed): run.disconnect(signal_name,_changed)
		run.studio_departure_guard = Callable()
		run.studio_action_guard = Callable()
		run.checkpoint_before_mutation = Callable()
	run = value
	run.studio_departure_guard = before_departure
	run.studio_action_guard = before_studio_action
	run.checkpoint_before_mutation = before_mutation
	for signal_name in [&"cash_changed",&"calendar_changed",&"features_changed",&"sales_changed",&"contracts_changed",&"finance_changed",&"employees_changed",&"engines_changed",&"publisher_relationships_changed",&"studio_notice_state_changed"]:
		run.connect(signal_name,_changed)

func _changed() -> void:
	if debug_session:pending=false;return
	if not in_studio: return
	_change_revision+=1
	pending = true
	# Preserve an in-flight boundary snapshot. Later actions stay dirty until
	# another boundary rather than superseding it into a per-action autosave.

func entered_studio(restored: bool = false) -> void:
	in_studio = true
	if debug_session:pending=false;_notify_status();return
	pending = not restored
	_save_requested = pending
	if pending:
		_change_revision+=1
		# Batch same-frame return/menu actions into the newest detached snapshot.
		if background_saves:_request_save.call_deferred()
		else:_request_save()
	else: _notify_status()

func before_departure() -> bool:
	if not in_studio: return false
	if _save_requested: _request_save()
	if _write_job != null: _finish_write()
	return failure.is_empty()

func before_studio_action() -> bool:
	if not in_studio or run==null:return false
	return before_mutation()

func before_mutation() -> bool:
	if debug_session:return true
	return failure.is_empty()

func flush() -> bool:
	if debug_session:pending=false;return true
	# Explicit durability barrier for synchronous tools/guards. Interactive
	# routes await wait_saved() before invoking these guards.
	if _write_job!=null: _finish_write()
	if not in_studio or run==null: return failure.is_empty()
	if run.get_active_contract()!=null: return failure.is_empty()
	if not pending: return failure.is_empty()
	var payload := adapter.capture(run)
	if payload.is_empty(): return _failed(adapter.error)
	if rival_world != null:
		var world_codec: RefCounted = load("res://scripts/market/rival_world_checkpoint.gd").new()
		var saved_world: Dictionary = world_codec.capture(rival_world)
		if saved_world.is_empty(): return _failed("Rival world checkpoint: " + world_codec.error)
		payload["rival_world"] = saved_world
	# Guidance acknowledgments ride along only on a committed action. Repeated
	# callbacks with identical state never create another generation.
	if payload==last_payload:
		pending = false
		_save_requested = false
		return true
	# capture() just computed this fingerprint from executable resources. Reuse
	# it only during this synchronous publication; later inspections/Continue
	# compute their own identity. Never derive this authority from disk input.
	_publishing_source_identity = str(payload.get("rival_world",{}).get("source_identity",""))
	var result := store.replace_run(payload) if replace_on_save else store.save(payload)
	_publishing_source_identity = ""
	if result.status!=&"saved": return _failed(str(result.get("reason",result.status)))
	last_payload = payload
	_last_write_player={};_last_write_world={}
	replace_on_save = false
	pending = false
	_save_requested = false
	failure = ""
	run.checkpoint_mutations_allowed = true
	completed_saves += 1
	_notify_status()
	return true

func begin_debug_session() -> bool:
	if debug_session:return true
	if not in_studio or run==null or run.get_active_contract()!=null:return false
	if not await wait_for_requested_save() or not failure.is_empty() or _write_job!=null:return false
	debug_session=true;pending=false;run.checkpoint_mutations_allowed=true
	_notify_status();return true

func _failed(reason: String) -> bool:
	failure = reason
	run.checkpoint_mutations_allowed = false
	_notify_status()
	return false

func retry() -> bool:
	pending = true
	return flush()

func load_current() -> RunState:
	var operation := begin_load()
	while not operation.done: operation.advance()
	return operation.restored

func begin_load(parsed_cache: StudioCheckpointStore = null, title_job: RefCounted = null) -> RefCounted:
	if _write_job!=null: flush()
	return preload("res://scripts/persistence/checkpoint_load.gd").new(self,parsed_cache,title_job)

func _exit_tree() -> void:
	_exiting=true
	# Normal Quit awaits already. Unexpected scene teardown still joins the
	# worker and drains newer committed Studio work before releasing the lease.
	if _write_job!=null or (background_saves and pending and failure.is_empty()): flush()
	store.release_writer()
