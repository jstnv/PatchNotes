class_name BetaPhase
extends Control

var _workspace: PhaseWorkspace

signal priorities_changed
signal launch_requested

const CARD_VIEW_SCENE := preload("res://scenes/cards/card_view.tscn")
const BETA_PRIORITY_ALLOCATION_SCRIPT := preload("res://scripts/phases/beta_priority_allocation.gd")
const CANDIDATE_POOL_SIZE := 7
const SELECTED_HAND_SIZE := 4
const QA_SPECIALIZATION_MULTIPLIER := 1.5
const MARKETING_SPECIALIZATION_MULTIPLIER := 1.5
const BALANCED_OPERATIONS_MULTIPLIER := 1.25
const HOST_PLAYTEST_COST := 500
const HOST_PLAYTEST_COST_CENTS := 50000
const PLAYTEST_RIVAL_PAYOUT_CENTS := 100000
const CORE_SCORE_BY_STAT := {
	&"graphics": ProjectState.CoreScore.GRAPHICS,
	&"sound": ProjectState.CoreScore.SOUND,
	&"technology": ProjectState.CoreScore.TECHNOLOGY,
	&"design": ProjectState.CoreScore.DESIGN,
}
const PASS_ID_BY_CORE_SCORE := {
	ProjectState.CoreScore.GRAPHICS: &"graphics_pass",
	ProjectState.CoreScore.SOUND: &"sound_pass",
	ProjectState.CoreScore.TECHNOLOGY: &"technology_pass",
	ProjectState.CoreScore.DESIGN: &"design_pass",
}
const FINITE_IDS: Array[StringName] = [&"press_interview", &"playtest_rival_games", &"study_competition", &"predict_market_trends"]

enum PhaseState { PLANNING, ACTIVE_DEVELOPMENT, FINALIZED }

var _project_state: ProjectState
var _run_state: RunState
var _snapshot_database: PrimitiveSnapshotDatabase
var _phase_state := PhaseState.PLANNING
var _priority_allocation := BETA_PRIORITY_ALLOCATION_SCRIPT.new()
var _priority_draft: Dictionary[StringName, int]
var _syncing_priority_controls := false
var _candidate_cards: Array[CardData] = []
var _candidate_views: Array[CardView] = []
var _selected_card_views: Array[CardView] = []
var _injected_corrective_views: Array[CardView] = []
var _pending_corrective_pass_ids: Array[StringName] = []
var _deal_rng := RandomNumberGenerator.new()
var _insight_rng := RandomNumberGenerator.new()
var _transaction_in_progress := false
var _force_card_view_failure := false
var _launch_confirmation_pending := false
var _launch_authorized := false


func _ready() -> void:
	%RedrawButton.pressed.connect(_on_redraw_pressed)
	_deal_rng.randomize()
	_insight_rng.randomize()
	_priority_draft = _priority_allocation.get_distribution()
	_priority_allocation.allocation_changed.connect(_on_committed_priorities_changed)
	%BeginBetaButton.pressed.connect(_on_begin_beta_pressed)
	%CommitPrioritiesButton.pressed.connect(_on_commit_priorities_pressed)
	%PlayHandButton.pressed.connect(_on_play_hand_pressed)
	%HostPlaytestButton.pressed.connect(_on_host_playtest_pressed)
	%LaunchGameButton.pressed.connect(_on_launch_game_pressed)
	%LaunchWarningDialog.confirmed.connect(_on_launch_confirmed)
	%LaunchWarningDialog.canceled.connect(_on_launch_canceled)
	_sync_priority_controls()
	_refresh_known_bugs()
	_refresh_insider_information()
	_update_begin_action()
	_update_play_action()
	_update_host_playtest_action()
	_update_launch_action()

	_workspace = PhaseWorkspace.new()
	add_child(_workspace)
	_workspace.configure(self, "Beta")
	_workspace.bind_states(_project_state, _run_state)


func setup(project_state: ProjectState, run_state: RunState = null, snapshot_database: PrimitiveSnapshotDatabase = null) -> bool:
	if project_state == null or not project_state.has_alpha_finalization() or project_state.has_beta_finalization():
		push_warning("Beta requires an authoritatively finalized Alpha ProjectState.")
		return false
	if _project_state != null and _project_state.values_changed.is_connected(_refresh_known_bugs):
		_project_state.values_changed.disconnect(_refresh_known_bugs)
	if _project_state != null and _project_state.values_changed.is_connected(_refresh_insider_information):
		_project_state.values_changed.disconnect(_refresh_insider_information)
	if _run_state != null and _run_state.cash_changed.is_connected(_update_host_playtest_action):
		_run_state.cash_changed.disconnect(_update_host_playtest_action)
	_project_state = project_state
	_run_state = run_state
	_snapshot_database = snapshot_database
	if not _project_state.values_changed.is_connected(_refresh_known_bugs):
		_project_state.values_changed.connect(_refresh_known_bugs)
	if not _project_state.values_changed.is_connected(_refresh_insider_information):
		_project_state.values_changed.connect(_refresh_insider_information)
	if _run_state != null and not _run_state.cash_changed.is_connected(_update_host_playtest_action):
		_run_state.cash_changed.connect(_update_host_playtest_action)
	if _run_state != null and not _run_state.redraws_changed.is_connected(_refresh_redraw_controls):
		_run_state.redraws_changed.connect(_refresh_redraw_controls)
	_refresh_known_bugs()
	_refresh_insider_information()
	_update_begin_action()
	_update_play_action()
	_update_host_playtest_action()
	_update_launch_action()
	_refresh_redraw_controls()
	if _workspace != null: _workspace.bind_states(_project_state, _run_state)
	return true


func _exit_tree() -> void:
	if _project_state != null and _project_state.values_changed.is_connected(_refresh_known_bugs):
		_project_state.values_changed.disconnect(_refresh_known_bugs)
	if _project_state != null and _project_state.values_changed.is_connected(_refresh_insider_information):
		_project_state.values_changed.disconnect(_refresh_insider_information)
	if _run_state != null and _run_state.cash_changed.is_connected(_update_host_playtest_action):
		_run_state.cash_changed.disconnect(_update_host_playtest_action)
	if _run_state != null and _run_state.redraws_changed.is_connected(_refresh_redraw_controls):
		_run_state.redraws_changed.disconnect(_refresh_redraw_controls)


func set_priority_distribution(distribution: Dictionary) -> bool:
	if _launch_confirmation_pending or _transaction_in_progress or _phase_state == PhaseState.FINALIZED or not BetaPriorityAllocation.is_valid_distribution(distribution):
		return false
	if _phase_state == PhaseState.ACTIVE_DEVELOPMENT:
		if _run_state != null:
			return commit_priority_distribution(distribution)
		if not _priority_allocation.set_distribution(distribution): return false
		_priority_draft = _priority_allocation.get_distribution()
		_sync_priority_controls()
		return true
	if not _priority_allocation.set_distribution(distribution): return false
	_priority_draft = _priority_allocation.get_distribution()
	_sync_priority_controls()
	_update_begin_action()
	return true


func commit_priority_distribution(distribution: Dictionary = _priority_draft) -> bool:
	if not is_inside_tree(): return false
	if _phase_state != PhaseState.ACTIVE_DEVELOPMENT or _launch_confirmation_pending or _transaction_in_progress or _project_state == null or _run_state == null or not BetaPriorityAllocation.is_valid_distribution(distribution) or distribution == get_priority_distribution() or not _project_state.can_advance_cycle() or not _run_state.can_advance_calendar_cycle(): return false
	var commit := func() -> bool:
		if not _priority_allocation.set_distribution(distribution): return false
		_priority_draft = _priority_allocation.get_distribution()
		_project_state.advance_cycle()
		return true
	if not _run_state.complete_productive_action(commit, 0, -1, &"", &"priority_change", _project_state.get_release_id()): return false
	_sync_priority_controls()
	_refresh_redraw_controls()
	return true


func _on_commit_priorities_pressed() -> void:
	commit_priority_distribution()


func get_priority(category: StringName) -> int:
	return _priority_allocation.get_priority(category)


func get_priority_distribution() -> Dictionary[StringName, int]:
	return _priority_allocation.get_distribution()


func get_selected_candidate_count() -> int:
	return _selected_card_views.size()


func get_selected_candidate_views() -> Array[CardView]:
	return _selected_card_views.duplicate()


func get_pending_corrective_pass_ids() -> Array[StringName]:
	return _pending_corrective_pass_ids.duplicate()


## Gameplay grants this phase instance the one authoritative Launch boundary.
func authorize_launch() -> bool:
	if _launch_authorized or _project_state == null or _phase_state == PhaseState.FINALIZED:
		return false
	_launch_authorized = true
	_update_launch_action()
	return true


func begin_beta(category_rolls: Array[float] = [], definition_rolls: Array[float] = []) -> bool:
	if is_gameplay_input_blocked(): return false
	if _phase_state != PhaseState.PLANNING or _project_state == null or not _project_state.has_alpha_finalization():
		return false
	if not BetaPriorityAllocation.is_valid_distribution(_priority_draft):
		return false
	var database := get_node_or_null("/root/CardDatabase")
	if database == null:
		return false
	var definitions: Array[CardData] = []
	definitions.assign(database.call(&"get_cards_by_phase", CardData.PHASE_BETA))
	var validation_error := _get_source_validation_error(definitions)
	if not validation_error.is_empty():
		push_warning(validation_error)
		return false
	var committed_snapshot: Dictionary = _priority_draft.duplicate()
	var rng_state := _deal_rng.state
	var deal := _build_candidate_definitions(definitions, committed_snapshot, category_rolls, definition_rolls)
	if not deal.valid:
		_deal_rng.state = rng_state
		push_warning("Could not build the initial Beta candidate pool: %s" % deal.error)
		return false
	var prepared_views: Array[CardView] = []
	for card: CardData in deal.cards:
		var view := CARD_VIEW_SCENE.instantiate() as CardView
		if view == null:
			for prepared: CardView in prepared_views:
				prepared.free()
			_deal_rng.state = rng_state
			return false
		view.set_card(card)
		view.card_pressed.connect(_on_card_pressed)

		prepared_views.append(view)
	if not _priority_allocation.set_distribution(committed_snapshot):
		for prepared: CardView in prepared_views:
			prepared.free()
		_deal_rng.state = rng_state
		return false
	_candidate_cards.assign(deal.cards)
	_candidate_views.assign(prepared_views)
	for view: CardView in _candidate_views:
		%HandContainer.add_child(view)
	_refresh_redraw_controls()
	_refresh_redraw_controls()
	_phase_state = PhaseState.ACTIVE_DEVELOPMENT
	refresh_workspace()
	%BeginBetaButton.visible = false
	%BeginBetaButton.disabled = true
	_update_play_action()
	_update_host_playtest_action()
	_update_launch_action()
	_refresh_redraw_controls()
	return true


func _can_redraw_selection() -> bool:
	if is_gameplay_input_blocked(): return false
	if _phase_state != PhaseState.ACTIVE_DEVELOPMENT or _run_state == null or _transaction_in_progress or _launch_confirmation_pending or not _run_state.can_consume_redraw(_selected_card_views.size()):
		return false
	var seen: Array[CardView] = []
	for view: CardView in _selected_card_views:
		if not _is_current_candidate_view(view) or view.card_data == null or seen.has(view) or _injected_corrective_views.has(view):
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
		return false
	# Prepare every view before changing the pool, lifecycle, selection, or budget.
	var prepared: Array[CardView] = []
	for card: CardData in plan.cards:
		var replacement_view := _instantiate_card_view()
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

		_candidate_cards[slot] = replacement
		_candidate_views[slot] = prepared[index]
		%HandContainer.remove_child(old_view)
		old_view.queue_free()
		%HandContainer.add_child(prepared[index])
		%HandContainer.move_child(prepared[index], slot)
	_selected_card_views.clear()
	# One budget notification, after the complete pool and selection are committed.
	_run_state.consume_redraw(count)
	_update_play_action()
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
	var cards: Array[CardData] = []
	var failed := {&"valid": false, &"cards": cards, &"failed_features": []}
	var database := get_node_or_null("/root/CardDatabase")
	if database == null or _project_state == null: return failed
	var definitions: Array[CardData] = []
	definitions.assign(database.call(&"get_cards_by_phase", CardData.PHASE_BETA))
	var reserved := _project_state.get_exhausted_beta_card_ids()
	for current: CardData in _candidate_cards:
		if not current.renewable and not reserved.has(current.id): reserved.append(current.id)
	for index in range(_selected_card_views.size()):
		var excluded := reserved.duplicate()
		excluded.append(_selected_card_views[index].card_data.id)
		var rolls: Array[float] = []
		if not controlled_rolls.is_empty(): rolls.append(controlled_rolls[index])
		var deal := _build_candidate_definitions(definitions, get_priority_distribution(), rolls, rolls, excluded, 1)
		if not deal.valid: return failed
		var replacement: CardData = deal.cards[0]
		cards.append(replacement)
		if not replacement.renewable: reserved.append(replacement.id)
	return {&"valid": true, &"cards": cards, &"failed_features": []}


func _on_begin_beta_pressed() -> void:
	begin_beta()


func _on_play_hand_pressed() -> void:
	play_selected_hand()


func _on_host_playtest_pressed() -> void:
	host_playtest()


func _on_launch_game_pressed() -> void:
	request_launch()


func request_launch() -> bool:
	if not _can_launch():
		return false
	var warnings := _build_launch_warnings()
	if warnings.is_empty():
		return _finalize_beta()
	_launch_confirmation_pending = true
	%LaunchWarningDialog.dialog_text = "\n".join(warnings) + "\nThese conditions may reduce the game's launch performance.\nLaunch anyway?"
	%LaunchWarningDialog.popup_centered()
	_update_all_actions()
	return false


func confirm_launch_for_verification() -> bool:
	if not _launch_confirmation_pending:
		return false
	return _finalize_beta()


func cancel_launch_for_verification() -> bool:
	if not _launch_confirmation_pending:
		return false
	_on_launch_canceled()
	return true


func _on_launch_confirmed() -> void:
	if _launch_confirmation_pending:
		_finalize_beta()


func _on_launch_canceled() -> void:
	_launch_confirmation_pending = false
	_update_all_actions()


func _can_launch() -> bool:
	if _project_state == null or not _project_state.has_launch_feature_work():
		return false
	if is_gameplay_input_blocked(): return false
	return (
		not _transaction_in_progress
		and not _launch_confirmation_pending
		and _launch_authorized
		and _phase_state == PhaseState.ACTIVE_DEVELOPMENT
		and _project_state != null
		and _project_state.has_alpha_finalization()
		and not _project_state.has_beta_finalization()
		and _run_state != null
		and _run_state.is_cash_initialized()
		and _snapshot_database != null
		and _snapshot_database.has_competitor(_project_state.get_assigned_competitor_snapshot_id_for_authority())
		and _snapshot_database.has_forecast(_project_state.get_assigned_market_forecast_snapshot_id_for_authority())
		and _has_valid_active_pool()
		and is_inside_tree()
	)


func _build_launch_warnings() -> Array[String]:
	var warnings: Array[String] = []
	var current_scope := _project_state.get_current_scope()
	var required_scope := _project_state.get_required_scope()
	if current_scope < required_scope:
		warnings.append("Project Scope is incomplete: %d / %d." % [current_scope, required_scope])
		warnings.append("Scope shortfall: %d." % (required_scope - current_scope))
	var known_bugs := _project_state.get_known_bugs()
	if known_bugs > 0:
		warnings.append("Known Bugs remaining: %d. Unresolved Known Bugs will remain at launch." % known_bugs)
	if _project_state.get_marketing_output() == 0:
		warnings.append("No Marketing activity has been completed. Launch reach may be reduced.")
	return warnings


func _finalize_beta() -> bool:
	if _phase_state != PhaseState.ACTIVE_DEVELOPMENT or _transaction_in_progress or _project_state == null or _project_state.has_beta_finalization():
		return false
	var was_confirming := _launch_confirmation_pending
	_launch_confirmation_pending = false
	if not _can_launch():
		_launch_confirmation_pending = was_confirming
		_update_all_actions()
		return false
	var database := get_node_or_null("/root/CardDatabase")
	if database == null or not _validate_exhausted_beta_ids(database) or not _validate_feature_histories(database):
		_launch_confirmation_pending = was_confirming
		_update_all_actions()
		return false
	_transaction_in_progress = true
	if not _project_state.finalize_beta():
		_transaction_in_progress = false
		_launch_confirmation_pending = was_confirming
		_update_all_actions()
		return false
	_pending_corrective_pass_ids.clear()
	_phase_state = PhaseState.FINALIZED
	_retire_beta_interface()
	_transaction_in_progress = false
	launch_requested.emit()
	return true


func _validate_exhausted_beta_ids(database: Node) -> bool:
	for id: StringName in _project_state.get_exhausted_beta_card_ids():
		var card: CardData = database.call(&"get_card", id)
		if card == null or card.phase != CardData.PHASE_BETA or card.renewable or not FINITE_IDS.has(id):
			return false
	return true


func _validate_feature_histories(database: Node) -> bool:
	var histories := [
		[_project_state.get_implemented_design_feature_ids(), _project_state.get_unimplemented_design_feature_ids(), CardData.PHASE_DESIGN],
		[_project_state.get_implemented_alpha_feature_ids(), _project_state.get_unimplemented_alpha_feature_ids(), CardData.PHASE_ALPHA],
	]
	for history: Array in histories:
		var seen: Dictionary[StringName, bool] = {}
		for collection: Array in [history[0], history[1]]:
			for id: StringName in collection:
				var card: CardData = database.call(&"get_card", id)
				if seen.has(id) or card == null or card.phase != history[2] or card.card_type != &"feature":
					return false
				seen[id] = true
	return true


func _retire_beta_interface() -> void:
	%LaunchWarningDialog.hide()
	for view: CardView in _selected_card_views:
		if is_instance_valid(view):
			view.set_selected(false)
	_selected_card_views.clear()
	for view: CardView in _candidate_views:
		if is_instance_valid(view):
			%HandContainer.remove_child(view)
			view.queue_free()
	_candidate_cards.clear()
	_candidate_views.clear()
	_injected_corrective_views.clear()
	_update_all_actions()


func host_playtest() -> bool:
	if not _can_host_playtest():
		return false
	var pass_ids := _select_corrective_pass_ids()
	if pass_ids.size() != 2 or pass_ids[0] == pass_ids[1]:
		return false
	var database := get_node_or_null("/root/CardDatabase")
	if database == null:
		return false
	for id: StringName in pass_ids:
		var card: CardData = database.call(&"get_card", id)
		if not _is_valid_corrective_pass(card):
			return false
	_transaction_in_progress = true
	_update_play_action()
	_update_host_playtest_action()
	_update_launch_action()
	var commit := func() -> bool:
		_project_state.advance_cycle()
		_pending_corrective_pass_ids.assign(pass_ids)
		return true
	if not _run_state.complete_productive_action(commit, -HOST_PLAYTEST_COST_CENTS, -1, &"", &"playtest", _project_state.get_release_id()):
		_transaction_in_progress = false
		_update_play_action()
		_update_host_playtest_action()
		_update_launch_action()
		return false
	var names := _format_pass_names(pass_ids)
	%ActionFeedbackLabel.text = "Beta Host Playtest complete! $500 spent. One cycle advanced. Corrective Passes queued: %s" % names
	%ActionFeedbackLabel.visible = true
	print(%ActionFeedbackLabel.text)
	_transaction_in_progress = false
	_update_play_action()
	_update_host_playtest_action()
	_update_launch_action()
	return true


func play_selected_hand(insight_rolls: Array[int] = [], replacement_category_rolls: Array[float] = [], replacement_definition_rolls: Array[float] = []) -> bool:
	if not _can_attempt_play():
		return false
	var deal_rng_state := _deal_rng.state
	var insight_rng_state := _insight_rng.state
	var preflight := _build_hand_preflight(insight_rolls, replacement_category_rolls, replacement_definition_rolls)
	if not preflight.valid:
		_deal_rng.state = deal_rng_state
		_insight_rng.state = insight_rng_state
		push_warning("Beta hand rejected: %s" % preflight.error)
		return false
	_transaction_in_progress = true
	_update_play_action()
	_update_host_playtest_action()
	_update_launch_action()
	var resolved := [0, 0]
	var commit := func() -> bool:
		if not preflight.corrective_score_additions.is_empty():
			_project_state.add_core_scores_and_scope(preflight.corrective_score_additions, 0)
		for requested: int in preflight.search_requests:
			resolved[0] += _project_state.discover_bugs(requested)
		for requested: int in preflight.debug_requests:
			resolved[1] += _project_state.fix_known_bugs(requested)
		if preflight.marketing_gain > 0:
			_project_state.add_marketing_output(preflight.marketing_gain)
		if preflight.reveal_competitor:
			_project_state.reveal_competitor_snapshot()
		if preflight.reveal_forecast:
			_project_state.reveal_market_forecast_snapshot()
		_project_state.exhaust_beta_cards(preflight.finite_ids)
		_project_state.advance_cycle()
		return true
	if not _run_state.complete_productive_action(commit, preflight.cash_gain_cents, -1, &"", &"beta_income", _project_state.get_release_id()):
		for view: CardView in preflight.next_views: view.free()
		_deal_rng.state = deal_rng_state
		_insight_rng.state = insight_rng_state
		_transaction_in_progress = false
		_update_all_actions()
		return false
	_publish_replacement_pool(preflight.next_cards, preflight.next_views, preflight.injected_corrective_count)
	if not preflight.consumed_pending_ids.is_empty():
		_pending_corrective_pass_ids.clear()
	_refresh_known_bugs()
	_refresh_insider_information()
	_show_action_feedback(preflight, resolved[0], resolved[1])
	_transaction_in_progress = false
	_update_play_action()
	_update_host_playtest_action()
	_update_launch_action()
	return true


func _can_attempt_play() -> bool:
	if is_gameplay_input_blocked(): return false
	if _launch_confirmation_pending or _transaction_in_progress or _phase_state != PhaseState.ACTIVE_DEVELOPMENT or _project_state == null or _run_state == null or _snapshot_database == null:
		return false
	if not _project_state.has_alpha_finalization() or not _run_state.is_cash_initialized() or _selected_card_views.size() != SELECTED_HAND_SIZE or not _has_valid_active_pool():
		return false
	var seen_views: Dictionary[int, bool] = {}
	for view: CardView in _selected_card_views:
		if not _is_current_candidate_view(view) or seen_views.has(view.get_instance_id()):
			return false
		seen_views[view.get_instance_id()] = true
	return true


func _can_host_playtest() -> bool:
	if is_gameplay_input_blocked(): return false
	return (
		not _launch_confirmation_pending
		and not _transaction_in_progress
		and _phase_state == PhaseState.ACTIVE_DEVELOPMENT
		and _project_state != null
		and _run_state != null
		and _project_state.has_alpha_finalization()
		and _project_state.can_advance_cycle()
		and _run_state.can_complete_productive_cycle(-HOST_PLAYTEST_COST_CENTS)
		and _run_state.is_cash_initialized()
		and _run_state.get_cash_cents() >= HOST_PLAYTEST_COST_CENTS
		and _pending_corrective_pass_ids.is_empty()
		and _has_valid_active_pool()
	)


func _has_valid_active_pool() -> bool:
	if not is_node_ready() or _candidate_cards.size() != CANDIDATE_POOL_SIZE or _candidate_views.size() != CANDIDATE_POOL_SIZE or %HandContainer.get_child_count() != CANDIDATE_POOL_SIZE:
		return false
	for index in range(CANDIDATE_POOL_SIZE):
		var view := _candidate_views[index]
		if not is_instance_valid(view) or view.get_parent() != %HandContainer or view.card_data != _candidate_cards[index]:
			return false
	return true


func _build_hand_preflight(insight_rolls: Array[int], replacement_category_rolls: Array[float], replacement_definition_rolls: Array[float]) -> Dictionary:
	var card_database := get_node_or_null("/root/CardDatabase")
	if card_database == null:
		return _invalid_play("CardDatabase is unavailable.")
	var competitor_id := _project_state.get_assigned_competitor_snapshot_id_for_authority()
	var forecast_id := _project_state.get_assigned_market_forecast_snapshot_id_for_authority()
	if not _snapshot_database.has_competitor(competitor_id) or not _snapshot_database.has_forecast(forecast_id):
		return _invalid_play("Assigned project snapshots are missing or unknown.")
	var groups := {&"search": [] as Array[CardData], &"debug": [] as Array[CardData], &"marketing": [] as Array[CardData], &"playtest": [] as Array[CardData], &"study": [] as Array[CardData], &"predict": [] as Array[CardData]}
	var finite_ids: Array[StringName] = []
	var selected_cards: Array[CardData] = []
	var corrective_score_additions: Dictionary[ProjectState.CoreScore, int] = {}
	for view: CardView in _selected_card_views:
		var card := view.card_data
		if card == null or card_database.call(&"get_card", card.id) != card:
			return _invalid_play("A selected definition is not an authoritative Primitive Beta card.")
		if _injected_corrective_views.has(view):
			if not _is_valid_corrective_pass(card):
				return _invalid_play("An injected corrective Pass is malformed.")
			var category: ProjectState.CoreScore = CORE_SCORE_BY_STAT[card.primary_stat]
			corrective_score_additions[category] = corrective_score_additions.get(category, 0) + card.primary_value
			selected_cards.append(card)
			continue
		if card.phase != CardData.PHASE_BETA or card.card_type != &"beta" or card.scope != 0:
			return _invalid_play("A selected definition is not an authoritative Primitive Beta card.")
		if not card.renewable:
			if not FINITE_IDS.has(card.id) or finite_ids.has(card.id) or _project_state.is_beta_card_exhausted(card.id):
				return _invalid_play("A selected finite definition is invalid or exhausted.")
			finite_ids.append(card.id)
		selected_cards.append(card)
		match card.id:
			&"search_for_bugs": groups.search.append(card)
			&"debug": groups.debug.append(card)
			&"sign_flippers", &"posters", &"press_release", &"press_interview": groups.marketing.append(card)
			&"playtest_rival_games": groups.playtest.append(card)
			&"study_competition": groups.study.append(card)
			&"predict_market_trends": groups.predict.append(card)
			_: return _invalid_play("A selected Beta definition has no base resolver.")
	for category: ProjectState.CoreScore in corrective_score_additions:
		if corrective_score_additions[category] > ProjectState.MAX_SIGNED_INT - _project_state.get_core_score(category):
			return _invalid_play("Corrective Pass production would overflow.")
	var hidden := _project_state.get_hidden_bugs()
	var known := _project_state.get_known_bugs()
	var qa_specialization := _qualifies_for_qa_specialization(selected_cards)
	var marketing_specialization := _qualifies_for_marketing_specialization(selected_cards)
	var balanced_operations := not qa_specialization and not marketing_specialization and _qualifies_for_balanced_operations(selected_cards)
	var search_requests: Array[int] = []
	for card: CardData in groups.search:
		var final_value: float = card.beta_value * QA_SPECIALIZATION_MULTIPLIER if qa_specialization else card.beta_value
		var request := int(floor((1.0 + final_value) + (hidden * 0.15 * final_value)))
		if balanced_operations:
			request = int(ceil(request * BALANCED_OPERATIONS_MULTIPLIER))
		var actual := mini(request, hidden)
		search_requests.append(request)
		hidden -= actual
		known += actual
	var debug_requests: Array[int] = []
	for card: CardData in groups.debug:
		var final_value: float = card.beta_value * QA_SPECIALIZATION_MULTIPLIER if qa_specialization else card.beta_value
		var request := int(floor(1.0 + final_value))
		if balanced_operations:
			request = int(ceil(request * BALANCED_OPERATIONS_MULTIPLIER))
		debug_requests.append(request)
		known -= mini(request, known)
	var marketing_gain := 0
	for card: CardData in groups.marketing:
		marketing_gain += card.beta_value
	if marketing_specialization:
		marketing_gain = int(floor(marketing_gain * MARKETING_SPECIALIZATION_MULTIPLIER))
	elif balanced_operations:
		marketing_gain = int(ceil(marketing_gain * BALANCED_OPERATIONS_MULTIPLIER))
	if marketing_gain > ProjectState.MAX_SIGNED_INT - _project_state.get_marketing_output():
		return _invalid_play("Marketing Output would overflow.")
	var cash_gain: int = groups.playtest.size() * 1000
	var cash_gain_cents: int = groups.playtest.size() * PLAYTEST_RIVAL_PAYOUT_CENTS
	if cash_gain_cents > RunState.MAX_SIGNED_INT - _run_state.get_cash_cents():
		return _invalid_play("Run cash would overflow.")
	var cursor := [0]
	var competitor_revealed := _project_state.is_competitor_snapshot_revealed()
	var forecast_revealed := _project_state.is_market_forecast_snapshot_revealed()
	var rival_attempted := false
	var rival_gained := false
	var forecast_attempted := false
	var forecast_gained := false
	for card: CardData in groups.playtest:
		if not competitor_revealed:
			rival_attempted = true
			var chance := card.beta_value * 10
			if balanced_operations:
				chance = mini(100, int(ceil(chance * BALANCED_OPERATIONS_MULTIPLIER)))
			if _next_insight_roll(insight_rolls, cursor) < chance:
				competitor_revealed = true
				rival_gained = true
	for card: CardData in groups.study:
		if not competitor_revealed:
			rival_attempted = true
			var chance := card.beta_value * 15
			if balanced_operations:
				chance = mini(100, int(ceil(chance * BALANCED_OPERATIONS_MULTIPLIER)))
			if _next_insight_roll(insight_rolls, cursor) < chance:
				competitor_revealed = true
				rival_gained = true
	for card: CardData in groups.predict:
		if not forecast_revealed:
			forecast_attempted = true
			var chance := card.beta_value * 15
			if balanced_operations:
				chance = mini(100, int(ceil(chance * BALANCED_OPERATIONS_MULTIPLIER)))
			if _next_insight_roll(insight_rolls, cursor) < chance:
				forecast_revealed = true
				forecast_gained = true
	if not insight_rolls.is_empty() and cursor[0] != insight_rolls.size():
		return _invalid_play("Controlled insight rolls must match the rolls actually required.")
	var projected_exhausted := _project_state.get_exhausted_beta_card_ids()
	projected_exhausted.append_array(finite_ids)
	for view: CardView in _candidate_views:
		if view not in _selected_card_views and not view.card_data.renewable and view.card_data.id not in projected_exhausted:
			projected_exhausted.append(view.card_data.id)
	if not _project_state.can_advance_cycle():
		return _invalid_play("The project cycle cannot advance safely.")
	if not _run_state.can_complete_productive_cycle(cash_gain_cents):
		return _invalid_play("The run calendar cannot advance safely.")
	var definitions: Array[CardData] = []
	definitions.assign(card_database.call(&"get_cards_by_phase", CardData.PHASE_BETA))
	var replacement := _build_replacement_candidate_definitions(definitions, get_priority_distribution(), replacement_category_rolls, replacement_definition_rolls, projected_exhausted)
	if not replacement.valid:
		return _invalid_play("A complete replacement pool could not be prepared.")
	var next_views: Array[CardView] = []
	for card: CardData in replacement.cards:
		var view := _instantiate_card_view()
		if view == null:
			for prepared: CardView in next_views:
				prepared.free()
			return _invalid_play("A complete replacement CardView pool could not be prepared.")
		view.set_card(card)
		view.card_pressed.connect(_on_card_pressed)

		next_views.append(view)
	return {&"valid": true, &"qa_specialization": qa_specialization, &"marketing_specialization": marketing_specialization, &"balanced_operations": balanced_operations, &"corrective_score_additions": corrective_score_additions, &"search_requests": search_requests, &"debug_requests": debug_requests, &"marketing_gain": marketing_gain, &"cash_gain": cash_gain, &"cash_gain_cents": cash_gain_cents, &"reveal_competitor": competitor_revealed and not _project_state.is_competitor_snapshot_revealed(), &"reveal_forecast": forecast_revealed and not _project_state.is_market_forecast_snapshot_revealed(), &"rival_attempted": rival_attempted, &"rival_gained": rival_gained, &"forecast_attempted": forecast_attempted, &"forecast_gained": forecast_gained, &"finite_ids": finite_ids, &"next_cards": replacement.cards, &"next_views": next_views, &"injected_corrective_count": replacement.injected_count, &"consumed_pending_ids": replacement.consumed_pending_ids}


func _qualifies_for_qa_specialization(cards: Array[CardData]) -> bool:
	if cards.size() < 2:
		return false
	for card: CardData in cards:
		if card == null or card.beta_category != CardData.BETA_CATEGORY_QA:
			return false
	return true


func _qualifies_for_marketing_specialization(cards: Array[CardData]) -> bool:
	if cards.size() < 2:
		return false
	for card: CardData in cards:
		if card == null or card.beta_category != CardData.BETA_CATEGORY_MARKETING:
			return false
	return true


func _qualifies_for_balanced_operations(cards: Array[CardData]) -> bool:
	if cards.size() != SELECTED_HAND_SIZE:
		return false
	var counts := {
		CardData.BETA_CATEGORY_QA: 0,
		CardData.BETA_CATEGORY_MARKETING: 0,
		CardData.BETA_CATEGORY_INSIDER: 0,
	}
	for card: CardData in cards:
		if card == null or not counts.has(card.beta_category):
			return false
		counts[card.beta_category] += 1
	for count: int in counts.values():
		if count < 1 or count > 2:
			return false
	return true


func _select_corrective_pass_ids() -> Array[StringName]:
	if _project_state == null:
		return [] as Array[StringName]
	var categories: Array[ProjectState.CoreScore] = []
	categories.assign(ProjectState.CoreScore.values())
	categories.sort_custom(func(a: ProjectState.CoreScore, b: ProjectState.CoreScore) -> bool:
		var a_score := _project_state.get_core_score(a)
		var b_score := _project_state.get_core_score(b)
		return a_score < b_score if a_score != b_score else a < b
	)
	var ids: Array[StringName] = []
	for category: ProjectState.CoreScore in categories.slice(0, 2):
		ids.append(PASS_ID_BY_CORE_SCORE[category])
	return ids


func _is_valid_corrective_pass(card: CardData) -> bool:
	return (
		card != null
		and PASS_ID_BY_CORE_SCORE.values().has(card.id)
		and card.phase == CardData.PHASE_DESIGN
		and card.card_type == &"pass"
		and card.renewable
		and card.scope == 0
		and CORE_SCORE_BY_STAT.has(card.primary_stat)
		and PASS_ID_BY_CORE_SCORE[CORE_SCORE_BY_STAT[card.primary_stat]] == card.id
		and card.primary_value == 2
		and card.secondary_stat.is_empty()
		and card.secondary_value == 0
	)


func _format_pass_names(ids: Array) -> String:
	var names: Array[String] = []
	var database := get_node_or_null("/root/CardDatabase")
	for id: StringName in ids:
		var card: CardData = database.call(&"get_card", id) if database != null else null
		names.append(card.card_name if card != null else str(id))
	return ", ".join(names)


func _format_score_additions(additions: Dictionary) -> String:
	var parts: Array[String] = []
	for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
		var amount: int = additions.get(category, 0)
		if amount > 0:
			parts.append("%s +%d" % [ProjectState.CoreScore.keys()[category].capitalize(), amount])
	return ", ".join(parts)


func _next_insight_roll(controlled: Array[int], cursor: Array) -> int:
	if controlled.is_empty():
		return _insight_rng.randi_range(0, 99)
	if cursor[0] >= controlled.size() or controlled[cursor[0]] < 0 or controlled[cursor[0]] >= 100:
		return 100
	var roll := controlled[cursor[0]]
	cursor[0] += 1
	return roll


func _instantiate_card_view() -> CardView:
	if _force_card_view_failure:
		return null
	return CARD_VIEW_SCENE.instantiate() as CardView


func force_card_view_preparation_failure_for_verification() -> void:
	_force_card_view_failure = true


func _publish_replacement_pool(cards: Array, views: Array, injected_corrective_count: int = 0) -> void:
	var played := _selected_card_views.duplicate()
	_selected_card_views.clear()
	for view: CardView in played:
		view.set_selected(false)
		_injected_corrective_views.erase(view)
		_candidate_views.erase(view)
		%HandContainer.remove_child(view)
		view.queue_free()
	_candidate_cards.clear()
	for view: CardView in _candidate_views: _candidate_cards.append(view.card_data)
	for index in range(views.size()):
		var view: CardView = views[index]
		_candidate_cards.append(cards[index])
		_candidate_views.append(view)
		if index < injected_corrective_count: _injected_corrective_views.append(view)
		%HandContainer.add_child(view)
	_refresh_redraw_controls()


func _show_action_feedback(result: Dictionary, discovered: int, fixed: int) -> void:
	var parts: Array[String] = []
	if result.qa_specialization:
		_workspace.show_synergy("QA Specialization!", "Card Value ×1.50")
	elif result.marketing_specialization:
		_workspace.show_synergy("Marketing Specialization!", "Card Value ×1.50")
	elif result.balanced_operations:
		_workspace.show_synergy("Balanced Operations!", "Output ×1.25")
	if result.qa_specialization: parts.append("QA Specialization! Card Value ×1.50")
	elif result.marketing_specialization: parts.append("Marketing Specialization! Card Value ×1.50")
	elif result.balanced_operations: parts.append("Balanced Operations! Output ×1.25")
	if not result.corrective_score_additions.is_empty():
		parts.append("Corrective Pass gains: %s" % _format_score_additions(result.corrective_score_additions))
	if not result.search_requests.is_empty(): parts.append("Bugs discovered: %d" % discovered)
	if not result.debug_requests.is_empty(): parts.append("Known Bugs fixed: %d" % fixed)
	if result.marketing_gain > 0: parts.append("Marketing Output gained: %d" % result.marketing_gain)
	if result.cash_gain > 0: parts.append("Cash gained: $%d" % result.cash_gain)
	if result.rival_attempted: parts.append("Rival insight gained" if result.rival_gained else "No rival insight gained")
	if result.forecast_attempted: parts.append("Market forecast gained" if result.forecast_gained else "No market forecast gained")
	if not result.finite_ids.is_empty(): parts.append("Finite cards exhausted: %s" % ", ".join(result.finite_ids))
	if not result.consumed_pending_ids.is_empty(): parts.append("Beta Host Playtest corrective Passes injected: %s" % _format_pass_names(result.consumed_pending_ids))
	parts.append("Cycle advanced: 1")
	%ActionFeedbackLabel.text = " | ".join(parts)
	%ActionFeedbackLabel.visible = true
	print("Beta hand resolved: %s" % %ActionFeedbackLabel.text)


func _invalid_play(message: String) -> Dictionary:
	return {&"valid": false, &"error": message}


func _build_replacement_candidate_definitions(definitions: Array[CardData], priorities: Dictionary, category_rolls: Array[float], definition_rolls: Array[float], excluded_ids: Array[StringName]) -> Dictionary:
	if _pending_corrective_pass_ids.is_empty():
		var ordinary := _build_candidate_definitions(definitions, priorities, category_rolls, definition_rolls, excluded_ids, SELECTED_HAND_SIZE)
		ordinary[&"injected_count"] = 0
		ordinary[&"consumed_pending_ids"] = [] as Array[StringName]
		return ordinary
	if _pending_corrective_pass_ids.size() != 2 or _pending_corrective_pass_ids[0] == _pending_corrective_pass_ids[1]:
		return _invalid_deal("A Beta Host Playtest correction requires two distinct Pass IDs.")
	var database := get_node_or_null("/root/CardDatabase")
	if database == null:
		return _invalid_deal("CardDatabase is unavailable for corrective Pass injection.")
	var cards: Array[CardData] = []
	for id: StringName in _pending_corrective_pass_ids:
		var pass_card: CardData = database.call(&"get_card", id)
		if not _is_valid_corrective_pass(pass_card):
			return _invalid_deal("A queued corrective Core Pass is unavailable.")
		cards.append(pass_card)
	var ordinary := _build_candidate_definitions(definitions, priorities, category_rolls, definition_rolls, excluded_ids, SELECTED_HAND_SIZE - cards.size())
	if not ordinary.valid:
		return ordinary
	cards.append_array(ordinary.cards)
	return {&"valid": true, &"cards": cards, &"injected_count": 2, &"consumed_pending_ids": _pending_corrective_pass_ids.duplicate()}


func _build_candidate_definitions(definitions: Array[CardData], priorities: Dictionary, category_rolls: Array[float] = [], definition_rolls: Array[float] = [], excluded_ids: Array[StringName] = [], candidate_count: int = CANDIDATE_POOL_SIZE) -> Dictionary:
	if not BetaPriorityAllocation.is_valid_distribution(priorities):
		return _invalid_deal("Invalid committed Beta priority distribution.")
	if candidate_count < 1 or candidate_count > CANDIDATE_POOL_SIZE:
		return _invalid_deal("Beta candidate count must be between one and seven.")
	if (not category_rolls.is_empty() and category_rolls.size() != candidate_count) or (not definition_rolls.is_empty() and definition_rolls.size() != candidate_count):
		return _invalid_deal("Controlled Beta deals require exactly %d category and definition rolls." % candidate_count)
	for roll: float in category_rolls + definition_rolls:
		if not is_finite(roll) or roll < 0.0 or roll >= 1.0:
			return _invalid_deal("Controlled Beta rolls must be finite values in [0, 1).")
	var available_by_category := _group_definitions(definitions, excluded_ids)
	var selected: Array[CardData] = []
	for slot in range(candidate_count):
		var category_entries: Array[Dictionary] = []
		for category: StringName in BetaPriorityAllocation.CATEGORIES:
			var available: Array = available_by_category[category]
			if not available.is_empty():
				category_entries.append({&"value": category, &"weight": priorities[category]})
		var category_roll := category_rolls[slot] if not category_rolls.is_empty() else _deal_rng.randf()
		var category: StringName = _select_weighted_value(category_entries, category_roll)
		if category.is_empty():
			return _invalid_deal("No eligible Beta category for slot %d." % (slot + 1))
		var definition_entries: Array[Dictionary] = []
		var category_definitions: Array = available_by_category[category]
		category_definitions.sort_custom(func(a: CardData, b: CardData) -> bool: return str(a.id) < str(b.id))
		for card: CardData in category_definitions:
			definition_entries.append({&"value": card, &"weight": _get_definition_weight(card)})
		var definition_roll := definition_rolls[slot] if not definition_rolls.is_empty() else _deal_rng.randf()
		var card := _select_weighted_value(definition_entries, definition_roll) as CardData
		if card == null:
			return _invalid_deal("No eligible Beta definition for slot %d." % (slot + 1))
		selected.append(card)
		if not card.renewable:
			category_definitions.erase(card)
	return {&"valid": true, &"cards": selected}


func _select_weighted_value(entries: Array[Dictionary], roll: float) -> Variant:
	if not is_finite(roll) or roll < 0.0 or roll >= 1.0 or entries.is_empty():
		return null
	var total := 0.0
	for entry: Dictionary in entries:
		if not entry.has(&"value") or not entry.has(&"weight"):
			return null
		var weight := float(entry.weight)
		if not is_finite(weight) or weight <= 0.0:
			return null
		total += weight
	var target := roll * total
	var cumulative := 0.0
	for index in range(entries.size()):
		cumulative += float(entries[index].weight)
		if target < cumulative or index == entries.size() - 1:
			return entries[index].value
	return null


func _group_definitions(definitions: Array[CardData], excluded_ids: Array[StringName] = []) -> Dictionary:
	var grouped := {}
	for category: StringName in BetaPriorityAllocation.CATEGORIES:
		grouped[category] = [] as Array[CardData]
	for card: CardData in definitions:
		if not excluded_ids.has(card.id):
			(grouped[card.beta_category] as Array[CardData]).append(card)
	return grouped


func _get_definition_weight(card: CardData) -> float:
	if card.beta_category == CardData.BETA_CATEGORY_QA and card.qa_operation == CardData.QA_OPERATION_DEBUG:
		return 2.0
	return 1.0


func _get_source_validation_error(definitions: Array[CardData]) -> String:
	if definitions.size() != 9:
		return "Beta requires exactly nine Primitive definitions."
	var counts := {CardData.BETA_CATEGORY_QA: 0, CardData.BETA_CATEGORY_MARKETING: 0, CardData.BETA_CATEGORY_INSIDER: 0}
	var ids: Dictionary[StringName, bool] = {}
	for card: CardData in definitions:
		if card == null or card.id.is_empty() or card.phase != CardData.PHASE_BETA or card.card_type != &"beta" or not counts.has(card.beta_category) or card.beta_value < 0 or card.scope != 0 or ids.has(card.id):
			return "Beta source definitions are malformed or duplicated."
		if card.beta_category == CardData.BETA_CATEGORY_QA and not CardData.is_valid_qa_operation(card.qa_operation):
			return "A QA source definition has an invalid operation."
		if card.beta_category != CardData.BETA_CATEGORY_QA and not card.qa_operation.is_empty():
			return "A non-QA source definition contains a QA operation."
		ids[card.id] = true
		counts[card.beta_category] += 1
	if counts[CardData.BETA_CATEGORY_QA] != 2 or counts[CardData.BETA_CATEGORY_MARKETING] != 4 or counts[CardData.BETA_CATEGORY_INSIDER] != 3:
		return "Beta source definitions do not match the locked category counts."
	return ""


func _on_card_pressed(card_view: CardView) -> void:
	if is_gameplay_input_blocked(): return
	if _launch_confirmation_pending or _transaction_in_progress or _phase_state != PhaseState.ACTIVE_DEVELOPMENT or not _is_current_candidate_view(card_view):
		return
	if _selected_card_views.has(card_view):
		_selected_card_views.erase(card_view)
		card_view.set_selected(false)
	elif _selected_card_views.size() < SELECTED_HAND_SIZE:
		_selected_card_views.append(card_view)
		card_view.set_selected(true)
	else:
		push_warning("At most four Beta candidate instances may be selected.")
	_update_play_action()


func _is_current_candidate_view(card_view: CardView) -> bool:
	return card_view != null and is_instance_valid(card_view) and card_view in _candidate_views and card_view.get_parent() == %HandContainer


func _invalid_deal(message: String) -> Dictionary:
	return {&"valid": false, &"error": message, &"cards": [] as Array[CardData]}


func _refresh_known_bugs() -> void:
	if not is_node_ready():
		return
	var known_bugs := 0 if _project_state == null else _project_state.get_known_bugs()
	var fixed_bugs := 0 if _project_state == null else _project_state.get_fixed_bugs()
	%KnownBugsLabel.text = "Known Bugs: %d | Fixed Bugs: %d" % [known_bugs, fixed_bugs]


func _refresh_insider_information() -> void:
	if not is_node_ready():
		return
	%CompetitorInfoLabel.visible = false
	%ForecastInfoLabel.visible = false
	if _project_state == null or _snapshot_database == null:
		return
	var competitor_id := _project_state.get_revealed_competitor_snapshot_id()
	if not competitor_id.is_empty():
		var competitor := _snapshot_database.get_competitor(competitor_id)
		if competitor != null:
			%CompetitorInfoLabel.text = "Rival: %s — Target Release: Cycle %d" % [competitor.get_display_name(), competitor.get_target_release_cycle()]
			%CompetitorInfoLabel.visible = true
	var forecast_id := _project_state.get_revealed_market_forecast_snapshot_id()
	if not forecast_id.is_empty():
		var forecast := _snapshot_database.get_forecast(forecast_id)
		if forecast != null:
			%ForecastInfoLabel.text = "Forecast: %s — Launch Demand ×%s" % [forecast.get_display_name(), forecast.get_launch_demand_multiplier_text()]
			%ForecastInfoLabel.visible = true


func _update_play_action() -> void:
	refresh_workspace()
	_refresh_redraw_controls()
	if is_node_ready():
		%PlayHandButton.disabled = not _can_attempt_play()


func _update_host_playtest_action() -> void:
	if not is_node_ready():
		return
	%HostPlaytestButton.text = "Playtest Pending" if not _pending_corrective_pass_ids.is_empty() else "Host Playtest ($500)"
	%HostPlaytestButton.disabled = not _can_host_playtest()


func _update_launch_action() -> void:
	if is_node_ready():
		%LaunchGameButton.disabled = not _can_launch()


func _update_all_actions() -> void:
	_update_begin_action()
	_update_play_action()
	_update_host_playtest_action()
	_update_launch_action()
	var editing_disabled := _launch_confirmation_pending or _transaction_in_progress or _phase_state == PhaseState.FINALIZED
	%QAPriority.editable = not editing_disabled
	%MarketingPriority.editable = not editing_disabled
	%InsiderPriority.editable = not editing_disabled


func _on_qa_priority_value_changed(value: float) -> void:
	_update_priority_draft(CardData.BETA_CATEGORY_QA, value)


func _on_marketing_priority_value_changed(value: float) -> void:
	_update_priority_draft(CardData.BETA_CATEGORY_MARKETING, value)


func _on_insider_priority_value_changed(value: float) -> void:
	_update_priority_draft(CardData.BETA_CATEGORY_INSIDER, value)


func _update_priority_draft(category: StringName, value: float) -> void:
	if _syncing_priority_controls or _launch_confirmation_pending or _transaction_in_progress or _phase_state == PhaseState.FINALIZED:
		return
	if not is_finite(value) or value < BetaPriorityAllocation.MIN_PRIORITY or value > BetaPriorityAllocation.MAX_PRIORITY or int(value) != value or int(value) % BetaPriorityAllocation.PRIORITY_STEP != 0:
		_sync_priority_controls()
		return
	_priority_draft[category] = int(value)
	_sync_priority_controls(false)
	_update_begin_action()


func _on_committed_priorities_changed() -> void:
	priorities_changed.emit()


func _sync_priority_controls(reset_draft: bool = true) -> void:
	if not is_node_ready():
		return
	if reset_draft:
		_priority_draft = _priority_allocation.get_distribution()
	_syncing_priority_controls = true
	%QAPriority.value = _priority_draft[CardData.BETA_CATEGORY_QA]
	%MarketingPriority.value = _priority_draft[CardData.BETA_CATEGORY_MARKETING]
	%InsiderPriority.value = _priority_draft[CardData.BETA_CATEGORY_INSIDER]
	%QAPriorityValue.text = str(_priority_draft[CardData.BETA_CATEGORY_QA])
	%MarketingPriorityValue.text = str(_priority_draft[CardData.BETA_CATEGORY_MARKETING])
	%InsiderPriorityValue.text = str(_priority_draft[CardData.BETA_CATEGORY_INSIDER])
	var total := 0
	for value: int in _priority_draft.values():
		total += value
	%PriorityTotal.text = "Priority Total: %d / 100" % total
	%CommitPrioritiesButton.disabled = _phase_state == PhaseState.FINALIZED or not BetaPriorityAllocation.is_valid_distribution(_priority_draft) or (_phase_state != PhaseState.PLANNING and _priority_draft == get_priority_distribution()) or _transaction_in_progress or _launch_confirmation_pending
	_syncing_priority_controls = false


func _update_begin_action() -> void:
	if not is_node_ready():
		return
	%BeginBetaButton.disabled = _phase_state != PhaseState.PLANNING or _project_state == null or not _project_state.has_alpha_finalization() or not BetaPriorityAllocation.is_valid_distribution(_priority_draft)


func get_workspace() -> PhaseWorkspace:
	return _workspace


func refresh_workspace() -> void:
	if _workspace != null: _workspace.refresh()


func is_gameplay_input_blocked() -> bool:
	return not is_inside_tree() or (_workspace != null and _workspace.overlay != null and _workspace.overlay.visible)


func can_edit_priorities() -> bool:
	return is_inside_tree() and _phase_state == PhaseState.ACTIVE_DEVELOPMENT and not _launch_confirmation_pending and not _transaction_in_progress


func is_initial_priority_planning() -> bool:
	return _phase_state == PhaseState.PLANNING


func can_initialize_priorities() -> bool:
	return is_inside_tree() and _phase_state == PhaseState.PLANNING and _project_state != null and _project_state.has_alpha_finalization() and not _launch_confirmation_pending and not _transaction_in_progress and BetaPriorityAllocation.is_valid_distribution(_priority_draft)


func open_priority_overlay() -> bool:
	return _workspace != null and _workspace.overlay.open()


func reset_priority_draft() -> void:
	_priority_draft = get_priority_distribution()
	_sync_priority_controls()


func refresh_overlay_actions() -> void:
	_update_all_actions()


func get_launch_readiness_text() -> String:
	if _project_state != null and not _project_state.has_launch_feature_work():
		return "Release requires a played Feature with positive Scope"
	return "Launch available" if _can_launch() else "Launch unavailable"
