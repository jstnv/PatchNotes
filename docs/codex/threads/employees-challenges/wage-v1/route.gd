extends "res://analysis/task32_routes_v1.gd"

func _state_for(project: ProjectState, run: RunState) -> Dictionary:
	var state := super._state_for(project,run)
	state["employees"] = run.get_employees()
	return state

func _production_hand(phase: Control, project: ProjectState, run: RunState, policy: String, focus: String, label: String, game_number: int, out: Dictionary) -> bool:
	var cards: Array[CardData] = []
	cards.assign(phase.get("_candidate_cards"))
	if cards.size() != 7: return false
	var entry := {"phase": label, "game": game_number, "draw": _ids(cards), "redraws": [], "before": _state_for(project, run)}
	var attempts := 0 if policy in ["cautious", "frugal"] else 1 if policy == "ordinary" else 2
	for unused in range(attempts):
		if run.get_available_redraws() == 0: break
		var slot := _weakest(cards, focus)
		var views: Array = phase.get_node("%HandContainer").get_children()
		(views[slot] as CardView).input_button.pressed.emit()
		var old := str(cards[slot].id)
		var changed: bool = phase.redraw_selected_cards()
		entry.redraws.append({"slot": slot, "from": old, "success": changed})
		if not changed:
			(views[slot] as CardView).input_button.pressed.emit()
			break
		cards.assign(phase.get("_candidate_cards"))
		entry.redraws[-1]["to"] = str(cards[slot].id)
	entry["final_draw"] = _ids(cards)
	var indices := _choose_production(cards, project, run, policy, focus)
	if indices.size() != 4:
		entry["blocked"] = "no affordable four-card selection"
		out.actions.append(entry)
		return false
	var selected: Array[CardData] = []
	var views: Array = phase.get_node("%HandContainer").get_children()
	for slot: int in indices:
		selected.append(cards[slot])
		(views[slot] as CardView).input_button.pressed.emit()
	entry["selected"] = _ids(selected)
	entry["printed_scope"] = selected.reduce(func(total: int, card: CardData) -> int: return total + card.scope, 0)
	entry["printed_core"] = _printed(selected)
	entry["cost_cents"] = run.primitive_feature_hand_cost_cents(selected)
	var base: Dictionary = phase.call("_validate_and_calculate_base_action")
	if not base.valid: return false
	var resolved: Dictionary = phase.call("_calculate_final_action_production", base)
	entry["synergy"] = str(resolved.specialization_stat) + " specialization" if not resolved.specialization_stat.is_empty() else "balanced production" if resolved.balanced_production else "none"
	var before_cycle := run.get_completed_run_cycles()
	var employee: Dictionary = phase.get_employee_hand_status()
	var proposal: Dictionary = phase.get_priority_distribution().duplicate()
	var printed := {0:0,1:0,2:0,3:0}
	for card: CardData in selected:
		if ContractState.CORE_BY_STAT.has(card.primary_stat): printed[ContractState.CORE_BY_STAT[card.primary_stat]] += card.primary_value
		if ContractState.CORE_BY_STAT.has(card.secondary_stat): printed[ContractState.CORE_BY_STAT[card.secondary_stat]] += card.secondary_value
	var ranked: Array = [0,1,2,3]
	ranked.sort_custom(func(a,b):return printed[a]>printed[b] if printed[a]!=printed[b] else a<b)
	proposal[ranked[0]] += 5
	proposal[ranked[-1]] -= 5
	if policy == "synergy" and employee.available and employee.qualifying and PriorityAllocation.is_valid_distribution(proposal):
		entry["employee_plan"] = proposal.duplicate()
		entry["employee_plan_success"] = phase.play_hand_with_employee_plan(proposal)
	else:
		if label == "design": phase.call("_on_play_card_pressed")
		else: phase.call("_on_play_alpha_hand_pressed")
	entry["after"] = _state_for(project, run)
	out.actions.append(entry)
	return run.get_completed_run_cycles() == before_cycle + 1


func _install_shadows(_run: RunState) -> void:
	pass

func _choose_production(cards: Array[CardData], project: ProjectState, run: RunState, policy: String, focus: String) -> Array[int]:
	if policy != "frugal": return super._choose_production(cards,project,run,policy,focus)
	var chosen: Array[int] = []
	var best_cost := 9223372036854775807
	var best_core := -1
	for a in range(4):
		for b in range(a+1,5):
			for c in range(b+1,6):
				for d in range(c+1,7):
					var hand: Array[CardData] = [cards[a],cards[b],cards[c],cards[d]]
					var cost := run.primitive_feature_hand_cost_cents(hand)
					var core := 0
					for card: CardData in hand: core += card.primary_value+card.secondary_value
					if cost >= 0 and cost <= run.get_cash_cents() and (cost < best_cost or (cost == best_cost and core > best_core)):
						best_cost=cost
						best_core=core
						chosen.assign([a,b,c,d])
	return chosen

func _shop_matched(game: Control, out: Dictionary, number: int) -> void:
	var run: RunState = game.run_state
	if OS.get_environment("WAGE_CENTS") != "0" and run.get_employees().employees.is_empty():
		var before := _state(game)
		var quote := run.get_production_hire_quote()
		var hired := not quote.is_empty() and run.hire_production_specialist(quote)
		out.actions.append({"phase":"hire_attempt","game":number,"quote":quote,"success":hired,"before":before,"after":_state(game)})
	if number == 2 and OS.get_environment("STRATUM") in ["bank","bankfunded"]:
		var before := _state(game)
		var quote := run.get_bank_quote(50000,12)
		var success: bool = quote.get("accepted",false) and run.accept_bank_loan(quote)
		out.actions.append({"phase":"chosen_bank","quote":quote,"success":success,"before":before,"after":_state(game)})
	if number == 2 and OS.get_environment("STRATUM") == "store":
		var before := _state(game)
		var quote := run.get_primitive_reserve_offer(&"music")
		var success := run.purchase_primitive_reserve_feature(&"music")
		out.actions.append({"phase":"chosen_store","quote":quote,"success":success,"before":before,"after":_state(game)})
