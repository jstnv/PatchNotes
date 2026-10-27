extends SceneTree
const Factory=preload("res://scripts/simulation/run_factory.gd")
const Campaign=preload("res://scripts/simulation/campaign_session.gd")
const Replay=preload("res://scripts/simulation/development_replay.gd")
const Feedback=preload("res://scripts/contracts/crown_feedback.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+label)
func _initialize() -> void:go.call_deferred()
func go() -> void:
	var folder:=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fixture="):folder=arg.trim_prefix("--fixture=")
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	var fresh=Factory.create_fresh_session({"schema_version":1,"studio_id":"cold-feedback","studio_name":"Cold","specialty":"action","traits":[],"seed":"4417"},catalog)
	var initial: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("initial-current.json")))
	var final: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("completed-current.json")))
	var tape: Dictionary=Replay.load_tape(folder.path_join("feedback-tape.json"))
	var s=Campaign.new()
	check(s.restore_checkpoint(initial,catalog,fresh.snapshots),"Independent process accepts exact current initial envelope")
	if s.run==null:finish();return
	var replayed:=Replay.replay(s,tape)
	print("CROWN_REPLAY_RESULT ",JSON.stringify(replayed))
	check(replayed.ok,"Independent process replays every command/state/RNG step")
	var restored=Campaign.new()
	check(restored.restore_checkpoint(final,catalog,fresh.snapshots),"Independent process accepts completed Studio ledger")
	if restored.run!=null:
		check(Replay.state(restored)==Replay.state(s),"Cold Studio equals exact replayed state and RNG")
		check(Feedback.history(restored.run).available and Feedback.history(restored.run).count==3,"Derived consecutive-zero history survives fresh process")
	var bad:=final.duplicate(true);bad.source_identity="unknown"
	var reject=Campaign.new()
	check(not reject.restore_checkpoint(bad,catalog,fresh.snapshots) and reject.run==null,"Unknown source remains rejected")
	var old_path:=OS.get_environment("PN_CROWN_OUTPUT").get_base_dir().path_join("employee-menu-click-20261026-v1/before-pair.json")
	var old_hash:=FileAccess.get_sha256(old_path)
	var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(old_path))
	check(StudioCheckpoint.new().hydrate(old)==null,"Canonical predecessor deliberately rejects under private Crown schema; no unapproved migration")
	check(FileAccess.get_sha256(old_path)==old_hash,"Predecessor fixture bytes remain unchanged")
	finish()
func finish() -> void:
	print("CROWN_COLD_REPLAY checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
