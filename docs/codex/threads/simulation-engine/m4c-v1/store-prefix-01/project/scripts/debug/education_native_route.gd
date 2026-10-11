extends "res://scripts/debug/starwave_native_route.gd"

func _run() -> void:
	declared_seed=1104;random_inputs.seed=declared_seed
	era_policy="synergy";release_band="early";project_number=0;store_arm="none";neon_policy=false
	var directory:=_arg("--directory=","")
	var out:Dictionary={"seed":declared_seed,"policy":era_policy,"actions":[],"releases":[],"cycles":[],"errors":[],"blockers":[],"stop":"","cases":{}}
	var run:=RunState.new();run.initialize_cash(0)
	run.create_studio_with_traits("Education native route",&"action",[&"lean_production",&"studio_buzz",&"college_dropout"])
	run.random_streams.stream(&"contract_deal").seed=31104
	var game:Control=load("res://scenes/gameplay.tscn").instantiate()
	game.run_state=run;root.add_child(game);await process_frame
	run.calendar_changed.connect(func():
		out.cycles.append(_state(game))
		if run.get_completed_run_cycles() in [24,25,26,27,28]:out.cases["native-cycle-"+str(run.get_completed_run_cycles())]=run.get_studio_finance_snapshot())
	out.initial=_state(game);out.cases.creation=run.get_studio_finance_snapshot()
	for number in range(1,4):
		if not _begin_game(game,"Education release %d"%number,&"action",out):out.stop="departure";break
		if not await _develop_game(game,era_policy,"mixed","qa",declared_seed+(number-1)*500000,number,out):out.stop="development";break
		out.releases.append(_release(game.project_state,run))
		if number==1:
			if not await _trial_contract(game,ContractState.CONTRACT_ID,out):out.stop="Ironclad";break
		else:
			var publisher:=PublisherCatalog.CROWN_QUILL if number==2 else PublisherCatalog.NEON_CIRCUIT
			var offer:=pending_for(run,publisher)
			if not offer.is_empty() and not await _trial_contract(game,offer,out):out.stop="publisher";break
		out.cases["after-game-"+str(number)]=run.get_studio_finance_snapshot()
	var adapter:=StudioCheckpoint.new()
	out.loan_quote=run.get_bank_quote(50000,12)
	out.loan_accepted=run.accept_bank_loan(out.loan_quote) if out.loan_quote.get("accepted",false) else false
	out.before_payoff=_state(game);out.payoff_quote=run.get_education_payoff_quote()
	out.before_checkpoint=adapter.capture(run)
	if out.before_checkpoint.is_empty():out.stop="native Studio checkpoint: "+adapter.error
	else:
		FileAccess.open(directory.path_join("before-education-payoff.payload.json"),FileAccess.WRITE).store_string(JSON.stringify(out.before_checkpoint))
		FileAccess.open(directory.path_join("before-education-payoff.checkpoint.1.json"),FileAccess.WRITE).store_string(CheckpointCodec.new().envelope(out.before_checkpoint))
	out.late_payoff=run.pay_off_education(out.payoff_quote) if run.get_cash_cents()>=out.payoff_quote.get("required_cash_cents",9223372036854775807) else false
	out.cases["native-final"]=run.get_studio_finance_snapshot()
	# A separate legal creation cohort verifies an affordable grace-period payoff.
	# Its normal point-funded cash is never transferred into the developed route.
	var initial:=RunState.new();initial.initialize_cash(0)
	initial.create_studio_with_traits("Creation payoff cohort",&"action",[&"college_dropout"])
	out.cases["creation-payoff-before"]=initial.get_studio_finance_snapshot()
	var creation_quote:=initial.get_education_payoff_quote()
	out.creation_payoff=initial.pay_off_education(creation_quote)
	out.cases["creation-payoff-after"]=initial.get_studio_finance_snapshot()
	out.final=_state(game);out.finance=run.get_studio_finance_snapshot();out.sales=run._released_games;out.metadata=run._release_metadata
	out.valid=out.stop.is_empty() and out.releases.size()==3 and out.creation_payoff and StudioFinanceLedger._is_valid(out.finance)
	FileAccess.open(directory.path_join("native-route.json"),FileAccess.WRITE).store_string(JSON.stringify(out))
	print("EDUCATION NATIVE ",out.valid," stop=",out.stop," reviews=",out.releases.map(func(r):return r.final_review)," cycle=",run.get_completed_run_cycles()," late_payoff=",out.late_payoff)
	game.queue_free();await process_frame;quit(0 if out.valid else 1)
