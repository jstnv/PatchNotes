extends "res://scripts/debug/candidate_route.gd"

func _trace(actions:Array)->Array:
	var result:Array=[]
	for action:Dictionary in actions:
		var row:Dictionary={}
		for key:String in ["phase","game","draw","final_draw","selected","redraws","priorities","rolls","printed_core","printed_scope","synergy","success","budget_curtailed"]:
			if action.has(key):row[key]=action[key]
		result.append(row)
	return JSON.parse_string(JSON.stringify(result))

func _run()->void:
	declared_seed=4417;random_inputs.seed=declared_seed;era_policy="synergy";release_band="late";project_number=0;store_arm="none";neon_policy=false
	var out:Dictionary={"seed":declared_seed,"policy":era_policy,"actions":[],"releases":[],"cycles":[],"errors":[],"blockers":[],"stop":""}
	var traits:Array[StringName]=[]
	for id in _arg("--traits=","").split(",",false):traits.append(StringName(id))
	var run:=RunState.new();run.initialize_cash(0);run.create_studio_with_traits("Cult high Review",&"action",traits)
	out.build=_arg("--build=","");out.traits=run.get_studio_traits();out.candidate={"seed":CultCandidate.initial(out.traits),"point_cost":CultCandidate.price() if &"cult_following" in traits else 0}
	out.positive_slots=traits.size();out.three_positives_reject=not StudioTraits.evaluate_traits([&"cult_following",&"studio_buzz",&"lean_production"]).valid
	for i in range(RunRandom.STREAMS.size()):run.random_streams.stream(RunRandom.STREAMS[i]).seed=declared_seed+i*100
	var game:Control=load("res://scenes/gameplay.tscn").instantiate();game.run_state=run;root.add_child(game);await process_frame
	run.calendar_changed.connect(func():out.cycles.append(_state(game)))
	out.initial=_state(game)
	var developed:=_begin_game(game,"Cult high first",&"action",out) and await _develop_game(game,era_policy,"mixed","qa",declared_seed,1,out)
	var parity:=false
	if developed:
		var release:=_release(game.project_state,run);release.metadata=run.get_release_metadata(game.project_state.get_release_id());out.releases.append(release)
		out.first_release=_state(game)
		var historic:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(_arg("--foundation=","")))
		parity=_trace(out.actions)==_trace(historic.known_trace) and release.final_review==8.5 and release.cycle==18
		out.foundation_parity=parity
		if parity:
			if not await _trial_contract(game,ContractState.CONTRACT_ID,out):out.stop="Ironclad rejected"
		else:out.stop="historical first-release parity mismatch"
	else:out.stop="development failed"
	out.final=_state(game);out.finance=run.get_studio_finance_snapshot();out.fanbase=run.get_fanbase_snapshot();out.sales=run._released_games;out.metadata=run._release_metadata
	out.checkpoint=StudioCheckpoint.new().capture(run);out.final_saved=_save(run,"high-final") if parity and out.stop.is_empty() else false
	out.valid=developed and parity and out.stop.is_empty() and out.blockers.is_empty() and out.final_saved and run.get_completed_run_cycles()==20
	FileAccess.open(_arg("--out=",""),FileAccess.WRITE).store_string(JSON.stringify(out))
	print("High-Review candidate ",out.build," valid=",out.valid," parity=",parity," Fans=",run.get_fans()," stop=",out.stop)
	game.queue_free();await process_frame;quit(0 if out.valid else 1)
