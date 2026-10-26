extends "res://scripts/debug/verify_design_command.gd"

func _initialize() -> void: _three_core.call_deferred()

func _three_core() -> void:
	var database := root.get_node("CardDatabase")
	for phase_name in ["design","alpha"]:
		var outcomes := []
		for live in [true,false]:
			var project := ProjectState.new(30)
			project._release_id=&"three_core_parity"
			var card: CardData=database._create_card({"id":"synthetic_three_core","name":"Three Core Test","type":"feature","phase":phase_name,"department":"gameplay","scope":3,"renewable":false,"core_contributions":[{"stat":"graphics","value":3},{"stat":"sound","value":7},{"stat":"technology","value":5}]})
			var cards: Array[CardData]=[card,database.get_card(&"design_pass"),database.get_card(&"design_pass"),database.get_card(&"design_pass")]
			var phase: Object
			if live:
				phase=load("res://scenes/phases/"+phase_name+"_phase.tscn").instantiate()
				phase.setup(project)
				root.add_child(phase);await process_frame
				phase.set("_phase_state",1)
				_set_exact_candidates(phase,cards)
			else:
				phase=load("res://scripts/simulation/"+phase_name+"_hand_command.gd").new()
				phase._project_state=project;phase.active=true
				phase.priorities=PriorityAllocation.new().get_priority_distribution()
				phase._candidate_cards.assign(cards);phase.candidate_ids.assign([0,1,2,3]);phase.next_candidate_id=4
			phase.set("_deal_rng",RandomNumberGenerator.new());phase.get("_deal_rng").seed=4417
			phase.get("_pass_definitions").assign(database.get_cards_by_phase_and_types(&"design",[&"pass"] as Array[StringName]))
			phase.get("_available_features").assign([card] if phase_name=="alpha" else [])
			var events := []
			project.values_changed.connect(func(): events.append("values"))
			project.cycle_changed.connect(func(): events.append("cycle"))
			if live:
				phase.get_workspace().hand_motion.cancel()
				phase.get("_selected_card_views").assign(phase.get_node("%HandContainer").get_children())
				phase.call("_on_play_card_pressed" if phase_name=="design" else "_on_play_alpha_hand_pressed")
				phase.get_workspace().hand_motion.cancel()
			else:
				_expect(phase.execute(phase.command([0,1,2,3] as Array[int])).ok,"Synthetic three-Core accepted "+phase_name)
			outcomes.append({"project":freeze(project),"events":events.duplicate(),"rng":freeze(phase.get("_deal_rng")),"cards":freeze(phase.get("_candidate_cards")),"exhausted":freeze(phase.get("_exhausted_card_ids" if phase_name=="design" else "_exhausted_feature_ids"))})
			if live: phase.free();await process_frame
		_expect(outcomes[0]==outcomes[1],"Three-Core native/headless complete project, events, refill and RNG parity "+phase_name)
		FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT")+"-"+phase_name,FileAccess.WRITE).store_string(JSON.stringify(outcomes,"\t"))
	quit(1 if _failures else 0)
