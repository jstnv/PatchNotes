extends "res://scripts/debug/publisher_native_route.gd"

func _state_for(project: ProjectState, run: RunState) -> Dictionary:
	var result:=super._state_for(project,run)
	result.fans=run.get_fans()
	result.fanbase=run.get_fanbase_snapshot()
	return result

func pending_for(run: RunState, publisher: StringName) -> StringName:
	for id: StringName in run.get_pending_publisher_offer_ids():
		if run._publisher_offers[id].publisher_id==publisher: return id
	return &""

func _run() -> void:
	declared_seed=int(_arg("--seed=","1104"))
	random_inputs.seed=declared_seed
	era_policy="synergy";release_band="early";project_number=0;store_arm="none";neon_policy=false
	var out:Dictionary={"seed":declared_seed,"policy":era_policy,"actions":[],"releases":[],"cycles":[],"errors":[],"blockers":[],"stop":""}
	var run:=RunState.new()
	run.initialize_cash(0)
	run.create_studio_with_traits("Starwave acceptance",&"action",[&"lean_production",&"studio_buzz",&"expensive_lease"])
	run.random_streams.stream(&"contract_deal").seed=31104
	var game:Control=load("res://scenes/gameplay.tscn").instantiate()
	game.run_state=run
	root.add_child(game)
	await process_frame
	run.calendar_changed.connect(func():out.cycles.append(_state(game)))
	out.initial=_state(game)
	for number in range(1,4):
		if not _begin_game(game,"Starwave foundation %d"%number,&"action",out):out.stop="departure";break
		if not await _develop_game(game,era_policy,"mixed","qa",declared_seed+(number-1)*500000,number,out):out.stop="development";break
		out.releases.append(_release(game.project_state,run))
		if number==1:
			if not await _trial_contract(game,ContractState.CONTRACT_ID,out):out.stop="Ironclad";break
		elif number==2:
			var loan:=run.get_bank_quote(50000,12)
			out.loan_quote=loan
			out.loan_accepted=run.accept_bank_loan(loan) if loan.get("accepted",false) else false
			out.hired=run.hire_production_specialist(run.get_production_hire_quote())
			var crown:=pending_for(run,PublisherCatalog.CROWN_QUILL)
			if crown.is_empty() or not await _trial_contract(game,crown,out):out.stop="Crown";break
		else:
			var neon:=pending_for(run,PublisherCatalog.NEON_CIRCUIT)
			if neon.is_empty() or not await _trial_contract(game,neon,out):out.stop="Neon";break
	var directory:=_arg("--directory=","")
	var adapter:=StudioCheckpoint.new()
	var starwave:=pending_for(run,PublisherCatalog.STARWAVE)
	if out.stop.is_empty() and not starwave.is_empty():
		# A genuine eligible quote after two later settled months supplies the
		# integrated Bank boundary; the earlier ineligible quote stays evidence.
		if not out.get("loan_accepted",false):
			var late_loan:=run.get_bank_quote(50000,12)
			out.late_loan_quote=late_loan
			out.late_loan_accepted=run.accept_bank_loan(late_loan) if late_loan.get("accepted",false) else false
			if not out.late_loan_accepted:out.stop="eligible Bank loan not reached"
		out.before_starwave=_state(game)
		out.before_checkpoint=adapter.capture(run)
		out.pending_promotion=run.get_pending_promotion_awards()
		out.frozen_pool=run._primitive_contract_eligible_ids()
		if out.before_checkpoint.is_empty():out.stop="foundation checkpoint: "+adapter.error
		else:
			FileAccess.open(directory.path_join("before-starwave.payload.json"),FileAccess.WRITE).store_string(JSON.stringify(out.before_checkpoint))
			FileAccess.open(directory.path_join("before-starwave.checkpoint.1.json"),FileAccess.WRITE).store_string(CheckpointCodec.new().envelope(out.before_checkpoint))
			if not await _trial_contract(game,starwave,out):out.stop="Starwave"
			else:
				out.completed_checkpoint=adapter.capture(run)
				out.after_starwave=_state(game)
				if out.completed_checkpoint.is_empty():out.stop="completed checkpoint: "+adapter.error
				if not _begin_game(game,"After Starwave",&"action",out) or not await _develop_game(game,era_policy,"mixed","qa",declared_seed+1500000,4,out):out.stop="next release"
				else:
					out.releases.append(_release(game.project_state,run))
					out.next_launch_checkpoint=adapter.capture(run)
					out.next_launch_promotion=run.get_release_promotion(game.project_state.get_release_id())
					if not _begin_game(game,"After Starwave earnings",&"action",out):out.stop="earning departure"
					else:
						var phase:DesignPhase=game._active_phase
						phase._deal_rng.seed=declared_seed+2000003
						phase._finalization_rng.seed=declared_seed+2000004
						if phase.is_initial_priority_planning():
							phase.set_priority_distribution(_priorities(game.project_state))
							if not phase.get_workspace().overlay.commit_draft():out.stop="earning priorities"
						for hand in range(2):
							phase_for_choice=phase
							if not _production_hand(phase,game.project_state,run,era_policy,"mixed","design",5,out):out.stop="earning hand";break
	elif out.stop.is_empty():out.stop="no earned Starwave offer"
	out.final=_state(game)
	out.finance=run.get_studio_finance_snapshot()
	out.fanbase=run.get_fanbase_snapshot()
	out.sales=run._released_games
	out.metadata=run._release_metadata
	out.valid=out.stop.is_empty() and out.releases.size()==4 and StudioFinanceLedger._is_valid(run._studio_finance)
	FileAccess.open(directory.path_join("native-route.json"),FileAccess.WRITE).store_string(JSON.stringify(out))
	print("STARWAVE NATIVE ",out.valid," stop=",out.stop," releases=",out.releases.map(func(r):return r.final_review)," cycle=",run.get_completed_run_cycles())
	game.queue_free()
	await process_frame
	quit(0 if out.valid else 1)

func _trial_contract(game: Control, offer_id: StringName, out: Dictionary) -> bool:
	var run:RunState=game.run_state
	var studio:StudioPhase=game._active_phase
	studio.get_node("%Contracts").pressed.emit()
	var chooser:OptionButton=studio._contract_chooser
	for index in range(chooser.item_count):
		if chooser.get_item_metadata(index)==offer_id:
			chooser.select(index);chooser.item_selected.emit(index)
	var before:=_state(game)
	studio._contract_detail.find_child("AcceptContractButton",true,false).pressed.emit()
	if not game._active_phase is ContractPhase:return false
	var phase:ContractPhase=game._active_phase
	var state:=run.get_active_contract()
	await process_frame
	var record:Dictionary={"phase":"contract","offer_id":offer_id,"before":before,"accepted":_state(game),"hands":[],"terms":state._trial_terms,"pool":state.get_eligible_feature_ids()}
	for hand in range(state.get_required_hands()):
		var cards:=phase.get_candidate_cards()
		var indices:=_choose_contract(cards,state,"optimizer")
		if indices.size()!=4:return false
		var selected:Array[CardData]=[]
		for index:int in indices:
			selected.append(cards[index])
			(phase._candidate_row.get_children()[index] as CardView).input_button.pressed.emit()
		var step:Dictionary={"draw":_ids(cards),"selected":_ids(selected),"before":_state(game),"rng_before":run.random_streams.snapshot()}
		if not phase._play_selected_hand():return false
		step.after=_state(game);step.rng_after=run.random_streams.snapshot()
		record.hands.append(step)
	record.result={"cash":state.get_result().get_payout_cents(),"promotion":state.get_result().get_promotion(),"scope":state.get_scope(),"numerator":state.get_result().get_completion_numerator(),"cores":state._core_half_units}
	phase._completion_panel.find_child("DismissCompletionButton",true,false).pressed.emit()
	record.after=_state(game)
	out.actions.append(record)
	return game._active_phase is StudioPhase
