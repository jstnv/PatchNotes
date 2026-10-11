extends "res://scripts/debug/publisher_native_route.gd"

func blank() -> Dictionary:
	return {"actions":[],"releases":[],"cycles":[],"errors":[],"blockers":[],"stop":""}

func _begin_game(game: Control, title: String, genre: StringName, out: Dictionary) -> bool:
	var success: bool = super._begin_game(game, title, genre, out)
	if not success:
		_stop(game, out, "predevelopment", "departure rejected")
	return success

# The inherited helper only persists its record after success. This bounded
# variant retains acceptance and every attempted hand, including real blocks.
func _trial_contract(game: Control, offer_id: StringName, out: Dictionary) -> bool:
	var run: RunState = game.run_state
	var record := {"phase":"contract", "offer_id":offer_id, "before":_state(game), "hands":[], "accepted":false, "completed":false}
	out.actions.append(record)
	if not game._active_phase is StudioPhase:
		_stop(game, out, "contract acceptance", "Studio unavailable")
		return false
	var studio: StudioPhase = game._active_phase
	studio.get_node("%Contracts").pressed.emit()
	var chooser: OptionButton = studio._contract_chooser
	var found := false
	for index in range(chooser.item_count):
		if chooser.get_item_metadata(index) == offer_id:
			chooser.select(index)
			chooser.item_selected.emit(index)
			found = true
			break
	var accept := studio._contract_detail.find_child("AcceptContractButton", true, false)
	if not found or accept == null:
		record["after"] = _state(game)
		_stop(game, out, "contract acceptance", "declared offer unavailable")
		return false
	accept.pressed.emit()
	record["after_accept"] = _state(game)
	if not game._active_phase is ContractPhase:
		_stop(game, out, "contract acceptance", "acceptance rejected")
		return false
	record.accepted = true
	var phase: ContractPhase = game._active_phase
	var state := run.get_active_contract()
	await process_frame
	for hand in range(2):
		var cards := phase.get_candidate_cards()
		var indices := _choose_contract(cards, state, "optimizer" if era_policy == "synergy" else "ordinary")
		var step := {"hand":hand + 1, "draw":_ids(cards), "selected":[], "before":_state(game), "success":false}
		record.hands.append(step)
		if indices.size() != 4:
			step["after"] = _state(game)
			_stop(game, out, "contract hand", "no legal four-card selection for hand %d" % (hand + 1))
			return false
		var views := phase._candidate_row.get_children()
		var selected: Array[CardData] = []
		for index: int in indices:
			selected.append(cards[index])
			(views[index] as CardView).input_button.pressed.emit()
		step.selected = _ids(selected)
		step.success = phase._play_selected_hand()
		step["after"] = _state(game)
		if not step.success:
			_stop(game, out, "contract hand", "productive hand %d rejected" % (hand + 1))
			return false
	record["result"] = {"cash":state.get_result().get_payout_cents(), "promotion":state.get_result().get_promotion(), "scope":state.get_scope()}
	phase._completion_panel.find_child("DismissCompletionButton", true, false).pressed.emit()
	record["after"] = _state(game)
	record.completed = game._active_phase is StudioPhase
	if not record.completed:
		_stop(game, out, "contract dismissal", "did not return to Studio")
	return record.completed

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
		if not admitted: _stop(game, out, "research admission", "declared Colored Text admission rejected")
		if admitted:
			q=run.get_feature_research_quote(&"colored_text");before=_state(game)
			var researched:=run.research_feature(q)
			out.actions.append({"phase":"research","quote":q,"success":researched,"before":before,"after":_state(game)})
			if not researched: _stop(game, out, "research", "declared Colored Text Research rejected")
		var contract_ok:bool=await _trial_contract(game,ContractState.CONTRACT_ID,out)
		out.contract_ok=contract_ok
		if contract_ok:
			var id:StringName=run.get_released_game_ids()[0];before=_state(game)
			var campaign:=run.purchase_post_launch_campaign(id,run.get_completed_run_cycles())
			out.actions.append({"phase":"campaign","success":campaign,"before":before,"after":_state(game)})
			if not campaign: _stop(game, out, "campaign", "declared campaign rejected")
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
				arm_out.second_release_completed = false
				if _begin_game(child,"B6 second",&"action",arm_out) and await _develop_game(child,era_policy,"mixed","qa",declared_seed+500000,2,arm_out):
					arm_out.releases.append(_release(child.project_state,fork))
					arm_out.second_release_completed = true
				arm_out.before_payoff=_state(child)
				arm_out.payoff_attempted = false
				arm_out.payoff = false
				arm_out.payoff_skip_reason = "no loan" if amount == 0 else "Game 2 did not launch"
				if amount>0 and arm_out.accepted and arm_out.second_release_completed:
					arm_out.payoff_attempted = true
					arm_out.payoff_skip_reason = ""
					arm_out.payoff_quote=fork.get_bank_payoff_quote(fork._studio_finance.bank_loans[-1].loan_id)
					arm_out.payoff_rng_before = fork.random_streams.snapshot()
					arm_out.payoff=fork.pay_off_bank_loan(arm_out.payoff_quote)
					arm_out.payoff_rng_after = fork.random_streams.snapshot()
					arm_out.after_payoff = _state(child)
					if arm_out.payoff:
						arm_out.duplicate_payoff = fork.pay_off_bank_loan(arm_out.payoff_quote)
						arm_out.after_duplicate_payoff = _state(child)
						arm_out.duplicate_payoff_rng = fork.random_streams.snapshot()
				arm_out.final=_state(child);arm_out.valid=StudioFinanceLedger._is_valid(fork._studio_finance)
				out.loans.append(arm_out);child.queue_free();await process_frame
	out.final=_state(game);out.valid=StudioFinanceLedger._is_valid(run._studio_finance)
	FileAccess.open(_arg("--out=",""),FileAccess.WRITE).store_string(JSON.stringify(out))
	print("B6 ",creation," ",era_policy," ",release_band," loans=",out.loans.size()," valid=",out.valid)
	game.queue_free();await process_frame;quit(0 if out.valid else 1)
