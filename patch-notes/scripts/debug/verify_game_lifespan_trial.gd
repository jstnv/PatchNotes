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


func _released_project(review: float, units: int) -> ProjectState:
	var project := ProjectState.new(30)
	project.initialize_snapshots(&"fast_follower", &"stable_market")
	project.finalize_design_bugs(false, 0, [], [])
	project.finalize_alpha(0, [], [])
	project.finalize_beta()
	project.commit_review_result(ReviewResult.new(PrimitiveReviewCalculator.get_baseline_profile(), {}, 0.0, 0.0, 0.0, review, 1.0, 0, 0.0, 1.0, 50, 0.0, review, review))
	project.commit_awareness_result(PrimitiveAwarenessCalculator.calculate(project))
	project.commit_launch_market_context_result(PrimitiveLaunchMarketContextCalculator.calculate(project, snapshots))
	project.set("_units_sold_result", UnitsSoldResult.new(&"primitive_units_sold_v1", &"month_1", 500, 70, 70, 100, 200, 300, 10000, 10000, units, 1, float(units), units))
	project.commit_month_one_sales_revenue_result(PrimitiveMonthOneSalesRevenueCalculator.calculate(project))
	return project


func _snapshot(run: RunState, id: StringName) -> Array:
	return [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_available_redraws(), run.get_released_game_sales(id)]


func _run() -> void:
	snapshots.load_ledgers()
	var run := RunState.new()
	check(run.initialize_cash_cents(200000), "Campaign fixture begins with exact-cent cash")
	var strong := _released_project(7.0, 751)
	check(run.register_release(strong), "Strong release registers with frozen sales inputs")
	var id := strong.get_release_id()
	var record := run.get_released_game_sales(id)
	check(record.get("review_tenths", -1) == 70 and record.get("market_bp", -1) == strong.get_launch_market_context_result().get_forecast_multiplier_basis_points() and record.get("launch_awareness", -1) == strong.get_awareness_result().get_total_awareness(), "Review, launch Awareness and concealed market basis points freeze at release")
	check(not run.get_post_launch_campaign_offer(id).can_purchase, "Campaign cannot spend during Month 1")
	check(run.complete_productive_action() and run.complete_productive_action(), "Two productive cycles earn Month 1")
	record = run.get_released_game_sales(id)
	check(record.earned_cycles == 2 and record.earned_units == 751 and record.settled_cents == 525174 and run.get_cash_cents() == 725174, "Month 1 keeps its 751-unit cumulative exact-cent settlement")
	var projection := ReleasedGameSales.get_projection(record)
	check(projection.next_age_month == 2 and projection.next_age_cycle == 1 and run.get_post_launch_campaign_offer(id).can_purchase, "First Month 2 release-age cycle offers a campaign")
	var before := _snapshot(run, id)
	check(run.purchase_post_launch_campaign(id, 2), "Selected release receives its first campaign")
	record = run.get_released_game_sales(id)
	check(run.get_completed_run_cycles() == 3 and record.get("campaign_count", -1) == 1 and record.get("total_earned_cycles", -1) == 3 and run.get_cash_cents() == int(before[0]) - 10000, "Campaign spends $100 and one cycle before settlement, without early cash")
	var after := _snapshot(run, id)
	check(not run.purchase_post_launch_campaign(id, 2) and not run.purchase_post_launch_campaign(id, 3) and _snapshot(run, id) == after, "Repeated and same-age-month callbacks do not stack or mutate")
	check(run.complete_productive_action() and run.get_completed_run_cycles() == 4, "Second Month 2 cycle crosses the calendar boundary")
	record = run.get_released_game_sales(id)
	check(record.settled_cents == record.entitlement_cents and record.earned_units > 751, "Later-month earned net settles once at the next boundary")
	check(run.get_post_launch_campaign_offer(id).can_purchase, "A fresh release-age month may offer a separate campaign")
	var weak_run := RunState.new()
	weak_run.initialize_cash_cents(200000)
	var weak := _released_project(2.0, 751)
	check(weak_run.register_release(weak) and weak_run.complete_productive_action() and weak_run.complete_productive_action(), "Matched weak Review keeps identical Month 1 units")
	var weak_projection := ReleasedGameSales.get_projection(weak_run.get_released_game_sales(weak.get_release_id()))
	check(weak_projection.projected_month_units < projection.projected_month_units, "Stronger Review produces more later units at matched launch units")
	var studio: StudioPhase = load("res://scenes/phases/studio_phase.tscn").instantiate()
	root.add_child(studio)
	check(studio.setup(strong, run, snapshots), "Studio reconstructs a released title after a campaign")
	studio.open_summary()
	check(studio.get_node("%CurrentAgeLabel").text.contains("Month 3") and studio.get_node("%CampaignButton").visible and not studio.get_node("%CampaignButton").disabled and studio.get_node("%LaterProjectedUnitsLabel").text.contains("organic"), "Browsable release summary shows age, next sales and campaign action")
	if "--capture-lifespan" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://design-logs/lifespan-trial-studio.png")
	var reconstruction := _snapshot(run, id)
	studio.close_summary()
	studio.open_summary()
	check(_snapshot(run, id) == reconstruction, "Summary browsing and reconstruction preserve cash, time and sales")
	studio.queue_free()
	await process_frame
	var poor := RunState.new()
	poor.initialize_cash_cents(0)
	var poor_project := _released_project(7.0, 0)
	check(poor.register_release(poor_project) and poor.complete_productive_action() and poor.complete_productive_action(), "Zero-sale fixture reaches Month 2")
	var poor_id := poor_project.get_release_id()
	var poor_before := _snapshot(poor, poor_id)
	check(not poor.purchase_post_launch_campaign(poor_id, 2) and _snapshot(poor, poor_id) == poor_before, "Unaffordable campaign rejects without any mutation")
	var overflow := RunState.new()
	overflow.initialize_cash_cents(0)
	check(overflow.complete_productive_action(), "Overflow fixture aligns release with second half")
	var overflow_project := _released_project(7.0, 751)
	check(overflow.register_release(overflow_project) and overflow.complete_productive_action() and overflow.complete_productive_action(), "Overflow fixture reaches Month 2")
	var overflow_id := overflow_project.get_release_id()
	overflow.set("_cash_cents", RunState.MAX_SIGNED_INT - 1)
	var overflow_before := _snapshot(overflow, overflow_id)
	check(not overflow.purchase_post_launch_campaign(overflow_id, 3) and _snapshot(overflow, overflow_id) == overflow_before, "Campaign plus prospective sales overflow rejects atomically")
	print("Playable lifespan trial verification: %d failures" % failures)
	quit(failures)
