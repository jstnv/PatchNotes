extends "res://scripts/debug/verify_main_menu_history.gd"

func _run() -> void:
	for dimensions in [Vector2i(1280,720),Vector2i(1152,648)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		var run := RunState.new()
		run.initialize_cash(0)
		run.create_studio_with_traits("Review bounds",&"action",[])
		run.finalize_starter_selection()
		var project := PrimitivePredevelopment.prepare_project("Review fixture",&"action",&"fantasy",run)
		_finish_project(project)
		var snapshots := PrimitiveSnapshotDatabase.new()
		snapshots.load_ledgers()
		var game: Control = load("res://scenes/gameplay.tscn").instantiate()
		game.run_state = run
		root.add_child(game)
		var studio: StudioPhase = game._active_phase
		expect(studio.setup(project,run,snapshots),"Studio setup")
		studio.open_launch_review()
		await create_timer(0.3).timeout
		var review: Control = studio._review_view
		for path in ["Margin","Margin/Layout","Margin/Layout/Title","Margin/Layout/Categories","Margin/Layout/Footer/ContinueButton"]:
			var control: Control = review.get_node(path)
			print(dimensions," ",path," ",control.get_global_rect()," visible=",control.is_visible_in_tree())
			expect(game.get_node("%PhaseRoot").get_global_rect().encloses(control.get_global_rect()),"Review control fits: "+path)
		game.queue_free()
		await process_frame
	quit(0 if failures==0 else 1)
