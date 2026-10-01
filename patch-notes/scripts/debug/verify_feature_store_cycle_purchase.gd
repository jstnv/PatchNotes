extends SceneTree

var failures := 0
var snapshots := PrimitiveSnapshotDatabase.new()


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: " + label)
	else:
		failures += 1
		push_error("FAIL: " + label)


func _released_project(units: int) -> ProjectState:
	var project := ProjectState.new(30)
	project.initialize_snapshots(&"fast_follower", &"stable_market")
	project.finalize_design_bugs(false, 0, [&"text"], [])
	project.finalize_alpha(0, [], [])
	project.finalize_beta()
	project.commit_review_result(ReviewResult.new(PrimitiveReviewCalculator.get_baseline_profile(), {}, 0.0, 0.0, 0.0, 7.0, 1.0, 0, 0.0, 1.0, 50, 0.0, 7.0, 7.0))
	project.commit_awareness_result(PrimitiveAwarenessCalculator.calculate(project))
	project.commit_launch_market_context_result(PrimitiveLaunchMarketContextCalculator.calculate(project, snapshots))
	project.set("_units_sold_result", UnitsSoldResult.new(&"primitive_units_sold_v1", &"month_1", 500, 70, 70, 100, 200, 300, 10000, 10000, units, 1, float(units), units))
	project.commit_month_one_sales_revenue_result(PrimitiveMonthOneSalesRevenueCalculator.calculate(project))
	return project


func _snapshot(run: RunState, project: ProjectState) -> Array:
	return [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_available_redraws(),
		run.get_owned_feature_ids(), run.get_released_game_sales(project.get_release_id())]


func _run() -> void:
	snapshots.load_ledgers()
	var run := RunState.new()
	check(run.initialize_cash_cents(0) and run.set_studio_name("Cycle Store", &"adventure"), "Named Studio receives authoritative $5,500")
	check(run.purchase_starter_feature(&"sprites") and run.get_cash_cents() == 505000 and run.get_completed_run_cycles() == 0, "First-game starter purchase remains zero-cycle")
	check(run.finalize_starter_selection() and run.complete_productive_action(), "Starter window closes and controlled clock reaches second half")
	var project := _released_project(751)
	check(run.register_release(project), "Controlled 751-unit release registers")
	check(run.consume_redraw(2) and run.get_available_redraws() == 2, "Fixture spends two redraws before Store purchase")
	var before := _snapshot(run, project)
	check(not run.purchase_feature(&"branching_nodes") and _snapshot(run, project) == before, "Locked child rejection preserves cash, clock, redraws, ownership and sales")
	check(run.get_feature_store_offer(&"save_files").price_cents == 220000 and _snapshot(run, project) == before, "Browsing Store quotes is passive")
	check(run.purchase_feature(&"save_files"), "Root purchase succeeds at shared productive boundary")
	var sales := run.get_released_game_sales(project.get_release_id())
	check(run.get_cash_cents() == 547237 and run.get_completed_run_cycles() == 2 and run.get_available_redraws() == 3, "Root spends $2,200, earns one cycle, settles $2,622.37 and restores one redraw")
	check(sales.earned_cycles == 1 and sales.earned_units == 375 and sales.settled_cents == 262237, "Month-boundary sales commit once with Store purchase")
	check(run.get_feature_store_offer(&"branching_nodes").unlocked, "Parent ownership unlocks child without playing it")
	var after_root := _snapshot(run, project)
	check(not run.purchase_feature(&"save_files") and _snapshot(run, project) == after_root, "Duplicate purchase neither reearns nor resettles sales")
	check(run.purchase_feature(&"branching_nodes") and run.get_completed_run_cycles() == 3 and run.get_cash_cents() == 397237 and run.get_available_redraws() == 4, "Child purchase spends $1,500 and one later half-month cycle")
	sales = run.get_released_game_sales(project.get_release_id())
	check(sales.earned_cycles == 2 and sales.earned_units == 751 and sales.settled_cents == 262237, "Second sales cycle earns remaining units but waits for next month to settle")
	var next := PrimitivePredevelopment.prepare_project("Next Store Game", &"action", &"fantasy", run)
	check(next.get_feature_supply_ids().has(&"save_files") and next.get_feature_supply_ids().has(&"branching_nodes"), "Purchased nodes enter next project's eligible supply")
	var poor := RunState.new()
	check(poor.initialize_cash_cents(64999), "Legacy one-cent-short fixture starts")
	var poor_before := [poor.get_cash_cents(), poor.get_completed_run_cycles(), poor.get_available_redraws(), poor.get_owned_feature_ids()]
	check(not poor.purchase_feature(&"colored_text") and poor_before == [poor.get_cash_cents(), poor.get_completed_run_cycles(), poor.get_available_redraws(), poor.get_owned_feature_ids()], "Unaffordable purchase rolls back")
	var overflowing := RunState.new()
	check(overflowing.initialize_cash_cents(0) and overflowing.set_studio_name("Overflow Store", &"adventure") and overflowing.finalize_starter_selection() and overflowing.complete_productive_action(), "Overflow fixture reaches second-half release alignment")
	var overflow_project := _released_project(751)
	check(overflowing.register_release(overflow_project), "Overflow fixture registers a paying release")
	overflowing.set("_cash_cents", RunState.MAX_SIGNED_INT - 100)
	var overflow_before := _snapshot(overflowing, overflow_project)
	check(not overflowing.purchase_feature(&"save_files") and _snapshot(overflowing, overflow_project) == overflow_before, "Combined purchase and settlement overflow rejects atomically")
	overflowing.set("_completed_run_cycles", RunState.MAX_SIGNED_INT)
	var clock_before := _snapshot(overflowing, overflow_project)
	check(not overflowing.purchase_feature(&"save_files") and _snapshot(overflowing, overflow_project) == clock_before, "Calendar overflow rejects before ownership or cash mutation")
	print("Feature Store productive-cycle verification: %d failures" % failures)
	quit(failures)
