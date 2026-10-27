extends SceneTree

const Replay := preload("res://scripts/simulation/development_replay.gd")


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		push_error("Expected one bundle path")
		quit(2)
		return
	var cases_path: String = args[0].path_join("cases")
	for case_id in DirAccess.get_directories_at(cases_path):
		var tape: Dictionary = Replay.load_tape(cases_path.path_join(case_id).path_join("replay.tape.json"))
		if tape.is_empty():
			print("PN_SHADOW_INSPECT " + JSON.stringify({"case_id":case_id,"error":"tape decode failed"}))
			continue
		var found: Array = []
		for step in tape.get("steps", []):
			for event in step.result.get("events", []):
				if event.get("type") == "sidestreet_relationship_shadow":
					found.append({"step":found.size(),"event":event})
		print("PN_SHADOW_INSPECT " + JSON.stringify({"case_id":case_id,"events":found,"initial_state":tape.get("initial_state"),"initial_rng":Replay.digest(tape.get("initial_rng"))}))
	quit()
