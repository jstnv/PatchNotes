## Headless replay bootstrap for an explicit fresh-Studio recipe. This does not
## deserialize saves or allow Continue outside the existing Studio checkpoint.
extends SceneTree

const Session := preload("res://scripts/simulation/development_session.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")

func _initialize() -> void:
	await process_frame
	var inputs: Dictionary = {"recipe":OS.get_environment("PN_DEVELOPMENT_RECIPE"),"tape":OS.get_environment("PN_DEVELOPMENT_TAPE"),"output":OS.get_environment("PN_CARD_FRAME_OUTPUT")}
	for argument in OS.get_cmdline_user_args():
		var pair:=argument.trim_prefix("--").split("=",true,1)
		if pair.size()==2 and inputs.has(pair[0]): inputs[pair[0]]=pair[1]
	if inputs.recipe.is_empty() or inputs.tape.is_empty():
		print("Usage: --headless --path patch-notes --script res://scripts/debug/development_replay_cli.gd -- --recipe=<fresh-studio.json> --tape=<tape.json> --output=<report.json>")
		quit(2)
		return
	var recipe: Variant = JSON.parse_string(FileAccess.get_file_as_string(inputs.recipe))
	var session:=create_fresh_session(recipe,root.get_node("CardDatabase"))
	var report: Dictionary = {"ok":false,"error":"Invalid fresh-Studio recipe"}
	if session!=null: report=Replay.replay(session,Replay.load_tape(inputs.tape))
	print(JSON.stringify(report))
	if not inputs.output.is_empty():
		var output:=FileAccess.open(inputs.output,FileAccess.WRITE)
		if output==null: quit(2); return
		output.store_string(JSON.stringify(report,"\t"))
	quit(0 if report.ok else 1)

static func create_fresh_session(recipe: Variant,database: Node) -> RefCounted:
	if not recipe is Dictionary or recipe.get("schema_version")!=1: return null
	for field in ["project_id","studio_id","studio_name","game_name","genre","theme","specialty","competitor","forecast","seed"]:
		if not recipe.get(field) is String or recipe[field].is_empty(): return null
	if not recipe.seed.is_valid_int() or int(recipe.seed)<0 or int(recipe.seed)>ProjectState.MAX_SIGNED_INT-RunRandom.STREAMS.size(): return null
	if not recipe.get("traits") is Array or not recipe.get("tutorial") is bool: return null
	var scope: Variant = recipe.get("required_scope")
	if (not scope is int and not scope is float) or not is_finite(float(scope)) or scope!=floor(float(scope)) or scope<1 or scope>1000000: return null
	var traits: Array[StringName] = []
	for trait_id: Variant in recipe.traits:
		if not trait_id is String: return null
		traits.append(StringName(trait_id))
	var snapshots:=PrimitiveSnapshotDatabase.new()
	if not snapshots.load_ledgers() or not snapshots.has_competitor(StringName(recipe.competitor)) or not snapshots.has_forecast(StringName(recipe.forecast)): return null
	var run:=RunState.new()
	run.initialize_cash(0)
	if not run.create_studio_with_traits(recipe.studio_name,StringName(recipe.specialty),traits): return null
	# Stable fresh-run identities, not saved-state mutation or migration.
	run.set("_bank_run_id",StringName(recipe.studio_id))
	run.set("_employees",EmployeeRoster.create(StringName(recipe.studio_id)))
	var project:=ProjectState.new(int(scope))
	project.set("_release_id",StringName(recipe.project_id))
	if not project.initialize_snapshots(StringName(recipe.competitor),StringName(recipe.forecast)): return null
	if not project.configure_predevelopment(recipe.game_name,StringName(recipe.genre),StringName(recipe.theme),run.get_owned_feature_ids()): return null
	if recipe.tutorial and not run.begin_first_game_tutorial(project): return null
	for id in RunRandom.STREAMS: run.random_streams.stream(id).seed=int(recipe.seed)+RunRandom.STREAMS.find(id)
	var session:=Session.new()
	return session if session.initialize(project,run,database.get_development_catalog(),snapshots) else null
