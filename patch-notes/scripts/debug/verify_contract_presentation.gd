extends "res://scripts/debug/verify_balanced_primitive_contract.gd"


func _verify() -> void:
	snapshots.load_ledgers()
	database = root.get_node("CardDatabase")
	for resolution in [Vector2i(1152, 648), Vector2i(1600, 900)]:
		root.size = resolution
		root.content_scale_size = resolution
		var project := release(751)
		var run := new_run()
		var studio := load("res://scenes/phases/studio_phase.tscn").instantiate() as StudioPhase
		root.add_child(studio)
		studio.setup(project, run, snapshots)
		studio.hide()
		RenderingServer.set_default_clear_color(Color("#100608"))
		var state := run.accept_primitive_contract()
		var phase := load("res://scenes/phases/contract_phase.tscn").instantiate() as ContractPhase
		phase.setup(state, run)
		root.add_child(phase)
		phase.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		await process_frame
		await process_frame
		var before := run_snapshot(run, project)
		phase.open_priority_overlay()
		expect(phase.get("_priority_modal").visible and run_snapshot(run, project) == before, "Priority navigation is passive")
		phase.get("_priority_modal").hide()
		var counters: Array = phase.get("_score_values")
		expect(counters[0].text == "Graphics\n0 / 6" and counters[4].text == "Scope\n0 / 12", "Header displays current / required Core and Scope")
		await capture("pool", resolution)
		for hand in range(2):
			_select_first(phase, 4)
			phase.get("_play_button").pressed.emit()
			expect(phase.hand_motion.busy and not phase.get("_completion_modal").visible, "Hand animation starts with completion hidden")
			var timeout := 0
			while phase.hand_motion.busy and timeout < 600:
				await create_timer(0.02).timeout
				timeout += 1
			expect(not phase.hand_motion.busy, "Animated hand finishes without freezing")
			expect(state.get_successful_hand_count() == hand + 1, "Animated action commits exactly once")
			if hand == 0:
				expect(phase.get("_candidate_row").visible and phase.get_selected_candidate_views().is_empty(), "Second pool is visible and selectable")
		await process_frame
		var panel: PanelContainer = phase.get("_completion_panel")
		var rect := panel.get_global_rect()
		expect(phase.get("_completion_modal").visible and not phase.get("_candidate_row").visible, "Completion replaces exhausted hand above gameplay")
		expect(Rect2(Vector2.ZERO, Vector2(resolution)).encloses(rect), "Completion fits viewport at %s" % resolution)
		expect(rect.get_center().distance_to(Vector2(resolution) / 2.0) < 2, "Completion is centered")
		expect(phase.get("_status_label").text.begins_with("Hands remaining: 0 / 2"), "Remaining hands reaches zero")
		await capture("completion", resolution)
		var after := run_snapshot(run, project)
		var dismissed := [false]
		phase.completion_dismissed.connect(func(_phase): dismissed[0] = true)
		(panel.find_child("DismissCompletionButton", true, false) as Button).pressed.emit()
		expect(dismissed[0] and run_snapshot(run, project) == after, "Completion return remains passive and actionable")
		phase.queue_free()
		studio.queue_free()
		await process_frame
	print("Contract presentation verification: %d failures" % failures)
	quit(failures)


func capture(label: String, resolution: Vector2i) -> void:
	if "--capture" not in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://design-logs/contract-ui-v1/%s-%dx%d.png" % [label, resolution.x, resolution.y])
