class_name DesignPhase
extends Control

signal proceed_to_alpha_requested
signal priorities_changed

const CARD_VIEW_SCENE := preload("res://scenes/cards/card_view.tscn")
const PRIORITY_ALLOCATION_SCRIPT := preload("res://scripts/phases/priority_allocation.gd")
const WEIGHTED_CANDIDATE_MATH := preload("res://scripts/phases/weighted_candidate_math.gd")
const CANDIDATE_POOL_SIZE := 7
const SELECTED_HAND_SIZE := 4
const SPECIALIZATION_MULTIPLIER := 1.5
const BALANCED_PRODUCTION_THRESHOLD := 0.20
const BALANCED_PRODUCTION_MULTIPLIER := 1.20
const BUG_PRESSURE_DENOMINATOR := 18.0
const PERFECT_PRODUCTION_THRESHOLD := 0.05
const PERFECT_BUG_PRESSURE_MULTIPLIER := 0.80
const CORE_SCORE_BY_STAT := {
	&"graphics": ProjectState.CoreScore.GRAPHICS,
	&"sound": ProjectState.CoreScore.SOUND,
	&"technology": ProjectState.CoreScore.TECHNOLOGY,
	&"design": ProjectState.CoreScore.DESIGN,
}

var _project_state: ProjectState
var _available_features: Array[CardData] = []
var _pass_definitions: Array[CardData] = []
var _candidate_cards: Array[CardData] = []
var _selected_card_views: Array[CardView] = []
var _exhausted_card_ids: Dictionary[StringName, bool] = {}
var _finalization_requested := false
var _finalization_rng := RandomNumberGenerator.new()
var _deal_rng := RandomNumberGenerator.new()
enum PhaseState { PLANNING, ACTIVE_DEVELOPMENT }

var _phase_state := PhaseState.PLANNING
var _priority_allocation := PRIORITY_ALLOCATION_SCRIPT.new()
var _syncing_priority_controls := false

@onready var graphics_value: Label = %GraphicsValue
@onready var sound_value: Label = %SoundValue
@onready var technology_value: Label = %TechnologyValue
@onready var design_value: Label = %DesignValue
@onready var scope_value: Label = %ScopeValue
@onready var bug_pressure_value: Label = %BugPressureValue
@onready var hand_container: HBoxContainer = %HandContainer
@onready var play_card_button: Button = %PlayCardButton
@onready var proceed_to_alpha_button: Button = %ProceedToAlphaButton


func _ready() -> void:
	_finalization_rng.randomize()
	_deal_rng.randomize()
	_priority_allocation.allocation_changed.connect(_on_priority_allocation_changed)
	play_card_button.pressed.connect(_on_play_card_pressed)
	proceed_to_alpha_button.pressed.connect(_on_proceed_to_alpha_pressed)
	%BeginDesignButton.pressed.connect(_on_begin_design_pressed)
	_update_play_button()
	_refresh_display()
	_sync_priority_controls()


func setup(project_state: ProjectState) -> void:
	if _project_state != null and _project_state.values_changed.is_connected(_refresh_display):
		_project_state.values_changed.disconnect(_refresh_display)

	_project_state = project_state
	if _project_state != null:
		_project_state.values_changed.connect(_refresh_display)

	if is_node_ready():
		_refresh_display()


## Phase-local planning only. Candidate dealing intentionally does not consume
## this distribution until the separately approved weighted-draw milestone.
func set_priority(category: int, requested_value: Variant) -> bool:
	return _priority_allocation.set_priority(category, requested_value)


func get_priority(category: int) -> int:
	return _priority_allocation.get_priority(category)


func get_priority_distribution() -> Dictionary[ProjectState.CoreScore, int]:
	return _priority_allocation.get_priority_distribution()


func get_available_priority() -> int:
	return _priority_allocation.get_available_priority()


func begin_design() -> bool:
	if _phase_state != PhaseState.PLANNING or _finalization_requested:
		return false
	if not _initialize_design_lifecycle():
		push_warning("Could not begin Design because the initial weighted candidate pool could not be dealt.")
		return false
	_phase_state = PhaseState.ACTIVE_DEVELOPMENT
	%BeginDesignButton.disabled = true
	%BeginDesignButton.visible = false
	_update_play_button()
	return true


func _on_begin_design_pressed() -> void:
	begin_design()


func _on_priority_allocation_changed() -> void:
	_sync_priority_controls()
	priorities_changed.emit()


func _on_graphics_priority_value_changed(value: float) -> void:
	_on_priority_slider_changed(ProjectState.CoreScore.GRAPHICS, value)


func _on_sound_priority_value_changed(value: float) -> void:
	_on_priority_slider_changed(ProjectState.CoreScore.SOUND, value)


func _on_technology_priority_value_changed(value: float) -> void:
	_on_priority_slider_changed(ProjectState.CoreScore.TECHNOLOGY, value)


func _on_design_priority_value_changed(value: float) -> void:
	_on_priority_slider_changed(ProjectState.CoreScore.DESIGN, value)


func _on_priority_slider_changed(category: ProjectState.CoreScore, value: float) -> void:
	if _syncing_priority_controls:
		return
	set_priority(category, int(value))


func _sync_priority_controls() -> void:
	if not is_node_ready():
		return
	_syncing_priority_controls = true
	%GraphicsPriority.value = get_priority(ProjectState.CoreScore.GRAPHICS)
	%SoundPriority.value = get_priority(ProjectState.CoreScore.SOUND)
	%TechnologyPriority.value = get_priority(ProjectState.CoreScore.TECHNOLOGY)
	%DesignPriority.value = get_priority(ProjectState.CoreScore.DESIGN)
	%GraphicsPriorityValue.text = str(get_priority(ProjectState.CoreScore.GRAPHICS))
	%SoundPriorityValue.text = str(get_priority(ProjectState.CoreScore.SOUND))
	%TechnologyPriorityValue.text = str(get_priority(ProjectState.CoreScore.TECHNOLOGY))
	%DesignPriorityValue.text = str(get_priority(ProjectState.CoreScore.DESIGN))
	%DesignAvailablePriority.text = "Available Priority: %d" % get_available_priority()
	_syncing_priority_controls = false


func _refresh_display() -> void:
	if _project_state == null:
		return

	graphics_value.text = "Graphics: %d" % _project_state.get_core_score(ProjectState.CoreScore.GRAPHICS)
	sound_value.text = "Sound: %d" % _project_state.get_core_score(ProjectState.CoreScore.SOUND)
	technology_value.text = "Technology: %d" % _project_state.get_core_score(ProjectState.CoreScore.TECHNOLOGY)
	design_value.text = "Design: %d" % _project_state.get_core_score(ProjectState.CoreScore.DESIGN)
	scope_value.text = "Scope: %d / %d" % [
		_project_state.get_current_scope(),
		_project_state.get_required_scope(),
	]
	bug_pressure_value.text = "Bug Pressure: %.2f" % _project_state.get_accumulated_bug_pressure()


func _initialize_design_lifecycle() -> bool:
	_clear_candidate_pool()
	_available_features.clear()
	_pass_definitions.clear()
	_exhausted_card_ids.clear()
	var card_database := get_node("/root/CardDatabase")
	var eligible_types: Array[StringName] = [&"feature", &"pass"]
	var definitions: Array[CardData] = []
	definitions.assign(card_database.call(
		&"get_cards_by_phase_and_types",
		CardData.PHASE_DESIGN,
		eligible_types,
	))
	for card in definitions:
		if card.card_type == &"feature" and not card.renewable:
			_available_features.append(card)
		elif card.card_type == &"pass" and card.renewable:
			_pass_definitions.append(card)
	return _deal_next_candidate_pool()


func _deal_next_candidate_pool(controlled_rolls: Array[float] = []) -> bool:
	if not _candidate_cards.is_empty():
		push_warning("Cannot deal a new Design candidate pool while the current pool is active.")
		return false
	var priority_snapshot := get_priority_distribution()
	var deal := _build_weighted_candidate_definitions(priority_snapshot, controlled_rolls)
	if not deal.valid:
		push_warning("Could not build a complete weighted Design candidate pool: %s" % deal.error)
		return false

	_candidate_cards.assign(deal.cards)
	for feature: CardData in deal.selected_features:
		_available_features.erase(feature)

	for card in _candidate_cards:
		var card_view: CardView = CARD_VIEW_SCENE.instantiate()
		card_view.set_card(card)
		card_view.card_pressed.connect(_on_card_pressed)
		hand_container.add_child(card_view)
	return true


func _build_weighted_candidate_definitions(priority_snapshot: Dictionary, controlled_rolls: Array[float] = []) -> Dictionary:
	var validation_error := _get_deal_input_validation_error(priority_snapshot)
	if not validation_error.is_empty():
		return {&"valid": false, &"error": validation_error}
	if not controlled_rolls.is_empty() and controlled_rolls.size() != CANDIDATE_POOL_SIZE:
		return {&"valid": false, &"error": "Controlled deal must provide exactly seven rolls."}
	for roll: float in controlled_rolls:
		if not is_finite(roll) or roll < 0.0 or roll >= 1.0:
			return {&"valid": false, &"error": "Weighted deal rolls must be finite values in [0, 1)."}

	var remaining_features: Array[CardData] = _available_features.duplicate()
	var selected_cards: Array[CardData] = []
	var selected_features: Array[CardData] = []
	for slot in range(CANDIDATE_POOL_SIZE):
		var entries: Array[Dictionary] = []
		for card: CardData in remaining_features + _pass_definitions:
			var weight := _calculate_candidate_weight(card, priority_snapshot)
			if not is_finite(weight) or weight < 0.0:
				return {&"valid": false, &"error": "Candidate '%s' produced an invalid weight." % card.id}
			if weight > 0.0:
				entries.append({&"card": card, &"weight": weight})
		entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.card.id) < str(b.card.id))
		var roll := controlled_rolls[slot] if not controlled_rolls.is_empty() else _deal_rng.randf()
		var selected := _select_weighted_entry(entries, roll)
		if selected == null:
			return {&"valid": false, &"error": "Slot %d had no positive finite selectable weight." % (slot + 1)}
		selected_cards.append(selected)
		if selected.card_type == &"feature":
			selected_features.append(selected)
			remaining_features.erase(selected)
	return {&"valid": true, &"cards": selected_cards, &"selected_features": selected_features}


func _select_weighted_entry(entries: Array[Dictionary], roll: float) -> CardData:
	return WEIGHTED_CANDIDATE_MATH.select_weighted_entry(entries, roll)


func _calculate_candidate_weight(card: CardData, priority_snapshot: Dictionary) -> float:
	return WEIGHTED_CANDIDATE_MATH.calculate_printed_score_weight(card, priority_snapshot, CORE_SCORE_BY_STAT)


func _get_deal_input_validation_error(priority_snapshot: Dictionary) -> String:
	if priority_snapshot.size() != PriorityAllocation.CORE_CATEGORIES.size():
		return "Priority snapshot must contain all four Core categories."
	var priority_total := 0
	for category: ProjectState.CoreScore in PriorityAllocation.CORE_CATEGORIES:
		if not priority_snapshot.has(category) or typeof(priority_snapshot[category]) != TYPE_INT:
			return "Priority snapshot contains a missing or malformed category."
		var value: int = priority_snapshot[category]
		if value < PriorityAllocation.MIN_PRIORITY or value > PriorityAllocation.MAX_PRIORITY or value % PriorityAllocation.PRIORITY_STEP != 0:
			return "Priority snapshot contains an out-of-range or non-step value."
		priority_total += value
	if priority_total > PriorityAllocation.MAX_TOTAL_PRIORITY:
		return "Priority snapshot exceeds the allocation budget."

	var feature_ids: Dictionary[StringName, bool] = {}
	for card: CardData in _available_features:
		var error := _get_weighted_definition_validation_error(card, &"feature")
		if not error.is_empty():
			return error
		if feature_ids.has(card.id):
			return "Available Design Feature IDs must be unique: %s" % card.id
		if _exhausted_card_ids.has(card.id):
			return "Exhausted Design Feature cannot remain available: %s" % card.id
		feature_ids[card.id] = true
	if _pass_definitions.size() != 4:
		return "Weighted Design dealing requires exactly four Core Pass definitions."
	var pass_categories: Dictionary[ProjectState.CoreScore, bool] = {}
	var pass_ids: Dictionary[StringName, bool] = {}
	for card: CardData in _pass_definitions:
		var error := _get_weighted_definition_validation_error(card, &"pass")
		if not error.is_empty():
			return error
		var category: ProjectState.CoreScore = CORE_SCORE_BY_STAT[card.primary_stat]
		if pass_categories.has(category) or pass_ids.has(card.id):
			return "Weighted Design dealing requires one Pass per Core category."
		pass_categories[category] = true
		pass_ids[card.id] = true
	return ""


func _get_weighted_definition_validation_error(card: CardData, expected_type: StringName) -> String:
	if card == null or card.id.is_empty():
		return "Weighted candidate definitions require stable nonempty IDs."
	if card.phase != CardData.PHASE_DESIGN or card.card_type != expected_type:
		return "Candidate '%s' has an invalid Design phase or type." % card.id
	if (expected_type == &"feature" and card.renewable) or (expected_type == &"pass" and not card.renewable):
		return "Candidate '%s' has invalid renewability." % card.id
	var production_error := _get_card_validation_error(card)
	if not production_error.is_empty():
		return production_error
	if expected_type == &"pass" and (not card.secondary_stat.is_empty() or card.secondary_value != 0):
		return "Core Pass '%s' cannot have a secondary weighted score." % card.id
	return ""


func _clear_candidate_pool() -> void:
	_clear_selection()
	_candidate_cards.clear()
	for child in hand_container.get_children():
		hand_container.remove_child(child)
		child.queue_free()


func _on_card_pressed(card_view: CardView) -> void:
	if _phase_state != PhaseState.ACTIVE_DEVELOPMENT or _finalization_requested:
		return
	if not _is_current_candidate_view(card_view):
		return
	if _selected_card_views.has(card_view):
		_selected_card_views.erase(card_view)
		card_view.set_selected(false)
		_update_play_button()
		return
	if _selected_card_views.size() >= SELECTED_HAND_SIZE:
		push_warning("Exactly four Design candidates may be selected.")
		return

	_selected_card_views.append(card_view)
	card_view.set_selected(true)
	_update_play_button()


func _clear_selection() -> void:
	for card_view in _selected_card_views:
		if is_instance_valid(card_view):
			card_view.set_selected(false)
	_selected_card_views.clear()
	_update_play_button()


func _on_play_card_pressed() -> void:
	if _phase_state != PhaseState.ACTIVE_DEVELOPMENT or _finalization_requested:
		return
	if not _can_play_selected_hand():
		return

	var base_hand := _validate_and_calculate_base_action()
	if not base_hand.valid:
		return
	var final_action := _calculate_final_action_production(base_hand)

	var additions: Dictionary[ProjectState.CoreScore, int] = final_action.score_additions
	if not _project_state.add_core_scores_and_scope(additions, base_hand.scope, base_hand.bug_pressure):
		return
	if not final_action.specialization_stat.is_empty():
		print(_build_specialization_debug_message(final_action.specialization_stat, additions))
	elif final_action.balanced_production:
		print("Balanced Production!")

	_complete_successful_cycle()


func _on_proceed_to_alpha_pressed() -> void:
	if _finalization_requested:
		return
	var finalization := _calculate_design_finalization(
		_finalization_rng.randf(),
		_finalization_rng.randf(),
	)
	if not finalization.valid:
		return
	var feature_history := _build_design_feature_history()
	if not feature_history.valid:
		return
	if not _project_state.finalize_design_bugs(
		finalization.perfect_production,
		finalization.hidden_bugs,
		feature_history.implemented_ids,
		feature_history.unimplemented_ids,
	):
		return
	_finalization_requested = true
	%BeginDesignButton.disabled = true
	proceed_to_alpha_button.disabled = true
	_update_play_button()
	if finalization.perfect_production:
		print("Perfect Production!")
	print("Final Hidden Bugs: %d" % finalization.hidden_bugs)
	proceed_to_alpha_requested.emit()


func _build_design_feature_history() -> Dictionary:
	var card_database := get_node("/root/CardDatabase")
	var definitions: Array[CardData] = []
	definitions.assign(card_database.call(
		&"get_cards_by_phase_and_types",
		CardData.PHASE_DESIGN,
		[&"feature"] as Array[StringName],
	))
	var eligible_ids: Dictionary[StringName, bool] = {}
	for card in definitions:
		if (
			card == null
			or card.id.is_empty()
			or card.phase != CardData.PHASE_DESIGN
			or card.card_type != &"feature"
			or card.renewable
			or eligible_ids.has(card.id)
		):
			push_warning("Cannot finalize invalid Design Feature definition history.")
			return {&"valid": false}
		eligible_ids[card.id] = true
	for exhausted_id: StringName in _exhausted_card_ids:
		if not eligible_ids.has(exhausted_id):
			push_warning("Exhausted ID is not an eligible Design Feature: %s" % exhausted_id)
			return {&"valid": false}

	var implemented_ids: Array[StringName] = []
	var unimplemented_ids: Array[StringName] = []
	for id: StringName in eligible_ids:
		if _exhausted_card_ids.has(id):
			implemented_ids.append(id)
		else:
			unimplemented_ids.append(id)
	implemented_ids.sort_custom(func(a: StringName, b: StringName) -> bool: return str(a) < str(b))
	unimplemented_ids.sort_custom(func(a: StringName, b: StringName) -> bool: return str(a) < str(b))
	if not _is_valid_design_feature_history(implemented_ids, unimplemented_ids, definitions):
		return {&"valid": false}
	return {
		&"valid": true,
		&"implemented_ids": implemented_ids,
		&"unimplemented_ids": unimplemented_ids,
	}


func _is_valid_design_feature_history(implemented_ids: Array, unimplemented_ids: Array, definitions: Array[CardData]) -> bool:
	var card_database := get_node("/root/CardDatabase")
	var expected_ids: Dictionary[StringName, bool] = {}
	for card in definitions:
		expected_ids[card.id] = true
	var seen: Dictionary[StringName, bool] = {}
	for raw_id: Variant in implemented_ids + unimplemented_ids:
		if typeof(raw_id) != TYPE_STRING and typeof(raw_id) != TYPE_STRING_NAME:
			return false
		var id := StringName(raw_id)
		if id.is_empty() or seen.has(id):
			return false
		var card: CardData = card_database.call(&"get_card", id)
		if card == null or card.phase != CardData.PHASE_DESIGN or card.card_type != &"feature" or card.renewable:
			return false
		seen[id] = true
	if seen.size() != expected_ids.size():
		return false
	for id: StringName in expected_ids:
		if not seen.has(id):
			return false
	return true


func _calculate_design_finalization(stochastic_roll: float, variance_roll: float) -> Dictionary:
	if (
		not is_finite(stochastic_roll)
		or stochastic_roll < 0.0
		or stochastic_roll >= 1.0
		or not is_finite(variance_roll)
		or variance_roll < 0.0
		or variance_roll >= 1.0
	):
		return {&"valid": false}

	var perfect_production := _is_perfect_production()
	var accumulated_bug_pressure := _project_state.get_accumulated_bug_pressure()
	var adjusted_bug_pressure := accumulated_bug_pressure
	if perfect_production:
		adjusted_bug_pressure *= PERFECT_BUG_PRESSURE_MULTIPLIER
	var rounded_bug_base := floori(adjusted_bug_pressure)
	var fraction := adjusted_bug_pressure - rounded_bug_base
	if stochastic_roll < fraction:
		rounded_bug_base += 1
	var hidden_bugs := maxi(0, rounded_bug_base + _get_bug_variance(variance_roll))
	return {
		&"valid": true,
		&"perfect_production": perfect_production,
		&"adjusted_bug_pressure": adjusted_bug_pressure,
		&"hidden_bugs": hidden_bugs,
	}


func _is_perfect_production() -> bool:
	var scores: Dictionary[ProjectState.CoreScore, int] = {}
	for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
		scores[category] = _project_state.get_core_score(category)
	return _are_core_scores_perfect(scores)


func _are_core_scores_perfect(scores: Dictionary) -> bool:
	var total := 0
	for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
		total += scores.get(category, 0)
	var mean := total / 4.0
	var lower_bound := mean * (1.0 - PERFECT_PRODUCTION_THRESHOLD)
	var upper_bound := mean * (1.0 + PERFECT_PRODUCTION_THRESHOLD)
	for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
		var score: int = scores.get(category, 0)
		if score < lower_bound or score > upper_bound:
			return false
	return true


func _get_bug_variance(roll: float) -> int:
	if roll < 0.08:
		return -2
	if roll < 0.25:
		return -1
	if roll < 0.75:
		return 0
	if roll < 0.92:
		return 1
	return 2


func _complete_successful_cycle() -> void:
	for card_view in _selected_card_views:
		var card := card_view.card_data
		if card.card_type == &"feature" and not card.renewable:
			_exhausted_card_ids[card.id] = true

	for card in _candidate_cards:
		if card.card_type == &"feature" and not _exhausted_card_ids.has(card.id):
			_return_feature_to_available(card)

	_clear_candidate_pool()
	_project_state.advance_cycle()
	if not _deal_next_candidate_pool():
		push_warning("The Design hand resolved, but the next weighted candidate pool could not be dealt.")


func _return_feature_to_available(card: CardData) -> void:
	if _exhausted_card_ids.has(card.id) or _available_features.has(card):
		return
	_available_features.append(card)


func _can_play_selected_hand() -> bool:
	if _phase_state != PhaseState.ACTIVE_DEVELOPMENT or _finalization_requested or _project_state == null or _selected_card_views.size() != SELECTED_HAND_SIZE:
		return false
	var seen_views: Dictionary[int, bool] = {}
	for card_view in _selected_card_views:
		if not _is_current_candidate_view(card_view):
			return false
		var instance_id := card_view.get_instance_id()
		if seen_views.has(instance_id):
			return false
		seen_views[instance_id] = true
	return true


func _is_current_candidate_view(card_view: CardView) -> bool:
	return (
		is_instance_valid(card_view)
		and card_view.get_parent() == hand_container
		and card_view.card_data != null
		and _candidate_cards.has(card_view.card_data)
	)


func _validate_and_calculate_base_action() -> Dictionary:
	var cards: Array[CardData] = []
	for card_view in _selected_card_views:
		var card := card_view.card_data
		var validation_error := _get_card_validation_error(card)
		if not validation_error.is_empty():
			return _invalid_base_hand(validation_error)
		cards.append(card)

	var score_additions: Dictionary[ProjectState.CoreScore, int] = {}
	var contributions: Array[Dictionary] = []
	var total_scope := 0
	var action_bug_pressure := 0.0
	var has_feature := false
	for card in cards:
		var primary_category: ProjectState.CoreScore = CORE_SCORE_BY_STAT[card.primary_stat]
		var contribution := {
			&"primary_category": primary_category,
			&"primary_value": card.primary_value,
			&"has_secondary": not card.secondary_stat.is_empty(),
			&"secondary_category": ProjectState.CoreScore.GRAPHICS,
			&"secondary_value": card.secondary_value,
		}
		score_additions[primary_category] = score_additions.get(primary_category, 0) + card.primary_value
		total_scope += card.scope
		has_feature = has_feature or card.card_type == &"feature"

		if contribution.has_secondary:
			var secondary_category: ProjectState.CoreScore = CORE_SCORE_BY_STAT[card.secondary_stat]
			contribution.secondary_category = secondary_category
			score_additions[secondary_category] = score_additions.get(secondary_category, 0) + card.secondary_value
		contributions.append(contribution)
		if card.card_type == &"feature":
			action_bug_pressure += _calculate_feature_bug_pressure(card)

	return {
		&"valid": true,
		&"cards": cards,
		&"score_additions": score_additions,
		&"scope": total_scope,
		&"bug_pressure": action_bug_pressure,
		&"has_feature": has_feature,
		&"contributions": contributions,
	}


func _calculate_feature_bug_pressure(card: CardData) -> float:
	var total_printed_raw_score := card.primary_value
	if not card.secondary_stat.is_empty():
		total_printed_raw_score += card.secondary_value
	return (float(total_printed_raw_score) * float(card.scope)) / BUG_PRESSURE_DENOMINATOR


func _calculate_final_action_production(base_hand: Dictionary) -> Dictionary:
	var cards: Array[CardData] = []
	cards.assign(base_hand.cards)
	var provisional_scores := _calculate_provisional_core_scores(base_hand.score_additions)
	var specialization_stat := _get_specialization_stat(cards)
	var balanced_production: bool = (
		base_hand.has_feature
		and _are_core_scores_balanced(provisional_scores)
	)
	if not specialization_stat.is_empty():
		return {
			&"specialization_stat": specialization_stat,
			&"balanced_production": false,
			&"balanced_eligible": balanced_production,
			&"provisional_scores": provisional_scores,
			&"score_additions": _apply_specialization(base_hand.score_additions),
		}
	if balanced_production:
		return {
			&"specialization_stat": &"",
			&"balanced_production": true,
			&"balanced_eligible": true,
			&"provisional_scores": provisional_scores,
			&"score_additions": _apply_balanced_production(base_hand.score_additions),
		}
	return {
		&"specialization_stat": &"",
		&"balanced_production": false,
		&"balanced_eligible": false,
		&"provisional_scores": provisional_scores,
		&"score_additions": base_hand.score_additions.duplicate(),
	}


func _calculate_provisional_core_scores(base_additions: Dictionary) -> Dictionary[ProjectState.CoreScore, int]:
	var provisional_scores: Dictionary[ProjectState.CoreScore, int] = {}
	for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
		provisional_scores[category] = _project_state.get_core_score(category) + base_additions.get(category, 0)
	return provisional_scores


func _are_core_scores_balanced(scores: Dictionary) -> bool:
	var total := 0
	for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
		total += scores.get(category, 0)
	var mean := total / 4.0
	var lower_bound := mean * (1.0 - BALANCED_PRODUCTION_THRESHOLD)
	var upper_bound := mean * (1.0 + BALANCED_PRODUCTION_THRESHOLD)
	for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
		var score: int = scores.get(category, 0)
		if score < lower_bound or score > upper_bound:
			return false
	return true


func _apply_balanced_production(base_additions: Dictionary) -> Dictionary[ProjectState.CoreScore, int]:
	var adjusted: Dictionary[ProjectState.CoreScore, int] = {}
	for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
		var base_amount: int = base_additions.get(category, 0)
		adjusted[category] = roundi(base_amount * BALANCED_PRODUCTION_MULTIPLIER)
	return adjusted


func _apply_specialization(base_additions: Dictionary) -> Dictionary[ProjectState.CoreScore, int]:
	var adjusted: Dictionary[ProjectState.CoreScore, int] = {}
	for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
		var base_amount: int = base_additions.get(category, 0)
		adjusted[category] = roundi(base_amount * SPECIALIZATION_MULTIPLIER)
	return adjusted


func _get_card_validation_error(card: CardData) -> String:
	if card.primary_stat.is_empty():
		return "Card '%s' has no primary stat." % card.id
	if not CORE_SCORE_BY_STAT.has(card.primary_stat):
		return "Card '%s' has an invalid primary stat: %s" % [card.id, card.primary_stat]
	if card.primary_value < 0:
		return "Card '%s' has a negative primary value." % card.id
	if card.scope < 0:
		return "Card '%s' has negative Scope." % card.id
	if card.secondary_stat.is_empty():
		if card.secondary_value != 0:
			return "Card '%s' has a secondary value without a secondary stat." % card.id
		return ""
	if not CORE_SCORE_BY_STAT.has(card.secondary_stat):
		return "Card '%s' has an invalid secondary stat: %s" % [card.id, card.secondary_stat]
	if card.secondary_value < 0:
		return "Card '%s' has a negative secondary value." % card.id
	return ""


func _get_specialization_stat(cards: Array[CardData]) -> StringName:
	if cards.size() != SELECTED_HAND_SIZE:
		return &""
	var shared_stat := cards[0].primary_stat
	if not CORE_SCORE_BY_STAT.has(shared_stat):
		return &""
	for card in cards.slice(1):
		if card.primary_stat != shared_stat:
			return &""
	return shared_stat


func _build_specialization_debug_message(specialization_stat: StringName, score_additions: Dictionary[ProjectState.CoreScore, int]) -> String:
	var added_scores: Array[String] = []
	for stat: StringName in [&"graphics", &"sound", &"technology", &"design"]:
		var category: ProjectState.CoreScore = CORE_SCORE_BY_STAT[stat]
		if score_additions.has(category) and score_additions[category] != 0:
			added_scores.append("%s +%d" % [str(stat).capitalize(), score_additions[category]])
	return "Specialization hit: %s Specialization! Added scores: %s" % [
		str(specialization_stat).capitalize(),
		", ".join(added_scores),
	]


func _invalid_base_hand(message: String) -> Dictionary:
	push_warning(message)
	return {
		&"valid": false,
		&"cards": [] as Array[CardData],
		&"score_additions": {},
		&"scope": 0,
		&"bug_pressure": 0.0,
		&"has_feature": false,
		&"contributions": [] as Array[Dictionary],
	}


func _update_play_button() -> void:
	if is_node_ready():
		play_card_button.disabled = not _can_play_selected_hand()
