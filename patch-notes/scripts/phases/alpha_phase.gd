class_name AlphaPhase
extends Control

var _workspace: PhaseWorkspace

signal priorities_changed
signal proceed_to_beta_requested

const CARD_VIEW_SCENE := preload("res://scenes/cards/card_view.tscn")
const PRIORITY_ALLOCATION_SCRIPT := preload("res://scripts/phases/priority_allocation.gd")
const WEIGHTED_CANDIDATE_MATH := preload("res://scripts/phases/weighted_candidate_math.gd")
const CANDIDATE_POOL_SIZE := 7
const SELECTED_HAND_SIZE := 4
const ALPHA_BUG_PRESSURE_DENOMINATOR := 18.0
const ALPHA_SPECIALIZATION_MULTIPLIER := 1.5
const ALPHA_BALANCED_PRODUCTION_THRESHOLD := 0.20
const ALPHA_BALANCED_PRODUCTION_MULTIPLIER := 1.20
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
	_deal_rng.randomize()
	_finalization_rng.randomize()
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
	var commit := func() -> bool:
		if not _priority_allocation.set_distribution(distribution): return false
		_priority_draft = _priority_allocation.get_priority_distribution()
		_project_state.advance_cycle()
		return true
	if not _run_state.complete_productive_action(commit): return false
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
	if not _can_host_playtest():
		return false
	var corrective_categories := _select_corrective_categories()
	if corrective_categories.size() != 2 or corrective_categories[0] == corrective_categories[1]:
		return false
	var commit := func() -> bool:
		_pending_playtest_categories.assign(corrective_categories)
		_project_state.advance_cycle()
		return true
	if not (_run_state.complete_productive_action(commit) if _run_state != null else commit.call()): return false
	print("Host Playtest complete! One cycle advanced. Corrective Passes queued: %s" % _format_corrective_pass_names(_pending_playtest_categories))
	_update_host_playtest_action()
	return true


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
	return _finalize_alpha(_finalization_rng.randf(), _finalization_rng.randf())


func _on_proceed_to_beta_pressed() -> void:
	request_proceed_to_beta()


func _on_under_scope_confirmed() -> void:
	if not _scope_warning_pending:
		return
	_scope_warning_pending = false
	_finalize_alpha(_finalization_rng.randf(), _finalization_rng.randf())


func _on_under_scope_canceled() -> void:
	_scope_warning_pending = false


func _can_proceed_to_beta() -> bool:
	if is_gameplay_input_blocked(): return false
	return (
		_phase_state == PhaseState.ACTIVE_DEVELOPMENT
		and _project_state != null
		and _project_state.can_advance_cycle()
		and (_run_state == null or _run_state.can_advance_calendar_cycle())
		and not _project_state.has_alpha_finalization()
		and _has_valid_active_candidate_pool()
		and _build_alpha_feature_history(false).valid
	)


func _update_proceed_action() -> void:
	if not is_node_ready():
		return
	%ProceedToBetaButton.disabled = not _can_proceed_to_beta() or _scope_warning_pending


func _build_alpha_feature_history(report_errors: bool = true) -> Dictionary:
	var card_database := get_node_or_null("/root/CardDatabase")
	if card_database == null:
		if report_errors:
			push_warning("Cannot finalize Alpha Feature history without CardDatabase.")
		return {&"valid": false}
	var definitions: Array[CardData] = []
	definitions.assign(card_database.get_project_features_for_phase(_project_state, CardData.PHASE_ALPHA))
	var eligible_ids: Dictionary[StringName, bool] = {}
	for card: CardData in definitions:
		if (
			card == null
			or card.id.is_empty()
			or card.phase != CardData.PHASE_ALPHA
			or card.card_type != &"feature"
			or card.renewable
			or eligible_ids.has(card.id)
		):
			if report_errors:
				push_warning("Cannot finalize invalid Alpha Feature definition history.")
			return {&"valid": false}
		eligible_ids[card.id] = true
	for exhausted_id: StringName in _exhausted_feature_ids:
		if not eligible_ids.has(exhausted_id):
			if report_errors:
				push_warning("Exhausted ID is not an eligible Alpha Feature: %s" % exhausted_id)
			return {&"valid": false}

	var implemented_ids: Array[StringName] = []
	var unimplemented_ids: Array[StringName] = []
	for id: StringName in eligible_ids:
		if _exhausted_feature_ids.has(id):
			implemented_ids.append(id)
		else:
			unimplemented_ids.append(id)
	implemented_ids.sort_custom(func(a: StringName, b: StringName) -> bool: return str(a) < str(b))
	unimplemented_ids.sort_custom(func(a: StringName, b: StringName) -> bool: return str(a) < str(b))
	return {
		&"valid": true,
		&"implemented_ids": implemented_ids,
		&"unimplemented_ids": unimplemented_ids,
	}


func _calculate_alpha_finalization(stochastic_roll: float, variance_roll: float) -> Dictionary:
	if (
		_project_state == null
		or not is_finite(stochastic_roll)
		or stochastic_roll < 0.0
		or stochastic_roll >= 1.0
		or not is_finite(variance_roll)
		or variance_roll < 0.0
		or variance_roll >= 1.0
	):
		return {&"valid": false}
	var pressure := _project_state.get_accumulated_alpha_bug_pressure()
	if not is_finite(pressure) or pressure < 0.0:
		return {&"valid": false}
	var base := floori(pressure)
	var fraction := pressure - base
	var rounded := base + (1 if stochastic_roll < fraction else 0)
	var variance := _get_alpha_bug_variance(variance_roll)
	var generated := maxi(0, rounded + variance)
	return {
		&"valid": true,
		&"pressure": pressure,
		&"base": base,
		&"rounded": rounded,
		&"variance": variance,
		&"generated": generated,
	}


func _get_alpha_bug_variance(roll: float) -> int:
	if roll < BUG_VARIANCE_NEGATIVE_TWO_THRESHOLD:
		return -2
	if roll < BUG_VARIANCE_NEGATIVE_ONE_THRESHOLD:
		return -1
	if roll < BUG_VARIANCE_ZERO_THRESHOLD:
		return 0
	if roll < BUG_VARIANCE_POSITIVE_ONE_THRESHOLD:
		return 1
	return 2


func _finalize_alpha(stochastic_roll: float, variance_roll: float) -> bool:
	if not _can_proceed_to_beta():
		return false
	var feature_history := _build_alpha_feature_history()
	if not feature_history.valid:
		return false
	var finalization := _calculate_alpha_finalization(stochastic_roll, variance_roll)
	if not finalization.valid:
		return false
	if not _project_state.finalize_alpha(
		finalization.generated,
		feature_history.implemented_ids,
		feature_history.unimplemented_ids,
	):
		return false
	var discarded_playtest := not _pending_playtest_categories.is_empty()
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
	if _project_state == null:
		return [] as Array[ProjectState.CoreScore]
	var categories: Array[ProjectState.CoreScore] = []
	categories.assign(ProjectState.CoreScore.values())
	categories.sort_custom(func(a: ProjectState.CoreScore, b: ProjectState.CoreScore) -> bool:
		var a_score := _project_state.get_core_score(a)
		var b_score := _project_state.get_core_score(b)
		if a_score != b_score:
			return a_score < b_score
		var a_priority := get_priority(a)
		var b_priority := get_priority(b)
		if a_priority != b_priority:
			return a_priority > b_priority
		return a < b
	)
	return categories.slice(0, 2)


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
	var had_pending_playtest := not _pending_playtest_categories.is_empty()
	var deal := (
		_build_corrective_candidate_definitions(get_priority_distribution(), controlled_rolls)
		if had_pending_playtest
		else _build_weighted_candidate_definitions(get_priority_distribution(), controlled_rolls)
	)
	if not deal.valid:
		push_warning("Could not build a complete weighted Alpha candidate pool: %s" % deal.error)
		return false
	_candidate_cards.assign(deal.cards)
	for card: CardData in _candidate_cards:
		var card_view := CARD_VIEW_SCENE.instantiate() as CardView
		card_view.set_card(card)
		card_view.card_pressed.connect(_on_card_pressed)

		%HandContainer.add_child(card_view)
	if had_pending_playtest:
		var injected_categories := _pending_playtest_categories.duplicate()
		_pending_playtest_categories.clear()
		print("Host Playtest corrective Passes injected and consumed: %s" % _format_corrective_pass_names(injected_categories))
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

		_candidate_cards[slot] = replacement

		%HandContainer.remove_child(old_view)
		old_view.queue_free()
		%HandContainer.add_child(prepared[index])
		%HandContainer.move_child(prepared[index], slot)
	_selected_card_views.clear()
	%RedrawFeedbackLabel.text = ""
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


func _build_corrective_candidate_definitions(priority_snapshot: Dictionary, controlled_rolls: Array[float] = []) -> Dictionary:
	if _pending_playtest_categories.size() != 2 or _pending_playtest_categories[0] == _pending_playtest_categories[1]:
		return {&"valid": false, &"error": "A corrective Alpha deal requires two distinct queued Core categories."}
	var injected_cards: Array[CardData] = []
	for category: ProjectState.CoreScore in _pending_playtest_categories:
		var pass_card := _get_pass_for_category(category)
		if pass_card == null:
			return {&"valid": false, &"error": "A queued corrective Core Pass is unavailable."}
		injected_cards.append(pass_card)
	var weighted_deal := _build_weighted_candidate_definitions(priority_snapshot, controlled_rolls, CANDIDATE_POOL_SIZE - injected_cards.size())
	if not weighted_deal.valid:
		return weighted_deal
	var cards := injected_cards.duplicate()
	cards.append_array(weighted_deal.cards)
	return {&"valid": true, &"cards": cards}


func _build_weighted_candidate_definitions(priority_snapshot: Dictionary, controlled_rolls: Array[float] = [], candidate_count: int = CANDIDATE_POOL_SIZE) -> Dictionary:
	var validation_error := _get_deal_input_validation_error(priority_snapshot, controlled_rolls, candidate_count)
	if not validation_error.is_empty():
		return {&"valid": false, &"error": validation_error}
	var remaining_features := _available_features.duplicate()
	var selected_cards: Array[CardData] = []
	for slot in range(candidate_count):
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
			remaining_features.erase(selected)
	return {&"valid": true, &"cards": selected_cards}


func _select_weighted_entry(entries: Array[Dictionary], roll: float) -> CardData:
	return WEIGHTED_CANDIDATE_MATH.select_weighted_entry(entries, roll)


func _calculate_candidate_weight(card: CardData, priority_snapshot: Dictionary) -> float:
	return WEIGHTED_CANDIDATE_MATH.calculate_printed_score_weight(card, priority_snapshot, CORE_SCORE_BY_STAT)


func _get_deal_input_validation_error(priority_snapshot: Dictionary, controlled_rolls: Array[float], candidate_count: int = CANDIDATE_POOL_SIZE) -> String:
	if candidate_count < 1 or candidate_count > CANDIDATE_POOL_SIZE:
		return "Alpha candidate count must be between one and seven."
	if priority_snapshot.size() != PriorityAllocation.CORE_CATEGORIES.size():
		return "Priority snapshot must contain all four Core categories."
	var total_priority := 0
	for category: ProjectState.CoreScore in PriorityAllocation.CORE_CATEGORIES:
		if not priority_snapshot.has(category) or typeof(priority_snapshot[category]) != TYPE_INT:
			return "Priority snapshot contains a missing or malformed category."
		var value: int = priority_snapshot[category]
		if value < PriorityAllocation.MIN_PRIORITY or value > PriorityAllocation.MAX_PRIORITY or value % PriorityAllocation.PRIORITY_STEP != 0:
			return "Priority snapshot contains an out-of-range or non-step value."
		total_priority += value
	if total_priority > PriorityAllocation.MAX_TOTAL_PRIORITY:
		return "Priority snapshot exceeds the allocation budget."
	if not controlled_rolls.is_empty():
		if controlled_rolls.size() != candidate_count:
			return "A controlled Alpha deal requires exactly %d rolls." % candidate_count
		for roll: float in controlled_rolls:
			if not is_finite(roll) or roll < 0.0 or roll >= 1.0:
				return "Controlled Alpha rolls must be finite values in [0, 1)."

	var feature_ids: Dictionary[StringName, bool] = {}
	for card: CardData in _available_features:
		var error := _get_feature_validation_error(card)
		if not error.is_empty():
			return error
		if feature_ids.has(card.id):
			return "Alpha Feature IDs must be unique: %s" % card.id
		if _exhausted_feature_ids.has(card.id):
			return "Exhausted Alpha Feature cannot remain available: %s" % card.id
		feature_ids[card.id] = true
	if _pass_definitions.size() != 4:
		return "Alpha requires exactly four Core Pass definitions."
	var pass_categories: Dictionary[ProjectState.CoreScore, bool] = {}
	var pass_ids: Dictionary[StringName, bool] = {}
	for card: CardData in _pass_definitions:
		var error := _get_pass_validation_error(card)
		if not error.is_empty():
			return error
		var category: ProjectState.CoreScore = CORE_SCORE_BY_STAT[card.primary_stat]
		if pass_categories.has(category) or pass_ids.has(card.id):
			return "Alpha requires one unique Pass per Core category."
		pass_categories[category] = true
		pass_ids[card.id] = true
	return ""


func _get_pass_for_category(category: ProjectState.CoreScore) -> CardData:
	for card: CardData in _pass_definitions:
		if CORE_SCORE_BY_STAT.get(card.primary_stat, -1) == category:
			return card
	return null


func _get_feature_validation_error(card: CardData) -> String:
	if card == null or card.id.is_empty():
		return "Alpha Features require stable nonempty IDs."
	if card.phase != CardData.PHASE_ALPHA or card.card_type != &"feature" or card.renewable:
		return "Candidate '%s' is not a nonrenewable Alpha Feature." % card.id
	if card.department not in ALPHA_DEPARTMENTS:
		return "Alpha Feature '%s' has an invalid department." % card.id
	if card.scope < 0:
		return "Alpha Feature '%s' has negative Scope." % card.id
	return _get_printed_score_validation_error(card)


func _get_pass_validation_error(card: CardData) -> String:
	if card == null or card.id.is_empty():
		return "Core Passes require stable nonempty IDs."
	if card.phase != CardData.PHASE_DESIGN or card.card_type != &"pass" or not card.renewable:
		return "Candidate '%s' is not an Alpha-authorized Core Pass." % card.id
	if not card.department.is_empty() or card.scope != 0 or not card.secondary_stat.is_empty() or card.secondary_value != 0:
		return "Core Pass '%s' has invalid Alpha pool fields." % card.id
	return _get_printed_score_validation_error(card)


func _get_printed_score_validation_error(card: CardData) -> String:
	if not CORE_SCORE_BY_STAT.has(card.primary_stat) or card.primary_value < 0:
		return "Candidate '%s' has an invalid primary score." % card.id
	if card.secondary_stat.is_empty():
		if card.secondary_value != 0:
			return "Candidate '%s' has a secondary value without a stat." % card.id
	elif not CORE_SCORE_BY_STAT.has(card.secondary_stat) or card.secondary_value < 0:
		return "Candidate '%s' has an invalid secondary score." % card.id
	return ""


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
		var cost := _run_state.primitive_feature_hand_cost_cents(cards)
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
	if not _can_play_selected_instances():
		return
	var action := _validate_and_calculate_base_action()
	if not action.valid:
		return
	var play_cost := 0
	if _run_state != null:
		var selected_cards: Array[CardData] = []
		selected_cards.assign(action.cards)
		play_cost = _run_state.primitive_feature_hand_cost_cents(selected_cards)
		if play_cost < 0 or _run_state.get_cash_cents() < play_cost:
			return
	var final_production := _calculate_final_action_production(action)
	var additions: Dictionary[ProjectState.CoreScore, int] = final_production.score_additions
	var commit := func() -> bool:
		if not _project_state.add_alpha_production(additions, action.scope, action.alpha_bug_pressure): return false
		_complete_successful_action()
		return true
	if not (_run_state.complete_productive_action(commit, -play_cost) if _run_state != null else commit.call()):
		return
	if not final_production.specialization_stat.is_empty():
		print(_build_specialization_debug_message(final_production.specialization_stat, additions))
	elif final_production.balanced_production:
		print(_build_balanced_production_debug_message(additions))
	if not _deal_next_candidate_pool():
		push_warning("The Alpha hand resolved, but the next weighted candidate pool could not be dealt.")
	if not final_production.specialization_stat.is_empty():
		_workspace.show_synergy("%s Specialization!" % str(final_production.specialization_stat).capitalize(), "Production ×1.50")
	elif final_production.balanced_production:
		_workspace.show_synergy("Balanced Production!", "Production ×1.20")


func _validate_and_calculate_base_action() -> Dictionary:
	if not _can_play_selected_instances():
		return _invalid_action("A complete Alpha action requires four current candidate instances.")
	var score_additions: Dictionary[ProjectState.CoreScore, int] = {}
	var scope_amount := 0
	var alpha_bug_pressure := 0.0
	var cards: Array[CardData] = []
	var seen_feature_ids: Dictionary[StringName, bool] = {}
	for card_view: CardView in _selected_card_views:
		var card := card_view.card_data
		if card == null or not _candidate_cards.has(card):
			return _invalid_action("Alpha selection contains stale or missing CardData.")
		var validation_error := ""
		if card.card_type == &"feature":
			validation_error = _get_feature_validation_error(card)
			if validation_error.is_empty() and (not _available_features.has(card) or _exhausted_feature_ids.has(card.id)):
				validation_error = "Alpha Feature '%s' is not currently available." % card.id
			if validation_error.is_empty() and seen_feature_ids.has(card.id):
				validation_error = "Alpha Feature '%s' appears more than once in the action." % card.id
			seen_feature_ids[card.id] = true
		elif card.card_type == &"pass":
			validation_error = _get_pass_validation_error(card)
			if validation_error.is_empty() and not _pass_definitions.has(card):
				validation_error = "Pass '%s' is not authorized for Alpha." % card.id
		else:
			validation_error = "Card '%s' has an invalid Alpha action type." % card.id
		if not validation_error.is_empty():
			return _invalid_action(validation_error)

		cards.append(card)
		var primary_category: ProjectState.CoreScore = CORE_SCORE_BY_STAT[card.primary_stat]
		score_additions[primary_category] = score_additions.get(primary_category, 0) + card.primary_value
		if not card.secondary_stat.is_empty():
			var secondary_category: ProjectState.CoreScore = CORE_SCORE_BY_STAT[card.secondary_stat]
			score_additions[secondary_category] = score_additions.get(secondary_category, 0) + card.secondary_value
		scope_amount += card.scope
		if card.card_type == &"feature":
			alpha_bug_pressure += _calculate_feature_alpha_bug_pressure(card)
	return {
		&"valid": true,
		&"cards": cards,
		&"score_additions": score_additions,
		&"scope": scope_amount,
		&"alpha_bug_pressure": alpha_bug_pressure,
	}


func _calculate_final_action_production(base_action: Dictionary) -> Dictionary:
	var cards: Array[CardData] = []
	cards.assign(base_action.cards)
	var specialization_stat := _get_specialization_stat(cards)
	var provisional_scores := _calculate_provisional_core_scores(base_action.score_additions)
	var has_feature := cards.any(func(card: CardData) -> bool: return card.card_type == &"feature")
	var balanced_production := has_feature and _are_core_scores_balanced(provisional_scores)
	var score_additions: Dictionary[ProjectState.CoreScore, int] = {}
	for category: ProjectState.CoreScore in base_action.score_additions:
		score_additions[category] = base_action.score_additions[category]
	if not specialization_stat.is_empty():
		for category: ProjectState.CoreScore in score_additions:
			score_additions[category] = roundi(score_additions[category] * ALPHA_SPECIALIZATION_MULTIPLIER)
	elif balanced_production:
		for category: ProjectState.CoreScore in score_additions:
			score_additions[category] = roundi(score_additions[category] * ALPHA_BALANCED_PRODUCTION_MULTIPLIER)
	return {
		&"specialization_stat": specialization_stat,
		&"balanced_production": specialization_stat.is_empty() and balanced_production,
		&"balanced_eligible": balanced_production,
		&"provisional_scores": provisional_scores,
		&"score_additions": score_additions,
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
	var lower_bound := mean * (1.0 - ALPHA_BALANCED_PRODUCTION_THRESHOLD)
	var upper_bound := mean * (1.0 + ALPHA_BALANCED_PRODUCTION_THRESHOLD)
	for category: ProjectState.CoreScore in ProjectState.CoreScore.values():
		var score: int = scores.get(category, 0)
		if score < lower_bound or score > upper_bound:
			return false
	return true


func _get_specialization_stat(cards: Array[CardData]) -> StringName:
	if cards.size() != SELECTED_HAND_SIZE:
		return &""
	var specialization_stat := cards[0].primary_stat
	if not CORE_SCORE_BY_STAT.has(specialization_stat):
		return &""
	for card: CardData in cards:
		if card.primary_stat != specialization_stat:
			return &""
	return specialization_stat


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
	var raw_score := card.primary_value
	if not card.secondary_stat.is_empty():
		raw_score += card.secondary_value
	return (float(raw_score) * float(card.scope)) / ALPHA_BUG_PRESSURE_DENOMINATOR


func _invalid_action(message: String) -> Dictionary:
	push_warning(message)
	return {
		&"valid": false,
		&"cards": [] as Array[CardData],
		&"score_additions": {},
		&"scope": 0,
		&"alpha_bug_pressure": 0.0,
	}


func _complete_successful_action() -> void:
	for card_view: CardView in _selected_card_views:
		var card := card_view.card_data
		if card.card_type == &"feature":
			_exhausted_feature_ids[card.id] = true
			if _run_state != null:
				_run_state.record_resolved_feature(_project_state, card.id, CardData.PHASE_ALPHA)
			_available_features.erase(card)
	_clear_candidate_pool()
	_project_state.advance_cycle()


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
	return not is_inside_tree() or (_workspace != null and _workspace.overlay != null and _workspace.overlay.visible)


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
