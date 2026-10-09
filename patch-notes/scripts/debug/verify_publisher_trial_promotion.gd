extends "res://scripts/debug/verify_publisher_trial_offers.gd"

func finished(run: RunState, title: String, marketing: int) -> ProjectState:
	var p := PrimitivePredevelopment.prepare_project(title,&"action",&"fantasy",run)
	p.add_core_scores_and_scope({0:90,1:90,2:90,3:90},30)
	p.add_marketing_output(marketing)
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
	return p

func finish_contract(run: RunState, publisher: StringName) -> ContractState:
	var state := run.accept_publisher_contract(offer_for(run,publisher))
	if state==null: return null
	var cards: Array[CardData] = []
	for id in ContractState.PASS_IDS: cards.append(root.get_node("CardDatabase").get_card(id))
	for i in range(2):
		var plan := state.plan_hand(cards)
		expect(commit_native_hand(run,state,cards,plan.remainder_cents),"Native trial completion hand")
	return state

func _run() -> void:
	var run := RunState.new()
	run.initialize_cash(0)
	run.create_studio_with_traits("Promotion fixture",&"action",[&"studio_buzz",&"unknown_name"])
	var first := finished(run,"First",25)
	expect(first.get_awareness_result().get_total_awareness()==118 and run.register_release(first),"First-launch Buzz and Unknown Name freeze together")
	expect(not run.get_unlocked_publisher_ids().has(PublisherCatalog.NEON_CIRCUIT),"First release below Neon threshold")
	var crown := finish_contract(run,PublisherCatalog.CROWN_QUILL)
	expect(crown!=null and run.get_pending_promotion()==8,"Crown banks separately floored whole points")
	var pending := run.get_pending_promotion_awards()
	expect(not run.register_release(ProjectState.new(30)) and pending==run.get_pending_promotion_awards(),"Failed launch preserves bank")
	expect(run.register_release(first) and pending==run.get_pending_promotion_awards(),"Old release callback cannot consume newly banked Promotion")
	var second := finished(run,"Second",14)
	expect(second.get_awareness_result().get_total_awareness()==125 and run.get_pending_promotion_awards()==pending,"Previewed launch includes Promotion without consuming it")
	expect(run.register_release(second) and run.get_pending_promotion_awards().is_empty(),"Successful launch consumes exactly its award IDs")
	var id := second.get_release_id()
	expect(run.get_release_metadata(id).review.awareness==125 and run.get_released_game_sales(id).launch_awareness==125 and run.get_release_promotion(id)==8,"History, sales and Promotion history share the frozen result")
	expect(run.get_unlocked_publisher_ids().has(PublisherCatalog.NEON_CIRCUIT),"Promotion participates in the frozen Neon threshold")
	var neon := finish_contract(run,PublisherCatalog.NEON_CIRCUIT)
	expect(neon!=null and run.get_pending_promotion()==neon.get_result().get_promotion(),"Later Neon award remains separate")
	var later := run.get_pending_promotion_awards()
	expect(run.register_release(second) and later==run.get_pending_promotion_awards(),"Duplicate second launch cannot consume a later award")
	var third := finished(run,"Third",0)
	expect(run.register_release(third) and run.get_pending_promotion()==0,"Next successful release consumes later award once")
	expect(run.get_release_metadata(first.get_release_id()).review.awareness==118 and run.get_release_metadata(id).review.awareness==125,"Earlier releases remain frozen")
	print("Publisher trial Promotion: %d failures" % failures)
	quit(0 if failures==0 else 1)
