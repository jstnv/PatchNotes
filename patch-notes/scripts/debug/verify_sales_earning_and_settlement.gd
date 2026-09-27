extends SceneTree

var failures := 0
var snapshots := PrimitiveSnapshotDatabase.new()

func _initialize() -> void:
	call_deferred("_verify")

func expect(ok: bool, message: String) -> void:
	if ok: print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func release(total: int) -> ProjectState:
	var project := ProjectState.new(30)
	project.initialize_snapshots(&"fast_follower", &"stable_market")
	project.finalize_design_bugs(false, 0, [], [])
	project.finalize_alpha(0, [], [])
	project.finalize_beta()
	project.commit_review_result(ReviewResult.new(PrimitiveReviewCalculator.get_baseline_profile(), {}, 0.0, 0.0, 0.0, 7.0, 1.0, 0, 0.0, 1.0, 50, 0.0, 7.0, 7.0))
	project.commit_awareness_result(PrimitiveAwarenessCalculator.calculate(project))
	project.commit_launch_market_context_result(PrimitiveLaunchMarketContextCalculator.calculate(project, snapshots))
	# Controlled unit oracle; all downstream production code uses the real result.
	project.set("_units_sold_result", UnitsSoldResult.new(&"primitive_units_sold_v1", &"month_1", 500, 70, 70, 100, 200, 300, 10000, 10000, total, 1, float(total), total))
	project.commit_month_one_sales_revenue_result(PrimitiveMonthOneSalesRevenueCalculator.calculate(project))
	return project

func new_run(cents: int = 0, initial_cycles: int = 0) -> RunState:
	var run := RunState.new()
	run.initialize_cash_cents(cents)
	for i in range(initial_cycles): run.advance_calendar_cycle()
	return run

func snapshot(run: RunState, project: ProjectState) -> Array:
	return [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_available_redraws(), run.get_released_game_sales(project.get_release_id())]

func _verify() -> void:
	snapshots.load_ledgers()
	_verify_oracle()
	_verify_atomicity()
	await _verify_studio()
	await _verify_actions()
	print("Sales earning and settlement verification: %d failures" % failures)
	quit(failures)

func _verify_oracle() -> void:
	var project := release(751)
	var run := new_run(1, 1)
	var signals := [0, 0]
	run.cash_changed.connect(func(): signals[0] += 1)
	run.sales_changed.connect(func(): signals[1] += 1)
	expect(run.register_release(project), "Release registration succeeds")
	var id := project.get_release_id()
	var initial := snapshot(run, project)
	expect(run.register_release(project) and snapshot(run, project) == initial and signals == [0, 1], "Registration is one-shot and pays/earns nothing")
	var copy := run.get_released_game_sales(id)
	copy.earned_cycles = 2
	expect(run.get_released_game_sales(id).earned_cycles == 0, "Sales query returns an isolated snapshot")
	var expected_cycle := run.get_completed_run_cycles()
	expect(run.complete_productive_action(Callable(), 0, expected_cycle), "First post-release crossing action succeeds")
	var record := run.get_released_game_sales(id)
	expect(record.earned_cycles == 1 and record.earned_units == 375 and record.entitlement_cents == 262237 and record.settled_cents == 262237 and run.get_cash_cents() == 262238, "751 oracle: crossing earns before settling exact 262237 cents")
	var after := snapshot(run, project)
	expect(not run.complete_productive_action(Callable(), 0, expected_cycle) and snapshot(run, project) == after, "Repeated completion callback with original cycle rejects atomically")
	run.complete_productive_action()
	record = run.get_released_game_sales(id)
	expect(record.earned_cycles == 2 and record.earned_units == 751 and record.entitlement_cents == 525174 and record.settled_cents == 262237 and run.get_cash_cents() == 262238, "Non-boundary second cycle earns but pays nothing")
	run.complete_productive_action()
	record = run.get_released_game_sales(id)
	expect(record.settled_cents == 525174 and run.get_cash_cents() == 525175 and signals[0] == 2, "Following boundary pays remaining 262937 cents once")
	for i in range(4): run.complete_productive_action()
	record = run.get_released_game_sales(id)
	expect(record.exhausted and record.earned_cycles == 2 and record.earned_units == 751 and run.get_cash_cents() == 525175 and signals[0] == 2, "Exhaustion prevents later earning; zero payable emits no cash signal")
	expect(project.get_month_one_sales_revenue_result().get_net_cents_previously_settled() == 0 and project.get_current_cycle() == 0, "Released ProjectState stays frozen")
	for units in [750, 751, 1, 0]:
		var p := release(units)
		var r := new_run()
		r.register_release(p)
		r.complete_productive_action()
		expect(r.get_released_game_sales(p.get_release_id()).earned_units == units / 2 and r.get_cash_cents() == 0, "First non-crossing split earns floor(total/2) for %d units" % units)
		r.complete_productive_action()
		expect(r.get_released_game_sales(p.get_release_id()).earned_units == units and r.get_cash_cents() == p.get_month_one_sales_revenue_result().get_projected_month_one_net_cents(), "Both cycles settle cumulatively at one boundary for %d units" % units)
	var recreated := release(751)
	recreated.set("_release_id", id)
	var before := snapshot(run, project)
	expect(run.register_release(recreated) and snapshot(run, project) == before, "Reconstructed project with same stable release ID reuses history")
	expect(run.register_release(release(751)) and run.get_released_game_ids().size() == 2, "Next-project releases register independently while retaining earlier history")

func _verify_atomicity() -> void:
	var p := release(751)
	var run := new_run(RunState.MAX_SIGNED_INT - 262236, 1)
	run.register_release(p)
	run.consume_redraw(3)
	var before := snapshot(run, p)
	var touched := [false]
	var commit := func() -> bool:
		touched[0] = true
		return true
	expect(not run.complete_productive_action(commit) and not touched[0] and snapshot(run, p) == before, "Settlement overflow rejects before direct effects, calendar, redraw and sales mutation")
	run.spend_cash_cents(1)
	expect(run.complete_productive_action(commit) and run.get_cash_cents() == RunState.MAX_SIGNED_INT, "Exact maximum cash is representable")
	var failed := new_run(9)
	failed.register_release(p)
	before = snapshot(failed, p)
	expect(not failed.complete_productive_action(func() -> bool: return false) and snapshot(failed, p) == before, "Failed atomic direct action leaves every run field unchanged")
	var combined := new_run(RunState.MAX_SIGNED_INT - 300000, 1)
	combined.register_release(p)
	before = snapshot(combined, p)
	expect(not combined.complete_productive_action(commit, 100000) and snapshot(combined, p) == before, "Direct income plus settlement overflow rejects as one action")
	var spending := new_run(RunState.MAX_SIGNED_INT - 220000, 1)
	spending.register_release(p)
	expect(spending.complete_productive_action(commit, -50000) and spending.get_cash_cents() == RunState.MAX_SIGNED_INT - 7763, "Preflight accounts for direct spending before settlement")
	var corrupt := new_run(0, 1)
	corrupt.register_release(p)
	var records: Dictionary = corrupt.get("_released_games")
	records[p.get_release_id()].earned_cycles = 3
	before = snapshot(corrupt, p)
	expect(not corrupt.complete_productive_action(commit) and snapshot(corrupt, p) == before, "Invalid sales state rejects without partial writes")
	var calendar_overflow := new_run()
	calendar_overflow.set("_completed_run_cycles", RunState.MAX_SIGNED_INT)
	expect(not calendar_overflow.complete_productive_action(commit), "Calendar overflow rejects")
	expect(ReleasedGameSales.create(&"overflow", RunState.MAX_SIGNED_INT).is_empty(), "Revenue arithmetic overflow rejects registration input")
	var zero := new_run(123, 1)
	zero.register_release(release(0))
	var cash_signals := [0]
	zero.cash_changed.connect(func(): cash_signals[0] += 1)
	zero.complete_productive_action()
	expect(zero.get_cash_cents() == 123 and cash_signals[0] == 0, "Zero-unit settlement is a signal-free cash no-op")
	var reentrant := new_run(0, 1)
	reentrant.register_release(p)
	var observed := [false]
	reentrant.cash_changed.connect(func():
		observed[0] = reentrant.get_released_game_sales(p.get_release_id()).settled_cents == 262237
		expect(reentrant.can_complete_productive_cycle() and reentrant.can_consume_redraw(), "Notifications expose ready-state queries to UI")
		expect(not reentrant.complete_productive_action(), "Reentrant settlement callback cannot advance twice"))
	reentrant.complete_productive_action()
	expect(observed[0] and reentrant.get_completed_run_cycles() == 2, "Cash observers see complete sales/calendar transaction")

func _verify_studio() -> void:
	var p := release(751)
	var run := new_run(1)
	var studio: StudioPhase = load("res://scenes/phases/studio_phase.tscn").instantiate()
	root.add_child(studio)
	expect(studio.setup(p, run, snapshots), "Studio entry registers release")
	expect(run.get_released_game_sales(p.get_release_id()).earned_cycles == 0 and run.get_cash_cents() == 1, "Launch/Studio starts with zero earned and settled sales")
	run.complete_productive_action()
	expect(studio.get_node("%ProjectedRevenueLabel").text.contains("$5251.74") and studio.get_node("%EntitledLabel").text.contains("$2622.37") and studio.get_node("%SettledLabel").text.contains("$0.00") and studio.get_node("%UnpaidLabel").text.contains("$2622.37"), "Studio distinguishes projection, earned, settled and unpaid values")
	var before := snapshot(run, p)
	expect(studio.setup(p, run, snapshots) and snapshot(run, p) == before, "Studio reconstruction neither earns nor settles")
	studio.call("_open_feature_store")
	var store: FeatureStore = studio.get("_feature_store")
	store.hide()
	expect(snapshot(run, p) == before, "Feature Store browsing stays zero-cycle")
	run.complete_productive_action()
	expect(studio.get_node("%SettledLabel").text.contains("$5251.74") and studio.get_node("%UnpaidLabel").text.contains("$0.00") and studio.get_node("%ExhaustionLabel").text.contains("exhausted"), "Live summary updates at settlement and exhaustion")
	studio.queue_free()
	await process_frame

func _verify_actions() -> void:
	# Integration fixture: an existing action with a prior registered release.
	# This does not add or simulate a player-facing new-project flow.
	var released := release(751)
	var run := new_run(RunState.MAX_SIGNED_INT - 1000, 1)
	run.register_release(released)
	var project := ProjectState.new(30)
	var design: DesignPhase = load("res://scenes/phases/design_phase.tscn").instantiate()
	design.setup(project, run)
	root.add_child(design)
	design.get_workspace().overlay.cancel()
	expect(design.begin_design(), "Existing Design fixture begins")
	var views := design.get_node("%HandContainer").get_children()
	for i in range(4): views[i].input_button.pressed.emit()
	var before := snapshot(run, released)
	design.call("_on_play_card_pressed")
	expect(snapshot(run, released) == before and project.get_current_cycle() == 0 and project.get_current_scope() == 0 and design.get("_selected_card_views").size() == 4, "Real production rejects settlement overflow before scores, selection or lifecycle change")
	run.spend_cash_cents(300000)
	design.call("_on_play_card_pressed")
	expect(project.get_current_cycle() == 1 and run.get_completed_run_cycles() == 2 and run.get_released_game_sales(released.get_release_id()).earned_cycles == 1, "Real production advances each clock and sales exactly once")
	design.queue_free()
	await process_frame
