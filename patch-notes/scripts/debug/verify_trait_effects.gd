extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failures += 1
func _initialize() -> void:
	for test: Array in [[[],570000,100],[ [&"family_funding"],590000,100],[ [&"studio_buzz"],565000,103],[ [&"unknown_name"],580000,90],[ [&"unknown_name",&"studio_buzz"],575000,93],[ [&"unknown_name",&"family_funding"],600000,90]]:
		var run := RunState.new()
		run.initialize_cash_cents(0)
		check(run.create_studio_with_traits("Effects", &"action", test[0]) and run.get_cash_cents() == test[1], "Approved startup: " + str(test[0]))
		check(run.trait_launch_awareness(100) == test[2], "First Awareness: " + str(test[0]))
		var selection := run.get_studio_traits()
		check(StudioTraits.launch_awareness(selection, 100, false) == (103 if &"studio_buzz" in test[0] else 100), "Unknown expires, Buzz remains")
		check(bytes_to_var(var_to_bytes(selection)) == selection, "Selection typed reconstruction exact")
		if &"family_funding" in test[0]:
			var tx: Array = run.get_studio_finance_snapshot().transactions
			check(tx.size() == 3 and tx[2].source_id == &"studio_trait_family_funding_v1" and tx[2].amount_cents == 30000, "Family has separate financing receipt")
	var unknown := StudioTraits.evaluate_traits([&"unknown_name"])
	check(StudioTraits.launch_awareness(unknown,7,true) == 0, "Unknown floors at zero")
	check(StudioTraits.launch_awareness(unknown,134,true) == 124 and StudioTraits.launch_awareness(unknown,135,true) == 125, "Neon threshold boundary")
	check(StudioTraits.launch_awareness(StudioTraits.evaluate(&"family_funding",[&"studio_buzz",&"unknown_name"]),100,true) == 100, "Legacy preview remains inactive")
	for marketing in [34,35]:
		var run := RunState.new()
		run.initialize_cash_cents(0)
		run.create_studio_with_traits("Launch", &"action", [&"unknown_name"])
		check(not run.register_release(null) and run.trait_launch_awareness(100) == 90, "Rejected release does not spend first-launch penalty")
		var project := ready_project(run, marketing)
		check(project != null and project.get_awareness_result().get_total_awareness() == 90 + marketing, "Native calculator freezes adjusted Awareness")
		check(run.register_release(project), "Native release registers")
		var snapshot := run.get_released_game_sales(project.get_release_id())
		check(snapshot.launch_awareness == 90 + marketing and run.get_release_metadata(project.get_release_id()).review.awareness == snapshot.launch_awareness, "Sales/history share frozen value")
		check((PublisherCatalog.NEON_CIRCUIT in run.get_unlocked_publisher_ids()) == (marketing == 35), "Native Neon profile threshold uses frozen Awareness")
		check(run.register_release(project) and run.get_released_game_ids().size() == 1 and run.trait_launch_awareness(100) == 100, "Duplicate registration cannot consume another first release")
		var second := ready_project(run, 0)
		check(run.register_release(second) and second.get_awareness_result().get_total_awareness() == 100, "Second release has no Unknown penalty")
	print("Trait effects verification: %d failures" % failures)
	quit(failures)

func ready_project(run: RunState, marketing: int) -> ProjectState:
	var project := PrimitivePredevelopment.prepare_project("Launch", &"action", &"fantasy", run)
	var snapshots := PrimitiveSnapshotDatabase.new()
	snapshots.load_ledgers()
	var scores: Dictionary[ProjectState.CoreScore, int] = {0:30,1:30,2:30,3:30}
	project.add_core_scores_and_scope(scores,30)
	project.initialize_snapshots(&"fast_follower", &"stable_market")
	project.finalize_design_bugs(false,0,[&"text"],[])
	project.finalize_alpha(0,[],[])
	project.set("_marketing_output",marketing)
	project.finalize_beta()
	project.commit_review_result(PrimitiveReviewCalculator.calculate(project,50))
	project.commit_awareness_result(PrimitiveAwarenessCalculator.calculate(project,run))
	project.commit_launch_market_context_result(PrimitiveLaunchMarketContextCalculator.calculate(project,snapshots))
	project.commit_units_sold_result(PrimitiveUnitsSoldCalculator.calculate(project))
	project.commit_month_one_sales_revenue_result(PrimitiveMonthOneSalesRevenueCalculator.calculate(project))
	return project

