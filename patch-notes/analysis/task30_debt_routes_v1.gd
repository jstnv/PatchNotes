## Analysis-only candidate startup lending. NO live bank system is installed.
## Native production/cash/rent/sales; explicit financing_in and debt payments.
extends "res://analysis/task29_routes_v1.gd"

var candidate_principal := 0
var candidate_debt: Dictionary = {}
var candidate_bank_events: Array = []
var candidate_run: RunState

func _run() -> void:
	if _arg("--projections=", "0") == "1":
		_project_profiles()
		return
	era_policy = "synergy"
	release_band = "long24"
	declared_seed = int(_arg("--seed=", "1104"))
	candidate_principal = int(_arg("--loan=", "0")) * 100
	route_case = declared_seed
	project_number = 0
	max_games = 2
	action_limit = 70
	era_cap = 0
	first_store_cycle = 0
	arm = "next"
	experiment = "task30_candidate_startup"
	random_inputs.seed = declared_seed
	var out := await _finance_route()
	out["first_release_target_cycle"] = 24
	out["candidate_only"] = true
	out["candidate_debt"] = candidate_debt
	out["candidate_bank_events"] = candidate_bank_events
	out["candidate_rule"] = "Startup exception stress offer: recurring-surplus capacity is zero; score600 fixes10% total interest/12 months; native rent first, then oldest bank installment interest before principal; bank arrears block production unless exact next native income/settlement can clear them. Not an approved or playable loan."
	var destination := "res://design-logs/task30-v1/native_%d_%d.json" % [declared_seed, candidate_principal / 100]
	FileAccess.open(destination, FileAccess.WRITE).store_string(JSON.stringify(out))
	print("TASK30 candidate ", destination, " releases=", out.releases.size(), " stop=", out.stop, " discrepancies=", discrepancies.size())
	quit(0 if out.valid else 1)

func _state_for(project: ProjectState, run: RunState) -> Dictionary:
	var state := super._state_for(project, run)
	state["candidate_bank"] = candidate_debt.duplicate(true)
	state["candidate_bank_arrears_cents"] = _bank_arrears(run.get_completed_run_cycles())
	return state

func _visit(game: Control, out: Dictionary, reason: String) -> void:
	super._visit(game, out, reason)
	if reason != "initial Studio": return
	candidate_run = game.run_state
	var before := _state(game)
	candidate_debt = {"principal_cents": candidate_principal, "total_interest_cents": candidate_principal / 10, "origination_cycle": 0, "quoted_credit": 600, "rate_percent": 10, "term_months": 12, "capacity_eligible": false, "startup_exception_trial": true, "installments": []}
	if candidate_principal > 0:
		for index in range(12):
			var principal: int = candidate_principal / 12 if index < 11 else candidate_principal - (candidate_principal / 12) * 11
			var total_interest: int = candidate_debt.total_interest_cents
			var interest: int = total_interest / 12 if index < 11 else total_interest - (total_interest / 12) * 11
			candidate_debt.installments.append({"ordinal": index + 1, "due_cycle": (index + 1) * 2, "principal_cents": principal, "interest_cents": interest, "principal_paid_cents": 0, "interest_paid_cents": 0, "late": false, "paid_on_time": false})
		var success := candidate_run.add_cash_cents(candidate_principal, &"financing_in", &"task30_candidate_startup")
		if not success: discrepancies.append({"kind": "candidate origination rejected"})
		out.actions.append({"phase": "candidate loan origination", "candidate_only": true, "before": before, "after": _state(game), "success": success, "principal_cents": candidate_principal})

func _bank_arrears(cycle: int) -> int:
	var total := 0
	for payment: Dictionary in candidate_debt.get("installments", []):
		if payment.due_cycle <= cycle:
			total += int(payment.principal_cents) + int(payment.interest_cents) - int(payment.principal_paid_cents) - int(payment.interest_paid_cents)
	return total

func _bank_can_commit(run: RunState, direct_delta: int) -> bool:
	if run.get_completed_run_cycles() >= action_limit: return false
	# Checked native next-action cash; this is not borrowing future forecasts.
	var plan: Dictionary = run.call("_plan_productive_cycle", direct_delta)
	if plan.is_empty(): return false
	if _bank_arrears(run.get_completed_run_cycles()) == 0: return true
	return int(plan.finance.cash_cents) >= _bank_arrears(run.get_completed_run_cycles() + 1)

func _service_bank(game: Control, out: Dictionary, trigger: String) -> void:
	var run: RunState = game.run_state
	var cycle := run.get_completed_run_cycles()
	var before := _state(game)
	var payments: Array = []
	for installment: Dictionary in candidate_debt.get("installments", []):
		if installment.due_cycle > cycle: continue
		for category: String in ["interest", "principal"]:
			var amount := mini(run.get_cash_cents(), int(installment[category + "_cents"]) - int(installment[category + "_paid_cents"]))
			if amount <= 0: continue
			var kind := &"interest" if category == "interest" else &"principal_paid"
			var success := run.spend_cash_cents(amount, kind, &"task30_candidate_startup")
			payments.append({"ordinal": installment.ordinal, "due_month": installment.ordinal, "due_cycle": installment.due_cycle, "kind": kind, "cents": amount, "success": success})
			if success: installment[category + "_paid_cents"] += amount
			else: break # Native rent arrears take priority over bank payments.
		var remaining := int(installment.principal_cents) + int(installment.interest_cents) - int(installment.principal_paid_cents) - int(installment.interest_paid_cents)
		if remaining > 0: installment.late = true
		elif not installment.late and installment.due_cycle == cycle: installment.paid_on_time = true
	var closing_boundary := cycle > 0 and cycle % 2 == 0 and not trigger.ends_with("acceptance")
	var after := _state(game)
	var event := {"phase": "candidate bank service", "candidate_only": true, "trigger": trigger, "cycle": cycle, "stage": "post-productive boundary" if closing_boundary else "current partial month after passive income/action", "modeled_service_month": cycle / 2 if closing_boundary else cycle / 2 + 1, "native_journal_month": cycle / 2 + 1, "transaction_sequence_first": before.finance.transactions.size() + 1, "transaction_sequence_last": after.finance.transactions.size(), "before": before, "after": after, "payments": payments}
	if before != event.after:
		out.actions.append(event)
		candidate_bank_events.append(event)

func _begin_game(game: Control, title: String, genre: StringName, out: Dictionary) -> bool:
	if not _bank_can_commit(game.run_state, 0):
		out.actions.append({"phase": "candidate bank blocked departure", "before": _state(game), "after": _state(game), "success": false})
		return false
	var success := super._begin_game(game, title, genre, out)
	if success: _service_bank(game, out, "departure")
	return success

func _production_hand(phase: Control, project: ProjectState, run: RunState, policy: String, focus: String, label: String, number: int, out: Dictionary) -> bool:
	var success := super._production_hand(phase, project, run, policy, focus, label, number, out)
	if success: _service_bank(phase.get_parent().get_parent(), out, label)
	return success

func _choose_production(cards: Array[CardData], project: ProjectState, run: RunState, policy: String, focus: String) -> Array[int]:
	var chosen := super._choose_production(cards, project, run, policy, focus)
	var hand: Array[CardData] = []
	for index: int in chosen: hand.append(cards[index])
	if chosen.size() == 4 and not _bank_can_commit(run, -run.primitive_feature_hand_cost_cents(hand)): return []
	return chosen

func _beta_hand(phase: BetaPhase, project: ProjectState, run: RunState, policy: String, mode: String, number: int, out: Dictionary) -> bool:
	var success := super._beta_hand(phase, project, run, policy, mode, number, out)
	if success: _service_bank(phase.get_parent().get_parent(), out, "beta")
	return success

func _choose_beta(cards: Array[CardData], project: ProjectState, mode: String, policy: String) -> Array[int]:
	var chosen := super._choose_beta(cards, project, mode, policy)
	var income := 0
	for index: int in chosen:
		if cards[index].id == &"playtest_rival_games": income += BetaPhase.PLAYTEST_RIVAL_PAYOUT_CENTS
	if _bank_can_commit(candidate_run, income): return chosen
	# Visible income recovery: keep the best three ordinary choices and include
	# the displayed finite Playtest Rival card if its actual payout clears debt.
	for index in range(cards.size()):
		if cards[index].id != &"playtest_rival_games" or chosen.has(index): continue
		var recovered: Array[int] = chosen.duplicate()
		recovered[-1] = index
		if _bank_can_commit(candidate_run, BetaPhase.PLAYTEST_RIVAL_PAYOUT_CENTS): return recovered
	return []

func _stop(game: Control, out: Dictionary, phase: String, reason: String) -> void:
	super._stop(game, out, phase, reason)
	if _bank_arrears(game.run_state.get_completed_run_cycles()) > 0: out.stop = "candidate bank arrears block"

func _project_profiles() -> void:
	var inputs: Array = JSON.parse_string(FileAccess.get_file_as_string("res://design-logs/task30-v1/projection-inputs.json"))
	var results: Array = []
	var errors: Array = []
	for input: Dictionary in inputs:
		var frozen: Dictionary = input.frozen
		var record := ReleasedGameSales.create(&"projection", int(frozen.total_units), int(frozen.review_tenths), int(frozen.launch_awareness), int(frozen.market_bp))
		var release_cycle := int(input.release_cycle)
		var boundaries: Array = []
		var checkpoints := {}
		for absolute_cycle in [40, 60]:
			if absolute_cycle <= release_cycle: checkpoints[str(absolute_cycle)] = {"earned_units": 0, "earned_net_cents": 0, "settled_cents": 0, "not_yet_earning": true}
		for age in range(1, 61):
			var cycle := release_cycle + age
			record = ReleasedGameSales.next_cycle(record, cycle, cycle % 2 == 0, false)
			if record.is_empty(): errors.append({"id": input.id, "age": age}); break
			var observed := {"cycle": cycle, "age_cycle": age, "earned_units": record.earned_units, "earned_net_cents": record.entitlement_cents, "settled_cents": record.settled_cents, "unpaid_cents": record.entitlement_cents - record.settled_cents}
			if cycle % 2 == 0: boundaries.append(observed)
			if cycle in [40, 60]: checkpoints[str(cycle)] = observed
		var report := ReleasedGameMonthlyReport.build(record, release_cycle)
		if report.is_empty(): errors.append({"id": input.id, "reason": "monthly report unavailable"})
		results.append({"id": input.id, "label": "Conditional native sales projection, not legally advanced gameplay. No campaigns, future operating costs, other titles or financing included.", "release_cycle": release_cycle, "review_tenths": frozen.review_tenths, "checkpoints": checkpoints, "boundaries": boundaries, "month30_earned_net_cents": record.get("entitlement_cents", -1), "monthly_report": report})
	FileAccess.open("res://design-logs/task30-v1/native-projections-month30.json", FileAccess.WRITE).store_string(JSON.stringify({"results": results, "errors": errors}))
	print("TASK30 native projections=", results.size(), " errors=", errors.size())
	quit(0 if errors.is_empty() else 1)


func _develop_game(game: Control, policy: String, focus: String, _mode: String, seed_value: int, number: int, out: Dictionary) -> bool:
	await process_frame
	var project: ProjectState = game.project_state
	var run: RunState = game.run_state
	active_project = project
	var budgets := [7, 9, 7]
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
				_curtail(game, out, label, hand)
				curtailed = true
				break
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
			_curtail(game, out, "beta", hand)
			curtailed = true
			break
	game.set("_controlled_review_roll", -1)
	game.get("_review_rng").seed = seed_value + 7
	var before := _state(game)
	var launched := beta.request_launch()
	if not launched: launched = beta.confirm_launch_for_verification()
	out.actions.append({"phase": "launch", "game": number, "success": launched, "budget_curtailed": curtailed, "before": before, "after": _state(game)})
	if not launched: _stop(game, out, "launch", "launch rejected")
	return launched and game.get("_active_phase") is StudioPhase


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
	_service_bank(game, out, label + " acceptance")
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
		var allowed := _bank_can_commit(run, int(action.plan.get("remainder_cents", 0)))
		action["candidate_bank_can_commit"] = allowed
		action["success"] = phase.call("_play_selected_hand") if allowed else false
		action["after"] = _state(game)
		log.hands.append(action)
		out.actions.append(action)
		if action.success: _service_bank(game, out, label + " hand")
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

