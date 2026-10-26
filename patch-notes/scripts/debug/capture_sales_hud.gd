extends "res://scripts/debug/verify_sales_revenue_hud.gd"

func _initialize() -> void:
	await process_frame
	if DisplayServer.get_name() == "headless": quit(2); return
	create_timer(90).timeout.connect(func(): push_error("Sales HUD capture timeout"); quit(2))
	var run := fixture_run()
	release_fixture(run,"First release")
	for i in range(5): expect(run.complete_productive_action(),"Capture sales cycle")
	release_fixture(run,"Second release")
	for i in range(2): expect(run.complete_productive_action(),"Concurrent capture sales cycle")
	var adapter := StudioCheckpoint.new()
	var payload := adapter.capture(run)
	for resolution in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size = resolution
		root.content_scale_size = resolution
		for mode in ["studio","design","alpha","beta","contract"]:
			var fixture := adapter.hydrate(payload)
			expect(fixture != null,"Graphical fixture restored")
			if fixture == null: quit(1); return
			var game: Control = load("res://scenes/gameplay.tscn").instantiate()
			game.run_state = fixture
			root.add_child(game)
			var hud: GameplayHUD = game.get_node("%GameplayHUD")
			await settle()
			# Settings startup applies its saved default size; resize after that.
			root.size = resolution
			await settle()
			if mode == "contract":
				var contract := fixture.accept_primitive_contract()
				expect(contract != null,"Contract fixture accepts")
				game._on_contract_requested(game._active_phase,contract)
			elif mode != "studio":
				expect(game._begin_next_project(game._active_phase,"Next project",&"action",&"fantasy"),"Development fixture starts")
				var phase: Control = game._active_phase
				if mode != "design":
					var holder: Control = game.get_node("%PhaseRoot")
					holder.remove_child(phase)
					phase.queue_free()
					phase = load("res://scenes/phases/%s_phase.tscn" % mode).instantiate()
					var project: ProjectState = game.project_state
					project.finalize_design_bugs(false,0,[&"text"],[])
					if mode == "beta": project.finalize_alpha(0,[],[])
					holder.add_child(phase)
					if mode == "beta": phase.setup(project,fixture,game.get_snapshot_database())
					else: phase.setup(project,fixture)
					game._active_phase = phase
					hud.set_phase(phase)
				expect(phase.get_workspace().overlay.commit_draft(),"Production fixture begins")
				await settle()
				for i in range(4):
					var card: CardView = phase.get_node("%HandContainer").get_child(i)
					card.card_pressed.emit(card)
			hud.tutorial_overlay.close()
			hud.contextual_tip.dismiss()
			await create_timer(0.8).timeout
			await capture(game,mode,resolution)
			if mode == "studio":
				var studio: StudioPhase = game._active_phase
				studio.open_summary()
				await settle()
				await capture(game,"summary",resolution)
				studio.open_detailed_review()
				await settle()
				await capture(game,"review",resolution)
				studio._review_view.get_node("%ContinueButton").pressed.emit()
				studio.close_summary()
			var before := hud.sales_hud.model.duplicate(true)
			hud.show_settings()
			hud.settings_menu.close()
			expect(hud.sales_hud.model == before,"Settings navigation preserves series")
			game.queue_free()
			await settle()
	print("SALES_HUD_RENDER checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)

func capture(game: Control,mode: String,resolution: Vector2i) -> void:
	await RenderingServer.frame_post_draw
	var hud: GameplayHUD = game.get_node("%GameplayHUD")
	var graph := hud.sales_hud.get_global_rect()
	var viewport := Rect2(Vector2.ZERO,Vector2(resolution))
	expect(hud.sales_hud.visible and viewport.encloses(graph),mode+": sales HUD fits viewport")
	var phase_root: Control = game.get_node("%PhaseRoot")
	expect(not graph.intersects(phase_root.get_global_rect()),mode+": reserved graph corner never overlaps phase views")
	var header: Control = hud.get_node("PersistentHeader")
	expect(header.visible and header.get_global_rect().encloses(graph),mode+": chart belongs inside the existing top HUD")
	expect(hud.sales_hud.get_parent() == header.get_child(0) and hud.sales_hud.get_theme_stylebox("panel") is StyleBoxEmpty,mode+": chart has no separate framed panel")
	if header.visible:
		if mode in ["design","alpha","beta"]:
			for label: Label in hud.stats:
				expect(header.get_global_rect().encloses(label.get_global_rect()),mode+": score label fits remaining header")
			expect(header.get_global_rect().encloses(hud.change_priorities.get_global_rect()),mode+": priority button fits")
	if mode == "contract":
		expect(viewport.encloses(game._active_phase._play_button.get_global_rect()),"Contract Play remains visible")
		expect(game._active_phase._play_button.get_global_rect().end.y <= hud.footer_panel.get_global_rect().position.y,"Contract actions clear footer")
	if mode in ["design","alpha","beta"]:
		var workspace: PhaseWorkspace = game._active_phase.get_workspace()
		expect(workspace.get_node("Regions/ContextAndPhase/ActionRow").get_global_rect().end.y <= hud.footer_panel.get_global_rect().position.y,"Development actions clear footer")
	var path := OS.get_environment("PN_SALES_HUD_CAPTURE").path_join("%s-%dx%d.png" % [mode,resolution.x,resolution.y])
	var screenshot := root.get_texture().get_image()
	expect(screenshot.get_size() == resolution,"Capture has requested native pixel dimensions")
	expect(screenshot.save_png(path) == OK,"Capture "+path)
