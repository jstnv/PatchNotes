extends "res://scripts/debug/verify_primitive_branches.gd"
func _initialize() -> void:
	await process_frame
	catalog=root.get_node("CardDatabase").get_development_catalog()
	var rows:Array=JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("PN_BRANCH_REPLAY_INPUT")))
	check(rows.size()==2,"two real prior-save continuation cases")
	for row:Dictionary in rows:
		var session:=from_payload(row.initial)
		check(session!=null,"cold Studio restore")
		if session!=null:check(Replay.replay(session,Replay.load_tape(row.tape)).ok,"cold exact continuation replay")
	print("PRIMITIVE_BRANCH_COLD checks=%d failures=%d"%[checks,failures]);quit(failures)
