extends SceneTree

const Replay := preload("res://scripts/simulation/development_replay.gd")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("Expected output path and tape paths")
		quit(2)
		return
	var definitions: Dictionary = {}
	for path in ["res://data/card_ledger.json","res://data/feature_store_ledger.json"]:
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not parsed is Array:
			print("Invalid ledger: ",path)
			quit(2)
			return
		for entry: Dictionary in parsed: definitions[str(entry.id)]=entry
	var reports: Array = []
	for index in range(1,args.size()):
		var tape: Dictionary = Replay.load_tape(args[index])
		if tape.is_empty():
			print("Tape failed to load: ",args[index])
			quit(2)
			return
		var phase_state: Dictionary = {}
		var rows: Array = []
		for step: Dictionary in tape.steps:
			var command: Dictionary = step.command
			if str(command.get("type","")) != "development": continue
			var request: Dictionary = command.get("payload",{}).get("request",{})
			if str(request.get("type","")) != "play" or not bool(step.result.get("ok",false)): continue
			var phase := str(request.get("phase",""))
			if phase not in ["design","alpha"]: continue
			var project_id := str(request.get("project_id",""))
			var key := project_id+":"+phase
			var state: Dictionary = phase_state.get(key,{"feature_core":0,"passes":0,"hands":0})
			var base: Dictionary = step.result.get("base_hand",{})
			var cards: Array = base.get("cards",[])
			var hand_features := 0
			var hand_passes := 0
			var hand_core := 0
			for raw_card: Variant in cards:
				var card: Dictionary = definitions.get(str(raw_card),{})
				if card.is_empty():
					print("Unknown card: ",raw_card)
					quit(2)
					return
				if str(card.type)=="pass":
					hand_passes+=1
				elif str(card.type)=="feature":
					hand_features+=1
					if card.has("core_contributions"):
						for entry: Dictionary in card.core_contributions: hand_core+=int(entry.value)
					else: hand_core+=int(card.get("primary_value",0))+int(card.get("secondary_value",0))
			state.hands+=1
			state.feature_core+=hand_core
			state.passes+=hand_passes
			var generated := 2+int(floor(float(state.feature_core)/8.0))
			if state.passes>generated:
				print("Pass budget exceeded: ",key)
				quit(2)
				return
			rows.append({"project_id":project_id,"phase":phase,"hand":state.hands,"features":hand_features,"passes":hand_passes,"printed_feature_core":hand_core,"cumulative_feature_core":state.feature_core,"cumulative_passes":state.passes,"budget_generated":generated,"budget_remaining":generated-state.passes})
			phase_state[key]=state
		reports.append({"tape":args[index],"rows":rows})
	var file:=FileAccess.open(args[0],FileAccess.WRITE)
	if file==null:
		print("Cannot write report")
		quit(2)
		return
	file.store_string(JSON.stringify(reports,"\t"))
	print("PASS_COUNT_REPORT ",args[0]," tapes=",reports.size())
	quit()
