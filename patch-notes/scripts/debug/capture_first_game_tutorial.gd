extends SceneTree

# Run with the compatibility renderer, without --headless. This drives actual
# scene signals and action handlers, then captures rendered frames. It does not
# represent native mouse/keyboard playtesting. The six-feature starter route
# intentionally uses the existing low-Scope opt-in start callback.
var folder := ProjectSettings.globalize_path("res://design-logs/first-game-tutorial-v1")
var failures := 0

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func capture(name: String, hud: GameplayHUD, phase: DesignPhase) -> void:
	for settle in range(8): await process_frame
	await RenderingServer.frame_post_draw
	var path := folder.path_join(name + ".png")
	var error := root.get_texture().get_image().save_png(path)
	check(error == OK, name + ": viewport PNG saved")
	var priority := phase.get_workspace().overlay
	if priority.visible:
		var rect := priority.dialog.get_global_rect()
		check(rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= root.size.x and rect.end.y <= priority.shade.get_global_rect().end.y, name + ": priority explanation fits above the footer")
	if hud.contextual_tip.panel.visible:
		var rect := hud.contextual_tip.panel.get_global_rect()
		check(rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= root.size.x and rect.end.y <= root.size.y, name + ": contextual tip fits the viewport")
	print("CAPTURE ", path, " result=", error, " viewport=", root.size)
	print("LAYOUT ", name, " phase=", phase.get_global_rect(), " priority=", phase.get_workspace().overlay.dialog.get_global_rect(), " tip=", hud.contextual_tip.panel.get_global_rect(), " tip_visible=", hud.contextual_tip.panel.visible)

func select_core(phase: DesignPhase, stat: StringName) -> void:
	phase.call("_clear_selection")
	for view: CardView in phase.get_node("%HandContainer").get_children():
		if view.card_data.primary_stat == stat and phase.get_selected_candidate_views().size() < 4:
			view.card_pressed.emit(view)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(folder)
	for viewport_size: Vector2i in [Vector2i(1152, 648), Vector2i(900, 600)]:
		root.size = viewport_size
		root.content_scale_size = viewport_size
		var game: Control = load("res://scenes/gameplay.tscn").instantiate()
		root.add_child(game)
		await process_frame
		root.size = viewport_size
		root.content_scale_size = viewport_size
		var main: MainMenu = game.get("_active_phase")
		main.get_node("CenterContainer/MenuLayout/StartGame").pressed.emit()
		main._name_input.text = "First Steps Studio"
		main.get_node("CenterContainer/MenuLayout/StudioSetup/StudioSpecialty").select(1)
		main.get_node("CenterContainer/MenuLayout/StudioSetup/EnterStudio").pressed.emit()
		main.call("_show_review")
		main.call("_confirm_studio")
		var studio: Control = game.get("_active_phase")
		if not game.call("_begin_next_project", studio, "Learning the Ropes", &"action", &"fantasy"):
			push_error("Real first project did not start")
			quit(1)
			return
		var phase := game.get("_active_phase") as DesignPhase
		var hud := game.get_node("%GameplayHUD") as GameplayHUD
		var rng: RandomNumberGenerator = phase.get("_deal_rng")
		rng.seed = 408
		phase.get_node("%GraphicsPriority").value = 20
		phase.get_node("%SoundPriority").value = 40
		phase.get_node("%TechnologyPriority").value = 20
		phase.get_node("%DesignPriority").value = 20
		var suffix := "%dx%d" % [viewport_size.x, viewport_size.y]
		await capture(suffix + "_1_core_scope_priorities", hud, phase)
		if not phase.get_workspace().overlay.commit_draft():
			push_error("Priority confirmation failed")
			quit(1)
			return
		await capture(suffix + "_2_sound_specialization_available", hud, phase)
		var tutorial: FirstGameTutorial = game.run_state.get_first_game_tutorial(game.project_state)
		select_core(phase, tutorial.first_stat)
		await capture(suffix + "_3_sound_specialization_selected", hud, phase)
		phase.get_node("%PlayCardButton").pressed.emit()
		await capture(suffix + "_4_one_card_away", hud, phase)
		phase.call("_clear_selection")
		for view: CardView in phase.get_node("%HandContainer").get_children():
			if view.card_data.primary_stat != tutorial.second_stat:
				view.card_pressed.emit(view)
				break
		await capture(suffix + "_5_redraw_selected", hud, phase)
		if not phase.redraw_selected_cards():
			push_error("Tutorial redraw failed")
			quit(1)
			return
		await capture(suffix + "_6_redraw_completed", hud, phase)
		select_core(phase, tutorial.second_stat)
		await capture(suffix + "_7_second_specialization_selected", hud, phase)
		game.queue_free()
		await process_frame
	print("Known existing layout limitation: at 900x600 the 1008px-wide production workspace extends beyond both viewport sides. This probe checks the new tutorial surfaces separately.")
	print("Rendered first-game tutorial capture completed: %d failures" % failures)
	quit(0 if failures == 0 else 1)
