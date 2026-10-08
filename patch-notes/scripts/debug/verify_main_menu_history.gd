extends SceneTree

var failures := 0

func expect(ok: bool, message: String) -> void:
	if ok: print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _init() -> void:
	call_deferred("_run")

func _capture(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args(): return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://design-logs/" + name + ".png")

func _finish_project(project: ProjectState) -> void:
	var snapshots := PrimitiveSnapshotDatabase.new()
	snapshots.load_ledgers()
	var scores: Dictionary[ProjectState.CoreScore, int] = {0: 30, 1: 30, 2: 30, 3: 30}
	project.add_core_scores_and_scope(scores, 30)
	project.initialize_snapshots(&"fast_follower", &"stable_market")
	project.finalize_design_bugs(false, 0, [&"text"], [])
	project.finalize_alpha(0, [], [])
	project.finalize_beta()
	project.commit_review_result(PrimitiveReviewCalculator.calculate(project, 50))
	project.commit_awareness_result(PrimitiveAwarenessCalculator.calculate(project))
	project.commit_launch_market_context_result(PrimitiveLaunchMarketContextCalculator.calculate(project, snapshots))
	project.commit_units_sold_result(PrimitiveUnitsSoldCalculator.calculate(project))
	project.commit_month_one_sales_revenue_result(PrimitiveMonthOneSalesRevenueCalculator.calculate(project))

func _run() -> void:
	root.size = Vector2i(1152, 648)
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var run: RunState = game.run_state
	var menu: MainMenu = game.get("_active_phase")
	expect(menu != null and run.get_cash_cents() == 0 and game.project_state == null, "New run opens main menu without project or charge")
	await _capture("main-menu")
	menu.get_node("CenterContainer/MenuLayout/StartGame").pressed.emit()
	var input: LineEdit = menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioName")
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioSpecialty").select(1)
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/EnterStudio").pressed.emit()
	expect(run.get_studio_name().is_empty() and run.get_completed_run_cycles() == 0, "Blank studio name rejects for free")
	input.text = "  North Star  "
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioSpecialty").select(1)
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/EnterStudio").pressed.emit()
	menu.call("_show_review")
	menu.call("_confirm_studio")
	var studio: StudioPhase = game.get("_active_phase")
	expect(studio != null and run.get_studio_name() == "North Star" and run.get_completed_run_cycles() == 0 and run.get_cash_cents() == 570000 and game.project_state == null, "Studio name commits once, grants initial funding, and enters empty Studio for free")
	expect(run.finalize_starter_selection(), "History fixture closes the first-game purchase window before released projects")
	game.get_node("%GameplayHUD").tutorial_overlay.close()
	await _capture("new-studio")
	expect(studio.get_node("%PostGameSummaries").disabled and studio.get_node("%StartNextGame").text == "Produce First Game", "Empty Studio offers first game without false release history")
	expect(run.consume_redraw(), "Passive Studio navigation fixture uses a partial redraw bank")
	var prior := [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_available_redraws()]
	studio.get_node("%FeatureStoreButton").pressed.emit()
	(studio.get("_feature_store") as FeatureStore).hide()
	expect(prior == [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_available_redraws()], "Empty Studio browsing preserves finance and time")
	var first := PrimitivePredevelopment.prepare_project("First", &"action", &"fantasy", run)
	var second := PrimitivePredevelopment.prepare_project("Second", &"puzzle", &"mystery", run)
	_finish_project(first)
	_finish_project(second)
	expect(run.register_release(first) and run.register_release(second), "Two release histories register independently")
	var first_id := first.get_release_id()
	var second_id := second.get_release_id()
	var history := run.get_release_metadata(first_id)
	expect(history.review.final_review == first.get_review_result().get_final_review() and history.review.projected_gross_cents == first.get_month_one_sales_revenue_result().get_projected_month_one_gross_cents(), "Release captures exact review and gross projection")
	var rebuilt: StudioPhase = load("res://scenes/phases/studio_phase.tscn").instantiate()
	expect(rebuilt.setup(second, run, game.get_snapshot_database()), "Studio reconstructs from newest release")
	root.add_child(rebuilt)
	await process_frame
	rebuilt.open_summary()
	await _capture("game-history")
	expect(rebuilt.get_node("%GameList").item_count == 2 and rebuilt.get_node("%SummaryTitle").text == "Second", "Summary lists all released games and selects newest")
	var before := [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_released_game_sales(first_id), run.get_released_game_sales(second_id)]
	rebuilt.get_node("%GameList").select(0)
	rebuilt.get_node("%GameList").item_selected.emit(0)
	expect(rebuilt.get_node("%SummaryTitle").text == "First" and rebuilt.get_node("%ProjectedRevenueLabel").text.contains("Gross"), "Older game selection displays its own gross results")
	rebuilt.open_detailed_review()
	var review: PostGameReview = rebuilt.get("_review_view")
	expect(review != null and review.get_node("%GraphicsLabel").text.contains(str(first.get_core_score(0))) and review.get_node("%SalesNetLabel").text.contains("Gross"), "Historical detail shows category review and grossing")
	expect(before == [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_released_game_sales(first_id), run.get_released_game_sales(second_id)], "History browsing is passive")
	review.get_node("%ContinueButton").pressed.emit()
	expect(run.advance_calendar_cycle(), "One productive cycle earns both historical releases")
	var earned := run.get_released_game_sales(first_id)
	expect(earned.earned_units > 0 and rebuilt.get_node("%EarnedLabel").text.contains(CashFormatter.format_exact_cents(earned.earned_units * PrimitiveMonthOneSalesRevenueCalculator.PRICE_CENTS)), "Selected history updates its exact earned gross after sales progress")
	history.review.final_review = 0.0
	expect(run.get_release_metadata(first_id).review.final_review == first.get_review_result().get_final_review(), "History query returns a defensive copy")
	var reconstruction: Control = load("res://scenes/gameplay.tscn").instantiate()
	reconstruction.run_state = run
	root.add_child(reconstruction)
	await process_frame
	expect(reconstruction.get("_active_phase") is StudioPhase and run.get_studio_name() == "North Star" and run.get_released_game_ids().size() == 2, "Run reconstruction restores named Studio and both games")
	print("Main menu and release history verification: %d failures" % failures)
	quit(0 if failures == 0 else 1)
