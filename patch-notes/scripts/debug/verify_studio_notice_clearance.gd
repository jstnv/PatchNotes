extends SceneTree

var failures := 0
var checks := 0
var snapshots := PrimitiveSnapshotDatabase.new()

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, description: String) -> void:
	checks += 1
	print(("PASS: " if condition else "FAIL: ") + description)
	if not condition: failures += 1

func click(point: Vector2) -> void:
	var move := InputEventMouseMotion.new()
	move.position = point
	move.global_position = point
	root.push_input(move, true)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)

func effective_z(item: CanvasItem) -> int:
	var total := 0
	var cursor: Node = item
	while cursor is CanvasItem:
		total += cursor.z_index
		if not cursor.z_as_relative: break
		cursor = cursor.get_parent()
	return total

func make_release() -> ProjectState:
	var project := ProjectState.new(30)
	project.initialize_snapshots(&"fast_follower", &"stable_market")
	project.add_scope(30)
	project.add_marketing_output(24)
	project.finalize_design_bugs(false, 0, [&"text"], [])
	project.finalize_alpha(0, [], [])
	project.finalize_beta()
	project.commit_review_result(ReviewResult.new(PrimitiveReviewCalculator.get_baseline_profile(), {}, 0.0, 0.0, 0.0, 6.9, 1.0, 0, 0.0, 1.0, 50, 0.0, 6.9, 6.9))
	project.commit_awareness_result(PrimitiveAwarenessCalculator.calculate(project))
	project.commit_launch_market_context_result(PrimitiveLaunchMarketContextCalculator.calculate(project, snapshots))
	project.commit_units_sold_result(PrimitiveUnitsSoldCalculator.calculate(project))
	project.commit_month_one_sales_revenue_result(PrimitiveMonthOneSalesRevenueCalculator.calculate(project))
	return project

func _run() -> void:
	snapshots.load_ledgers()
	root.size = Vector2i(1152,648)
	var run := RunState.new()
	run.initialize_cash_cents(0)
	var studio := load("res://scenes/phases/studio_phase.tscn").instantiate() as StudioPhase
	check(studio.setup(make_release(), run, snapshots), "First release enters Studio")
	root.add_child(studio)
	for frame in 4: await process_frame
	var notice: PanelContainer = studio._publisher_notice
	check(is_instance_valid(notice) and notice.is_visible_in_tree(), "Publisher notification is shown")
	if not is_instance_valid(notice):
		quit(failures + 1)
		return
	var message := notice.find_child("PublisherUnlockMessage", true, false) as Label
	var dismiss := notice.find_child("DismissPublisherNotice", true, false) as Button
	for viewport_size in [Vector2i(900,600), Vector2i(1152,648), Vector2i(1920,1080)]:
		root.size = viewport_size
		for frame in 4: await process_frame
		var root_rect: Rect2 = studio._hub._root_panel.get_global_rect()
		var notice_rect: Rect2 = notice.get_global_rect()
		var viewport_rect := root.get_visible_rect()
		print("NOTICE_GEOMETRY viewport=%s visible=%s studio=%s hub=%s root=%s notice=%s text=%s dismiss=%s" % [viewport_size, root.get_visible_rect(), studio.get_global_rect(), studio._hub.get_global_rect(), root_rect, notice_rect, message.get_global_rect(), dismiss.get_global_rect()])
		check(not root_rect.intersects(notice_rect), "Notice clears Studio panel at %s" % viewport_size)
		check(viewport_rect.encloses(notice_rect), "Entire notice fits the viewport at %s" % viewport_size)
		check(notice_rect.encloses(message.get_global_rect()) and notice_rect.encloses(dismiss.get_global_rect()), "Notice text and dismiss button fit at %s" % viewport_size)
	root.size = Vector2i(900,600)
	message.text = "Publisher unlocked: Ironclad Interactive, Crown & Quill Software, Neon Circuit, SideStreet Games, Starwave"
	for frame in 4: await process_frame
	check(root.get_visible_rect().encloses(notice.get_global_rect()), "Multi-publisher notice fits narrow viewport")
	check(notice.get_global_rect().encloses(message.get_global_rect()) and message.get_visible_line_count() >= message.get_line_count(), "All wrapped publisher names remain visible")
	check(not notice.get_global_rect().intersects(studio._hub._root_panel.get_global_rect()), "Multi-publisher notice clears Studio panel")
	message.text = "Publisher unlocked: Ironclad Interactive"
	root.size = Vector2i(1152,648)
	for frame in 3: await process_frame
	var before := [run.get_cash_cents(), run.get_completed_run_cycles()]
	click(dismiss.get_global_rect().get_center())
	await process_frame
	check(not notice.visible, "Pointer dismisses notification with no selected menu")
	notice.show()
	studio._hub.select_group(&"studio_info")
	studio._hub.settle_motion()
	for frame in 3: await process_frame
	check(studio._hub._companion.is_visible_in_tree(), "Selected Studio menu is visible")
	var companion: Control = studio._hub._companion
	var overlaps := notice.get_global_rect().intersects(companion.get_global_rect())
	var on_top := effective_z(notice) > effective_z(companion) or (effective_z(notice) == effective_z(companion) and notice.is_greater_than(companion))
	check(not overlaps or on_top, "Notification is drawn over the selected companion when they overlap")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("user://studio-notice-selected.png") == OK, "Selected menu screenshot saved")
	# If the notice is geometrically covered by the companion, actual pointer
	# hit-testing must still reach Dismiss; lower-drawn notices cannot do so.
	click(dismiss.get_global_rect().get_center())
	await process_frame
	check(not notice.visible, "Pointer dismisses notification above selected Studio menu")
	check(before == [run.get_cash_cents(), run.get_completed_run_cycles()], "Dismiss is presentation only")
	studio.queue_free()
	await process_frame
	print("STUDIO_NOTICE_CLEARANCE checks=%d failures=%d" % [checks, failures])
	quit(failures)
