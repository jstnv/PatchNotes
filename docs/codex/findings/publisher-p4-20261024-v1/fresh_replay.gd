## External acceptance bootstrap; shipped Replay/Factory remain authoritative.
extends SceneTree
func _initialize() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	var recipe: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	var session := preload("res://scripts/simulation/run_factory.gd").create_fresh_session(recipe,root.get_node("CardDatabase").get_development_catalog())
	assert(session != null)
	var replay := preload("res://scripts/simulation/development_replay.gd")
	var result := replay.replay(session,replay.load_tape(args[1]))
	FileAccess.open(args[2],FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("Fresh process replay: ",result.ok," steps ",result.get("steps",[]).size())
	quit(0 if result.ok else 1)
