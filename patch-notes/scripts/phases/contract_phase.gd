class_name ContractPhase
extends Control

signal completion_dismissed(source: ContractPhase)

const CARD_VIEW_SCENE := preload("res://scenes/cards/card_view.tscn")
const CANDIDATE_COUNT := 7
const HAND_SIZE := 4

var _state: ContractState
var _run: RunState
var _candidate_cards: Array[CardData] = []
var _selected_views: Array[CardView] = []
var _priority_draft: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _initial_category_rolls: Array[float] = []
var _initial_definition_rolls: Array[float] = []

var _candidate_row: HBoxContainer
var _status_label: Label
var _scores_label: Label
var _feedback_label: Label
var _play_button: Button
var _redraw_button: Button
var _commit_button: Button
var _priority_inputs: Dictionary = {}
var _completion_panel: PanelContainer
var _completion_stats: Label


func setup(state: ContractState, run: RunState, category_rolls: Array[float] = [], definition_rolls: Array[float] = []) -> bool:
	if state == null or run == null or run.get_primitive_contract() != state:
		return false
	if not category_rolls.is_empty() and category_rolls.size() != CANDIDATE_COUNT:
		return false
	if not definition_rolls.is_empty() and definition_rolls.size() != CANDIDATE_COUNT:
		return false
	_state = state
	_run = run
	_initial_category_rolls = category_rolls.duplicate()
	_initial_definition_rolls = definition_rolls.duplicate()
	_priority_draft = state.get_priority_distribution()
	if is_node_ready():
		_initialize_presentation()
	return true


func _ready() -> void:
	_rng.randomize()
	_build_ui()
	if _state != null:
		_initialize_presentation()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)
	var title := Label.new()
	title.text = "Balanced Primitive Contract"
	title.add_theme_font_size_override("font_size", 25)
	layout.add_child(title)
	_status_label = Label.new()
	layout.add_child(_status_label)
	_scores_label = Label.new()
	_scores_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_scores_label)
	var priority_row := HBoxContainer.new()
	priority_row.add_theme_constant_override("separation", 10)
	layout.add_child(priority_row)
	for category: ProjectState.CoreScore in PriorityAllocation.CORE_CATEGORIES:
		var box := VBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var label := Label.new()
		label.text = _category_name(category)
		box.add_child(label)
		var input := SpinBox.new()
		input.min_value = PriorityAllocation.MIN_PRIORITY
		input.max_value = PriorityAllocation.MAX_PRIORITY
		input.step = PriorityAllocation.PRIORITY_STEP
		input.value_changed.connect(func(value: float): _priority_draft[category] = int(value); _refresh_actions())
		box.add_child(input)
		_priority_inputs[category] = input
		priority_row.add_child(box)
	_commit_button = Button.new()
	_commit_button.text = "Commit Priorities (1 cycle)"
	_commit_button.pressed.connect(func(): commit_priority_distribution())
	priority_row.add_child(_commit_button)
	var pool_title := Label.new()
	pool_title.text = "Contract Draw — select exactly four cards"
	layout.add_child(pool_title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	_candidate_row = HBoxContainer.new()
	_candidate_row.add_theme_constant_override("separation", 8)
	scroll.add_child(_candidate_row)
	var actions := HBoxContainer.new()
	layout.add_child(actions)
	_play_button = Button.new()
	_play_button.text = "Play Contract Hand"
	_play_button.pressed.connect(_play_selected_hand)
	actions.add_child(_play_button)
	_redraw_button = Button.new()
	_redraw_button.pressed.connect(func(): redraw_selected_cards())
	actions.add_child(_redraw_button)
	_feedback_label = Label.new()
	_feedback_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(_feedback_label)
	_build_completion_panel()


func _build_completion_panel() -> void:
	_completion_panel = PanelContainer.new()
	_completion_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_completion_panel.custom_minimum_size = Vector2(560, 360)
	_completion_panel.visible = false
	add_child(_completion_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	_completion_panel.add_child(content)
	var title := Label.new()
	title.text = "Contract Complete"
	title.add_theme_font_size_override("font_size", 26)
	content.add_child(title)
	_completion_stats = Label.new()
	_completion_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_completion_stats)
	var dismiss := Button.new()
	dismiss.name = "DismissCompletionButton"
	dismiss.unique_name_in_owner = true
	dismiss.text = "Return to Studio"
	dismiss.pressed.connect(func(): completion_dismissed.emit(self))
	content.add_child(dismiss)


func _initialize_presentation() -> void:
	_priority_draft = _state.get_priority_distribution()
	_sync_priority_inputs()
	if _state.is_completed():
		_show_completion()
	elif _candidate_cards.is_empty():
		var deal := _build_candidate_pool({}, _initial_category_rolls, _initial_definition_rolls)
		_initial_category_rolls.clear()
		_initial_definition_rolls.clear()
		if deal.is_empty():
			_feedback_label.text = "The contract draw could not be prepared."
		else:
			_publish_candidate_pool(deal)
	_refresh_all()


func get_contract_state() -> ContractState:
	return _state


func get_selected_candidate_views() -> Array[CardView]:
	return _selected_views.duplicate()


func get_candidate_cards() -> Array[CardData]:
	return _candidate_cards.duplicate()


func can_edit_priorities() -> bool:
	return _state != null and not _state.is_completed() and _run.can_complete_productive_cycle()


func set_priority_draft(distribution: Dictionary) -> bool:
	if not PriorityAllocation.is_valid_distribution(distribution):
		return false
	_priority_draft = distribution.duplicate()
	_sync_priority_inputs()
	_refresh_actions()
	return true


func commit_priority_distribution(distribution: Dictionary = _priority_draft) -> bool:
	if _state == null or not _state.can_commit_priorities(distribution) or not _run.can_complete_productive_cycle():
		return false
	var expected_cycle := _run.get_completed_run_cycles()
	var commit := func() -> bool: return _state.commit_priorities(distribution)
	if not _run.complete_productive_action(commit, 0, expected_cycle):
		return false
	_priority_draft = _state.get_priority_distribution()
	_sync_priority_inputs()
	_feedback_label.text = "Priorities committed. The current draw is unchanged."
	_refresh_all()
	return true


func redraw_selected_cards(category_rolls: Array[float] = [], definition_rolls: Array[float] = []) -> bool:
	var count := _selected_views.size()
	if _state == null or _state.is_completed() or count == 0 or not _run.can_consume_redraw(count):
		return false
	if (not category_rolls.is_empty() and category_rolls.size() != count) or (not definition_rolls.is_empty() and definition_rolls.size() != count):
		return false
	var replacements: Array[CardData] = []
	var reserved_features: Dictionary = {}
	for visible_card in _candidate_cards:
		if visible_card.card_type == &"feature": reserved_features[visible_card.id] = true
	for index in range(count):
		var old := _selected_views[index].card_data
		var category_roll := category_rolls[index] if not category_rolls.is_empty() else _rng.randf()
		var definition_roll := definition_rolls[index] if not definition_rolls.is_empty() else _rng.randf()
		var replacement := _draw_one(old.card_type, reserved_features, category_roll, definition_roll, old.id)
		if replacement == null:
			return false
		replacements.append(replacement)
		if replacement.card_type == &"feature": reserved_features[replacement.id] = true
	var old_views := _selected_views.duplicate()
	for index in range(count):
		var old_view: CardView = old_views[index]
		var slot := old_view.get_index()
		_candidate_cards[slot] = replacements[index]
		var replacement_view := _make_card_view(replacements[index])
		_candidate_row.remove_child(old_view)
		old_view.queue_free()
		_candidate_row.add_child(replacement_view)
		_candidate_row.move_child(replacement_view, slot)
	_selected_views.clear()
	_run.consume_redraw(count)
	_feedback_label.text = "Selected cards redrawn."
	_refresh_all()
	return true


func _play_selected_hand() -> bool:
	if _state == null or _state.is_completed() or _selected_views.size() != HAND_SIZE:
		return false
	var cards: Array[CardData] = []
	for view in _selected_views: cards.append(view.card_data)
	var plan := _state.plan_hand(cards)
	if plan.is_empty():
		return false
	var payout: int = plan.payout_cents
	if not _run.can_complete_productive_cycle(payout):
		return false
	var next_cards: Array[CardData] = []
	if not plan.completing:
		var projected_exhausted: Dictionary = {}
		for id: StringName in plan.exhausted_ids: projected_exhausted[id] = true
		next_cards = _build_candidate_pool(projected_exhausted)
		if next_cards.is_empty():
			return false
	var expected_cycle := _run.get_completed_run_cycles()
	var commit := func() -> bool: return _state.commit_hand(cards, payout)
	if not _run.complete_productive_action(commit, payout, expected_cycle):
		return false
	if _state.is_completed():
		_show_completion()
	else:
		_publish_candidate_pool(next_cards)
		_feedback_label.text = "Hand complete. Draw two is ready."
	_refresh_all()
	return true


func _build_candidate_pool(extra_exhausted: Dictionary = {}, category_rolls: Array[float] = [], definition_rolls: Array[float] = []) -> Array[CardData]:
	if (not category_rolls.is_empty() and category_rolls.size() != CANDIDATE_COUNT) or (not definition_rolls.is_empty() and definition_rolls.size() != CANDIDATE_COUNT):
		return []
	var cards: Array[CardData] = []
	var reserved: Dictionary = extra_exhausted.duplicate()
	for slot in range(CANDIDATE_COUNT):
		var category_roll := category_rolls[slot] if not category_rolls.is_empty() else _rng.randf()
		var definition_roll := definition_rolls[slot] if not definition_rolls.is_empty() else _rng.randf()
		var card := _draw_one(&"", reserved, category_roll, definition_roll)
		if card == null:
			return []
		cards.append(card)
		if card.card_type == &"feature": reserved[card.id] = true
	return cards


func _draw_one(type_filter: StringName, reserved_features: Dictionary, category_roll: float, definition_roll: float, excluded_id: StringName = &"") -> CardData:
	if not is_finite(category_roll) or category_roll < 0.0 or category_roll >= 1.0 or not is_finite(definition_roll) or definition_roll < 0.0 or definition_roll >= 1.0:
		return null
	var by_category: Dictionary = {}
	for category: ProjectState.CoreScore in PriorityAllocation.CORE_CATEGORIES: by_category[category] = []
	var database := get_node_or_null("/root/CardDatabase")
	if database == null: return null
	for id in _state.get_eligible_feature_ids():
		if reserved_features.has(id) or _state.is_feature_exhausted(id) or id == excluded_id: continue
		var card: CardData = database.get_card(id)
		if card != null and (type_filter.is_empty() or type_filter == &"feature"):
			by_category[ContractState.CORE_BY_STAT[card.primary_stat]].append(card)
	for id in ContractState.PASS_IDS:
		if id == excluded_id: continue
		var pass_card: CardData = database.get_card(id)
		if pass_card != null and (type_filter.is_empty() or type_filter == &"pass"):
			by_category[ContractState.CORE_BY_STAT[pass_card.primary_stat]].append(pass_card)
	var available_categories: Array[ProjectState.CoreScore] = []
	var total_weight := 0
	var priorities := _state.get_priority_distribution()
	for category: ProjectState.CoreScore in PriorityAllocation.CORE_CATEGORIES:
		if not by_category[category].is_empty():
			available_categories.append(category)
			total_weight += priorities[category]
	if total_weight <= 0: return null
	var target := category_roll * total_weight
	var cumulative := 0
	var chosen := available_categories[-1]
	for category in available_categories:
		cumulative += priorities[category]
		if target < cumulative:
			chosen = category
			break
	var definitions: Array = by_category[chosen]
	definitions.sort_custom(func(a: CardData, b: CardData) -> bool: return str(a.id) < str(b.id))
	return definitions[mini(floori(definition_roll * definitions.size()), definitions.size() - 1)]


func _publish_candidate_pool(cards: Array[CardData]) -> void:
	for child in _candidate_row.get_children():
		_candidate_row.remove_child(child)
		child.free()
	_candidate_cards = cards.duplicate()
	_selected_views.clear()
	for card in cards: _candidate_row.add_child(_make_card_view(card))


func _make_card_view(card: CardData) -> CardView:
	var view := CARD_VIEW_SCENE.instantiate() as CardView
	view.set_card(card)
	view.custom_minimum_size = Vector2(154, 300)
	view.card_pressed.connect(_on_card_pressed)
	return view


func _on_card_pressed(view: CardView) -> void:
	if _state.is_completed() or view not in _candidate_row.get_children(): return
	if _selected_views.has(view):
		_selected_views.erase(view)
		view.set_selected(false)
	elif _selected_views.size() < HAND_SIZE:
		_selected_views.append(view)
		view.set_selected(true)
	_refresh_actions()


func _show_completion() -> void:
	var result := _state.get_result()
	if result == null: return
	_completion_stats.text = "Final Scope: %d / %d\nGraphics: %s / 6\nSound: %s / 6\nTechnology: %s / 6\nDesign: %s / 6\nCompletion: %.1f%%\nExact Payout: %s" % [
		result.get_scope(), ContractState.EXPECTED_SCOPE,
		_format_half(result.get_core_score_half_units(ProjectState.CoreScore.GRAPHICS)),
		_format_half(result.get_core_score_half_units(ProjectState.CoreScore.SOUND)),
		_format_half(result.get_core_score_half_units(ProjectState.CoreScore.TECHNOLOGY)),
		_format_half(result.get_core_score_half_units(ProjectState.CoreScore.DESIGN)),
		result.get_completion_percent(), CashFormatter.format_exact_cents(result.get_payout_cents())]
	_completion_panel.show()
	(_completion_panel.find_child("DismissCompletionButton", true, false) as Button).grab_focus()


func _refresh_all() -> void:
	if _state == null: return
	_status_label.text = "Hand %d / %d · Date: %s · Redraws: %d / 4" % [_state.get_successful_hand_count(), ContractState.REQUIRED_HANDS, _run.get_calendar_label(), _run.get_available_redraws()]
	_scores_label.text = "Scope %d / 12 · Graphics %s · Sound %s · Technology %s · Design %s" % [
		_state.get_scope(), _format_half(_state.get_core_score_half_units(ProjectState.CoreScore.GRAPHICS)),
		_format_half(_state.get_core_score_half_units(ProjectState.CoreScore.SOUND)), _format_half(_state.get_core_score_half_units(ProjectState.CoreScore.TECHNOLOGY)),
		_format_half(_state.get_core_score_half_units(ProjectState.CoreScore.DESIGN))]
	_refresh_actions()


func _refresh_actions() -> void:
	if _state == null: return
	_play_button.disabled = _state.is_completed() or _selected_views.size() != HAND_SIZE or _state.plan_hand(_selected_cards()).is_empty()
	_redraw_button.text = "Redraw Selected (%d/4)" % _run.get_available_redraws()
	_redraw_button.disabled = _state.is_completed() or _selected_views.is_empty() or not _run.can_consume_redraw(_selected_views.size())
	_commit_button.disabled = not _state.can_commit_priorities(_priority_draft) or not _run.can_complete_productive_cycle()


func _selected_cards() -> Array[CardData]:
	var cards: Array[CardData] = []
	for view in _selected_views: cards.append(view.card_data)
	return cards


func _sync_priority_inputs() -> void:
	for category: ProjectState.CoreScore in PriorityAllocation.CORE_CATEGORIES:
		(_priority_inputs[category] as SpinBox).set_value_no_signal(_priority_draft[category])


func _format_half(half_units: int) -> String:
	return str(half_units / 2) if half_units % 2 == 0 else "%d.5" % (half_units / 2)


func _category_name(category: ProjectState.CoreScore) -> String:
	return ["Graphics", "Sound", "Technology", "Design"][category]
