## Analysis only: two genuine native continuations from one frozen payload.
extends "res://scripts/debug/cross_specialty_base.gd"

const ENDPOINTS := [75, 77, 79]

func _run() -> void:
	var specialty := StringName(_arg("--specialty=", "action"))
	declared_seed = int(_arg("--seed=", "1104"))
	var arm := _arg("--arm=", "")
	var input_path := _arg("--input=", "")
	var output_path := _arg("--out=", "")
	era_policy = "synergy"
	release_band = "early"
	project_number = 3
	store_arm = "none"
	neon_policy = false
	random_inputs.seed = declared_seed
	var out: Dictionary = {"arm": arm, "specialty": str(specialty), "seed": declared_seed,
		"input_path": input_path, "input_sha256": FileAccess.get_sha256(input_path),
		"policy": era_policy, "game4_seed": declared_seed + 1500000,
		"game5_seed": declared_seed + 2000000, "actions": [], "releases": [],
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
				design._deal_rng.seed = declared_seed + 2000001
				design._finalization_rng.seed = declared_seed + 2000002
				if not design.get_workspace().overlay.commit_draft():
					out.stop = "Game-5 initial priority commit rejected"
				else:
					var hand := 0
					while run.get_completed_run_cycles() < 79 and out.stop.is_empty():
						phase_for_choice = design
						if not _production_hand(design, game.project_state, run, era_policy, "mixed", "design", 5, out):
							out.stop = "Game-5 Design hand %d stopped" % (hand + 1)
							break
						if hand == 0:
							var before_priority := _state(game)
							var changed := design.commit_priority_distribution(_core_adjustment())
							out.actions.append({"phase": "design_priority", "game": 5,
								"success": changed, "before": before_priority, "after": _state(game)})
							if not changed:
								out.stop = "Game-5 priority change rejected"
						_capture_endpoint(game, out)
						hand += 1
					out.game5_hands = hand
	out.final = _endpoint(game)
	out.ledger_valid = StudioFinanceLedger._is_valid(run._studio_finance)
	out.remaining_starwave_offer = not pending_for(run, PublisherCatalog.STARWAVE).is_empty()
	out.first_blocked_action = out.blockers[0] if not out.blockers.is_empty() else ""
	out.valid = out.stop.is_empty() and out.ledger_valid and out.initial_typed_parity and out.endpoints.size() == 3
	if out.valid and ((arm == "skip" and not out.remaining_starwave_offer) or (arm == "starwave" and out.remaining_starwave_offer)):
		out.stop = "Starwave offer identity did not match arm"
		out.valid = false
	_write_result(output_path, out)
	print("MATCHED CONTINUATION ", specialty, " ", arm, " valid=", out.valid,
		" stop=", out.stop, " endpoints=", out.endpoints.keys())
	game.queue_free()
	await process_frame
	quit(0 if out.valid else 1)

func _capture_endpoint(game: Control, out: Dictionary) -> void:
	var cycle := game.run_state.get_completed_run_cycles()
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
