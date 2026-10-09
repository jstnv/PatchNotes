## Bounded, native Task29 rent routes. Policies see only displayed information.
## No injected money/cards, free waits, loan, or forced launch results.
extends "res://analysis/lifespan_verify_routes_v2.gd"

var declared_seed := 1104
var release_band := "early"
var next_contract_seed := 0
var finance_observations: Array = []

func _run() -> void:
	era_policy = _arg("--policy=", "ordinary")
	release_band = _arg("--band=", "early")
	declared_seed = int(_arg("--seed=", "1104"))
	route_case = declared_seed
	project_number = 0
	max_games = 2
	action_limit = 60
	era_cap = 0
	first_store_cycle = 0
	arm = "next"
	experiment = "task29"
	random_inputs.seed = declared_seed
	var out := await _finance_route()
	var destination := "res://design-logs/task29-v1/route_%s_%s_%d.json" % [release_band, era_policy, declared_seed]
	FileAccess.open(destination, FileAccess.WRITE).store_string(JSON.stringify(out))
	print("TASK29 ", destination, " releases=", out.releases.size(), " stop=", out.stop, " discrepancies=", discrepancies.size())
	quit(0 if out.valid else 1)

func _state_for(project: ProjectState, run: RunState) -> Dictionary:
	var value := super._state_for(project, run)
	value["finance"] = run.call("get_studio_finance_snapshot") if run.has_method("get_studio_finance_snapshot") else {}
	value["finance_report"] = run.call("get_studio_finance_report") if run.has_method("get_studio_finance_report") else {}
	value["financial_block"] = run.call("get_financial_block_reason") if run.has_method("get_financial_block_reason") else "finance API unavailable"
	return value

func _capture_cycle(game: Control) -> void:
	super._capture_cycle(game)
	finance_observations.append({"cycle": game.run_state.get_completed_run_cycles(), "report": game.run_state.call("get_studio_finance_report"), "snapshot": game.run_state.call("get_studio_finance_snapshot")})

func _capture_final(game: Control, out: Dictionary) -> void:
	super._capture_final(game, out)
	if final_captures.is_empty(): return
	var capture: Dictionary = final_captures[-1]
	for key: String in ["studio_finance", "studio_finance_report"]:
		var live: Dictionary = game.run_state.call("get_studio_finance_snapshot" if key == "studio_finance" else "get_studio_finance_report")
		if capture.get(key, {}) != JSON.parse_string(JSON.stringify(live)):
			discrepancies.append({"kind": "finance capture mismatch", "field": key})

func _finance_blocked(run: RunState) -> bool:
	return not str(run.call("get_financial_block_reason")).is_empty()

func _stop(game: Control, out: Dictionary, phase: String, reason: String) -> void:
	out.stop = "financial_block" if _finance_blocked(game.run_state) else "policy_action_blocked"
	out.blockers.append({"game": project_number, "phase": phase, "reason": reason, "state": _state(game)})

func _curtail(game: Control, out: Dictionary, phase: String, hand: int) -> void:
	out.blockers.append({"game": project_number, "phase": phase, "hand": hand + 1, "reason": "Rejected production; take remaining free phase transitions and attempt legal release", "state": _state(game)})

func _finance_route() -> Dictionary:
	var out := {"seed": declared_seed, "policy": era_policy, "band": release_band, "first_release_target_cycle": 12 if release_band == "early" else 18, "specialty": "action", "actions": [], "purchases": [], "releases": [], "studio_visits": [], "errors": [], "blockers": [], "stop": "requested two-release horizon", "valid": false}
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var menu: MainMenu = game.get("_active_phase")
	menu.get_node("CenterContainer/MenuLayout/StartGame").pressed.emit()
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioName").text = "Rent Route %d" % declared_seed
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioSpecialty").select(1)
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/EnterStudio").pressed.emit()
	# Studio creation now requires one explicit background and confirmation.
	var background: OptionButton = menu.get_node("CenterContainer/MenuLayout/StudioTraits/Background")
	background.select(1)
	menu.call("_refresh_traits")
	menu.get_node("CenterContainer/MenuLayout/StudioTraits/ReviewChoices").pressed.emit()
	menu.get_node("CenterContainer/MenuLayout/CreationReview/ConfirmStudio").pressed.emit()
	var run: RunState = game.run_state
	if not run.has_method("get_studio_finance_report"):
		out.errors.append("Task29 finance API unavailable")
	else:
		run.calendar_changed.connect(_capture_cycle.bind(game))
		out["initial"] = _state(game)
		out["starter_summary"] = run.get_starter_pool_summary()
		out["owned_ids"] = run.get_owned_feature_ids()
		_visit(game, out, "initial Studio")
		for number in range(1, 3):
			if not _begin_game(game, "Rent Route Game %d" % number, &"action", out): _stop(game, out, "predevelopment", "departure rejected"); break
			if not await _develop_game(game, era_policy, "mixed", "qa", declared_seed + (number - 1) * 500000, number, out): break
			var release := _release(game.project_state, run)
			release["required_scope"] = game.project_state.get_required_scope()
			release["qualifies"] = game.project_state.get_current_scope() >= game.project_state.get_required_scope()
			out.releases.append(release)
			_visit(game, out, "committed release")
			if number == 1:
				if not await _contract(game, era_policy, declared_seed + 30000, out, "ironclad"): _stop(game, out, "ironclad", "Contract did not complete"); break
				if run.is_sidestreet_offer_available():
					if not await _contract(game, era_policy, declared_seed + 40000, out, "sidestreet_1"): _stop(game, out, "sidestreet", "Contract did not complete"); break
				out["game2_available_cash"] = _state(game)
				_visit(game, out, "before Game 2")
		if out.releases.size() == 2:
			out["second_release_checkpoint"] = _state(game)
			if _begin_game(game, "Rent Route Follow-up", &"action", out):
				await process_frame
				var phase: DesignPhase = game.get("_active_phase")
				active_project = game.project_state
				phase_for_choice = phase
				if not _production_hand(phase, game.project_state, run, era_policy, "mixed", "design", 3, out):
					_stop(game, out, "post-release follow-up", "first Game3 hand rejected before Game2 full settlement")
				else: out.stop = "two releases and two legal earning follow-up actions"
			else: _stop(game, out, "post-release follow-up", "Game3 departure rejected before Game2 first settlement")
		_capture_final(game, out)
	out["final"] = _state(game)
	out["final_finance_report"] = run.call("get_studio_finance_report") if run.has_method("get_studio_finance_report") else {}
	out["live_cycles"] = live_cycles
	out["finance_observations"] = finance_observations
	out["ledger_checks"] = ledger_checks
	out["row_checks"] = row_checks
	out["discrepancies"] = discrepancies
	out["captures"] = final_captures
	out.valid = out.errors.is_empty() and discrepancies.is_empty()
	game.queue_free()
	await process_frame
	return out

func _begin_game(game: Control, title: String, genre: StringName, out: Dictionary) -> bool:
	project_number += 1
	var seed_value := declared_seed + (project_number - 1) * 500000
	var seed_ready := func(child: Node):
		if child is DesignPhase:
			child.ready.connect(func():
				child.get("_deal_rng").seed = seed_value + 1
				child.get("_finalization_rng").seed = seed_value + 2, CONNECT_ONE_SHOT)
	game.get_node("%PhaseRoot").child_entered_tree.connect(seed_ready)
	var rolls: Array[int] = [random_inputs.randi_range(0, 99), random_inputs.randi_range(0, 99)]
	game.set("_controlled_snapshot_rolls", rolls)
	var studio: StudioPhase = game.get("_active_phase")
	studio.close_summary()
	studio.get_node("%StartNextGame").pressed.emit()
	if studio.get_node("%LowScopeWarning").visible: studio.get_node("%LowScopeWarning").confirmed.emit()
	var setup: PredevelopmentOverlay = studio.get("_predevelopment")
	if setup == null:
		game.get_node("%PhaseRoot").child_entered_tree.disconnect(seed_ready)
		return false
	setup.name_input.text = title
	for i in range(setup.genre_input.item_count):
		if setup.genre_input.get_item_metadata(i) == genre: setup.genre_input.select(i)
	var priorities := {0: 25, 1: 25, 2: 25, 3: 25}
	# Rank the actual visible Genre ratios; equal ratios keep Core display order.
	if era_policy == "synergy":
		var ratios: Array = PrimitivePredevelopment.find_entry("genres", genre).ratios
		var ranked: Array[int] = [0, 1, 2, 3]
		ranked.sort_custom(func(a: int, b: int): return ratios[a] > ratios[b] if ratios[a] != ratios[b] else a < b)
		priorities = {ranked[0]: 50, ranked[1]: 30, ranked[2]: 15, ranked[3]: 5}
	for i in range(4): setup.priority_sliders[i].value = priorities[i]
	var before := _state(game)
	setup.begin_button.pressed.emit()
	game.get_node("%PhaseRoot").child_entered_tree.disconnect(seed_ready)
	var success: bool = game.get("_active_phase") is DesignPhase and not game.get("_active_phase").is_initial_priority_planning()
	out.actions.append({"phase": "predevelopment", "game": project_number, "title": title, "genre": genre, "rolls": rolls, "priorities": priorities, "before": before, "after": _state(game), "success": success})
	return success

func _develop_game(game: Control, policy: String, focus: String, _mode: String, seed_value: int, number: int, out: Dictionary) -> bool:
	await process_frame
	var project: ProjectState = game.project_state
	var run: RunState = game.run_state
	active_project = project
	var budgets := [3, 4, 4] if release_band == "early" else [5, 6, 6]
	if number == 3 and _arg("--weak=", "none") != "none":
		budgets = [4,4,4]
	var curtailed := false
	for phase_index in range(2):
		var label := "design" if phase_index == 0 else "alpha"
		var phase: Control = game.get("_active_phase")
		if phase.is_initial_priority_planning():
			phase.get("_deal_rng").seed = seed_value + 3
			phase.get("_finalization_rng").seed = seed_value + 4
			if policy == "synergy": phase.set_priority_distribution(_priorities(project))
			if not phase.get_workspace().overlay.commit_draft(): _stop(game, out, label, "initial priorities rejected"); return false
		for hand in range(budgets[phase_index]):
			if curtailed: break
			phase_for_choice = phase
			if not _production_hand(phase, project, run, policy, focus, label, number, out):
				_stop(game,out,label,"first rejected hand; censored")
				return false
		if phase_index == 0: phase.call("_on_proceed_to_alpha_pressed")
		else:
			phase.request_proceed_to_beta()
			if phase.get_node("%UnderScopeDialog").visible: phase.get_node("%UnderScopeDialog").confirmed.emit()
		if (phase_index == 0 and not game.get("_active_phase") is AlphaPhase) or (phase_index == 1 and not game.get("_active_phase") is BetaPhase): _stop(game, out, label, "phase transition rejected"); return false
	var beta: BetaPhase = game.get("_active_phase")
	beta.get("_deal_rng").seed = seed_value + 5
	beta.get("_insight_rng").seed = seed_value + 6
	beta.set_priority_distribution(_beta_priorities("qa"))
	if not beta.get_workspace().overlay.commit_draft(): _stop(game, out, "beta", "initial priorities rejected"); return false
	for hand in range(budgets[2]):
		if curtailed: break
		if not _beta_hand(beta, project, run, policy, "qa", number, out):
			_stop(game,out,"beta","first rejected hand; censored")
			return false
	game.set("_controlled_review_roll", -1)
	game.get("_review_rng").seed = seed_value + 7
	var before := _state(game)
	var launched := beta.request_launch()
	if not launched: launched = beta.confirm_launch_for_verification()
	out.actions.append({"phase": "launch", "game": number, "success": launched, "budget_curtailed": curtailed, "before": before, "after": _state(game)})
	if not launched: _stop(game, out, "launch", "launch rejected")
	return launched and game.get("_active_phase") is StudioPhase

func _seed_contract_before_ready(node: Node) -> void:
	if not node is ContractPhase: return
	var generator := RandomNumberGenerator.new()
	generator.seed = next_contract_seed
	var cats: Array[float] = []
	var defs: Array[float] = []
	for i in range(7):
		cats.append(generator.randf())
		defs.append(generator.randf())
	var run: RunState = node.get("_run")
	if not node.setup(node.get("_state"), run, cats, defs): discrepancies.append({"kind": "Contract setup"})
	contract_initial_rolls = {"seed": next_contract_seed, "category": cats, "definition": defs}
	node.ready.connect(func():
		node.get("_rng").seed = generator.seed
		node.get("_rng").state = generator.state, CONNECT_ONE_SHOT)

func _contract(game: Control, policy: String, seed_value: int, out: Dictionary, label: String) -> bool:
	var run: RunState = game.run_state
	var before := _state(game)
	next_contract_seed = seed_value
	var studio: StudioPhase = game.get("_active_phase")
	studio.get_node("%Contracts").pressed.emit()
	var detail := studio.get_node_or_null("ContractDetail")
	if detail == null: return false
	(detail.find_child("AcceptContractButton", true, false) as Button).pressed.emit()
	if not game.get("_active_phase") is ContractPhase: return false
	var phase: ContractPhase = game.get("_active_phase")
	var state := run.get_active_contract()
	var log := {"label": label, "initial_uniform_rolls": contract_initial_rolls.duplicate(true), "before": before, "after_accept": _state(game), "hands": []}
	out.actions.append({"phase": label + " accept", "before": before, "after": _state(game), "success": true})
	await process_frame
	for hand in range(2):
		var cards := phase.get_candidate_cards()
		if cards.size() != 7: return false
		var action := {"phase": label + " hand", "hand": hand + 1, "draw": _ids(cards), "before": _state(game), "redraws": []}
		if run.get_available_redraws() > 0:
			var slot := _weakest(cards, "mixed")
			var views: Array = phase.get("_candidate_row").get_children()
			(views[slot] as CardView).input_button.pressed.emit()
			var old := str(cards[slot].id)
			var changed := phase.redraw_selected_cards()
			action.redraws.append({"slot": slot, "from": old, "success": changed})
			if not changed: (views[slot] as CardView).input_button.pressed.emit()
			else:
				cards = phase.get_candidate_cards()
				action.redraws[-1]["to"] = str(cards[slot].id)
		var indices := _choose_contract(cards, state, policy)
		var selected: Array[CardData] = []
		var views: Array = phase.get("_candidate_row").get_children()
		for slot: int in indices:
			selected.append(cards[slot])
			(views[slot] as CardView).input_button.pressed.emit()
		action["selected"] = _ids(selected)
		action["plan"] = state.plan_hand(selected)
		action["success"] = phase.call("_play_selected_hand")
		action["after"] = _state(game)
		log.hands.append(action)
		out.actions.append(action)
		if not action.success: out[label] = log; return false
	if not state.is_completed(): return false
	var result := state.get_result()
	log["completion"] = {"numerator": result.get_completion_numerator(), "scope": result.get_scope(), "payout_cents": result.get_payout_cents(), "upfront_cents": result.get_upfront_cents(), "remainder_cents": result.get_completion_payment_cents()}
	var before_dismiss := _state(game)
	(phase.get("_completion_panel").find_child("DismissCompletionButton", true, false) as Button).pressed.emit()
	log["after_dismiss"] = _state(game)
	log["dismiss_passive"] = before_dismiss == log.after_dismiss
	out[label] = log
	if not log.dismiss_passive: discrepancies.append({"kind": "Contract dismissal changed state"})
	return game.get("_active_phase") is StudioPhase and log.dismiss_passive
