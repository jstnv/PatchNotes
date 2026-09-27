extends SceneTree

var failures := 0
var capture := "--capture" in OS.get_cmdline_user_args()

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if ok: print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _settle() -> void:
	for i in range(4): await process_frame

func _capture(name: String) -> void:
	if not capture: return
	await RenderingServer.frame_post_draw
	var folder := OS.get_environment("TEMP").path_join("patch-notes-release-menus")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder.path_join(name + ".png"))

func _run() -> void:
	root.size = Vector2i(1152, 648)
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	game.project_state = ProjectState.new(30) # Existing-project fixture; first-run setup is tested separately.
	root.add_child(game)
	await _settle()
	var hud: GameplayHUD = game.get_node("%GameplayHUD")
	hud.tutorial_overlay.close()
	var holder := game.get_node("%PhaseRoot")
	var original: Control = game.get("_active_phase")
	holder.remove_child(original)
	original.queue_free()
	var state: ProjectState = game.project_state
	var run: RunState = game.run_state
	var scores: Dictionary[ProjectState.CoreScore, int] = {0: 33, 1: 34, 2: 39, 3: 39}
	state.add_core_scores_and_scope(scores, 38)
	state.finalize_design_bugs(false, 0, [], [])
	state.finalize_alpha(0, [], [])
	state.add_marketing_output(50)
	var beta: BetaPhase = load("res://scenes/phases/beta_phase.tscn").instantiate()
	beta.setup(state, run, game.get_snapshot_database())
	beta.authorize_launch()
	beta.launch_requested.connect(Callable(game, "_on_beta_launch_requested").bind(beta))
	holder.add_child(beta)
	game.set("_active_phase", beta)
	hud.set_phase(beta)
	beta.get_workspace().overlay.cancel()
	beta.begin_beta()
	var launch_before := [run.get_cash_cents(), run.get_completed_run_cycles(), state.get_current_cycle()]
	check(beta.request_launch(), "Launch enters Studio through the real phase transition")
	await _settle()
	var studio: StudioPhase = game.get("_active_phase")
	check(hud.tutorial_context == &"studio" and not hud.tutorial_overlay.visible and hud.contextual_tip.panel.visible, "Automatic Studio entry presents nonblocking guidance")
	hud.contextual_tip.dismiss()
	check(studio != null and launch_before == [run.get_cash_cents(), run.get_completed_run_cycles(), state.get_current_cycle()], "Launch automatically enters Studio at zero cash and cycle cost")
	var sales_before := run.get_released_game_sales(state.get_release_id())
	studio.open_summary()
	studio.get_node("%DetailedReviewButton").pressed.emit()
	await _settle()
	var review: PostGameReview = studio.get("_review_view")
	check(hud.tutorial_context == &"review" and not hud.tutorial_overlay.visible and hud.contextual_tip.panel.visible, "Opening Detailed Review selects inline Review guidance")
	hud.contextual_tip.dismiss()
	check(review != null and review.get_node("%Categories").get_tab_count() == 5, "Review offers five performance categories")
	var before := [run.get_cash_cents(), run.get_completed_run_cycles(), state.get_current_cycle(), state.get_review_result()]
	for window_size in [Vector2i(1152, 648), Vector2i(900, 600)]:
		root.size = window_size
		await _settle()
		for tab in range(5):
			review.get_node("%Categories").current_tab = tab
			await _settle()
			var continue_rect: Rect2 = review.get_node("%ContinueButton").get_global_rect()
			check(continue_rect.position.y >= review.get_node("%Categories").get_global_rect().end.y and continue_rect.end.y <= hud.footer_panel.get_global_rect().position.y, "Continue stays below every category and above the bottom HUD at %s" % window_size)
	root.size = Vector2i(1152, 648)
	review.get_node("%Categories").current_tab = 1
	await _settle()
	check(review.get_node("%GraphicsLabel").text.contains("33 points") and review.get_node("%GraphicsLabel").text.contains("33 standard"), "Core performance uses the actual release scores and rebalanced standard")
	await _capture("review-core")
	review.get_node("%Categories").current_tab = 0
	await _settle()
	await _capture("review-overview")
	check(before == [run.get_cash_cents(), run.get_completed_run_cycles(), state.get_current_cycle(), state.get_review_result()], "Category browsing never changes release results, time or cash")
	review.get_node("%ContinueButton").pressed.emit()
	await _settle()
	check(game.get("_active_phase") == studio and studio.get_node("%SummaryPanel").visible and not review.visible, "Detailed Review returns to the same Studio summary")
	studio.close_summary()
	check(studio != null and not hud.get_node("PersistentHeader").visible and hud.footer_panel.is_visible_in_tree(), "Studio hides the top HUD and keeps the bottom HUD")
	check(studio.get_node("%Dashboard").visible and not studio.get_node("%SummaryPanel").visible and not studio.get_node("%ReviewLabel").is_visible_in_tree(), "Dashboard contains menu buttons, with release statistics hidden")
	await _capture("studio")
	studio.get_node("%PostGameSummaries").pressed.emit()
	await _settle()
	check(studio.get_node("%SummaryPanel").is_visible_in_tree() and not studio.get_node("%Dashboard").visible and studio.get_node("%ReviewLabel").is_visible_in_tree(), "Post Game Summaries opens the release statistics")
	await _capture("summary")
	studio.get_node("%CloseSummaryButton").pressed.emit()
	check(studio.get_node("%Dashboard").visible and not studio.get_node("%SummaryPanel").visible, "Back to Studio restores the menu")
	studio.get_node("%FeatureStoreButton").pressed.emit()
	await _settle()
	var store: FeatureStore = studio.get("_feature_store")
	check(hud.tutorial_context == &"feature_store" and not hud.tutorial_overlay.visible and hud.contextual_tip.panel.visible, "Feature Store entry presents inline tree guidance")
	hud.contextual_tip.dismiss()
	check(studio.get_global_rect().encloses(store.get_global_rect()), "Feature Store fits inside the Studio workspace")
	await _capture("store")
	store.hide()
	check(hud.tutorial_context == &"studio" and not hud.tutorial_overlay.visible and not hud.contextual_tip.panel.visible, "Returning to Studio restores its context without repeated guidance")
	studio.get_node("%StartNextGame").pressed.emit()
	check(hud.tutorial_context == &"predevelopment" and not hud.tutorial_overlay.visible and hud.contextual_tip.panel.visible, "Next-game setup selects inline Pre-Development guidance")
	hud.contextual_tip.dismiss()
	(studio.get("_predevelopment") as PredevelopmentOverlay).cancelled.emit()
	studio.get_node("%Contracts").pressed.emit()
	check(hud.tutorial_context == &"contract" and not hud.tutorial_overlay.visible and hud.contextual_tip.panel.visible, "Contract offer presents inline guidance")
	hud.contextual_tip.dismiss()
	studio.call("_close_contract_detail")
	check(studio.get_node("%Dashboard").visible, "Closing Feature Store restores the dashboard")
	check(before == [run.get_cash_cents(), run.get_completed_run_cycles(), state.get_current_cycle(), state.get_review_result()] and sales_before == run.get_released_game_sales(state.get_release_id()), "Detailed Review and Studio browsing preserve finance, sales history and release results")
	game.queue_free()
	await process_frame
	print("Release menus verification: %d failures" % failures)
	quit(failures)
