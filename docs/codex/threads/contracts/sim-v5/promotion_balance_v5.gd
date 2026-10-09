## Read-only current-source continuation. Loaded only by the isolated analysis copy.
extends "res://scripts/debug/publisher_native_route.gd"

func _run() -> void:
	var cohort := _arg("--cohort=", "neon-current")
	var output_path := _arg("--out=", "")
	var creation := "lease" if cohort.ends_with("lease") else "current"
	var target_publisher := PublisherCatalog.CROWN_QUILL if cohort.begins_with("crown") else PublisherCatalog.NEON_CIRCUIT
	var anchor_game := 3 if target_publisher == PublisherCatalog.CROWN_QUILL else 2
	era_policy = "synergy" if creation == "lease" else "ordinary"
	declared_seed = 1104
	random_inputs.seed = declared_seed
	project_number = 0
	release_band = "early"
	store_arm = "none"
	neon_policy = true
	max_games = 5
	action_limit = 120
	era_cap = 0
	first_store_cycle = 0
	var out := {"cohort": cohort, "creation": creation, "policy": era_policy, "seed": declared_seed,
		"target_publisher": target_publisher, "anchor_game": anchor_game, "foundation": {}, "arms": [], "errors": [], "valid": false}
	if output_path.is_empty() or cohort not in ["neon-current", "neon-lease", "crown-lease"]:
		out.errors.append("Invalid output path or undeclared cohort")
	else:
		var prepared: Dictionary = await _prepare(creation, anchor_game, out)
		if prepared.is_empty():
			out.errors.append("Legal foundation or checkpoint failed")
		else:
			var reference_cycle := -1
			for mode in ["trial", "cash_only", "no_offer"]:
				var arm: Dictionary = await _run_arm(prepared.checkpoint, target_publisher, anchor_game, creation, mode, reference_cycle)
				out.arms.append(arm)
				if mode == "trial" and bool(arm.get("success", false)):
					reference_cycle = int(arm.launch.cycle)
				if not bool(arm.get("success", false)):
					out.errors.append("Arm failed: " + mode + ": " + str(arm.get("errors", [])))
			out.valid = out.errors.is_empty() and out.arms.size() == 3
	if not output_path.is_empty():
		var file := FileAccess.open(output_path, FileAccess.WRITE)
		if file == null:
			push_error("Could not write " + output_path)
			quit(1)
			return
		file.store_string(JSON.stringify(out))
		file.close()
	print("PROMOTION_V5 ", cohort, " valid=", out.valid, " arms=", out.arms.size(), " errors=", out.errors)
	quit(0 if out.valid else 1)

func _prepare(creation: String, anchor_game: int, overall: Dictionary) -> Dictionary:
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	var run := RunState.new()
	run.initialize_cash(0)
	run.random_streams.stream(&"contract_deal").seed = 31104
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
			var quote := run.get_bank_quote(50000, 12)
			history["loan_quote"] = quote
			if quote.get("accepted", false): history["loan_accepted"] = run.accept_bank_loan(quote)
			history["hire"] = run.hire_production_specialist(run.get_production_hire_quote())
			if anchor_game == 3:
				var neon_id := _pending_id(run, PublisherCatalog.NEON_CIRCUIT)
				if neon_id.is_empty() or not await _trial_contract(game, neon_id, history):
					history.stop = "pre-Crown Neon"
					break
	var result := {}
	if history.stop.is_empty() and history.releases.size() == anchor_game and game._active_phase is StudioPhase:
		var adapter := StudioCheckpoint.new()
		var checkpoint: Dictionary = adapter.capture(run)
		if not checkpoint.is_empty():
			history["pre_target"] = _state(game)
			history["pending_offers"] = run.get_pending_publisher_offer_ids()
			history["pending_promotion"] = run.get_pending_promotion_awards()
			result = {"checkpoint": checkpoint}
		else:
			history.errors.append("Checkpoint: " + adapter.error)
	overall.foundation = history
	game.queue_free()
	await process_frame
	await process_frame
	return result

func _pending_id(run: RunState, publisher: StringName) -> StringName:
	for id: StringName in run.get_pending_publisher_offer_ids():
		if run.get_publisher_contract_offer(id).publisher_id == publisher:
			return id
	return &""

func _run_arm(checkpoint: Dictionary, publisher: StringName, anchor_game: int, creation: String, mode: String, reference_cycle: int) -> Dictionary:
	var out := {"mode": mode, "actions": [], "releases": [], "errors": [], "blockers": [], "success": false}
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
	out["before"] = _state(game)
	out["pending_before"] = run.get_pending_promotion_awards()
	var offer_id := _pending_id(run, publisher)
	if offer_id.is_empty():
		out.errors.append("Target offer absent")
	else:
		out["offer_id"] = offer_id
		if mode != "no_offer":
			if not await _trial_contract(game, offer_id, out):
				out.errors.append("Native Contract rejected")
			else:
				out["after_contract"] = _state(game)
				out["awards_after_contract"] = run.get_pending_promotion_awards()
				if mode == "cash_only":
					if not run._promotion_awards.has(offer_id):
						out.errors.append("Expected award absent before analysis intervention")
					else:
						out["suppressed_award"] = run._promotion_awards[offer_id]
						run._promotion_awards.erase(offer_id)
		if out.errors.is_empty():
			var next_number := anchor_game + 1
			if not _begin_game(game, "Native game %d" % next_number, &"action", out):
				out.errors.append("Next game departure blocked")
			elif not await _develop_game(game, era_policy, "mixed", "qa", declared_seed + (next_number - 1) * 500000, next_number, out):
				out.errors.append("Next game development blocked")
			else:
				var release_id: StringName = game.project_state.get_release_id()
				out["launch"] = _release(game.project_state, run)
				out["launch_promotion"] = run.get_release_promotion(release_id)
				out["launch_unlocked"] = run.get_unlocked_publisher_ids()
				var launch_cycle := int(out.launch.cycle)
				if reference_cycle < 0: reference_cycle = launch_cycle
				if mode == "cash_only" and launch_cycle != reference_cycle:
					out.errors.append("Cash-only launch calendar diverged")
				elif launch_cycle >= reference_cycle + 2:
					out.errors.append("No-offer launch too late for matched endpoint")
				else:
					run.calendar_changed.connect(_capture_settlement.bind(game, reference_cycle, release_id, out))
					var following := next_number + 1
					if not _begin_game(game, "Native game %d" % following, &"action", out):
						out.errors.append("Following game departure blocked")
					elif not await _develop_game(game, era_policy, "mixed", "qa", declared_seed + (following - 1) * 500000, following, out):
						out.errors.append("Following game development blocked")
					if not out.has("cycle_plus_2") or not out.has("cycle_plus_4"):
						out.errors.append("Missing first/second settlement capture")
				out["after"] = _state(game)
				out["ledger_valid"] = StudioFinanceLedger._is_valid(run._studio_finance)
				if not out.ledger_valid: out.errors.append("Finance ledger invalid")
	out.success = out.errors.is_empty()
	game.queue_free()
	await process_frame
	await process_frame
	return out

func _capture_settlement(game: Control, reference_cycle: int, release_id: StringName, out: Dictionary) -> void:
	var run: RunState = game.run_state
	var cycle := run.get_completed_run_cycles()
	if cycle not in [reference_cycle + 2, reference_cycle + 4]: return
	var key := "cycle_plus_2" if cycle == reference_cycle + 2 else "cycle_plus_4"
	out[key] = {"cycle": cycle, "state": _state(game), "target_sales": run.get_released_game_sales(release_id),
		"cash_cents": run.get_cash_cents(), "promotion_used": run.get_release_promotion(release_id),
		"pending_promotion": run.get_pending_promotion(), "unlocked": run.get_unlocked_publisher_ids(),
		"finance_valid": StudioFinanceLedger._is_valid(run._studio_finance)}
