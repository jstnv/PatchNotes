## Read-only analysis of a retained simulation tape. No gameplay is executed.
extends SceneTree

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		push_error("Expected replay.tape.json and new analysis output path")
		quit(1)
		return
	var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	if not envelope is Dictionary or envelope.get("format") != "patch-notes-development-replay":
		quit(2)
		return
	var tape: Variant = bytes_to_var(Marshalls.base64_to_raw(envelope.payload))
	if not tape is Dictionary or not tape.get("steps") is Array:
		quit(3)
		return
	var rows: Array = []
	for index in range(tape.steps.size()):
		var entry: Dictionary = tape.steps[index]
		var command: Dictionary = entry.command
		if str(command.phase) != "beta" or str(command.type) != "development": continue
		var request: Dictionary = command.payload.request
		if str(request.type) != "play": continue
		rows.append({"step":index+1,"request":request,"events":entry.result.get("events",[])})
	var file := FileAccess.open(args[1],FileAccess.WRITE)
	if file == null:
		quit(4)
		return
	file.store_string(JSON.stringify({"source_tape":args[0],"beta_plays":rows},"\t"))
	file.close()
	print(JSON.stringify({"ok":true,"beta_plays":rows.size(),"output":args[1]}))
	quit()
