extends "res://scripts/debug/verify_publisher_trial_offers.gd"

func _run() -> void:
	var zero := {0:0,1:0,2:0,3:0}
	var crown := PublisherTrialTerms.completion(PublisherTrialTerms.CROWN,0,zero)
	var neon := PublisherTrialTerms.completion(PublisherTrialTerms.NEON,0,zero,0)
	expect(crown.payout_cents==15000 and crown.remainder_cents==0 and crown.promotion==0,"Crown zero completion retains only its advance")
	expect(neon.payout_cents==0 and neon.promotion==0,"Neon zero completion pays zero")
	crown = PublisherTrialTerms.completion(PublisherTrialTerms.CROWN,9,{0:8,1:8,2:8,3:8})
	neon = PublisherTrialTerms.completion(PublisherTrialTerms.NEON,10,{0:18,1:4,2:4,3:4},0)
	expect(crown.payout_cents==192000 and crown.remainder_cents==177000 and crown.promotion==12,"Crown exact full-completion cash and Promotion")
	expect(neon.payout_cents==156000 and neon.promotion==20,"Neon exact full-completion cash and Promotion")
	crown = PublisherTrialTerms.completion(PublisherTrialTerms.CROWN,4,{0:1,1:2,2:3,3:4})
	neon = PublisherTrialTerms.completion(PublisherTrialTerms.NEON,5,{0:9,1:2,2:6,3:1},0)
	expect(crown.numerator==20 and crown.remainder_cents==53636 and crown.promotion==3,"Crown fractional cents and points floor independently")
	expect(neon.numerator==44 and neon.payout_cents==79813 and neon.promotion==10,"Neon exact focused partial calculation")
	for publisher in [PublisherCatalog.CROWN_QUILL,PublisherCatalog.NEON_CIRCUIT]:
		var run := trial_run()
		var quote := offer_for(run,publisher)
		var state := run.accept_publisher_contract(quote)
		var cards: Array[CardData] = []
		for id in ContractState.PASS_IDS: cards.append(root.get_node("CardDatabase").get_card(id))
		var before_cycle := run.get_completed_run_cycles()
		for i in range(2):
			var plan := state.plan_hand(cards)
			expect(commit_native_hand(run,state,cards,plan.remainder_cents),"Native four-card trial hand commits")
			expect(run.get_completed_run_cycles()==before_cycle+i+1,"One productive cycle per Contract hand")
			expect(StudioFinanceLedger._is_valid(run.get_studio_finance_snapshot()),"Native finance journal reconciles")
		var result := state.get_result()
		expect(result!=null and state.is_payout_committed() and state.get_successful_hand_count()==2,"One immutable completed result")
		var receipt := 0
		for action: Dictionary in run.get_studio_finance_snapshot().actions:
			if action.source_id==state.get_offer_id() and action.kind==&"publisher_receipt": receipt += int(action.direct_delta)
		expect(receipt==result.get_payout_cents(),"Recorded acceptance plus completion receipts equal exact total")
		expect(run.get_completed_contract_count()==1 and not run.is_sidestreet_offer_available(),"Crown/Neon completion does not unlock SideStreet")
		var before := [run.get_cash_cents(),run.get_completed_run_cycles(),run.get_studio_finance_snapshot(),run.random_streams.snapshot()]
		expect(not commit_native_hand(run,state,cards,0) and run.accept_publisher_contract(quote)==null,"Completed hand and acceptance replay reject")
		expect(before==[run.get_cash_cents(),run.get_completed_run_cycles(),run.get_studio_finance_snapshot(),run.random_streams.snapshot()],"Rejected replay preserves cash, calendar, journal and RNG")
	print("Publisher trial cash: %d failures" % failures)
	quit(0 if failures==0 else 1)
