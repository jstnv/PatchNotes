class_name CheckpointCoordinator
extends Node

signal status_changed
var adapter := StudioCheckpoint.new()
var store := StudioCheckpointStore.new("user://saves/studio", adapter.validate)
var run: RunState
var in_studio := false
var pending := false
var failure := ""
var last_payload: Dictionary = {}
var replace_on_save := false

func attach(value: RunState) -> void:
	if run!=null:
		for name in [&"cash_changed",&"calendar_changed",&"features_changed",&"sales_changed",&"contracts_changed",&"finance_changed",&"employees_changed"]:
			if run.is_connected(name,_changed): run.disconnect(name,_changed)
		run.studio_departure_guard = Callable()
		run.checkpoint_before_mutation = Callable()
	run = value
	run.studio_departure_guard = before_departure
	run.checkpoint_before_mutation = before_mutation
	for name in [&"cash_changed",&"calendar_changed",&"features_changed",&"sales_changed",&"contracts_changed",&"finance_changed",&"employees_changed"]:
		run.connect(name,_changed)

func _changed() -> void:
	if not in_studio: return
	pending = true
	flush.call_deferred()

func entered_studio(restored: bool = false) -> void:
	in_studio = true
	pending = not restored
	if pending: flush()
	else: status_changed.emit()

func before_departure() -> bool:
	if not in_studio: return false
	return flush()

func before_mutation() -> bool:
	if not failure.is_empty(): return false
	if not in_studio or run._productive_cycle_in_progress or run._publishing_cycle or run._feature_purchase_in_progress or run._committing_cycle_cash: return true
	return flush()

func flush() -> bool:
	if not in_studio or run==null: return failure.is_empty()
	if run.get_active_contract()!=null: return failure.is_empty()
	if not pending: return failure.is_empty()
	var payload := adapter.capture(run)
	if payload.is_empty(): return _failed(adapter.error)
	# Guidance acknowledgments ride along only on a committed action. Repeated
	# callbacks with identical state never create another generation.
	if payload==last_payload:
		pending = false
		return true
	var result := store.replace_run(payload) if replace_on_save else store.save(payload)
	if result.status!=&"saved": return _failed(str(result.get("reason",result.status)))
	last_payload = payload
	replace_on_save = false
	pending = false
	failure = ""
	run.checkpoint_mutations_allowed = true
	status_changed.emit()
	return true

func _failed(reason: String) -> bool:
	failure = reason
	run.checkpoint_mutations_allowed = false
	status_changed.emit()
	return false

func retry() -> bool:
	pending = true
	return flush()

func load_current() -> RunState:
	if not store.acquire():
		failure = "Another Patch Notes process owns the save slot. Close it before continuing."
		status_changed.emit()
		return null
	var inspected := store.inspect()
	if inspected.status!=&"valid": return null
	var restored := adapter.hydrate(inspected.payload)
	if restored==null: return null
	last_payload = inspected.payload.duplicate(true)
	last_payload.sequence = "1"
	failure = ""
	pending = false
	attach(restored)
	return restored

func _exit_tree() -> void:
	store.release_writer()
