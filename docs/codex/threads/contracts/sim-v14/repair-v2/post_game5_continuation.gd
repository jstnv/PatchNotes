## Analysis only: replay v13 exactly, then continue Game 5 and its settlements.
extends "res://scripts/debug/cross_specialty_base.gd"

const ENDPOINTS := [75, 77, 79, 94, 96, 98]

func _run() -> void:
	var specialty := StringName(_arg("--specialty=", "action"))
	declared_seed = int(_arg("--seed=", "1104"))
	var arm := _arg("--arm=", "")
	var input_path := _arg("--input=", "")
	var reference_path := _arg("--reference=", "")
	var output_path := _arg("--out=", "")
	era_policy = "synergy"
	release_band = "early"
	project_number = 3
	store_arm = "none"
	neon_policy = false
	random_inputs.seed = declared_seed
	var out: Dictionary = {"arm": arm, "specialty": str(specialty), "seed": declared_seed,
		"input_path": input_path, "input_sha256": FileAccess.get_sha256(input_path),
		"reference_path": reference_path, "reference_sha256": FileAccess.get_sha256(reference_path),
		"policy": era_policy, "game4_seed": declared_seed + 1500000,
		"game5_seed": declared_seed + 2000000, "game6_seed": declared_seed + 2500000,
		"actions": [], "releases": [], "game5_phase_counts": {"design": 0, "alpha": 0, "beta": 0},
		"v13_parity": {},
		"errors": [], "blockers": [], "endpoints": {}, "stop": "", "valid": false}
	if arm not in ["starwave", "skip"] or specialty not in [&"action", &"puzzle", &"racing"]:
		out.stop = "undeclared arm or specialty"
		_write_result(output_path, out)
		quit(1)
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(input_path))
	if not parsed is Dictionary:
		out.stop = "checkpoint JSON missing or invalid"
		_write_result(output_path, out)
		quit(1)
		return
	var payload: Dictionary = parsed
	var adapter := StudioCheckpoint.new()
	var run: RunState = adapter.hydrate(payload)
	if run == null:
		out.stop = "checkpoint hydration: " + adapter.error
		_write_result(output_path, out)
		quit(1)
		return
	out.initial_checkpoint = adapter.capture(run)
	out.initial_typed_parity = out.initial_checkpoint == payload
	if not out.initial_typed_parity:
		out.stop = "initial typed checkpoint differs after hydration"
		_write_result(output_path, out)
		quit(1)
		return
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	game.run_state = run
	root.add_child(game)
	await process_frame
	out.before = _endpoint(game)
	out.initial_rng = run.random_streams.snapshot()
	var starwave := pending_for(run, PublisherCatalog.STARWAVE)
	if not game._active_phase is StudioPhase or run.get_completed_run_cycles() != 54:
		out.stop = "hydrated state is not cycle-54 Studio"
	elif run.get_released_game_ids().size() != 3 or run.get_completed_contract_count() != 3 or starwave.is_empty():
		out.stop = "hydrated foundation lacks three releases/contracts and earned offer"
	if out.stop.is_empty() and arm == "starwave":
		if not await _trial_contract(game, starwave, out):
			out.stop = "native Starwave contract stopped"
		else:
			out.after_starwave = _endpoint(game)
			out.starwave_result = out.actions[-1].result
			out.starwave_hands = out.actions[-1].hands
	if out.stop.is_empty():
		var expected_start_cycle := 57 if arm == "starwave" else 54
		if run.get_completed_run_cycles() != expected_start_cycle:
			out.stop = "unexpected Game-4 start cycle"
	if out.stop.is_empty():
		if not _begin_game(game, "Matched Game 4", specialty, out):
			out.stop = "Game-4 departure rejected"
		elif not await _develop_game(game, era_policy, "mixed", "qa", declared_seed + 1500000, 4, out):
			out.stop = "Game-4 development stopped"
		else:
			out.releases.append(_release(game.project_state, run))
			out.game4_launch = _endpoint(game)
			out.game4_release_id = str(game.project_state.get_release_id())
			out.game4_promotion = run.get_release_promotion(game.project_state.get_release_id())
			_capture_endpoint(game, out)
			var expected_launch := 75 if arm == "starwave" else 72
			if run.get_completed_run_cycles() != expected_launch:
				out.stop = "Game-4 launch not at declared cycle %d" % expected_launch
	if out.stop.is_empty():
		if not _begin_game(game, "Matched Game 5", specialty, out):
			out.stop = "Game-5 departure rejected"
		else:
			_capture_endpoint(game, out)
			if not game._active_phase is DesignPhase:
				out.stop = "Game-5 Design phase absent"
			else:
				var design: DesignPhase = game._active_phase
				design._deal_rng.seed = declared_seed + 2000003
				design._finalization_rng.seed = declared_seed + 2000004
				var priority_ready := true
				if design.is_initial_priority_planning():
					design.set_priority_distribution(_priorities(game.project_state))
					priority_ready = design.get_workspace().overlay.commit_draft()
				if not priority_ready:
					out.stop = "Game-5 initial priority commit rejected"
				else:
					var hand := 0
					while run.get_completed_run_cycles() < 79 and out.stop.is_empty():
						phase_for_choice = design
						if not _production_hand(design, game.project_state, run, era_policy, "mixed", "design", 5, out):
							out.stop = "Game-5 Design hand %d stopped" % (hand + 1)
							break
						_capture_endpoint(game, out)
						hand += 1
					out.game5_hands = hand
	if out.stop.is_empty():
		out.v13_parity = _compare_v13(out, reference_path)
		if not out.v13_parity.get("matched", false):
			out.stop = "v13 cycle-79 replay parity mismatch"
	if out.stop.is_empty():
		if not await _finish_game5(game, out):
			out.stop = "Game-5 completion stopped"
	if out.stop.is_empty():
		if not await _game6_to_endpoint(game, specialty, out):
			out.stop = "Game-6 continuation stopped"
	out.final = _endpoint(game)
	out.ledger_valid = StudioFinanceLedger._is_valid(run._studio_finance)
	out.remaining_starwave_offer = not pending_for(run, PublisherCatalog.STARWAVE).is_empty()
	out.first_blocked_action = out.blockers[0] if not out.blockers.is_empty() else ""
	out.valid = out.stop.is_empty() and out.ledger_valid and out.initial_typed_parity and out.endpoints.size() == 6
	if out.valid and ((arm == "skip" and not out.remaining_starwave_offer) or (arm == "starwave" and out.remaining_starwave_offer)):
		out.stop = "Starwave offer identity did not match arm"
		out.valid = false
	_write_result(output_path, out)
	print("MATCHED CONTINUATION ", specialty, " ", arm, " valid=", out.valid,
		" stop=", out.stop, " endpoints=", out.endpoints.keys())
	game.queue_free()
	await process_frame
	quit(0 if out.valid else 1)

func _compare_v13(out: Dictionary, reference_path: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(reference_path))
	if not parsed is Dictionary:
		return {"matched": false, "reason": "v13 reference absent or invalid"}
	var reference: Dictionary = parsed
	var checks: Dictionary = {"valid": reference.get("valid", false),
		"initial_checkpoint": out.initial_checkpoint == reference.get("initial_checkpoint"),
		"initial_rng": out.initial_rng == reference.get("initial_rng"),
		"before": out.before == reference.get("before"),
		"game4_launch": out.game4_launch == reference.get("game4_launch"),
		"game4_release_id": out.game4_release_id == reference.get("game4_release_id"),
		"game4_promotion": out.game4_promotion == reference.get("game4_promotion"),
		"releases": out.releases == reference.get("releases"),
		"actions": out.actions == reference.get("actions")}
	if out.arm == "starwave":
		checks["starwave_result"] = out.starwave_result == reference.get("starwave_result")
		checks["starwave_hands"] = out.starwave_hands == reference.get("starwave_hands")
	for cycle in [75, 77, 79]:
		checks["endpoint_%d" % cycle] = out.endpoints.get(str(cycle)) == reference.endpoints.get(str(cycle))
	var matched := true
	for value in checks.values():
		if value != true:
			matched = false
	return {"matched": matched, "checks": checks}

func _finish_game5(game: Control, out: Dictionary) -> bool:
	var run: RunState = game.run_state
	var project: ProjectState = game.project_state
	var seed_value: int = declared_seed + 2000000
	var design: DesignPhase = game._active_phase
	var already: int = int(out.get("game5_hands", 0))
	out.game5_phase_counts.design = already
	if already > 6 or already < 0:
		out.blockers.append({"phase": "Game-5 Design", "reason": "invalid v13 hand count", "hands": already})
		return false
	for hand in range(already, 6):
		phase_for_choice = design
		if not _production_hand(design, project, run, era_policy, "mixed", "design", 5, out):
			out.blockers.append({"phase": "Game-5 Design", "hand": hand + 1, "reason": "native hand rejected"})
			return false
		out.game5_phase_counts.design = hand + 1
		_capture_endpoint(game, out)
	design.call("_on_proceed_to_alpha_pressed")
	if not game._active_phase is AlphaPhase:
		out.blockers.append({"phase": "Game-5 transition", "reason": "Alpha absent"})
		return false
	var alpha: AlphaPhase = game._active_phase
	if alpha.is_initial_priority_planning():
		alpha._deal_rng.seed = seed_value + 3
		alpha._finalization_rng.seed = seed_value + 4
		alpha.set_priority_distribution(_priorities(project))
		if not alpha.get_workspace().overlay.commit_draft():
			out.blockers.append({"phase": "Game-5 Alpha", "reason": "initial priorities rejected"})
			return false
	for hand in range(6):
		phase_for_choice = alpha
		if not _production_hand(alpha, project, run, era_policy, "mixed", "alpha", 5, out):
			out.blockers.append({"phase": "Game-5 Alpha", "hand": hand + 1, "reason": "native hand rejected"})
			return false
		out.game5_phase_counts.alpha = hand + 1
		_capture_endpoint(game, out)
	alpha.request_proceed_to_beta()
	if alpha.get_node("%UnderScopeDialog").visible:
		alpha.get_node("%UnderScopeDialog").confirmed.emit()
	if not game._active_phase is BetaPhase:
		out.blockers.append({"phase": "Game-5 transition", "reason": "Beta absent"})
		return false
	var beta: BetaPhase = game._active_phase
	beta._deal_rng.seed = seed_value + 5
	beta._insight_rng.seed = seed_value + 6
	beta.set_priority_distribution(_beta_priorities("qa"))
	if not beta.get_workspace().overlay.commit_draft():
		out.blockers.append({"phase": "Game-5 Beta", "reason": "initial priorities rejected"})
		return false
	for hand in range(6):
		if not await _beta_hand(beta, project, run, era_policy, "qa", 5, out):
			out.blockers.append({"phase": "Game-5 Beta", "hand": hand + 1, "reason": "native hand rejected"})
			return false
		out.game5_phase_counts.beta = hand + 1
		_capture_endpoint(game, out)
	game.set("_controlled_review_roll", -1)
	game.get("_review_rng").seed = seed_value + 7
	var before := _state(game)
	var launched := beta.request_launch()
	if not launched:
		launched = beta.confirm_launch_for_verification()
	out.actions.append({"phase": "launch", "game": 5, "success": launched,
		"budget_curtailed": false, "before": before, "after": _state(game)})
	if not launched or not game._active_phase is StudioPhase:
		out.blockers.append({"phase": "Game-5 launch", "reason": "native launch rejected"})
		return false
	out.releases.append(_release(project, run))
	out.game5_launch = _endpoint(game)
	out.game5_release_id = str(project.get_release_id())
	out.game5_promotion = run.get_release_promotion(project.get_release_id())
	_capture_endpoint(game, out)
	var expected: int = 94 if out.arm == "starwave" else 91
	if run.get_completed_run_cycles() != expected:
		out.blockers.append({"phase": "Game-5 launch", "reason": "unexpected cycle", "expected": expected,
			"actual": run.get_completed_run_cycles()})
		return false
	return true

func _game6_to_endpoint(game: Control, specialty: StringName, out: Dictionary) -> bool:
	var run: RunState = game.run_state
	if not _begin_game(game, "Matched Game 6", specialty, out):
		out.blockers.append({"phase": "Game-6 departure", "reason": "native departure rejected"})
		return false
	_capture_endpoint(game, out)
	if not game._active_phase is DesignPhase:
		out.blockers.append({"phase": "Game-6 Design", "reason": "phase absent"})
		return false
	var design: DesignPhase = game._active_phase
	var project: ProjectState = game.project_state
	var seed_value: int = declared_seed + 2500000
	design._deal_rng.seed = seed_value + 3
	design._finalization_rng.seed = seed_value + 4
	var priority_ready := true
	if design.is_initial_priority_planning():
		design.set_priority_distribution(_priorities(project))
		priority_ready = design.get_workspace().overlay.commit_draft()
	if not priority_ready:
		out.blockers.append({"phase": "Game-6 Design", "reason": "initial priorities rejected"})
		return false
	out.game6_hands = 0
	while run.get_completed_run_cycles() < 98:
		phase_for_choice = design
		if not _production_hand(design, project, run, era_policy, "mixed", "design", 6, out):
			out.blockers.append({"phase": "Game-6 Design", "hand": int(out.game6_hands) + 1,
				"reason": "native hand rejected"})
			return false
		out.game6_hands = int(out.game6_hands) + 1
		_capture_endpoint(game, out)
	return true

func _capture_endpoint(game: Control, out: Dictionary) -> void:
	var cycle: int = game.run_state.get_completed_run_cycles()
	if cycle in ENDPOINTS:
		out.endpoints[str(cycle)] = _endpoint(game)

func _endpoint(game: Control) -> Dictionary:
	var run: RunState = game.run_state
	var sales: Dictionary = {}
	var settled := 0
	for id: StringName in run.get_released_game_ids():
		var record: Dictionary = run.get_released_game_sales(id)
		sales[str(id)] = record
		settled += int(record.get("settled_cents", 0))
	var project: ProjectState = game.project_state
	return {"cycle": run.get_completed_run_cycles(), "cash_cents": run.get_cash_cents(),
		"state": _state(game), "project_release_id": str(project.get_release_id()) if project != null else "",
		"project_cycle": project.get_current_cycle() if project != null else -1,
		"project_scope": project.get_current_scope() if project != null else 0,
		"project_cores": _cores(project),
		"released_ids": run.get_released_game_ids(), "completed_contracts": run.get_completed_contract_count(),
		"pending_offers": run.get_pending_publisher_offer_ids(),
		"pending_promotion_awards": run.get_pending_promotion_awards(),
		"promotion_consumed": run._promotion_consumed.duplicate(true),
		"fans": run.get_fans(), "fanbase": run.get_fanbase_snapshot(),
		"sales": sales, "portfolio_settled_cents": settled,
		"finance": run.get_studio_finance_snapshot(), "finance_report": run.get_studio_finance_report(),
		"finance_valid": StudioFinanceLedger._is_valid(run._studio_finance),
		"rng": run.random_streams.snapshot()}

func _write_result(destination: String, result: Dictionary) -> void:
	if destination.is_empty():
		push_error("--out= is required")
		return
	var file := FileAccess.open(destination, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write matched result: " + destination)
		return
	file.store_string(JSON.stringify(result))
