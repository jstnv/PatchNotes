extends "res://scripts/debug/verify_primitive_branches.gd"

func _initialize() -> void:
	await process_frame
	catalog=root.get_node("CardDatabase").get_development_catalog()
	var name:=OS.get_cmdline_user_args()[0]
	var base:=OS.get_environment("PN_BANK_AGE_DIR")
	var initial: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(base.path_join(name+".json.initial.json")))
	var tape_input:=Replay.load_tape(base.path_join(name+".json.tape.json"))
	var result:=Replay.replay(Factory.create({"checkpoint":initial},catalog),tape_input)
	check(result.ok,"fresh-process exact state/RNG/event replay including rejected actions")
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify({"source":Replay.source_identity(),"input":name,"result":result,"checks":checks,"failures":failures},"\t"))
	print("BANK_REPLAY checks=%d failures=%d steps=%d"%[checks,failures,result.get("steps",[]).size()]);quit(failures)
