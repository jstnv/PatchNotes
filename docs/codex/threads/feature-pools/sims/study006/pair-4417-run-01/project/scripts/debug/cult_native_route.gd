extends "res://scripts/debug/fanbase_native_route.gd"

func _state_for(project: ProjectState, run: RunState) -> Dictionary:
	var result:=super._state_for(project,run)
	result.fans=run.get_fans()
	result.fanbase=run.get_fanbase_snapshot()
	return result

func _run() -> void:
	declared_seed=1104;random_inputs.seed=declared_seed;era_policy="ordinary";release_band="early";project_number=0;store_arm="none";neon_policy=false
	var out: Dictionary={"seed":declared_seed,"policy":era_policy,"actions":[],"releases":[],"cycles":[],"errors":[],"blockers":[],"stop":""}
	var ids: Array = [&"cult_following"] if OS.get_environment("PN_CULT_ARM") == "cult" else []
	var run:=RunState.new();run.initialize_cash(0);run.create_studio_with_traits("Cult matched route",&"action",ids)
	out.checkpoints = {"creation":StudioCheckpoint.new().capture(run)}
	for i in range(RunRandom.STREAMS.size()):run.random_streams.stream(RunRandom.STREAMS[i]).seed=declared_seed+i*100
	var game: Control=load("res://scenes/gameplay.tscn").instantiate();game.run_state=run;root.add_child(game)
	await process_frame
	run.calendar_changed.connect(func():out.cycles.append(_state(game)))
	out.initial=_state(game)
	for number in range(1,4):
		if not _begin_game(game,"Fan integration %d"%number,&"action",out):out.stop="departure";break
		if not await _develop_game(game,era_policy,"mixed","qa",declared_seed+(number-1)*500000,number,out):out.stop="development";break
		out.releases.append(_release(game.project_state,run))
		out.releases[-1].fanbase=run.get_fanbase_snapshot()
		out.releases[-1].metadata=run.get_release_metadata(game.project_state.get_release_id())
		out.checkpoints["launch_%d" % number] = StudioCheckpoint.new().capture(run)
		if not out.blockers.is_empty():out.stop="development affordability";break
		if number==1:
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
	out.valid=out.stop.is_empty() and out.releases.size()==3 and not out.checkpoint.is_empty() and StudioFinanceLedger._is_valid(run._studio_finance)
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify(out))
	print("FAN ROUTE ",out.valid," stop=",out.stop," reviews=",out.releases.map(func(r):return r.final_review)," checkpoint=",adapter.error)
	game.queue_free();await process_frame
	quit(0 if out.valid else 1)
