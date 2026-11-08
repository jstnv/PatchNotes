extends SceneTree

var failures := 0
var checks := 0

func check(value: bool, name: String) -> void:
	checks += 1
	print(("PASS " if value else "FAIL ") + name)
	if not value: failures += 1

func _initialize() -> void: run_test.call_deferred()

func label_bounds(label: Control) -> Rect2:
	var t := label.get_global_transform_with_canvas()
	var bounds := Rect2(t * Vector2.ZERO, Vector2.ZERO)
	bounds = bounds.expand(t * Vector2(label.size.x, 0))
	bounds = bounds.expand(t * label.size)
	return bounds.expand(t * Vector2(0, label.size.y))

func run_test() -> void:
	var size := Vector2i(900, 600) if OS.get_environment("PN_TIP_SMALL") == "1" else Vector2i(1280, 720)
	root.size = size
	root.content_scale_size = size
	var run := RunState.new()
	check(run.initialize_cash(0) and run.create_studio_with_traits("Tip test", &"action", []), "Initialized isolated Studio")
	var game = load("res://scenes/gameplay.tscn").instantiate()
	game.run_state = run
	game.project_state = ProjectState.new(30)
	root.add_child(game)
	for i in 8: await process_frame
	if DisplayServer.get_name() != "headless":
		# The game normally enforces 1152x648 as a window minimum. Override that
		# in this private test only to inspect the requested 900x600 surface.
		root.min_size = Vector2i.ZERO
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(size)
		for i in 10: await process_frame
		check(DisplayServer.window_get_size() == size, "Native window matches requested dimensions")
	print("TIP_VIEWPORT actual_window=",DisplayServer.window_get_size()," visible=",root.get_visible_rect().size," render=",root.get_texture().get_size())
	var hud = game.get_node("%GameplayHUD")
	check(game._active_phase is DesignPhase and game._active_phase.get_workspace().overlay.commit_draft(), "Real Design hand opened")
	await create_timer(1.0).timeout
	var pending_before: Dictionary = run.get_studio_notice_state()
	var cash_before: int = run.get_cash_cents()
	var cycle_before: int = run.get_completed_run_cycles()
	check(not hud.tip_button.disabled, "Tip button enabled")
	hud.tip_button.pressed.emit()
	await create_timer(0.2).timeout
	check(hud.contextual_tip.panel.visible, "Explicit Tip immediately appears in Production")
	check(run.get_studio_notice_state() == pending_before, "Manual Tip does not change automatic notice queue")
	check(run.get_cash_cents() == cash_before and run.get_completed_run_cycles() == cycle_before, "Manual Tip does not change finance or cycle")
	if not hud.contextual_tip.panel.visible:
		var tip: Dictionary = hud._guidance_for_current_state()
		hud.contextual_tip.show_tip(tip.title, tip.body)
		await process_frame
	var rect: Rect2 = hud.contextual_tip.panel.get_global_rect()
	check(not rect.intersects(hud.scoreboard.get_global_rect()) and not rect.intersects(hud.footer_panel.get_global_rect()), "Tip clears persistent HUD")
	for c in game._active_phase.get_node("%HandContainer").get_children():
		if c is CardView: check(not rect.intersects(label_bounds(c.card_name_label)), "Tip clears card title " + c.name)
	var fan: CardFan = game._active_phase.get_node("%HandContainer")
	var last: CardView = fan.ordered_cards().back()
	last.card_pressed.emit(last)
	await create_timer(0.25).timeout
	check(last.is_selected(), "Card selection still works while the tip is open")
	var moving_clear := true
	for i in 40:
		await create_timer(0.1).timeout
		var active: Rect2 = hud.contextual_tip.panel.get_global_rect()
		if active.intersects(hud.scoreboard.get_global_rect()) or active.intersects(hud.footer_panel.get_global_rect()): moving_clear = false
		for c: CardView in fan.ordered_cards():
			if active.intersects(label_bounds(c.card_name_label)): moving_clear = false
	check(moving_clear, "Tip clears HUD and moving card titles through a complete fan wave")
	var long_body := "With a Feature, positive hand Core gains qualify if highest minus lowest is at most 1 point, or each is within ±15% of the average. Boost the Core total ×1.25, round down, then share it evenly after playing. Spare points follow Graphics, Sound, Technology, Design. Scope stays printed."
	hud.contextual_tip.show_tip("Balanced Production ready", long_body)
	await create_timer(0.2).timeout
	var long_rect: Rect2 = hud.contextual_tip.panel.get_global_rect()
	var long_clear := not long_rect.intersects(hud.scoreboard.get_global_rect()) and not long_rect.intersects(hud.footer_panel.get_global_rect())
	for c: CardView in fan.ordered_cards():
		if long_rect.intersects(label_bounds(c.card_name_label)): long_clear = false
	check(long_clear, "Longest Production help clears card titles and HUD")
	check(hud.contextual_tip.body_label.get_visible_line_count() >= hud.contextual_tip.body_label.get_line_count(), "Long help text is fully visible")
	var candidate_card: CardView = fan.ordered_cards()[0]
	var point: Vector2 = candidate_card.get_global_transform_with_canvas() * Vector2(candidate_card.size.x * 0.1, candidate_card.size.y * 0.45)
	var fan_point: Vector2 = fan.get_global_transform_with_canvas().affine_inverse() * point
	var routed: CardView = fan.card_at(fan_point)
	if routed != null and not hud.contextual_tip.dismiss_button.get_global_rect().has_point(point):
		var was_selected := routed.is_selected()
		var down := InputEventMouseButton.new(); down.button_index = MOUSE_BUTTON_LEFT; down.position = point; down.global_position = point; down.pressed = true
		var up := InputEventMouseButton.new(); up.button_index = MOUSE_BUTTON_LEFT; up.position = point; up.global_position = point; up.pressed = false
		root.push_input(down, true); root.push_input(up, true)
		await process_frame
		check(routed.is_selected() != was_selected, "Viewport pointer can select an exposed card with Tip open")
	else:
		check(false, "Viewport pointer has an exposed card target")
	var pending_after_selection: Dictionary = run.get_studio_notice_state()
	if not OS.get_environment("PN_TIP_CAPTURE").is_empty() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("PN_TIP_CAPTURE"))
	hud.contextual_tip.dismiss_button.pressed.emit()
	check(not hud.contextual_tip.panel.visible, "Tip stays dismissible")
	check(run.get_studio_notice_state() == pending_after_selection, "Dismissal preserves queued notifications")
	game.pause_menu.open()
	check(paused and game.pause_menu.layer > hud.contextual_tip.layer, "Pause owns input above the tip layer")
	hud.show_current_tip()
	check(not hud.contextual_tip.panel.visible, "Paused Production cannot reopen the tip behind the pause menu")
	game.pause_menu.close()
	await create_timer(0.4, true).timeout
	check(not paused, "Resume restores normal input")
	var overlay = game._active_phase.get_workspace().overlay
	check(game._active_phase.open_priority_overlay(), "Priority modal opens")
	hud.show_current_tip()
	check(not hud.contextual_tip.panel.visible, "Priority modal cannot open an underlying tip")
	check(run.get_studio_notice_state() == pending_after_selection, "Modal and pause checks preserve notice queue")
	overlay.cancel()
	var design = game._active_phase
	game.project_state.add_scope(30)
	design._exhausted_card_ids[&"text"] = true
	design.get_node("%ProceedToAlphaButton").pressed.emit()
	for i in 6: await process_frame
	check(game._active_phase is AlphaPhase, "Design transitions to Alpha")
	if game._active_phase is AlphaPhase:
		var alpha = game._active_phase
		check(alpha.get_workspace().overlay.commit_draft(), "Alpha hand opens")
		await create_timer(0.2).timeout
		hud.show_current_tip()
		await create_timer(0.2).timeout
		check(hud.contextual_tip.panel.visible, "Explicit Alpha Tip is immediate")
		hud.contextual_tip.dismiss()
		check(alpha._finalize_alpha(0.0, 0.5), "Alpha finalizes")
		for i in 6: await process_frame
		check(game._active_phase is BetaPhase, "Alpha transitions to Beta")
		if game._active_phase is BetaPhase:
			var beta = game._active_phase
			check(beta.get_workspace().overlay.commit_draft(), "Beta hand opens")
			await create_timer(0.2).timeout
			hud.show_current_tip()
			await create_timer(0.2).timeout
			check(hud.contextual_tip.panel.visible, "Explicit Beta Tip is immediate")
			hud.contextual_tip.dismiss()
	print("TIP_TEST size=",size," tip=",rect," checks=",checks," failures=",failures)
	game.free()
	quit(0 if failures == 0 else 1)
