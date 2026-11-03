extends "res://scripts/debug/verify_studio_finance_integration.gd"
var output := ""
func capture(label: String) -> void:
	if DisplayServer.get_name()=="headless" or output.is_empty():return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
	snapshots.load_ledgers()
	for resolution in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=resolution;root.content_scale_size=resolution
		var run:=preload("res://scripts/debug/employee_test_actions.gd").fresh_two_releases(root.get_node("CardDatabase").get_development_catalog())
		var host:=Control.new();root.add_child(host);host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var panel:=EmployeePanel.new();host.add_child(panel);panel.open_for(run)
		check(panel.visible and not panel._hire_buttons[&"qa"].disabled,"Legal two-release prefix unlocks hiring")
		panel.back_button.pressed.emit();check(not panel.visible,"Back closes folder")
		var untouched:=named()
		check(untouched.register_release(_released_project(751)) and untouched.get_employee_hire_quote(&"qa").is_empty(),"One release does not unlock hiring")
		panel.open_for(run)
		for i in range(8):await process_frame
		check(panel.theme==FolderUI.THEME and panel.employee_buttons.size()==3 and panel.course_buttons.size()==3 and panel.back_button.has_focus(),"Shared folder Theme, employee list and keyboard focus")
		check(Rect2(Vector2.ZERO,Vector2(resolution)).encloses(panel.panel.get_global_rect()) and panel.footer.is_visible_in_tree(),"Bounded folder and fixed payroll footer fit viewport")
		await capture("employees-roster-%d"%resolution.x)
		var quote:=run.get_employee_hire_quote(&"qa");var before:=snapshot(run)
		panel.request_purchase(&"hire",quote);panel.confirmation.hide();panel.confirmation.canceled.emit()
		check(snapshot(run)==before and run.get_employees().employees.is_empty(),"Cancel confirmation changes no money or roster")
		panel.request_purchase(&"hire",quote);panel.confirmation.hide();panel.confirmation.confirmed.emit()
		check(run.get_employees().employees.size()==1 and run.get_cash_cents()==before[0]-10000,"Confirmed QA hiring charges once")
		check(not run.hire_specialist(quote),"Stale hire quote rejects")
		panel.open_courses(&"qa");await process_frame;await capture("employees-courses-%d"%resolution.x)
		var course:=run.get_qa_course_quote(&"mixed");before=snapshot(run)
		panel.request_purchase(&"course",course);panel.confirmation.hide();panel.confirmation.confirmed.emit()
		check(run.get_cash_cents()==before[0]-15000 and run.get_completed_run_cycles()==before[1] and not run.purchase_qa_course(course),"Course exact fee, zero cycles and duplicate rejection")
		var public_view: Dictionary=preload("res://scripts/simulation/studio_actions.gd").observation(run)
		var qa_view: Dictionary=public_view.employees.employees.values()[0]
		check(not qa_view.has("rng_seed") and not qa_view.has("rng_state") and not qa_view.has("pending_design") and not public_view.employees.has("events"),"Policy observations exclude private QA RNG and unresolved Design leads")
		var production:=run.get_employee_hire_quote(&"production")
		check(run.hire_specialist(production) and run.get_studio_finance_report().monthly_payroll_cents==200000,"Production and QA typed payroll add to $2,000")
		panel.open_courses(&"qa");panel.course_grid.inspect(&"mixed");await process_frame;await capture("employees-progress-%d"%resolution.x)
		var adapter:=StudioCheckpoint.new();var dto:=adapter.capture(run)
		check(not dto.is_empty() and adapter.validate(dto).is_empty(),"Employee/course checkpoint schema and provenance validate: "+adapter.error)
		var restored:=adapter.hydrate(dto)
		check(restored!=null and adapter.capture(restored)==dto,"Current employee/course Studio restores exactly")
		var forged_run:=adapter.hydrate(dto)
		check(forged_run.complete_productive_action(),"Adversarial accounting fixture advances without a Beta hand")
		forged_run._employees=EmployeeRoster.qa_beta_hand(forged_run._employees,&"phantom_qa_hand",0,forged_run.get_completed_run_cycles(),2,2,1,1)
		forged_run._sync_employee_raises()
		check(adapter.capture(forged_run).is_empty(),"Phantom QA progress without a committed Beta finance action rejects")
		var escape:=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true
		panel._input(escape);check(not panel.course_grid.popup.visible,"Escape closes course inspector")
		panel._input(escape);check(panel.section==&"roster","Escape restores employee list")
		panel._input(escape);check(not panel.visible,"Escape closes folder")
		host.queue_free();await process_frame
	print("Employee UI: %d failures"%failures);quit(failures)
