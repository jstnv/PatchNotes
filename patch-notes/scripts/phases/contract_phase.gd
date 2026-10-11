class_name ContractPhase
extends Control

signal completion_dismissed(source: ContractPhase)
signal guidance_changed

const CARD_VIEW_SCENE := preload("res://scenes/cards/card_view.tscn")
const CANDIDATE_COUNT := 7
const HAND_SIZE := 4
const ContractSession := preload("res://scripts/simulation/contract_session.gd")
var _command_ids: Dictionary = {}
var _command_next_id := 0
var _command_sequence := 0
var _command_busy := false

var _state: ContractState
var _run: RunState
var _candidate_cards: Array[CardData] = []
var _selected_views: Array[CardView] = []
var _priority_draft: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _initial_category_rolls: Array[float] = []
var _initial_definition_rolls: Array[float] = []

var _candidate_row: CardFan
var hand_motion: HandPresentation
var _presented_scores: Dictionary = {}
var _status_label: Label
var _scores_label: Label
var _feedback_label: Label
var _play_button: Button
var _redraw_button: Button
var _commit_button: Button
var _priority_inputs: Dictionary = {}
var _completion_panel: PanelContainer
var _completion_stats: Label
var _title: Label
var _score_values: Array[Label] = []
var _change_priorities: Button
var _priority_modal: CanvasLayer
var _priority_chart: PriorityInfluenceChart
var _completion_modal: CanvasLayer


func setup(state: ContractState, run: RunState, category_rolls: Array[float] = [], definition_rolls: Array[float] = []) -> bool:
	if state == null or run == null or not run.owns_contract_state(state):
		return false
	if not category_rolls.is_empty() and category_rolls.size() != CANDIDATE_COUNT:
		return false
	if not definition_rolls.is_empty() and definition_rolls.size() != CANDIDATE_COUNT:
		return false
	for roll:float in category_rolls+definition_rolls:
		if not is_finite(roll) or roll<0.0 or roll>=1.0:return false
	_state = state
	_run = run
	if _run != null: _rng = _run.random_streams.stream(&"contract_deal")
	_initial_category_rolls = category_rolls.duplicate()
	_initial_definition_rolls = definition_rolls.duplicate()
	_priority_draft = state.get_priority_distribution()
	if is_node_ready():
		return _initialize_presentation()
	return true


func _ready() -> void:
	if _run != null: _rng = _run.random_streams.stream(&"contract_deal")
	else: _rng.randomize()
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
	_title = Label.new()
	_title.text = "Balanced Primitive Contract"
	_title.add_theme_font_size_override("font_size", 25)
	var header := PanelContainer.new()
	header.name = "ContractHeader"
	layout.add_child(header)
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 18)
	header.add_child(header_row)
	for category in ["Graphics", "Sound", "Tech", "Design", "Scope"]:
		var value := Label.new()
		value.name = category + "Counter"
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header_row.add_child(value)
		_score_values.append(value)
	_change_priorities = Button.new()
	_change_priorities.text = "Change Priorities"
	_change_priorities.pressed.connect(open_priority_overlay)
	header_row.add_child(_change_priorities)
	layout.add_child(_title)
	_status_label = Label.new()
	layout.add_child(_status_label)
	_scores_label = Label.new()
	_scores_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_scores_label.hide()
	layout.add_child(_scores_label)
	var priority_row := VBoxContainer.new()
	priority_row.add_theme_constant_override("separation", 10)
	priority_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	priority_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_priority_modal = CanvasLayer.new()
	_priority_modal.layer = 20
	add_child(_priority_modal)
	var priority_content := _modal_content(_priority_modal, Vector2(640, 380))
	var priority_title := Label.new()
	priority_title.text = "Change Priorities"
	priority_title.add_theme_font_size_override("font_size", 24)
	priority_content.add_child(priority_title)
	var help := Label.new()
	help.text = "Future draws only · total 100 · 5–50 in steps of 5\nChanged priorities cost 1 cycle. Cancel is free."
	priority_content.add_child(help)
	var priority_body := HBoxContainer.new()
	priority_body.add_theme_constant_override("separation", 24)
	priority_content.add_child(priority_body)
	priority_body.add_child(priority_row)
	for category: ProjectState.CoreScore in PriorityAllocation.CORE_CATEGORIES:
		var box := HBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var label := Label.new()
		label.text = PriorityInfluenceChart.CORE_NAMES[category]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_color_override("font_color", PriorityInfluenceChart.CORE_COLORS[category])
		box.add_child(label)
		var input := SpinBox.new()
		input.min_value = PriorityAllocation.MIN_PRIORITY
		input.max_value = PriorityAllocation.MAX_PRIORITY
		input.step = PriorityAllocation.PRIORITY_STEP
		input.tooltip_text = "Weight future %s contract draws. All four priorities must total 100." % _category_name(category)
		input.value_changed.connect(func(value: float): _priority_draft[category] = int(value); _refresh_actions())
		box.add_child(input)
		_priority_inputs[category] = input
		priority_row.add_child(box)
	_priority_chart = PriorityInfluenceChart.new()
	priority_body.add_child(_priority_chart)
	_priority_chart.bind_controls(_priority_inputs.values(), PriorityInfluenceChart.CORE_NAMES, PriorityInfluenceChart.CORE_COLORS)
	_commit_button = Button.new()
	_commit_button.text = "Commit Priorities (1 cycle)"
	_commit_button.tooltip_text = "A valid changed allocation costs one cycle and affects later draws, not the current hand."
	_commit_button.pressed.connect(func():
		if commit_priority_distribution(): _priority_modal.hide())
	var priority_actions := HBoxContainer.new()
	priority_content.add_child(priority_actions)
	priority_actions.add_child(_commit_button)
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.pressed.connect(func():
		_priority_draft = _state.get_priority_distribution()
		_sync_priority_inputs()
		_priority_modal.hide()
		_change_priorities.grab_focus())
	priority_actions.add_child(cancel)
	_priority_modal.hide()
	var pool_title := Label.new()
	pool_title.text = "Contract Draw — select exactly four cards"
	layout.add_child(pool_title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	_candidate_row = CardFan.new()
	_candidate_row.custom_minimum_size.y = 280
	scroll.add_child(_candidate_row)
	var actions := HBoxContainer.new()
	layout.add_child(actions)
	_play_button = Button.new()
	_play_button.text = "Play Contract Hand"
	_play_button.tooltip_text = "Play exactly four selected cards. A successful hand advances one cycle."
	_play_button.pressed.connect(_present_action.bind("play", _play_selected_hand))
	actions.add_child(_play_button)
	_redraw_button = Button.new()
	_redraw_button.tooltip_text = "Replace selected candidates using the shared redraw budget; no cycle cost."
	_redraw_button.pressed.connect(_present_action.bind("redraw", redraw_selected_cards))
	actions.add_child(_redraw_button)
	_feedback_label = Label.new()
	_feedback_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(_feedback_label)
	_build_completion_panel()
	hand_motion = HandPresentation.new()
	add_child(hand_motion)
	var organize := Button.new()
	organize.name = "OrganizePoolButton"
	organize.text = "Sort by Category"
	organize.tooltip_text = "Alternate category (Graphics, Sound, Tech, Design) and Scope (highest first). The button names the next sort. No cash, cycle or redraw cost."
	organize.pressed.connect(func():
		if not hand_motion.busy: organize.text = _candidate_row.cycle_organization())
	hand_motion.busy_changed.connect(func():
		organize.disabled = hand_motion.busy or _state.is_completed()
		_refresh_actions())
	actions.add_child(organize)
	actions.move_child(organize, _redraw_button.get_index() + 1)

func _present_action(kind: String, action: Callable) -> void:
	if hand_motion.busy: return
	if hand_motion.play(kind, _candidate_row, _selected_views, action, _score_snapshot, _display_scores, _restore_scores):
		if _state.is_completed(): _completion_modal.hide()

func _score_snapshot() -> Dictionary:
	var values := {&"scope": _state.get_scope(), "_cycle": _run.get_completed_run_cycles(), "_redraws": _run.get_available_redraws()}
	for i in range(4): values[HandPresentation.CORE[i]] = _state.get_core_score_half_units(i)
	return values

func _display_scores(values: Dictionary, deltas: Dictionary) -> void:
	_presented_scores = values.duplicate()
	_refresh_all()
	var parts: Array[String] = []
	for key: StringName in deltas:
		if deltas[key] == 0: continue
		parts.append("+%s %s" % [str(deltas[key]) if key == &"scope" else _format_half(deltas[key]), str(key).capitalize()])
	if parts.is_empty(): return
	var pulse := Label.new()
	pulse.text = " · ".join(parts)
	pulse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pulse.z_index = 200
	pulse.add_theme_color_override("font_color", Color("f5ce69"))
	add_child(pulse)
	pulse.global_position = _score_values[0].global_position + Vector2(0, 20)
	var tween := pulse.create_tween().set_parallel()
	tween.tween_property(pulse, "position:y", pulse.position.y - 16.0, 0.55)
	tween.tween_property(pulse, "modulate:a", 0.0, 0.55)
	tween.chain().tween_callback(pulse.queue_free)

func _restore_scores() -> void:
	_presented_scores.clear()
	_refresh_all()
	if _state.is_completed(): _show_completion()


func _modal_content(layer: CanvasLayer, minimum: Vector2) -> VBoxContainer:
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.01, 0.015, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.add_child(center)
	var panel := PanelContainer.new()
	panel.name = "ContractModal"
	panel.theme = preload("res://resources/ui/workspace_theme.tres")
	var surface := StyleBoxFlat.new()
	surface.bg_color = Color("#1b1b21")
	surface.border_color = Color("#665447")
	surface.set_border_width_all(1)
	surface.set_corner_radius_all(6)
	surface.content_margin_left = 18
	surface.content_margin_right = 18
	surface.content_margin_top = 16
	surface.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", surface)
	panel.custom_minimum_size = minimum
	center.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)
	return content


func open_priority_overlay() -> void:
	if not can_edit_priorities() or hand_motion.busy: return
	_priority_draft = _state.get_priority_distribution()
	_sync_priority_inputs()
	_refresh_actions()
	_priority_modal.show()
	(_priority_inputs[ProjectState.CoreScore.GRAPHICS] as SpinBox).get_line_edit().grab_focus()


func _build_completion_panel() -> void:
	_completion_modal = CanvasLayer.new()
	_completion_modal.layer = 30
	add_child(_completion_modal)
	var content := _modal_content(_completion_modal, Vector2(560, 360))
	_completion_panel = content.get_parent() as PanelContainer
	_completion_panel.hide()
	_completion_modal.hide()
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


func _initialize_presentation() -> bool:
	_title.text = _state.get_title()
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
			_refresh_all()
			return false
		else:
			_publish_candidate_pool(deal)
	_refresh_all()
	return true


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
	if _command_busy or _state == null: return false
	_command_busy = true
	var ok: bool = _capture_contract().commit_priorities(distribution)
	_command_busy = false
	if not ok: return false
	_command_sequence += 1
	_priority_draft = _state.get_priority_distribution()
	_sync_priority_inputs()
	_feedback_label.text = "Priorities committed. The current draw is unchanged."
	_refresh_all()
	return true



func redraw_selected_cards(category_rolls: Array[float] = [], definition_rolls: Array[float] = []) -> bool:
	if _command_busy or _state == null: return false
	_command_busy = true
	var session := _capture_contract()
	var old_views := _selected_views.duplicate()
	var slots: Array[int] = []
	for view in old_views: slots.append(view.get_index())
	var prepared: Array[CardView] = []
	var readiness := func(replacements: Array[CardData]) -> bool:
		for card in replacements: prepared.append(_make_card_view(card))
		return true
	var publish := func(replacements: Array[CardData]) -> void:
		for index in range(old_views.size()):
			var old_view: CardView = old_views[index]
			var slot: int = slots[index]
			_candidate_cards[slot] = replacements[index]
			_candidate_row.remove_child(old_view)
			old_view.queue_free()
			_candidate_row.add_child(prepared[index])
			_candidate_row.move_child(prepared[index],slot)
		_selected_views.clear()
	var result: Dictionary = session.redraw(slots,category_rolls,definition_rolls,readiness,publish)
	if result.ok:
		session.sequence += 1
		_sync_contract_tokens(session)
	else:
		for view in prepared:
			if view.get_parent() == null: view.free()
	_command_busy = false
	if not result.ok: return false
	_feedback_label.text = "Selected cards redrawn."
	_refresh_all()
	return true



func _play_selected_hand() -> bool:
	if _command_busy or _state == null: return false
	_command_busy = true
	var session := _capture_contract()
	var ids: Array[int] = []
	for view in _selected_views:
		if not _command_ids.has(view.get_instance_id()):
			_command_busy = false
			return false
		ids.append(_command_ids[view.get_instance_id()])
	var result: Dictionary = session.execute(session.command(&"play",{"candidate_ids":ids}))
	if not result.ok:
		_command_busy = false
		_feedback_label.text = _run.get_financial_block_reason()
		return false
	if _state.is_completed(): _show_completion()
	else:
		_publish_candidate_pool(result.replacements,true)
		_feedback_label.text = "Hand complete. Draw %d is ready." % (_state.get_successful_hand_count()+1)
	_sync_contract_tokens(session)
	_command_busy = false
	_refresh_all()
	return true



func _build_candidate_pool(extra_exhausted: Dictionary = {}, category_rolls: Array[float] = [], definition_rolls: Array[float] = [], candidate_count: int = CANDIDATE_COUNT) -> Array[CardData]:
	return _capture_contract()._build_candidate_pool(extra_exhausted,category_rolls,definition_rolls,candidate_count)



func _draw_one(type_filter: StringName, reserved_features: Dictionary, category_roll: float, definition_roll: float, excluded_id: StringName = &"") -> CardData:
	return _capture_contract()._draw_one(type_filter,reserved_features,category_roll,definition_roll,excluded_id)



func _publish_candidate_pool(cards: Array[CardData], retain_unselected := false) -> void:
	_candidate_cards.clear()
	for child in _candidate_row.get_children():
		if not child is CardView: continue
		if retain_unselected and child not in _selected_views:
			_candidate_cards.append(child.card_data)
			continue
		child.set_selected(false)
		_candidate_row.remove_child(child)
		child.queue_free()
	_selected_views.clear()
	_candidate_cards.append_array(cards)
	for card in cards: _candidate_row.add_child(_make_card_view(card))


func _make_card_view(card: CardData) -> CardView:
	var view := CARD_VIEW_SCENE.instantiate() as CardView
	view.set_card(card)
	view.custom_minimum_size = Vector2(154, 300)
	view.card_pressed.connect(_on_card_pressed)
	return view


func _on_card_pressed(view: CardView) -> void:
	if _state.is_completed() or hand_motion.busy or _priority_modal.visible or view not in _candidate_row.get_children(): return
	if _selected_views.has(view):
		_selected_views.erase(view)
		view.set_selected(false)
	elif _selected_views.size() < HAND_SIZE:
		_selected_views.append(view)
		view.set_selected(true)
	_refresh_actions()


func _show_completion() -> void:
	# The authoritative action completes before its visual replay. Do not cover it.
	if hand_motion != null and (hand_motion.capturing or hand_motion.busy): return
	var result := _state.get_result()
	if result == null: return
	_completion_stats.text = "Final Scope: %d / %d\nGraphics: %s / %s\nSound: %s / %s\nTechnology: %s / %s\nDesign: %s / %s\nCompletion: %.1f%%\nGuaranteed Upfront: %s\nCompletion Payment: %s\nTotal Payout: %s" % [
		result.get_scope(), _state.get_scope_target(),
		_format_half(result.get_core_score_half_units(ProjectState.CoreScore.GRAPHICS)), _format_half(_state.get_core_target(0)),
		_format_half(result.get_core_score_half_units(ProjectState.CoreScore.SOUND)), _format_half(_state.get_core_target(1)),
		_format_half(result.get_core_score_half_units(ProjectState.CoreScore.TECHNOLOGY)), _format_half(_state.get_core_target(2)),
		_format_half(result.get_core_score_half_units(ProjectState.CoreScore.DESIGN)), _format_half(_state.get_core_target(3)),
		result.get_completion_percent(), CashFormatter.format_exact_cents(result.get_upfront_cents()),
		CashFormatter.format_exact_cents(result.get_completion_payment_cents()), CashFormatter.format_exact_cents(result.get_payout_cents())]
	if _state.get_contract_id()==PublisherTrialTerms.STARWAVE:
		_completion_stats.text += "\nNo Promotion from this Contract. Existing awards are unchanged."
	elif not _state._trial_terms.is_empty(): _completion_stats.text += "\nPromotion earned: %d Awareness for the next successful launch" % result.get_promotion()
	_selected_views.clear()
	_candidate_row.hide()
	_priority_modal.hide()
	_completion_modal.show()
	_completion_panel.show()
	(_completion_panel.find_child("DismissCompletionButton", true, false) as Button).grab_focus()


func _refresh_all() -> void:
	if _state == null: return
	_status_label.text = "Hands remaining: %d / %d · Select exactly four cards" % [maxi(0, _state.get_required_hands() - _state.get_successful_hand_count()), _state.get_required_hands()]
	if _state.get_contract_id()==PublisherTrialTerms.STARWAVE:
		var cores := {}
		for category in range(4): cores[category] = _state.get_core_score_half_units(category)
		var earned := _state.calculate_for_state(_state.get_scope(),cores)
		_status_label.text += "\nCash at current completion: %s · Paid after hand 3 · No Promotion" % CashFormatter.format_exact_cents(earned.get("remainder_cents",0))
	for i in range(4):
		_score_values[i].text = "%s\n%s / %s" % [["Graphics", "Sound", "Tech", "Design"][i], _format_half(_presented_scores.get(HandPresentation.CORE[i], _state.get_core_score_half_units(i))), _format_half(_state.get_core_target(i))]
	_score_values[4].text = "Scope\n%d / %d" % [_presented_scores.get(&"scope", _state.get_scope()), _state.get_scope_target()]
	_scores_label.text = "Scope %d / %d · Graphics %s · Sound %s · Technology %s · Design %s" % [
		_presented_scores.get(&"scope", _state.get_scope()), _state.get_scope_target(), _format_half(_presented_scores.get(&"graphics", _state.get_core_score_half_units(ProjectState.CoreScore.GRAPHICS))),
		_format_half(_presented_scores.get(&"sound", _state.get_core_score_half_units(ProjectState.CoreScore.SOUND))), _format_half(_presented_scores.get(&"technology", _state.get_core_score_half_units(ProjectState.CoreScore.TECHNOLOGY))),
		_format_half(_presented_scores.get(&"design", _state.get_core_score_half_units(ProjectState.CoreScore.DESIGN)))]
	_refresh_actions()


func _refresh_actions() -> void:
	if _state == null: return
	var animating := hand_motion != null and hand_motion.busy
	_change_priorities.disabled = animating or not can_edit_priorities()
	var plan := _state.plan_hand(_selected_cards()) if _selected_views.size() == HAND_SIZE else {}
	_play_button.disabled = animating or _state.is_completed() or plan.is_empty() or not _run.can_complete_productive_cycle(int(plan.get("remainder_cents", 0)))
	_play_button.tooltip_text = _run.get_financial_block_reason() if _play_button.disabled else ""
	_redraw_button.text = "Redraw Selected (%d/4)" % _run.get_available_redraws()
	_redraw_button.disabled = animating or _state.is_completed() or _selected_views.is_empty() or not _run.can_consume_redraw(_selected_views.size())
	_commit_button.disabled = not _state.can_commit_priorities(_priority_draft) or not _run.can_complete_productive_cycle()
	guidance_changed.emit()


func _selected_cards() -> Array[CardData]:
	var cards: Array[CardData] = []
	for view in _selected_views: cards.append(view.card_data)
	return cards


func _sync_priority_inputs() -> void:
	for category: ProjectState.CoreScore in PriorityAllocation.CORE_CATEGORIES:
		(_priority_inputs[category] as SpinBox).set_value_no_signal(_priority_draft[category])
	_priority_chart.refresh_from_controls()


func _format_half(half_units: int) -> String:
	return str(half_units / 2) if half_units % 2 == 0 else "%d.5" % (half_units / 2)


func _category_name(category: ProjectState.CoreScore) -> String:
	return ["Graphics", "Sound", "Technology", "Design"][category]


func _capture_contract() -> RefCounted:
	var database := get_node_or_null("/root/CardDatabase") if is_inside_tree() else null
	var session := ContractSession.new(_state,_run,database.get_development_catalog() if database != null else null)
	session._rng = _rng
	session.cards = _candidate_cards.duplicate()
	session.next_id = _command_next_id
	session.sequence = _command_sequence
	if _candidate_row != null:
		for child in _candidate_row.get_children():
			if not child is CardView: continue
			if not _command_ids.has(child.get_instance_id()):
				_command_ids[child.get_instance_id()] = session.next_id
				session.next_id += 1
			session.candidate_ids.append(_command_ids[child.get_instance_id()])
	_command_next_id = session.next_id
	return session

func _sync_contract_tokens(session: RefCounted) -> void:
	_command_ids.clear()
	var index := 0
	for child in _candidate_row.get_children():
		if not child is CardView: continue
		_command_ids[child.get_instance_id()] = session.candidate_ids[index]
		index += 1
	_command_next_id = session.next_id
	_command_sequence = session.sequence
