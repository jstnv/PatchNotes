extends SceneTree

var failures := 0
var snapshots := PrimitiveSnapshotDatabase.new()


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + label)


func project_at(review: float, units: int, fans: int = 0) -> ProjectState:
	var project := ProjectState.new(30)
	project.initialize_snapshots(&"fast_follower", &"stable_market")
	project.finalize_design_bugs(false, 0, [&"text"], [])
	project.finalize_alpha(0, [], [])
	project.finalize_beta()
	project.commit_review_result(ReviewResult.new(PrimitiveReviewCalculator.get_baseline_profile(), {}, 0.0, 0.0, 0.0, review, 1.0, 0, 0.0, 1.0, 50, 0.0, review, review))
	project.commit_awareness_result(PrimitiveAwarenessCalculator.calculate(project, fans))
	project.commit_launch_market_context_result(PrimitiveLaunchMarketContextCalculator.calculate(project, snapshots))
	project.set("_units_sold_result", UnitsSoldResult.new(&"primitive_units_sold_v1", &"month_1", 500, 70, 70, 100, 200, 300, 10000, 10000, units, 1, float(units), units))
	project.commit_month_one_sales_revenue_result(PrimitiveMonthOneSalesRevenueCalculator.calculate(project))
	return project


func _run() -> void:
	snapshots.load_ledgers()
	var run := RunState.new()
	check(run.initialize_cash_cents(100000), "Fixture starts with cash")
	var first := project_at(7.0, 750)
	check(run.get_fans() == 0 and first.get_awareness_result().get_fan_awareness() == 0, "First game starts with no fans or fan Awareness")
	check(run.register_release(first) and run.get_fans() == 0, "Projection grants no fans")
	check(run.complete_productive_action() and run.get_fans() == 0, "First earning half grants no fans before month boundary")
	check(run.complete_productive_action() and run.get_fans() == 60, "750 actual earned units at Review 7 recruit 60 fans")
	var history := run.get_fanbase_history()
	check(history.size() == 1 and history[0].starting == 0 and history[0].gained == 60 and history[0].lost == 0, "Monthly starting, gained and lost totals reconcile")
	var frozen: int = run.get_released_game_sales(first.get_release_id()).launch_awareness
	var second := project_at(7.0, 750, run.get_fans())
	check(second.get_awareness_result().get_existing_fans() == 60 and second.get_awareness_result().get_fan_awareness() == 25, "Next launch snapshots 60 fans as 25 Awareness")
	check(run.register_release(second) and run.get_released_game_sales(first.get_release_id()).launch_awareness == frozen, "New fans do not rewrite an older launch")
	var before := run.get_fanbase_snapshot()
	check(not run.complete_productive_action(Callable(), 0, 1) and run.get_fanbase_snapshot() == before, "Duplicate callback leaves fans unchanged")
	check(run.complete_productive_action() and run.complete_productive_action(), "Concurrent releases earn across the next month")
	history = run.get_fanbase_history()
	check(history.size() == 2 and history[1].starting == 60 and history[1].ending == run.get_fans(), "Concurrent titles share the same pre-boundary fan snapshot")
	var second_entry: Dictionary = run.get_fanbase_snapshot().releases[second.get_release_id()]
	check(second_entry.gained <= 60 and second_entry.accounted_units >= 750, "Existing launch fans are excluded from their own title's recruits")
	var neutral := RunState.new()
	neutral.initialize_cash_cents(100000)
	var five := project_at(5.0, 750)
	check(neutral.register_release(five) and neutral.complete_productive_action() and neutral.complete_productive_action(), "Neutral game earns its Month 1 sales")
	check(neutral.get_fans() == 0 and neutral.get_fanbase_history()[0].net == 0, "Review exactly 5 remains fan-neutral")
	var poor := project_at(4.0, 400, run.get_fans())
	check(run.register_release(poor) and run.complete_productive_action() and run.complete_productive_action(), "Disappointing game settles alongside older releases")
	var loss_row: Dictionary = run.get_fanbase_history()[-1]
	check(loss_row.lost > 0 and run.get_fans() >= 0, "Poor Review loses only pre-existing fans, bounded at zero")
	var detached := run.get_fanbase_snapshot()
	detached.fans = 999999
	check(detached.fans != run.get_fans(), "Fan history is returned by value")
	var ledger := StudioFanbase.create()
	ledger.fans = 10
	var a := ReleasedGameSales.create(&"poor_a", 0, 0, 100, 10000)
	var b := ReleasedGameSales.create(&"poor_b", 0, 0, 100, 10000)
	ledger = StudioFanbase.register_release(ledger, a, 10)
	ledger = StudioFanbase.register_release(ledger, b, 10)
	var previous := {&"poor_a": a, &"poor_b": b}
	for cycle in range(1, 5):
		var next := {}
		for id: StringName in previous:
			next[id] = ReleasedGameSales.next_cycle(previous[id], cycle, cycle % 2 == 0)
		ledger = StudioFanbase.plan(ledger, previous, next, cycle)
		previous = next
		check(not ledger.is_empty(), "Zero-sales poor titles have valid fan preflight")
	var first_loss: Dictionary = ledger.months[0]
	var detail_losses := 0
	for detail: Dictionary in first_loss.releases: detail_losses += int(detail.lost_fans)
	check(first_loss.lost == 10 and detail_losses == 10 and first_loss.ending == 0, "Two poor zero-sales releases share the pre-boundary ten-fan loss cap")
	check(ledger.months[1].lost == 0 and ledger.fans == 0, "Cumulative exposure cannot recharge lost fans")
	print("Studio fanbase: %d failures" % failures)
	quit(failures)
