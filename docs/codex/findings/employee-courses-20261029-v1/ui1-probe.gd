## Real controls and live adapters; synthetic trained roster tests UI mechanics only.
extends "res://scripts/debug/verify_feature_store_radial.gd"
var checks:=0
var captures: Array=[]
func test(ok: bool,label: String) -> void:
	checks+=1;expect(ok,label)
func frames(count: int=3) -> void:
	for i in count:await process_frame
func click(button: Control) -> void:
	var viewport:=button.get_viewport()
	var point:=button.get_global_rect().get_center()
	var motion:=InputEventMouseMotion.new();motion.position=point;viewport.push_input(motion)
	for down in [true,false]:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=point;viewport.push_input(event)
	await frames()
func key(button: Control,code: Key=KEY_ENTER) -> void:
	button.grab_focus();await frames()
	for down in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.pressed=down;button.get_viewport().push_input(event)
	await frames()
func shot(label: String) -> void:
	if DisplayServer.get_name()=="headless":return
	await RenderingServer.frame_post_draw
	var path:=OS.get_environment("PN_CARD_FRAME_OUTPUT").get_basename()+"-"+label+".png"
	root.get_texture().get_image().save_png(path);captures.append(path)
func _verify() -> void:
	# This verifier needs longer than the inherited bounded Store fixture timer.
	var catalog: RefCounted=root.get_node("CardDatabase").get_development_catalog()
	for dimensions in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=dimensions;root.content_scale_size=dimensions
		var run:=preload("res://scripts/debug/employee_test_actions.gd").fresh_two_releases(catalog)
		var panel:=EmployeePanel.new();root.add_child(panel);panel.open_for(run);await frames(8)
		test(panel.tabs.size()==3 and panel._hire_buttons.size()==3,"Three role folders and hires are visible")
		var before:=[run.get_cash_cents(),run.get_completed_run_cycles(),run.get_employees()]
		await click(panel._hire_buttons[&"production"]);await create_timer(0.3).timeout
		test(panel.confirmation.visible and panel.confirmation.get_ok_button().theme_type_variation==&"PrimaryButton","Pointer opens themed hire confirmation")
		await key(panel.confirmation.get_cancel_button())
		test([run.get_cash_cents(),run.get_completed_run_cycles(),run.get_employees()]==before,"Keyboard Cancel leaves entire roster/cash/time untouched")
		await click(panel._hire_buttons[&"production"]);await create_timer(0.3).timeout
		await key(panel.confirmation.get_ok_button())
		test(run.get_employees().employees.size()==1 and run.get_cash_cents()==before[0]-10000,"Keyboard confirms Production hire once")
		var manager: Button=panel._hire_buttons[&"project_manager"]
		panel.content.get_parent().ensure_control_visible(manager);await frames()
		await key(manager);await create_timer(0.3).timeout;await key(panel.confirmation.get_ok_button())
		test(run.get_employees().employees.size()==2 and run.get_cash_cents()==before[0]-20000,"Scrollable Manager hire is keyboard reachable")
		await click(panel.tabs[&"courses"])
		var course: Button=panel.content.find_child("Enroll_production_planning",true,false)
		test(course!=null and not course.disabled,"Production first course is available")
		if course!=null:
			panel.content.get_parent().ensure_control_visible(course);await frames();await key(course);await create_timer(0.3).timeout
			await shot("course-confirm-%d"%dimensions.x);await key(panel.confirmation.get_ok_button())
		course=panel.content.find_child("Enroll_manager_1",true,false)
		test(course!=null and not course.disabled,"Manager first course is available")
		if course!=null:
			panel.content.get_parent().ensure_control_visible(course);await frames();await key(course);await create_timer(0.3).timeout;await key(panel.confirmation.get_ok_button())
		test(run.get_cash_cents()==before[0]-50000 and run.get_completed_run_cycles()==before[1],"Two hires and two courses charge exact $500 with no cycles")
		test(EmployeeRoster.Career.level(run._employees)==0 and not EmployeeRoster.Career.alignment_available(run._employees),"Enrollment gives no immediate range or alignment buff")
		await click(panel.tabs[&"progress"]);await shot("progress-%d"%dimensions.x)
		test(panel.footer.is_visible_in_tree() and Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(panel.panel.get_global_rect()),"Fixed payroll footer and bounded folder fit viewport")
		await key(panel.back_button);test(not panel.visible,"Back returns from Employees")
		panel.open_for(run);await frames();await key(panel.back_button,KEY_ESCAPE);test(not panel.visible,"Escape returns from Employees")
		panel.queue_free();await frames()
		for phase_name: StringName in [&"design",&"alpha"]:await phase_ui(phase_name,dimensions,catalog)
	FileAccess.open(OS.get_environment("PN_CARD_FRAME_OUTPUT"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures}))
	print("CAREER_UI checks=%d failures=%d"%[checks,failures]);quit(failures)
func phase_ui(phase_name: StringName,dimensions: Vector2i,catalog: RefCounted) -> void:
	var run:=RunState.new();run.initialize_cash(0);run.create_studio_with_traits("Alignment UI",&"action",[]);run.finalize_starter_selection()
	run._employees=preload("res://scripts/debug/verify_production_alignment.gd").trained(run._bank_run_id)
	var project:=ProjectState.new(30);project._release_id=&"alignment_ui"
	var phase: Control=load("res://scenes/phases/%s_phase.tscn"%phase_name).instantiate();root.add_child(phase);phase.setup(project,run)
	await frames()
	test(phase.begin_design() if phase_name==&"design" else phase.begin_alpha(),"Live phase begins "+str(phase_name))
	var feature: CardData=catalog.get_card(&"timer_system" if phase_name==&"design" else &"main_theme")
	var pool: Array[CardData]=[catalog.get_card(&"graphics_pass"),catalog.get_card(&"graphics_pass"),feature,catalog.get_card(&"sound_pass"),catalog.get_card(&"technology_pass"),catalog.get_card(&"design_pass"),catalog.get_card(&"sound_pass")]
	phase._candidate_cards.assign(pool);phase._available_features.assign([feature])
	var views: Array=phase.get_node("%HandContainer").card_views()
	for i in 7:views[i].set_card(pool[i])
	if phase_name==&"alpha":phase._command_injected_ids.clear()
	await frames(8);phase._on_card_pressed(views[0]);await click(phase.get_node("%RedrawButton"));await create_timer(0.3).timeout
	var menu: CanvasLayer=phase._pass_choice_menu
	test(is_instance_valid(menu) and menu.visible,"Redraw opens live choice with selected ordinary Pass "+str(phase_name))
	if not is_instance_valid(menu):phase.queue_free();await frames();return
	test(menu.preview.card_data.id==menu.selected.target_id and menu.options.get_child_count()>0,"Actual selected Pass preview and alternatives")
	test(Rect2(Vector2.ZERO,Vector2(dimensions)).encloses(menu.panel.get_global_rect()),"Pass choice fits viewport")
	await shot("alignment-%s-%d"%[phase_name,dimensions.x])
	var before:=[run.get_cash_cents(),run.get_completed_run_cycles(),run.get_available_redraws(),run.random_streams.snapshot(),phase._candidate_cards.duplicate()]
	await key(menu.back_button,KEY_ESCAPE)
	test(not menu.visible and [run.get_cash_cents(),run.get_completed_run_cycles(),run.get_available_redraws(),run.random_streams.snapshot(),phase._candidate_cards.duplicate()]==before,"Escape preview is passive")
	await click(phase.get_node("%RedrawButton"));await create_timer(0.3).timeout
	var target: StringName=menu.selected.target_id
	await key(menu.confirm_button)
	test(not menu.visible and phase._candidate_cards[0].id==target and phase._candidate_cards[1].id==&"graphics_pass" and run.get_available_redraws()==3,"Keyboard replacement changes one duplicate slot and spends one redraw")
	test(run.random_streams.snapshot()==before[3] and run.get_completed_run_cycles()==before[1],"Live alignment preserves RNG and time")
	views=phase.get_node("%HandContainer").card_views();phase._on_card_pressed(views[1]);await click(phase.get_node("%RedrawButton"));await create_timer(0.3).timeout
	if menu.visible:
		phase._command_revision+=1
		await key(menu.confirm_button)
		test(menu.visible and menu.confirm_button.disabled and run.get_available_redraws()==3,"Stale live quote explains rejection without debit")
		await key(menu.back_button)
	await click(phase.get_node("%RedrawButton"));await create_timer(0.3).timeout
	if menu.visible:await click(menu.ordinary_button)
	test(not menu.visible and run.get_available_redraws()==2,"Reopened ordinary redraw option works after stale choice")
	if phase_name==&"alpha":
		views=phase.get_node("%HandContainer").card_views();var state: RefCounted=phase._capture_development_actions().hand
		phase._command_injected_ids.assign([state.candidate_ids[3]])
		phase._on_card_pressed(views[3])
		test(not phase._can_redraw_selection(),"Live injected Alpha Pass remains protected")
	phase.queue_free();await frames()
