class_name StudioPhase
extends Control

signal tutorial_context_changed(context: StringName)

signal contract_requested(source: StudioPhase, state: ContractState)
signal development_requested(source: StudioPhase, base_name: String, genre: StringName, theme_id: StringName)

var _project_state: ProjectState
var _run_state: RunState
var _snapshot_database: PrimitiveSnapshotDatabase
var _feature_store: FeatureStore
var _publisher_browser: PublisherBrowser
var _publisher_notice: PanelContainer
var _contract_detail: PanelContainer
var _selected_contract_offer_id: StringName
var _predevelopment: PredevelopmentOverlay
var _review_view: PostGameReview
var _selected_release_id: StringName


func _ready() -> void:
	%StartNextGame.pressed.connect(_open_predevelopment)
	%FeatureStoreButton.pressed.connect(_open_feature_store)
	%PublisherList.pressed.connect(_open_publishers)
	%PostGameSummaries.pressed.connect(open_summary)
	%CloseSummaryButton.pressed.connect(close_summary)
	%DetailedReviewButton.pressed.connect(open_detailed_review)
	%Contracts.pressed.connect(_open_contracts)
	%GameList.item_selected.connect(_on_game_selected)
	%LowScopeWarning.confirmed.connect(_show_predevelopment)
	%PostGameSummaries.tooltip_text = "Browse every released game, its category Reviews, and earned versus projected sales. Opening is free."
	%FeatureStoreButton.tooltip_text = "Browse owned Features, prices and prerequisites. Opening the Store costs no cycles."
	%StartNextGame.tooltip_text = "Name the next game and choose its Genre and Theme. Opening setup is free."
	if _run_state != null:
		_refresh_game_list()
		_refresh_summary()
		_show_pending_publisher_notice()
		_refresh_starter_hint()


func _refresh_starter_hint() -> void:
	if _run_state == null or not is_node_ready():
		return
	%StoreHint.visible = _run_state.needs_starter_selection()
	if not %StoreHint.visible:
		return
	var pool := _run_state.get_starter_pool_summary()
	%StoreHintText.text = "TIP · Visit the Feature Store to buy Primitive Features for your first game.\nPool: %d / 23 Scope · %s / $4,000 spent. Aim for 20–23 Scope." % [pool.scope, CashFormatter.format_exact_cents(pool.spent_cents)]
	%FeatureStoreButton.tooltip_text = "Buy first-game Primitive Features here. Starter purchases cost zero cycles."


func _open_publishers() -> void:
	if _run_state == null:
		return
	if _publisher_browser == null:
		_publisher_browser = PublisherBrowser.new()
		_publisher_browser.name = "PublisherBrowser"
		add_child(_publisher_browser)
		_publisher_browser.setup(_run_state)
		_publisher_browser.closed.connect(func():
			_publisher_browser.hide()
			%Dashboard.show()
			%PublisherList.grab_focus()
			tutorial_context_changed.emit(&"studio"))
	%SummaryPanel.hide()
	%Dashboard.hide()
	_publisher_browser.open_browser()
	tutorial_context_changed.emit(&"studio")


func _show_pending_publisher_notice() -> void:
	if _run_state == null or not is_node_ready():
		return
	var unlocked := _run_state.take_pending_publisher_notifications()
	if unlocked.is_empty():
		return
	if _publisher_notice == null:
		_publisher_notice = PanelContainer.new()
		_publisher_notice.name = "PublisherUnlockNotice"
		$Dashboard/Layout.add_child(_publisher_notice)
		$Dashboard/Layout.move_child(_publisher_notice, 1)
		var row := HBoxContainer.new()
		_publisher_notice.add_child(row)
		var message := Label.new()
		message.name = "PublisherUnlockMessage"
		message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(message)
		var dismiss := Button.new()
		dismiss.name = "DismissPublisherNotice"
		dismiss.text = "Dismiss"
		dismiss.pressed.connect(func(): _publisher_notice.hide())
		row.add_child(dismiss)
	var names: Array[String] = []
	for id: StringName in unlocked:
		names.append(PublisherCatalog.name_for(id))
	(_publisher_notice.find_child("PublisherUnlockMessage", true, false) as Label).text = "Publisher unlocked: %s" % ", ".join(names)
	_publisher_notice.show()


func _open_predevelopment() -> void:
	if _run_state == null:
		return
	if _run_state.needs_starter_selection():
		var pool := _run_state.get_starter_pool_summary()
		if int(pool.scope) < 20:
			%LowScopeWarning.dialog_text = "Your pool has %d printed Scope, below the 20–23 target and the 30-Scope B standard. Visit the Feature Store for more Features, or continue with this smaller pool?" % pool.scope
			%LowScopeWarning.popup_centered()
			return
	_show_predevelopment()


func _show_predevelopment() -> void:
	if _predevelopment == null:
		_predevelopment = PredevelopmentOverlay.new()
		_predevelopment.name = "Predevelopment"
		add_child(_predevelopment)
		_predevelopment.begin_requested.connect(func(base_name: String, genre: StringName, theme_id: StringName):
			development_requested.emit(self, base_name, genre, theme_id))
		_predevelopment.cancelled.connect(func():
			_predevelopment.hide()
			%Dashboard.show()
			%StartNextGame.grab_focus()
			tutorial_context_changed.emit(&"studio"))
	%SummaryPanel.hide()
	%Dashboard.hide()
	_predevelopment.open()
	tutorial_context_changed.emit(&"predevelopment")


func show_development_error(message: String) -> void:
	if _predevelopment != null:
		_predevelopment.error_label.text = message


func open_summary() -> void:
	if _run_state == null or _run_state.get_released_game_ids().is_empty(): return
	_refresh_game_list()
	_refresh_summary()
	%Dashboard.hide()
	%SummaryPanel.show()
	%CloseSummaryButton.grab_focus()
	tutorial_context_changed.emit(&"studio")


func close_summary() -> void:
	%SummaryPanel.hide()
	%Dashboard.show()
	%PostGameSummaries.grab_focus()
	tutorial_context_changed.emit(&"studio")


## The former interstitial review is still inspectable, but no longer gates
## automatic Studio entry or performs release registration when dismissed.
func open_detailed_review() -> void:
	if _selected_release_id.is_empty():
		return
	if _review_view != null:
		_review_view.queue_free()
		_review_view = null
	if _review_view == null:
		_review_view = preload("res://scenes/phases/post_game_review.tscn").instantiate()
		_review_view.name = "DetailedReview"
		var metadata := _run_state.get_release_metadata(_selected_release_id)
		var sales := _run_state.get_released_game_sales(_selected_release_id)
		if not _review_view.setup_release_snapshot(metadata, sales):
			_review_view.free()
			_review_view = null
			return
		add_child(_review_view)
		_review_view.get_node("%ContinueButton").text = "Back to Summary"
		_review_view.continue_to_studio_requested.connect(func():
			_review_view.hide()
			open_summary())
	%Dashboard.hide()
	%SummaryPanel.hide()
	_review_view.show()
	tutorial_context_changed.emit(&"review")


func _open_contracts() -> void:
	if _run_state == null:
		return
	var active := _run_state.get_active_contract()
	if active != null:
		contract_requested.emit(self, active)
		return
	_selected_contract_offer_id = &""
	if _run_state.is_primitive_contract_offer_available():
		_selected_contract_offer_id = ContractState.CONTRACT_ID
	elif _run_state.is_sidestreet_offer_available():
		_selected_contract_offer_id = _run_state.get_next_sidestreet_offer().offer_id
	if _selected_contract_offer_id.is_empty():
		return
	_ensure_contract_detail()
	_configure_contract_detail()
	%SummaryPanel.hide()
	%Dashboard.hide()
	_contract_detail.show()
	tutorial_context_changed.emit(&"contract")
	(_contract_detail.find_child("AcceptContractButton", true, false) as Button).grab_focus()


func _ensure_contract_detail() -> void:
	if _contract_detail != null:
		return
	_contract_detail = PanelContainer.new()
	_contract_detail.name = "ContractDetail"
	_contract_detail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_contract_detail)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	_contract_detail.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)
	var title := Label.new()
	title.name = "ContractDetailTitle"
	title.text = "Balanced Primitive Contract"
	title.add_theme_font_size_override("font_size", 26)
	layout.add_child(title)
	var details := Label.new()
	details.name = "ContractDetailText"
	details.text = "Publisher: Ironclad Interactive\nTwo production hands · four cards per hand\nTargets: Scope 12 · Graphics/Sound/Technology/Design 6 each\nInvestment and maximum total payout: $2,400.00\nAccept for a guaranteed $400.00 immediately; the earned remainder pays after hand two.\nUnlocked Primitive Design and Alpha Features are finite; Core Passes are renewable.\nAcceptance costs no cycles. The contract cannot be abandoned after acceptance."
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(details)
	var actions := HBoxContainer.new()
	layout.add_child(actions)
	var accept := Button.new()
	accept.name = "AcceptContractButton"
	accept.unique_name_in_owner = true
	accept.text = "Accept Contract"
	accept.custom_minimum_size = Vector2(200, 46)
	accept.pressed.connect(_accept_contract)
	actions.add_child(accept)
	var back := Button.new()
	back.name = "CloseContractDetailButton"
	back.unique_name_in_owner = true
	back.text = "Back to Studio"
	back.custom_minimum_size = Vector2(180, 46)
	back.pressed.connect(_close_contract_detail)
	actions.add_child(back)


func _configure_contract_detail() -> void:
	var title := _contract_detail.find_child("ContractDetailTitle", true, false) as Label
	var details := _contract_detail.find_child("ContractDetailText", true, false) as Label
	if _selected_contract_offer_id == ContractState.CONTRACT_ID:
		title.text = "Balanced Primitive Contract"
		details.text = "Publisher: Ironclad Interactive\nTwo production hands · four cards per hand\nTargets: Scope 12 · Graphics/Sound/Technology/Design 6 each\nInvestment and maximum total payout: $2,400.00\nAccept for a guaranteed $400.00 immediately; the earned remainder pays after hand two.\nUnlocked Primitive Design and Alpha Features are finite; Core Passes are renewable.\nAcceptance costs no cycles. The contract cannot be abandoned after acceptance."
	else:
		var offer := _run_state.get_next_sidestreet_offer()
		title.text = "SideStreet Cash Contract"
		details.text = "Publisher: SideStreet Games\nOffer for: %s\nTwo production hands · four cards per hand\nTargets: Scope 12 · Graphics/Sound/Technology/Design 6 each\nMaximum payout: $1,200.00, paid only after hand two according to completion.\nUnlocked Primitive Design and Alpha Features are finite; Core Passes are renewable.\nAcceptance costs no cash or cycles. The contract cannot be abandoned after acceptance." % _run_state.get_released_game_display_name(offer.release_id)


func _close_contract_detail() -> void:
	if _contract_detail != null:
		_contract_detail.hide()
	%Dashboard.show()
	%Contracts.grab_focus()
	tutorial_context_changed.emit(&"studio")


func _accept_contract() -> void:
	var state: ContractState = _run_state.accept_primitive_contract() if _selected_contract_offer_id == ContractState.CONTRACT_ID else _run_state.accept_sidestreet_offer(_selected_contract_offer_id)
	if state == null:
		return
	_contract_detail.hide()
	contract_requested.emit(self, state)


func _open_feature_store() -> void:
	if _run_state == null:
		return
	if _feature_store == null:
		_feature_store = FeatureStore.new()
		add_child(_feature_store)
		_feature_store.setup(_run_state)
		_feature_store.visibility_changed.connect(func():
			if not _feature_store.visible:
				%Dashboard.show()
				%FeatureStoreButton.grab_focus()
				tutorial_context_changed.emit(&"studio"))
	%SummaryPanel.hide()
	%Dashboard.hide()
	_feature_store.open_store()
	tutorial_context_changed.emit(&"feature_store")


func setup(project_state: ProjectState, run_state: RunState, snapshot_database: PrimitiveSnapshotDatabase) -> bool:
	if run_state == null or snapshot_database == null or not run_state.is_cash_initialized():
		return false
	if project_state == null and run_state.get_studio_name().is_empty():
		return false
	if project_state != null and not run_state.can_register_release(project_state):
		return false
	if _run_state != null and _run_state.calendar_changed.is_connected(_refresh_summary):
		_run_state.calendar_changed.disconnect(_refresh_summary)
	if _run_state != null and _run_state.sales_changed.is_connected(_refresh_summary):
		_run_state.sales_changed.disconnect(_refresh_summary)
	if _run_state != null and _run_state.features_changed.is_connected(_refresh_starter_hint):
		_run_state.features_changed.disconnect(_refresh_starter_hint)
	_project_state = project_state
	_run_state = run_state
	_snapshot_database = snapshot_database
	# The fully validated Studio-entry boundary is idempotent on reconstruction.
	if project_state != null and not _run_state.register_release(project_state):
		return false
	_run_state.calendar_changed.connect(_refresh_summary)
	_run_state.sales_changed.connect(_refresh_summary)
	_run_state.features_changed.connect(_refresh_starter_hint)
	if project_state != null:
		_selected_release_id = project_state.get_release_id()
	_refresh_game_list()
	_refresh_summary()
	_refresh_contract_action()
	%PublisherList.disabled = false
	%PublisherList.tooltip_text = "Browse publisher profiles and unlock requirements."
	_show_pending_publisher_notice()
	%PostGameSummaries.disabled = _run_state.get_released_game_ids().is_empty()
	%StartNextGame.text = "Produce First Game" if _run_state.get_released_game_ids().is_empty() else "Produce Next Game"
	%StartNextGame.disabled = false
	$Dashboard/Layout/Heading/Title.text = "%s — Studio" % _run_state.get_studio_name() if not _run_state.get_studio_name().is_empty() else "Studio Phase"
	_refresh_starter_hint()
	return true

func _refresh_game_list() -> void:
	if _run_state == null or not is_node_ready(): return
	var ids := _run_state.get_released_game_ids()
	%GameList.clear()
	for id: StringName in ids:
		var metadata := _run_state.get_release_metadata(id)
		var snapshot: Dictionary = metadata.get("review", {})
		%GameList.add_item("%s  ·  %d  ·  %.1f / 10" % [_run_state.get_released_game_display_name(id), metadata.get("release_year", 0), snapshot.get("final_review", 0.0)])
	if not ids.is_empty():
		if not ids.has(_selected_release_id): _selected_release_id = ids[-1]
		%GameList.select(ids.find(_selected_release_id))

func _on_game_selected(index: int) -> void:
	var ids := _run_state.get_released_game_ids()
	if index < 0 or index >= ids.size(): return
	_selected_release_id = ids[index]
	_refresh_summary()


func _refresh_contract_action() -> void:
	var state := _run_state.get_active_contract()
	if state != null:
		%Contracts.disabled = false
		%Contracts.text = "Resume Contract"
		%Contracts.tooltip_text = "Return to the active contract."
	elif _run_state.is_primitive_contract_offer_available():
		%Contracts.disabled = false
		%Contracts.text = "Contracts"
		%Contracts.tooltip_text = "Review the fixed Ironclad Primitive contract offer."
	elif _run_state.is_sidestreet_offer_available():
		%Contracts.disabled = false
		%Contracts.text = "SideStreet Offer"
		%Contracts.tooltip_text = "Review the next cash-only offer linked to a released game."
	else:
		%Contracts.disabled = true
		%Contracts.text = "Contract Completed" if _run_state.get_completed_contract_count() > 0 else "Contracts"
		%Contracts.tooltip_text = "No pending Contract offer." if _run_state.get_completed_contract_count() > 0 else "Available after the first game enters Studio."


func _refresh_summary() -> void:
	if _run_state == null or _selected_release_id.is_empty() or not is_node_ready(): return
	var metadata := _run_state.get_release_metadata(_selected_release_id)
	var snapshot: Dictionary = metadata.get("review", {})
	if snapshot.is_empty(): return
	var earned := _run_state.get_released_game_sales(_selected_release_id)
	%SummaryTitle.text = _run_state.get_released_game_display_name(_selected_release_id)
	%CalendarLabel.text = "Released in %d · Current date: %s" % [metadata.release_year, _run_state.get_calendar_label()]
	%ReviewLabel.text = "Final Review: %.1f / 10.0 · Production: %.2f · Scope: %.1f%%" % [snapshot.final_review, snapshot.production_rating, snapshot.scope_completion * 100.0]
	%AwarenessLabel.text = "Awareness: %d · Graphics %d · Sound %d · Technology %d · Design %d" % [snapshot.awareness, snapshot.cores[0], snapshot.cores[1], snapshot.cores[2], snapshot.cores[3]]
	%ProjectedUnitsLabel.text = "Projected Month 1 Units: %d" % snapshot.projected_units
	%ProjectedRevenueLabel.text = "Projected Month 1 Gross: %s · Projected Month 1 Net: %s" % [CashFormatter.format_exact_cents(snapshot.projected_gross_cents), CashFormatter.format_exact_cents(snapshot.projected_net_cents)]
	%EarnedLabel.text = "Earned: %d / 2 sales cycles, %d units · Gross: %s" % [earned.earned_cycles, earned.earned_units, CashFormatter.format_exact_cents(earned.earned_units * PrimitiveMonthOneSalesRevenueCalculator.PRICE_CENTS)]
	%EntitledLabel.text = "Earned Net Entitlement: %s" % CashFormatter.format_exact_cents(earned.entitlement_cents)
	%SettledLabel.text = "Settled Revenue: %s" % CashFormatter.format_exact_cents(earned.settled_cents)
	%UnpaidLabel.text = "Currently Unpaid: %s" % CashFormatter.format_exact_cents(earned.entitlement_cents - earned.settled_cents)
	%ExhaustionLabel.text = "Month 1 sales exhausted (2/2 cycles)" if earned.exhausted else "Month 1 sales remaining: %d cycles" % (2 - earned.earned_cycles)
	%MarketLabel.visible = not StringName(snapshot.get("forecast_id", &"")).is_empty()
	if %MarketLabel.visible:
		var forecast := _snapshot_database.get_forecast(snapshot.forecast_id)
		if forecast != null: %MarketLabel.text = "Market: %s — Launch Demand ×%s" % [forecast.get_display_name(), snapshot.forecast_multiplier]
	%RivalLabel.visible = not StringName(snapshot.get("competitor_id", &"")).is_empty()
	if %RivalLabel.visible:
		var competitor := _snapshot_database.get_competitor(snapshot.competitor_id)
		if competitor != null: %RivalLabel.text = "Rival: %s — Target Release: Cycle %d" % [competitor.get_display_name(), snapshot.competitor_target_cycle]


func get_project_state() -> ProjectState: return _project_state
func get_run_state() -> RunState: return _run_state
