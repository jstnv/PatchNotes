## Read-only current-source active-loan stress comparison. Isolated copy only.
extends "res://scripts/debug/publisher_native_route.gd"
var loan_attempted := false

func _run() -> void:
	var cohort := _arg("--cohort=", "neon-loan-pressure")
	var output_path := _arg("--out=", "")
	var creation := "current"
	var target_publisher := PublisherCatalog.NEON_CIRCUIT
	var anchor_game := 2
	era_policy = "ordinary"
	declared_seed = 1104
	random_inputs.seed = declared_seed
	project_number = 0
	release_band = "early"
	store_arm = "none"
	neon_policy = true
	max_games = 4
	action_limit = 120
	era_cap = 0
	first_store_cycle = 0
	var out := {"cohort": cohort, "creation": creation, "policy": era_policy, "seed": declared_seed,
		"target_publisher": target_publisher, "anchor_game": anchor_game, "foundation": {}, "arms": [], "errors": [], "valid": false}
	if output_path.is_empty() or cohort != "neon-loan-pressure":
		out.errors.append("Invalid output path or undeclared cohort")
	else:
		var prepared: Dictionary = await _prepare(creation, anchor_game, out)
		if prepared.is_empty():
			out.errors.append("Legal foundation or checkpoint failed")
		else:
			var reference_cycle := -1
			for mode in ["pressure_neon", "pressure_pending", "baseline_neon", "baseline_pending"]:
				var arm: Dictionary = await _run_arm(prepared.checkpoint, target_publisher, anchor_game, creation, mode, reference_cycle)
				out.arms.append(arm)
				if mode == "pressure_neon" and arm.has("launch"):
					reference_cycle = int(arm.launch.cycle)
				if not bool(arm.get("valid_observation", false)):
					out.errors.append("Arm failed: " + mode + ": " + str(arm.get("errors", [])))
			out.valid = out.errors.is_empty() and out.arms.size() == 4
	if not output_path.is_empty():
		var file := FileAccess.open(output_path, FileAccess.WRITE)
		if file == null:
			push_error("Could not write " + output_path)
			quit(1)
			return
		file.store_string(JSON.stringify(out))
		file.close()
	print("NEON_LOAN_PRESSURE_V9 ", cohort, " valid=", out.valid, " arms=", out.arms.size(), " errors=", out.errors)
	quit(0 if out.valid else 1)

func _prepare(creation: String, anchor_game: int, overall: Dictionary) -> Dictionary:
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	var run := RunState.new()
	run.initialize_cash(0)
	run.random_streams.stream(&"contract_deal").seed = 31104
	loan_attempted = false
	var created := run.set_studio_name("Native trial", &"action") if creation == "legacy" else run.create_studio_with_traits("Native trial", &"action", [&"lean_production", &"studio_buzz", &"expensive_lease"] if creation == "lease" else [])
	if not created:
		return {}
	game.run_state = run
	root.add_child(game)
	await process_frame
	var history := {"actions": [], "releases": [], "errors": [], "blockers": [], "stop": "", "initial": _state(game)}
	for number in range(1, anchor_game + 1):
		if not _begin_game(game, "Native game %d" % number, &"action", history):
			history.stop = "departure"
			break
		if not await _develop_game(game, era_policy, "mixed", "qa", declared_seed + (number - 1) * 500000, number, history):
			history.stop = "development"
			break
		history.releases.append(_release(game.project_state, run))
		if number == 1:
			if not await _trial_contract(game, ContractState.CONTRACT_ID, history):
				history.stop = "Ironclad"
				break
		elif number == 2:
			history["hire"] = run.hire_production_specialist(run.get_production_hire_quote())
			if not loan_attempted or not bool(history.get("loan_accepted", false)):
				history.stop = "required cycle-16 Bank loan not accepted"
				break
	var result := {}
	if history.stop.is_empty() and history.releases.size() == anchor_game and game._active_phase is StudioPhase:
		var adapter := StudioCheckpoint.new()
		var checkpoint: Dictionary = adapter.capture(run)
		if not checkpoint.is_empty():
			history["pre_target"] = _state(game)
			history["pending_offers"] = run.get_pending_publisher_offer_ids()
			history["pending_promotion"] = run.get_pending_promotion_awards()
			history["bank_report"] = run.get_studio_finance_report()
			if _pending_id(run, PublisherCatalog.NEON_CIRCUIT).is_empty() or history.bank_report.bank_loans.size() != 1 or history.bank_report.total_overdue_cents != 0:
				history.errors.append("Required pending Neon/active-loan/no-arrears state absent")
			else:
				result = {"checkpoint": checkpoint}
		else:
			history.errors.append("Checkpoint: " + adapter.error)
	overall.foundation = history
	game.queue_free()
	await process_frame
	await process_frame
	return result

func _production_hand(phase: Control, project: ProjectState, run: RunState, policy: String, focus: String, label: String, game_number: int, out: Dictionary) -> bool:
	var success := super._production_hand(phase, project, run, policy, focus, label, game_number, out)
	if not success: return false
	if game_number == 2 and label == "design" and run.get_completed_run_cycles() == 16 and not loan_attempted:
		loan_attempted = true
		var quote := run.get_bank_quote(50000, 12)
		out["loan_quote_cycle16"] = quote
		out["loan_cash_before"] = run.get_cash_cents()
		out["loan_accepted"] = quote.get("accepted", false) and run.accept_bank_loan(quote)
		out["loan_cash_after"] = run.get_cash_cents()
		out.actions.append({"phase": "Bank acceptance", "game": 2, "cycle": run.get_completed_run_cycles(), "quote": quote, "accepted": out.loan_accepted})
	return success

func _pending_id(run: RunState, publisher: StringName) -> StringName:
	for id: StringName in run.get_pending_publisher_offer_ids():
		if run.get_publisher_contract_offer(id).publisher_id == publisher:
			return id
	return &""

func _run_arm(checkpoint: Dictionary, publisher: StringName, anchor_game: int, _creation: String, mode: String, reference_cycle: int) -> Dictionary:
	var out := {"mode": mode, "actions": [], "releases": [], "errors": [], "blockers": [], "stop": "", "valid_observation": false}
	var adapter := StudioCheckpoint.new()
	var run: RunState = adapter.hydrate(checkpoint)
	if run == null:
		out.errors.append("Hydration: " + adapter.error)
		return out
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	game.run_state = run
	root.add_child(game)
	await process_frame
	project_number = anchor_game
	random_inputs.seed = declared_seed
	out["before"] = _endpoint(game)
	out["owned_before"] = run.get_owned_feature_ids()
	out["pending_offers_before"] = run.get_pending_publisher_offer_ids()
	if mode.begins_with("pressure"):
		for id in [&"save_files", &"colored_text"]:
			var quote := run.get_feature_research_quote(id)
			var accepted := bool(quote.get("can_admit", false)) and run.admit_feature_research(quote)
			out.actions.append({"phase": "research admission", "feature_id": id, "quote": quote, "accepted": accepted, "after": _endpoint(game)})
			if not accepted:
				out.errors.append("Declared research admission rejected: " + str(id))
				break
	out["post_policy"] = _endpoint(game)
	out["owned_after_policy"] = run.get_owned_feature_ids()
	out["research_queue"] = run.get_feature_research_queue()
	if out.owned_before != out.owned_after_policy:
		out.errors.append("Admission changed ownership before Research")
	var offer_id := _pending_id(run, publisher)
	if offer_id.is_empty():
		out.errors.append("Pending Neon offer absent")
	else:
		out["offer_id"] = offer_id
	if out.errors.is_empty():
		run.calendar_changed.connect(_capture_early.bind(game, out))
		if mode.ends_with("neon"):
			if not await _trial_contract(game, offer_id, out):
				out.stop = "Native Neon Contract hand blocked"
				out["block_reason"] = run.get_financial_block_reason()
			else:
				out["after_contract"] = _endpoint(game)
				out["awards_after_contract"] = run.get_pending_promotion_awards()
		if out.stop.is_empty():
			var next_number := anchor_game + 1
			if not _begin_game(game, "Native game %d" % next_number, &"action", out):
				out.stop = "Game 3 departure blocked"
				out["block_reason"] = run.get_financial_block_reason()
			elif not await _develop_game(game, era_policy, "mixed", "qa", declared_seed + (next_number - 1) * 500000, next_number, out):
				out.stop = "Game 3 development/launch blocked"
				out["block_reason"] = run.get_financial_block_reason()
			else:
				var release_id: StringName = game.project_state.get_release_id()
				out["launch"] = _release(game.project_state, run)
				out["launch_promotion"] = run.get_release_promotion(release_id)
				out["launch_unlocked"] = run.get_unlocked_publisher_ids()
				if reference_cycle < 0: reference_cycle = int(out.launch.cycle)
				if int(out.launch.cycle) >= reference_cycle + 2:
					out.errors.append("Earlier-choice Game 3 launch reached comparator too late")
				else:
					run.calendar_changed.connect(_capture_settlement.bind(game, reference_cycle, release_id, out))
					var following := next_number + 1
					if not _begin_game(game, "Native game %d" % following, &"action", out):
						out.stop = "Game 4 departure blocked"
						out["block_reason"] = run.get_financial_block_reason()
					elif not await _develop_game(game, era_policy, "mixed", "qa", declared_seed + (following - 1) * 500000, following, out):
						out.stop = "Game 4 development/launch blocked"
						out["block_reason"] = run.get_financial_block_reason()
					if out.stop.is_empty() and (not out.has("cycle_plus_2") or not out.has("cycle_plus_4")):
						out.errors.append("Missing first/second matched settlement capture")
	out["final"] = _endpoint(game)
	out["ledger_valid"] = StudioFinanceLedger._is_valid(run._studio_finance)
	if not out.ledger_valid: out.errors.append("Finance ledger invalid")
	out.valid_observation = out.errors.is_empty()
	game.queue_free()
	await process_frame
	await process_frame
	return out

func _endpoint(game: Control) -> Dictionary:
	var run: RunState = game.run_state
	return {"cycle": run.get_completed_run_cycles(), "state": _state(game),
		"cash_cents": run.get_cash_cents(), "finance_report": run.get_studio_finance_report(),
		"pending_offers": run.get_pending_publisher_offer_ids(), "pending_promotion": run.get_pending_promotion_awards(),
		"owned_features": run.get_owned_feature_ids(), "research_queue": run.get_feature_research_queue(),
		"financial_block_reason": run.get_financial_block_reason(),
		"finance_valid": StudioFinanceLedger._is_valid(run._studio_finance)}

func _capture_early(game: Control, out: Dictionary) -> void:
	var cycle: int = game.run_state.get_completed_run_cycles()
	if cycle in [34, 36, 38]:
		out["cycle_" + str(cycle)] = _endpoint(game)

func _capture_settlement(game: Control, reference_cycle: int, release_id: StringName, out: Dictionary) -> void:
	var run: RunState = game.run_state
	var cycle := run.get_completed_run_cycles()
	if cycle not in [reference_cycle + 2, reference_cycle + 4]: return
	var key := "cycle_plus_2" if cycle == reference_cycle + 2 else "cycle_plus_4"
	out[key] = _endpoint(game)
	out[key]["target_sales"] = run.get_released_game_sales(release_id)
	out[key]["promotion_used"] = run.get_release_promotion(release_id)
