class_name EmployeePanel
extends Control
const Clock := preload("res://scripts/calendar/calendar_clock.gd")
const Data := preload("res://scripts/ui/progression_tree_data.gd")
signal closed
signal confirmed
var run: RunState
var quote: Dictionary={}
var panel: PanelContainer
var course_grid: Control
var footer: Label
var back_button: Button
var confirmation: ConfirmationDialog
var pending: Dictionary={}
var status: Label
var section: StringName=&"roster"
var selected_role: StringName=&"production"
var employee_buttons: Dictionary={}
var course_buttons: Dictionary={}
var _hire_buttons: Dictionary={}
var _roster_page: HBoxContainer
var _employee_pages: Dictionary={}
var _employee_copy: Dictionary={}
var _wage_boxes: Dictionary={}
var _training_boxes: Dictionary={}
var _heading: Label
var _displayed_role: StringName=&""
var _return_focus: Control
var challenge_label: Label
var challenge_heading: Label
var challenge_panel: PanelContainer
var progress_bar: ProgressBar
var progress_label: Label
var course_view_switch: HSlider
var _course_switch_row: HBoxContainer
var _challenge_switch_label: Label
var _reward_switch_label: Label
var _course_view_id: StringName = &""
var _course_challenge := ""
var _course_reward := ""
var _course_enrolled := false

func _ready() -> void:
	add_to_group(PauseMenu.CANCEL_OWNER_GROUP)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme=FolderUI.THEME;mouse_filter=Control.MOUSE_FILTER_STOP;z_index=30
	var host:=FolderUI.SurfaceHost.new();host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(host)
	panel=FolderUI.surface(host);panel.set_meta("bounded_folder",true)
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",12);panel.add_child(box)
	var header:=FolderUI.header(box,"Employees","Select an employee or open their Courses to inspect training.",_back)
	back_button=header.get_node("Back");_heading=header.get_child(1).get_child(0)
	status=FolderUI.label(box,"");status.hide()
	_roster_page=HBoxContainer.new();_roster_page.add_theme_constant_override("separation",18);_roster_page.size_flags_vertical=Control.SIZE_EXPAND_FILL;box.add_child(_roster_page)
	var list_scroll:=ScrollContainer.new();list_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;list_scroll.follow_focus=true
	list_scroll.custom_minimum_size.x=400;list_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_roster_page.add_child(list_scroll)
	var list:=VBoxContainer.new();list.name="EmployeeList";list.add_theme_constant_override("separation",12);list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list_scroll.add_child(list)
	FolderUI.label(list,"One specialist per role",&"SectionHeading")
	var details_scroll:=ScrollContainer.new();details_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;details_scroll.follow_focus=true
	details_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;details_scroll.size_flags_stretch_ratio=1.3;_roster_page.add_child(details_scroll)
	var pages:=VBoxContainer.new();pages.size_flags_horizontal=Control.SIZE_EXPAND_FILL;details_scroll.add_child(pages)
	for role: StringName in [&"production",&"qa",&"project_manager"]:
		var row:=HBoxContainer.new();row.add_theme_constant_override("separation",8);list.add_child(row)
		var button:=FolderUI.button(row,_role_name(role),select_employee.bind(role));button.name="Employee_"+str(role)
		button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;button.custom_minimum_size.y=68;button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;employee_buttons[role]=button
		var courses:=FolderUI.button(row,"Courses",open_courses.bind(role));courses.name="Courses_"+str(role);courses.custom_minimum_size.x=116;course_buttons[role]=courses
		var page:=VBoxContainer.new();page.add_theme_constant_override("separation",14);page.size_flags_horizontal=Control.SIZE_EXPAND_FILL;pages.add_child(page);_employee_pages[role]=page
		FolderUI.label(page,_role_name(role),&"HeadingLabel")
		FolderUI.label(page,_role_description(role))
		_employee_copy[role]=FolderUI.label(page,"")
		_wage_boxes[role]=VBoxContainer.new();page.add_child(_wage_boxes[role])
		_training_boxes[role]=VBoxContainer.new();page.add_child(_training_boxes[role])
		var hire:=FolderUI.button(page,"Hire for $100.00",func():request_purchase(&"hire",run.get_employee_hire_quote(role)),&"PrimaryButton")
		hire.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;hire.name="Hire_"+str(role);_hire_buttons[role]=hire
	course_grid=preload("res://scripts/ui/progression_tree_view.gd").new();course_grid.name="CourseTree";course_grid.size_flags_vertical=Control.SIZE_EXPAND_FILL;box.add_child(course_grid);course_grid.hide()
	course_grid.inspected.connect(_inspect_course_node);course_grid.action_requested.connect(_enroll_course_node)
	_build_course_details()
	footer=FolderUI.label(box,"",&"SecondaryLabel")
	confirmation=preload("res://scripts/ui/quit_confirmation.gd").new();confirmation.wrap_controls=false;confirmation.min_size=Vector2i(680,300);confirmation.exclusive=true;add_child(confirmation)
	confirmation.confirmed.connect(_commit_pending);confirmation.canceled.connect(func():pending={})
	hide()

func _build_course_details() -> void:
	course_grid.popup.theme_type_variation=&"DocumentPanel" # Inspectors must obscure the tree beneath their text.
	course_grid.minimum_detail_height=320.0
	course_grid.detail_width=480.0
	var heading: HBoxContainer = course_grid._title.get_parent()
	course_grid._title.custom_minimum_size.x = 88
	var close_button: Control = heading.get_child(1)
	close_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_course_switch_row = HBoxContainer.new()
	_course_switch_row.name = "CourseViewSelector"
	_course_switch_row.add_theme_constant_override("separation",4)
	_course_switch_row.alignment = BoxContainer.ALIGNMENT_END
	_course_switch_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	heading.add_child(_course_switch_row)
	heading.move_child(_course_switch_row,1)
	_challenge_switch_label = FolderUI.label(_course_switch_row,"Challenge",&"MetadataLabel")
	_challenge_switch_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_challenge_switch_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_challenge_switch_label.add_theme_font_size_override("font_size",12)
	course_view_switch = HSlider.new()
	course_view_switch.name = "CourseViewSwitch"
	course_view_switch.min_value = 0; course_view_switch.max_value = 1; course_view_switch.step = 1
	course_view_switch.custom_minimum_size = Vector2(48,32)
	course_view_switch.focus_mode = Control.FOCUS_ALL
	course_view_switch.scrollable = false
	course_view_switch.tooltip_text = "Switch between challenge and rewards."
	var track := StyleBoxFlat.new()
	track.bg_color = FolderUI.color(&"secondary")
	track.border_color = FolderUI.color(&"indigo")
	track.set_border_width_all(1);track.set_corner_radius_all(6)
	track.content_margin_top = 4;track.content_margin_bottom = 4
	course_view_switch.add_theme_stylebox_override("slider",track)
	var knob_image := Image.create(16,16,false,Image.FORMAT_RGBA8)
	knob_image.fill(Color.TRANSPARENT)
	var knob_color := FolderUI.color(&"mint")
	for x in 16:
		for y in 16:
			if Vector2(x-7.5,y-7.5).length_squared() <= 49.0: knob_image.set_pixel(x,y,knob_color)
	var knob := ImageTexture.create_from_image(knob_image)
	course_view_switch.add_theme_icon_override("grabber",knob)
	course_view_switch.add_theme_icon_override("grabber_highlight",knob)
	_course_switch_row.add_child(course_view_switch)
	_reward_switch_label = FolderUI.label(_course_switch_row,"Rewards",&"MetadataLabel")
	_reward_switch_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_reward_switch_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_reward_switch_label.add_theme_font_size_override("font_size",12)
	course_view_switch.value_changed.connect(func(_value: float): _render_course_view(true))
	_course_switch_row.hide()
	challenge_panel=FolderUI.surface(course_grid.detail_extension)
	challenge_panel.add_theme_stylebox_override("panel",FolderUI.THEME.get_stylebox("normal",&"Button"))
	challenge_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var inset:=MarginContainer.new();challenge_panel.add_child(inset)
	for edge in ["left","right","top","bottom"]:inset.add_theme_constant_override("margin_"+edge,14)
	var challenge_box:=VBoxContainer.new();challenge_box.add_theme_constant_override("separation",8);inset.add_child(challenge_box)
	challenge_heading=FolderUI.label(challenge_box,"",&"SectionHeading");challenge_heading.hide()
	challenge_label=FolderUI.label(challenge_box,"");challenge_label.name="CourseChallenge";challenge_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	progress_bar=ProgressBar.new();progress_bar.name="CourseProgress";progress_bar.custom_minimum_size.y=48;progress_bar.show_percentage=false;progress_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	progress_bar.add_theme_stylebox_override("background",FolderUI.THEME.get_stylebox("normal",&"Button"))
	progress_bar.add_theme_stylebox_override("fill",FolderUI.THEME.get_stylebox("normal",&"ActiveFolderTab"))
	course_grid.action_extension.add_child(progress_bar)
	progress_label=FolderUI.label(progress_bar,"",&"MetadataLabel");progress_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	progress_label.offset_left=10;progress_label.offset_right=-10;progress_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;progress_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size",14);progress_label.add_theme_color_override("font_color",FolderUI.color(&"text"));progress_label.mouse_filter=Control.MOUSE_FILTER_IGNORE

func open_for(value: RunState) -> void:
	if run!=value:
		if run!=null:
			if run.employees_changed.is_connected(_refresh):run.employees_changed.disconnect(_refresh)
			if run.finance_changed.is_connected(_refresh):run.finance_changed.disconnect(_refresh)
		pending={};confirmation.hide();selected_role=&"production";_displayed_role=&""
		run=value;run.employees_changed.connect(_refresh);run.finance_changed.connect(_refresh)
	_return_focus=get_viewport().gui_get_focus_owner()
	section=&"roster";status.hide();course_grid.close_details();show();_refresh();back_button.grab_focus()

func select_employee(role: StringName) -> void:
	if not employee_buttons.has(role):return
	selected_role=role;section=&"roster";_refresh()

func open_courses(role: StringName) -> void:
	if not employee_buttons.has(role):return
	_course_view_id=&"";course_view_switch.set_value_no_signal(0)
	selected_role=role;section=&"courses";_refresh();course_grid.focus_root.call_deferred()

func _back() -> void:
	if confirmation.visible:confirmation.hide();pending={};return
	if section==&"courses" and course_grid.popup.visible:course_grid.close_details();return
	if section==&"courses":
		course_grid.close_details();section=&"roster";_refresh();course_buttons[selected_role].grab_focus()
	else:close()

func close() -> void:
	if confirmation.visible:confirmation.hide();pending={};return
	course_grid.close_details();hide();closed.emit()
	if is_instance_valid(_return_focus):_return_focus.grab_focus()

func _employee(role: StringName,roster: Dictionary) -> Dictionary:
	for candidate: Dictionary in roster.employees.values():
		if candidate.type==role:return candidate
	return {}

func _clear(parent: Node) -> void:
	for child in parent.get_children():parent.remove_child(child);child.queue_free()

func _refresh() -> void:
	if run==null or not visible:return
	var roster:=run.get_employees()
	var payroll:=run.get_studio_finance_snapshot()
	var total:=0;var current:=0
	for pay: Dictionary in payroll.employees:
		total+=StudioFinanceLedger.payroll_wage(pay,StudioFinanceLedger.MAX_INT,run.get_calendar_profile())
		current+=StudioFinanceLedger.payroll_wage(pay,run.get_completed_run_cycles(),run.get_calendar_profile())
	footer.text="Monthly payroll: current %s · scheduled %s · Cash %s"%[CashFormatter.format_exact_cents(current),CashFormatter.format_exact_cents(total),CashFormatter.format_exact_cents(run.get_cash_cents())]
	_roster_page.visible=section==&"roster";course_grid.visible=section==&"courses"
	_heading.text=_role_name(selected_role)+" · Courses" if section==&"courses" else "Employees"
	if section==&"courses":
		course_grid.set_rows(Data.employee_courses(run,selected_role),_displayed_role!=selected_role);_displayed_role=selected_role
		return
	for role: StringName in employee_buttons:
		_employee_pages[role].visible=role==selected_role
		employee_buttons[role].theme_type_variation=&"ActiveFolderTab" if role==selected_role else &"Button"
		var e:=_employee(role,roster);var offer:=run.get_employee_hire_quote(role) if e.is_empty() else {}
		_hire_buttons[role].visible=e.is_empty();_hire_buttons[role].disabled=offer.is_empty() or not run.uses_employee_trial()
		_clear(_wage_boxes[role]);_clear(_training_boxes[role])
		if e.is_empty():
			_employee_copy[role].text="Available to hire · $1,000.00/month"+(" · First payday: cycle %d"%offer.first_due_cycle if not offer.is_empty() else "\nRequires two releases, current bills and enough cash.")
		else:
			_employee_copy[role].text="Hired · Courses and challenges belong to this employee."
			_payroll_copy(_wage_boxes[role],e,payroll)
			if e.has("career"):_career_summary(_training_boxes[role],e)
			elif e.type==&"production" and e.trained:FolderUI.label(_training_boxes[role],"Training complete (legacy)")
			else:FolderUI.label(_training_boxes[role],"Courses completed: %d / 2"%e.get("courses",{}).values().filter(func(c):return c.completed_cycle>=0).size())

func _inspect_course_node(id: StringName) -> void:
	var node: Dictionary=course_grid.rows.get(id,{})
	if node.get("kind")!=&"course":
		_course_view_id=&"";_course_switch_row.hide();course_grid._copy.show();return
	if _course_view_id!=id:
		_course_view_id=id;course_view_switch.set_value_no_signal(0)
	_course_switch_row.show()
	var employee: Dictionary=run.get_employees().employees.get(node.employee_id,{})
	var progress:=Data.course_progress(employee,node.course)
	var text: String=_benefit(node.course) if node.role==&"qa" else "Once per game, change priorities during a matching hand without spending a cycle." if node.course==&"production_planning" else "Use one redraw to pick a Pass that matches a Feature." if node.course==&"pass_alignment" else "Lower your minimum and raise your maximum priority by 5 points."
	_course_reward=text
	_course_challenge=_criterion(node.course) if node.role==&"qa" else _career_criterion(node.course)
	_course_enrolled=progress.enrolled
	var offer: Dictionary=run.get_employee_course_quote(node.employee_id,node.course) if node.state=="ready" else {}
	var reason := ""
	if not progress.enrolled and offer.is_empty():reason="Hire this employee first." if employee.is_empty() else "Complete the previous course and check your available money."
	course_grid.set_description(reason);course_grid._copy.visible=not reason.is_empty();course_grid.use_detail_extension()
	_render_course_view()
	progress_bar.visible=progress.enrolled;progress_bar.max_value=progress.maximum;progress_bar.value=progress.value;progress_label.text=progress.text
	course_grid.action_button.name="Enroll_"+str(node.course)
	course_grid.configure_action("" if progress.enrolled else str(node.action),not offer.is_empty())
	course_grid._fit_popup.call_deferred()

func _render_course_view(reset_scroll: bool = false) -> void:
	if not is_instance_valid(challenge_heading) or not is_instance_valid(course_view_switch): return
	var rewards := course_view_switch.value >= 0.5
	challenge_heading.hide()
	challenge_label.show()
	challenge_label.text = _course_reward if rewards else _course_challenge
	_challenge_switch_label.add_theme_color_override("font_color",FolderUI.color(&"muted") if rewards else FolderUI.color(&"mint"))
	_reward_switch_label.add_theme_color_override("font_color",FolderUI.color(&"mint") if rewards else FolderUI.color(&"muted"))
	if is_instance_valid(course_grid) and course_grid.popup.visible:
		if reset_scroll: course_grid.reset_details_scroll()
		course_grid._fit_popup.call_deferred()

func _enroll_course_node(id: StringName) -> void:
	var node: Dictionary=course_grid.rows.get(id,{})
	if node.get("kind")==&"course":request_purchase(&"course",run.get_employee_course_quote(node.employee_id,node.course))

func request_purchase(kind: StringName,offer: Dictionary) -> void:
	if offer.is_empty() or confirmation.visible:return
	pending={"kind":kind,"quote":offer.duplicate(true)};quote=offer.duplicate(true)
	confirmation.title="Confirm hiring" if kind==&"hire" else "Confirm course"
	confirmation.dialog_text="Hire for $100.00? Monthly base pay is $1,000.00. First payday: cycle %d."%offer.first_due_cycle if kind==&"hire" else "Enroll for $150.00? Only future hands count. Completing this challenge permanently adds $100.00/month to this employee's wage."
	confirmation.get_ok_button().text="Confirm";confirmation.popup_centered(Vector2i(680,300));confirmation.get_cancel_button().grab_focus()

func _commit_pending() -> void:
	if pending.is_empty() or run==null:return
	var choice:=pending.duplicate(true);pending={}
	var result: Dictionary=preload("res://scripts/simulation/studio_actions.gd").execute(run,choice.kind,{"quote":choice.quote},true)
	_refresh();status.text="Purchase complete." if result.ok else "Cash, bills or this offer changed. Please review the current offer.";status.show()
	if section==&"courses" and course_grid.popup.visible:
		course_grid.reset_details_scroll();course_grid.focus_details.call_deferred()
	else:employee_buttons[selected_role].grab_focus()

func _input(event: InputEvent) -> void:
	if is_visible_in_tree() and MenuTransitions.navigation_input_blocked(self):get_viewport().set_input_as_handled();return
	if visible and MenuTransitions.cancel_pressed(event):
		if confirmation.visible:confirmation.hide();pending={}
		elif course_grid.visible and course_grid.popup.visible:course_grid.close_details()
		else:_back()
		get_viewport().set_input_as_handled()

func get_menu_transition_content() -> Control: return panel.get_child(0)

static func _role_name(role: StringName) -> String:
	return {&"production":"Production Specialist",&"qa":"QA Specialist",&"project_manager":"Project Manager"}.get(role,str(role).capitalize())

static func _role_description(role: StringName) -> String:
	return {&"production":"Enroll in Production courses to earn bundled priority planning and chosen matching Pass replacement.",&"qa":"Enroll in QA courses to earn specialization Bug searches and one-card Swap.",&"project_manager":"Complete sequential course challenges to widen priority ranges across planning screens."}.get(role,"")

static func _career_criterion(course: StringName) -> String:
	if course==&"production_planning":return "In Design, play a Pass and a Feature with matching Core."
	if course==&"pass_alignment":return "In one game, play a matching Pass and Feature in Design and Alpha. Then release the game."
	if course==&"manager_1":return "Play 2 specialty hands under the category with the lowest priority, 4 times"
	return "In each of 4 released games, play 2 specialty hands at the lowest allowed priority."

func _career_summary(parent: Node,e: Dictionary) -> void:
	if e.type==&"project_manager":
		var level:=EmployeeRoster.Career.completed(e)
		var core:=PriorityAllocation.bounds(run);var beta:=BetaPriorityAllocation.bounds(run)
		FolderUI.label(parent,"Level %d/4 · Core %d–%d%% · Beta %d–%d%% · exact 100 in 5-point steps"%[level,core.x,core.y,beta.x,beta.y])
	else:FolderUI.label(parent,"Completed courses: %d/2 · Course purchase starts training; completion earns the benefit and raise."%EmployeeRoster.Career.completed(e))

func _payroll_copy(parent: Node,e: Dictionary,payroll: Dictionary) -> void:
	for pay: Dictionary in payroll.employees:
		if pay.employee_id!=e.employee_id:continue
		var due: int=StudioFinanceLedger.payroll_due_cycle(pay,int(pay.issued),run.get_calendar_profile())
		FolderUI.label(parent,"Current wage %s/month · Next bill %s at cycle %d"%[CashFormatter.format_exact_cents(StudioFinanceLedger.payroll_wage(pay,run.get_completed_run_cycles(),run.get_calendar_profile())),CashFormatter.format_exact_cents(StudioFinanceLedger.payroll_wage(pay,due,run.get_calendar_profile())),due])
		for change: Dictionary in pay.get("wage_changes",[]):
			var effective: int=Clock.retarget_cycle(int(change.cycle),change.get("calendar",{}),run.get_calendar_profile())
			if effective>run.get_completed_run_cycles():FolderUI.label(parent,"Scheduled wage %s/month from cycle %d"%[CashFormatter.format_exact_cents(change.wage_cents),effective])

static func _criterion(course: StringName) -> String:
	return "Find 2 bugs and fix 2 bugs in one Beta hand. Do this 4 times." if course==&"mixed" else "In Beta, play 4 Search cards in a hand 3 times, and 4 Debug cards in a hand 3 times."

static func _benefit(course: StringName) -> String:
	return "Each Feature replay in a specialty hand has a 25% chance to find a Hidden Bug." if course==&"mixed" else "Once per game, after 4 Search or 4 Debug cards, swap a QA card for its opposite for free."
