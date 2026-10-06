extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_verify")

func expect(ok: bool, message: String) -> void:
	if ok:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func _settle() -> void:
	for i in range(4): await process_frame

func _verify() -> void:
	_verify_catalog()
	_verify_release_titles()
	await _verify_flow()
	_verify_multiple_sales()
	print("Pre-Development verification: %d failures" % failures)
	quit(failures)

func _verify_catalog() -> void:
	var expected := {
		&"action": [30, 20, 30, 20], &"adventure": [25, 20, 15, 40],
		&"role_playing": [15, 20, 30, 35], &"strategy": [15, 10, 40, 35],
		&"simulation": [15, 15, 45, 25], &"puzzle": [15, 10, 30, 45],
		&"sports": [25, 25, 30, 20], &"racing": [30, 25, 35, 10]}
	var run := RunState.new()
	run.initialize_cash(0)
	expect(PrimitivePredevelopment.catalog().genres.size() == 8, "Exactly eight Primitive genres")
	var themes := ["Fantasy", "Science Fiction", "Horror", "Crime", "War", "Historical", "Contemporary", "Western", "Post-Apocalyptic", "Mystery"]
	var actual_themes: Array[String] = []
	for entry: Dictionary in PrimitivePredevelopment.catalog().themes:
		actual_themes.append(entry.name)
	expect(actual_themes == themes, "Exactly the ten locked Primitive Themes in ledger order")
	for id: StringName in expected:
		var project := PrimitivePredevelopment.prepare_project(" Game ", id, &"fantasy", run)
		expect(project != null and project.get_base_name() == "Game" and project.get_genre_ratios() == expected[id], "Locked genre ratios stored on project: " + str(id))
		var copy := project.get_genre_ratios()
		copy[0] = 99
		expect(project.get_genre_ratios() == expected[id] and not project.configure_predevelopment("Changed", &"action", &"mystery", []), "Project choices and ratio copies are immutable")
		for entry: Dictionary in PrimitivePredevelopment.catalog().themes:
			var themed := PrimitivePredevelopment.prepare_project("Game", id, StringName(entry.id), run)
			expect(themed.get_theme_id() == StringName(entry.id) and themed.get_genre_ratios() == expected[id] and themed.get_current_cycle() == 0, "Theme stores identity only for " + str(id) + " / " + str(entry.name))
	expect(PrimitivePredevelopment.prepare_project(" \t\n", &"action", &"fantasy", run) == null, "Whitespace-only name rejects")
	expect(PrimitivePredevelopment.prepare_project("Game", &"unknown", &"fantasy", run) == null and PrimitivePredevelopment.prepare_project("Game", &"action", &"unknown", run) == null, "Unknown genre and theme reject")
	expect(run.get_cash_cents() == 0 and run.get_completed_run_cycles() == 0, "Preparing or rejecting choices has no run cost")

func _release_active_project(game: Control) -> StudioPhase:
	var project: ProjectState = game.project_state
	var old: Control = game.get("_active_phase")
	game.get_node("%GameplayHUD").tutorial_overlay.close()
	project.add_core_scores_and_scope({0: 20, 1: 21, 2: 22, 3: 23}, 30)
	project.finalize_design_bugs(false, 3, [&"text"], [&"sprites"])
	project.finalize_alpha(2, [&"enemies"], [&"controls"])
	project.add_marketing_output(4)
	var beta: BetaPhase = load("res://scenes/phases/beta_phase.tscn").instantiate()
	beta.setup(project, game.run_state, game.get_snapshot_database())
	beta.authorize_launch()
	beta.launch_requested.connect(Callable(game, "_on_beta_launch_requested").bind(beta))
	game.get_node("%PhaseRoot").add_child(beta)
	game.set("_active_phase", beta)
	game.get_node("%GameplayHUD").set_phase(beta)
	game.get_node("%PhaseRoot").remove_child(old)
	old.queue_free()
	beta.get_workspace().overlay.cancel()
	beta.begin_beta()
	var before := [game.run_state.get_cash_cents(), game.run_state.get_completed_run_cycles(), project.get_current_cycle()]
	beta.request_launch()
	beta.confirm_launch_for_verification()
	await _settle()
	var studio := game.get("_active_phase") as StudioPhase
	expect(studio != null, "Launch enters Studio automatically after results commit")
	if studio == null: return null
	expect(before == [game.run_state.get_cash_cents(), game.run_state.get_completed_run_cycles(), project.get_current_cycle()], "Automatic Studio entry retains zero cash and cycle cost")
	return game.get("_active_phase")

func _verify_flow() -> void:
	root.size = Vector2i(1152, 648)
	var run := RunState.new()
	run.initialize_cash_cents(220001)
	run.purchase_feature(&"save_files")
	run.spend_cash_cents(1)
	for i in range(22): run.advance_calendar_cycle() # Store node purchase already spent the first cycle.
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	game.project_state = ProjectState.new(30) # Existing-project fixture; first-run setup is tested separately.
	game.run_state = run
	root.add_child(game)
	await _settle()
	var old: ProjectState = game.project_state
	old.configure_predevelopment("Doom", &"action", &"fantasy", run.get_owned_feature_ids())
	run.record_resolved_feature(old, &"text", &"design")
	var studio := await _release_active_project(game)
	if studio == null:
		game.queue_free()
		return
	var id := old.get_release_id()
	var frozen := [old.get_core_score(0), old.get_current_scope(), old.get_current_cycle(), old.get_hidden_bugs(), old.get_marketing_output(), old.get_review_result()]
	var cash_before := run.get_cash_cents()
	var sales_before := run.get_released_game_sales(id)
	var calendar_before := run.get_completed_run_cycles()
	run.consume_redraw(4)
	var owned := run.get_owned_feature_ids()
	var contract := run.accept_primitive_contract()
	expect(contract != null and run.get_cash_cents() == cash_before + ContractState.GUARANTEED_UPFRONT_CENTS, "Accepting Ironclad credits its guarantee without advancing time")
	cash_before = run.get_cash_cents()
	studio.get_node("%StartNextGame").pressed.emit()
	var overlay: PredevelopmentOverlay = studio.get("_predevelopment")
	await _settle()
	expect(overlay.visible and not studio.get_node("%Dashboard").visible, "Produce Next Game opens overlay")
	overlay.name_input.text = "   "
	overlay.begin_button.pressed.emit()
	expect(overlay.error_label.text == "Enter a game name." and game.project_state == old and run.get_completed_run_cycles() == calendar_before, "Missing-name UI validation preserves project and time")
	overlay.name_input.text = "Doom"
	overlay.name_input.text_changed.emit("Doom")
	overlay.priority_sliders[0].value = 50
	overlay.begin_button.pressed.emit()
	expect(overlay.begin_button.disabled and game.project_state == old and run.get_completed_run_cycles() == calendar_before, "Invalid pre-development priorities reject without spending or creating a project")
	for i in range(4): overlay.priority_sliders[i].value = [50, 15, 15, 20][i]
	overlay.genre_input.select(5)
	overlay.theme_input.select(9)
	for window_size in [Vector2i(1152, 648), Vector2i(900, 600)]:
		root.size = window_size
		await _settle()
		expect(studio.get_global_rect().encloses(overlay.get_global_rect()) and overlay.begin_button.get_global_rect().end.y <= game.get_node("%GameplayHUD").footer_panel.get_global_rect().position.y, "Overlay and confirmation fit above unchanged HUD at %s" % window_size)
	root.size = Vector2i(1152, 648)
	await _settle()
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://design-logs/predevelopment.png")
	overlay.cancelled.emit()
	expect(studio.get_node("%Dashboard").visible and not overlay.visible, "Cancel returns to Studio")
	studio.get_node("%StartNextGame").pressed.emit()
	expect(overlay.name_input.text == "Doom" and run.get_cash_cents() == cash_before and run.get_released_game_sales(id) == sales_before and run.get_available_redraws() == 0, "Opening, editing and cancelling are free and preserve the draft")
	run.set("_completed_run_cycles", RunState.MAX_SIGNED_INT)
	overlay.begin_button.pressed.emit()
	expect(game.project_state == old and overlay.visible and run.get_cash_cents() == cash_before and run.get_released_game_sales(id) == sales_before, "Calendar overflow rejects confirmation without replacing project or spending cash")
	run.set("_completed_run_cycles", calendar_before)
	expect(cash_before == ContractState.GUARANTEED_UPFRONT_CENTS and not overlay.begin_button.disabled, "Begin Development remains available with the accepted Contract guarantee")
	overlay.begin_button.pressed.emit()
	var fresh: ProjectState = game.project_state
	expect(fresh != old and fresh.get_base_name() == "Doom" and fresh.get_genre_id() == &"puzzle" and fresh.get_theme_id() == &"mystery", "Confirmation creates a fresh named project with selected choices")
	expect(fresh.get_current_cycle() == 0 and run.get_completed_run_cycles() == calendar_before + 1 and run.get_available_redraws() == 4, "Confirmation costs one run cycle, starts project cycle zero and refreshes redraws to four")
	expect(not game.call("_begin_next_project", studio, "Replay", &"action", &"fantasy") and run.get_completed_run_cycles() == calendar_before + 1, "Repeated confirmation from stale Studio cannot charge twice")
	expect(game.run_state == run and run.get_owned_feature_ids() == owned and run.get_feature_familiarity(&"text") == 1 and run.get_primitive_contract() == contract, "Same RunState preserves ownership, familiarity and contract identity")
	var sales := run.get_released_game_sales(id)
	var expected_income: int = old.get_month_one_sales_revenue_result().get_cumulative_net_entitlement_cents()[0]
	expect(sales.earned_cycles == 1 and run.get_cash_cents() == cash_before + expected_income and sales.settled_cents == expected_income, "Begin cycle earns and settles historical sales through exact-cent boundary")
	expect(frozen == [old.get_core_score(0), old.get_current_scope(), old.get_current_cycle(), old.get_hidden_bugs(), old.get_marketing_output(), old.get_review_result()], "Released project stays frozen")
	expect(fresh.get_core_score(0) == 0 and fresh.get_core_score(1) == 0 and fresh.get_core_score(2) == 0 and fresh.get_core_score(3) == 0 and fresh.get_current_scope() == 0 and fresh.get_accumulated_bug_pressure() == 0 and fresh.get_accumulated_alpha_bug_pressure() == 0 and fresh.get_marketing_output() == 0, "Fresh project resets every score, Scope, Bug Pressure and Marketing")
	expect(fresh.get("_hidden_bugs") == 0 and fresh.get_known_bugs() == 0 and fresh.get_fixed_bugs() == 0 and fresh.get("_implemented_design_feature_ids").is_empty() and fresh.get("_implemented_alpha_feature_ids").is_empty() and fresh.get("_exhausted_beta_card_ids").is_empty(), "Fresh Bugs and all phase Feature histories are empty")
	expect(not fresh.has_design_bug_finalization() and not fresh.has_alpha_finalization() and not fresh.has_beta_finalization() and not fresh.has_review_result() and not fresh.has_awareness_result() and not fresh.has_month_one_sales_revenue_result(), "Fresh project has no prior phase or launch results")
	expect(fresh.has_competitor_snapshot() and fresh.has_market_forecast_snapshot() and not fresh.is_competitor_snapshot_revealed() and not fresh.is_market_forecast_snapshot_revealed(), "New project has freshly assigned concealed market snapshots")
	var design: DesignPhase = game.get("_active_phase")
	expect(design != null and design.get("_project_state") == fresh and design.get_priority_distribution() == {0: 50, 1: 15, 2: 15, 3: 20} and design.get("_exhausted_card_ids").is_empty(), "Transition deals Design using Pre-Development priorities and fresh exhaustion")
	expect(game.get_node("%GameplayHUD").project == fresh and not old.values_changed.is_connected(game.get_node("%GameplayHUD").refresh), "Existing HUD is rebound and disconnects old project")
	var rebuilt: Control = load("res://scenes/gameplay.tscn").instantiate()
	rebuilt.project_state = fresh
	rebuilt.run_state = run
	var reconstruction_before := [fresh.get_current_cycle(), run.get_completed_run_cycles(), run.get_cash_cents(), fresh.get_feature_supply_ids(), fresh.get_assigned_competitor_snapshot_id_for_authority(), fresh.get_assigned_market_forecast_snapshot_id_for_authority()]
	root.add_child(rebuilt)
	expect(rebuilt.get("_active_phase") is DesignPhase and rebuilt.project_state == fresh and rebuilt.run_state == run and reconstruction_before == [fresh.get_current_cycle(), run.get_completed_run_cycles(), run.get_cash_cents(), fresh.get_feature_supply_ids(), fresh.get_assigned_competitor_snapshot_id_for_authority(), fresh.get_assigned_market_forecast_snapshot_id_for_authority()], "Reconstructing fresh Design preserves identity, supply, snapshots and zero project cycles without recharging")
	rebuilt.queue_free()
	design.get_workspace().overlay.cancel()
	expect(not design.is_initial_priority_planning() and fresh.get_current_cycle() == 0, "Design begins automatically from Pre-Development without another cycle")
	var history: Dictionary = design.call("_build_design_feature_history")
	expect(history.valid and history.unimplemented_ids.has(&"save_files"), "New Design supply and history include purchased Save Files")
	run.add_cash(1000)
	run.purchase_feature(&"colored_text")
	expect(not fresh.get_feature_supply_ids().has(&"colored_text"), "Later purchases cannot alter creation-time project supply")
	var second_studio := await _release_active_project(game)
	expect(second_studio != null and run.get_released_game_ids().size() == 2, "Second game completes existing release flow and registers separately")
	expect(run.get_released_game_display_name(id) == "Doom" and run.get_released_game_display_name(fresh.get_release_id()) == "Doom (1981)", "First release keeps its name and later duplicate uses actual release year")
	second_studio.open_summary()
	expect(second_studio.get_node("%SummaryTitle").text == "Doom (1981)", "Released duplicate title is visible in Studio summary")
	var metadata := run.get_release_metadata(id)
	metadata.release_year = 9999
	expect(run.get_release_metadata(id).release_year == 1980 and fresh.get_base_name() == "Doom", "History queries cannot rename or redate immutable release metadata")
	second_studio.close_summary()
	second_studio.get_node("%StartNextGame").pressed.emit()
	var third_overlay: PredevelopmentOverlay = second_studio.get("_predevelopment")
	third_overlay.name_input.text = "Third Game"
	var cents_before := run.get_cash_cents()
	var first_settled_before: int = run.get_released_game_sales(id).settled_cents
	var second_settled_before: int = run.get_released_game_sales(fresh.get_release_id()).settled_cents
	third_overlay.begin_button.pressed.emit()
	var settled_delta: int = int(run.get_released_game_sales(id).settled_cents) - first_settled_before + int(run.get_released_game_sales(fresh.get_release_id()).settled_cents) - second_settled_before
	expect(game.project_state.get_base_name() == "Third Game" and run.get_completed_run_cycles() == 26 and run.get_cash_cents() == cents_before + settled_delta and run.get_released_game_ids().size() == 2, "Another project begins with both sales records retained and same-boundary settlement")
	var third_design: DesignPhase = game.get("_active_phase")
	third_design.get_workspace().overlay.cancel()
	third_design.begin_design()
	var views := third_design.get_node("%HandContainer").get_children()
	for i in range(4): views[i].input_button.pressed.emit()
	third_design.get_node("%PlayCardButton").pressed.emit()
	expect(game.project_state.get_current_cycle() == 1 and run.get_completed_run_cycles() == 27, "First Design hand advances project zero to one and run calendar once")
	game.queue_free()
	await _settle()

func _finish_project(project: ProjectState) -> void:
	var snapshots := PrimitiveSnapshotDatabase.new()
	snapshots.load_ledgers()
	project.initialize_snapshots(&"fast_follower", &"stable_market")
	project.finalize_design_bugs(false, 0, [&"text"], [])
	project.finalize_alpha(0, [], [])
	project.finalize_beta()
	project.commit_review_result(PrimitiveReviewCalculator.calculate(project, 50))
	project.commit_awareness_result(PrimitiveAwarenessCalculator.calculate(project))
	project.commit_launch_market_context_result(PrimitiveLaunchMarketContextCalculator.calculate(project, snapshots))
	project.commit_units_sold_result(PrimitiveUnitsSoldCalculator.calculate(project))
	project.commit_month_one_sales_revenue_result(PrimitiveMonthOneSalesRevenueCalculator.calculate(project))

func _verify_release_titles() -> void:
	var run := RunState.new()
	run.initialize_cash_cents(1)
	var first := PrimitivePredevelopment.prepare_project("Doom", &"action", &"fantasy", run)
	var later := PrimitivePredevelopment.prepare_project("Doom", &"action", &"horror", run)
	expect(first != null and later != null and first.get_release_id() != later.get_release_id(), "Duplicate names create distinct project identities")
	_finish_project(first)
	expect(run.register_release(first) and run.get_released_game_display_name(first.get_release_id()) == "Doom", "First released use retains the unmodified title")
	for i in range(24): run.advance_calendar_cycle()
	expect(run.get_project_display_name(later) == "Doom" and run.get_release_metadata(later.get_release_id()).is_empty(), "Unreleased title lookup neither resolves a duplicate nor creates history")
	_finish_project(later)
	expect(run.register_release(later) and run.get_released_game_display_name(later.get_release_id()) == "Doom (1981)", "Duplicate created in 1980 resolves using actual 1981 release year")
	var same_year := PrimitivePredevelopment.prepare_project("Doom", &"action", &"mystery", run)
	_finish_project(same_year)
	expect(run.register_release(same_year) and run.get_released_game_display_name(same_year.get_release_id()) == "Doom (1981)", "Same-year duplicates are accepted without invented sequel suffixes")
	var later_id := later.get_release_id()
	var original_metadata := run.get_release_metadata(later_id)
	for i in range(24): run.advance_calendar_cycle()
	var sales_before := run.get_released_game_sales(later_id)
	var observed := [0]
	run.sales_changed.connect(func(): observed[0] += 1)
	var reconstructed := PrimitivePredevelopment.prepare_project("Doom", &"action", &"horror", run)
	reconstructed.set("_release_id", later_id)
	_finish_project(reconstructed)
	expect(run.register_release(later) and run.register_release(reconstructed) and observed[0] == 0, "Repeated and reconstructed release registration is a signal-free no-op")
	expect(run.get_release_metadata(later_id) == original_metadata and run.get_released_game_sales(later_id) == sales_before and run.get_project_display_name(reconstructed) == "Doom (1981)", "Reconstruction in 1982 preserves resolved title, release year and sales")
	expect(run.get_released_game_display_name(first.get_release_id()) == "Doom" and sales_before.release_title == "Doom (1981)" and sales_before.base_name == "Doom", "Later names and sales earning never rename earlier releases; base/title stored separately")
	var invalid_identity := PrimitivePredevelopment.prepare_project("Doom", &"puzzle", &"horror", run)
	invalid_identity.set("_release_id", later_id)
	_finish_project(invalid_identity)
	expect(not run.register_release(invalid_identity) and run.get_release_metadata(later_id) == original_metadata, "Same release ID cannot be reconstructed with different permanent genre identity")

func _verify_multiple_sales() -> void:
	var run := RunState.new()
	run.initialize_cash_cents(1)
	# Independently known 751-unit oracle for simultaneous released-game earning.
	var records: Dictionary = run.get("_released_games")
	records[&"one"] = ReleasedGameSales.create(&"one", 751)
	records[&"two"] = ReleasedGameSales.create(&"two", 751)
	run.complete_productive_action()
	run.complete_productive_action()
	expect(run.get_cash_cents() == 1050349 and run.get_released_game_sales(&"one").settled_cents == 525174 and run.get_released_game_sales(&"two").settled_cents == 525174, "Two games settle independently and sum exact cents")
	var overflow := RunState.new()
	overflow.initialize_cash_cents(RunState.MAX_SIGNED_INT - 800000)
	var unsafe_records: Dictionary = overflow.get("_released_games")
	unsafe_records[&"one"] = ReleasedGameSales.create(&"one", 751)
	unsafe_records[&"two"] = ReleasedGameSales.create(&"two", 751)
	overflow.complete_productive_action()
	var before := [overflow.get_cash_cents(), overflow.get_completed_run_cycles(), overflow.get_released_game_sales(&"one"), overflow.get_released_game_sales(&"two")]
	var touched := [false]
	expect(not overflow.complete_productive_action(func() -> bool: touched[0] = true; return true) and not touched[0], "Combined multi-release overflow rejects before direct action")
	expect(before == [overflow.get_cash_cents(), overflow.get_completed_run_cycles(), overflow.get_released_game_sales(&"one"), overflow.get_released_game_sales(&"two")], "Rejected multi-release action preserves all history, cash and cycles")
