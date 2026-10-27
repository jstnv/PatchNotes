extends SceneTree
const Factory=preload("res://scripts/simulation/run_factory.gd")
const Replay=preload("res://scripts/simulation/development_replay.gd")
var input: String
var output: String
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--input="):input=arg.trim_prefix("--input=")
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
	var raw: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(input))
	var tape: Dictionary=Replay.load_tape(input+".tape.json")
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	var session:=Factory.create_fresh_session(raw.recipe,catalog)
	var replayed:=Replay.replay(session,tape)
	var adapter:=StudioCheckpoint.new()
	var valid: bool=raw.source==Replay.source_identity() and replayed.ok and adapter.capture(session.run)==raw.checkpoint
	var cold:=adapter.hydrate(raw.checkpoint)
	valid=valid and cold!=null and adapter.capture(cold)==raw.checkpoint
	if cold!=null:
		valid=valid and cold.get_contract_search_quote(&"sidestreet",&"cash")==session.run.get_contract_search_quote(&"sidestreet",&"cash") and cold.get_publisher_relationships()==session.run.get_publisher_relationships() and cold.random_streams.snapshot()==session.run.random_streams.snapshot()
	if not output.is_empty():FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"pass":valid,"source":Replay.source_identity(),"replay":replayed,"commands":tape.steps.size(),"cold_exact":cold!=null and adapter.capture(cold)==raw.checkpoint},"\t"))
	print("COLD_SEARCH_REPLAY pass=%s commands=%d"%[valid,tape.steps.size()]);quit(0 if valid else 1)
