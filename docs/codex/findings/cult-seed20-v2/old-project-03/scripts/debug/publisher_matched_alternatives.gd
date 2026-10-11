extends "res://scripts/debug/publisher_native_route.gd"

func _run() -> void:
	var branch := _arg("--arm=","crown")
	var payload: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://../docs/codex/findings/contracts-implementation-v1/legal-post3.checkpoint.json"))
	var adapter := StudioCheckpoint.new()
	var run := adapter.hydrate(payload)
	if run==null: push_error(adapter.error); quit(1); return
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	game.run_state = run
	root.add_child(game)
	await process_frame
	era_policy = "synergy"
	project_number = 3
	random_inputs.seed = 1501104
	var out := {"actions":[],"errors":[],"blockers":[],"before":_state(game),"arm":branch}
	var success := false
	var applicable := true
	if branch=="crown":
		for id in run.get_pending_publisher_offer_ids():
			if run.get_publisher_contract_offer(id).publisher_id==PublisherCatalog.CROWN_QUILL:
				success = await _trial_contract(game,id,out)
	elif branch=="sidestreet":
		var offer := run.get_next_sidestreet_offer()
		if not offer.is_empty(): success = await _trial_contract(game,offer.offer_id,out)
		else: applicable = false; success = true
	else:
		success = _begin_game(game,"Matched next project",&"action",out)
		if success:
			await process_frame
			var phase: DesignPhase = game._active_phase
			active_project = game.project_state
			phase_for_choice = phase
			success = _production_hand(phase,game.project_state,run,"synergy","mixed","design",4,out)
	out["after"] = _state(game)
	out["promotion"] = run.get_pending_promotion()
	out["applicable"] = applicable
	out["success"] = success and run.get_completed_run_cycles()==int(out.before.cycle)+(2 if applicable else 0) and StudioFinanceLedger._is_valid(run._studio_finance)
	FileAccess.open("res://../docs/codex/findings/contracts-implementation-v1/matched-%s.json" % branch,FileAccess.WRITE).store_string(JSON.stringify(out))
	print("Matched alternative ",branch,": ",out.success)
	game.queue_free()
	await process_frame
	quit(0 if out.success else 1)
