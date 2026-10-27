## Read-only route planning from a validated ordinary-input Studio checkpoint.
extends SceneTree
const Campaign := preload("res://scripts/simulation/campaign_session.gd")
func _initialize() -> void: probe.call_deferred()
func probe() -> void:
	var codec := CheckpointCodec.new()
	var payload := codec.open_envelope(FileAccess.get_file_as_string(OS.get_environment("PN_SAVED_EVIDENCE")))
	if payload.is_empty(): push_error(codec.error); quit(1); return
	var adapter := StudioCheckpoint.new()
	var restored := adapter.hydrate(payload)
	if restored == null: push_error(adapter.error); quit(1); return
	var session := Campaign.new()
	session.run = restored
	session.catalog = root.get_node("CardDatabase").get_development_catalog()
	session.snapshots = PrimitiveSnapshotDatabase.new()
	if not session.snapshots.load_ledgers(): quit(1); return
	var result := {"view":session.observation(),"quote":session.quote_bank(50000,12)}
	FileAccess.open(OS.get_environment("PN_PROBE_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("Validated ordinary-input checkpoint and recorded detached public observations.")
	quit(0)
