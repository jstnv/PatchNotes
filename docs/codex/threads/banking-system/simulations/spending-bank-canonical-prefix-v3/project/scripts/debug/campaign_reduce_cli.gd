extends SceneTree
const Replay := preload("res://scripts/simulation/development_replay.gd")
const Reducer := preload("res://scripts/debug/campaign_failure_reducer.gd")

func _initialize() -> void:
	await process_frame
	var args: Dictionary = {}
	for argument in OS.get_cmdline_user_args():
		var pair := argument.trim_prefix("--").split("=",true,1)
		if pair.size() == 2: args[pair[0]] = pair[1]
	for field in ["case","tape","kind","output","max-commands"]:
		if not args.has(field): print("Missing --"+field); quit(2); return
	var output: String = args.output
	if DirAccess.dir_exists_absolute(output) or FileAccess.file_exists(output) or DirAccess.make_dir_recursive_absolute(output) != OK: print("Reduction output must be new"); quit(2); return
	var item := Replay.load_tape(args["case"])
	var tape := Replay.load_tape(args.tape)
	var report: Dictionary = {}
	if args.has("result"):
		var original: Variant = JSON.parse_string(FileAccess.get_file_as_string(args.result))
		if not original is Dictionary or original.get("input_identity") != Replay.digest(item) or original.get("tape_identity") != Replay.digest(tape): report = {"ok":false,"error":"Original exact case/tape identity mismatch"}
	if report.is_empty(): report = Reducer.reduce_case(item,tape,root.get_node("CardDatabase").get_development_catalog(),args.kind,int(args["max-commands"]))
	if report.get("ok",false):
		var saved: bool = Replay.save_tape(output.path_join("case.variant.json"),report["case"]) and Replay.save_tape(output.path_join("replay.tape.json"),report.tape)
		if not saved: report = {"ok":false,"error":"Could not save reduced evidence"}
		else:
			report.erase("case")
			report.erase("tape")
	var file := FileAccess.open(output.path_join("reduction.json"),FileAccess.WRITE)
	if file == null: quit(2); return
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print(JSON.stringify(report))
	quit(0 if report.get("ok",false) else 1)
