extends SceneTree

var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ",message)
	if not ok: failures += 1

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for dimensions in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		var game := load("res://scenes/gameplay.tscn").instantiate() as Control
		game.project_state = ProjectState.new(30)
		root.add_child(game)
		for i in 5: await process_frame
		var project: ProjectState = game.get("project_state")
		var run_state: RunState = game.get("run_state")
		var hud: GameplayHUD = game.get_node("%GameplayHUD")
		for title in ["Design","Alpha","Beta"]:
			var phase: Control = game.get("_active_phase")
			var workspace: PhaseWorkspace = phase.get_workspace()
			check(workspace.find_child("PlayedHand",true,false) == null,title + ": Played Hand panel is absent")
			check(workspace.find_child("SelectionSummary",true,false) == null,title + ": Played Hand summary is absent")
			check(workspace.find_child("SynergyHelpButton",true,false) == null,title + ": Synergy button is absent")
			check(workspace.employee_plan_button != null if title != "Beta" else workspace.employee_plan_button == null,title + ": appropriate Specialist plan control")
			check(workspace.overlay.commit_draft(),title + ": priorities initialize")
			hud.contextual_tip.dismiss()
			hud.tutorial_overlay.close()
			await create_timer(1.0).timeout
			var fan: CardFan = phase.get_node("%HandContainer")
			var views := fan.card_views()
			check(views.size() >= 4,title + ": real draw pool is available")
			if views.size() < 4: quit(1);return
			var pointer_card: CardView = views[-1]
			var local := pointer_card.get_transform() * (pointer_card.size * Vector2(0.5,0.5))
			var point := fan.get_global_transform_with_canvas() * local
			check(fan.card_at(local)==pointer_card,title + ": pointer target is inside the rendered card")
			var move := InputEventMouseMotion.new();move.position=point;move.global_position=point;root.push_input(move,true)
			await process_frame
			for down in [true,false]:
				var click := InputEventMouseButton.new();click.position=point;click.global_position=point;click.button_index=MOUSE_BUTTON_LEFT;click.pressed=down;root.push_input(click,true)
				await process_frame
			check(pointer_card in phase.get_selected_candidate_views(),title + ": pointer selects a real card")
			for view: CardView in views.slice(0,3):view.input_button.pressed.emit()
			check(phase.get_selected_candidate_views().size() == 4,title + ": four cards can be selected")
			check(not workspace.get_node("Regions/PoolHeader").get_global_rect().intersects(hud.get_node("PersistentHeader").get_global_rect()),title + ": pool header does not overlap the HUD")
			var capture := OS.get_environment("PN_PLAYED_HAND_CAPTURE")
			if not capture.is_empty() and DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(capture.path_join("%s-%d.png" % [title.to_lower(),dimensions.x]))
			var before := run_state.get_completed_run_cycles()
			var play_name: String = {"Design":"PlayCardButton","Alpha":"PlayAlphaHandButton","Beta":"PlayHandButton"}[title]
			phase.get_node("%"+play_name).pressed.emit()
			check(run_state.get_completed_run_cycles() == before+1,title + ": selected hand commits one productive cycle")
			var deadline := Time.get_ticks_msec()+16000
			while workspace.hand_motion.busy and Time.get_ticks_msec()<deadline:await process_frame
			check(not workspace.hand_motion.busy,title + ": hand presentation completes")
			if title == "Design":
				phase.get_node("%ProceedToAlphaButton").pressed.emit()
			elif title == "Alpha":
				project.add_scope(30)
				check(phase.call("_finalize_alpha",0.0,0.5),"Alpha transitions through its existing finalizer")
			for i in 5: await process_frame
		game.queue_free()
		for i in 3: await process_frame
	print("PLAYED_HAND_REMOVAL checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)
