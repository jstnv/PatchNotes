extends Control

const DesignHandCommand := preload("res://scripts/simulation/design_hand_command.gd")
const ProductionHand := preload("res://scripts/simulation/production_hand.gd")
const BalancedProduction := preload("res://scripts/cards/balanced_production.gd")

var _workspace: PhaseWorkspace
var _command_view_ids: Dictionary = {}
var _command_next_id := 0
var _command_revision := 0
var _hand_command_busy := false
var _last_hand_command_result: Dictionary = {}

signal proceed_to_alpha_requested
signal priorities_changed

const CARD_VIEW_SCENE := preload("res://scenes/cards/card_view.tscn")
const PRIORITY_ALLOCATION_SCRIPT := preload("res://scripts/phases/priority_allocation.gd")
const WEIGHTED_CANDIDATE_MATH := preload("res://scripts/phases/weighted_candidate_math.gd")
const CANDIDATE_POOL_SIZE := 7
const SELECTED_HAND_SIZE := 4
const SPECIALIZATION_MULTIPLIER := ProductionHand.SPECIALIZATION_MULTIPLIER
const BALANCED_PRODUCTION_THRESHOLD := 0.15
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
var _run_state: RunState
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
var _priority_draft: Dictionary[ProjectState.CoreScore, int] = {}
var _employee_priority_choice: Dictionary = {}
var _syncing_priority_controls := false

@onready var graphics_value: Label = %GraphicsValue
@onready var sound_value: Label = %SoundValue
@onready var technology_value: Label = %TechnologyValue
@onready var design_value: Label = %DesignValue
@onready var scope_value: Label = %ScopeValue
@onready var bug_pressure_value: Label = %BugPressureValue
@onready var hand_container: Container = %HandContainer
@onready var play_card_button: Button = %PlayCardButton
@onready var proceed_to_alpha_button: Button = %ProceedToAlphaButton


func _ready() -> void:
	%RedrawButton.pressed.connect(_on_redraw_pressed)
	if _run_state != null: _finalization_rng = _run_state.random_streams.stream(&"design_finalize")
	else: _finalization_rng.randomize()
	if _run_state != null: _deal_rng = _run_state.random_streams.stream(&"design_deal")
	else: _deal_rng.randomize()
	_priority_allocation.allocation_changed.connect(_on_priority_allocation_changed)
	_priority_draft = _priority_allocation.get_priority_distribution()
	play_card_button.pressed.connect(_on_play_card_pressed)
	proceed_to_alpha_button.pressed.connect(_on_proceed_to_alpha_pressed)
	%BeginDesignButton.pressed.connect(_on_begin_design_pressed)
	%CommitPrioritiesButton.pressed.connect(_on_commit_priorities_pressed)
	_update_play_button()
	_refresh_display()
	_sync_priority_controls()

	_workspace = PhaseWorkspace.new()
	add_child(_workspace)
	_workspace.configure(self, "Design")
	_workspace.bind_states(_project_state, _run_state)


func setup(project_state: ProjectState, run_state: RunState = null) -> void:
	if _project_state != null and _project_state.values_changed.is_connected(_refresh_display):
		_project_state.values_changed.disconnect(_refresh_display)

	_project_state = project_state
	_run_state = run_state
	if _run_state != null: _finalization_rng = _run_state.random_streams.stream(&"design_finalize")
	if _run_state != null: _deal_rng = _run_state.random_streams.stream(&"design_deal")
	if _run_state != null and not _run_state.redraws_changed.is_connected(_refresh_redraw_controls):
		_run_state.redraws_changed.connect(_refresh_redraw_controls)
	if _project_state != null:
		_project_state.values_changed.connect(_refresh_display)

	if is_node_ready():
		_refresh_display()
		_refresh_redraw_controls()
	if _workspace != null: _workspace.bind_states(_project_state, _run_state)


## Phase-local planning only. Candidate dealing intentionally does not consume
## this distribution until the separately approved weighted-draw milestone.
func set_priority(category: int, requested_value: Variant) -> bool:
	if _phase_state == PhaseState.PLANNING:
		var changed := _priority_allocation.set_priority(category, requested_value)
		_priority_draft = _priority_allocation.get_priority_distribution()
		_sync_priority_controls()
		return changed
	if not _priority_draft.has(category) or (typeof(requested_value) != TYPE_INT and typeof(requested_value) != TYPE_FLOAT):
		return false
	var value := int(requested_value)
	if value < PriorityAllocation.MIN_PRIORITY or value > PriorityAllocation.MAX_PRIORITY or value % PriorityAllocation.PRIORITY_STEP != 0:
		return false
	_priority_draft[category] = value
	_sync_priority_controls()
	return true


func commit_priority_distribution(distribution: Dictionary = _priority_draft) -> bool:
	if not is_inside_tree(): return false
	if _phase_state == PhaseState.PLANNING and not _finalization_requested:
		if distribution == get_priority_distribution(): return false
		return set_priority_distribution(distribution)
	if _phase_state != PhaseState.ACTIVE_DEVELOPMENT or _finalization_requested or _project_state == null or _run_state == null:
		return false
	if not PriorityAllocation.is_valid_distribution(distribution) or distribution == get_priority_distribution() or not _project_state.can_advance_cycle() or not _run_state.can_advance_calendar_cycle():
		return false
	var commit := func() -> bool:
		if not _priority_allocation.set_distribution(distribution): return false
		_priority_draft = _priority_allocation.get_priority_distribution()
		_project_state.advance_cycle()
		return true
	if not _run_state.complete_productive_action(commit, 0, -1, &"", &"priority_change", _project_state.get_release_id()):
		return false
	_sync_priority_controls()
	return true


func _on_commit_priorities_pressed() -> void:
	commit_priority_distribution()


func get_priority(category: int) -> int:
	return _priority_allocation.get_priority(category)


func get_priority_distribution() -> Dictionary[ProjectState.CoreScore, int]:
	return _priority_allocation.get_priority_distribution()


func get_available_priority() -> int:
	return _priority_allocation.get_available_priority()


func set_priority_distribution(distribution: Dictionary) -> bool:
	if _phase_state != PhaseState.PLANNING or not PriorityAllocation.is_valid_distribution(distribution): return false
	if not _priority_allocation.set_distribution(distribution): return false
	_priority_draft = _priority_allocation.get_priority_distribution()
	_sync_priority_controls()
	return true


func begin_design() -> bool:
	if is_gameplay_input_blocked(): return false
	if _phase_state != PhaseState.PLANNING or _finalization_requested:
		return false
	if not PriorityAllocation.is_valid_distribution(_priority_draft) or not _priority_allocation.set_distribution(_priority_draft) or not _initialize_design_lifecycle():
		push_warning("Could not begin Design because the initial weighted candidate pool could not be dealt.")
		return false
	_phase_state = PhaseState.ACTIVE_DEVELOPMENT
	refresh_workspace()
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
	if _phase_state == PhaseState.PLANNING and (_workspace == null or not _workspace.overlay.visible):
		set_priority(category, int(value))
	else:
		_priority_draft[category] = int(value)
		_sync_priority_controls()


func _sync_priority_controls() -> void:
	if not is_node_ready():
		return
	_syncing_priority_controls = true
	var values := _priority_draft if not _priority_draft.is_empty() else get_priority_distribution()
	%GraphicsPriority.value = values[ProjectState.CoreScore.GRAPHICS]
	%SoundPriority.value = values[ProjectState.CoreScore.SOUND]
	%TechnologyPriority.value = values[ProjectState.CoreScore.TECHNOLOGY]
	%DesignPriority.value = values[ProjectState.CoreScore.DESIGN]
	%GraphicsPriorityValue.text = str(values[ProjectState.CoreScore.GRAPHICS])
	%SoundPriorityValue.text = str(values[ProjectState.CoreScore.SOUND])
	%TechnologyPriorityValue.text = str(values[ProjectState.CoreScore.TECHNOLOGY])
	%DesignPriorityValue.text = str(values[ProjectState.CoreScore.DESIGN])
	var total := 0
	for amount: int in values.values(): total += amount
	%DesignAvailablePriority.text = "Available Priority: %d" % (PriorityAllocation.MAX_TOTAL_PRIORITY - total)
	%CommitPrioritiesButton.disabled = _finalization_requested or not PriorityAllocation.is_valid_distribution(values) or (_phase_state != PhaseState.PLANNING and values == get_priority_distribution())
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
	var definitions: Array[CardData] = []
	definitions.assign(card_database.get_project_features_for_phase(_project_state, CardData.PHASE_DESIGN))
	definitions.append_array(card_database.get_cards_by_phase_and_types(CardData.PHASE_DESIGN, [&"pass"] as Array[StringName]))
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

	_publish_refill(deal)
	return true


func _publish_refill(deal: Dictionary) -> void:
	_command_revision += 1
	_candidate_cards.append_array(deal.cards)
	for feature: CardData in deal.selected_features:
		_available_features.erase(feature)

	for card in deal.cards:
		var card_view: CardView = CARD_VIEW_SCENE.instantiate()
		card_view.set_card(card)
		card_view.card_pressed.connect(_on_card_pressed)

		hand_container.add_child(card_view)
	if deal.has("tutorial_stat"):
		_get_first_game_tutorial().record_deal(deal.tutorial_stat)
	_refresh_redraw_controls()
	refresh_workspace()


func _can_redraw_selection() -> bool:
	if is_gameplay_input_blocked(): return false
	if _phase_state != PhaseState.ACTIVE_DEVELOPMENT or _run_state == null or _finalization_requested or not _run_state.can_consume_redraw(_selected_card_views.size()):
		return false
	var seen: Array[CardView] = []
	for view: CardView in _selected_card_views:
		if not _is_current_candidate_view(view) or view.card_data == null or seen.has(view) or view.card_data.card_type not in [&"feature", &"pass"]:
			return false
		seen.append(view)
	return true


func redraw_selected_cards(controlled_rolls: Array[float] = []) -> bool:
	if not _can_redraw_selection(): return false
	var count := _selected_card_views.size()
	if not controlled_rolls.is_empty() and controlled_rolls.size() != count: return false
	for roll: float in controlled_rolls:
		if not is_finite(roll) or roll < 0.0 or roll >= 1.0: return false
	var rng_state := _deal_rng.state
	var plan := _plan_selected_redraw(controlled_rolls)
	if not plan.valid:
		_deal_rng.state = rng_state
		if not plan.failed_features.is_empty():
			%RedrawFeedbackLabel.text = "No more Feature cards"
			for view: CardView in plan.failed_features: view.shake_no()
		return false
	# Prepare every view before changing the pool, lifecycle, selection, or budget.
	var prepared: Array[CardView] = []
	for card: CardData in plan.cards:
		var replacement_view := CARD_VIEW_SCENE.instantiate() as CardView
		if replacement_view == null:
			for view: CardView in prepared: view.free()
			_deal_rng.state = rng_state
			return false
		replacement_view.set_card(card)
		replacement_view.card_pressed.connect(_on_card_pressed)
		prepared.append(replacement_view)
	var selected := _selected_card_views.duplicate()
	for index in range(count):
		var old_view: CardView = selected[index]
		var slot := old_view.get_index()
		var replacement: CardData = plan.cards[index]
		if replacement.card_type == &"feature":
			_available_features.erase(replacement)
		if old_view.card_data.card_type == &"feature":
			_return_feature_to_available(old_view.card_data)
		_candidate_cards[slot] = replacement

		%HandContainer.remove_child(old_view)
		old_view.queue_free()
		%HandContainer.add_child(prepared[index])
		%HandContainer.move_child(prepared[index], slot)
	_selected_card_views.clear()
	%RedrawFeedbackLabel.text = ""
	if plan.get("guided_redraw", false):
		_get_first_game_tutorial().record_successful_redraw()
	# One budget notification, after the complete pool and selection are committed.
	_command_revision += 1
	_run_state.consume_redraw(count)
	_update_play_button()
	_refresh_redraw_controls()
	return true


func _on_redraw_pressed() -> void:
	redraw_selected_cards()


func _refresh_redraw_controls() -> void:
	if not is_node_ready(): return
	%RedrawButton.text = "Redraw (%d/4)" % (_run_state.get_available_redraws() if _run_state != null else 0)
	%RedrawButton.disabled = not _can_redraw_selection()
	if not %RedrawButton.disabled:
		var rolls: Array[float] = []
		rolls.resize(_selected_card_views.size())
		rolls.fill(0.5)
		%RedrawButton.disabled = not _plan_selected_redraw(rolls).valid


func _plan_selected_redraw(controlled_rolls: Array[float]) -> Dictionary:
	var tutorial := _get_first_game_tutorial()
	if tutorial != null:
		var guided_card := tutorial.guaranteed_redraw(_candidate_cards, _selected_card_views, _pass_definitions)
		if guided_card != null:
			return {&"valid": true, &"cards": [guided_card] as Array[CardData], &"failed_features": [] as Array[CardView], &"guided_redraw": true}
	var cards: Array[CardData] = []
	var reserved: Array[StringName] = []
	var failed_features: Array[CardView] = []
	var valid := true
	for index in range(_selected_card_views.size()):
		var view := _selected_card_views[index]
		var old_card := view.card_data
		var feature_entries: Array[Dictionary] = []
		var pass_entries: Array[Dictionary] = []
		for card: CardData in _available_features:
			if card.id == old_card.id or reserved.has(card.id): continue
			var already_visible := false
			for current: CardData in _candidate_cards:
				if current.id == card.id: already_visible = true
			if already_visible: continue
			var weight := _calculate_candidate_weight(card, get_priority_distribution())
			if weight > 0.0: feature_entries.append({&"card": card, &"weight": weight})
		for card: CardData in _pass_definitions:
			if card.id == old_card.id: continue
			var weight := _calculate_candidate_weight(card, get_priority_distribution())
			if weight > 0.0: pass_entries.append({&"card": card, &"weight": weight})
		feature_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.card.id) < str(b.card.id))
		pass_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.card.id) < str(b.card.id))
		var roll := controlled_rolls[index] if not controlled_rolls.is_empty() else _deal_rng.randf()
		var entries: Array[Dictionary] = []
		var weighted_roll := roll
		if not feature_entries.is_empty() and not pass_entries.is_empty():
			# Split one uniform roll by class, then use its remaining range for
			# priority-weighted selection within that class.
			entries = feature_entries if roll < 0.5 else pass_entries
			weighted_roll = roll * 2.0 if roll < 0.5 else (roll - 0.5) * 2.0
		elif not feature_entries.is_empty():
			entries = feature_entries
		else:
			entries = pass_entries
		var replacement := _select_weighted_entry(entries, weighted_roll)
		if replacement == null:
			valid = false
			if old_card.card_type == &"feature": failed_features.append(view)
		else:
			cards.append(replacement)
			if not replacement.renewable: reserved.append(replacement.id)
	return {&"valid": valid, &"cards": cards, &"failed_features": failed_features}


func _build_weighted_candidate_definitions(priority_snapshot: Dictionary, controlled_rolls: Array[float] = [], candidate_count: int = CANDIDATE_POOL_SIZE) -> Dictionary:
	return _capture_design_command()._build_weighted_candidate_definitions(priority_snapshot, controlled_rolls, candidate_count)


func _select_weighted_entry(entries: Array[Dictionary], roll: float) -> CardData:
	return _capture_design_command()._select_weighted_entry(entries, roll)


func _calculate_candidate_weight(card: CardData, priority_snapshot: Dictionary) -> float:
	return _capture_design_command()._calculate_candidate_weight(card, priority_snapshot)


func _get_deal_input_validation_error(priority_snapshot: Dictionary) -> String:
	return _capture_design_command()._get_deal_input_validation_error(priority_snapshot)


func _get_weighted_definition_validation_error(card: CardData, expected_type: StringName) -> String:
	return _capture_design_command()._get_weighted_definition_validation_error(card, expected_type)


func _clear_candidate_pool() -> void:
	_clear_selection()
	_candidate_cards.clear()
	for child in hand_container.get_children():
		hand_container.remove_child(child)
		child.queue_free()


func _on_card_pressed(card_view: CardView) -> void:
	if is_gameplay_input_blocked(): return
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
	if _hand_command_busy or not _can_play_selected_hand(): return
	_hand_command_busy = true
	var resolver := _capture_design_command()
	var ids: Array[int] = []
	for view in _selected_card_views: ids.append(_command_view_ids[view.get_instance_id()])
	var result: Dictionary = resolver.execute(resolver.command(ids, _employee_priority_choice))
	if not result.ok:
		_hand_command_busy = false
		return
	_exhausted_card_ids.assign(resolver._exhausted_card_ids)
	_available_features.assign(resolver._available_features)
	_priority_allocation.set_distribution(resolver.priorities)
	_priority_draft = _priority_allocation.get_priority_distribution()
	# Commit is complete. Remove played views and publish only the new views.
	var played := _selected_card_views.duplicate()
	_clear_selection()
	for view in played:
		hand_container.remove_child(view)
		view.queue_free()
	_candidate_cards.clear()
	for view in hand_container.get_children():
		if view is CardView: _candidate_cards.append(view.card_data)
	var refill: Dictionary = result.refill.duplicate()
	# Tutorial state is committed by the resolver; publishing views must not repeat it.
	refill.erase("tutorial_stat")
	_publish_refill(refill)
	_command_revision = resolver.revision
	for index in range(hand_container.get_child_count()):
		_command_view_ids[hand_container.get_child(index).get_instance_id()] = resolver.candidate_ids[index]
	_command_next_id = resolver.next_candidate_id
	var current_views := {}
	for view in hand_container.get_children(): current_views[view.get_instance_id()] = _command_view_ids[view.get_instance_id()]
	_command_view_ids = current_views
	_last_hand_command_result = result
	_hand_command_busy = false
	var final_action: Dictionary = result.final_action
	if not final_action.specialization_stat.is_empty():
		_workspace.show_synergy("%s Specialization!" % str(final_action.specialization_stat).capitalize(), "Production Ã—1.50")
	elif final_action.balanced_production:
		_workspace.show_synergy("Balanced Production!", "Hand total shared across four categories")


func _on_proceed_to_alpha_pressed() -> void:
	if is_gameplay_input_blocked(): return
	if _finalization_requested:
		return
	var prior_rng := _finalization_rng.state
	var finalization := _calculate_design_finalization(
		_finalization_rng.randf(),
		_finalization_rng.randf(),
	)
	if not finalization.valid:
		_finalization_rng.state = prior_rng
		return
	var feature_history := _build_design_feature_history()
	if not feature_history.valid:
		_finalization_rng.state = prior_rng
		return
	if not _project_state.finalize_design_bugs(
		finalization.perfect_production,
		finalization.hidden_bugs,
		feature_history.implemented_ids,
		feature_history.unimplemented_ids,
	):
		_finalization_rng.state = prior_rng
		return
	_finalization_requested = true
	%BeginDesignButton.disabled = true
	proceed_to_alpha_button.disabled = true
	_update_play_button()
	if finalization.perfect_production:
		print("Perfect Production!")
		_workspace.show_synergy("Perfect Production!", "Finalization Bug Pressure Ã—0.80")
	print("Final Hidden Bugs: %d" % finalization.hidden_bugs)
	proceed_to_alpha_requested.emit()


func _build_design_feature_history() -> Dictionary:
	var card_database := get_node("/root/CardDatabase")
	var definitions: Array[CardData] = []
	definitions.assign(card_database.get_project_features_for_phase(_project_state, CardData.PHASE_DESIGN))
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


func _return_feature_to_available(card: CardData) -> void:
	if _exhausted_card_ids.has(card.id) or _available_features.has(card):
		return
	_available_features.append(card)


func _can_play_selected_hand() -> bool:
	if _hand_command_busy: return false
	if is_gameplay_input_blocked(): return false
	if _phase_state != PhaseState.ACTIVE_DEVELOPMENT or _finalization_requested or _project_state == null or not _project_state.can_advance_cycle() or (_run_state != null and not _run_state.can_advance_calendar_cycle()) or _selected_card_views.size() != SELECTED_HAND_SIZE:
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
	for view in _selected_card_views: cards.append(view.card_data)
	return _capture_design_command().calculate_base(cards)


func _calculate_feature_bug_pressure(card: CardData) -> float:
	return _capture_design_command()._calculate_feature_bug_pressure(card)


func _calculate_final_action_production(base_hand: Dictionary) -> Dictionary:
	var records: Array = []
	for card: CardData in base_hand.cards:
		records.append({&"primary_stat": card.primary_stat})
	var has_feature: bool = base_hand.has_feature
	var result := ProductionHand.calculate(records, base_hand.score_additions, has_feature)
	# Preserve Design's historical full-category specialization result shape.
	if not result.specialization_stat.is_empty():
		for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
			if not result.score_additions.has(category):
				result.score_additions[category] = 0
	result[&"provisional_scores"] = _calculate_provisional_core_scores(base_hand.score_additions)
	return result


func _calculate_provisional_core_scores(base_additions: Dictionary) -> Dictionary[ProjectState.CoreScore, int]:
	var provisional_scores: Dictionary[ProjectState.CoreScore, int] = {}
	for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
		provisional_scores[category] = _project_state.get_core_score(category) + base_additions.get(category, 0)
	return provisional_scores


func _are_core_scores_balanced(scores: Dictionary) -> bool:
	return BalancedProduction.qualifies(scores)


func _apply_balanced_production(base_additions: Dictionary) -> Dictionary[ProjectState.CoreScore, int]:
	return BalancedProduction.redistribute(base_additions)


func _apply_specialization(base_additions: Dictionary) -> Dictionary[ProjectState.CoreScore, int]:
	var adjusted := ProductionHand.specialize(base_additions)
	for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
		if not adjusted.has(category):
			adjusted[category] = 0
	return adjusted


func _get_card_validation_error(card: CardData) -> String:
	return _capture_design_command()._get_card_validation_error(card)


func _get_specialization_stat(cards: Array[CardData]) -> StringName:
	var records: Array = []
	for card in cards:
		records.append({&"primary_stat": card.primary_stat})
	return ProductionHand.specialization_stat(records)


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
	return _capture_design_command()._invalid_base_hand(message)


func _update_play_button() -> void:
	refresh_workspace()
	_refresh_redraw_controls()
	if is_node_ready():
		play_card_button.text = "Implement"
		play_card_button.tooltip_text = ""
		play_card_button.disabled = not _can_play_selected_hand()
		if _run_state != null and _run_state.uses_first_studio_economy() and _selected_card_views.size() == SELECTED_HAND_SIZE:
			var cards: Array[CardData] = []
			for view: CardView in _selected_card_views:
				cards.append(view.card_data)
			var cost := _run_state.primitive_feature_hand_cost_cents(cards, _project_state.get_release_id())
			if cost >= 0:
				play_card_button.text = "Implement Â· " + CashFormatter.format_exact_cents(cost)
				if _run_state.get_cash_cents() < cost:
					play_card_button.disabled = true
					play_card_button.tooltip_text = "Insufficient cash for this hand."


func get_workspace() -> PhaseWorkspace:
	return _workspace


func _get_first_game_tutorial() -> FirstGameTutorial:
	return _run_state.get_first_game_tutorial(_project_state) if _run_state != null else null


## This is current-pool guidance, not a promise about an ordinary future roll.
func get_first_game_guidance() -> Dictionary:
	var tutorial := _get_first_game_tutorial()
	if tutorial == null or tutorial.stage == FirstGameTutorial.Stage.COMPLETE or _phase_state != PhaseState.ACTIVE_DEVELOPMENT or _finalization_requested:
		return {}
	var stat := tutorial.first_stat if tutorial.stage == FirstGameTutorial.Stage.FIRST_HAND else tutorial.second_stat
	if stat.is_empty(): return {}
	var matching: Array[String] = []
	var other_slots: Array[int] = []
	for index in range(_candidate_cards.size()):
		if _candidate_cards[index].primary_stat == stat:
			matching.append(str(index + 1))
		else:
			other_slots.append(index)
	var core := str(stat).capitalize()
	var selected_match := _selected_card_views.size() == 4
	for view: CardView in _selected_card_views:
		if view.card_data.primary_stat != stat: selected_match = false
	if matching.size() >= 4:
		var first := tutorial.stage == FirstGameTutorial.Stage.FIRST_HAND
		return {"key": "first_game_" + ("first" if first else "redraw") + ("_implement" if selected_match else "_find"),
			"title": ("Implement your %s synergy" if selected_match else "%s Specialization is playable") % core,
			"hint": "First game Â· " + ("Press Implement for %s Specialization." % core if selected_match else "Find four %s primary labels, then Implement. Selected cards lift out of the fan." % core),
			"body": "At least four cards share %s as their primary Core (the first score). Look across the fan to find them. Choose any four matching cards and press Implement for Ã—1.5 hand Core gains. Printed Scope stays the same; Passes add no Scope. Playing still uses one cycle and the shown Feature cost." % core}
	if tutorial.stage == FirstGameTutorial.Stage.REDRAW_HAND and matching.size() == 3 and not other_slots.is_empty():
		if _run_state.get_available_redraws() == 0:
			return {"key": "first_game_redraw_empty", "title": "No redraws left", "hint": "First game Â· Play a hand to restore one redraw.", "body": "This pool is one %s card short of Specialization. Your redraw bank is empty. You can play any affordable four-card hand normally; a successful hand restores one redraw." % core}
		var ready := _selected_card_views.size() == 1 and _selected_card_views[0].card_data.primary_stat != stat
		var wrong_selection := not ready and not _selected_card_views.is_empty()
		var selection_help := "Click selected cards again to deselect them. " if wrong_selection else ""
		return {"key": "first_game_redraw_now" if ready else "first_game_redraw_wrong" if wrong_selection else "first_game_redraw_select",
			"title": "Redraw your selected card" if ready else "One card away from %s Specialization" % core,
			"hint": "First game Â· " + ("Press Redraw for the fourth %s card." % core if ready else "Keep three %s cards. Select only one other card and Redraw." % core),
			"body": selection_help + "Keep the three %s cards unselected for now. Select only one card with a different primary label, then Redraw. This tutorial guarantees a %s Pass: one redraw, zero cash or cycles. Then find all four %s cards in the fan and Implement. Later redraws use normal chance." % [core, core, core]}
	return {"key": "first_game_pool_changed", "title": "Your pool has changed", "hint": "First game Â· Find four matching primary labels, or play another hand.", "body": "Your choices changed the guided pattern. You can still find a Specialization by matching four primary Core labels, or play any affordable four cards normally. The guided opening ends after your second successful Design hand."}


func refresh_workspace() -> void:
	if _workspace != null: _workspace.refresh()


func is_gameplay_input_blocked() -> bool:
	return _hand_command_busy or not is_inside_tree() or (_workspace != null and _workspace.overlay != null and _workspace.overlay.visible)


func can_edit_priorities() -> bool:
	return is_inside_tree() and not _finalization_requested


func is_initial_priority_planning() -> bool:
	return _phase_state == PhaseState.PLANNING


func can_initialize_priorities() -> bool:
	return is_inside_tree() and _phase_state == PhaseState.PLANNING and not _finalization_requested and PriorityAllocation.is_valid_distribution(_priority_draft)


func open_priority_overlay() -> bool:
	return _workspace != null and _workspace.overlay.open()


func reset_priority_draft() -> void:
	_priority_draft = get_priority_distribution()
	_sync_priority_controls()


func get_selected_candidate_views() -> Array[CardView]:
	return _selected_card_views.duplicate()


func refresh_overlay_actions() -> void:
	_update_play_button()


func get_employee_hand_status() -> Dictionary:
	if _run_state == null or _project_state == null: return {}
	var roster := _run_state.get_employees()
	var base := _validate_and_calculate_base_action()
	return {"hired":not roster.employees.is_empty(),"available":EmployeeRoster.available(roster,_project_state.get_release_id()),"qualifying":base.get("valid",false) and EmployeeRoster.matches(EmployeeRoster.card_facts(base.get("cards",[])))}


func play_hand_with_employee_plan(distribution: Dictionary) -> bool:
	if not _employee_priority_choice.is_empty() or not PriorityAllocation.is_valid_distribution(distribution) or distribution == get_priority_distribution(): return false
	var before := _project_state.get_current_cycle()
	_employee_priority_choice = distribution.duplicate()
	_on_play_card_pressed()
	_employee_priority_choice.clear()
	return _project_state.get_current_cycle() == before+1


## Copy phase-local mechanics into the command boundary. Candidate tokens refer
## to instances, so repeated Pass definitions remain distinct. No visual order
## or global Object instance ID is passed to the resolver.
func _capture_design_command() -> RefCounted:
	var state := DesignHandCommand.new()
	state._project_state = _project_state
	state._run_state = _run_state
	state._deal_rng = _deal_rng
	state._available_features.assign(_available_features)
	state._pass_definitions.assign(_pass_definitions)
	state._candidate_cards.assign(_candidate_cards)
	state._exhausted_card_ids.assign(_exhausted_card_ids)
	state.priorities = get_priority_distribution()
	state.active = _phase_state == PhaseState.ACTIVE_DEVELOPMENT
	state.finalization_requested = _finalization_requested
	state.revision = _command_revision
	if is_instance_valid(hand_container):
		for view in hand_container.get_children():
			if not view is CardView: continue
			var id := view.get_instance_id()
			if not _command_view_ids.has(id):
				_command_view_ids[id] = _command_next_id
				_command_next_id += 1
			state.candidate_ids.append(_command_view_ids[id])
	state.next_candidate_id = _command_next_id
	return state
