extends "res://scripts/debug/publisher_native_route.gd"

func _state_for(project: ProjectState, run: RunState) -> Dictionary:
	var result:=super._state_for(project,run)
	result.fans=run.get_fans()
	result.fanbase=run.get_fanbase_snapshot()
	return result

func _run() -> void:
	declared_seed=int(_arg("--seed=","1104"));random_inputs.seed=declared_seed;era_policy="ordinary";release_band="early";project_number=0;store_arm="none";neon_policy=false
	var out: Dictionary={"seed":declared_seed,"policy":era_policy,"actions":[],"releases":[],"cycles":[],"errors":[],"blockers":[],"stop":""}
	var traits: Array[StringName]=[]
	for id in _arg("--traits=","").split(",",false):traits.append(StringName(id))
	var run:=RunState.new();run.initialize_cash(0);run.create_studio_with_traits("Cult candidate screen",&"action",traits)
	out.build=_arg("--build=","control");out.traits=run.get_studio_traits();out.candidate={"seed":CultCandidate.initial(out.traits),"point_cost":CultCandidate.price() if &"cult_following" in traits else 0}
	out.positive_slots=traits.size()
	out.three_positives_reject=not StudioTraits.evaluate_traits([&"cult_following",&"studio_buzz",&"lean_production"]).valid
	for i in range(RunRandom.STREAMS.size()):run.random_streams.stream(RunRandom.STREAMS[i]).seed=declared_seed+i*100
	var game: Control=load("res://scenes/gameplay.tscn").instantiate();game.run_state=run;root.add_child(game)
	await process_frame
	run.calendar_changed.connect(func():out.cycles.append(_state(game)))
	out.initial=_state(game)
	out.initial_saved=_save(run,"initial")
	for number in range(1,2 if _arg("--search=","0")=="1" else 4):
		if not _begin_game(game,"Fan integration %d"%number,&"action",out):out.stop="departure";break
		if not await _develop_game(game,era_policy,"mixed","qa",declared_seed+(number-1)*500000,number,out):out.stop="development";break
		out.releases.append(_release(game.project_state,run))
		out.releases[-1].fanbase=run.get_fanbase_snapshot()
		out.releases[-1].metadata=run.get_release_metadata(game.project_state.get_release_id())
		if not out.blockers.is_empty():out.stop="development affordability";break
		if number==1 and _arg("--search=","0")!="1":
			if not await _trial_contract(game,ContractState.CONTRACT_ID,out):out.stop="Ironclad";break
		elif number==2 and run.is_sidestreet_offer_available():
			if not await _trial_contract(game,run.get_next_sidestreet_offer().offer_id,out):out.stop="SideStreet";break
	out.final=_state(game)
	out.finance=run.get_studio_finance_snapshot()
	out.fanbase=run.get_fanbase_snapshot()
	out.sales=run._released_games
	out.metadata=run._release_metadata
	var adapter:=StudioCheckpoint.new()
	out.checkpoint=adapter.capture(run)
	out.checkpoint_error=adapter.error
	out.valid=out.stop.is_empty() and out.releases.size()==(1 if _arg("--search=","0")=="1" else 3) and not out.checkpoint.is_empty() and StudioFinanceLedger._is_valid(run._studio_finance)
	out.final_saved=_save(run,"final")
	out.valid=out.valid and out.initial_saved and out.final_saved
	FileAccess.open(_arg("--out=",""),FileAccess.WRITE).store_string(JSON.stringify(out))
	print("FAN ROUTE ",out.valid," stop=",out.stop," reviews=",out.releases.map(func(r):return r.final_review)," checkpoint=",adapter.error)
	game.queue_free();await process_frame
	quit(0 if out.valid else 1)

func _develop_game(game: Control, policy: String, focus: String, _mode: String, seed_value: int, number: int, out: Dictionary) -> bool:
	await process_frame
	var project: ProjectState = game.project_state
	var run: RunState = game.run_state
	active_project = project
	var budgets: Array=[1,0,0] if number==2 else [3,4,4]
	if number==1:
		var parts:=_arg("--budget=","3,4,4").split(",")
		budgets=[int(parts[0]),int(parts[1]),int(parts[2])]
	var curtailed := false
	for phase_index in range(2):
		var label := "design" if phase_index == 0 else "alpha"
		var phase: Control = game.get("_active_phase")
		if phase.is_initial_priority_planning():
			phase.get("_deal_rng").seed = seed_value + 3
			phase.get("_finalization_rng").seed = seed_value + 4
			if policy == "synergy": phase.set_priority_distribution(_priorities(project))
			if not phase.get_workspace().overlay.commit_draft(): _stop(game, out, label, "initial priorities rejected"); return false
		for hand in range(budgets[phase_index]):
			if curtailed: break
			phase_for_choice = phase
			if not _production_hand(phase, project, run, policy, focus, label, number, out):
				_curtail(game, out, label, hand)
				curtailed = true
				break
		if phase_index == 0: phase.call("_on_proceed_to_alpha_pressed")
		else:
			phase.request_proceed_to_beta()
			if phase.get_node("%UnderScopeDialog").visible: phase.get_node("%UnderScopeDialog").confirmed.emit()
		if (phase_index == 0 and not game.get("_active_phase") is AlphaPhase) or (phase_index == 1 and not game.get("_active_phase") is BetaPhase): _stop(game, out, label, "phase transition rejected"); return false
	var beta: BetaPhase = game.get("_active_phase")
	beta.get("_deal_rng").seed = seed_value + 5
	beta.get("_insight_rng").seed = seed_value + 6
	beta.set_priority_distribution(_beta_priorities("qa"))
	if not beta.get_workspace().overlay.commit_draft(): _stop(game, out, "beta", "initial priorities rejected"); return false
	for hand in range(budgets[2]):
		if curtailed: break
		if not await _beta_hand(beta, project, run, policy, "qa", number, out):
			_curtail(game, out, "beta", hand)
			curtailed = true
			break
	game.set("_controlled_review_roll", -1)
	game.get("_review_rng").seed = seed_value + 7
	var before := _state(game)
	var launched := beta.request_launch()
	if not launched: launched = beta.confirm_launch_for_verification()
	out.actions.append({"phase": "launch", "game": number, "success": launched, "budget_curtailed": curtailed, "before": before, "after": _state(game)})
	if not launched: _stop(game, out, "launch", "launch rejected")
	return launched and game.get("_active_phase") is StudioPhase

func _save(run: RunState, label: String) -> bool:
	var adapter:=StudioCheckpoint.new()
	var payload:=adapter.capture(run)
	if payload.is_empty():return false
	var store:=StudioCheckpointStore.new("user://cult-"+label,adapter.validate)
	store._writer=TCPServer.new()
	if store._writer.listen(47846,"127.0.0.1")!=OK:return false
	var result:=store.save(payload)
	store.release_writer()
	FileAccess.open("user://cult-"+label+".sha256",FileAccess.WRITE).store_string(JSON.stringify(payload).sha256_text())
	return result.status==&"saved"
