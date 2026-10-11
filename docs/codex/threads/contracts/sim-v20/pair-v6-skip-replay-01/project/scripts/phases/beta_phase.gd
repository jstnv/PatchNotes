class_name BetaPhase
extends Control

const DevelopmentActions := preload("res://scripts/simulation/development_actions.gd")

const BetaHandCommand := preload("res://scripts/simulation/beta_hand_command.gd")
var _command_view_ids: Dictionary = {}
var _command_next_id := 0
var _command_revision := 0
var _last_hand_command_result: Dictionary = {}

var _workspace: PhaseWorkspace

signal priorities_changed
signal launch_requested

const CARD_VIEW_SCENE := preload("res://scenes/cards/card_view.tscn")
const BETA_PRIORITY_ALLOCATION_SCRIPT := preload("res://scripts/phases/beta_priority_allocation.gd")
const CANDIDATE_POOL_SIZE := BetaHandCommand.CANDIDATE_POOL_SIZE
const SELECTED_HAND_SIZE := BetaHandCommand.SELECTED_HAND_SIZE
const QA_SPECIALIZATION_MULTIPLIER := BetaHandCommand.QA_SPECIALIZATION_MULTIPLIER
const MARKETING_SPECIALIZATION_MULTIPLIER := BetaHandCommand.MARKETING_SPECIALIZATION_MULTIPLIER
const BALANCED_OPERATIONS_MULTIPLIER := BetaHandCommand.BALANCED_OPERATIONS_MULTIPLIER
const HOST_PLAYTEST_COST := 500
const HOST_PLAYTEST_COST_CENTS := DevelopmentActions.BETA_PLAYTEST_COST_CENTS
const PLAYTEST_RIVAL_PAYOUT_CENTS := BetaHandCommand.PLAYTEST_RIVAL_PAYOUT_CENTS
const CORE_SCORE_BY_STAT := BetaHandCommand.CORE_SCORE_BY_STAT
const PASS_ID_BY_CORE_SCORE := BetaHandCommand.PASS_ID_BY_CORE_SCORE
const FINITE_IDS: Array[StringName] = BetaHandCommand.FINITE_IDS

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
	if _run_state != null: _deal_rng = _run_state.random_streams.stream(&"beta_deal")
	else: _deal_rng.randomize()
	if _run_state != null: _insight_rng = _run_state.random_streams.stream(&"beta_insight")
	else: _insight_rng.randomize()
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
	if _run_state != null: _insight_rng = _run_state.random_streams.stream(&"beta_insight")
	if _run_state != null: _deal_rng = _run_state.random_streams.stream(&"beta_deal")
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
	var publish:=func() -> void:
		_priority_draft=_priority_allocation.get_distribution()
	if not DevelopmentActions.commit_priorities(_project_state,_run_state,_priority_allocation,distribution,publish): return false
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
	var actions:=_capture_development_actions()
	actions.hand.priorities=committed_snapshot
	var deal: Dictionary = actions.initial_plan(category_rolls,definition_rolls)
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
	actions.publish_initial(deal)
	_candidate_cards.assign(actions.hand._candidate_cards)
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
	_sync_command_tokens(actions.hand)
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
	_transaction_in_progress=true
	var actions:=_capture_development_actions()
	var slots:=_redraw_slots()
	var selected:=_selected_card_views.duplicate()
	var prepared: Array[CardView] = []
	var prepare:=func(cards: Array) -> bool:
		for card: CardData in cards:
			var view: CardView = _instantiate_card_view()
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
			_candidate_views[slots[index]]=prepared[index]
		_selected_card_views.clear()
		_sync_command_tokens(actions.hand)
	var result: Dictionary = actions.redraw(slots,controlled_rolls,prepare,publish)
	if not result.ok:
		for view in prepared: view.free()

	else:

		_sync_command_tokens(actions.hand)
	_transaction_in_progress=false
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
	return _capture_development_actions().boundary()._build_launch_warnings()


func _finalize_beta() -> bool:
	if _phase_state != PhaseState.ACTIVE_DEVELOPMENT or _transaction_in_progress or _project_state == null or _project_state.has_beta_finalization():
		return false
	var was_confirming := _launch_confirmation_pending
	_launch_confirmation_pending = false
	if not _can_launch():
		_launch_confirmation_pending = was_confirming
		_update_all_actions()
		return false
	_transaction_in_progress=true
	var result: Dictionary = _capture_development_actions().finalize()
	if not result.ok:
		_transaction_in_progress=false
		_launch_confirmation_pending=was_confirming
		_update_all_actions()
		return false
	_pending_corrective_pass_ids.clear()
	_phase_state = PhaseState.FINALIZED
	_retire_beta_interface()
	_transaction_in_progress = false
	launch_requested.emit()
	return true


func _validate_exhausted_beta_ids(database: Node) -> bool:
	return _capture_development_actions().boundary()._validate_exhausted_beta_ids(database.get_development_catalog())


func _validate_feature_histories(database: Node) -> bool:
	return _capture_development_actions().boundary()._validate_feature_histories(database.get_development_catalog())


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
	_transaction_in_progress=true
	var actions:=_capture_development_actions()
	actions.hand._pending_corrective_pass_ids=_pending_corrective_pass_ids
	if not actions.host_playtest():
		_transaction_in_progress=false
		_update_all_actions()
		return false
	var pass_ids:=_pending_corrective_pass_ids.duplicate()
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
	if not _can_attempt_play(): return false
	_transaction_in_progress = true
	_update_all_actions()
	var resolver := _capture_beta_command()
	var ids: Array[int] = []
	for view in _selected_card_views: ids.append(_command_view_ids[view.get_instance_id()])
	var prepared: Array[CardView] = []
	var readiness := func(cards: Array) -> bool:
		for card: CardData in cards:
			var view := _instantiate_card_view()
			if view == null: return false
			view.set_card(card)
			view.card_pressed.connect(_on_card_pressed)
			prepared.append(view)
		return true
	var result: Dictionary = resolver.execute(resolver.command(ids),insight_rolls,replacement_category_rolls,replacement_definition_rolls,readiness)
	if not result.ok:
		for view in prepared: view.free()
		_transaction_in_progress = false
		_update_all_actions()
		push_warning("Beta hand rejected: %s" % result.error)
		return false
	var preflight: Dictionary = result.preflight
	_publish_replacement_pool(preflight.next_cards,prepared,preflight.injected_corrective_count)
	_pending_corrective_pass_ids.assign(resolver._pending_corrective_pass_ids)
	_command_revision = resolver.revision
	_command_next_id = resolver.next_candidate_id
	_command_view_ids.clear()
	for index in range(_candidate_views.size()): _command_view_ids[_candidate_views[index].get_instance_id()] = resolver.candidate_ids[index]
	_last_hand_command_result = result
	_refresh_known_bugs()
	_refresh_insider_information()
	_show_action_feedback(preflight,result.discovered,result.fixed)
	_transaction_in_progress = false
	_update_all_actions()
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



func _qualifies_for_qa_specialization(cards: Array[CardData]) -> bool:
	return _capture_beta_command()._qualifies_for_qa_specialization(cards)


func _qualifies_for_marketing_specialization(cards: Array[CardData]) -> bool:
	return _capture_beta_command()._qualifies_for_marketing_specialization(cards)


func _qualifies_for_balanced_operations(cards: Array[CardData]) -> bool:
	return _capture_beta_command()._qualifies_for_balanced_operations(cards)


func _select_corrective_pass_ids() -> Array[StringName]:
	return _capture_development_actions().corrective_pass_ids()


func _is_valid_corrective_pass(card: CardData) -> bool:
	return _capture_beta_command()._is_valid_corrective_pass(card)


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
	return _capture_beta_command()._next_insight_roll(controlled, cursor)


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
	return _capture_beta_command()._invalid_play(message)


func _build_replacement_candidate_definitions(definitions: Array[CardData], priorities: Dictionary, category_rolls: Array[float], definition_rolls: Array[float], excluded_ids: Array[StringName]) -> Dictionary:
	return _capture_beta_command()._build_replacement_candidate_definitions(definitions, priorities, category_rolls, definition_rolls, excluded_ids)


func _build_candidate_definitions(definitions: Array[CardData], priorities: Dictionary, category_rolls: Array[float] = [], definition_rolls: Array[float] = [], excluded_ids: Array[StringName] = [], candidate_count: int = CANDIDATE_POOL_SIZE) -> Dictionary:
	return _capture_beta_command()._build_candidate_definitions(definitions, priorities, category_rolls, definition_rolls, excluded_ids, candidate_count)


func _select_weighted_value(entries: Array[Dictionary], roll: float) -> Variant:
	return _capture_beta_command()._select_weighted_value(entries, roll)


func _group_definitions(definitions: Array[CardData], excluded_ids: Array[StringName] = []) -> Dictionary:
	return _capture_beta_command()._group_definitions(definitions, excluded_ids)


func _get_definition_weight(card: CardData) -> float:
	return _capture_beta_command()._get_definition_weight(card)


func _get_source_validation_error(definitions: Array[CardData]) -> String:
	return _capture_beta_command()._get_source_validation_error(definitions)


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
	return _capture_beta_command()._invalid_deal(message)


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


## Only immutable definitions and explicit instance tokens cross the command boundary.
func _capture_beta_command() -> RefCounted:
	var state := BetaHandCommand.new()
	state._project_state = _project_state
	state._run_state = _run_state
	state._snapshot_database = _snapshot_database
	state._deal_rng = _deal_rng
	state._insight_rng = _insight_rng
	state._candidate_cards.assign(_candidate_cards)
	state._pending_corrective_pass_ids.assign(_pending_corrective_pass_ids)
	state.priorities = get_priority_distribution()
	state.active = _phase_state == PhaseState.ACTIVE_DEVELOPMENT
	state.launch_confirmation_pending = _launch_confirmation_pending
	state.revision = _command_revision
	var database := get_node_or_null("/root/CardDatabase") if is_inside_tree() else null
	if database != null:
		state._beta_definitions.assign(database.get_cards_by_phase(CardData.PHASE_BETA))
		for card in state._beta_definitions: state._definitions_by_id[card.id] = card
		for id in PASS_ID_BY_CORE_SCORE.values(): state._definitions_by_id[id] = database.get_card(id)
	for view in _candidate_views:
		if not is_instance_valid(view): continue
		var id := view.get_instance_id()
		if not _command_view_ids.has(id):
			_command_view_ids[id] = _command_next_id
			_command_next_id += 1
		state.candidate_ids.append(_command_view_ids[id])
		if view in _injected_corrective_views: state.injected_candidate_ids.append(_command_view_ids[id])
	state.next_candidate_id = _command_next_id
	return state


func _capture_development_actions() -> RefCounted:
	var actions:=DevelopmentActions.new()
	actions.phase=&"beta"
	actions.hand=_capture_beta_command()
	var database:=get_node_or_null("/root/CardDatabase") if is_inside_tree() else null
	if database!=null: actions.catalog=database.get_development_catalog()

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
