class_name AlphaPhase
extends Control

const DevelopmentActions := preload("res://scripts/simulation/development_actions.gd")

const AlphaHandCommand := preload("res://scripts/simulation/alpha_hand_command.gd")

var _command_view_ids: Dictionary = {}
var _command_next_id := 0
var _command_revision := 0
var _hand_command_busy := false
var _last_hand_command_result: Dictionary = {}

const ProductionHand := preload("res://scripts/simulation/production_hand.gd")
const BalancedProduction := preload("res://scripts/cards/balanced_production.gd")

var _workspace: PhaseWorkspace

signal priorities_changed
signal proceed_to_beta_requested

const CARD_VIEW_SCENE := preload("res://scenes/cards/card_view.tscn")
const PRIORITY_ALLOCATION_SCRIPT := preload("res://scripts/phases/priority_allocation.gd")
const WEIGHTED_CANDIDATE_MATH := preload("res://scripts/phases/weighted_candidate_math.gd")
const CANDIDATE_POOL_SIZE := 7
const SELECTED_HAND_SIZE := 4
const ALPHA_BUG_PRESSURE_DENOMINATOR := 18.0
const ALPHA_SPECIALIZATION_MULTIPLIER := ProductionHand.SPECIALIZATION_MULTIPLIER
const ALPHA_BALANCED_PRODUCTION_THRESHOLD := 0.15
const BUG_VARIANCE_NEGATIVE_TWO_THRESHOLD := 0.08
const BUG_VARIANCE_NEGATIVE_ONE_THRESHOLD := 0.25
const BUG_VARIANCE_ZERO_THRESHOLD := 0.75
const BUG_VARIANCE_POSITIVE_ONE_THRESHOLD := 0.92
const ALPHA_DEPARTMENTS: Array[StringName] = [&"story", &"gameplay", &"world_design", &"audio"]
const CORE_SCORE_BY_STAT := {
	&"graphics": ProjectState.CoreScore.GRAPHICS,
	&"sound": ProjectState.CoreScore.SOUND,
	&"technology": ProjectState.CoreScore.TECHNOLOGY,
	&"design": ProjectState.CoreScore.DESIGN,
}

enum PhaseState { PLANNING, ACTIVE_DEVELOPMENT, FINALIZED }

var _project_state: ProjectState
var _run_state: RunState
var _phase_state := PhaseState.PLANNING
var _priority_allocation := PRIORITY_ALLOCATION_SCRIPT.new()
var _priority_draft: Dictionary[ProjectState.CoreScore, int] = {}
var _employee_priority_choice: Dictionary = {}
var _syncing_priority_controls := false
var _available_features: Array[CardData] = []
var _pass_definitions: Array[CardData] = []
var _candidate_cards: Array[CardData] = []
var _selected_card_views: Array[CardView] = []
var _exhausted_feature_ids: Dictionary[StringName, bool] = {}
var _pending_playtest_categories: Array[ProjectState.CoreScore] = []
var _deal_rng := RandomNumberGenerator.new()
var _finalization_rng := RandomNumberGenerator.new()
var _scope_warning_pending := false


func _ready() -> void:
	%RedrawButton.pressed.connect(_on_redraw_pressed)
	if _run_state != null: _deal_rng = _run_state.random_streams.stream(&"alpha_deal")
	else: _deal_rng.randomize()
	if _run_state != null: _finalization_rng = _run_state.random_streams.stream(&"alpha_finalize")
	else: _finalization_rng.randomize()
	_priority_allocation.allocation_changed.connect(_on_priority_allocation_changed)
	_priority_draft = _priority_allocation.get_priority_distribution()
	%BeginAlphaButton.pressed.connect(_on_begin_alpha_pressed)
	%CommitPrioritiesButton.pressed.connect(_on_commit_priorities_pressed)
	%PlayAlphaHandButton.pressed.connect(_on_play_alpha_hand_pressed)
	%HostPlaytestButton.pressed.connect(_on_host_playtest_pressed)
	%ProceedToBetaButton.pressed.connect(_on_proceed_to_beta_pressed)
	%UnderScopeDialog.confirmed.connect(_on_under_scope_confirmed)
	%UnderScopeDialog.canceled.connect(_on_under_scope_canceled)
	_sync_priority_controls()
	_refresh_alpha_bug_pressure()
	_update_play_action()
	_update_host_playtest_action()
	_update_proceed_action()

	_workspace = PhaseWorkspace.new()
	add_child(_workspace)
	_workspace.configure(self, "Alpha")
	_workspace.bind_states(_project_state, _run_state)


func setup(project_state: ProjectState, run_state: RunState = null) -> void:
	if _project_state != null and _project_state.values_changed.is_connected(_refresh_alpha_bug_pressure):
		_project_state.values_changed.disconnect(_refresh_alpha_bug_pressure)
	_project_state = project_state
	_run_state = run_state
	if _run_state != null: _finalization_rng = _run_state.random_streams.stream(&"alpha_finalize")
	if _run_state != null: _deal_rng = _run_state.random_streams.stream(&"alpha_deal")
	if _run_state != null and not _run_state.redraws_changed.is_connected(_refresh_redraw_controls):
		_run_state.redraws_changed.connect(_refresh_redraw_controls)
	if _project_state != null and not _project_state.values_changed.is_connected(_refresh_alpha_bug_pressure):
		_project_state.values_changed.connect(_refresh_alpha_bug_pressure)
	_refresh_alpha_bug_pressure()
	_update_host_playtest_action()
	_update_proceed_action()
	_refresh_redraw_controls()
	if _workspace != null: _workspace.bind_states(_project_state, _run_state)


func set_priority(category: int, requested_value: Variant) -> bool:
	if _phase_state == PhaseState.FINALIZED:
		return false
	if _phase_state == PhaseState.PLANNING:
		var accepted := _priority_allocation.set_priority(category, requested_value)
		_priority_draft = _priority_allocation.get_priority_distribution()
		_sync_priority_controls()
		return accepted
	if not _priority_draft.has(category) or (typeof(requested_value) != TYPE_INT and typeof(requested_value) != TYPE_FLOAT): return false
	var value := int(requested_value)
	if value < PriorityAllocation.MIN_PRIORITY or value > PriorityAllocation.MAX_PRIORITY or value % PriorityAllocation.PRIORITY_STEP != 0: return false
	_priority_draft[category] = value
	_sync_priority_controls()
	return true


func commit_priority_distribution(distribution: Dictionary = _priority_draft) -> bool:
	if not is_inside_tree(): return false
	if _phase_state != PhaseState.ACTIVE_DEVELOPMENT or _project_state == null or _run_state == null or not PriorityAllocation.is_valid_distribution(distribution) or distribution == get_priority_distribution() or not _project_state.can_advance_cycle() or not _run_state.can_advance_calendar_cycle(): return false
	var publish:=func() -> void:
		_priority_draft=_priority_allocation.get_priority_distribution()
	if not DevelopmentActions.commit_priorities(_project_state,_run_state,_priority_allocation,distribution,publish): return false
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


func get_selected_candidate_count() -> int:
	return _selected_card_views.size()


func get_pending_playtest_categories() -> Array[ProjectState.CoreScore]:
	return _pending_playtest_categories.duplicate()


func begin_alpha(controlled_rolls: Array[float] = []) -> bool:
	if is_gameplay_input_blocked(): return false
	if _phase_state != PhaseState.PLANNING:
		return false
	if not PriorityAllocation.is_valid_distribution(_priority_draft) or not _priority_allocation.set_distribution(_priority_draft) or not _load_source_definitions():
		return false
	if not _deal_next_candidate_pool(controlled_rolls):
		push_warning("Could not begin Alpha because its weighted candidate pool is invalid.")
		return false
	_phase_state = PhaseState.ACTIVE_DEVELOPMENT
	refresh_workspace()
	%BeginAlphaButton.visible = false
	%BeginAlphaButton.disabled = true
	_update_host_playtest_action()
	_update_proceed_action()
	return true


func _on_begin_alpha_pressed() -> void:
	begin_alpha()


func host_playtest() -> bool:
	if not _can_host_playtest(): return false
	_hand_command_busy=true
	var actions:=_capture_development_actions()
	actions.hand._pending_playtest_categories=_pending_playtest_categories
	var accepted: bool = actions.host_playtest()
	_hand_command_busy=false
	_update_host_playtest_action()
	return accepted


func _on_host_playtest_pressed() -> void:
	host_playtest()


func request_proceed_to_beta() -> bool:
	if not _can_proceed_to_beta() or _scope_warning_pending:
		return false
	if _project_state.get_current_scope() < _project_state.get_required_scope():
		_scope_warning_pending = true
		var actual := _project_state.get_current_scope()
		var required := _project_state.get_required_scope()
		var shortfall := required - actual
		%UnderScopeDialog.dialog_text = (
			"Project Scope is incomplete: %d / %d.\n"
			+ "Scope shortfall: %d.\n"
			+ "Releasing under Scope will reduce the final review.\n"
			+ "Proceed to Beta anyway?"
		) % [actual, required, shortfall]
		%UnderScopeDialog.popup_centered()
		return false
	return _finalize_with_run_rng()


func _on_proceed_to_beta_pressed() -> void:
	request_proceed_to_beta()


func _on_under_scope_confirmed() -> void:
	if not _scope_warning_pending:
		return
	_scope_warning_pending = false
	if not _can_proceed_to_beta():
		return
	_finalize_with_run_rng()


func _on_under_scope_canceled() -> void:
	_scope_warning_pending = false


func _can_proceed_to_beta() -> bool:
	if is_gameplay_input_blocked(): return false
	return (
		_phase_state == PhaseState.ACTIVE_DEVELOPMENT
		and _project_state != null
		and _project_state.can_advance_cycle()
		and (_run_state == null or _run_state.can_transition_without_productive_cycle())
		and not _project_state.has_alpha_finalization()
		and _has_valid_active_candidate_pool()
		and _build_alpha_feature_history(false).valid
		and _has_launch_feature_work()
	)


func _has_launch_feature_work() -> bool:
	if _project_state == null:
		return false
	var history := _build_alpha_feature_history(false)
	return history.valid and _project_state.has_launch_feature_work(history.implemented_ids)


func _update_proceed_action() -> void:
	if not is_node_ready():
		return
	%ProceedToBetaButton.disabled = not _can_proceed_to_beta() or _scope_warning_pending
	%ProceedToBetaButton.tooltip_text = "" if _has_launch_feature_work() else "Play at least one Feature with positive Scope before Beta. Passes alone cannot make a releasable game."


func _build_alpha_feature_history(report_errors: bool = true) -> Dictionary:
	return _capture_development_actions().boundary()._build_alpha_feature_history(report_errors)


func _calculate_alpha_finalization(stochastic_roll: float, variance_roll: float) -> Dictionary:
	return _capture_development_actions().boundary()._calculate_alpha_finalization(stochastic_roll,variance_roll)


func _get_alpha_bug_variance(roll: float) -> int:
	return _capture_development_actions().boundary()._get_alpha_bug_variance(roll)


func _finalize_alpha(stochastic_roll: float, variance_roll: float) -> bool:
	if not _can_proceed_to_beta():
		return false
	var discarded_playtest:=not _pending_playtest_categories.is_empty()
	_hand_command_busy=true
	var result: Dictionary = _capture_development_actions().finalize([stochastic_roll,variance_roll] as Array[float])
	_hand_command_busy=false
	if not result.ok: return false
	var feature_history: Dictionary = result.history
	var finalization: Dictionary = result.finalization
	_pending_playtest_categories.clear()
	_retire_alpha()
	print(
		"Alpha completed! Pressure %.4f; stochastic result %d; variance %+d; Alpha Hidden Bugs %d; total Hidden Bugs %d; implemented %d; unimplemented %d%s"
		% [
			finalization.pressure,
			finalization.rounded,
			finalization.variance,
			finalization.generated,
			_project_state.get_hidden_bugs(),
			feature_history.implemented_ids.size(),
			feature_history.unimplemented_ids.size(),
			"; pending Playtest discarded" if discarded_playtest else "",
		]
	)
	proceed_to_beta_requested.emit()
	return true


func _retire_alpha() -> void:
	_phase_state = PhaseState.FINALIZED
	_scope_warning_pending = false
	for card_view: CardView in _selected_card_views:
		if is_instance_valid(card_view):
			card_view.set_selected(false)
	_selected_card_views.clear()
	%BeginAlphaButton.disabled = true
	%PlayAlphaHandButton.disabled = true
	%HostPlaytestButton.disabled = true
	%ProceedToBetaButton.disabled = true
	%GraphicsPriority.editable = false
	%SoundPriority.editable = false
	%TechnologyPriority.editable = false
	%DesignPriority.editable = false


func _can_host_playtest() -> bool:
	if is_gameplay_input_blocked(): return false
	return (
		_phase_state == PhaseState.ACTIVE_DEVELOPMENT
		and _project_state != null
		and _pending_playtest_categories.is_empty()
		and _project_state.can_advance_cycle()
		and (_run_state == null or _run_state.can_complete_productive_cycle())
		and _has_valid_active_candidate_pool()
	)


func _has_valid_active_candidate_pool() -> bool:
	if not is_node_ready() or _candidate_cards.size() != CANDIDATE_POOL_SIZE or %HandContainer.get_child_count() != CANDIDATE_POOL_SIZE:
		return false
	var seen_feature_ids: Dictionary[StringName, bool] = {}
	for index in range(CANDIDATE_POOL_SIZE):
		var card: CardData = _candidate_cards[index]
		var child := %HandContainer.get_child(index)
		if not child is CardView or (child as CardView).card_data != card:
			return false
		if card.card_type == &"feature":
			if not _get_feature_validation_error(card).is_empty() or not _available_features.has(card) or _exhausted_feature_ids.has(card.id) or seen_feature_ids.has(card.id):
				return false
			seen_feature_ids[card.id] = true
		elif card.card_type == &"pass":
			if not _get_pass_validation_error(card).is_empty() or not _pass_definitions.has(card):
				return false
		else:
			return false
	return true


func _select_corrective_categories() -> Array[ProjectState.CoreScore]:
	return _capture_development_actions().corrective_categories()


func _format_corrective_pass_names(categories: Array) -> String:
	var names: Array[String] = []
	for category: ProjectState.CoreScore in categories:
		names.append("%s Pass" % ProjectState.CoreScore.keys()[category].capitalize())
	return ", ".join(names)


func _update_host_playtest_action() -> void:
	if not is_node_ready():
		return
	%HostPlaytestButton.text = "Playtest Pending" if not _pending_playtest_categories.is_empty() else "Host Playtest"
	%HostPlaytestButton.disabled = not _can_host_playtest()


func _load_source_definitions() -> bool:
	var card_database := get_node_or_null("/root/CardDatabase")
	if card_database == null:
		push_warning("Alpha cannot load candidates without CardDatabase.")
		return false
	var features: Array[CardData] = []
	features.assign(card_database.get_project_features_for_phase(_project_state, CardData.PHASE_ALPHA))
	var passes: Array[CardData] = []
	passes.assign(card_database.call(&"get_cards_by_phase_and_types", CardData.PHASE_DESIGN, [&"pass"] as Array[StringName]))
	_available_features = features
	_pass_definitions = passes
	return true


func _deal_next_candidate_pool(controlled_rolls: Array[float] = []) -> bool:
	if not _candidate_cards.is_empty():
		push_warning("Cannot deal Alpha candidates while a pool is active.")
		return false
	var actions:=_capture_development_actions()
	var deal: Dictionary = actions.initial_plan(controlled_rolls)
	if not deal.valid:
		push_warning("Could not build a complete weighted Alpha candidate pool: %s" % deal.error)
		return false
	actions.publish_initial(deal)
	_candidate_cards.assign(actions.hand._candidate_cards)
	_pending_playtest_categories.assign(actions.hand._pending_playtest_categories)
	for card: CardData in _candidate_cards:
		var card_view := CARD_VIEW_SCENE.instantiate() as CardView
		card_view.set_card(card)
		card_view.card_pressed.connect(_on_card_pressed)

		%HandContainer.add_child(card_view)
	_sync_command_tokens(actions.hand)
	_update_host_playtest_action()
	_update_proceed_action()
	_refresh_redraw_controls()
	return true


func _can_redraw_selection() -> bool:
	if is_gameplay_input_blocked(): return false
	if _phase_state != PhaseState.ACTIVE_DEVELOPMENT or _run_state == null or not _run_state.can_consume_redraw(_selected_card_views.size()):
		return false
	var seen: Array[CardView] = []
	for view: CardView in _selected_card_views:
		if not _is_current_candidate_view(view) or view.card_data == null or seen.has(view) or view.card_data.card_type not in [&"feature", &"pass"]:
			return false
		seen.append(view)
	return true


func redraw_selected_cards(controlled_rolls: Array[float] = []) -> bool:
	if not _can_redraw_selection(): return false
	_hand_command_busy=true
	var actions:=_capture_development_actions()
	var slots:=_redraw_slots()
	var selected:=_selected_card_views.duplicate()
	var prepared: Array[CardView] = []
	var prepare:=func(cards: Array) -> bool:
		for card: CardData in cards:
			var view: CardView = CARD_VIEW_SCENE.instantiate() as CardView
			if view==null: return false
			view.set_card(card)
			view.card_pressed.connect(_on_card_pressed)
			prepared.append(view)
		return true
	var publish:=func(_plan: Dictionary) -> void:
		_candidate_cards.assign(actions.hand._candidate_cards)

		for index in range(slots.size()):
			var old: CardView = selected[index]
			%HandContainer.remove_child(old)
			old.queue_free()
			%HandContainer.add_child(prepared[index])
			%HandContainer.move_child(prepared[index],slots[index])

		_selected_card_views.clear()
		_sync_command_tokens(actions.hand)
	var result: Dictionary = actions.redraw(slots,controlled_rolls,prepare,publish)
	if not result.ok:
		for view in prepared: view.free()
		if not result.plan.failed_features.is_empty():
			%RedrawFeedbackLabel.text="No more Feature cards"
			for slot: int in result.plan.failed_features: (%HandContainer.get_child(slot) as CardView).shake_no()
	else:
		%RedrawFeedbackLabel.text=""
		_sync_command_tokens(actions.hand)
	_hand_command_busy=false
	_update_play_action()
	_refresh_redraw_controls()
	return result.ok


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
	var plan: Dictionary = _capture_development_actions().redraw_plan(_redraw_slots(),controlled_rolls)
	var failed: Array[CardView] = []
	for slot: int in plan.failed_features: failed.append(%HandContainer.get_child(slot))
	plan.failed_features=failed
	return plan


func _build_corrective_candidate_definitions(priority_snapshot: Dictionary, controlled_rolls: Array[float] = [], candidate_count: int = CANDIDATE_POOL_SIZE, excluded_ids: Array[StringName] = []) -> Dictionary:
	return _capture_alpha_command()._build_corrective_candidate_definitions(priority_snapshot, controlled_rolls, candidate_count, excluded_ids)


func _build_weighted_candidate_definitions(priority_snapshot: Dictionary, controlled_rolls: Array[float] = [], candidate_count: int = CANDIDATE_POOL_SIZE, excluded_ids: Array[StringName] = []) -> Dictionary:
	return _capture_alpha_command()._build_weighted_candidate_definitions(priority_snapshot, controlled_rolls, candidate_count, excluded_ids)


func _select_weighted_entry(entries: Array[Dictionary], roll: float) -> CardData:
	return _capture_alpha_command()._select_weighted_entry(entries, roll)


func _calculate_candidate_weight(card: CardData, priority_snapshot: Dictionary) -> float:
	return _capture_alpha_command()._calculate_candidate_weight(card, priority_snapshot)


func _get_deal_input_validation_error(priority_snapshot: Dictionary, controlled_rolls: Array[float], candidate_count: int = CANDIDATE_POOL_SIZE) -> String:
	return _capture_alpha_command()._get_deal_input_validation_error(priority_snapshot, controlled_rolls, candidate_count)


func _get_pass_for_category(category: ProjectState.CoreScore) -> CardData:
	return _capture_alpha_command()._get_pass_for_category(category)


func _get_feature_validation_error(card: CardData) -> String:
	return _capture_alpha_command()._get_feature_validation_error(card)


func _get_pass_validation_error(card: CardData) -> String:
	return _capture_alpha_command()._get_pass_validation_error(card)


func _get_printed_score_validation_error(card: CardData) -> String:
	return _capture_alpha_command()._get_printed_score_validation_error(card)


func _on_card_pressed(card_view: CardView) -> void:
	if is_gameplay_input_blocked(): return
	if _phase_state != PhaseState.ACTIVE_DEVELOPMENT or not _is_current_candidate_view(card_view):
		return
	if _selected_card_views.has(card_view):
		_selected_card_views.erase(card_view)
		card_view.set_selected(false)
	elif _selected_card_views.size() < SELECTED_HAND_SIZE:
		_selected_card_views.append(card_view)
		card_view.set_selected(true)
	else:
		push_warning("Exactly four Alpha candidates may be selected.")
	_update_play_action()


func _is_current_candidate_view(card_view: CardView) -> bool:
	return card_view != null and is_instance_valid(card_view) and card_view.get_parent() == %HandContainer


func _update_play_action() -> void:
	refresh_workspace()
	_refresh_redraw_controls()
	if not is_node_ready():
		return
	%PlayAlphaHandButton.disabled = not _can_play_selected_instances()
	%PlayAlphaHandButton.text = "Implement"
	%PlayAlphaHandButton.tooltip_text = ""
	if _run_state != null and _run_state.uses_first_studio_economy() and _selected_card_views.size() == SELECTED_HAND_SIZE:
		var cards: Array[CardData] = []
		for view: CardView in _selected_card_views:
			cards.append(view.card_data)
		var cost := _run_state.primitive_feature_hand_cost_cents(cards, _project_state.get_release_id())
		if cost >= 0:
			%PlayAlphaHandButton.text = "Implement · " + CashFormatter.format_exact_cents(cost)
			if _run_state.get_cash_cents() < cost:
				%PlayAlphaHandButton.disabled = true
				%PlayAlphaHandButton.tooltip_text = "Insufficient cash for this hand."


func _can_play_selected_instances() -> bool:
	if is_gameplay_input_blocked(): return false
	if _phase_state != PhaseState.ACTIVE_DEVELOPMENT or _project_state == null or not _project_state.can_advance_cycle() or (_run_state != null and not _run_state.can_advance_calendar_cycle()) or _selected_card_views.size() != SELECTED_HAND_SIZE:
		return false
	var seen: Dictionary[int, bool] = {}
	for card_view: CardView in _selected_card_views:
		if not _is_current_candidate_view(card_view) or seen.has(card_view.get_instance_id()):
			return false
		seen[card_view.get_instance_id()] = true
	return true


func _on_play_alpha_hand_pressed() -> void:
	if _hand_command_busy or not _can_play_selected_instances(): return
	_hand_command_busy = true
	var resolver := _capture_alpha_command()
	var ids: Array[int] = []
	for view in _selected_card_views: ids.append(_command_view_ids[view.get_instance_id()])
	var result: Dictionary = resolver.execute(resolver.command(ids, _employee_priority_choice))
	if not result.ok:
		_hand_command_busy = false
		return
	_available_features.assign(resolver._available_features)
	_exhausted_feature_ids.assign(resolver._exhausted_feature_ids)
	_pending_playtest_categories.assign(resolver._pending_playtest_categories)
	_priority_allocation.set_distribution(resolver.priorities)
	_priority_draft = _priority_allocation.get_priority_distribution()
	# The command has committed all gameplay; only update presentation here.
	var played := _selected_card_views.duplicate()
	_selected_card_views.clear()
	for view in played:
		view.set_selected(false)
		%HandContainer.remove_child(view)
		view.queue_free()
	_candidate_cards.assign(resolver._candidate_cards)
	for card: CardData in result.refill.cards:
		var view := CARD_VIEW_SCENE.instantiate() as CardView
		view.set_card(card)
		view.card_pressed.connect(_on_card_pressed)
		%HandContainer.add_child(view)
	_command_revision = resolver.revision
	_command_next_id = resolver.next_candidate_id
	_command_view_ids.clear()
	for index in range(%HandContainer.get_child_count()):
		_command_view_ids[%HandContainer.get_child(index).get_instance_id()] = resolver.candidate_ids[index]
	_last_hand_command_result = result
	_hand_command_busy = false
	_refresh_redraw_controls()
	_update_host_playtest_action()
	_update_proceed_action()
	var final_production: Dictionary = result.final_action
	if not final_production.specialization_stat.is_empty():
		print(_build_specialization_debug_message(final_production.specialization_stat, final_production.score_additions))
		_workspace.show_synergy("%s Specialization!" % str(final_production.specialization_stat).capitalize(), "Production ×1.50")
	elif final_production.balanced_production:
		print(_build_balanced_production_debug_message(final_production.score_additions))
		_workspace.show_synergy("Balanced Production!", "Hand total shared across four categories")


func _validate_and_calculate_base_action() -> Dictionary:
	if not _can_play_selected_instances(): return _invalid_action("A complete Alpha action requires four current candidate instances.")
	var cards: Array[CardData] = []
	for view in _selected_card_views: cards.append(view.card_data)
	return _capture_alpha_command().calculate_base(cards)


func _calculate_final_action_production(base_action: Dictionary) -> Dictionary:
	return _capture_alpha_command()._calculate_final_action_production(base_action)


func _calculate_provisional_core_scores(base_additions: Dictionary) -> Dictionary[ProjectState.CoreScore, int]:
	return _capture_alpha_command()._calculate_provisional_core_scores(base_additions)


func _are_core_scores_balanced(scores: Dictionary) -> bool:
	return BalancedProduction.qualifies(scores)


func _get_specialization_stat(cards: Array[CardData]) -> StringName:
	var records: Array = []
	for card in cards:
		records.append({&"primary_stat": card.primary_stat})
	return ProductionHand.specialization_stat(records)


func _build_specialization_debug_message(specialization_stat: StringName, score_additions: Dictionary) -> String:
	var parts: Array[String] = []
	for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
		var amount: int = score_additions.get(category, 0)
		if amount != 0:
			parts.append("%s +%d" % [ProjectState.CoreScore.keys()[category].capitalize(), amount])
	return "Alpha Specialization hit: %s Specialization! Added scores: %s" % [
		str(specialization_stat).capitalize(),
		", ".join(parts),
	]


func _build_balanced_production_debug_message(score_additions: Dictionary) -> String:
	var parts: Array[String] = []
	for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
		var amount: int = score_additions.get(category, 0)
		if amount != 0:
			parts.append("%s +%d" % [ProjectState.CoreScore.keys()[category].capitalize(), amount])
	return "Alpha Balanced Production hit! Added scores: %s" % ", ".join(parts)


func _calculate_feature_alpha_bug_pressure(card: CardData) -> float:
	return _capture_alpha_command()._calculate_feature_alpha_bug_pressure(card)


func _invalid_action(message: String) -> Dictionary:
	return _capture_alpha_command()._invalid_action(message)



func _clear_candidate_pool() -> void:
	for child: Node in %HandContainer.get_children():
		if child is CardView:
			(child as CardView).set_selected(false)
		%HandContainer.remove_child(child)
		child.queue_free()
	_selected_card_views.clear()
	_candidate_cards.clear()
	_update_play_action()
	_update_host_playtest_action()
	_update_proceed_action()


func _refresh_alpha_bug_pressure() -> void:
	if not is_node_ready():
		return
	var pressure := 0.0 if _project_state == null else _project_state.get_accumulated_alpha_bug_pressure()
	%AlphaBugPressureValue.text = "Alpha Bug Pressure: %.2f" % pressure


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
	if _phase_state == PhaseState.PLANNING and (_workspace == null or not _workspace.overlay.visible): set_priority(category, value)
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
	%AvailablePriority.text = "Available Priority: %d" % (PriorityAllocation.MAX_TOTAL_PRIORITY - total)
	%CommitPrioritiesButton.disabled = _phase_state == PhaseState.FINALIZED or not PriorityAllocation.is_valid_distribution(values) or (_phase_state != PhaseState.PLANNING and values == get_priority_distribution())
	_syncing_priority_controls = false


func get_workspace() -> PhaseWorkspace:
	return _workspace


func refresh_workspace() -> void:
	if _workspace != null: _workspace.refresh()


func is_gameplay_input_blocked() -> bool:
	return _hand_command_busy or not is_inside_tree() or (_workspace != null and _workspace.overlay != null and _workspace.overlay.visible)


func can_edit_priorities() -> bool:
	return is_inside_tree() and _phase_state == PhaseState.ACTIVE_DEVELOPMENT and not _scope_warning_pending


func is_initial_priority_planning() -> bool:
	return _phase_state == PhaseState.PLANNING


func can_initialize_priorities() -> bool:
	return is_inside_tree() and _phase_state == PhaseState.PLANNING and _project_state != null and not _scope_warning_pending and PriorityAllocation.is_valid_distribution(_priority_draft)


func open_priority_overlay() -> bool:
	return _workspace != null and _workspace.overlay.open()


func reset_priority_draft() -> void:
	_priority_draft = get_priority_distribution()
	_sync_priority_controls()


func get_selected_candidate_views() -> Array[CardView]:
	return _selected_card_views.duplicate()


func refresh_overlay_actions() -> void:
	_update_play_action()
	_update_host_playtest_action()
	_update_proceed_action()


func get_employee_hand_status() -> Dictionary:
	if _run_state == null or _project_state == null: return {}
	var roster := _run_state.get_employees()
	var base := _validate_and_calculate_base_action()
	return {"hired":not roster.employees.is_empty(),"available":EmployeeRoster.available(roster,_project_state.get_release_id()),"qualifying":base.get("valid",false) and EmployeeRoster.matches(EmployeeRoster.card_facts(base.get("cards",[])))}


func play_hand_with_employee_plan(distribution: Dictionary) -> bool:
	if not _employee_priority_choice.is_empty() or not PriorityAllocation.is_valid_distribution(distribution) or distribution == get_priority_distribution(): return false
	var before := _project_state.get_current_cycle()
	_employee_priority_choice = distribution.duplicate()
	_on_play_alpha_hand_pressed()
	_employee_priority_choice.clear()
	return _project_state.get_current_cycle() == before+1

func _finalize_with_run_rng() -> bool:
	var prior_rng := _finalization_rng.state
	var accepted := _finalize_alpha(_finalization_rng.randf(), _finalization_rng.randf())
	if not accepted: _finalization_rng.state = prior_rng
	return accepted


## Build the scene-free command state with session-local candidate tokens.
func _capture_alpha_command() -> RefCounted:
	var state := AlphaHandCommand.new()
	state._project_state = _project_state
	state._run_state = _run_state
	state._deal_rng = _deal_rng
	state._available_features.assign(_available_features)
	state._pass_definitions.assign(_pass_definitions)
	state._candidate_cards.assign(_candidate_cards)
	state._exhausted_feature_ids.assign(_exhausted_feature_ids)
	state.priorities = get_priority_distribution()
	state.active = _phase_state == PhaseState.ACTIVE_DEVELOPMENT
	state._pending_playtest_categories.assign(_pending_playtest_categories)
	state.revision = _command_revision
	if is_inside_tree() and get_node_or_null("%HandContainer")!=null:
		for view in %HandContainer.get_children():
			if not view is CardView: continue
			var id := view.get_instance_id()
			if not _command_view_ids.has(id):
				_command_view_ids[id] = _command_next_id
				_command_next_id += 1
			state.candidate_ids.append(_command_view_ids[id])
	state.next_candidate_id = _command_next_id
	return state


func _capture_development_actions() -> RefCounted:
	var actions:=DevelopmentActions.new()
	actions.phase=&"alpha"
	actions.hand=_capture_alpha_command()
	var database:=get_node_or_null("/root/CardDatabase") if is_inside_tree() else null
	if database!=null: actions.catalog=database.get_development_catalog()
	actions.finalization_rng=_finalization_rng
	return actions

func _redraw_slots() -> Array[int]:
	var slots: Array[int] = []
	for view: CardView in _selected_card_views: slots.append(view.get_index())
	return slots

func _sync_command_tokens(state: RefCounted) -> void:
	_command_revision=state.revision
	_command_next_id=state.next_candidate_id
	_command_view_ids.clear()
	for index in range(%HandContainer.get_child_count()):
		_command_view_ids[%HandContainer.get_child(index).get_instance_id()]=state.candidate_ids[index]
