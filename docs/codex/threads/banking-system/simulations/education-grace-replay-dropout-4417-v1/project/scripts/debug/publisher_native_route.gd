extends "res://analysis/task32_routes_v1.gd"

func _run() -> void:
	era_policy = _arg("--policy=","ordinary")
	var comparison := _arg("--arm=","trial")
	var creation := _arg("--creation=","current")
	declared_seed = 1104
	random_inputs.seed = declared_seed
	project_number = 0
	release_band = "early"
	store_arm = "none"
	neon_policy = true
	var out := {"actions":[],"releases":[],"errors":[],"blockers":[],"stop":"", "policy":era_policy,"creation":creation,"arm":comparison}
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	var run := RunState.new()
	run.initialize_cash(0)
	run.random_streams.stream(&"contract_deal").seed = 31104
	if creation=="legacy": run.set_studio_name("Native trial",&"action")
	else: run.create_studio_with_traits("Native trial",&"action",[&"lean_production",&"studio_buzz",&"expensive_lease"] if creation=="lease" else [])
	game.run_state = run
	root.add_child(game)
	await process_frame
	out["initial"] = _state(game)
	for number in range(1,4):
		if not _begin_game(game,"Native game %d" % number,&"action",out): out.stop="departure"; break
		if not await _develop_game(game,era_policy,"mixed","qa",declared_seed+(number-1)*500000,number,out): out.stop="development"; break
		out.releases.append(_release(game.project_state,run))
		if number==1:
			if not await _trial_contract(game,ContractState.CONTRACT_ID,out): out.stop="Ironclad"; break
		elif number==2:
			var quote := run.get_bank_quote(50000,12)
			out["loan_quote"] = quote
			if quote.get("accepted",false): out["loan_accepted"] = run.accept_bank_loan(quote)
			out["hire"] = run.hire_production_specialist(run.get_production_hire_quote())
			out["comparison_start"] = _state(game)
			if comparison=="trial":
				for offer_id in run.get_pending_publisher_offer_ids():
					if not await _trial_contract(game,offer_id,out): out.stop="trial"; break
			elif comparison=="sidestreet" and run.is_sidestreet_offer_available():
				if not await _trial_contract(game,run.get_next_sidestreet_offer().offer_id,out): out.stop="SideStreet"; break
			out["before_next_launch"] = _state(game)
			out["pending_promotion"] = run.get_pending_promotion()
	if _arg("--crown=","0")=="1":
		var checkpoint := StudioCheckpoint.new().capture(run)
		FileAccess.open("res://../docs/codex/findings/contracts-implementation-v1/legal-post3.checkpoint.json",FileAccess.WRITE).store_string(JSON.stringify(checkpoint))
		for offer_id in run.get_pending_publisher_offer_ids():
			if not await _trial_contract(game,offer_id,out): out.stop="late Crown"; break
		if run.is_sidestreet_offer_available():
			if not await _trial_contract(game,run.get_next_sidestreet_offer().offer_id,out): out.stop="Bank settlement SideStreet"
		var loan := run.get_bank_quote(50000,12)
		out["late_loan_quote"] = loan
		out["late_loan_accepted"] = run.accept_bank_loan(loan)
		if not out.late_loan_accepted: out.stop="late Bank quote rejected"
		if not _begin_game(game,"Crown follow-up",&"action",out) or not await _develop_game(game,era_policy,"mixed","qa",declared_seed+1500000,4,out): out.stop="Crown next launch"
		else: out.releases.append(_release(game.project_state,run))
		if out.late_loan_accepted:
			var saved := StudioCheckpoint.new().capture(run)
			out["loan_checkpoint_valid"] = not saved.is_empty()
			var loan_id: StringName = run._studio_finance.bank_loans[0].loan_id
			out["late_payoff"] = run.pay_off_bank_loan(run.get_bank_payoff_quote(loan_id))
			if not out.late_payoff: out.stop="late payoff rejected"
	out["final"] = _state(game)
	out["remaining_promotion"] = run.get_pending_promotion()
	out["ledger_valid"] = StudioFinanceLedger._is_valid(run._studio_finance)
	var adapter := StudioCheckpoint.new()
	out["checkpoint_valid"] = not adapter.capture(run).is_empty()
	out["checkpoint_error"] = adapter.error
	if _arg("--crown=","0")=="1": comparison += "-crown"
	var destination := "res://../docs/codex/findings/contracts-implementation-v1/native-%s-%s-%s.json" % [creation,era_policy,comparison]
	FileAccess.open(destination,FileAccess.WRITE).store_string(JSON.stringify(out))
	print("Native trial route ",creation," ",era_policy," releases=",out.releases.size()," stop=",out.stop," checkpoint=",out.checkpoint_valid)
	game.queue_free()
	await process_frame
	quit(0 if out.stop.is_empty() and out.ledger_valid and out.checkpoint_valid else 1)

func _trial_contract(game: Control, offer_id: StringName, out: Dictionary) -> bool:
	var run: RunState = game.run_state
	var studio: StudioPhase = game._active_phase
	studio.get_node("%Contracts").pressed.emit()
	var chooser: OptionButton = studio._contract_chooser
	for index in range(chooser.item_count):
		if chooser.get_item_metadata(index)==offer_id:
			chooser.select(index)
			chooser.item_selected.emit(index)
	var before := _state(game)
	studio._contract_detail.find_child("AcceptContractButton",true,false).pressed.emit()
	if not game._active_phase is ContractPhase: return false
	var phase: ContractPhase = game._active_phase
	var state := run.get_active_contract()
	await process_frame
	var record := {"offer_id":offer_id,"before":before,"accepted":_state(game),"hands":[]}
	for hand in range(2):
		var cards := phase.get_candidate_cards()
		var indices := _choose_contract(cards,state,"optimizer" if era_policy=="synergy" else "ordinary")
		if indices.size()!=4: return false
		var views := phase._candidate_row.get_children()
		var selected: Array[CardData] = []
		for index: int in indices:
			selected.append(cards[index])
			(views[index] as CardView).input_button.pressed.emit()
		var step := {"draw":_ids(cards),"selected":_ids(selected),"before":_state(game)}
		if not phase._play_selected_hand(): return false
		step["after"] = _state(game)
		record.hands.append(step)
	record["result"] = {"cash":state.get_result().get_payout_cents(),"promotion":state.get_result().get_promotion(),"scope":state.get_scope()}
	phase._completion_panel.find_child("DismissCompletionButton",true,false).pressed.emit()
	record["after"] = _state(game)
	out.actions.append(record)
	return game._active_phase is StudioPhase

func _production_hand(phase: Control, project: ProjectState, run: RunState, policy: String, focus: String, label: String, game_number: int, out: Dictionary) -> bool:
	var cards: Array[CardData] = []
	cards.assign(phase.get("_candidate_cards"))
	if cards.size() != 7: return false
	var entry := {"phase": label, "game": game_number, "draw": _ids(cards), "redraws": [], "before": _state_for(project, run)}
	var attempts := 0 if policy == "cautious" else 1 if policy == "ordinary" else 2
	for unused in range(attempts):
		if run.get_available_redraws() == 0: break
		var slot := _weakest(cards, focus)
		var views: Array = phase.get_node("%HandContainer").get_children()
		(views[slot] as CardView).input_button.pressed.emit()
		var old := str(cards[slot].id)
		var changed: bool = phase.redraw_selected_cards()
		entry.redraws.append({"slot": slot, "from": old, "success": changed})
		if not changed:
			(views[slot] as CardView).input_button.pressed.emit()
			break
		cards.assign(phase.get("_candidate_cards"))
		entry.redraws[-1]["to"] = str(cards[slot].id)
	entry["final_draw"] = _ids(cards)
	var indices := _choose_production(cards, project, run, policy, focus)
	if indices.size() != 4:
		entry["blocked"] = "no affordable four-card selection"
		out.actions.append(entry)
		return false
	var selected: Array[CardData] = []
	var views: Array = phase.get_node("%HandContainer").get_children()
	for slot: int in indices:
		selected.append(cards[slot])
		(views[slot] as CardView).input_button.pressed.emit()
	entry["selected"] = _ids(selected)
	entry["printed_scope"] = selected.reduce(func(total: int, card: CardData) -> int: return total + card.scope, 0)
	entry["printed_core"] = _printed(selected)
	entry["normal_cents"] = run.primitive_feature_hand_cost_cents(selected)
	entry["cost_cents"] = run.primitive_feature_hand_cost_cents(selected,project.get_release_id())
	var base: Dictionary = phase.call("_validate_and_calculate_base_action")
	if not base.valid: return false
	var resolved: Dictionary = phase.call("_calculate_final_action_production", base)
	entry["synergy"] = str(resolved.specialization_stat) + " specialization" if not resolved.specialization_stat.is_empty() else "balanced production" if resolved.balanced_production else "none"
	var before_cycle := run.get_completed_run_cycles()
	if label == "design": phase.call("_on_play_card_pressed")
	else: phase.call("_on_play_alpha_hand_pressed")
	entry["after"] = _state_for(project, run)
	out.actions.append(entry)
	return run.get_completed_run_cycles() == before_cycle + 1

