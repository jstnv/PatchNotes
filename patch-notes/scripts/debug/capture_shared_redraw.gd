extends SceneTree

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1152, 648)
	var folder := OS.get_environment("TEMP").path_join("patchnotes-redraw-visual")
	DirAccess.make_dir_recursive_absolute(folder)
	for name: String in ["design", "alpha", "beta"]:
		var game := load("res://scenes/gameplay.tscn").instantiate() as Control
		game.project_state = ProjectState.new(30) # Existing-project fixture; first-run setup is tested separately.
		root.add_child(game)
		game.get_node("%GameplayHUD").tutorial_overlay.close()
		var holder := game.get_node("%PhaseRoot")
		var phase: Control = game.get("_active_phase")
		if phase.get_workspace().overlay.visible:
			phase.get_workspace().overlay.cancel()
		if name != "design":
			holder.remove_child(phase)
			phase.free()
			phase = load("res://scenes/phases/%s_phase.tscn" % name).instantiate()
			holder.add_child(phase)
			var project: ProjectState = game.get("project_state")
			if name == "beta":
				project.finalize_design_bugs(false, 0, [], [])
				project.finalize_alpha(0, [], [])
				phase.call("setup", project, game.get("run_state"), game.call("get_snapshot_database"))
			else:
				phase.call("setup", project, game.get("run_state"))
		phase.call("begin_" + name)
		for state: String in ["disabled", "enabled"]:
			if state == "enabled":
				var view := phase.get_node("%HandContainer").get_child(0) as CardView
				view.card_pressed.emit(view)
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(folder.path_join(name + "_" + state + ".png"))
		game.queue_free()
		await process_frame
	quit()
