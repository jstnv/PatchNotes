## Read-only current-source continuation. Loaded only by the isolated analysis copy.
extends "res://scripts/debug/publisher_native_route.gd"

func _run() -> void:
	var cohort := _arg("--cohort=", "crown-lease-chain")
	var output_path := _arg("--out=", "")
	var creation := "lease"
	var target_publisher := PublisherCatalog.CROWN_QUILL
	var anchor_game := 2
	era_policy = "synergy"
	declared_seed = 1104
	random_inputs.seed = declared_seed
	project_number = 0
	release_band = "early"
	store_arm = "none"
	neon_policy = false
	max_games = 6
	action_limit = 160
	era_cap = 0
	first_store_cycle = 0
	var out := {"cohort": cohort, "creation": creation, "policy": era_policy, "seed": declared_seed,
		"target_publisher": target_publisher, "anchor_game": anchor_game, "foundation": {}, "arms": [], "errors": [], "valid": false}
	if output_path.is_empty() or cohort != "crown-lease-chain":
		out.errors.append("Invalid output path or undeclared cohort")
	else:
		var prepared: Dictionary = await _prepare(creation, anchor_game, out)
		if prepared.is_empty():
			out.errors.append("Legal foundation or checkpoint failed")
		else:
			var reference_cycle := -1
			for mode in ["chain", "crown_only", "crown_cash_only", "no_crown"]:
				var arm: Dictionary = await _run_arm(prepared.checkpoint, target_publisher, anchor_game, creation, mode, reference_cycle)
				out.arms.append(arm)
				if mode == "chain" and bool(arm.get("success", false)):
						reference_cycle = int(arm.game5_launch.cycle)
				if not bool(arm.get("success", false)):
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
	print("CROWN_NEON_GAME5_V8 ", cohort, " valid=", out.valid, " arms=", out.arms.size(), " errors=", out.errors)
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
			history["unlocked_before"] = run.get_unlocked_publisher_ids()
			history["pending_promotion"] = run.get_pending_promotion_awards()
			var last: Dictionary = history.releases[-1]
			if float(last.final_review) < 7.0 or int(last.awareness) >= 125 or PublisherCatalog.NEON_CIRCUIT in history.unlocked_before or _pending_id(run, PublisherCatalog.CROWN_QUILL).is_empty():
				history.errors.append("Required Crown-before-Neon state not reached")
			else:
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
	out["unlocked_before"] = run.get_unlocked_publisher_ids()
	out["pending_before"] = run.get_pending_publisher_offer_ids()
	var offer_id := _pending_id(run, publisher)
	if offer_id.is_empty():
		out.errors.append("Crown offer absent")
	else:
		out["crown_offer_id"] = offer_id
		if mode != "no_crown":
			if not await _trial_contract(game, offer_id, out):
				out.errors.append("Native Crown Contract rejected")
			else:
				out["after_crown"] = _state(game)
				out["crown_awards"] = run.get_pending_promotion_awards()
				if mode == "crown_cash_only":
					if not run._promotion_awards.has(offer_id):
						out.errors.append("Expected Crown award absent before analysis intervention")
					else:
						out["suppressed_award"] = run._promotion_awards[offer_id]
						run._promotion_awards.erase(offer_id)
		if out.errors.is_empty():
			var game3 := anchor_game + 1
			if not _begin_game(game, "Native game %d" % game3, &"action", out):
				out.errors.append("Game 3 departure blocked")
			elif not await _develop_game(game, era_policy, "mixed", "qa", declared_seed + (game3 - 1) * 500000, game3, out):
				out.errors.append("Game 3 development blocked")
			else:
				var game3_id: StringName = game.project_state.get_release_id()
				out["game3_launch"] = _release(game.project_state, run)
				out["game3_promotion"] = run.get_release_promotion(game3_id)
				out["game3_unlocked"] = run.get_unlocked_publisher_ids()
				out["pending_after_game3"] = run.get_pending_publisher_offer_ids()
				var neon_id := _pending_id(run, PublisherCatalog.NEON_CIRCUIT)
				if mode == "chain":
					if neon_id.is_empty():
						out.errors.append("Promotion did not make a pending Neon offer")
					elif not await _trial_contract(game, neon_id, out):
						out.errors.append("Native Neon Contract rejected")
					else:
						out["neon_offer_id"] = neon_id
						out["after_neon"] = _state(game)
						out["neon_awards"] = run.get_pending_promotion_awards()
				elif mode == "crown_only" and neon_id.is_empty():
					out.errors.append("Expected Neon offer absent in Crown-only arm")
				elif mode in ["crown_cash_only", "no_crown"] and not neon_id.is_empty():
					out.errors.append("Unexpected Neon offer in unpromoted arm")
				if out.errors.is_empty():
					var game4 := game3 + 1
					if not _begin_game(game, "Native game %d" % game4, &"action", out):
						out.errors.append("Game 4 departure blocked")
					elif not await _develop_game(game, era_policy, "mixed", "qa", declared_seed + (game4 - 1) * 500000, game4, out):
						out.errors.append("Game 4 development blocked")
					else:
						var game4_id: StringName = game.project_state.get_release_id()
						out["game4_launch"] = _release(game.project_state, run)
						out["game4_promotion"] = run.get_release_promotion(game4_id)
						out["game4_unlocked"] = run.get_unlocked_publisher_ids()
						out["pending_after_game4"] = run.get_pending_publisher_offer_ids()
						var game5 := game4 + 1
						if not _begin_game(game, "Native game %d" % game5, &"action", out):
							out.errors.append("Game 5 departure blocked")
						elif not await _develop_game(game, era_policy, "mixed", "qa", declared_seed + (game5 - 1) * 500000, game5, out):
							out.errors.append("Game 5 development blocked")
						else:
							var game5_id: StringName = game.project_state.get_release_id()
							out["game5_launch"] = _release(game.project_state, run)
							out["releases"].append(out.game5_launch)
							out["game5_promotion"] = run.get_release_promotion(game5_id)
							if reference_cycle < 0: reference_cycle = int(out.game5_launch.cycle)
							if int(out.game5_launch.cycle) > reference_cycle:
								out.errors.append("Game 5 launch later than reference")
							else:
								run.calendar_changed.connect(_capture_calendar.bind(game, reference_cycle, game3_id, game4_id, game5_id, out))
								if int(out.game5_launch.cycle) == reference_cycle:
									out["matched_G"] = _endpoint(game, game3_id, game4_id, game5_id)
								var game6 := game5 + 1
								if not _begin_game(game, "Native game %d" % game6, &"action", out):
									out.errors.append("Game 6 departure blocked before endpoint")
								else:
									out["game6_development_completed"] = await _develop_game(game, era_policy, "mixed", "qa", declared_seed + (game6 - 1) * 500000, game6, out)
								if not out.has("matched_G") or not out.has("cycle_plus_2") or not out.has("cycle_plus_4"):
									out.errors.append("Missing matched Game-5 calendar endpoint")
								out["after"] = _state(game)
								out["ledger_valid"] = StudioFinanceLedger._is_valid(run._studio_finance)
								if not out.ledger_valid: out.errors.append("Finance ledger invalid")
	out.success = out.errors.is_empty()
	game.queue_free()
	await process_frame
	await process_frame
	return out

func _capture_calendar(game: Control, reference_cycle: int, game3_id: StringName, game4_id: StringName, game5_id: StringName, out: Dictionary) -> void:
	var run: RunState = game.run_state
	var cycle := run.get_completed_run_cycles()
	if cycle not in [reference_cycle, reference_cycle + 2, reference_cycle + 4]: return
	var key := "matched_G" if cycle == reference_cycle else "cycle_plus_2" if cycle == reference_cycle + 2 else "cycle_plus_4"
	out[key] = _endpoint(game, game3_id, game4_id, game5_id)

func _endpoint(game: Control, game3_id: StringName, game4_id: StringName, game5_id: StringName) -> Dictionary:
	var run: RunState = game.run_state
	return {"cycle": run.get_completed_run_cycles(), "state": _state(game),
		"game3_sales": run.get_released_game_sales(game3_id), "game4_sales": run.get_released_game_sales(game4_id),
		"game5_sales": run.get_released_game_sales(game5_id),
		"cash_cents": run.get_cash_cents(), "pending_promotion": run.get_pending_promotion(),
		"pending_offers": run.get_pending_publisher_offer_ids(), "unlocked": run.get_unlocked_publisher_ids(),
		"completed_contracts": run.get_completed_contract_count(),
		"finance_valid": StudioFinanceLedger._is_valid(run._studio_finance)}
