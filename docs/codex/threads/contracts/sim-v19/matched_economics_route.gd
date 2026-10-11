## Analysis only. Two independently initialized native strategies to matched cycles.
extends "res://scripts/debug/starter_buy_base.gd"

const ENDPOINTS := [93, 95, 97]

func _run() -> void:
	declared_seed = int(_arg("--seed=", "1104"))
	var specialty := StringName(_arg("--specialty=", ""))
	var arm := _arg("--arm=", "")
	var directory := _arg("--directory=", "")
	random_inputs.seed = declared_seed
	era_policy = "synergy"
	release_band = "early"
	project_number = 0
	store_arm = "none"
	neon_policy = false
	var out: Dictionary = {"source": "native-v3", "seed": declared_seed, "specialty": str(specialty),
		"project_genre": str(specialty), "arm": arm, "contract_deal_seed": 31104,
		"policy": era_policy, "first_release_band": "early", "later_release_band": "slow",
		"traits": ["lean_production", "studio_buzz", "expensive_lease"],
		"actions": [], "releases": [], "cycles": [], "endpoints": {}, "purchases": [],
		"starter_offers": [], "spent_cents": 0, "errors": [], "blockers": [],
		"stop": "", "valid": false, "starwave_completed": false}
	if declared_seed != 1104 or specialty not in [&"adventure", &"role_playing", &"strategy", &"simulation"] or arm not in ["buy_chain", "no_buy"]:
		out.stop = "undeclared input"
		_write(directory, out)
		quit(2)
		return
	var run := RunState.new()
	run.initialize_cash(0)
	run.create_studio_with_traits("Starwave specialty screen", specialty,
		[&"lean_production", &"studio_buzz", &"expensive_lease"])
	run.random_streams.stream(&"contract_deal").seed = 31104
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	game.run_state = run
	root.add_child(game)
	await process_frame
	run.calendar_changed.connect(func(): out.cycles.append(_state(game)))
	out.initial = _state(game)
	out.before_purchase_owned_ids = run.get_owned_feature_ids()
	out.before_purchase_cash_cents = run.get_cash_cents()
	if arm == "buy_chain" and not _buy_starters(run, out):
		out.stop = "starter purchase rejected"
	out.initial_owned_ids = run.get_owned_feature_ids()
	out.starter_summary = run.get_starter_pool_summary()
	for number in range(1, 4):
		if not out.stop.is_empty(): break
		if not _begin_game(game, "Starwave foundation %d" % number, specialty, out):
			out.stop = "game %d departure" % number
			break
		if not await _develop_game(game, era_policy, "mixed", "qa", declared_seed + (number - 1) * 500000, number, out):
			out.stop = "game %d development" % number
			break
		out.releases.append(_release(game.project_state, run))
		if number == 1:
			if not await _trial_contract(game, ContractState.CONTRACT_ID, out):
				out.stop = "Ironclad"
				break
		elif number == 2:
			var loan := run.get_bank_quote(50000, 12)
			out.loan_quote = loan
			out.loan_accepted = run.accept_bank_loan(loan) if loan.get("accepted", false) else false
			out.hired = run.hire_production_specialist(run.get_production_hire_quote())
			if arm == "buy_chain":
				var crown := pending_for(run, PublisherCatalog.CROWN_QUILL)
				if crown.is_empty():
					out.stop = "no earned Crown offer"
					break
				if not await _trial_contract(game, crown, out):
					out.stop = "Crown hand"
					break
			else:
				out.prefix = _prefix(game, out)
		else:
			if arm == "buy_chain":
				var neon := pending_for(run, PublisherCatalog.NEON_CIRCUIT)
				if neon.is_empty():
					out.stop = "no earned Neon offer"
					break
				if not await _trial_contract(game, neon, out):
					out.stop = "Neon hand"
					break
	if out.stop.is_empty():
		if not out.get("loan_accepted", false):
			var late_loan := run.get_bank_quote(50000, 12)
			out.late_loan_quote = late_loan
			out.late_loan_accepted = run.accept_bank_loan(late_loan) if late_loan.get("accepted", false) else false
		out.foundation_contract_count = run.get_completed_contract_count()
		out.foundation_release_ids = run.get_released_game_ids()
		out.offer_earned = not pending_for(run, PublisherCatalog.STARWAVE).is_empty()
		if arm == "buy_chain":
			var starwave := pending_for(run, PublisherCatalog.STARWAVE)
			if starwave.is_empty():
				out.stop = "no earned Starwave offer"
			else:
				out.before_starwave = _state(game)
				out.frozen_pool = run._primitive_contract_eligible_ids()
				if not await _trial_contract(game, starwave, out):
					out.stop = "Starwave hand"
				else:
					out.starwave_completed = true
					out.after_starwave = _state(game)
					out.prefix = _prefix(game, out)
		else:
			out.no_buy_after_game3 = _endpoint(game)
	if out.stop.is_empty():
		for number in range(4, 6):
			if not _begin_game(game, "Matched Game %d" % number, specialty, out):
				out.stop = "game %d departure" % number
				break
			if not await _develop_game(game, era_policy, "mixed", "qa", declared_seed + (number - 1) * 500000, number, out):
				out.stop = "game %d development" % number
				break
			out.releases.append(_release(game.project_state, run))
			out["game%d_launch" % number] = _endpoint(game)
			_capture_endpoint(game, out)
			var expected := (75 if arm == "buy_chain" else 68) if number == 4 else (93 if arm == "buy_chain" else 86)
			if run.get_completed_run_cycles() != expected:
				out.stop = "game %d launch at unexpected cycle %d" % [number, run.get_completed_run_cycles()]
				break
	if out.stop.is_empty() and not await _game6_to_97(game, specialty, out):
		out.stop = "Game 6 continuation"
	out.final = _endpoint(game)
	out.ledger_valid = StudioFinanceLedger._is_valid(run._studio_finance)
	out.first_blocked_action = out.blockers[0] if not out.blockers.is_empty() else ""
	out.valid = out.stop.is_empty() and out.ledger_valid and out.endpoints.size() == 3 and out.releases.size() == 5
	_write(directory, out)
	print("MATCHED ECONOMICS ", specialty, " ", arm, " valid=", out.valid, " stop=", out.stop, " endpoints=", out.endpoints.keys())
	game.queue_free()
	await process_frame
	quit(0 if out.valid else 1)

func _prefix(game: Control, out: Dictionary) -> Dictionary:
	return {"actions": out.actions.duplicate(true), "releases": out.releases.duplicate(true),
		"cycles": out.cycles.duplicate(true), "state": _state(game),
		"finance": game.run_state.get_studio_finance_snapshot(),
		"owned_ids": game.run_state.get_owned_feature_ids(),
		"rng": game.run_state.random_streams.snapshot()}

func _game6_to_97(game: Control, specialty: StringName, out: Dictionary) -> bool:
	var run: RunState = game.run_state
	if not _begin_game(game, "Matched Game 6", specialty, out):
		out.blockers.append("Game 6 departure rejected")
		return false
	_capture_endpoint(game, out)
	if not game._active_phase is DesignPhase: return false
	var project: ProjectState = game.project_state
	var design: DesignPhase = game._active_phase
	var seed_value := declared_seed + 2500000
	design._deal_rng.seed = seed_value + 3
	design._finalization_rng.seed = seed_value + 4
	if design.is_initial_priority_planning():
		design.set_priority_distribution(_priorities(project))
		if not design.get_workspace().overlay.commit_draft(): return false
	var design_hands := 0
	while run.get_completed_run_cycles() < 97 and design_hands < 6:
		phase_for_choice = design
		if not _production_hand(design, project, run, era_policy, "mixed", "design", 6, out):
			out.blockers.append("Game 6 Design hand rejected")
			return false
		design_hands += 1
		_capture_endpoint(game, out)
	if run.get_completed_run_cycles() < 97:
		design.call("_on_proceed_to_alpha_pressed")
		if not game._active_phase is AlphaPhase: return false
		var alpha: AlphaPhase = game._active_phase
		if alpha.is_initial_priority_planning():
			alpha._deal_rng.seed = seed_value + 3
			alpha._finalization_rng.seed = seed_value + 4
			alpha.set_priority_distribution(_priorities(project))
			if not alpha.get_workspace().overlay.commit_draft(): return false
		var alpha_hands := 0
		while run.get_completed_run_cycles() < 97 and alpha_hands < 6:
			phase_for_choice = alpha
			if not _production_hand(alpha, project, run, era_policy, "mixed", "alpha", 6, out):
				out.blockers.append("Game 6 Alpha hand rejected")
				return false
			alpha_hands += 1
			_capture_endpoint(game, out)
	out.game6_design_hands = design_hands
	out.game6_alpha_hands = int(out.actions.filter(func(a: Dictionary): return a.get("phase") == "alpha" and a.get("game") == 6).size())
	return run.get_completed_run_cycles() == 97

func _capture_endpoint(game: Control, out: Dictionary) -> void:
	var cycle: int = game.run_state.get_completed_run_cycles()
	if cycle in ENDPOINTS: out.endpoints[str(cycle)] = _endpoint(game)

func _endpoint(game: Control) -> Dictionary:
	var run: RunState = game.run_state
	var sales: Dictionary = {}
	var settled := 0
	var entitled := 0
	for id: StringName in run.get_released_game_ids():
		var record: Dictionary = run.get_released_game_sales(id)
		sales[str(id)] = record
		settled += int(record.get("settled_cents", 0))
		entitled += int(record.get("entitlement_cents", 0))
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
		"sales": sales, "portfolio_settled_cents": settled, "portfolio_entitlement_cents": entitled,
		"finance": run.get_studio_finance_snapshot(), "finance_report": run.get_studio_finance_report(),
		"finance_valid": StudioFinanceLedger._is_valid(run._studio_finance), "rng": run.random_streams.snapshot()}

func _write(directory: String, result: Dictionary) -> void:
	var file := FileAccess.open(directory.path_join("native-route.json"), FileAccess.WRITE)
	if file == null: push_error("Cannot write native matched route")
	else: file.store_string(JSON.stringify(result))
