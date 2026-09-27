extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("_run")

func expect(ok: bool, message: String) -> void:
	if ok: print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func snapshot(run: RunState) -> Array:
	return [run.get_completed_run_cycles(), run.get_cash_cents(), run.get_available_redraws(), run.get_owned_feature_ids(), run.get_released_game_ids()]

func _run() -> void:
	root.size = Vector2i(1152, 648)
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var run: RunState = game.run_state
	var menu: MainMenu = game.get("_active_phase")
	var hud: GameplayHUD = game.get_node("%GameplayHUD")
	var before := snapshot(run)
	expect(game.project_state == null and menu != null and run.get_cash_cents() == 0, "New run waits at main menu without creating a project")
	menu.get_node("CenterContainer/MenuLayout/StartGame").pressed.emit()
	var studio_input: LineEdit = menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioName")
	studio_input.text = "First Studio"
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/EnterStudio").pressed.emit()
	var studio: StudioPhase = game.get("_active_phase")
	expect(studio != null and run.get_studio_name() == "First Studio" and snapshot(run) == before, "Naming studio enters Studio without charging or creating a game")
	studio.get_node("%StartNextGame").pressed.emit()
	var overlay: PredevelopmentOverlay = studio.get("_predevelopment")
	expect(hud.tutorial_overlay.visible and hud.tutorial_context == &"predevelopment", "First game setup presents Pre-Development tips")
	hud.tutorial_overlay.close()
	overlay.name_input.text = "   "
	overlay.begin_button.pressed.emit()
	expect(game.project_state == null and snapshot(run) == before and not overlay.error_label.text.is_empty(), "Missing name rejects without project or time mutation")
	overlay.name_input.text = "First Game"
	overlay.genre_input.select(2)
	overlay.theme_input.select(9)
	overlay.back_button.pressed.emit()
	expect(not overlay.visible and game.project_state == null and snapshot(run) == before, "Cancelling setup is free and does not bypass it")
	studio.get_node("%StartNextGame").pressed.emit()
	expect(overlay.visible and overlay.name_input.text == "First Game" and snapshot(run) == before, "Reopening preserves draft and costs nothing")
	for size: Vector2i in [Vector2i(900, 600), Vector2i(1152, 648)]:
		root.size = size
		await process_frame
		await process_frame
		expect(overlay.begin_button.get_global_rect().end.x <= size.x and overlay.begin_button.get_global_rect().end.y <= hud.footer_panel.get_global_rect().position.y, "Setup fits above the footer at " + str(size))
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://design-logs/first-game-setup.png")
	overlay.begin_button.pressed.emit()
	var project: ProjectState = game.project_state
	expect(project != null and project.get_base_name() == "First Game" and project.get_genre_id() == &"role_playing" and project.get_theme_id() == &"mystery", "First project locks chosen identity")
	expect(run.get_completed_run_cycles() == 1 and project.get_current_cycle() == 0 and run.get_cash_cents() == 0 and run.get_available_redraws() == 4, "Begin costs exactly one run cycle, project zero, no cash, redraw four")
	expect(project.get_feature_supply_ids() == run.get_owned_feature_ids() and project.has_competitor_snapshot() and project.has_market_forecast_snapshot(), "Fresh project uses owned supply and authoritative snapshots")
	var design: DesignPhase = game.get("_active_phase")
	expect(design != null and design.get_workspace().overlay.visible and hud.tutorial_context == &"design" and hud.tutorial_overlay.visible, "Design planning and Design tips follow setup")
	var current := snapshot(run)
	expect(not game.call("_begin_next_project", studio, "Duplicate", &"action", &"fantasy") and snapshot(run) == current, "Stale setup callback cannot charge twice")
	hud.tutorial_overlay.close()
	hud.set_phase(design)
	expect(not hud.tutorial_overlay.visible, "Repeat phase entry does not repeat tips")
	hud.show_tutorial()
	expect(hud.tutorial_overlay.visible and hud.tutorial_overlay.topic == &"design", "Tutorial button reopens current phase guidance")
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://design-logs/design-phase-tips.png")
	for topic: StringName in [&"alpha", &"beta", &"review", &"contract", &"feature_store"]:
		hud.set_tutorial_context(topic)
		expect(hud.tutorial_overlay.visible and hud.tutorial_overlay.topic == topic, "First visit shows relevant " + str(topic) + " tips")
		for i in range(hud.tutorial_overlay.pages.size()): hud.tutorial_overlay.next_page()
		hud.set_tutorial_context(topic)
		expect(not hud.tutorial_overlay.visible and snapshot(run) == current, "Repeat " + str(topic) + " visit is quiet and free")
		hud.show_tutorial()
		expect(hud.tutorial_overlay.topic == topic and snapshot(run) == current, "Manual " + str(topic) + " replay is relevant and free")
	var rebuilt: Control = load("res://scenes/gameplay.tscn").instantiate()
	rebuilt.project_state = project
	rebuilt.run_state = run
	root.add_child(rebuilt)
	await process_frame
	expect(rebuilt.get("_active_phase") is DesignPhase and not rebuilt.get_node("%GameplayHUD").tutorial_overlay.visible and snapshot(run) == current, "Reconstruction retains project and seen tips without charging")
	rebuilt.queue_free()
	game.queue_free()
	await process_frame
	print("First-game and phase-tip verification: %d failures" % failures)
	quit(0 if failures == 0 else 1)
