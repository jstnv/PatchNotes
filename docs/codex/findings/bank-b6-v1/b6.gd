extends "res://scripts/debug/publisher_native_route.gd"

func blank() -> Dictionary:
	return {"actions":[],"releases":[],"cycles":[],"errors":[],"blockers":[],"stop":""}

func _run() -> void:
	declared_seed=int(_arg("--seed=","1104"));random_inputs.seed=declared_seed
	era_policy=_arg("--policy=","ordinary");release_band=_arg("--band=","early")
	project_number=0;store_arm="none";neon_policy=false
	var creation:=_arg("--creation=","current")
	var out:=blank();out.merge({"creation":creation,"policy":era_policy,"band":release_band,"seed":declared_seed,"loans":[]})
	var run:=RunState.new();run.initialize_cash(0)
	if creation=="legacy":run.set_studio_name("Bank B6",&"action")
	else:run.create_studio_with_traits("Bank B6",&"action",[])
	for i in range(RunRandom.STREAMS.size()):run.random_streams.stream(RunRandom.STREAMS[i]).seed=declared_seed+i*100
	var game:Control=load("res://scenes/gameplay.tscn").instantiate();game.run_state=run;root.add_child(game);await process_frame
	run.calendar_changed.connect(func():out.cycles.append(_state(game)))
	out.initial=_state(game)
	if _begin_game(game,"B6 first",&"action",out) and await _develop_game(game,era_policy,"mixed","qa",declared_seed,1,out):
		out.releases.append(_release(game.project_state,run));out.first_release=_state(game)
		var q:=run.get_feature_research_quote(&"colored_text")
		var before:=_state(game);var admitted:=run.admit_feature_research(q)
		out.actions.append({"phase":"research admission","quote":q,"success":admitted,"before":before,"after":_state(game)})
		if admitted:
			q=run.get_feature_research_quote(&"colored_text");before=_state(game)
			var researched:=run.research_feature(q)
			out.actions.append({"phase":"research","quote":q,"success":researched,"before":before,"after":_state(game)})
		var contract_ok:bool=await _trial_contract(game,ContractState.CONTRACT_ID,out)
		out.contract_ok=contract_ok
		if contract_ok:
			var id:StringName=run.get_released_game_ids()[0];before=_state(game)
			var campaign:=run.purchase_post_launch_campaign(id,run.get_completed_run_cycles())
			out.actions.append({"phase":"campaign","success":campaign,"before":before,"after":_state(game)})
		out.eligible_state=_state(game);out.quote=run.get_bank_quote(50000,12)
		var adapter:=StudioCheckpoint.new();var saved:=adapter.capture(run)
		out.checkpoint_valid=not saved.is_empty()
		if out.quote.get("accepted",false) and not saved.is_empty():
			var amounts:Array[int]=[0,50000]
			var bigger:=run.get_bank_quote(100000,12)
			if bigger.get("accepted",false):amounts.append(100000)
			var continuation_rng_state:=random_inputs.state
			for amount in amounts:
				project_number=1
				random_inputs.state=continuation_rng_state
				var fork:=adapter.hydrate(saved);assert(fork!=null)
				var child:Control=load("res://scenes/gameplay.tscn").instantiate();child.run_state=fork;root.add_child(child);await process_frame
				var arm_out:=blank();arm_out.principal=amount;arm_out.initial=_state(child)
				arm_out.restored_exact=adapter.capture(fork)==saved
				fork.calendar_changed.connect(func():arm_out.cycles.append(_state(child)))
				arm_out.quote=fork.get_bank_quote(amount,12)
				arm_out.accepted=fork.accept_bank_loan(arm_out.quote) if amount>0 else false
				arm_out.after_accept=_state(child)
				if _begin_game(child,"B6 second",&"action",arm_out) and await _develop_game(child,era_policy,"mixed","qa",declared_seed+500000,2,arm_out):arm_out.releases.append(_release(child.project_state,fork))
				arm_out.before_payoff=_state(child)
				if amount>0 and arm_out.accepted:
					arm_out.payoff_quote=fork.get_bank_payoff_quote(fork._studio_finance.bank_loans[-1].loan_id)
					arm_out.payoff=fork.pay_off_bank_loan(arm_out.payoff_quote)
				arm_out.final=_state(child);arm_out.valid=StudioFinanceLedger._is_valid(fork._studio_finance)
				out.loans.append(arm_out);child.queue_free();await process_frame
	out.final=_state(game);out.valid=StudioFinanceLedger._is_valid(run._studio_finance)
	FileAccess.open(_arg("--out=",""),FileAccess.WRITE).store_string(JSON.stringify(out))
	print("B6 ",creation," ",era_policy," ",release_band," loans=",out.loans.size()," valid=",out.valid)
	game.queue_free();await process_frame;quit(0 if out.valid else 1)
