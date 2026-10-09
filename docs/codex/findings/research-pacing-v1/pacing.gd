extends "res://scripts/debug/publisher_native_route.gd"
var target: StringName
var acquisition: String
func _state_for(project: ProjectState, run: RunState) -> Dictionary:
	var result := super._state_for(project,run)
	result["research"] = run._feature_research.duplicate(true)
	result["owned"] = run.get_owned_feature_ids()
	return result
func instant(run: RunState, id: StringName) -> bool:
	if run.needs_starter_selection() or run._feature_purchase_in_progress or run._productive_cycle_in_progress or run._publishing_cycle: return false
	var offer := run.get_feature_store_offer(id)
	if offer.is_empty() or offer.owned or not offer.unlocked or not offer.affordable: return false
	var price: int = offer.price_cents
	if not run.can_complete_productive_cycle(-price): return false
	var commit := func() -> bool:
		if run.owns_feature(id): return false
		run._owned_features[id] = true
		return true
	return run.complete_productive_action(commit,-price,run.get_completed_run_cycles(),&"",&"store",id)
func acquire(game: Control, out: Dictionary, id: StringName, operation: String) -> bool:
	var run: RunState = game.run_state
	var quote := run.get_feature_research_quote(id)
	var before := _state(game)
	var rng := run.random_streams.snapshot()
	var success := false
	match operation:
		"instant": success = instant(run,id)
		"admit": success = run.admit_feature_research(quote)
		"research": success = run.research_feature(quote)
	out.acquisitions.append({"id":id,"operation":operation,"quote":quote,"before":before,"after":_state(game),"success":success,"rng_unchanged":rng==run.random_streams.snapshot()})
	return success
func shopping(game: Control, out: Dictionary) -> void:
	if acquisition == "none": return
	var run: RunState = game.run_state
	var targets: Array[StringName] = [target]
	if acquisition in ["fifo","sequential"]: targets = [&"colored_text",&"recorded_sounds"]
	var defer_ready := false
	if out.releases.size()>=2 and out.releases[1].final_review>out.releases[0].final_review:
		defer_ready = int(run.get_released_game_sales(StringName(out.releases[1].release_id)).get("settled_cents",0))>0
	for id in targets:
		if run.owns_feature(id): continue
		if acquisition == "instant":
			acquire(game,out,id,"instant")
			continue
		if not run.get_feature_research_quote(id).queued: acquire(game,out,id,"admit")
		if acquisition == "fifo": continue
		if acquisition == "defer" and not defer_ready: continue
		if run.get_feature_research_quote(id).queued: acquire(game,out,id,"research")
	if acquisition == "fifo":
		for id in targets:
			if run.get_feature_research_quote(id).head:
				if not acquire(game,out,id,"research"): break
func _run() -> void:
	declared_seed=int(_arg("--seed=","1104"));random_inputs.seed=declared_seed
	era_policy=_arg("--policy=","ordinary");release_band="early";project_number=0
	store_arm="none";neon_policy=false
	target=StringName(_arg("--target=","colored_text"));acquisition=_arg("--acquisition=","none")
	var creation:=_arg("--creation=","current")
	var out: Dictionary={"seed":declared_seed,"policy":era_policy,"creation":creation,"target":target,"acquisition":acquisition,"actions":[],"releases":[],"acquisitions":[],"cycles":[],"errors":[],"blockers":[],"stop":""}
	var run:=RunState.new();run.initialize_cash(0)
	if creation=="legacy":run.set_studio_name("Pacing",&"action")
	else:run.create_studio_with_traits("Pacing",&"action",[])
	for i in range(RunRandom.STREAMS.size()):run.random_streams.stream(RunRandom.STREAMS[i]).seed=declared_seed+i*100
	var game: Control=load("res://scenes/gameplay.tscn").instantiate();game.run_state=run;root.add_child(game)
	await process_frame
	run.calendar_changed.connect(func():out.cycles.append(_state(game)))
	out["initial"]=_state(game)
	for number in range(1,4):
		if not _begin_game(game,"Pacing game %d" % number,&"action",out):out.stop="departure";break
		out.actions[-1]["eligible_supply"]=game.project_state.get_feature_supply_ids()
		if not await _develop_game(game,era_policy,"mixed","qa",declared_seed+(number-1)*500000,number,out):out.stop="development";break
		out.releases.append(_release(game.project_state,run))
		if not out.blockers.is_empty():out.stop="first development block";break
		shopping(game,out)
	if out.stop.is_empty():
		if _begin_game(game,"Pacing game 4",&"action",out):
			out.actions[-1]["eligible_supply"]=game.project_state.get_feature_supply_ids()
			var phase: DesignPhase=game._active_phase
			active_project=game.project_state;phase_for_choice=phase
			for hand in range(2):
				if not _production_hand(phase,game.project_state,run,era_policy,"mixed","design",4,out):out.stop="Game4 hand blocked";break
		else:out.stop="Game4 departure blocked"
	out["final"]=_state(game)
	out["finance_valid"]=StudioFinanceLedger._is_valid(run._studio_finance)
	out["queue"]=run.get_feature_research_queue()
	out["sales"]=run._released_games
	FileAccess.open(_arg("--out=",""),FileAccess.WRITE).store_string(JSON.stringify(out))
	print("PACING ",creation," ",era_policy," ",target," ",acquisition," stop=",out.stop," finance=",out.finance_valid)
	game.queue_free();await process_frame
	quit(0 if out.finance_valid else 1)
