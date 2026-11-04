class_name StudioPhase
extends Control
const Clock := preload("res://scripts/calendar/calendar_clock.gd")
const HUB_GROUPS := [&"studio_info", &"management", &"market", &"production"]

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
var _menu_panels: Dictionary={}
var _menu_buttons: Dictionary={}
var _active_menu: StringName=&""
var _rival_info: Control
var _studio_info: Control
var _management_panel: Control
var _engine_browser: Control
var _contract_engine_picker: VBoxContainer
var _management_button: Button
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
var _run_refresh_pending := false
var _hub: Control
var _hub_motion: MenuTransitions
var _returning_destination := false
var _destination_layer: CanvasLayer
var _destination_fits: Array[Dictionary]=[]

func set_rival_world(world: RivalWorld) -> void:
	_rival_world = world
	_refresh_rivals()

func get_live_rival_rows() -> Array:
	return preload("res://scripts/ui/studio_rival_info.gd").rows(_rival_world)

func _refresh_rivals() -> void:
	if is_instance_valid(_rival_info) and _rival_info.visible:_rival_info.open(_rival_world)


func _ready() -> void:
	FolderUI.enable_menu_gamepad()
	theme=preload("res://resources/ui/onyx_theme.tres")
	resized.connect(_fit_dashboard)
	%Dashboard.visibility_changed.connect(_dashboard_visibility_changed)
	%Dashboard.minimum_size_changed.connect(_fit_dashboard)
	_fit_dashboard()
	%StartNextGame.pressed.connect(_open_predevelopment)
	_market_button = Button.new()
	_market_button.name = "MarketButton"
	_market_button.text = "Daily Chart"
	_market_button.custom_minimum_size = Vector2(270,54)
	_market_button.tooltip_text = "Browse actual player and AI releases, Reviews and sales. Opening is free."
	_market_button.pressed.connect(_open_market)
	%PostGameSummaries.get_parent().add_child(_market_button)
	%PostGameSummaries.get_parent().move_child(_market_button,1)
	%FeatureStoreButton.hide()
	%Employees.disabled = true
	%Employees.tooltip_text = "Unlocks after releasing 2 games."
	%Employees.pressed.connect(_open_employees)
	_build_management_menu()
	%PublisherList.pressed.connect(_open_publishers)
	%PostGameSummaries.pressed.connect(open_summary)
	%CloseSummaryButton.pressed.connect(close_summary)
	FolderUI.standard_back(%CloseSummaryButton)
	%SummaryPanel.get_node("Margin").add_theme_constant_override("margin_top",20)
	%DetailedReviewButton.pressed.connect(open_detailed_review)
	%MonthlySalesButton.pressed.connect(open_monthly_sales)
	%Contracts.pressed.connect(_open_contracts)
	%CampaignButton.pressed.connect(_purchase_selected_campaign)
	%GameList.item_selected.connect(_on_game_selected)
	%PostGameSummaries.tooltip_text = "Browse every released game, its category Reviews, and earned versus projected sales. Opening is free."
	%StartNextGame.tooltip_text = "Name the next game and choose its Genre and Theme. Opening setup is free."
	if _run_state != null:
		_refresh_game_list()
		_refresh_summary()
		# Launch prevalidates this scene before committing its release. Once
		# mounted, derive action availability from the committed RunState.
		_refresh_dashboard_actions()
		_show_pending_publisher_notice()


func _menu_button(parent: Node,label: String,key: String,callback: Callable) -> Button:
	var button:=FolderUI.button(parent,label,callback);button.name=key
	button.custom_minimum_size=Vector2(310,54);button.owner=self;button.unique_name_in_owner=true
	return button

func _menu_page(key: StringName,title: String) -> VBoxContainer:
	var page:=Control.new();page.name=title.replace(" ","");add_child(page)
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);page.add_to_group(PauseMenu.CANCEL_OWNER_GROUP)
	var host:=FolderUI.SurfaceHost.new();page.add_child(host);host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var surface:=FolderUI.surface(host);surface.set_meta("bounded_folder",true)
	var layout:=VBoxContainer.new();layout.add_theme_constant_override("separation",12);surface.add_child(layout)
	FolderUI.header(layout,title,"",_close_menu.bind(key))
	var center:=CenterContainer.new();center.size_flags_vertical=Control.SIZE_EXPAND_FILL;layout.add_child(center)
	var choices:=VBoxContainer.new();choices.add_theme_constant_override("separation",12);center.add_child(choices)
	_menu_panels[key]=page;page.hide();return choices

func _build_management_menu() -> void:
	_hub_motion=MenuTransitions.new();_hub_motion.name="StudioNavigation";_hub_motion.automatic_entrances=false;add_child(_hub_motion)
	_hub=preload("res://scripts/ui/studio_hub.gd").new();_hub.motion=_hub_motion;%Dashboard.add_child(_hub)
	var studio_info: VBoxContainer=_hub.add_group(&"studio_info","Studio Info")
	var management: VBoxContainer=_hub.add_group(&"management","Studio Management")
	var market: VBoxContainer=_hub.add_group(&"market","Market Info")
	var production: VBoxContainer=_hub.add_group(&"production","Start Production")
	_menu_panels[&"studio_info"]=studio_info;_menu_panels[&"market"]=market;_menu_panels[&"management"]=management;_menu_panels[&"production"]=production
	for entry in [[&"studio_info","StudioInfoMenuButton"],[&"management","StudioManagementButton"],[&"market","MarketInfoButton"],[&"production","StartProductionButton"]]:
		var button: Button=_hub.root_buttons[entry[0]];button.name=entry[1];button.owner=self;button.unique_name_in_owner=true;_menu_buttons[entry[0]]=button
	_management_button=_menu_buttons[&"management"];_management_panel=management
	_hub.selection_changed.connect(func(id: StringName):_active_menu=id;_refresh_dashboard_actions();tutorial_context_changed.emit(&"studio"))
	_market_button.reparent(market,false);%PublisherList.reparent(market,false)
	_menu_button(market,"Rival Info","RivalInfoButton",_open_rival_info)
	%Employees.reparent(management,false)
	_menu_button(management,"Engines","StudioEnginesButton",_open_engines)
	_menu_button(studio_info,"Studio Info","StudioInfoButton",_open_studio_info)
	%PostGameSummaries.reparent(studio_info,false)
	_menu_button(studio_info,"Bank","StudioBankButton",_open_bank)
	%StartNextGame.reparent(production,false);%Contracts.reparent(production,false)
	$Dashboard/Layout.hide()
	_hub_motion.set_root(%Dashboard)

func _hide_menu_pages() -> void:
	for key: StringName in _menu_panels:
		if key not in HUB_GROUPS:_menu_panels[key].hide()

func _show_group(key: StringName,focus: Control=null) -> void:
	%SummaryPanel.hide();%Dashboard.show();_active_menu=key
	_refresh_dashboard_actions();_hub.select_group(key,focus)
	tutorial_context_changed.emit(&"studio")

func _open_menu(key: StringName,focus: Control=null) -> void:
	if _run_state==null or _returning_destination:return
	if _hub_motion.depth()>1:
		if _hub_motion.busy:return
		_returning_destination=true
		if is_instance_valid(_destination_layer):_destination_layer.show()
		_hub_motion.pop();return
	_show_group(key,focus)

func _present_destination(view: Control,focus: Control=null,layer: CanvasLayer=null) -> void:
	if _hub_motion.busy:return
	if _hub_motion.is_top(view):return
	for frame: Dictionary in _hub_motion.frames:
		if frame.view.get_ref()==view:
			_returning_destination=true;_hub_motion.pop();return
	_hub.settle_motion()
	_destination_layer=layer
	var previous: Control=_hub_motion.frames[-1].view.get_ref()
	if is_instance_valid(previous):previous.show()
	var invoking: Control=_destination_invoker(view)
	if is_instance_valid(invoking) and invoking.is_visible_in_tree():invoking.grab_focus()
	view.set_meta("folder_navigation_managed",true)
	if view==_review_view:
		var layout: VBoxContainer=view.get_node("Margin/Layout")
		var title: Control=layout.get_node_or_null("Title")
		if title!=null:
			var header:=HBoxContainer.new();layout.add_child(header);layout.move_child(header,0);title.reparent(header,false)
			view.get_node("%ContinueButton").reparent(header,false)
			FolderUI.standard_back(view.get_node("%ContinueButton"))
			view.get_node("Margin").add_theme_constant_override("margin_top",28)
			view.get_node("Margin").add_theme_constant_override("margin_left",32)
			view.get_node("Margin").add_theme_constant_override("margin_right",32)
	var group: StringName=_active_menu if _active_menu in HUB_GROUPS else &"production"
	_destination_layer=layer
	var layer_ref: WeakRef=weakref(layer) if is_instance_valid(layer) else null
	var view_ref: WeakRef=weakref(view)
	var closed:=func():
		var current_layer: CanvasLayer=layer_ref.get_ref() if layer_ref!=null else null
		var current_view: Control=view_ref.get_ref()
		if is_instance_valid(current_layer):current_layer.hide()
		if is_instance_valid(current_view):current_view.remove_meta("folder_navigation_managed")
		_destination_layer=null;_returning_destination=false
		if _hub_motion.depth()==1:_show_group(group)
	if view.get_parent()==self:
		var fit_callback:=_queue_destination_fit.bind(view)
		if not view.minimum_size_changed.is_connected(fit_callback):view.minimum_size_changed.connect(fit_callback)
		_queue_destination_fit(view)
	_hub_motion.push_from_bottom(view,focus,closed,get_global_rect().end.y)

func _destination_invoker(view: Control) -> Control:
	for pair in [[_engine_browser,get_node_or_null("%StudioEnginesButton")],[_feature_store,get_node_or_null("%StudioEnginesButton")],[_employees_panel,%Employees],[_rival_info,get_node_or_null("%RivalInfoButton")],[_studio_info,get_node_or_null("%StudioInfoButton")],[_market_browser,_market_button],[_publisher_browser,%PublisherList],[_predevelopment,%StartNextGame],[_contract_detail,%Contracts],[%SummaryPanel,%PostGameSummaries],[_review_view,%DetailedReviewButton],[_monthly_report,%MonthlySalesButton]]:
		if pair[0]==view:return pair[1]
	return get_node_or_null("%StudioBankButton") if is_instance_valid(_destination_layer) else null

func _close_menu(key: StringName) -> void:
	if key==&"info":_open_menu(&"studio_info",get_node("%StudioInfoButton"));return
	if key==&"engines":_open_management(get_node("%StudioEnginesButton"));return
	if _hub_motion.depth()>1:_open_menu(key);return
	_hub.close_group();_menu_buttons[key].grab_focus()
	tutorial_context_changed.emit(&"studio")

func _open_management(focus: Control=null) -> void:_open_menu(&"management",focus)
func _close_management() -> void:_close_menu(&"management")

func _open_rival_info() -> void:
	if _rival_info==null:
		_rival_info=preload("res://scripts/ui/studio_rival_info.gd").new();add_child(_rival_info)
		_rival_info.name="RivalInfo";_rival_info.closed.connect(func():_open_menu(&"market",get_node("%RivalInfoButton")))
	_hide_menu_pages();_rival_info.open(_rival_world);_present_destination(_rival_info)

func _open_studio_info() -> void:
	if _studio_info==null:
		var choices:=_menu_page(&"info","Studio Info");_studio_info=_menu_panels[&"info"]
		var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(520,280)
		choices.get_parent().add_child(scroll);choices.reparent(scroll,false)
		choices.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		FolderUI.label(choices,_run_state.get_studio_name(),&"HeadingLabel")
		FolderUI.label(choices,"Genre specialty: "+String(_run_state.get_studio_specialty()).capitalize())
		FolderUI.label(choices,StudioTraits.summary(_run_state.get_studio_traits()))
	_hide_menu_pages();_studio_info.show();_present_destination(_studio_info,_studio_info.find_child("Back",true,false))

func _open_engines(detail_id: StringName=&"") -> void:
	if _engine_browser==null:
		_engine_browser=preload("res://scripts/ui/engine_market_browser.gd").new()
		add_child(_engine_browser);_menu_panels[&"engines"]=_engine_browser
		_engine_browser.closed.connect(_close_menu.bind(&"engines"))
		_engine_browser.configure_requested.connect(_open_feature_store)
	_hide_menu_pages();%Dashboard.hide();%SummaryPanel.hide();
	_engine_browser.open(_run_state,_rival_world,detail_id)
	_present_destination(_engine_browser,_engine_browser.find_child("Back",true,false))
	tutorial_context_changed.emit(&"studio")

func _open_bank() -> void:
	var ancestor: Node=get_parent()
	while ancestor!=null:
		var hud:=ancestor.get_node_or_null("%GameplayHUD") as GameplayHUD
		if hud!=null:
			if not hud.studio_finances.closed.is_connected(_bank_closed):hud.studio_finances.closed.connect(_bank_closed)
			if hud.show_bank_from_studio():_present_destination(hud.studio_finances.dialog,hud.studio_finances.back_button,hud.studio_finances)
			return
		ancestor=ancestor.get_parent()

func _bank_closed() -> void:
	if is_instance_valid(_destination_layer):_open_menu(&"studio_info",get_node("%StudioBankButton"))

func _unhandled_input(event: InputEvent) -> void:
	if not MenuTransitions.cancel_pressed(event):return
	if _hub_motion.busy or _returning_destination:get_viewport().set_input_as_handled();return
	if _hub_motion.depth()>1:
		_open_menu(_active_menu);get_viewport().set_input_as_handled();return
	if not _hub.selected.is_empty():
		_close_menu(_hub.selected);get_viewport().set_input_as_handled()


func _fit_dashboard() -> void:
	# The new phase can briefly inherit the outgoing phase's layout before the
	# host sorts it. Clear temporary minimum-size offsets after that sort.
	# A bound one-shot connection is disconnected automatically if this phase
	# exits first; a suspended coroutine would resume on a freed instance.
	if not is_inside_tree(): return
	if not get_tree().process_frame.is_connected(_apply_dashboard_fit):
		get_tree().process_frame.connect(_apply_dashboard_fit, CONNECT_ONE_SHOT)


func _dashboard_visibility_changed() -> void:
	_fit_dashboard()
	if is_inside_tree() and %Dashboard.is_visible_in_tree():
		_refresh_summary()
		_refresh_rivals()


func _queue_run_refresh() -> void:
	if _run_refresh_pending or not is_inside_tree():return
	_run_refresh_pending=true
	_flush_run_refresh.call_deferred()


func _flush_run_refresh() -> void:
	_run_refresh_pending=false
	if not is_inside_tree():return
	# Store/Employees/Bank browsing does not need hidden review forecasts.
	# Opening Summary and returning to Dashboard explicitly refresh current data.
	if %Dashboard.is_visible_in_tree() or %SummaryPanel.is_visible_in_tree():_refresh_summary()
	if %Dashboard.is_visible_in_tree() or (is_instance_valid(_rival_info) and _rival_info.visible):_refresh_rivals()


func _apply_dashboard_fit() -> void:
	if is_inside_tree() and %Dashboard.is_visible_in_tree():
		%Dashboard.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _open_publishers() -> void:
	_hide_menu_pages()
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
			_open_menu(&"market",%PublisherList)
			tutorial_context_changed.emit(&"studio"))
	%SummaryPanel.hide()
	%Dashboard.hide()
	_publisher_browser.open_browser()
	_present_destination(_publisher_browser)
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
		# Keep the unlock notice available even when no companion is selected.
		_hub.notice_host.add_child(_publisher_notice)
		_publisher_notice.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
		_publisher_notice.offset_left=12;_publisher_notice.offset_right=312
		_publisher_notice.offset_top=-112;_publisher_notice.offset_bottom=-12
		_publisher_notice.grow_vertical=Control.GROW_DIRECTION_BEGIN
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
	# The small starter pool is intentional; planning is free. Keep the hidden
	# legacy warning node for capture scripts, without an active modal path.
	_show_predevelopment()


func _show_predevelopment() -> void:
	_hide_menu_pages()
	if _predevelopment == null:
		_predevelopment = PredevelopmentOverlay.new()
		_predevelopment.name = "Predevelopment"
		add_child(_predevelopment)
		_predevelopment.begin_requested.connect(func(base_name: String, genre: StringName, theme_id: StringName):
			development_requested.emit(self, base_name, genre, theme_id))
		_predevelopment.cancelled.connect(func():
			_predevelopment.hide()
			_open_menu(_active_menu if not _active_menu.is_empty() else &"production",%StartNextGame if _active_menu!=&"market" else %PublisherList)
			tutorial_context_changed.emit(&"studio"))
	%SummaryPanel.hide()
	%Dashboard.hide()
	_predevelopment.market_run=_run_state
	_predevelopment.commission_mode = _commission_mode
	_predevelopment.support_mode = _support_mode
	_predevelopment.open()
	_present_destination(_predevelopment,_predevelopment.name_input)
	tutorial_context_changed.emit(&"predevelopment")


func show_development_error(message: String) -> void:
	if _predevelopment != null:
		_predevelopment.error_label.text = message


func open_summary() -> void:
	_hide_menu_pages()
	if _run_state == null or _run_state.get_released_game_ids().is_empty(): return
	_refresh_game_list()
	_refresh_summary()
	%Dashboard.hide()
	%SummaryPanel.show()
	_present_destination(%SummaryPanel,%CloseSummaryButton)
	tutorial_context_changed.emit(&"studio")


func close_summary(to_dashboard := false) -> void:
	%SummaryPanel.hide()
	if to_dashboard:
		_open_menu(&"production",_menu_buttons[&"production"])
	else:
		_open_menu(&"studio_info",%PostGameSummaries)
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
			if launch_reveal: close_summary(true)
			else: open_summary())
	%Dashboard.hide()
	%SummaryPanel.hide()
	_review_view.show()
	_present_destination(_review_view,_review_view.get_node("%ContinueButton"))
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
	_present_destination(_monthly_report)


func _open_contracts(select_id: StringName = &"",preview_only: bool=false) -> void:
	_hide_menu_pages()
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
	_configure_contract_detail(preview_only)
	%SummaryPanel.hide()
	%Dashboard.hide()
	_contract_detail.show()
	tutorial_context_changed.emit(&"contract")
	_present_destination(_contract_detail,_contract_detail.find_child("CloseContractDetailButton",true,false))


func _ensure_contract_detail() -> void:
	if _contract_detail != null:
		return
	_contract_detail = PanelContainer.new()
	_contract_detail.name = "ContractDetail"
	_contract_detail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_contract_detail)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
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
	title.theme_type_variation=&"HeadingLabel"
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
	FolderUI.standard_back(back)
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
	_contract_engine_picker=preload("res://scripts/ui/engine_picker.gd").new()
	layout.add_child(_contract_engine_picker)
	_contract_engine_picker.selection_changed.connect(func(_id: StringName):
		_selected_contract_quote={};_configure_contract_detail())
	# Wrapping text must not grow the full-screen panel beyond its workspace.
	# Keep both navigation and acceptance outside the scrolling description.
	var scroll := ScrollContainer.new()
	scroll.name = "ContractDetailScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	var details := Label.new()
	details.name = "ContractDetailText"
	details.text = "Publisher: Ironclad Interactive\nTwo production hands · one to four cards per hand\nTargets: Scope 12 · Graphics/Sound/Technology/Design 6 each\nInvestment and maximum total payout: $2,400.00\nAccept for a guaranteed %s immediately; completion pool %s pays proportionally after hand two.\nUnlocked Primitive Design and Alpha Features are finite; Core Passes are renewable.\nAcceptance costs no cycles. The contract cannot be abandoned after acceptance." % [CashFormatter.format_exact_cents(_run_state.get_ironclad_advance_cents()),CashFormatter.format_exact_cents(240000-_run_state.get_ironclad_advance_cents())]
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


func _configure_contract_detail(preview_only: bool=false) -> void:
	_contract_engine_picker.bind(_run_state)
	var title := _contract_detail.find_child("ContractDetailTitle", true, false) as Label
	if preview_only:
		_search_quote={};_search_action.disabled=true;_prepare_found.hide()
		_search_status.text="Tour preview: searching advances one productive cycle. No search is performed during this tour."
	else:_refresh_contract_search()
	var accept: Button=_contract_detail.find_child("AcceptContractButton",true,false)
	accept.disabled=preview_only or _selected_contract_offer_id.is_empty()
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
		details.text = "Two successful hands · one to four cards per hand\nTargets: Scope 10 · Graphics / Sound / Technology / Design 3 each\nNo advance, cash, Promotion or Investment. Up to 10 Reputation.\nAward: 10 × the lower of completion and promise, rounded down to 0.01 Reputation. Completion uses the existing 64-unit denominator.\nPromise: finish at Scope 10 or less with no successful redraws for 100%; Scope 11 gives 50%; Scope 12+ or any successful redraw gives 0%.\nEach played hand costs one productive calendar cycle. Rent, payroll and Bank obligations continue.\nAcceptance and browsing cost no cycles. The Brief cannot be abandoned. This does not count as a completed cash Contract.\nReputation 20 unlocks an optional publisher-owned commission; access does not spend standing."
		return
	_selected_contract_quote = _run_state.get_publisher_contract_offer(_selected_contract_offer_id)
	if not _selected_contract_quote.is_empty():
		var quote := _selected_contract_quote
		var terms: Dictionary = quote.terms
		title.text = PublisherCatalog.name_for(quote.publisher_id)+" Contract"
		if quote.publisher_id==PublisherCatalog.STARWAVE:
			details.text = "Three production hands · one to four cards per hand\nTargets: Scope 14 · Graphics/Sound/Technology/Design 7 each\nAdvance on acceptance: $0.00\nBase maximum cash: $2,240.00, paid only after hand three. Hands one and two pay $0.00.\nCash scales with capped Scope and Core completion, rounded down to cents; no minimum completion is required.\nNo Promotion from this Contract. Existing awards are unchanged.\nYour %d owned Primitive Features and Core Passes are frozen at acceptance.\nEach hand costs one productive cycle; Feature play costs $0.\nAcceptance and browsing cost no cycles. This Contract cannot be abandoned." % quote.eligible.size()
			details.text = details.text.replace("No Promotion from this Contract. Existing awards are unchanged.", "No base Promotion. A separate challenge can award up to $100 and 4 Promotion for the next successful launch.")
			details.text += "\n" + ContractChallenges.description(PublisherTrialTerms.STARWAVE)
			return
		var focus := "Balanced Cores: each Core target 4, with an additional weakest-Core share." if quote.focus<0 else "Frozen Core focus: %s (target 9); other Core targets: 2 each." % String(PublisherTrialTerms.STATS[quote.focus]).capitalize()
		details.text = "Two production hands · one to four cards per hand\nScope target: %d\n%s\nAdvance on acceptance: %s\nBase maximum cash (including advance): %s\nMaximum Promotion: %d Awareness for your next successful launch.\nCash and whole Promotion are separately rounded down according to completion.\nYour %d owned Primitive Features and Core Passes are frozen at acceptance.\nEach hand costs one productive cycle; Feature play costs $0.\nAcceptance and browsing cost no cycles. This Contract cannot be abandoned." % [terms.scope,focus,CashFormatter.format_exact_cents(terms.advance_cents),CashFormatter.format_exact_cents(terms.cash_cents),terms.promotion,quote.eligible.size()]
		details.text += "\nSeparate challenge bonus: up to $100 and 4 Promotion. Base rewards stay intact.\n" + ContractChallenges.description(PublisherTrialTerms.contract_id(quote.publisher_id))
		return
	if _selected_contract_offer_id == ContractState.CONTRACT_ID:
		title.text = "Balanced Primitive Contract"
		details.text = "Publisher: Ironclad Interactive\nTwo production hands · one to four cards per hand\nTargets: Scope 12 · Graphics/Sound/Technology/Design 6 each\nInvestment and maximum total payout: $2,400.00\nAccept for a guaranteed %s immediately; completion pool %s pays proportionally after hand two.\nUnlocked Primitive Design and Alpha Features are finite; Core Passes are renewable.\nAcceptance costs no cycles. The contract cannot be abandoned after acceptance." % [CashFormatter.format_exact_cents(_run_state.get_ironclad_advance_cents()),CashFormatter.format_exact_cents(240000-_run_state.get_ironclad_advance_cents())]
	else:
		var offer := {}
		for release: StringName in _run_state._sidestreet_entitlements:
			if _run_state._sidestreet_entitlements[release].offer_id==_selected_contract_offer_id: offer = {"release_id":release}
		if offer.is_empty():
			details.text = "This offer is no longer available. Return to Studio and reopen Contracts."
			return
		title.text = "SideStreet Cash Contract"
		details.text = "Publisher: SideStreet Games\nOffer for: %s\nTwo production hands · one to four cards per hand\nTargets: Scope 12 · Graphics/Sound/Technology/Design 6 each\nBase maximum payout: $1,200.00, paid only after hand two according to completion.\nUnlocked Primitive Design and Alpha Features are finite; Core Passes are renewable.\nAcceptance costs no cash or cycles. The contract cannot be abandoned after acceptance." % ("Found by a paid search" if not _run_state.ContractSearch.source(_run_state,_selected_contract_offer_id,&"cash").is_empty() else _run_state.get_released_game_display_name(offer.release_id))
		details.text += "\nSeparate challenge bonus: up to $100 and 4 Promotion. Base payout stays intact.\n" + ContractChallenges.description(ContractDefinitions.SIDESTREET)


func _close_contract_detail() -> void:
	if _contract_detail != null:
		_contract_detail.hide()
	_open_menu(&"production",%Contracts)
	tutorial_context_changed.emit(&"studio")


func _accept_contract() -> void:
	if _checkpoint_action_waiting: return
	var gate:=preload("res://scripts/persistence/checkpoint_ui_gate.gd")
	if gate.needs_wait(_run_state):
		_checkpoint_action_waiting=true
		var selected:=_selected_contract_offer_id
		var engine:=_run_state.get_selected_engine_id()
		var saved: bool=await gate.wait_saved(_run_state)
		_checkpoint_action_waiting=false
		if not saved or not _contract_detail.visible or selected!=_selected_contract_offer_id or engine!=_run_state.get_selected_engine_id(): return
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
	_hide_menu_pages()
	if _run_state == null: return
	if _market_browser == null:
		_market_browser = MarketBrowser.new()
		add_child(_market_browser)
		_market_browser.closed.connect(func():
			_open_menu(&"market",_market_button)
			tutorial_context_changed.emit(&"studio"))
	%Dashboard.hide()
	%SummaryPanel.hide()
	_market_browser.open(_run_state,_rival_world)
	_present_destination(_market_browser,_market_browser.back_button)
	tutorial_context_changed.emit(&"market")


func _open_feature_store() -> void:
	if _run_state == null or _engine_browser==null:
		return
	var engine_id: StringName=_engine_browser.selected_id
	var state:=_run_state.get_engine_feature_state()
	if not state.engines.has(engine_id) or state.engines[engine_id].kind!=&"proprietary":return
	_hide_menu_pages()
	if _feature_store == null:
		_feature_store = FeatureStore.new()
		add_child(_feature_store)
		_feature_store.setup(_run_state)
		_feature_store.visibility_changed.connect(func():
			if not _feature_store.visible:
				_open_engines(_engine_browser.selected_id))
	%SummaryPanel.hide()
	%Dashboard.hide()

	_feature_store.open_store(engine_id)
	_present_destination(_feature_store)
	tutorial_context_changed.emit(&"feature_store")


func setup(project_state: ProjectState, run_state: RunState, snapshot_database: PrimitiveSnapshotDatabase, prepare_only: bool = false) -> bool:
	if run_state == null or snapshot_database == null or not run_state.is_cash_initialized():
		return false
	if project_state == null and run_state.get_studio_name().is_empty():
		return false
	if project_state != null and not run_state.can_register_release(project_state):
		return false
	if _run_state != null:
		for event in [&"calendar_changed",&"sales_changed"]:
			if _run_state.is_connected(event,_queue_run_refresh):_run_state.disconnect(event,_queue_run_refresh)
	_project_state = project_state
	_run_state = run_state
	_snapshot_database = snapshot_database
	# The fully validated Studio-entry boundary is idempotent on reconstruction.
	if project_state != null and not prepare_only and not _run_state.register_release(project_state):
		return false
	_run_state.calendar_changed.connect(_queue_run_refresh)
	_run_state.sales_changed.connect(_queue_run_refresh)
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
	%StartNextGame.text = "Produce New Game"
	%StartNextGame.disabled = false
	%Employees.disabled = _run_state.get_released_game_ids().size() < 2
	%Employees.tooltip_text = "Unlocks after releasing 2 games." if %Employees.disabled else "Manage specialists, courses and training."
	if _hub!=null and _hub.transitioning:_hub._disable_choices()

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
	var first_month_cycles := Clock.month_end(1,earned.get("calendar",{}))
	%SummaryTitle.text = _run_state.get_released_game_display_name(_selected_release_id)
	%CalendarLabel.text = "Released in %d · Current date: %s" % [metadata.release_year, _run_state.get_calendar_label()]
	%ReviewLabel.text = "Final Review: %.1f / 10.0 · Production: %.2f · Scope: %.1f%%" % [snapshot.final_review, snapshot.production_rating, snapshot.scope_completion * 100.0]
	var commission_text := preload("res://scripts/contracts/commission_presentation.gd").result_text(_run_state,_selected_release_id)
	if not commission_text.is_empty(): %ReviewLabel.text += "\n"+commission_text
	%AwarenessLabel.text = "Awareness: %d · Graphics %d · Sound %d · Technology %d · Design %d" % [snapshot.awareness, snapshot.cores[0], snapshot.cores[1], snapshot.cores[2], snapshot.cores[3]]
	%ProjectedUnitsLabel.text = "Projected Month 1 Units: %d" % snapshot.projected_units
	%ProjectedRevenueLabel.text = "Projected Month 1 Gross: %s · Projected Month 1 Net: %s" % [CashFormatter.format_exact_cents(snapshot.projected_gross_cents), CashFormatter.format_exact_cents(snapshot.projected_net_cents)]
	%EarnedLabel.text = "Earned: %d / %d Month 1 cycles · Lifetime %d units · Gross: %s" % [earned.earned_cycles, first_month_cycles, earned.earned_units, CashFormatter.format_exact_cents(earned.earned_units * PrimitiveMonthOneSalesRevenueCalculator.PRICE_CENTS)]
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
	%ExhaustionLabel.text = "Month 1 sales complete (%d/%d cycles); later sales continue" % [first_month_cycles,first_month_cycles] if earned.exhausted else "Month 1 sales remaining: %d cycles" % (first_month_cycles - earned.earned_cycles)
	var later := ReleasedGameSales.get_projection(earned)
	var offer := _run_state.get_post_launch_campaign_offer(_selected_release_id)
	%CurrentAgeLabel.text = "Next sales: release-age Month %d, cycle %d of %d" % [later.get("next_age_month", 1), later.get("next_age_cycle", 1),later.get("cycle_count",2)]
	if int(later.get("next_age_month", 1)) == 1:
		%OrganicAwarenessLabel.text = "Organic Awareness begins in release-age Month 2."
		%LaterProjectedUnitsLabel.text = "Month 1 forecast: %d units across %d earning cycles" % [int(later.get("projected_month_units", 0)),first_month_cycles]
	else:
		%OrganicAwarenessLabel.text = "Organic Awareness: %.4f" % (float(later.get("organic_awareness_scaled", 0)) / 10000.0)
		%LaterProjectedUnitsLabel.text = "Projected units this release-age month: %d organic" % int(later.get("projected_month_units", 0))
		if offer.get("eligible", false):
			%LaterProjectedUnitsLabel.text += " · %d with campaign" % int(later.get("campaign_projected_month_units", 0))
	%LaterProjectedUnitsLabel.text += "\nNew age months are before future market crowding; existing earning cycles retain their factor."
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


func _open_employees(preview_only: bool=false) -> void:
	if _run_state == null or _run_state.get_released_game_ids().size() < 2: return
	# Browsing is free. A save/mutation guard may defer first-time activation,
	# but must not turn an enabled navigation button into a silent no-op.
	var read_only := preview_only or (not _run_state.uses_employee_courses() and not _run_state.activate_employee_trial())
	if _employees_panel == null:
		_employees_panel = EmployeePanel.new()
		add_child(_employees_panel)
		_employees_panel.closed.connect(func():
			_open_management(%Employees))
	%SummaryPanel.hide()
	%Dashboard.hide()

	_employees_panel.open_for(_run_state)
	_present_destination(_employees_panel,_employees_panel.back_button)
	if read_only:
		_employees_panel.status.text = "Tour preview: no roster has been activated or changed. Finish the tour and open Employees to manage staff." if preview_only else "Employee management is temporarily read-only. Resolve any save warning, then reopen this menu to retry."
		_employees_panel.status.show()

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
	var result: Dictionary=preload("res://scripts/simulation/studio_actions.gd").execute(_run_state,&"search_contracts",{"quote":_search_quote.duplicate(true)},true)
	if not result.ok:
		_refresh_contract_search();return
	var id: StringName=_run_state.get_contract_search_state().receipts[-1].offer_id
	_open_contracts(id)

func get_predevelopment_intent() -> Dictionary:
	return {} if _predevelopment==null else _predevelopment.get_start_intent()

func _queue_destination_fit(view: Variant) -> void:
	if not is_instance_valid(view):return
	for item: Dictionary in _destination_fits:
		if item.view.get_ref()==view:item.frames=2;return
	_destination_fits.append({"view":weakref(view),"frames":2})

func _process(_delta: float) -> void:
	var waiting:=_destination_fits.duplicate();_destination_fits.clear()
	for item: Dictionary in waiting:
		var view: Control=item.view.get_ref()
		if view==null or not view.is_visible_in_tree():continue
		item.frames-=1
		if item.frames>0 or view.get_meta("folder_navigation_motion",false):_destination_fits.append(item);continue
		view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
