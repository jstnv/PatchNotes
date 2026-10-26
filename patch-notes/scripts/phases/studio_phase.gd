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
var _monthly_report: MonthlySalesReport
var _search_work: OptionButton
var _search_action: Button
var _search_status: Label
var _search_quote: Dictionary={}
var _prepare_found: Button
var _employees_panel: EmployeePanel
var _contract_chooser: OptionButton
var _selected_contract_quote: Dictionary = {}
var _promotion_notice: Label
var _rival_world: RivalWorld
var _rival_status: Label
var _market_browser: MarketBrowser
var _market_button: Button
var _commission_mode := false
var _support_mode := false
var _checkpoint_action_waiting := false

func set_rival_world(world: RivalWorld) -> void:
	_rival_world = world
	_refresh_rivals()

func _refresh_rivals() -> void:
	if _rival_world == null or _rival_status == null: return
	var rows: Array = ["Rivals (trial) · %d live releases" % _rival_world.live_releases.size()]
	for entry: Dictionary in _rival_world.observation().studios:
		rows.append("%s: %s · %d Fans · $%d · %d live games" % [entry.name,String(entry.phase).capitalize(),entry.fans,int(int(entry.cash_cents)/100),entry.release_count])
	_rival_status.text = "\n".join(rows)


func _ready() -> void:
	resized.connect(_fit_dashboard)
	%Dashboard.visibility_changed.connect(_fit_dashboard)
	%Dashboard.minimum_size_changed.connect(_fit_dashboard)
	_fit_dashboard()
	%StartNextGame.pressed.connect(_open_predevelopment)
	_market_button = Button.new()
	_market_button.name = "MarketButton"
	_market_button.text = "Market"
	_market_button.custom_minimum_size = Vector2(270,54)
	_market_button.tooltip_text = "Browse actual player and AI releases, Reviews and sales. Opening is free."
	_market_button.pressed.connect(_open_market)
	%PostGameSummaries.get_parent().add_child(_market_button)
	%PostGameSummaries.get_parent().move_child(_market_button,1)
	%FeatureStoreButton.pressed.connect(_open_feature_store)
	%Employees.disabled = true
	%Employees.tooltip_text = "Temporarily unavailable."
	%Employees.pressed.connect(_open_employees)
	%PublisherList.pressed.connect(_open_publishers)
	%PostGameSummaries.pressed.connect(open_summary)
	%CloseSummaryButton.pressed.connect(close_summary)
	%DetailedReviewButton.pressed.connect(open_detailed_review)
	%MonthlySalesButton.pressed.connect(open_monthly_sales)
	%Contracts.pressed.connect(_open_contracts)
	%CampaignButton.pressed.connect(_purchase_selected_campaign)
	%GameList.item_selected.connect(_on_game_selected)
	%LowScopeWarning.confirmed.connect(_show_predevelopment)
	%PostGameSummaries.tooltip_text = "Browse every released game, its category Reviews, and earned versus projected sales. Opening is free."
	%FeatureStoreButton.tooltip_text = "Browse owned Features, prices and prerequisites. Opening the Store costs no cycles."
	%StartNextGame.tooltip_text = "Name the next game and choose its Genre and Theme. Opening setup is free."
	if _rival_world != null:
		_rival_status = Label.new()
		_rival_status.name = "RivalTrialStatus"
		_rival_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		$Dashboard/Layout.add_child(_rival_status)
		$Dashboard/Layout.move_child(_rival_status,2)
		_refresh_rivals()
	if _run_state != null:
		_refresh_game_list()
		_refresh_summary()
		# Launch prevalidates this scene before committing its release. Once
		# mounted, derive action availability from the committed RunState.
		_refresh_dashboard_actions()
		_show_pending_publisher_notice()


func _fit_dashboard() -> void:
	# The new phase can briefly inherit the outgoing phase's layout before the
	# host sorts it. Clear temporary minimum-size offsets after that sort.
	# A bound one-shot connection is disconnected automatically if this phase
	# exits first; a suspended coroutine would resume on a freed instance.
	if not is_inside_tree(): return
	if not get_tree().process_frame.is_connected(_apply_dashboard_fit):
		get_tree().process_frame.connect(_apply_dashboard_fit, CONNECT_ONE_SHOT)


func _apply_dashboard_fit() -> void:
	if is_inside_tree() and %Dashboard.is_visible_in_tree():
		%Dashboard.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _open_publishers() -> void:
	if _run_state == null:
		return
	if _publisher_browser == null:
		_publisher_browser = PublisherBrowser.new()
		_publisher_browser.name = "PublisherBrowser"
		add_child(_publisher_browser)
		_publisher_browser.setup(_run_state)
		_publisher_browser.commission_requested.connect(func():
			_publisher_browser.hide()
			_commission_mode = true
			_support_mode = false
			_show_predevelopment())
		_publisher_browser.support_requested.connect(func():
			_publisher_browser.hide()
			_commission_mode = false
			_support_mode = true
			_show_predevelopment())
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
	_commission_mode = false
	_support_mode = false
	if _run_state == null:
		return
	if _run_state.needs_starter_selection():
		var pool := _run_state.get_starter_pool_summary()
		if int(pool.scope) < 20:
			%LowScopeWarning.dialog_text = "Your pool has %d printed Scope. The B standard is 30 played Scope; your first game can use this smaller pool. Continue to game setup?" % pool.scope
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
	_predevelopment.market_run=_run_state
	_predevelopment.commission_mode = _commission_mode
	_predevelopment.support_mode = _support_mode
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


## Launch and history share this screen. Release registration happens before
## presentation; dismissing either mode only changes navigation.
func open_detailed_review(launch_reveal := false) -> void:
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
		_review_view.get_node("%ContinueButton").text = "Continue to Studio" if launch_reveal else "Back to Summary"
		_review_view.continue_to_studio_requested.connect(func():
			_review_view.hide()
			if launch_reveal: close_summary()
			else: open_summary())
	%Dashboard.hide()
	%SummaryPanel.hide()
	_review_view.show()
	tutorial_context_changed.emit(&"review")
	if launch_reveal: _review_view.start_launch_reveal()


func open_launch_review() -> void:
	_selected_release_id = _project_state.get_release_id()
	open_detailed_review(true)


func open_monthly_sales() -> void:
	if _selected_release_id.is_empty(): return
	if _monthly_report == null:
		_monthly_report = MonthlySalesReport.new()
		_monthly_report.name = "MonthlySalesReport"
		add_child(_monthly_report)
		_monthly_report.closed.connect(open_summary)
	_monthly_report.setup(_run_state, _selected_release_id)
	%Dashboard.hide()
	%SummaryPanel.hide()
	_monthly_report.show()


func _open_contracts(select_id: StringName = &"") -> void:
	if _run_state == null:
		return
	var active := _run_state.get_active_contract()
	if active != null:
		contract_requested.emit(self, active)
		return
	_selected_contract_offer_id = &""
	var choices := _run_state.get_pending_contract_choices()
	if choices.is_empty() and not _run_state.can_browse_contract_search(): return
	_selected_contract_offer_id = choices[0].offer_id if not choices.is_empty() else &""
	_ensure_contract_detail()
	_contract_chooser.clear()
	for choice: Dictionary in choices:
		_contract_chooser.add_item(choice.label)
		_contract_chooser.set_item_metadata(_contract_chooser.item_count-1,choice.offer_id)
	if not choices.is_empty():_contract_chooser.select(0)
	for i in range(choices.size()):
		if choices[i].offer_id==select_id:_selected_contract_offer_id=select_id;_contract_chooser.select(i)
	_contract_chooser.visible = choices.size()>1
	_configure_contract_detail()
	%SummaryPanel.hide()
	%Dashboard.hide()
	_contract_detail.show()
	tutorial_context_changed.emit(&"contract")
	(_contract_detail.find_child("CloseContractDetailButton", true, false) as Button).grab_focus()


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
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	layout.add_child(header)
	var title := Label.new()
	title.name = "ContractDetailTitle"
	title.text = "Balanced Primitive Contract"
	title.add_theme_font_size_override("font_size", 26)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var back := Button.new()
	back.name = "CloseContractDetailButton"
	back.unique_name_in_owner = true
	back.text = "Back to Studio"
	back.custom_minimum_size = Vector2(180, 46)
	back.pressed.connect(_close_contract_detail)
	header.add_child(back)
	var search_row:=HBoxContainer.new();search_row.add_theme_constant_override("separation",12);layout.add_child(search_row)
	var publisher_label:=FolderUI.label(search_row,"SideStreet · Search for work",&"SecondaryLabel")
	publisher_label.autowrap_mode=TextServer.AUTOWRAP_OFF
	publisher_label.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	_search_work=OptionButton.new();_search_work.name="ContractSearchWork";_search_work.fit_to_longest_item=false;_search_work.custom_minimum_size=Vector2(240,42);_search_work.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for entry in [["Cash Contract",&"cash"],["Reputation Brief",&"brief"],["Commissioned game · R20 + released game",&"commission"]]:
		_search_work.add_item(entry[0]);_search_work.set_item_metadata(_search_work.item_count-1,entry[1])
	_search_work.item_selected.connect(func(_index):_refresh_contract_search());search_row.add_child(_search_work)
	_search_action=FolderUI.button(search_row,"Search — 1 cycle",_search_for_contracts);_search_action.name="ContractSearchButton"
	_search_status=FolderUI.label(layout,"");_search_status.name="ContractSearchStatus"
	_prepare_found=FolderUI.button(layout,"Prepare found commission",func():
		_contract_detail.hide();_commission_mode=true;_support_mode=false;_show_predevelopment())
	_prepare_found.name="PrepareFoundCommission"
	_contract_chooser = OptionButton.new()
	_contract_chooser.name = "ContractChooser"
	_contract_chooser.custom_minimum_size.y = 44
	_contract_chooser.item_selected.connect(func(index: int):
		_selected_contract_offer_id = _contract_chooser.get_item_metadata(index)
		_configure_contract_detail())
	layout.add_child(_contract_chooser)
	# Wrapping text must not grow the full-screen panel beyond its workspace.
	# Keep both navigation and acceptance outside the scrolling description.
	var scroll := ScrollContainer.new()
	scroll.name = "ContractDetailScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	var details := Label.new()
	details.name = "ContractDetailText"
	details.text = "Publisher: Ironclad Interactive\nTwo production hands · four cards per hand\nTargets: Scope 12 · Graphics/Sound/Technology/Design 6 each\nInvestment and maximum total payout: $2,400.00\nAccept for a guaranteed %s immediately; completion pool %s pays proportionally after hand two.\nUnlocked Primitive Design and Alpha Features are finite; Core Passes are renewable.\nAcceptance costs no cycles. The contract cannot be abandoned after acceptance." % [CashFormatter.format_exact_cents(_run_state.get_ironclad_advance_cents()),CashFormatter.format_exact_cents(240000-_run_state.get_ironclad_advance_cents())]
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(details)
	var actions := HBoxContainer.new()
	layout.add_child(actions)
	var accept := Button.new()
	accept.name = "AcceptContractButton"
	accept.unique_name_in_owner = true
	accept.text = "Accept Contract"
	accept.custom_minimum_size = Vector2(200, 46)
	accept.pressed.connect(_accept_contract)
	actions.add_child(accept)


func _configure_contract_detail() -> void:
	var title := _contract_detail.find_child("ContractDetailTitle", true, false) as Label
	_refresh_contract_search()
	var accept: Button=_contract_detail.find_child("AcceptContractButton",true,false)
	accept.disabled=_selected_contract_offer_id.is_empty()
	if _selected_contract_offer_id.is_empty():
		title.text="Contract Search"
		var copy: Label=_contract_detail.find_child("ContractDetailText",true,false)
		copy.text="No pending short Contract. Browse SideStreet's work types above. A successful search finds one lasting offer and advances one normal productive cycle. Browsing is free. Rent and other bills continue. No fee, advance or standing is awarded by searching."
		if not _run_state.ContractSearch.invitation(_run_state).is_empty():copy.text+="\n\nYour found commission is ready. Prepare its name, Genre and Theme to review exact Scope and terms. Canceling preparation keeps the invitation. Begin consumes it only when successful."
		return
	var details := _contract_detail.find_child("ContractDetailText", true, false) as Label
	var brief := _run_state.get_sidestreet_brief_offer()
	if not brief.is_empty() and brief.offer_id == _selected_contract_offer_id:
		_selected_contract_quote = {}
		title.text = "SideStreet Reputation Brief"
		details.text = "Two successful hands · four cards per hand\nTargets: Scope 10 · Graphics / Sound / Technology / Design 3 each\nNo advance, cash, Promotion or Investment. Up to 10 Reputation.\nAward: 10 × the lower of completion and promise, rounded down to 0.01 Reputation. Completion uses the existing 64-unit denominator.\nPromise: finish at Scope 10 or less with no successful redraws for 100%; Scope 11 gives 50%; Scope 12+ or any successful redraw gives 0%.\nEach played hand costs one productive calendar cycle. Rent, payroll and Bank obligations continue.\nAcceptance and browsing cost no cycles. The Brief cannot be abandoned. This does not count as a completed cash Contract.\nReputation 20 unlocks an optional publisher-owned commission; access does not spend standing."
		return
	_selected_contract_quote = _run_state.get_publisher_contract_offer(_selected_contract_offer_id)
	if not _selected_contract_quote.is_empty():
		var quote := _selected_contract_quote
		var terms: Dictionary = quote.terms
		title.text = PublisherCatalog.name_for(quote.publisher_id)+" Contract"
		if quote.publisher_id==PublisherCatalog.STARWAVE:
			details.text = "Three production hands · four cards per hand\nTargets: Scope 14 · Graphics/Sound/Technology/Design 7 each\nAdvance on acceptance: $0.00\nBase maximum cash: $2,240.00, paid only after hand three. Hands one and two pay $0.00.\nCash scales with capped Scope and Core completion, rounded down to cents; no minimum completion is required.\nNo Promotion from this Contract. Existing awards are unchanged.\nYour %d owned Primitive Features and Core Passes are frozen at acceptance.\nEach hand costs one productive cycle; Feature play costs $0.\nAcceptance and browsing cost no cycles. This Contract cannot be abandoned." % quote.eligible.size()
			details.text = details.text.replace("No Promotion from this Contract. Existing awards are unchanged.", "No base Promotion. A separate challenge can award up to $100 and 4 Promotion for the next successful launch.")
			details.text += "\n" + ContractChallenges.description(PublisherTrialTerms.STARWAVE)
			return
		var focus := "Balanced Cores: each Core target 4, with an additional weakest-Core share." if quote.focus<0 else "Frozen Core focus: %s (target 9); other Core targets: 2 each." % String(PublisherTrialTerms.STATS[quote.focus]).capitalize()
		details.text = "Two production hands · four cards per hand\nScope target: %d\n%s\nAdvance on acceptance: %s\nBase maximum cash (including advance): %s\nMaximum Promotion: %d Awareness for your next successful launch.\nCash and whole Promotion are separately rounded down according to completion.\nYour %d owned Primitive Features and Core Passes are frozen at acceptance.\nEach hand costs one productive cycle; Feature play costs $0.\nAcceptance and browsing cost no cycles. This Contract cannot be abandoned." % [terms.scope,focus,CashFormatter.format_exact_cents(terms.advance_cents),CashFormatter.format_exact_cents(terms.cash_cents),terms.promotion,quote.eligible.size()]
		details.text += "\nSeparate challenge bonus: up to $100 and 4 Promotion. Base rewards stay intact.\n" + ContractChallenges.description(PublisherTrialTerms.contract_id(quote.publisher_id))
		return
	if _selected_contract_offer_id == ContractState.CONTRACT_ID:
		title.text = "Balanced Primitive Contract"
		details.text = "Publisher: Ironclad Interactive\nTwo production hands · four cards per hand\nTargets: Scope 12 · Graphics/Sound/Technology/Design 6 each\nInvestment and maximum total payout: $2,400.00\nAccept for a guaranteed %s immediately; completion pool %s pays proportionally after hand two.\nUnlocked Primitive Design and Alpha Features are finite; Core Passes are renewable.\nAcceptance costs no cycles. The contract cannot be abandoned after acceptance." % [CashFormatter.format_exact_cents(_run_state.get_ironclad_advance_cents()),CashFormatter.format_exact_cents(240000-_run_state.get_ironclad_advance_cents())]
	else:
		var offer := {}
		for release: StringName in _run_state._sidestreet_entitlements:
			if _run_state._sidestreet_entitlements[release].offer_id==_selected_contract_offer_id: offer = {"release_id":release}
		if offer.is_empty():
			details.text = "This offer is no longer available. Return to Studio and reopen Contracts."
			return
		title.text = "SideStreet Cash Contract"
		details.text = "Publisher: SideStreet Games\nOffer for: %s\nTwo production hands · four cards per hand\nTargets: Scope 12 · Graphics/Sound/Technology/Design 6 each\nBase maximum payout: $1,200.00, paid only after hand two according to completion.\nUnlocked Primitive Design and Alpha Features are finite; Core Passes are renewable.\nAcceptance costs no cash or cycles. The contract cannot be abandoned after acceptance." % ("Found by a paid search" if not _run_state.ContractSearch.source(_run_state,_selected_contract_offer_id,&"cash").is_empty() else _run_state.get_released_game_display_name(offer.release_id))
		details.text += "\nSeparate challenge bonus: up to $100 and 4 Promotion. Base payout stays intact.\n" + ContractChallenges.description(ContractDefinitions.SIDESTREET)


func _close_contract_detail() -> void:
	if _contract_detail != null:
		_contract_detail.hide()
	%Dashboard.show()
	%Contracts.grab_focus()
	tutorial_context_changed.emit(&"studio")


func _accept_contract() -> void:
	if _checkpoint_action_waiting: return
	var gate:=preload("res://scripts/persistence/checkpoint_ui_gate.gd")
	if gate.needs_wait(_run_state):
		_checkpoint_action_waiting=true
		var selected:=_selected_contract_offer_id
		var saved: bool=await gate.wait_saved(_run_state)
		_checkpoint_action_waiting=false
		if not saved or not _contract_detail.visible or selected!=_selected_contract_offer_id: return
	var state: ContractState
	var brief := _run_state.get_sidestreet_brief_offer()
	if not brief.is_empty() and brief.offer_id == _selected_contract_offer_id: state = _run_state.accept_sidestreet_brief(_selected_contract_offer_id)
	elif not _selected_contract_quote.is_empty(): state = _run_state.accept_publisher_contract(_selected_contract_quote)
	else: state = _run_state.accept_primitive_contract() if _selected_contract_offer_id == ContractState.CONTRACT_ID else _run_state.accept_sidestreet_offer(_selected_contract_offer_id)
	if state == null:
		_configure_contract_detail()
		return
	_contract_detail.hide()
	contract_requested.emit(self, state)


func _open_market() -> void:
	if _run_state == null: return
	if _market_browser == null:
		_market_browser = MarketBrowser.new()
		add_child(_market_browser)
		_market_browser.closed.connect(func():
			%Dashboard.show()
			_market_button.grab_focus()
			tutorial_context_changed.emit(&"studio"))
	%Dashboard.hide()
	%SummaryPanel.hide()
	_market_browser.open(_run_state,_rival_world)
	tutorial_context_changed.emit(&"market")


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


func setup(project_state: ProjectState, run_state: RunState, snapshot_database: PrimitiveSnapshotDatabase, prepare_only: bool = false) -> bool:
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
	if _run_state != null and _run_state.calendar_changed.is_connected(_refresh_rivals):
		_run_state.calendar_changed.disconnect(_refresh_rivals)
	_project_state = project_state
	_run_state = run_state
	_snapshot_database = snapshot_database
	# The fully validated Studio-entry boundary is idempotent on reconstruction.
	if project_state != null and not prepare_only and not _run_state.register_release(project_state):
		return false
	_run_state.calendar_changed.connect(_refresh_summary)
	_run_state.calendar_changed.connect(_refresh_rivals)
	_run_state.sales_changed.connect(_refresh_summary)
	if project_state != null:
		_selected_release_id = project_state.get_release_id()
	_refresh_game_list()
	_refresh_summary()
	_refresh_rivals()
	_refresh_dashboard_actions()
	%PublisherList.disabled = false
	%PublisherList.tooltip_text = "Browse publisher profiles and unlock requirements."
	_show_pending_publisher_notice()
	return true

func _refresh_dashboard_actions() -> void:
	if _run_state == null: return
	_refresh_contract_action()
	var has_releases := not _run_state.get_released_game_ids().is_empty()
	%PostGameSummaries.disabled = not has_releases
	%StartNextGame.text = "Produce Next Game" if has_releases else "Produce First Game"
	%StartNextGame.disabled = false

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


func _purchase_selected_campaign() -> void:
	if _run_state == null or _selected_release_id.is_empty():
		return
	var expected_cycle := _run_state.get_completed_run_cycles()
	if not _run_state.purchase_post_launch_campaign(_selected_release_id, expected_cycle):
		%CampaignStatusLabel.text = "Campaign unavailable. Check its timing and cash before trying again."
		return
	_refresh_summary()


func _refresh_contract_action() -> void:
	if _promotion_notice==null:
		_promotion_notice = Label.new()
		_promotion_notice.hide()
		_promotion_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		$Dashboard/Layout.add_child(_promotion_notice)
		$Dashboard/Layout.move_child(_promotion_notice,1)
	_promotion_notice.text = "Banked Promotion: %d Awareness for your next successful launch" % _run_state.get_pending_promotion()
	_promotion_notice.visible = _run_state.get_pending_promotion()>0
	var state := _run_state.get_active_contract()
	if state != null:
		%Contracts.disabled = false
		%Contracts.text = "Resume Contract"
		%Contracts.tooltip_text = "Return to the active contract."
	elif _run_state.is_primitive_contract_offer_available():
		%Contracts.disabled = false
		%Contracts.text = "Contracts"
		%Contracts.tooltip_text = "Review the fixed Ironclad Primitive contract offer."
	elif not _run_state.get_pending_contract_choices().is_empty() or _run_state.can_browse_contract_search():
		%Contracts.disabled = false
		%Contracts.text = "Contracts"
		%Contracts.tooltip_text = "Review your available publisher contract offers."
	else:
		%Contracts.disabled = true
		%Contracts.text = "Contract Completed" if _run_state.get_completed_contract_count() > 0 else "Contracts"
		%Contracts.tooltip_text = "No pending Contract offer." if _run_state.get_completed_contract_count() > 0 else "Available after the first game enters Studio."


func _refresh_summary() -> void:
	if _run_state == null or not is_node_ready(): return
	var studio_title := "%s — Studio" % _run_state.get_studio_name() if not _run_state.get_studio_name().is_empty() else "Studio Phase"
	$Dashboard/Layout/Heading/Title.text = "%s · %d" % [studio_title, _run_state.get_current_year()]
	$Dashboard/Layout/StudioIdentity.text = "Genre specialty: %s\n%s" % [String(_run_state.get_studio_specialty()).capitalize(), StudioTraits.summary(_run_state.get_studio_traits())]
	if _selected_release_id.is_empty(): return
	var metadata := _run_state.get_release_metadata(_selected_release_id)
	var snapshot: Dictionary = metadata.get("review", {})
	if snapshot.is_empty(): return
	var earned := _run_state.get_released_game_sales(_selected_release_id)
	%SummaryTitle.text = _run_state.get_released_game_display_name(_selected_release_id)
	%CalendarLabel.text = "Released in %d · Current date: %s" % [metadata.release_year, _run_state.get_calendar_label()]
	%ReviewLabel.text = "Final Review: %.1f / 10.0 · Production: %.2f · Scope: %.1f%%" % [snapshot.final_review, snapshot.production_rating, snapshot.scope_completion * 100.0]
	var commission_text := preload("res://scripts/contracts/commission_presentation.gd").result_text(_run_state,_selected_release_id)
	if not commission_text.is_empty(): %ReviewLabel.text += "\n"+commission_text
	%AwarenessLabel.text = "Awareness: %d · Graphics %d · Sound %d · Technology %d · Design %d" % [snapshot.awareness, snapshot.cores[0], snapshot.cores[1], snapshot.cores[2], snapshot.cores[3]]
	%ProjectedUnitsLabel.text = "Projected Month 1 Units: %d" % snapshot.projected_units
	%ProjectedRevenueLabel.text = "Projected Month 1 Gross: %s · Projected Month 1 Net: %s" % [CashFormatter.format_exact_cents(snapshot.projected_gross_cents), CashFormatter.format_exact_cents(snapshot.projected_net_cents)]
	%EarnedLabel.text = "Earned: %d / 2 Month 1 cycles · Lifetime %d units · Gross: %s" % [earned.earned_cycles, earned.earned_units, CashFormatter.format_exact_cents(earned.earned_units * PrimitiveMonthOneSalesRevenueCalculator.PRICE_CENTS)]
	%EntitledLabel.text = "Earned Net Entitlement: %s" % CashFormatter.format_exact_cents(earned.entitlement_cents)
	%SettledLabel.text = "Settled Revenue: %s" % CashFormatter.format_exact_cents(earned.settled_cents)
	%UnpaidLabel.text = "Currently Unpaid: %s" % CashFormatter.format_exact_cents(earned.entitlement_cents - earned.settled_cents)
	if metadata.get("owner",&"studio") == &"publisher":
		%ProjectedRevenueLabel.text += " (raw title forecast; publisher owns revenue)"
		%EntitledLabel.text = "Raw title net: %s · Studio entitlement: $0.00" % CashFormatter.format_exact_cents(earned.entitlement_cents)
		%SettledLabel.text = "Raw title settled: %s · Studio sales paid: $0.00" % CashFormatter.format_exact_cents(earned.settled_cents)
		%UnpaidLabel.text = "Studio unpaid sales: $0.00"
	elif _run_state._support_rights.has(_selected_release_id):
		var rights: Dictionary = _run_state._support_rights[_selected_release_id]
		%EntitledLabel.text = "Raw title net: %s · Studio entitlement after recoup: %s" % [CashFormatter.format_exact_cents(earned.entitlement_cents),CashFormatter.format_exact_cents(rights.studio_earned_cents)]
		%SettledLabel.text = "Studio sales paid: %s" % CashFormatter.format_exact_cents(rights.studio_settled_cents)
		%UnpaidLabel.text = "Studio unpaid sales: %s" % CashFormatter.format_exact_cents(rights.studio_earned_cents-rights.studio_settled_cents)
	%ExhaustionLabel.text = "Month 1 sales complete (2/2 cycles); later sales continue" if earned.exhausted else "Month 1 sales remaining: %d cycles" % (2 - earned.earned_cycles)
	var later := ReleasedGameSales.get_projection(earned)
	var offer := _run_state.get_post_launch_campaign_offer(_selected_release_id)
	%CurrentAgeLabel.text = "Next sales: release-age Month %d, cycle %d of 2" % [later.get("next_age_month", 1), later.get("next_age_cycle", 1)]
	if int(later.get("next_age_month", 1)) == 1:
		%OrganicAwarenessLabel.text = "Organic Awareness begins in release-age Month 2."
		%LaterProjectedUnitsLabel.text = "Month 1 forecast: %d units across two earning cycles" % int(later.get("projected_month_units", 0))
	else:
		%OrganicAwarenessLabel.text = "Organic Awareness: %.4f" % (float(later.get("organic_awareness_scaled", 0)) / 10000.0)
		%LaterProjectedUnitsLabel.text = "Projected units this release-age month: %d organic" % int(later.get("projected_month_units", 0))
		if offer.get("eligible", false):
			%LaterProjectedUnitsLabel.text += " · %d with campaign" % int(later.get("campaign_projected_month_units", 0))
	%LaterProjectedUnitsLabel.text += "\nNew age months are before future market crowding; existing halves retain their factor."
	%CampaignButton.disabled = not offer.get("can_purchase", false)
	if not offer.get("eligible", false):
		%CampaignStatusLabel.text = "Campaigns open only at the first sales cycle of this game's Month 2 or later."
	elif not offer.get("affordable", false):
		%CampaignStatusLabel.text = "Need $100.00 cash before the next sales cycle."
	elif not offer.get("can_purchase", false):
		%CampaignStatusLabel.text = "Campaign unavailable while the next sales/settlement transaction cannot complete."
	else:
		%CampaignStatusLabel.text = "One release-age month only · $100.00 · one productive cycle · no stacking."
	if metadata.get("owner",&"studio") == &"publisher": %CampaignStatusLabel.text = "Publisher-owned commission: no Studio post-launch campaign spending."
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

func get_predevelopment_priorities() -> Dictionary:
	return _predevelopment.get_initial_priorities() if _predevelopment != null and _predevelopment.visible else {}

func get_predevelopment_commission_quote() -> Dictionary:
	return _predevelopment.get_confirmed_commission_quote() if _predevelopment != null and _predevelopment.visible else {}

func get_predevelopment_support_quote() -> Dictionary:
	return _predevelopment.get_confirmed_support_quote() if _predevelopment != null and _predevelopment.visible else {}


func _open_employees() -> void:
	if _run_state == null: return
	if _employees_panel == null:
		_employees_panel = EmployeePanel.new()
		add_child(_employees_panel)
	_employees_panel.open_for(_run_state)

func _refresh_contract_search() -> void:
	if _search_work==null or _run_state==null:return
	var work: StringName=_search_work.get_selected_metadata()
	_search_quote=_run_state.get_contract_search_quote(&"sidestreet",work)
	_search_action.disabled=_search_quote.is_empty()
	var standing:=_run_state.get_publisher_relationships()
	var reputation: int=standing.get(&"sidestreet",{}).get("reputation_bp",0)
	var blocker:=_run_state.contract_search_blocker(&"sidestreet",work)
	_search_status.text="Reputation %.2f · %s"%[reputation/100.0,blocker if not blocker.is_empty() else "One durable offer · no cash fee · ordinary bills and sales advance"]
	_prepare_found.visible=not _run_state.ContractSearch.invitation(_run_state).is_empty()

func _search_for_contracts() -> void:
	if _checkpoint_action_waiting: return
	var gate:=preload("res://scripts/persistence/checkpoint_ui_gate.gd")
	if gate.needs_wait(_run_state):
		_checkpoint_action_waiting=true
		var quote:=_search_quote.duplicate(true)
		var saved: bool=await gate.wait_saved(_run_state)
		_checkpoint_action_waiting=false
		if not saved or not _contract_detail.visible or quote!=_search_quote: return
	var result: Dictionary=preload("res://scripts/simulation/studio_actions.gd").execute(_run_state,&"search_contracts",{"quote":_search_quote.duplicate(true)},true)
	if not result.ok:
		_refresh_contract_search();return
	var id: StringName=_run_state.get_contract_search_state().receipts[-1].offer_id
	_open_contracts(id)
