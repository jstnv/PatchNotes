## Analysis-only timing and Promotion sensitivity. Installed only in the isolated project.
## The three placeholders below are NOT legal or scored Starwave Contract hands.
extends "res://scripts/debug/crown_neon_chain_base_v10.gd"

const SHADOW_ID := &"analysis_starwave_timing_v10"
const ARM_SPECS := [
	{"mode":"delay_only", "cycles":3, "cash_cents":0, "extra_promotion":0},
	{"mode":"pending", "cycles":0, "cash_cents":0, "extra_promotion":0},
	{"mode":"cash2240_p0", "cycles":3, "cash_cents":224000, "extra_promotion":0},
	{"mode":"cash2240_p6", "cycles":3, "cash_cents":224000, "extra_promotion":6},
	{"mode":"cash2240_p14", "cycles":3, "cash_cents":224000, "extra_promotion":14},
	{"mode":"cash3000_p6", "cycles":3, "cash_cents":300000, "extra_promotion":6},
]


func _run() -> void:
	var cohort := _arg("--cohort=", "starwave-timing")
	var output_path := _arg("--out=", "")
	era_policy = "synergy"
	declared_seed = 1104
	random_inputs.seed = declared_seed
	project_number = 0
	release_band = "early"
	store_arm = "none"
	neon_policy = false
	max_games = 5
	action_limit = 160
	era_cap = 0
	first_store_cycle = 0
	var out := {"cohort": cohort, "policy": era_policy, "seed": declared_seed,
		"foundation": {}, "starwave_chain": {}, "starwave_checkpoint": {},
		"arms": [], "errors": [], "valid": false}
	if output_path.is_empty() or cohort != "starwave-timing":
		out.errors.append("Invalid output path or undeclared cohort")
	else:
		var prepared: Dictionary = await _prepare_starwave(out)
		if prepared.is_empty():
			out.errors.append("Legal post-Neon Starwave-profile checkpoint failed")
		else:
			var reference_cycle := -1
			for spec: Dictionary in ARM_SPECS:
				var arm: Dictionary = await _run_shadow_arm(prepared.checkpoint, spec, reference_cycle)
				out.arms.append(arm)
				if spec.mode == "delay_only" and bool(arm.get("success", false)):
					reference_cycle = int(arm.game4_launch.cycle)
				if not bool(arm.get("success", false)):
					out.errors.append("Arm failed: " + spec.mode + ": " + str(arm.get("errors", [])))
			out["reference_cycle"] = reference_cycle
			out.valid = out.errors.is_empty() and out.arms.size() == ARM_SPECS.size()
	if not output_path.is_empty():
		var file := FileAccess.open(output_path, FileAccess.WRITE)
		if file == null:
			push_error("Could not write " + output_path)
			quit(1)
			return
		file.store_string(JSON.stringify(out))
		file.close()
	print("STARWAVE_TIMING_V10 ", cohort, " valid=", out.valid,
		" arms=", out.arms.size(), " errors=", out.errors)
	quit(0 if out.valid else 1)


func _prepare_starwave(overall: Dictionary) -> Dictionary:
	var prepared: Dictionary = await super._prepare("lease", 2, overall)
	if prepared.is_empty(): return {}
	var adapter := StudioCheckpoint.new()
	var run: RunState = adapter.hydrate(prepared.checkpoint)
	if run == null:
		overall.errors.append("Game-2 checkpoint hydrate: " + adapter.error)
		return {}
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	game.run_state = run
	root.add_child(game)
	await process_frame
	project_number = 2
	random_inputs.seed = declared_seed
	var history := {"actions": [], "releases": [], "errors": [], "blockers": [],
		"before_crown": _state(game), "stop": ""}
	var crown_id := _pending_id(run, PublisherCatalog.CROWN_QUILL)
	if crown_id.is_empty() or not await _trial_contract(game, crown_id, history):
		history.stop = "legal Crown completion"
	else:
		history["after_crown"] = _state(game)
		if not _begin_game(game, "Native game 3", &"action", history):
			history.stop = "Game-3 departure"
		elif not await _develop_game(game, era_policy, "mixed", "qa", declared_seed + 1000000, 3, history):
			history.stop = "Game-3 development"
		else:
			var game3_id: StringName = game.project_state.get_release_id()
			history["game3_launch"] = _release(game.project_state, run)
			history["game3_promotion"] = run.get_release_promotion(game3_id)
			var neon_id := _pending_id(run, PublisherCatalog.NEON_CIRCUIT)
			if neon_id.is_empty() or not await _trial_contract(game, neon_id, history):
				history.stop = "legal Neon completion"
			else:
				history["after_neon"] = _state(game)
				history["pending_promotion"] = run.get_pending_promotion_awards()
				history["unlocked"] = run.get_unlocked_publisher_ids()
				history["completed_contracts"] = run.get_completed_contract_count()
				history["pending_offers"] = run.get_pending_publisher_offer_ids()
	var result := {}
	if history.stop.is_empty() and game._active_phase is StudioPhase:
		var starwave := run.get_publisher_status(PublisherCatalog.STARWAVE)
		if run.get_released_game_ids().size() != 3 or run.get_completed_contract_count() != 3 or not bool(starwave.get("unlocked", false)) or run.get_pending_promotion() != 18 or not run.get_pending_publisher_offer_ids().is_empty():
			history.errors.append("Expected three releases/contracts, Starwave profile only, and Neon 18 pending")
		else:
			var checkpoint := adapter.capture(run)
			if checkpoint.is_empty(): history.errors.append("Post-Neon checkpoint: " + adapter.error)
			else:
				overall["starwave_checkpoint"] = checkpoint
				result = {"checkpoint": checkpoint}
	overall["starwave_chain"] = history
	game.queue_free()
	await process_frame
	await process_frame
	return result


func _run_shadow_arm(checkpoint: Dictionary, spec: Dictionary, reference_cycle: int) -> Dictionary:
	var out := {"mode": spec.mode, "spec": spec.duplicate(true), "actions": [],
		"releases": [], "errors": [], "blockers": [], "placeholders": [], "success": false}
	var adapter := StudioCheckpoint.new()
	var run: RunState = adapter.hydrate(checkpoint)
	if run == null:
		out.errors.append("Post-Neon hydration: " + adapter.error)
		return out
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	game.run_state = run
	root.add_child(game)
	await process_frame
	project_number = 3
	random_inputs.seed = declared_seed
	out["before"] = _shadow_endpoint(game, &"")
	if not game._active_phase is StudioPhase or run.get_completed_contract_count() != 3 or PublisherCatalog.STARWAVE not in run.get_unlocked_publisher_ids() or run.get_pending_promotion() != 18:
		out.errors.append("Hydrated post-Neon state mismatch")
	if out.errors.is_empty() and int(spec.cycles) == 3:
		for index in range(3):
			var before := _shadow_endpoint(game, &"")
			var receipt := int(spec.cash_cents) if index == 2 else 0
			var expected_cycle := run.get_completed_run_cycles()
			var kind := &"publisher_receipt" if receipt > 0 else &"contract_hand"
			var succeeded := run.complete_productive_action(Callable(), receipt, expected_cycle, &"", kind, SHADOW_ID)
			out.placeholders.append({"number": index + 1, "before": before,
				"after": _shadow_endpoint(game, &""), "receipt_cents": receipt,
				"success": succeeded, "analysis_only": true})
			if not succeeded:
				out.errors.append("Analysis-only productive-cycle placeholder rejected: " + str(index + 1))
				break
		if out.errors.is_empty() and int(spec.extra_promotion) > 0:
			if run._promotion_awards.has(SHADOW_ID) or run._promotion_consumed.has(SHADOW_ID):
				out.errors.append("Synthetic Promotion identity collision")
			else:
				run._promotion_awards[SHADOW_ID] = int(spec.extra_promotion)
		out["after_placeholders"] = _shadow_endpoint(game, &"")
	if out.errors.is_empty():
		if not _begin_game(game, "Native game 4", &"action", out):
			out.errors.append("Game-4 departure blocked")
		elif not await _develop_game(game, era_policy, "mixed", "qa", declared_seed + 1500000, 4, out):
			out.errors.append("Game-4 development blocked")
		else:
			var game4_id: StringName = game.project_state.get_release_id()
			out["game4_launch"] = _release(game.project_state, run)
			out["game4_promotion"] = run.get_release_promotion(game4_id)
			out["game4_consumed_awards"] = run._promotion_consumed.duplicate(true)
			if reference_cycle < 0: reference_cycle = int(out.game4_launch.cycle)
			if int(out.game4_launch.cycle) > reference_cycle:
				out.errors.append("Game-4 launch later than declared reference")
			else:
				run.calendar_changed.connect(_capture_shadow_calendar.bind(game, reference_cycle, game4_id, out))
				if int(out.game4_launch.cycle) == reference_cycle:
					out["matched_L"] = _shadow_endpoint(game, game4_id)
				if not _begin_game(game, "Native game 5", &"action", out):
					out.errors.append("Game-5 departure blocked before endpoint")
				else:
					out["game5_development_completed"] = await _develop_game(game, era_policy, "mixed", "qa", declared_seed + 2000000, 5, out)
				if not out.has("matched_L") or not out.has("cycle_plus_2") or not out.has("cycle_plus_4"):
					out.errors.append("Missing matched-calendar endpoint")
				out["after"] = _shadow_endpoint(game, game4_id)
				out["ledger_valid"] = StudioFinanceLedger._is_valid(run._studio_finance)
				if not out.ledger_valid: out.errors.append("Finance ledger invalid")
	out.success = out.errors.is_empty()
	game.queue_free()
	await process_frame
	await process_frame
	return out


func _capture_shadow_calendar(game: Control, reference_cycle: int, game4_id: StringName, out: Dictionary) -> void:
	var cycle: int = game.run_state.get_completed_run_cycles()
	if cycle not in [reference_cycle, reference_cycle + 2, reference_cycle + 4]: return
	var key := "matched_L" if cycle == reference_cycle else "cycle_plus_2" if cycle == reference_cycle + 2 else "cycle_plus_4"
	out[key] = _shadow_endpoint(game, game4_id)


func _shadow_endpoint(game: Control, game4_id: StringName) -> Dictionary:
	var run: RunState = game.run_state
	var sales := {}
	var portfolio_settled := 0
	for id: StringName in run.get_released_game_ids():
		var record: Dictionary = run.get_released_game_sales(id)
		sales[id] = record
		portfolio_settled += int(record.get("settled_cents", 0))
	return {"cycle": run.get_completed_run_cycles(), "state": _state(game),
		"cash_cents": run.get_cash_cents(), "portfolio_settled_cents": portfolio_settled,
		"sales": sales, "game4_sales": run.get_released_game_sales(game4_id) if not game4_id.is_empty() else {},
		"pending_promotion_awards": run.get_pending_promotion_awards(),
		"pending_promotion": run.get_pending_promotion(),
		"completed_contracts": run.get_completed_contract_count(),
		"unlocked": run.get_unlocked_publisher_ids(),
		"finance": run.get_studio_finance_report(),
		"finance_snapshot": run.get_studio_finance_snapshot(),
		"finance_valid": StudioFinanceLedger._is_valid(run._studio_finance)}
