extends "res://scripts/debug/verify_starwave.gd"

func poor(run:RunState,title:String)->ProjectState:
	var p:=PrimitivePredevelopment.prepare_project(title,&"action",&"fantasy",run)
	p.add_core_scores_and_scope({0:0,1:0,2:0,3:0},30)
	p.add_marketing_output(25)
	p.initialize_snapshots(&"fast_follower",&"stable_market")
	p.finalize_design_bugs(false,0,[&"text"],[]);p.finalize_alpha(0,[],[]);p.finalize_beta()
	p.commit_review_result(PrimitiveReviewCalculator.calculate(p,50))
	p.commit_awareness_result(PrimitiveAwarenessCalculator.calculate(p,run))
	var snapshots:=PrimitiveSnapshotDatabase.new();snapshots.load_ledgers()
	p.commit_launch_market_context_result(PrimitiveLaunchMarketContextCalculator.calculate(p,snapshots))
	p.commit_units_sold_result(PrimitiveUnitsSoldCalculator.calculate(p))
	p.commit_month_one_sales_revenue_result(PrimitiveMonthOneSalesRevenueCalculator.calculate(p))
	return p

func _run()->void:
	var cards:=passes()
	for prior_hands in [0,1,2]:
		var run:=RunState.new();run.initialize_cash(0)
		run.create_studio_with_traits("Starwave adverse liquidity fixture",&"action",[])
		run.register_release(poor(run,"First"))
		var iron:=run.accept_primitive_contract()
		for i in range(2):
			var plan:=iron.plan_hand(cards);expect(commit_native_hand(run,iron,cards,plan.remainder_cents),"Ironclad prerequisite")
		finish_contract(run,PublisherCatalog.NEON_CIRCUIT)
		run.register_release(poor(run,"Second"))
		var side:=run.accept_sidestreet_offer(run.get_next_sidestreet_offer().offer_id)
		for i in range(2):
			var plan:=side.plan_hand(cards);expect(commit_native_hand(run,side,cards,plan.remainder_cents),"SideStreet prerequisite")
		var state:=run.accept_publisher_contract(offer_for(run,PublisherCatalog.STARWAVE))
		expect(state!=null,"Constructed no-sales route earns Starwave eligibility")
		if state==null:quit(1);return
		expect(run.spend_cash_cents(run.get_cash_cents()),"Explicit fixture expense drains cash")
		for i in range(prior_hands):expect(commit_native_hand(run,state,cards,0),"Unpaid early hand before existing debt")
		while run.get_completed_run_cycles()<8:expect(run.complete_productive_action(),"Align fixture to original month-end rent")
		expect(StudioFinanceLedger.get_unpaid(run._studio_finance)==50000,"Original rent due remains exact")
		var before:=snapshot(run,state)
		var plan:=state.plan_hand(cards)
		if prior_hands<2:
			expect(plan.remainder_cents==0 and not commit_native_hand(run,state,cards,0),"Hand one or two cannot borrow a future completion receipt")
			expect(before==snapshot(run,state),"Blocked hand preserves cash/ledger/RNG/identity/progress/Fans")
		else:
			expect(plan.remainder_cents>=50000 and commit_native_hand(run,state,cards,plan.remainder_cents),"Actual hand-three cash recovers original overdue rent")
			expect(StudioFinanceLedger.get_unpaid(run._studio_finance)==0 and state.is_completed(),"Atomic hand-three receipt pays arrears once")
	print("Starwave adverse liquidity: %d failures"%failures)
	quit(0 if failures==0 else 1)
