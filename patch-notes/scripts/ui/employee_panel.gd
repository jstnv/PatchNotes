class_name EmployeePanel
extends Control
signal closed
signal confirmed
var run: RunState
var quote: Dictionary={}
var panel: PanelContainer
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
	var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.follow_focus=true;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;box.add_child(scroll)
	content=VBoxContainer.new();content.add_theme_constant_override("separation",14);content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(content)
	footer=FolderUI.label(box,"",&"SecondaryLabel")
	confirmation=ConfirmationDialog.new();confirmation.exclusive=true;add_child(confirmation)
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
func _refresh() -> void:
	if run==null or not visible:return
	for child in content.get_children():content.remove_child(child);child.queue_free()
	_hire_buttons.clear()
	for key in tabs:tabs[key].theme_type_variation=&"ActiveFolderTab" if key==section else &"FolderTab"
	var roster:=run.get_employees()
	var payroll:=run.get_studio_finance_snapshot()
	var total:=0;var current:=0
	for pay: Dictionary in payroll.employees:
		total+=StudioFinanceLedger.payroll_wage(pay,StudioFinanceLedger.MAX_INT)
		current+=StudioFinanceLedger.payroll_wage(pay,run.get_completed_run_cycles())
	footer.text="Monthly payroll: current %s · scheduled %s · Cash %s"%[CashFormatter.format_exact_cents(current),CashFormatter.format_exact_cents(total),CashFormatter.format_exact_cents(run.get_cash_cents())]
	if section==&"roster":
		FolderUI.label(content,"One specialist per role · Hiring unlocks after your second release",&"SubheadingLabel")
		for role in [&"production",&"qa"]:
			var e: Dictionary={}
			for candidate: Dictionary in roster.employees.values():
				if candidate.type==role:e=candidate
			var card:=FolderUI.surface(content,true);var body:=VBoxContainer.new();body.add_theme_constant_override("separation",8);card.add_child(body)
			FolderUI.label(body,"Production Specialist" if role==&"production" else "QA Specialist",&"SubheadingLabel")
			FolderUI.label(body,"Match a printed Pass and Feature to unlock bundled priority planning." if role==&"production" else "Enroll in QA courses to earn specialization Bug searches and one-card Swap.")
			if e.is_empty():
				var offer:=run.get_employee_hire_quote(role)
				FolderUI.label(body,"$1,000.00 / month · Hire $100.00"+(" · First payday: cycle %d"%offer.first_due_cycle if not offer.is_empty() else " · Requires two releases, current bills and enough cash"))
				var button:=FolderUI.button(body,"Hire for $100.00",func():request_purchase(&"hire",run.get_employee_hire_quote(role)))
				button.disabled=offer.is_empty() or not run.uses_employee_trial();_hire_buttons[role]=button
			else:
				FolderUI.label(body,"Hired · "+("Training complete" if e.trained else "Training in progress"));_payroll_copy(body,e,payroll)
	elif section==&"courses":
		var qa: Dictionary={}
		for e: Dictionary in roster.employees.values():
			if e.type==&"qa":qa=e
		if qa.is_empty():FolderUI.label(content,"Hire a QA Specialist after your second release to enroll in courses.")
		else:
			for course in [&"mixed",&"pure"]:
				var document:=FolderUI.surface(content,true);var body:=VBoxContainer.new();body.add_theme_constant_override("separation",8);document.add_child(body)
				FolderUI.label(body,"Search & Fix" if course==&"mixed" else "QA Versatility",&"SubheadingLabel")
				FolderUI.label(body,_criterion(course))
				FolderUI.label(body,_benefit(course))
				if qa.courses.has(course):FolderUI.label(body,"Completed · +$100.00/month" if qa.courses[course].completed_cycle>=0 else "Enrolled · Future committed hands count")
				else:
					var offer:=run.get_qa_course_quote(course)
					var button:=FolderUI.button(body,"Enroll for $150.00",func():request_purchase(&"course",run.get_qa_course_quote(course)))
					button.disabled=offer.is_empty()
	else:
		if roster.employees.is_empty():FolderUI.label(content,"Your hired specialists and their permanent progress will appear here.")
		for e: Dictionary in roster.employees.values():
			FolderUI.label(content,str(e.type).capitalize()+" Specialist",&"SubheadingLabel");_payroll_copy(content,e,payroll)
			if e.type==&"production":FolderUI.label(content,"Training: commit a Design hand with a Core Pass and matching printed primary/secondary Feature. Once trained, optionally change priorities with a later matching hand, once per project.")
			else:
				for course in [&"mixed",&"pure"]:
					FolderUI.label(content,_criterion(course))
					var progress: String="Not enrolled" if not e.courses.has(course) else ("Complete" if e.courses[course].completed_cycle>=0 else ("Search %d/3 · Debug %d/3"%[e.search_count,e.debug_count] if course==&"pure" else "Discover and fix in the same hand"))
					FolderUI.label(content,progress+" · "+_benefit(course))
func _payroll_copy(parent: Node,e: Dictionary,payroll: Dictionary) -> void:
	for pay: Dictionary in payroll.employees:
		if pay.employee_id!=e.employee_id:continue
		var due: int=pay.first_due_cycle+pay.issued*2
		FolderUI.label(parent,"Current wage %s/month · Next bill %s at cycle %d"%[CashFormatter.format_exact_cents(StudioFinanceLedger.payroll_wage(pay,run.get_completed_run_cycles())),CashFormatter.format_exact_cents(StudioFinanceLedger.payroll_wage(pay,due)),due])
		for change: Dictionary in pay.get("wage_changes",[]):
			if change.cycle>run.get_completed_run_cycles():FolderUI.label(parent,"Scheduled wage %s/month from cycle %d"%[CashFormatter.format_exact_cents(change.wage_cents),change.cycle])
static func _criterion(course: StringName) -> String:
	return "Commit one Beta hand that actually discovers a Hidden Bug with Search and fixes a Known Bug with Debug." if course==&"mixed" else "Across projects, commit three pure four-Search and three pure four-Debug Beta hands. Zero-output hands count."
static func _benefit(course: StringName) -> String:
	return "Permanent benefit: Feature specialization replays have a 25% trial chance each to discover one real Hidden Bug. Completion adds $100/month prospectively." if course==&"mixed" else "Permanent benefit: one later pure hand per project arms one Swap for a later hand. Select one QA card and use Swap; its value stays the same. Completion adds $100/month prospectively."
func request_purchase(kind: StringName,offer: Dictionary) -> void:
	if offer.is_empty():return
	pending={"kind":kind,"quote":offer.duplicate(true)};quote=offer.duplicate(true)
	confirmation.title="Confirm hiring" if kind==&"hire" else "Confirm course"
	confirmation.dialog_text="Hire for $100.00? Monthly base pay is $1,000.00. First payday: cycle %d."%offer.first_due_cycle if kind==&"hire" else "Enroll for $150.00? Only future hands count. Completing this challenge permanently adds $100.00/month to this employee's wage."
	confirmation.get_ok_button().text="Confirm";confirmation.popup_centered(Vector2i(600,220));confirmation.get_cancel_button().grab_focus()
func _commit_pending() -> void:
	if pending.is_empty() or run==null:return
	var choice:=pending.duplicate(true);pending={}
	var result: Dictionary=preload("res://scripts/simulation/studio_actions.gd").execute(run,choice.kind,{"quote":choice.quote},true)
	_refresh();status.text="Purchase complete." if result.ok else "Cash, bills or this offer changed. Please review the current offer.";status.show();back_button.grab_focus()
func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close();get_viewport().set_input_as_handled()

func get_menu_transition_content() -> Control: return panel.get_child(0)
