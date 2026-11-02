class_name EmployeePanel
extends Control
const Clock := preload("res://scripts/calendar/calendar_clock.gd")
signal closed
signal confirmed
var run: RunState
var quote: Dictionary={}
var panel: PanelContainer
var course_grid: Control
var _content_scroll: ScrollContainer
var content: VBoxContainer
var footer: Label
var back_button: Button
var tabs: Dictionary={}
var section: StringName=&"roster"
var confirmation: ConfirmationDialog
var pending: Dictionary={}
var status: Label
var _return_focus: Control
var _hire_buttons: Dictionary={}
func _ready() -> void:
	add_to_group(PauseMenu.CANCEL_OWNER_GROUP)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme=FolderUI.THEME;mouse_filter=Control.MOUSE_FILTER_STOP;z_index=30
	var host:=FolderUI.SurfaceHost.new();host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(host)
	panel=FolderUI.surface(host);panel.set_meta("bounded_folder",true)
	var box:=VBoxContainer.new();box.add_theme_constant_override("separation",12);panel.add_child(box)
	back_button=FolderUI.header(box,"Employees","Specialists, courses and permanent training",close).get_node("Back")
	var row:=FolderUI.tabs(box)
	for key in [&"roster",&"courses",&"progress"]:
		tabs[key]=FolderUI.button(row,str(key).capitalize(),func():show_section(key),&"FolderTab")
	status=FolderUI.label(box,"");status.hide()
	var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.follow_focus=true;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;box.add_child(scroll);_content_scroll=scroll
	content=VBoxContainer.new();content.add_theme_constant_override("separation",14);content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(content)
	course_grid=preload("res://scripts/ui/progression_tree_view.gd").new();course_grid.name="CourseTree";course_grid.size_flags_vertical=Control.SIZE_EXPAND_FILL;box.add_child(course_grid);course_grid.hide()
	course_grid.inspected.connect(_inspect_course_node);course_grid.action_requested.connect(_enroll_course_node)
	footer=FolderUI.label(box,"",&"SecondaryLabel")
	confirmation=preload("res://scripts/ui/quit_confirmation.gd").new();confirmation.wrap_controls=false;confirmation.min_size=Vector2i(680,300);confirmation.exclusive=true;add_child(confirmation)
	confirmation.confirmed.connect(_commit_pending);confirmation.canceled.connect(func():pending={})
	hide()
func open_for(value: RunState) -> void:
	if run!=value:
		if run!=null:
			if run.employees_changed.is_connected(_refresh):run.employees_changed.disconnect(_refresh)
			if run.finance_changed.is_connected(_refresh):run.finance_changed.disconnect(_refresh)
		run=value;run.employees_changed.connect(_refresh);run.finance_changed.connect(_refresh)
	_return_focus=get_viewport().gui_get_focus_owner()
	status.hide()
	show();_refresh();back_button.grab_focus()
func close() -> void:
	if confirmation.visible:confirmation.hide();pending={};return
	hide();closed.emit()
	if is_instance_valid(_return_focus):_return_focus.grab_focus()
func show_section(value: StringName) -> void:
	section=value;_refresh()
	if section==&"courses":course_grid.focus_root.call_deferred()
func _refresh() -> void:
	if run==null or not visible:return
	for child in content.get_children():content.remove_child(child);child.queue_free()
	_hire_buttons.clear()
	for key in tabs:tabs[key].theme_type_variation=&"ActiveFolderTab" if key==section else &"FolderTab"
	var roster:=run.get_employees()
	var payroll:=run.get_studio_finance_snapshot()
	var total:=0;var current:=0
	for pay: Dictionary in payroll.employees:
		total+=StudioFinanceLedger.payroll_wage(pay,StudioFinanceLedger.MAX_INT,run.get_calendar_profile())
		current+=StudioFinanceLedger.payroll_wage(pay,run.get_completed_run_cycles(),run.get_calendar_profile())
	footer.text="Monthly payroll: current %s · scheduled %s · Cash %s"%[CashFormatter.format_exact_cents(current),CashFormatter.format_exact_cents(total),CashFormatter.format_exact_cents(run.get_cash_cents())]
	course_grid.visible=section==&"courses";_content_scroll.visible=section!=&"courses"
	if section==&"courses":
		course_grid.set_rows(preload("res://scripts/ui/progression_tree_data.gd").courses(run));return
	if section==&"roster":
		FolderUI.label(content,"One specialist per role · Hiring unlocks after your second release",&"SubheadingLabel")
		for role in [&"production",&"qa",&"project_manager"]:
			var e: Dictionary={}
			for candidate: Dictionary in roster.employees.values():
				if candidate.type==role:e=candidate
			var card:=FolderUI.surface(content,true);var body:=VBoxContainer.new();body.add_theme_constant_override("separation",8);card.add_child(body)
			FolderUI.label(body,_role_name(role),&"SubheadingLabel")
			FolderUI.label(body,_role_description(role))
			if e.is_empty():
				var offer:=run.get_employee_hire_quote(role)
				FolderUI.label(body,"$1,000.00 / month · Hire $100.00"+(" · First payday: cycle %d"%offer.first_due_cycle if not offer.is_empty() else " · Requires two releases, current bills and enough cash"))
				var button:=FolderUI.button(body,"Hire for $100.00",func():request_purchase(&"hire",run.get_employee_hire_quote(role)))
				button.disabled=offer.is_empty() or not run.uses_employee_trial();_hire_buttons[role]=button
			else:
				FolderUI.label(body,"Hired · "+("Courses completed: %d"%EmployeeRoster.Career.completed(e) if e.has("career") else ("Training complete" if e.trained else "Enroll in a course to train")));_payroll_copy(body,e,payroll)
	else:
		if roster.employees.is_empty():FolderUI.label(content,"Your hired specialists and their permanent progress will appear here.")
		for e: Dictionary in roster.employees.values():
			FolderUI.label(content,_role_name(e.type),&"SubheadingLabel");_payroll_copy(content,e,payroll)
			if e.type==&"qa":
				for course in [&"mixed",&"pure"]:
					FolderUI.label(content,_criterion(course))
					var progress: String="Not enrolled" if not e.courses.has(course) else ("Complete" if e.courses[course].completed_cycle>=0 else ("Search %d/3 · Debug %d/3"%[e.search_count,e.debug_count] if course==&"pure" else "Discover and fix in the same hand"))
					FolderUI.label(content,progress+" · "+_benefit(course))
			else:
				_career_summary(content,e)
				for course: StringName in EmployeeRoster.Career.course_ids(e.type):
					FolderUI.label(content,_career_name(course)+" · "+_career_progress(e,course))

func _inspect_course_node(id: StringName) -> void:
	var node: Dictionary=course_grid.rows.get(id,{})
	if node.get("kind")!=&"course":return
	var employee: Dictionary=run.get_employees().employees.get(node.employee_id,{})
	var text: String=_criterion(node.course)+"\n\n"+_benefit(node.course) if node.role==&"qa" else _career_criterion(node.course)
	text+="\n\n"+(node.status if employee.is_empty() or node.role==&"qa" else _career_progress(employee,node.course))
	if not employee.is_empty() and node.role==&"qa" and node.course==&"pure" and employee.courses.has(&"pure"):text+="\nSearch %d/3 · Debug %d/3"%[employee.search_count,employee.debug_count]
	if node.role!=&"qa":text+="\n\nCompletion adds $100.00/month prospectively; enrollment gives no immediate benefit."
	var offer: Dictionary=run.get_employee_course_quote(node.employee_id,node.course) if node.state=="ready" else {}
	if node.state=="ready" and offer.is_empty():text+="\n\nEnrollment unavailable: check available cash, overdue bills or the current save/action warning."
	course_grid.set_description(text)
	course_grid.action_button.name="Enroll_"+str(node.course)
	course_grid.configure_action("Completed" if node.state=="complete" else "Enrolled" if node.state=="active" else node.action,not offer.is_empty())

func _enroll_course_node(id: StringName) -> void:
	var node: Dictionary=course_grid.rows.get(id,{})
	if node.get("kind")==&"course":request_purchase(&"course",run.get_employee_course_quote(node.employee_id,node.course))

static func _role_name(role: StringName) -> String:
	return {&"production":"Production Specialist",&"qa":"QA Specialist",&"project_manager":"Project Manager"}.get(role,str(role).capitalize())

static func _role_description(role: StringName) -> String:
	return {&"production":"Enroll in Production courses to earn bundled priority planning and chosen matching Pass replacement.",&"qa":"Enroll in QA courses to earn specialization Bug searches and one-card Swap.",&"project_manager":"Complete sequential course challenges to widen priority ranges across planning screens."}.get(role,"")

func _qa_course_card(e: Dictionary,course: StringName) -> void:
	var document:=FolderUI.surface(content,true);var body:=VBoxContainer.new();body.add_theme_constant_override("separation",8);document.add_child(body)
	FolderUI.label(body,"Search & Fix" if course==&"mixed" else "QA Versatility",&"SubheadingLabel")
	FolderUI.label(body,_criterion(course));FolderUI.label(body,_benefit(course))
	if e.courses.has(course):FolderUI.label(body,"Completed · +$100.00/month" if e.courses[course].completed_cycle>=0 else "Enrolled · Future committed hands count")
	else:
		var offer:=run.get_qa_course_quote(course)
		var button:=FolderUI.button(body,"Enroll for $150.00",func():request_purchase(&"course",run.get_qa_course_quote(course)))
		button.disabled=offer.is_empty()

static func _career_name(course: StringName) -> String:
	return "Production Planning" if course==&"production_planning" else "Pass Alignment" if course==&"pass_alignment" else "Project Management %s"%str(course).get_slice("_",1)

static func _career_criterion(course: StringName) -> String:
	if course==&"production_planning":return "After enrollment, commit a Design hand with a Core Pass and a Feature matching its printed primary or secondary Core. A later matching hand can use bundled priority planning once per project."
	if course==&"pass_alignment":return "After enrollment, commit a printed Pass/Feature match in Design and Alpha of the same game, then release it. Earn chosen matching Core Pass replacement through Redraw, one normal redraw per use."
	return "After enrollment, release four distinct games with two actual Design, Alpha or Beta Specializations each, in categories at that hand's legal minimum. Each completion widens both priority limits by 5 points. Contracts do not train this challenge."

static func _career_progress(e: Dictionary,course: StringName) -> String:
	var record: Dictionary=e.get("career",{}).get("courses",{}).get(course,{})
	if record.is_empty():return "Not enrolled"
	if record.completed_cycle>=0:return "Completed · +$100.00/month"+(" · legacy training retained" if record.legacy else "")
	if e.type==&"project_manager":return "Enrolled · %d/4 qualifying released games"%e.career.games.get(course,[]).size()
	if course==&"production_planning":return "Enrolled · Commit one matching Design hand"
	var pending:=0
	for project: Dictionary in e.career.projects.values():
		if not project.design.is_empty() and not project.alpha.is_empty():pending+=1
	return "Enrolled · %d game(s) have both matches; successful release required"%pending

func _career_summary(parent: Node,e: Dictionary) -> void:
	if e.type==&"project_manager":
		var level:=EmployeeRoster.Career.completed(e)
		var core:=PriorityAllocation.bounds(run);var beta:=BetaPriorityAllocation.bounds(run)
		FolderUI.label(parent,"Level %d/4 · Core %d–%d%% · Beta %d–%d%% · exact 100 in 5-point steps"%[level,core.x,core.y,beta.x,beta.y])
	else:FolderUI.label(parent,"Completed courses: %d/2 · Course purchase starts training; completion earns the benefit and raise."%EmployeeRoster.Career.completed(e))

func _career_course_card(e: Dictionary,course: StringName) -> void:
	var document:=FolderUI.surface(content,true);var body:=VBoxContainer.new();body.add_theme_constant_override("separation",8);document.add_child(body)
	FolderUI.label(body,_career_name(course),&"SubheadingLabel")
	FolderUI.label(body,_career_criterion(course));FolderUI.label(body,_career_progress(e,course))
	if not e.get("career",{}).get("courses",{}).has(course):
		var offer:=run.get_employee_course_quote(e.employee_id,course)
		var button:=FolderUI.button(body,"Enroll for $150.00",func():request_purchase(&"course",run.get_employee_course_quote(e.employee_id,course)))
		button.name="Enroll_"+str(course);button.disabled=offer.is_empty()
		if button.disabled:button.tooltip_text="Complete the preceding course first; enrollment also requires current bills, enough cash and an active employee system."

func _payroll_copy(parent: Node,e: Dictionary,payroll: Dictionary) -> void:
	for pay: Dictionary in payroll.employees:
		if pay.employee_id!=e.employee_id:continue
		var due: int=StudioFinanceLedger.payroll_due_cycle(pay,int(pay.issued),run.get_calendar_profile())
		FolderUI.label(parent,"Current wage %s/month · Next bill %s at cycle %d"%[CashFormatter.format_exact_cents(StudioFinanceLedger.payroll_wage(pay,run.get_completed_run_cycles(),run.get_calendar_profile())),CashFormatter.format_exact_cents(StudioFinanceLedger.payroll_wage(pay,due,run.get_calendar_profile())),due])
		for change: Dictionary in pay.get("wage_changes",[]):
			var effective: int=Clock.retarget_cycle(int(change.cycle),change.get("calendar",{}),run.get_calendar_profile())
			if effective>run.get_completed_run_cycles():FolderUI.label(parent,"Scheduled wage %s/month from cycle %d"%[CashFormatter.format_exact_cents(change.wage_cents),effective])
static func _criterion(course: StringName) -> String:
	return "Commit one Beta hand that actually discovers a Hidden Bug with Search and fixes a Known Bug with Debug." if course==&"mixed" else "Across projects, commit three pure four-Search and three pure four-Debug Beta hands. Zero-output hands count."
static func _benefit(course: StringName) -> String:
	return "Permanent benefit: Feature specialization replays have a 25% trial chance each to discover one real Hidden Bug. Completion adds $100/month prospectively." if course==&"mixed" else "Permanent benefit: one later pure hand per project arms one Swap for a later hand. Select one QA card and use Swap; its value stays the same. Completion adds $100/month prospectively."
func request_purchase(kind: StringName,offer: Dictionary) -> void:
	if offer.is_empty():return
	pending={"kind":kind,"quote":offer.duplicate(true)};quote=offer.duplicate(true)
	confirmation.title="Confirm hiring" if kind==&"hire" else "Confirm course"
	confirmation.dialog_text="Hire for $100.00? Monthly base pay is $1,000.00. First payday: cycle %d."%offer.first_due_cycle if kind==&"hire" else "Enroll for $150.00? Only future hands count. Completing this challenge permanently adds $100.00/month to this employee's wage."
	confirmation.get_ok_button().text="Confirm";confirmation.popup_centered(Vector2i(680,300));confirmation.get_cancel_button().grab_focus()
func _commit_pending() -> void:
	if pending.is_empty() or run==null:return
	var choice:=pending.duplicate(true);pending={}
	var result: Dictionary=preload("res://scripts/simulation/studio_actions.gd").execute(run,choice.kind,{"quote":choice.quote},true)
	_refresh();status.text="Purchase complete." if result.ok else "Cash, bills or this offer changed. Please review the current offer.";status.show();back_button.grab_focus()
func _input(event: InputEvent) -> void:
	if is_visible_in_tree() and MenuTransitions.navigation_input_blocked(self):get_viewport().set_input_as_handled();return
	if visible and MenuTransitions.cancel_pressed(event):
		if course_grid.visible and course_grid.popup.visible:course_grid.close_details()
		else:close()
		get_viewport().set_input_as_handled()

func get_menu_transition_content() -> Control: return panel.get_child(0)
