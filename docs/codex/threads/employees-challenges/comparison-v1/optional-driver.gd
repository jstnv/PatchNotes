## Analysis-only optional activation policy. Base driver remains pinned.
extends "res://analysis/employee_comparison_v1.gd"

var activation_decision := false

func _finance_route() -> Dictionary:
	var out := await super._finance_route()
	out["activation_policy"] = "optional expected first replacement; public owned definitions and Core deficits"
	return out

func _production_hand(phase: Control, project: ProjectState, run: RunState, policy: String, focus: String, label: String, game_number: int, out: Dictionary) -> bool:
	activation_decision = true
	var committed := super._production_hand(phase,project,run,policy,focus,label,game_number,out)
	activation_decision = false
	return committed

func _priorities(project: ProjectState) -> Dictionary:
	var proposed := super._priorities(project)
	if not activation_decision: return proposed
	var old: Dictionary = phase_for_choice.get_priority_distribution()
	var hand: Array[CardData] = []
	for view: CardView in phase_for_choice.get("_selected_card_views"): hand.append(view.card_data)
	if not trained or uses_in_project >= staff or not _printed_match(hand) or proposed == old: return proposed
	var current_value := _expected_first_replacement(project,old)
	var proposed_value := _expected_first_replacement(project,proposed)
	var use := proposed_value > current_value + 0.000001
	trial_events.append({"kind":"optional_decision","game":project_number,"cycle":phase_for_choice.get("_run_state").get_completed_run_cycles(),"old":old,"proposed":proposed,"current_expected":current_value,"proposed_expected":proposed_value,"use":use,"selected":_ids(hand)})
	return proposed if use else old

func _expected_first_replacement(project: ProjectState, distribution: Dictionary) -> float:
	var visible: Array = phase_for_choice.get("_candidate_cards")
	var excluded: Array = visible.map(func(card: CardData):return card.id)
	var definitions: Array = []
	for card: CardData in phase_for_choice.get("_available_features"):
		if card.id not in excluded: definitions.append(card)
	definitions.append_array(phase_for_choice.get("_pass_definitions"))
	var total := 0.0
	var value := 0.0
	for card: CardData in definitions:
		var weight: float = phase_for_choice.call("_calculate_candidate_weight",card,distribution)
		var utility := mini(card.scope,maxi(0,project.get_required_scope()-project.get_current_scope()))*10.0
		for index in range(4):
			var gain := (card.primary_value if card.primary_stat==STATS[index] else 0)+(card.secondary_value if card.secondary_stat==STATS[index] else 0)
			utility += minf(gain,maxf(0,_core_target(project,index)-project.get_core_score(index)))*4.0
		total += weight
		value += utility*weight
	return value/total if total>0 else 0.0
