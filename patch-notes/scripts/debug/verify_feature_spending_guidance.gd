extends SceneTree

const OUT := "res://design-logs/spending-advice-v1"
var failures := 0
var snapshots := PrimitiveSnapshotDatabase.new()
var evidence: Array = []

func _initialize() -> void:
	go.call_deferred()

func check(ok: bool, label: String) -> void:
	print("PASS: " if ok else "FAIL: ", label)
	if not ok: failures += 1

func studio() -> RunState:
	var run := RunState.new()
	check(run.initialize_cash_cents(0) and run.create_studio("Budget", &"action", &"family_funding", []), "Create real studio funding/finance")
	return run

## Synthetic frozen release fixture, not a claimed played route.
func release_fixture(cycles: int) -> ProjectState:
	var p := ProjectState.new(30)
	p.initialize_snapshots(&"fast_follower", &"stable_market")
	for i in cycles: p.advance_cycle()
	p.finalize_design_bugs(false, 0, [&"text"], [])
	p.finalize_alpha(0, [], [])
	p.finalize_beta()
	p.commit_review_result(ReviewResult.new(PrimitiveReviewCalculator.get_baseline_profile(), {}, 0.0, 0.0, 0.0, 7.0, 1.0, 0, 0.0, 1.0, 50, 0.0, 7.0, 7.0))
	p.commit_awareness_result(PrimitiveAwarenessCalculator.calculate(p))
	p.commit_launch_market_context_result(PrimitiveLaunchMarketContextCalculator.calculate(p, snapshots))
	p.set("_units_sold_result", UnitsSoldResult.new(&"primitive_units_sold_v1", &"month_1", 500, 70, 70, 100, 200, 300, 10000, 10000, 751, 1, 751.0, 751))
	p.commit_month_one_sales_revenue_result(PrimitiveMonthOneSalesRevenueCalculator.calculate(p))
	return p

func state(run: RunState) -> Array:
	var titles: Array = []
	for id in run.get_released_game_ids(): titles.append([run.get_release_metadata(id), run.get_released_game_sales(id)])
	return [run.get_cash_cents(), run.get_completed_run_cycles(), run.get_available_redraws(), run.get_owned_feature_ids(), run.get_studio_finance_snapshot(), titles]

func pause_layout() -> void:
	for i in 6: await process_frame

func go() -> void:
	snapshots.load_ledgers()
	var run := studio()
	var before := state(run)
	check(not run.get_development_pacing().available and run.get_development_pacing().sample_count == 0, "No invented cycle average on a new run")
	var a := run.get_feature_spending_advice()
	check(a.available and not a.pacing_available and not a.complete and a.rent_cents == 0, "No-history quote explicitly lacks a rent horizon")
	check(FeatureSpendingGuidance.explanation(a).contains("Rent estimate unavailable"), "Missing history is never displayed as zero rent")
	var db := root.get_node("CardDatabase")
	var owned: Array[CardData] = []
	for id in run.get_owned_feature_ids(): owned.append(db.get_card(id))
	check(a.known_play_cost_cents == run.primitive_feature_hand_cost_cents(owned) and a.owned_feature_count == owned.size(), "Budget charges exactly the owned pool, not every purchasable branch")
	var reserve_id: StringName
	for entry: Dictionary in FeatureStoreCatalog.starting_features():
		if not run.owns_feature(StringName(entry.id)):
			reserve_id = StringName(entry.id)
			break
	var extra: Array[CardData] = [db.get_card(reserve_id)]
	var quote := run.get_feature_spending_advice(reserve_id)
	check(quote.known_play_cost_cents == a.known_play_cost_cents + run.primitive_feature_hand_cost_cents(extra) and quote.purchase_cycles == 0, "Starter preview includes selected Feature play cost, zero purchase cycles")
	check(not run.get_feature_spending_advice(&"animated_sprites").available and not run.get_feature_spending_advice(&"missing").available, "Unavailable and invalid quotes remain unavailable")
	check(state(run) == before, "All advisory queries preserve cash, cycles, redraws, ownership and journals")
	var unfinished := ProjectState.new(30)
	unfinished.advance_cycle()
	check(not run.register_release(unfinished) and run.get_development_pacing().sample_count == 0, "Unreleased/failed registrations do not become pacing samples")
	var first := release_fixture(11)
	var second := release_fixture(14)
	check(run.register_release(first) and run.register_release(second), "Register two independent frozen release IDs")
	var pace := run.get_development_pacing()
	check(pace.sample_count == 2 and pace.total_development_cycles == 25 and pace.average_development_cycles == 12.5 and pace.rounded_development_cycles == 13, "Exact average 11 and 14 is 12.5; rent uses ceil 13")
	check(run.register_release(first) and run.get_development_pacing() == pace, "Repeated release callback cannot double-count")
	pace.samples.clear()
	check(run.get_development_pacing().sample_count == 2 and run.get_development_pacing().samples.size() == 2, "Pacing snapshot is defensive")
	check(run.finalize_starter_selection(), "Close initial purchase window")
	a = run.get_feature_spending_advice()
	check(a.horizon_cycles == 14 and a.rent_boundaries == 7 and a.rent_cents == 350000, "Average rounds up, adds setup, projects seven exact monthly dues")
	check(run.complete_productive_action(), "Advance actual central cycle with release earning")
	quote = run.get_feature_spending_advice(reserve_id)
	check(quote.purchase_cycles == 1 and quote.horizon_cycles == 15 and quote.rent_boundaries == 8 and quote.rent_cents == 400000, "Second-half purchase plus setup correctly adds next boundary")
	var colored := run.get_feature_spending_advice(&"colored_text")
	check(colored.unpriced_count == 1 and not colored.complete and colored.purchase_cents == 65000, "Later Feature preview marks undefined play price without inventing cost")
	check(run.record_resolved_feature(ProjectState.new(30), &"text", &"design"), "Grant existing familiarity credit")
	colored = run.get_feature_spending_advice(&"colored_text")
	check(colored.purchase_cents == 58500 and colored.cash_after_price_cents == run.get_cash_cents() - 58500, "Advisory uses current exact familiarity discount")
	check(run.get_development_pacing().average_development_cycles == 12.5, "Studio cycles/familiarity never inflate development average")
	var history: Dictionary = run.get("_release_metadata").duplicate(true)
	history[first.get_release_id()].review.erase("development_cycles")
	check(FeatureSpendingGuidance.pacing(history).sample_count == 1 and FeatureSpendingGuidance.pacing(history).excluded_count == 1, "Missing legacy cycle provenance excluded, never fabricated")
	history[second.get_release_id()].review.development_cycles = -1
	check(not FeatureSpendingGuidance.pacing(history).available, "Invalid history has no pacing estimate")
	history = {&"a": {"review": {"development_cycles": RunState.MAX_SIGNED_INT}}, &"b": {"review": {"development_cycles": 1}}}
	check(not FeatureSpendingGuidance.pacing(history).available, "Cycle sum overflow safely unavailable")
	var pool := {"available": true, "known_play_cost_cents": 115000, "feature_count": 10, "unpriced_count": 0}
	var finance := {"available": true, "unpaid_rent_cents": 12345, "monthly_rent_cents": 50000}
	var p := FeatureSpendingGuidance.pacing({&"sample": {"review": {"development_cycles": 13}}})
	var boundary := FeatureSpendingGuidance.estimate(p, pool, finance, 0, 550000, 1, 0)
	check(boundary.reserve_cents == 477345 and boundary.cash_after_price_cents == 549999, "Known 14-cycle reserve sums $1150 play, $3500 rent and $123.45 arrears exactly")
	var exact := FeatureSpendingGuidance.estimate(p, pool, finance, 0, 477346, 1, 0)
	var short := FeatureSpendingGuidance.estimate(p, pool, finance, 0, 477345, 1, 0)
	check(not exact.below_reserve and short.below_reserve, "One-cent advisory threshold")
	check(not FeatureSpendingGuidance.estimate(p, pool, finance, RunState.MAX_SIGNED_INT, 100, 0, 0).available, "Calendar horizon overflow unavailable")
	pool.known_play_cost_cents = RunState.MAX_SIGNED_INT
	check(not FeatureSpendingGuidance.estimate(p, pool, finance, 0, 100, 0, 0).available, "Reserve arithmetic overflow unavailable")
	var restored := studio()
	restored.set("_released_games", bytes_to_var(var_to_bytes(run.get("_released_games"))))
	restored.set("_release_metadata", bytes_to_var(var_to_bytes(run.get("_release_metadata"))))
	check(restored.get_development_pacing() == run.get_development_pacing(), "Value reconstruction derives same tracker without replay callbacks")
	var warning_run := studio()
	check(warning_run.register_release(release_fixture(23)) and warning_run.finalize_starter_selection(), "Create synthetic long-development warning fixture")
	var warning := warning_run.get_feature_spending_advice(&"colored_text")
	check(warning.below_reserve and warning.purchase_affordable, "Affordable purchase can still warn against reserve pressure")
	await verify_ui(warning_run, &"colored_text", "warning")
	check(warning_run.purchase_feature(&"colored_text"), "Advisory does not block a legal purchase")
	before = state(warning_run)
	check(not warning_run.purchase_feature(&"colored_text") and state(warning_run) == before, "Duplicate rejection retains existing transaction rules")
	await verify_ui(studio(), reserve_id, "no-history")
	before = state(run)
	var saved: String = preload("res://scripts/debug/lifespan_capture.gd").save_capture(run)
	check(saved.begins_with("Saved locally: "), "Editor capture writes hidden tracker")
	if saved.begins_with("Saved locally: "):
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(saved.trim_prefix("Saved locally: ")))
		check(data.development_pacing.sample_count == 2 and data.development_pacing.average_development_cycles == 12.5 and data.feature_spending_advice.rent_cents == run.get_feature_spending_advice().rent_cents, "Capture contains observed average and advisory inputs/results")
	check(state(run) == before, "Capture remains passive")
	evidence.append({"label": "Synthetic calculation fixtures, not played routes", "pacing": run.get_development_pacing(), "advice": run.get_feature_spending_advice(), "warning": warning, "boundary": boundary})
	DirAccess.make_dir_recursive_absolute(OUT)
	FileAccess.open(OUT + "/fixtures.json", FileAccess.WRITE).store_string(JSON.stringify(evidence, "\t"))
	print("Spending guidance: ", failures, " failures")
	quit(failures)

func verify_ui(run: RunState, id: StringName, label: String) -> void:
	for size: Vector2i in [Vector2i(1152,648), Vector2i(1280,720)]:
		root.size = size
		root.content_scale_size = size
		var store := FeatureStore.new()
		root.add_child(store)
		store.setup(run)
		store.open_store()
		await pause_layout()
		var before := state(run)
		store._select_node(id)
		await create_timer(0.6).timeout
		check(not store._spending_advice.text.is_empty() and root.get_visible_rect().encloses(store._spending_advice.get_global_rect()), "Spending advice visible at " + str(size))
		check(not store._spending_advice.text.contains("23") and not store._spending_advice.text.contains("average"), "Internal average is not a player-facing stat")
		check(root.get_visible_rect().encloses(store._buy.get_global_rect()) and not store._buy.disabled, "Advisory leaves reachable legal Purchase at " + str(size))
		if "--capture" in OS.get_cmdline_user_args():
			DirAccess.make_dir_recursive_absolute(OUT + "/rendered")
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUT + "/rendered/%s-%d.png" % [label, size.x])
		store._map.dismiss()
		check(store._spending_advice.text.begins_with("Next game"), "Closing details restores owned-only budget")
		store.hide()
		store.open_store()
		check(state(run) == before, "Browse/reopen/animate has zero transactions")
		store.queue_free()
		await process_frame
