## Explicit fresh-Studio recipe or source-pinned simulation Studio checkpoint.
extends SceneTree
const Session := preload("res://scripts/simulation/campaign_session.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
const Factory := preload("res://scripts/simulation/run_factory.gd")

func _initialize() -> void:
	await process_frame
	var recipe_path := OS.get_environment("PN_CAMPAIGN_RECIPE")
	var checkpoint_path := OS.get_environment("PN_CAMPAIGN_CHECKPOINT")
	var case_path := OS.get_environment("PN_CAMPAIGN_CASE")
	var tape_path := OS.get_environment("PN_CAMPAIGN_TAPE")
	var output := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	for argument in OS.get_cmdline_user_args():
		var pair := argument.trim_prefix("--").split("=",true,1)
		if pair.size() != 2: continue
		if pair[0] == "recipe": recipe_path = pair[1]
		if pair[0] == "checkpoint": checkpoint_path = pair[1]
		if pair[0] == "case": case_path = pair[1]
		if pair[0] == "tape": tape_path = pair[1]
		if pair[0] == "output": output = pair[1]
	var initial_count := int(not recipe_path.is_empty()) + int(not checkpoint_path.is_empty()) + int(not case_path.is_empty())
	if initial_count != 1 or tape_path.is_empty():
		print("Usage: -- (--recipe=<fresh-studio.json> | --checkpoint=<studio.json> | --case=<case.variant.json>) --tape=<campaign-tape.json> --output=<report.json>")
		quit(2)
		return
	var session: RefCounted
	if not case_path.is_empty():
		var exact_case := Replay.load_tape(case_path)
		if exact_case.get("initial") is Dictionary:
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
	if not output.is_empty(): FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print(JSON.stringify(report))
	quit(0 if report.ok else 1)

static func create_fresh_session(recipe: Variant, database: Node) -> RefCounted:
	return null if database == null else Factory.create_fresh_session(recipe,database.get_development_catalog())
