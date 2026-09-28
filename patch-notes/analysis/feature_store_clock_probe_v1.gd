## Read-only fixture for current Store timing and the central sales boundary.
extends SceneTree

var failures := 0
var snapshots := PrimitiveSnapshotDatabase.new()

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)
	else:
		print("PASS: " + label)

func _released_project(total: int) -> ProjectState:
	var project := ProjectState.new(30)
	project.initialize_snapshots(&"fast_follower", &"stable_market")
	project.finalize_design_bugs(false, 0, [], [])
	project.finalize_alpha(0, [], [])
	project.finalize_beta()
	project.commit_review_result(ReviewResult.new(PrimitiveReviewCalculator.get_baseline_profile(), {}, 0.0, 0.0, 0.0, 7.0, 1.0, 0, 0.0, 1.0, 50, 0.0, 7.0, 7.0))
	project.commit_awareness_result(PrimitiveAwarenessCalculator.calculate(project))
	project.commit_launch_market_context_result(PrimitiveLaunchMarketContextCalculator.calculate(project, snapshots))
	project.set("_units_sold_result", UnitsSoldResult.new(&"primitive_units_sold_v1", &"month_1", 500, 70, 70, 100, 200, 300, 10000, 10000, total, 1, float(total), total))
	project.commit_month_one_sales_revenue_result(PrimitiveMonthOneSalesRevenueCalculator.calculate(project))
	return project

func _snapshot(run: RunState, project: ProjectState) -> Array:
	return [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_available_redraws(),
		run.get_owned_feature_ids(), run.get_released_game_sales(project.get_release_id())]

func _run() -> void:
	snapshots.load_ledgers()
	var run := RunState.new()
	check(run.initialize_cash_cents(0) and run.set_studio_name("Clock Fixture"), "Named first Studio starts with authoritative cash")
	var before_starter := [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_available_redraws()]
	check(run.purchase_starter_feature(&"sprites") and run.get_cash_cents() == before_starter[0] - 45000 and run.get_completed_run_cycles() == 0, "Starter purchase spends exact cents and zero cycles")
	check(run.finalize_starter_selection(), "First Studio starter window closes")
	check(run.complete_productive_action(), "One productive cycle sets second-half release alignment")
	var project := _released_project(751)
	check(run.register_release(project), "Controlled release is registered once")
	var id := project.get_release_id()
	var before_browse := _snapshot(run, project)
	var root_quote := run.get_feature_store_offer(&"save_files")
	var child_before := run.get_feature_store_offer(&"branching_nodes")
	check(root_quote.price_cents == 220000 and not child_before.unlocked and _snapshot(run, project) == before_browse, "Store quote browsing is passive and child starts locked")
	check(not run.purchase_feature(&"branching_nodes") and _snapshot(run, project) == before_browse, "Locked child purchase rolls back")
	check(run.purchase_feature(&"save_files"), "Root purchase succeeds")
	var after_buy := _snapshot(run, project)
	check(after_buy[0] == before_browse[0] - 220000 and after_buy[1] == before_browse[1] and after_buy[2] == before_browse[2], "Current Store purchase costs cash but zero cycles or redraws")
	check(run.get_feature_store_offer(&"branching_nodes").unlocked, "Successful parent purchase immediately unlocks child")
	check(not run.purchase_feature(&"save_files") and _snapshot(run, project) == after_buy, "Duplicate Store purchase is a passive rejection")
	check(run.get_released_game_sales(id).earned_cycles == 0 and run.get_released_game_sales(id).settled_cents == 0, "Store purchase does not earn or settle sales")
	var expected_cycle := run.get_completed_run_cycles()
	check(run.complete_productive_action(Callable(), 0, expected_cycle), "Separate productive cycle crosses month boundary")
	var sales := run.get_released_game_sales(id)
	check(sales.earned_cycles == 1 and sales.earned_units == 375 and sales.settled_cents == 262237 and run.get_cash_cents() == int(after_buy[0]) + 262237, "Crossing action earns and settles exact cents after Store purchase")
	check(run.get_completed_run_cycles() == expected_cycle + 1 and run.get_available_redraws() == mini(RunState.MAX_REDRAWS, int(after_buy[2]) + 1), "Crossing action advances calendar and redraw recovery once")
	var after_cycle := _snapshot(run, project)
	check(not run.complete_productive_action(Callable(), 0, expected_cycle) and _snapshot(run, project) == after_cycle, "Repeated productive callback is atomic")
	var reserve_before := _snapshot(run, project)
	check(run.get_primitive_reserve_offer(&"music").price_cents == 45000 and run.purchase_primitive_reserve_feature(&"music"), "Unchosen Primitive can be purchased as a $450 reserve")
	var reserve_after := _snapshot(run, project)
	var reserve_sales := run.get_released_game_sales(id)
	check(int(reserve_after[0]) == int(reserve_before[0]) - 45000 and int(reserve_after[1]) == int(reserve_before[1]) + 1 and reserve_sales.earned_cycles == 2 and reserve_sales.settled_cents == 262237, "Reserve purchase charges one productive cycle, earns remaining units, and waits to settle")
	check(not run.purchase_primitive_reserve_feature(&"music") and _snapshot(run, project) == reserve_after, "Duplicate reserve purchase rolls back")
	var poor := RunState.new()
	check(poor.initialize_cash_cents(0) and poor.set_studio_name("Poor Fixture"), "Second first-Studio fixture starts")
	for starter_id: StringName in [&"sprites", &"scrolling", &"menu_system", &"multiple_endings", &"enemies", &"general_combat", &"levels", &"maps"]:
		check(poor.purchase_starter_feature(starter_id), "Legal starter fixture purchase: " + str(starter_id))
	check(poor.finalize_starter_selection() and poor.get_cash_cents() == 190000, "Legal 23-Scope pool leaves $1,900")
	var poor_before := [poor.get_cash_cents(), poor.get_completed_run_cycles(), poor.get_available_redraws(), poor.get_owned_feature_ids()]
	check(not poor.purchase_feature(&"save_files") and poor_before == [poor.get_cash_cents(), poor.get_completed_run_cycles(), poor.get_available_redraws(), poor.get_owned_feature_ids()], "Unaffordable Store purchase rejects without cash, calendar, redraw, or ownership mutation")
	print("Feature Store clock probe: %d failures" % failures)
	quit(failures)
