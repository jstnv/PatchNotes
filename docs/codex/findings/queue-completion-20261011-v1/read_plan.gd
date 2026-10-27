extends SceneTree
const Campaign := preload("res://scripts/simulation/campaign_session.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
func _initialize() -> void: emit_plan.call_deferred()
func emit_plan() -> void:
 var folder := OS.get_environment("PN_PLAN_DIR")
 var session := Campaign.new()
 var snapshots := PrimitiveSnapshotDatabase.new()
 snapshots.load_ledgers()
 if not session.restore_checkpoint(JSON.parse_string(FileAccess.get_file_as_string(folder+"/actual-studio-envelope.json")), root.get_node("CardDatabase").get_development_catalog(), snapshots): quit(1); return
 var tape := Replay.load_tape(folder+"/crown-planning-run-v2/cases/actual-6-6-6/replay.tape.json")
 var rows := []
 for step: Dictionary in tape.steps:
  var view: Dictionary = session.observation()
  var result: Dictionary = session.execute(step.command)
  if not result.ok: push_error(str(result)); quit(1); return
  rows.append({"command":step.command,"before":view,"result":result})
 FileAccess.open(folder+"/ordinary-input-plan.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"\t"))
 print("Read-only route plan: ", rows.size(), " legal commands")
 quit(0)
