extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	print(("PASS: " if ok else "FAIL: ") + label)
	if not ok: failures += 1
func _initialize() -> void: verify.call_deferred()
func frames(n := 3) -> void:
	for i in n: await process_frame
func verify() -> void:
	await process_frame
	var catalog = root.get_node("CardDatabase").get_development_catalog()
	var run: RunState = load("res://scripts/debug/employee_test_actions.gd").fresh_two_releases(catalog)
	check(run.hire_specialist(run.get_employee_hire_quote(&"project_manager")),"Real Manager hire succeeds")
	var manager: Dictionary=run.get_employees().employees.values().filter(func(e):return e.type==&"project_manager")[0]
	check(run.purchase_employee_course(run.get_employee_course_quote(manager.employee_id,&"manager_1")),"Real Manager 1 enrollment succeeds")
	var panel := EmployeePanel.new()
	root.add_child(panel);panel.open_for(run);await frames()
	var inspector_style: StyleBoxFlat = panel.course_grid.popup.get_theme_stylebox("panel")
	check(inspector_style != null and is_equal_approx(inspector_style.bg_color.a, 1.0), "Course inspector is opaque to block tree text")
	var main_style: StyleBoxFlat = panel.panel.get_theme_stylebox("panel")
	check(main_style != null and main_style.bg_color.a < 1.0, "Main employee panel retains translucent background")
	var courses := {&"production":[&"production_planning",&"pass_alignment"], &"qa":[&"mixed",&"pure"], &"project_manager":[&"manager_1",&"manager_2",&"manager_3",&"manager_4"]}
	for dimensions: Vector2i in [Vector2i(900,600),Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=dimensions;root.content_scale_size=dimensions;await frames()
		for role: StringName in courses:
			panel.open_courses(role);await frames()
			for course: StringName in courses[role]:
				panel.course_grid.inspect(course);await frames()
				check(not panel.challenge_heading.visible and panel.challenge_label.visible and not panel.challenge_label.text.is_empty(),"Challenge copy is visible without a repeated heading: %s at %s"%[course,dimensions])
				if course==&"manager_1":check(panel.challenge_label.text=="Play 2 specialty hands under the category with the lowest priority, 4 times", "Project Management 1 uses the requested wording")
				var challenge_scroll: VScrollBar=panel.course_grid.details_scroll.get_v_scroll_bar()
				check(challenge_scroll.max_value<=challenge_scroll.page+0.01,"Challenge fits without scrolling: %s at %s"%[course,dimensions])
				check(root.get_visible_rect().encloses(panel.course_grid.popup.get_global_rect()),"Inspector stays in the viewport: %s at %s"%[course,dimensions])
				check(panel.course_grid.details_scroll.get_global_rect().encloses(panel.challenge_label.get_global_rect()),"Challenge text stays inside its visible area: %s at %s"%[course,dimensions])
				if DisplayServer.get_name()!="headless" and not OS.get_environment("PN_COURSE_CAPTURE").is_empty() and course==&"manager_1":
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png(OS.get_environment("PN_COURSE_CAPTURE").path_join("%s-challenge-%d.png"%[course,dimensions.x]))
				panel.course_view_switch.value=1;await frames()
				var reward:=panel.challenge_label.text.to_lower()
				check(not panel.challenge_heading.visible and not reward.contains("permanent benefit") and not reward.contains("completion adds") and not reward.contains("enrollment gives"),"Reward is concise without repeated heading or wage boilerplate: %s"%course)
				var scrollbar: VScrollBar=panel.course_grid.details_scroll.get_v_scroll_bar()
				check(scrollbar.max_value<=scrollbar.page+0.01,"Course description does not need scrolling: %s at %s"%[course,dimensions])
				check(panel.course_grid.details_scroll.get_global_rect().encloses(panel.challenge_label.get_global_rect()),"Reward text stays inside its visible area: %s at %s"%[course,dimensions])
				if DisplayServer.get_name()!="headless" and not OS.get_environment("PN_COURSE_CAPTURE").is_empty() and course==&"manager_1":
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png(OS.get_environment("PN_COURSE_CAPTURE").path_join("%s-reward-%d.png"%[course,dimensions.x]))
				panel.course_view_switch.value=0;panel.course_grid.close_details();await frames()
	panel.queue_free();await frames()
	print("EMPLOYEE_PLAIN_COURSES checks=%d failures=%d"%[checks,failures]);quit(failures)
