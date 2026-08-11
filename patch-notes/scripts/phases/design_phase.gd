class_name DesignPhase
extends Control

const CARD_VIEW_SCENE := preload("res://scenes/cards/card_view.tscn")
const CANDIDATE_POOL_SIZE := 7
const SELECTED_HAND_SIZE := 4
const SPECIALIZATION_MULTIPLIER := 1.5
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

@onready var graphics_value: Label = %GraphicsValue
@onready var sound_value: Label = %SoundValue
@onready var technology_value: Label = %TechnologyValue
@onready var design_value: Label = %DesignValue
@onready var scope_value: Label = %ScopeValue
@onready var hand_container: HBoxContainer = %HandContainer
@onready var play_card_button: Button = %PlayCardButton


func _ready() -> void:
	play_card_button.pressed.connect(_on_play_card_pressed)
	_update_play_button()
	_refresh_display()
	_initialize_design_lifecycle()


func setup(project_state: ProjectState) -> void:
	if _project_state != null and _project_state.values_changed.is_connected(_refresh_display):
		_project_state.values_changed.disconnect(_refresh_display)

	_project_state = project_state
	if _project_state != null:
		_project_state.values_changed.connect(_refresh_display)

	if is_node_ready():
		_refresh_display()


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


func _initialize_design_lifecycle() -> void:
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
	_deal_next_candidate_pool()


func _deal_next_candidate_pool() -> void:
	if not _candidate_cards.is_empty():
		push_warning("Cannot deal a new Design candidate pool while the current pool is active.")
		return

	var shuffled_features := _available_features.duplicate()
	shuffled_features.shuffle()
	var feature_count := mini(CANDIDATE_POOL_SIZE, shuffled_features.size())
	_candidate_cards.assign(shuffled_features.slice(0, feature_count))
	for card in _candidate_cards:
		_available_features.erase(card)

	while _candidate_cards.size() < CANDIDATE_POOL_SIZE and not _pass_definitions.is_empty():
		_candidate_cards.append(_pass_definitions.pick_random())

	for card in _candidate_cards:
		var card_view: CardView = CARD_VIEW_SCENE.instantiate()
		card_view.set_card(card)
		card_view.card_pressed.connect(_on_card_pressed)
		hand_container.add_child(card_view)


func _clear_candidate_pool() -> void:
	_clear_selection()
	_candidate_cards.clear()
	for child in hand_container.get_children():
		hand_container.remove_child(child)
		child.queue_free()


func _on_card_pressed(card_view: CardView) -> void:
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
	if not _can_play_selected_hand():
		return

	var aggregate := _validate_and_aggregate_selected_hand()
	if not aggregate.valid:
		return

	var additions: Dictionary[ProjectState.CoreScore, int] = aggregate.score_additions
	if not _project_state.add_core_scores_and_scope(additions, aggregate.scope):
		return

	_complete_successful_cycle()


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
	_deal_next_candidate_pool()


func _return_feature_to_available(card: CardData) -> void:
	if _exhausted_card_ids.has(card.id) or _available_features.has(card):
		return
	_available_features.append(card)


func _can_play_selected_hand() -> bool:
	if _project_state == null or _selected_card_views.size() != SELECTED_HAND_SIZE:
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


func _validate_and_aggregate_selected_hand() -> Dictionary:
	var cards: Array[CardData] = []
	for card_view in _selected_card_views:
		var card := card_view.card_data
		var validation_error := _get_card_validation_error(card)
		if not validation_error.is_empty():
			return _invalid_hand(validation_error)
		cards.append(card)

	var specialization_stat := _get_specialization_stat(cards)
	var score_additions: Dictionary[ProjectState.CoreScore, int] = {}
	var total_scope := 0
	for card in cards:
		var primary_category: ProjectState.CoreScore = CORE_SCORE_BY_STAT[card.primary_stat]
		var primary_amount := _adjust_score_contribution(card.primary_value, not specialization_stat.is_empty())
		score_additions[primary_category] = score_additions.get(primary_category, 0) + primary_amount
		total_scope += card.scope

		if card.secondary_stat.is_empty():
			continue

		var secondary_category: ProjectState.CoreScore = CORE_SCORE_BY_STAT[card.secondary_stat]
		var secondary_amount := _adjust_score_contribution(card.secondary_value, not specialization_stat.is_empty())
		score_additions[secondary_category] = score_additions.get(secondary_category, 0) + secondary_amount

	return {
		&"valid": true,
		&"specialization_stat": specialization_stat,
		&"score_additions": score_additions,
		&"scope": total_scope,
	}


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


func _adjust_score_contribution(base_score: int, specialized: bool) -> int:
	if not specialized:
		return base_score
	return ceili(base_score * SPECIALIZATION_MULTIPLIER)


func _invalid_hand(message: String) -> Dictionary:
	push_warning(message)
	return {
		&"valid": false,
		&"specialization_stat": &"",
		&"score_additions": {},
		&"scope": 0,
	}


func _update_play_button() -> void:
	if is_node_ready():
		play_card_button.disabled = not _can_play_selected_hand()
