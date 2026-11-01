## Historical version1 two/K8; current version2 behaviors live in verify_flexible_hands.
## Run with Godot --headless --path patch-notes --script res://scripts/debug/verify_pass_budget.gd
extends SceneTree

const Budget := preload("res://scripts/simulation/pass_budget.gd")
const Design := preload("res://scripts/simulation/design_hand_command.gd")
const Alpha := preload("res://scripts/simulation/alpha_hand_command.gd")
const Database := preload("res://scripts/cards/card_database.gd")
const Actions := preload("res://scripts/simulation/development_actions.gd")
const CardScene := preload("res://scenes/cards/card_view.tscn")
var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var database := Database.new()
	database.name = "CardDatabase"
	root.add_child(database)
	await process_frame
	var feature: CardData = database.get_card(&"sprites")
	var pass_card: CardData = database.get_card(&"graphics_pass")
	var cards: Array[CardData] = [feature, pass_card, pass_card]
	var delta := Budget.delta(cards)
	check(Budget.generated(0,1) == 2 and Budget.remaining(0, 0,1) == 2, "Both phases start with two Passes")
	check(delta.printed == feature.printed_core_total() and delta.passes == 2, "Only printed Feature Core generates budget and duplicate Pass instances each spend one")
	check(Budget.generated(7,1) == 2 and Budget.progress(7) == 7, "Fractional progress is retained")
	check(Budget.generated(8,1) == 3 and Budget.generated(15,1) == 3 and Budget.generated(16,1) == 4, "Cumulative rounding crosses exact multiples of eight")
	check(Budget.remaining(16, 3,1) == 1, "Successful Pass plays subtract from shared generated budget")
	var priorities := PriorityAllocation.new().get_priority_distribution()
	for command_script in [Design, Alpha]:
		var command = command_script.new()
		command._project_state = ProjectState.new(30)
		command._project_state._pass_budget_version = 1
		command._deal_rng = RandomNumberGenerator.new()
		command._deal_rng.seed = 42
		command._pass_definitions.assign(database.get_cards_by_phase_and_types(CardData.PHASE_DESIGN, [&"pass"] as Array[StringName]))
		var deal: Dictionary = command._build_weighted_candidate_definitions(priorities)
		check(deal.valid and deal.cards.size() == 2, "Renewable Passes may duplicate but two budget caps the initial draw")
		command._budget_spent = 2
		var exhausted: Dictionary = command._build_weighted_candidate_definitions(priorities)
		check(exhausted.valid and exhausted.cards.is_empty(), "Exhausted candidate pools may be empty")
		command._budget_printed = 8
		var refreshed: Dictionary = command._build_weighted_candidate_definitions(priorities)
		check(refreshed.valid and refreshed.cards.size() == 1, "A printed Feature threshold immediately supplies one new Pass candidate")
		var other = command_script.new()
		other._project_state = ProjectState.new(30)
		other._project_state._pass_budget_version = 1
		check(other.pass_budget_available() == 2, "Phase transition starts an independent budget")
	var design := Design.new()
	design._project_state = ProjectState.new(30)
	design._project_state._pass_budget_version = 1
	design._deal_rng = RandomNumberGenerator.new()
	design._deal_rng.seed = 91
	design.priorities = priorities
	design._pass_definitions.assign(database.get_cards_by_phase_and_types(CardData.PHASE_DESIGN, [&"pass"] as Array[StringName]))
	var other_feature: CardData = database.get_card(&"text")
	design._candidate_cards.assign([pass_card, pass_card, feature] as Array[CardData])
	design._available_features.assign([other_feature] as Array[CardData])
	var actions := Actions.new()
	actions.hand = design
	actions.phase = &"design"
	var feature_redraw: Dictionary = actions.core_redraw_plan([2] as Array[int], [0.9] as Array[float])
	check(feature_redraw.valid and feature_redraw.cards[0].card_type == &"feature", "Two retained Passes reserve the entire initial budget during redraw")
	var pass_redraw: Dictionary = actions.core_redraw_plan([0] as Array[int], [0.9] as Array[float])
	check(pass_redraw.valid and pass_redraw.cards[0].card_type == &"pass" and pass_redraw.cards[0].id != pass_card.id, "Replacing a Pass releases its reservation and avoids the same definition")
	var four_passes := Design.new()
	four_passes._project_state = ProjectState.new(30)
	four_passes._project_state._pass_budget_version = 1
	four_passes._deal_rng = RandomNumberGenerator.new()
	four_passes._deal_rng.seed = 99
	four_passes.active = true
	four_passes.priorities = priorities
	four_passes._candidate_cards.assign([pass_card, pass_card, pass_card, pass_card] as Array[CardData])
	four_passes._pass_definitions.assign(design._pass_definitions)
	four_passes.candidate_ids.assign([0, 1, 2, 3] as Array[int])
	four_passes.next_candidate_id = 4
	var rejected: Dictionary = four_passes.execute(four_passes.command(four_passes.candidate_ids))
	check(not rejected.ok and four_passes._budget_spent == 0 and four_passes._project_state.get_current_cycle() == 0, "Insufficient Pass Budget rejects a hand without spending or advancing")
	four_passes._budget_printed = 16
	var play: Dictionary = four_passes.execute(four_passes.command(four_passes.candidate_ids))
	check(play.ok and four_passes._budget_spent == 4 and four_passes.pass_budget_available() == 0, "A successful four-Pass specialized hand spends four and retriggered Core creates no budget")
	check(four_passes._candidate_cards.is_empty(), "A fully exhausted pool refills with zero candidates after successful play")
	var feature_hand := Design.new()
	feature_hand._project_state = ProjectState.new(30)
	feature_hand._project_state._pass_budget_version = 1
	feature_hand._deal_rng = RandomNumberGenerator.new()
	feature_hand._deal_rng.seed = 100
	feature_hand.active = true
	feature_hand.priorities = priorities
	feature_hand._pass_definitions.assign(design._pass_definitions)
	var source_features: Array[CardData] = []
	source_features.assign(database.get_cards_by_phase_and_types(CardData.PHASE_DESIGN, [&"feature"] as Array[StringName]))
	feature_hand._candidate_cards.assign(source_features.slice(0, 4))
	feature_hand.candidate_ids.assign([0, 1, 2, 3] as Array[int])
	feature_hand.next_candidate_id = 4
	var printed := 0
	for candidate: CardData in feature_hand._candidate_cards: printed += candidate.printed_core_total()
	var feature_play: Dictionary = feature_hand.execute(feature_hand.command(feature_hand.candidate_ids))
	check(feature_play.ok and feature_hand._budget_printed == printed and feature_hand._budget_spent == 0, "Successful Feature hand counts all printed Core once without spending Passes")
	check(feature_hand.pass_budget_available() == Budget.generated(printed,1), "Feature activation immediately refreshes the available shared budget")
	var alpha_passes := Alpha.new()
	alpha_passes._project_state = ProjectState.new(30)
	alpha_passes._project_state._pass_budget_version = 1
	alpha_passes._deal_rng = RandomNumberGenerator.new()
	alpha_passes._deal_rng.seed = 101
	alpha_passes.active = true
	alpha_passes.priorities = priorities
	alpha_passes._budget_printed = 16
	alpha_passes._pass_definitions.assign(design._pass_definitions)
	alpha_passes._candidate_cards.assign([pass_card, pass_card, pass_card, pass_card] as Array[CardData])
	alpha_passes.candidate_ids.assign([0, 1, 2, 3] as Array[int])
	alpha_passes.next_candidate_id = 4
	var alpha_play: Dictionary = alpha_passes.execute(alpha_passes.command(alpha_passes.candidate_ids))
	check(alpha_play.ok and alpha_passes._budget_spent == 4 and alpha_passes.pass_budget_available() == 0, "Alpha independently spends its shared Pass Budget on successful activation")
	var alpha_empty := Alpha.new()
	alpha_empty._project_state = ProjectState.new(30)
	alpha_empty._project_state._pass_budget_version = 1
	alpha_empty._pass_definitions.assign(design._pass_definitions)
	var alpha_actions := Actions.new()
	alpha_actions.hand = alpha_empty
	alpha_actions.phase = &"alpha"
	check(alpha_actions.valid_pool(), "An empty Alpha pool is valid for phase completion")
	var card_view: CardView = CardScene.instantiate()
	card_view.set_card(pass_card)
	root.add_child(card_view)
	card_view.set_shared_pass_budget(1, 5)
	check(card_view.pass_budget_label.visible and not card_view.renewability_icon.visible and card_view.pass_budget_label.text == "Pass 1", "Pass card replaces renewability icon with the shared remaining budget")
	check("5/8" in card_view.input_button.tooltip_text, "Pass card tooltip shows preserved printed Core progress")
	card_view.queue_free()
	print("Pass Budget: %d failures" % failures)
	quit(1 if failures else 0)
