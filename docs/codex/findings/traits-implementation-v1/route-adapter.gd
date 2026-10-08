extends "res://analysis/task32_routes_v1.gd"
func _state_for(project: ProjectState, run: RunState) -> Dictionary:
	var state := super._state_for(project,run)
	state["traits"] = run.get_studio_traits()
	state["lean_savings"] = run.get_lean_savings()
	return state

func _production_hand(phase: Control, project: ProjectState, run: RunState, policy: String, focus: String, label: String, game_number: int, out: Dictionary) -> bool:
	var cards: Array[CardData] = []
	cards.assign(phase.get("_candidate_cards"))
	if cards.size() != 7: return false
	var entry := {"phase": label, "game": game_number, "draw": _ids(cards), "redraws": [], "before": _state_for(project, run)}
	var attempts := 0 if policy == "cautious" else 1 if policy == "ordinary" else 2
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
	entry["normal_cents"] = run.primitive_feature_hand_cost_cents(selected)
	entry["cost_cents"] = run.primitive_feature_hand_cost_cents(selected,project.get_release_id())
	var base: Dictionary = phase.call("_validate_and_calculate_base_action")
	if not base.valid: return false
	var resolved: Dictionary = phase.call("_calculate_final_action_production", base)
	entry["synergy"] = str(resolved.specialization_stat) + " specialization" if not resolved.specialization_stat.is_empty() else "balanced production" if resolved.balanced_production else "none"
	var before_cycle := run.get_completed_run_cycles()
	if label == "design": phase.call("_on_play_card_pressed")
	else: phase.call("_on_play_alpha_hand_pressed")
	entry["after"] = _state_for(project, run)
	out.actions.append(entry)
	return run.get_completed_run_cycles() == before_cycle + 1

