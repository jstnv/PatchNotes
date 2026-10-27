extends SceneTree
const Campaign := preload("res://scripts/simulation/campaign_session.gd")
func _initialize() -> void: convert.call_deferred()
func convert() -> void:
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
 if not session.save_checkpoint(OS.get_environment("PN_SIM_ENVELOPE")): quit(1); return
 print("Validated actual exported Studio evidence; no identity, cash, cycle, RNG or rule revision rewritten.")
 quit(0)
