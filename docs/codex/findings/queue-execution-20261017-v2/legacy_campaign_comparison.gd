extends SceneTree
const Factory := preload("res://scripts/simulation/run_factory.gd")
const Replay := preload("res://scripts/simulation/development_replay.gd")
func without_additive_field(value: Variant) -> Variant:
	if value is Dictionary:
		var result: Dictionary=value.duplicate(true)
		if result.has("_ordered_core_contributions"):
			assert(result._ordered_core_contributions==[])
			result.erase("_ordered_core_contributions")
		for key in result:result[key]=without_additive_field(result[key])
		return result
	if value is Array:return value.map(without_additive_field)
	return value
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var args:=OS.get_cmdline_user_args();var path:=args[0]
	var initial: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path.path_join("initial.json")))
	var session: RefCounted=Factory.create(initial,root.get_node("CardDatabase").get_development_catalog())
	var tape:=Replay.load_tape(path.path_join("replay.tape.json"))
	var report := {"source_identity":Replay.source_identity(),"baseline_source":tape.source_identity,"normalization":"Remove only the new empty ordered contribution field from legacy card definitions; no gameplay, RNG, action or result changes", "initial":false,"steps":[],"ok":true}
	report.initial=Replay.digest(without_additive_field(Replay.state(session)))==tape.initial_state
	if not report.initial: report.ok=false
	for step: Dictionary in tape.steps:
		var result: Dictionary=session.execute(step.command)
		var same: bool=Replay.freeze(result)==step.result and Replay.digest(without_additive_field(Replay.state(session)))==step.state
		report.steps.append(same)
		if not same: report.ok=false;break
	FileAccess.open(args[1],FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("Legacy campaign comparison ",report.ok,"; ",report.steps.size()," steps; initial ",report.initial)
	quit(0 if report.ok else 1)
