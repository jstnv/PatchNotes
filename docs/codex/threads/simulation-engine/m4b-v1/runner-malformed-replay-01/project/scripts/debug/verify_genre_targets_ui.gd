extends SceneTree
var failures := 0
func _init() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ",message)
	if not ok: failures+=1
func fits(control: Control, resolution: Vector2i) -> bool:
	var rect:=control.get_global_rect()
	return rect.position.x>=0 and rect.position.y>=0 and rect.end.x<=resolution.x and rect.end.y<=resolution.y
func capture(name: String, resolution: Vector2i) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	var rendered:=root.get_texture().get_image()
	check(rendered.get_size()==resolution,"Rendered pixels match requested resolution")
	rendered.save_png("res://../docs/codex/findings/genre-rating-implementation-v1/%s-%dx%d.png" % [name,resolution.x,resolution.y])
func _run() -> void:
	for resolution: Vector2i in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=resolution
		root.content_scale_size=resolution
		var overlay:=PredevelopmentOverlay.new()
		root.add_child(overlay)
		overlay.open()
		for i in 5: await process_frame
		check(overlay.genre_targets_label.text.contains("Graphics 40") and overlay.genre_targets_label.text.contains("Sound 26"),"Action targets shown before departure")
		overlay.genre_input.select(5)
		overlay.genre_input.item_selected.emit(5)
		for i in 5: await process_frame
		check(overlay.genre_targets_label.text.contains("Technology 40") and overlay.genre_targets_label.text.contains("Design 59"),"Changing Genre updates targets")
		check(fits(overlay.genre_targets_label,resolution) and fits(overlay.begin_button,resolution),"Predevelopment targets and Begin fit "+str(resolution))
		await capture("predevelopment",resolution)
		overlay.queue_free()
		await process_frame
		var run:=RunState.new()
		run.initialize_cash(0)
		run.create_studio_with_traits("Genre UI",&"action",[])
		run.finalize_starter_selection()
		var project:=PrimitivePredevelopment.prepare_project("Puzzle UI",&"puzzle",&"fantasy",run)
		var game: Control=load("res://scenes/gameplay.tscn").instantiate()
		game.run_state=run
		game.project_state=project
		root.add_child(game)
		await process_frame
		# Gameplay applies saved display settings on ready; then set test size.
		root.size=resolution
		root.content_scale_size=resolution
		var phase: DesignPhase=game._active_phase
		phase.get_workspace().overlay.commit_draft()
		await create_timer(3.0).timeout
		var hud: GameplayHUD=game.get_node("%GameplayHUD")
		check(hud.stats[1].text=="Graphics\n0 / 20" and hud.stats[4].text=="Design\n0 / 59","HUD uses project Genre rather than Studio specialty")
		for label in hud.stats: check(fits(label,resolution),"HUD score fits "+str(resolution))
		await capture("hud",resolution)
		game.queue_free()
		await process_frame
	print("Genre target UI: %d failures" % failures)
	quit(failures)
