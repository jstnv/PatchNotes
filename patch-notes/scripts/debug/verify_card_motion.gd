extends SceneTree

var failures := 0
var traces: Array = []
var capture := false

func _initialize() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	_verify.call_deferred()

func expect(ok: bool, text: String) -> void:
	print("PASS: " if ok else "FAIL: ", text)
	if not ok: failures += 1

func settle(seconds := 0.22) -> void:
	await create_timer(seconds).timeout

func shot(name: String) -> void:
	if not capture: return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://design-logs/card-motion-v1/%s.png" % name)

func click(point: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)

func _install(phase: Control, ids: Array[StringName]) -> void:
	var fan := phase.get_node("%HandContainer")
	for view in fan.get_children():
		fan.remove_child(view)
		view.queue_free()
	var cards: Array[CardData] = []
	var views: Array[CardView] = []
	for id in ids:
		var card: CardData = root.get_node("CardDatabase").get_card(id)
		var view: CardView = load("res://scenes/cards/card_view.tscn").instantiate()
		view.set_card(card)
		view.card_pressed.connect(Callable(phase, "_on_card_pressed"))
		fan.add_child(view)
		cards.append(card)
		views.append(view)
	phase.set("_candidate_cards", cards)
	phase.set("_selected_card_views", [] as Array[CardView])
	if phase is BetaPhase: phase.set("_candidate_views", views)
	phase.refresh_workspace()

func _snapshot(project: ProjectState, run: RunState) -> Array:
	return [HandPresentation.project_snapshot(project, run), run.get_cash_cents(), run.get_owned_feature_ids(), project.get_exhausted_beta_card_ids()]

func _verify() -> void:
	for dimensions in [Vector2i(1152, 648), Vector2i(900, 600)]:
		root.size = dimensions
		await _production(dimensions.x)
		await _store(dimensions.x)
	await _paid_hand()
	await _contract()
	var out := FileAccess.open("res://design-logs/card-motion-v1/animation-traces.json", FileAccess.WRITE)
	out.store_string(JSON.stringify(traces, "\t"))
	print("Card motion verification: %d failures" % failures)
	quit(failures)

func _production(width: int) -> void:
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	game.project_state = ProjectState.new(30)
	game.run_state = RunState.new()
	game.run_state.initialize_cash(10000)
	root.add_child(game)
	await process_frame
	var phase: Control = game.get("_active_phase")
	var hud: GameplayHUD = game.get_node("%GameplayHUD")
	phase.get("_deal_rng").seed = 240930
	phase.get_workspace().overlay.commit_draft()
	hud.contextual_tip.dismiss()
	_install(phase, [&"graphics_pass", &"graphics_pass", &"graphics_pass", &"graphics_pass", &"sound_pass", &"technology_pass", &"design_pass"])
	await settle()
	var fan: CardFan = phase.get_node("%HandContainer")
	var views := fan.get_children()
	expect(views.size() == 7 and views[0].rotation < 0 and views[6].rotation > 0, "Seven cards form an outward fan (%d)" % width)
	var unselected_y: float = views[0].position.y
	for i in [3, 2, 1, 0]: views[i].input_button.pressed.emit()
	await settle()
	expect(views[0].position.y < unselected_y - 40 and views[0].z_index > views[6].z_index, "Selected cards extend above the fan and remain raised")
	click(views[3].get_global_transform() * Vector2(220, 170))
	expect(not views[3].is_selected() and not views[4].is_selected(), "Native pointer routing selects the visible foreground card in an overlapping fan")
	views[3].input_button.pressed.emit()
	await settle()
	hud.contextual_tip.dismiss()
	await shot("selected-fan-%d" % width)
	var motion: HandPresentation = phase.get_workspace().hand_motion
	var project: ProjectState = game.project_state
	var run: RunState = game.run_state
	var cycle := run.get_completed_run_cycles()
	phase.get_node("%PlayCardButton").pressed.emit()
	expect(motion.busy and project.get_core_score(0) == 12 and run.get_completed_run_cycles() == cycle + 1, "Native specialization commits once before visual playback")
	expect(root.gui_get_focus_owner() == motion, "Presentation owns keyboard focus while the hand resolves")
	expect(hud.stats[1].text == "Graphics\n0" and not fan.visible, "Scoreboard holds old value while committed candidates are hidden")
	var committed := _snapshot(project, run)
	phase.get_node("%PlayCardButton").pressed.emit()
	phase.get_node("%RedrawButton").pressed.emit()
	expect(_snapshot(project, run) == committed, "Repeated UI callbacks during animation cannot replay or redraw")
	await settle(0.34)
	expect(motion._ghosts.size() == 7 and motion._hand.size() == 4 and motion._ghosts[4].scale.x < 0.4 and motion._ghosts[4].position.y > 160, "Unselected candidates shrink and lower while the selected hand centers")
	await shot("centered-hand-%d" % width)
	await settle(0.14)
	expect(hud.stats[1].text == "Graphics\n3" and not hud._score_pulses.is_empty(), "First bounce updates the scoreboard and exposes a +3 indicator")
	await shot("score-bounce-%d" % width)
	if motion.busy: await motion.finished
	var order: Array = []
	for event in motion.trace:
		if event.index >= 0: order.append([event.index, event.event])
	var expected: Array = []
	for i in range(4):
		for event in ["rise", "score", "grounded"]: expected.append([i, event])
	expect(order == expected, "Cards bounce left to right only after the previous card lands, independent of click order")
	expect(hud.stats[1].text == "Graphics\n12" and _snapshot(project, run) == committed and fan.visible, "Playback totals exactly match native resolution and makes no extra state changes")
	traces.append({"phase": "Design", "width": width, "seed": 240930, "order": motion.trace.duplicate(true), "state": committed})
	# Redraw one renewable Pass, preserving the remaining candidate instances.
	_install(phase, [&"graphics_pass", &"sound_pass", &"technology_pass", &"design_pass", &"graphics_pass", &"sound_pass", &"design_pass"])
	await settle()
	views = fan.get_children()
	views[0].input_button.pressed.emit()
	await settle()
	var cash := run.get_cash_cents()
	cycle = run.get_completed_run_cycles()
	var redraws := run.get_available_redraws()
	phase.get_node("%RedrawButton").pressed.emit()
	expect(motion.busy and run.get_available_redraws() == redraws - 1 and run.get_cash_cents() == cash and run.get_completed_run_cycles() == cycle, "Animated redraw preserves the exact one-card budget and zero-cycle/cash rules")
	await settle(0.36)
	var center_x := motion._hand[0].position.x
	await settle(0.18)
	expect(motion._hand[0].position.x > center_x + 50, "Redrawn hand slides right after centering")
	await shot("redraw-exit-%d" % width)
	if motion.busy: await motion.finished
	expect(fan.visible and fan.get_child(1) == views[1] and project.get_core_score(0) == 12, "Redraw returns to the fan without altering unaffected cards or scores")
	# Invalid hand must leave gameplay and visible candidates untouched.
	fan.get_child(0).input_button.pressed.emit()
	var before := _snapshot(project, run)
	phase.get_node("%PlayCardButton").pressed.emit()
	expect(not motion.busy and _snapshot(project, run) == before and fan.visible and fan.get_child(0).is_selected(), "Rejected hand starts no animation and preserves selection and state")
	phase.get_node("%HandContainer").get_child(0).input_button.pressed.emit()
	# Continue via the native phase transitions; Alpha gets the same fan/presenter.
	project.finalize_design_bugs(false, 8, [], [])
	expect(game.call("_replace_design_with_alpha", phase, load("res://scenes/phases/alpha_phase.tscn")), "Native Design-to-Alpha transition succeeds with the new workspace")
	phase = game.get("_active_phase")
	phase.get_workspace().overlay.commit_draft()
	_install(phase, [&"graphics_pass", &"graphics_pass", &"graphics_pass", &"graphics_pass", &"sound_pass", &"technology_pass", &"design_pass"])
	await settle()
	for i in range(4): phase.get_node("%HandContainer").get_child(i).input_button.pressed.emit()
	phase.get_node("%PlayAlphaHandButton").pressed.emit()
	motion = phase.get_workspace().hand_motion
	expect(motion.busy and project.get_core_score(0) == 24, "Alpha uses native scoring with the shared animation")
	motion.cancel()
	expect(hud.stats[1].text == "Graphics\n24" and not motion.busy, "Animation cancellation restores the authoritative scoreboard without rollback or replay")
	project.add_scope(30)
	phase.call("_finalize_alpha", 0.0, 0.5)
	phase = game.get("_active_phase")
	expect(phase is BetaPhase, "Native Alpha-to-Beta transition remains available")
	phase.get_workspace().overlay.commit_draft()
	_install(phase, [&"sign_flippers", &"sign_flippers", &"sign_flippers", &"sign_flippers", &"search_for_bugs", &"debug", &"study_competition"])
	await settle()
	for i in range(4): phase.get_node("%HandContainer").get_child(i).input_button.pressed.emit()
	phase.get_node("%PlayHandButton").pressed.emit()
	motion = phase.get_workspace().hand_motion
	expect(motion.busy and project.get_marketing_output() == 6 and hud.stats[0].text == "Marketing\n0", "Beta Marketing specialization commits its true output while display waits for bounces")
	if motion.busy: await motion.finished
	expect(hud.stats[0].text == "Marketing\n6" and project.get_core_score(0) == 24, "Beta displays Marketing gain without inventing Core gains")
	_install(phase, [&"debug", &"search_for_bugs", &"debug", &"search_for_bugs", &"sign_flippers", &"posters", &"press_release"])
	await settle()
	for i in range(4): phase.get_node("%HandContainer").get_child(i).input_button.pressed.emit()
	phase.get_node("%PlayHandButton").pressed.emit()
	var known_final := project.get_known_bugs()
	var fixed_final := project.get_fixed_bugs()
	var never_negative := [true]
	var check_known := func(_index: int, event: String):
		if event == "score": never_negative[0] = never_negative[0] and not hud.stats[6].text.contains("-")
	motion.card_step.connect(check_known)
	if motion.busy: await motion.finished
	motion.card_step.disconnect(check_known)
	expect(never_negative[0] and hud.stats[6].text == "Known / Fixed\n%d / %d" % [known_final, fixed_final], "QA visual order keeps Known Bugs nonnegative and ends at native Search-before-Debug totals")
	await shot("beta-fan-%d" % width)
	game.queue_free()
	await process_frame

func _store(width: int) -> void:
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var menu: MainMenu = game.get("_active_phase")
	menu.get_node("CenterContainer/MenuLayout/StartGame").pressed.emit()
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioName").text = "Motion Test Studio"
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/StudioSpecialty").select(1)
	menu.get_node("CenterContainer/MenuLayout/StudioSetup/EnterStudio").pressed.emit()
	var run: RunState = game.run_state
	var studio: StudioPhase = game.get("_active_phase")
	studio.get_node("%FeatureStoreButton").pressed.emit()
	var store: FeatureStore = studio.get("_feature_store")
	game.get_node("%GameplayHUD").contextual_tip.dismiss()
	await settle()
	store._map.fit_map()
	await settle()
	var small := store._map.zoom
	var before := [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_available_redraws(), run.get_owned_feature_ids()]
	store._map._focus_node(&"branching_nodes")
	await settle(0.20)
	expect(store._map.zoom > small and store._map.focusing, "Selecting an outer Store node smoothly zooms toward it (%d)" % width)
	await settle(0.13)
	var sliding_x := store._map.popup.position.x
	await settle(0.24)
	var node_rect: Rect2 = store._nodes[&"branching_nodes"].get_global_rect()
	expect(store._map.popup.position.x > sliding_x and store._map.popup.get_global_rect().position.x > node_rect.end.x, "Details slide right from the node border and finish on its right")
	expect(store.get_global_rect().encloses(store._map.popup.get_global_rect()) and store._map._map_rect().encloses(node_rect), "Focused node and right-hand menu fit onscreen")
	await shot("store-focus-%d" % width)
	store._map._focus_node(&"text")
	store._map._focus_node(&"save_files")
	await settle(0.56)
	expect(store._selected == &"save_files" and store._details.text.begins_with("Save Files"), "Rapid selection cancels the previous camera/menu animation")
	store._map._focus_node(&"colored_text")
	store._map.dismiss()
	await settle(0.56)
	expect(not store._map.popup.visible and not store._map.focusing, "Outside dismissal cancels pending zoom/menu callbacks")
	expect(before == [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_available_redraws(), run.get_owned_feature_ids()], "Store animations are entirely passive")
	game.queue_free()
	await process_frame

func _paid_hand() -> void:
	var game: Control = load("res://scenes/gameplay.tscn").instantiate()
	game.project_state = ProjectState.new(30)
	game.run_state = RunState.new()
	game.run_state.initialize_cash_cents(0)
	expect(game.run_state.set_studio_name("Paid animation fixture", &"action") and game.run_state.add_cash_cents(450001) and game.run_state.finalize_starter_selection(), "Paid fixture uses the named-Studio economy and native Action ownership")
	root.add_child(game)
	await process_frame
	var phase: DesignPhase = game.get("_active_phase")
	var project: ProjectState = game.project_state
	var run: RunState = game.run_state
	phase.get("_deal_rng").seed = 240930
	phase.get_workspace().overlay.commit_draft()
	await settle()
	var hand: Array[CardData] = []
	var views := phase.get_node("%HandContainer").get_children()
	for i in range(4):
		views[i].input_button.pressed.emit()
		hand.append(views[i].card_data)
	var cost := run.primitive_feature_hand_cost_cents(hand)
	expect(cost > 0, "Seeded native draw provides a paid Feature hand without fixture replacement")
	phase.get_node("%PlayCardButton").pressed.emit()
	var motion := phase.get_workspace().hand_motion
	expect(motion.busy and run.get_cash_cents() == 1000001 - cost and run.get_completed_run_cycles() == 1, "Paid animated hand spends the exact native quote once and keeps the one-cent remainder")
	var familiarity_ok := true
	for card in hand:
		if card.card_type == &"feature": familiarity_ok = familiarity_ok and run.get_feature_familiarity(card.id) == 1 and phase.get("_exhausted_card_ids").has(card.id)
	expect(familiarity_ok, "Animated Feature play grants normal familiarity and finite exhaustion exactly once")
	motion.cancel()
	run.spend_cash_cents(run.get_cash_cents())
	views = phase.get_node("%HandContainer").get_children()
	hand.clear()
	for i in range(4):
		views[i].input_button.pressed.emit()
		hand.append(views[i].card_data)
	cost = run.primitive_feature_hand_cost_cents(hand)
	var before := _snapshot(project, run)
	phase.get_node("%PlayCardButton").pressed.emit()
	expect(cost > 0 and not motion.busy and _snapshot(project, run) == before and phase.get_selected_candidate_views().size() == 4, "Unaffordable native hand preserves cash, cycles, redraws and selection without an animation")
	var pass_card: CardData = root.get_node("CardDatabase").get_card(&"graphics_pass")
	var timeline := HandPresentation.build_timeline([pass_card, pass_card, pass_card, pass_card], {&"graphics": 0}, {&"graphics": ProjectState.MAX_SIGNED_INT})
	var total := 0
	for row in timeline: total += row[&"graphics"]
	expect(total == ProjectState.MAX_SIGNED_INT and timeline.all(func(row): return row[&"graphics"] >= 0), "Presentation allocation retains exact totals near the signed-integer limit")
	game.queue_free()
	await process_frame

func _contract() -> void:
	var database := PrimitiveSnapshotDatabase.new()
	database.load_ledgers()
	var released := ProjectState.new(30)
	released.add_scope(30)
	released.initialize_snapshots(&"fast_follower", &"stable_market")
	released.finalize_design_bugs(false, 0, [], [])
	released.finalize_alpha(0, [], [])
	released.finalize_beta()
	released.commit_review_result(ReviewResult.new(PrimitiveReviewCalculator.get_baseline_profile(), {}, 0.0, 0.0, 0.0, 7.0, 1.0, 0, 0.0, 1.0, 50, 0.0, 7.0, 7.0))
	released.commit_awareness_result(PrimitiveAwarenessCalculator.calculate(released))
	released.commit_launch_market_context_result(PrimitiveLaunchMarketContextCalculator.calculate(released, database))
	released.set("_units_sold_result", UnitsSoldResult.new(&"primitive_units_sold_v1", &"month_1", 500, 70, 70, 100, 200, 300, 10000, 10000, 751, 1, 751.0, 751))
	released.commit_month_one_sales_revenue_result(PrimitiveMonthOneSalesRevenueCalculator.calculate(released))
	var run := RunState.new()
	run.initialize_cash(0)
	var studio: StudioPhase = load("res://scenes/phases/studio_phase.tscn").instantiate()
	root.add_child(studio)
	studio.setup(released, run, database)
	var state := run.accept_primitive_contract()
	var phase: ContractPhase = load("res://scenes/phases/contract_phase.tscn").instantiate()
	phase.setup(state, run)
	root.add_child(phase)
	phase.size = Vector2(1100, 580)
	var original_release := [released.get_current_scope(), released.get_current_cycle(), released.get_review_result()]
	for hand in range(2):
		var cards: Array[CardData] = []
		for i in range(7): cards.append(root.get_node("CardDatabase").get_card(&"graphics_pass"))
		phase._publish_candidate_pool(cards)
		await settle()
		for i in range(4): phase._candidate_row.get_child(i).input_button.pressed.emit()
		phase._play_button.pressed.emit()
		expect(phase.hand_motion.busy and state.get_successful_hand_count() == hand + 1, "Contract commits hand once before presentation")
		if hand == 1: expect(not phase._completion_panel.visible, "Contract completion waits until final hand finishes its visual sequence")
		if phase.hand_motion.busy: await phase.hand_motion.finished
		expect(state.get_core_score_half_units(0) == (hand + 1) * 24, "Contract animation preserves half-unit Specialization totals")
	expect(phase._completion_panel.visible and state.is_completed() and run.get_completed_run_cycles() == 2, "Final bounce reveals native completion with exactly two productive cycles")
	expect(original_release == [released.get_current_scope(), released.get_current_cycle(), released.get_review_result()], "Contract presentation leaves the frozen released project untouched")
	phase.queue_free()
	studio.queue_free()
	await process_frame
