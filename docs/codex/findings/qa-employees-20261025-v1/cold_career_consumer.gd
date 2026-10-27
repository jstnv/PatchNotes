extends SceneTree
const Session=preload("res://scripts/simulation/campaign_session.gd")
const Replay=preload("res://scripts/simulation/development_replay.gd")
var input: String
var output: String
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--input="):input=arg.trim_prefix("--input=")
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
	var raw: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(input))
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	var snapshots:=PrimitiveSnapshotDatabase.new();snapshots.load_ledgers()
	var current:=Session.new();var fresh:=Session.new()
	var valid: bool=raw.source==Replay.source_identity() and current.restore_checkpoint(raw.checkpoint,catalog,snapshots) and fresh.restore_checkpoint(raw.initial,catalog,snapshots)
	var replayed: Dictionary={}
	if valid:
		replayed=Replay.replay(fresh,Replay.load_tape(input+".tape.json"))
		valid=replayed.ok and current.export_checkpoint()==raw.checkpoint and Replay.state(current)==Replay.state(fresh)
	if not output.is_empty():FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"pass":valid,"source":Replay.source_identity(),"exact_cold_state_rng":valid,"replay":replayed,"synthetic_accounting_fixture":true,"affordability_evidence":false},"\t"))
	print("QA_CAREER_COLD pass=%s"%valid);quit(0 if valid else 1)
