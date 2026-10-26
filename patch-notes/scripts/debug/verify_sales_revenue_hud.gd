extends "res://scripts/debug/verify_rival_gameplay_activation.gd"

const Replay := preload("res://scripts/simulation/development_replay.gd")
var observations: Array = []

func _initialize() -> void:
	await process_frame
	create_timer(120).timeout.connect(func(): push_error("Sales HUD verifier timeout"); quit(2))
	var run := fixture_run()
	var hud := SalesRevenueHUD.new()
	root.add_child(hud)
	hud.bind_run(run)
	hud.set_context(true)
	expect(not hud.visible and hud.model.is_empty(),"No sales indicator before any release")
	var first := release_fixture(run,"First",0.0)
	await settle()
	expect(hud.visible and hud.model.total_cents == 0 and hud.model.market_count == 1,"Launch shows zero earned revenue, no forecast income")
	expect(run.complete_productive_action(),"First earning half commits")
	await settle()
	var before := Replay.digest(run)
	var target: float = hud._target[1]
	var partial: float = hud.chart.displayed[1]
	expect(target > 0 and partial < target,"New earnings animate the bar upward")
	paused = true
	await create_timer(0.15).timeout
	expect(hud.chart.displayed[1] == partial and Replay.digest(run) == before,"Pause freezes chart and leaves authoritative state untouched")
	paused = false
	await create_timer(0.75).timeout
	expect(hud.chart.displayed[1] == target and not hud.is_processing(),"Bar reaches its exact target then stops processing")
	expect(Replay.digest(run) == before,"Animation creates no cash, cycles, sales or RNG draws")
	expect(hud.model.unpaid_cents == hud.model.total_cents and hud.model.settled_cents == 0,"Earned half-month is distinct from paid cash")
	# Opposite launch alignment and concurrent titles exercise calendar aggregation.
	var second := release_fixture(run,"Second",0.0)
	await settle()
	for cycle in range(2,33):
		expect(run.complete_productive_action(),"Productive cycle %d" % cycle)
		await settle()
		check_model(run,hud)
		var stable := hud.model.duplicate(true)
		run.sales_changed.emit()
		run.sales_changed.emit()
		await settle()
		expect(hud.model == stable,"Repeated notifications never add a bar or revenue")
	expect(hud.model.rows.size() == 12 and hud.model.rows[0].month == 6 and hud.model.rows[-1].month == 17,"Rolling window advances beyond twelve months")
	# Existing sales rules retain dormant titles; a campaign can revive one.
	expect(ReleasedGameSales.get_projection(run.get_released_game_sales(first.get_release_id())).projected_month_units == 0,"Fixture has reached a zero-unit sales tail")
	expect(hud.visible and hud.model.market_count == 2,"Dormant on-market titles keep the indicator present")
	var earned: int = hud.model.total_cents
	expect(run.purchase_post_launch_campaign(first.get_release_id(),run.get_completed_run_cycles()),"Legal campaign revives an eligible dormant title")
	await settle()
	expect(hud.model.total_cents > earned,"Revival adds only actual newly earned revenue")
	check_model(run,hud)
	# Existing checkpoint codec supplies the history; there is no new HUD save state.
	var adapter := StudioCheckpoint.new()
	var payload := adapter.capture(run)
	expect(not payload.is_empty(),"Sales fixture captures a valid Studio checkpoint: "+adapter.error)
	var restored := adapter.hydrate(payload)
	expect(restored != null,"Studio checkpoint hydrates")
	if restored != null:
		var expected := hud.model.duplicate(true)
		hud.bind_run(restored)
		expect(hud.model == expected and not hud.is_processing(),"Continue reconstructs the exact graph without re-earning or replay animation")
		var snapshot := Replay.digest(restored)
		run.complete_productive_action()
		await settle()
		expect(hud.model == expected and Replay.digest(restored) == snapshot,"Rebinding disconnects the old run")
	hud.bind_run(fixture_run())
	expect(not hud.visible and hud.model.is_empty(),"A new Studio clears all previous sales")
	hud.queue_free()
	await settle()
	check_prior_world()
	var output := OS.get_environment("PN_CARD_FRAME_OUTPUT")
	if not output.is_empty(): FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations},"\t"))
	print("SALES_REVENUE_HUD checks=%d failures=%d" % [checks,failures])
	quit(0 if failures == 0 else 1)

func settle() -> void:
	await process_frame
	await process_frame

func fixture_run() -> RunState:
	var run := RunState.new()
	run.initialize_cash_cents(0)
	expect(run.create_studio_with_traits("Market HUD",&"action",[]),"Named Studio fixture created")
	# Explicit test funding avoids distress limiting a long passive display study.
	expect(run.add_cash_cents(10000000),"Fixture funding uses normal finance API")
	expect(run.finalize_starter_selection(),"Fixture starter selection completes")
	return run

func release_fixture(run: RunState,title: String,extra: float = 0.0) -> ProjectState:
	var project := PrimitivePredevelopment.prepare_project(title,&"action",&"fantasy",run)
	project.add_core_scores_and_scope({0:12+int(extra),1:12,2:12,3:12},30)
	project.initialize_snapshots(&"fast_follower",&"stable_market")
	project.finalize_design_bugs(false,0,[&"text"],[])
	project.finalize_alpha(0,[],[])
	project.finalize_beta()
	project.commit_review_result(PrimitiveReviewCalculator.calculate(project,50))
	project.commit_awareness_result(PrimitiveAwarenessCalculator.calculate(project,run))
	var snapshots := PrimitiveSnapshotDatabase.new()
	snapshots.load_ledgers()
	project.commit_launch_market_context_result(PrimitiveLaunchMarketContextCalculator.calculate(project,snapshots))
	project.commit_units_sold_result(PrimitiveUnitsSoldCalculator.calculate(project))
	project.commit_month_one_sales_revenue_result(PrimitiveMonthOneSalesRevenueCalculator.calculate(project))
	expect(run.register_release(project),"Constructed release boundary registers "+title)
	return project

func check_model(run: RunState,hud: SalesRevenueHUD) -> void:
	var rows := {}
	var earned := 0
	var paid := 0
	for id in run.get_released_game_ids():
		var report := run.get_released_game_monthly_report(id)
		expect(not report.is_empty(),"Independent per-title replay is valid")
		if report.is_empty(): continue
		earned += int(report.net_cents)
		paid += int(report.settled_cents)
		for month: Dictionary in report.rows:
			for slice: Dictionary in month.slices:
				var calendar_month := (int(slice.run_cycle)-1) / 2 + 1
				rows[calendar_month] = int(rows.get(calendar_month,0)) + int(slice.net_cents)
	expect(hud.model.total_cents == earned and hud.model.settled_cents == paid and hud.model.unpaid_cents == earned-paid,"Aggregate graph matches exact per-title earnings and settlement")
	for row: Dictionary in hud.model.rows:
		expect(row.cents == rows.get(row.month,0),"Calendar bar reconciles to actual earned slices")
	observations.append(hud.model.duplicate(true))

func check_prior_world() -> void:
	var path := OS.get_environment("PN_SALES_HUD_PRIOR_WORLD")
	if path.is_empty(): return
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var adapter := StudioCheckpoint.new()
	var codec := preload("res://scripts/market/rival_world_checkpoint.gd").new()
	var world: RivalWorld = codec.restore(data.world,data.player,adapter.hydrate(data.player),root.get_node("CardDatabase").get_development_catalog())
	expect(world != null,"Pre-HUD rival/Founder checkpoint restores: "+codec.error)
	if world == null: return
	var actual: Dictionary = codec.capture(world)
	var expected: Dictionary = data.world.duplicate(true)
	expected.source_identity = actual.source_identity
	expect(adapter.capture(world.player) == data.player and actual == expected,"Prior checkpoint fields unchanged except source marker")
	expected.source_identity = "unknown-sales-hud-source"
	expect(codec.restore(expected,data.player,adapter.hydrate(data.player),root.get_node("CardDatabase").get_development_catalog()) == null,"Unknown source still rejects")
