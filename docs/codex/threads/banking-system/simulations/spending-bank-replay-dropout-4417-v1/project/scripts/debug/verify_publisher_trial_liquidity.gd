extends "res://scripts/debug/verify_publisher_trial_offers.gd"

func poor_release_run() -> RunState:
	var run := RunState.new()
	run.initialize_cash(0)
	run.create_studio_with_traits("Liquidity boundary fixture",&"action",[])
	var p := PrimitivePredevelopment.prepare_project("High Awareness, no production",&"action",&"fantasy",run)
	p.add_core_scores_and_scope({0:1,1:1,2:1,3:1},1)
	p.add_marketing_output(25)
	p.initialize_snapshots(&"fast_follower",&"stable_market")
	p.finalize_design_bugs(false,0,[&"text"],[])
	p.finalize_alpha(0,[],[])
	p.finalize_beta()
	p.commit_review_result(PrimitiveReviewCalculator.calculate(p,50))
	p.commit_awareness_result(PrimitiveAwarenessCalculator.calculate(p,run))
	var snapshots := PrimitiveSnapshotDatabase.new()
	snapshots.load_ledgers()
	p.commit_launch_market_context_result(PrimitiveLaunchMarketContextCalculator.calculate(p,snapshots))
	p.commit_units_sold_result(PrimitiveUnitsSoldCalculator.calculate(p))
	p.commit_month_one_sales_revenue_result(PrimitiveMonthOneSalesRevenueCalculator.calculate(p))
	expect(run.register_release(p),"Frozen zero-production, qualifying-Awareness fixture")
	return run

func _run() -> void:
	var cards: Array[CardData] = []
	for id in ContractState.PASS_IDS: cards.append(root.get_node("CardDatabase").get_card(id))
	for second in [false,true]:
		var run := poor_release_run()
		expect(run.complete_productive_action(),"Align fixture to first month end")
		var state := run.accept_publisher_contract(offer_for(run,PublisherCatalog.NEON_CIRCUIT))
		expect(state!=null,"Zero-advance offer accepts")
		if state==null: quit(1); return
		expect(run.spend_cash_cents(run.get_cash_cents()),"Explicit expense drains fixture liquidity")
		if second:
			var first := state.plan_hand(cards)
			expect(commit_native_hand(run,state,cards,first.remainder_cents),"First hand records original unpaid month-end rent")
		else:
			expect(run.complete_productive_action(),"Fixture records unpaid month-end rent before first hand")
		expect(StudioFinanceLedger.get_unpaid(run._studio_finance)==50000,"Original rent debt is exact")
		var before := [run._studio_finance.duplicate(true),run.random_streams.snapshot(),state.get_successful_hand_count(),state.get_exhausted_feature_ids(),run.get_pending_promotion_awards()]
		if second:
			var plan := state.plan_hand(cards)
			expect(plan.remainder_cents>=50000 and commit_native_hand(run,state,cards,plan.remainder_cents),"Real completion income clears original rent and commits hand two")
			expect(StudioFinanceLedger.get_unpaid(run._studio_finance)==0 and state.is_payout_committed(),"Income recovery pays once")
		else:
			expect(not commit_native_hand(run,state,cards,0),"Zero-income first hand blocks on existing arrears")
			expect(before==[run._studio_finance,run.random_streams.snapshot(),state.get_successful_hand_count(),state.get_exhausted_feature_ids(),run.get_pending_promotion_awards()],"Blocked hand preserves ledger, RNG, cards, progress and reward")
	print("Publisher liquidity: %d failures" % failures)
	quit(0 if failures==0 else 1)
