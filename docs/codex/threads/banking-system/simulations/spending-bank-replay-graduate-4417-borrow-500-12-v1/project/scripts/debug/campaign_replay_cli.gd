## Explicit fresh-Studio recipe or source-pinned simulation Studio checkpoint.
extends SceneTree
const Session := preload("res://scripts/simulation/campaign_session.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Telemetry := preload("res://scripts/simulation/campaign_telemetry.gd")

func _initialize() -> void:
	await process_frame
	var recipe_path := OS.get_environment("PN_CAMPAIGN_RECIPE")
	var checkpoint_path := OS.get_environment("PN_CAMPAIGN_CHECKPOINT")
	var case_path := OS.get_environment("PN_CAMPAIGN_CASE")
	var tape_path := OS.get_environment("PN_CAMPAIGN_TAPE")
	var output := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	var telemetry_path := ""
	for argument in OS.get_cmdline_user_args():
		var pair := argument.trim_prefix("--").split("=",true,1)
		if pair.size() != 2: continue
		if pair[0] == "recipe": recipe_path = pair[1]
		if pair[0] == "checkpoint": checkpoint_path = pair[1]
		if pair[0] == "case": case_path = pair[1]
		if pair[0] == "tape": tape_path = pair[1]
		if pair[0] == "output": output = pair[1]
		if pair[0] == "telemetry": telemetry_path = pair[1]
	var initial_count := int(not recipe_path.is_empty()) + int(not checkpoint_path.is_empty()) + int(not case_path.is_empty())
	if initial_count != 1 or tape_path.is_empty():
		print("Usage: -- (--recipe=<fresh-studio.json> | --checkpoint=<studio.json> | --case=<case.variant.json>) --tape=<campaign-tape.json> --output=<report.json>")
		quit(2)
		return
	var session: RefCounted
	var exact_initial: Dictionary = {}
	if not case_path.is_empty():
		var exact_case := Replay.load_tape(case_path)
		if exact_case.get("initial") is Dictionary:
			exact_initial = exact_case.initial
			session = Factory.create(exact_case.initial,root.get_node("CardDatabase").get_development_catalog())
	elif not recipe_path.is_empty():
		session = create_fresh_session(JSON.parse_string(FileAccess.get_file_as_string(recipe_path)),root.get_node("CardDatabase"))
	else:
		var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(checkpoint_path))
		var snapshots := PrimitiveSnapshotDatabase.new()
		if envelope is Dictionary and snapshots.load_ledgers():
			var restored := Session.new()
			if restored.restore_checkpoint(envelope,root.get_node("CardDatabase").get_development_catalog(),snapshots): session = restored
	var report: Dictionary = {"ok":false,"error":"Invalid campaign recipe, checkpoint or exact case"}
	if session != null: report = Replay.replay(session,Replay.load_tape(tape_path))
	if report.ok and not telemetry_path.is_empty():
		var telemetry: Variant = JSON.parse_string(FileAccess.get_file_as_string(telemetry_path))
		if exact_initial.is_empty() or not telemetry is Dictionary:
			report = {"ok":false,"error":"Telemetry replay requires exact case and valid measurements"}
		else:
			var audit := _verify_telemetry(exact_initial,Replay.load_tape(tape_path),telemetry)
			report.telemetry_verified = audit.ok
			report.telemetry_samples = audit.get("samples",0)
			if not audit.ok:
				report.ok = false
				report.error = audit.error
	if not output.is_empty(): FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(0 if report.ok else 1)

static func create_fresh_session(recipe: Variant, database: Node) -> RefCounted:
	return null if database == null else Factory.create_fresh_session(recipe,database.get_development_catalog())

## Verify measurements in a second independent session, never against the first
## session or saved player data. Strict tape replay already checked source and
## initial-state identity; this pass also checks every recorded value.
func _verify_telemetry(initial: Dictionary,tape: Dictionary,expected: Dictionary) -> Dictionary:
	if expected.get("schema_version") != "1" or expected.get("sampling") != "initial_and_after_each_executed_command" or not expected.get("samples") is Array or expected.samples.size() != tape.steps.size()+1 or expected.get("source_identity") != tape.source_identity or expected.get("initial_state") != tape.initial_state: return {"ok":false,"error":"Malformed telemetry envelope"}
	var fresh: RefCounted = Factory.create(initial,root.get_node("CardDatabase").get_development_catalog())
	if fresh == null: return {"ok":false,"error":"Telemetry initial state failed"}
	var measured := Telemetry.sample(fresh,0,Replay.digest(Replay.state(fresh)))
	if JSON.parse_string(JSON.stringify(measured)) != expected.samples[0]: return {"ok":false,"error":"Telemetry initial sample differs"}
	for index in range(tape.steps.size()):
		var step: Dictionary = tape.steps[index]
		var result: Dictionary = fresh.execute(step.command)
		var state := Replay.digest(Replay.state(fresh))
		if state != step.state or Replay.freeze(result) != step.result: return {"ok":false,"error":"Telemetry verification command diverged"}
		measured = Telemetry.sample(fresh,index+1,state,step.command,result,int(measured.transaction_count))
		if JSON.parse_string(JSON.stringify(measured)) != expected.samples[index+1]: return {"ok":false,"error":"Telemetry sample differs at step %d" % [index+1]}
	if measured.state_digest != expected.get("final_state"): return {"ok":false,"error":"Telemetry final state differs"}
	return {"ok":true,"samples":expected.samples.size()}
