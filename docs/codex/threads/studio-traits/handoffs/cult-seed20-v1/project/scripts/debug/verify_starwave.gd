extends "res://scripts/debug/verify_publisher_trial_promotion.gd"

## Constructed scoring/unlock fixtures; the separate Starwave native route is
## the evidence of an earned gameplay foundation.
func starwave_fixture() -> RunState:
	var run := RunState.new()
	run.initialize_cash(0)
	expect(run.create_studio_with_traits("Starwave fixture",&"action",[]),"Create fixture")
	run.finalize_starter_selection()
	expect(run.register_release(finished(run,"First",25)),"First qualifying fixture")
	expect(not run.get_unlocked_publisher_ids().has(PublisherCatalog.STARWAVE),"One release cannot unlock Starwave")
	var cards := passes()
	var iron := run.accept_primitive_contract()
	for i in range(2):
		var plan := iron.plan_hand(cards)
		expect(commit_native_hand(run,iron,cards,plan.remainder_cents),"Ironclad stays two hands")
	finish_contract(run,PublisherCatalog.CROWN_QUILL)
	expect(run.register_release(finished(run,"Second",25)),"Second qualifying fixture")
	expect(not run.get_unlocked_publisher_ids().has(PublisherCatalog.STARWAVE),"Two releases and two completions cannot unlock Starwave")
	finish_contract(run,PublisherCatalog.NEON_CIRCUIT)
	expect(run.get_completed_contract_count()==3 and run.get_unlocked_publisher_ids().has(PublisherCatalog.STARWAVE),"Third distinct completion unlocks Starwave")
	return run

func passes() -> Array[CardData]:
	var result: Array[CardData] = []
	for id in ContractState.PASS_IDS: result.append(root.get_node("CardDatabase").get_card(id))
	return result

func snapshot(run: RunState, state: ContractState = null) -> Array:
	return [run.get_cash_cents(),run.get_completed_run_cycles(),run.get_available_redraws(),run.get_studio_finance_snapshot(),run.get_fanbase_snapshot(),run.random_streams.snapshot(),run._publisher_offers.duplicate(true),state._scope if state else 0,state._successful_hands if state else 0,state._exhausted_feature_ids.duplicate(true) if state else {}]

func _run() -> void:
	for value in [[0,0,0],[14,0,112000],[14,14,224000],[999,999,224000]]:
		var result := PublisherTrialTerms.completion(PublisherTrialTerms.STARWAVE,value[0],{0:value[1],1:value[1],2:value[1],3:value[1]})
		expect(result.payout_cents==value[2] and result.promotion==0 and result.denominator==112,"Exact approved capped payout %s"%str(value))
	expect(PublisherTrialTerms.completion(PublisherTrialTerms.STARWAVE,-1,{0:0,1:0,2:0,3:0}).is_empty(),"Malformed score rejects")
	var zero := ContractState.new([],PublisherTrialTerms.STARWAVE,&"zero_fixture")
	zero.freeze_trial(-1)
	zero.commit_upfront()
	var zero_cards := passes()
	for i in range(zero_cards.size()):
		var original:CardData=zero_cards[i]
		var card:=CardData.new()
		card.id=original.id
		card.primary_stat=original.primary_stat
		card.card_type=&"pass"
		card.renewable=true
		zero_cards[i]=card
	for i in range(3): expect(zero.commit_hand(zero_cards,0),"Zero-score hand commits")
	expect(zero.is_completed() and zero.is_payout_committed() and zero.get_result().get_payout_cents()==0,"Zero-score completion has a paid identity")
	var zero_run:=starwave_fixture()
	var zero_offer:=zero_run.accept_publisher_contract(offer_for(zero_run,PublisherCatalog.STARWAVE))
	var zero_bank:=zero_run.get_pending_promotion_awards()
	for i in range(3):expect(commit_native_hand(zero_run,zero_offer,zero_cards,0),"Constructed zero-payout RunState hand commits")
	expect(zero_run.get_completed_contract_count()==4 and zero_run.get_pending_promotion_awards()==zero_bank and not zero_run._promotion_awards.has(zero_offer.get_offer_id()),"Zero receipt counts once without an award")
	var zero_actions:=0
	for action:Dictionary in zero_run._studio_finance.actions:
		if action.source_id==zero_offer.get_offer_id():
			zero_actions+=1
			expect(action.kind==&"contract_hand" and action.direct_delta==0,"Zero payout has only productive hand journal entries")
	expect(zero_actions==3,"Zero payout journals exactly three hands")
	roundtrip(zero_run,"Zero-payout completed identity")
	for size in [Vector2i(1152,648),Vector2i(1280,720)]:
		root.size=size
		var run:=starwave_fixture()
		var adapter:=StudioCheckpoint.new()
		var pending:=adapter.capture(run)
		expect(not pending.is_empty(),"Pending Starwave checkpoint validates: "+adapter.error)
		var banked:=run.get_pending_promotion_awards()
		var quote:=offer_for(run,PublisherCatalog.STARWAVE)
		var before:=snapshot(run)
		run._refresh_publisher_unlocks()
		expect(before==snapshot(run),"Repeated unlock and browsing do not mutate")
		var stale:=quote.duplicate(true)
		stale.terms.required_hands=2
		expect(run.accept_publisher_contract(stale)==null and before==snapshot(run),"Changed hand-count quote rejects atomically")
		var state:=run.accept_publisher_contract(quote)
		expect(state!=null and state.get_required_hands()==3 and state._trial_terms==PublisherTrialTerms.terms(PublisherTrialTerms.STARWAVE),"Accepted three-hand terms freeze")
		expect(run.get_cash_cents()==before[0] and run.get_completed_run_cycles()==before[1] and run.get_studio_finance_snapshot()==before[3],"Zero advance creates no cash action or cycle")
		expect(run.accept_publisher_contract(quote)==null and run.get_pending_contract_choices().is_empty(),"Duplicate or second active offer rejects")
		var phase:ContractPhase=load("res://scenes/phases/contract_phase.tscn").instantiate()
		var setup_before:=snapshot(run,state)
		expect(not phase.setup(state,run,[NAN,0.0,0.0,0.0,0.0,0.0,0.0],[]) and setup_before==snapshot(run,state),"Malformed initial deal rejects before setup or RNG mutation")
		expect(phase.setup(state,run),"Native phase setup")
		root.add_child(phase)
		await process_frame
		setup_before=snapshot(run,state)
		expect(phase._build_candidate_pool({},[0.0,0.0,NAN,0.0,0.0,0.0,0.0],[]).is_empty() and setup_before==snapshot(run,state),"Failed partial initial deal restores entire RNG stream")
		var distribution:Dictionary[ProjectState.CoreScore,int]={0:40,1:20,2:20,3:20}
		expect(phase.commit_priority_distribution(distribution),"Priority change commits one separate productive action")
		var views:=phase._candidate_row.get_children()
		(views[0] as CardView).input_button.pressed.emit()
		var rng_before:=run.random_streams.snapshot()
		var redraws_before:=run.get_available_redraws()
		expect(not phase.redraw_selected_cards([NAN],[]) and rng_before==run.random_streams.snapshot() and redraws_before==run.get_available_redraws(),"Malformed redraw preserves RNG and budget")
		(views[0] as CardView).input_button.pressed.emit()
		var exhausted:Dictionary={}
		for hand in range(3):
			var drawn:=phase.get_candidate_cards()
			expect(drawn.size()==7,"Seven candidates before hand %d"%(hand+1))
			var retained:=drawn.slice(4)
			views=phase._candidate_row.get_children()
			for i in range(4):
				expect(drawn[i].renewable or not exhausted.has(drawn[i].id),"Finite Feature not reused")
				if not drawn[i].renewable: exhausted[drawn[i].id]=true
				(views[i] as CardView).input_button.pressed.emit()
			var cash_cycle:=run.get_completed_run_cycles()
			var actions_before:int=run._studio_finance.actions.size()
			expect(phase._play_selected_hand(),"Native Starwave hand %d"%(hand+1))
			expect(run.get_completed_run_cycles()==cash_cycle+1,"Exactly one cycle per successful hand")
			var action:Dictionary=run._studio_finance.actions[actions_before]
			expect(action.source_id==state.get_offer_id() and action.direct_delta==(state.get_result().get_payout_cents() if hand==2 else 0),"Only final hand earns exact receipt")
			expect(run.get_pending_promotion_awards()==banked and not run._promotion_awards.has(state.get_offer_id()),"Existing Promotion preserved without Starwave entry")
			if hand<2:
				expect(phase.get_candidate_cards().slice(0,3)==retained,"Three unselected cards retained")
				expect(adapter.capture(run).is_empty(),"Unfinished Contract cannot checkpoint")
			expect(phase._status_label.text.contains("/ 3") and phase._status_label.text.contains("No Promotion"),"Phase exposes count and cash-only terms")
		expect(run.get_completed_contract_count()==4 and state.is_completed(),"Three-hand completion counts once")
		before=snapshot(run,state)
		expect(not phase._play_selected_hand() and before==snapshot(run,state),"Duplicate completion is inert")
		expect(phase._completion_stats.text.contains("No Promotion"),"Result copy states no award")
		var restored:=roundtrip(run,"Completed Starwave with priority action")
		expect(restored!=null and restored.get_completed_contract_count()==4 and restored.get_pending_promotion_awards()==banked,"Restore preserves completion and earlier Promotion")
		var payload:=adapter.capture(run)
		var broken:=payload.duplicate(true)
		for pair in broken.run.publisher_offers:
			if pair.value.publisher_id=="starwave": pair.value.state.hands="2"
		expect(adapter.hydrate(broken)==null,"Forged two-hand Starwave save rejects")
		for field in ["scope","cash_cents","advance_cents","promotion","denominator","required_hands"]:
			broken=payload.duplicate(true)
			for pair in broken.run.publisher_offers:
				if pair.value.publisher_id=="starwave":pair.value.state.trial_terms[field]=str(int(pair.value.state.trial_terms[field])+1)
			expect(adapter.hydrate(broken)==null,"Changed frozen Starwave term rejects: "+field)
		broken=payload.duplicate(true)
		for pair in broken.run.publisher_offers:
			if pair.value.publisher_id=="starwave":pair.value.state.offer_id="forged_identity"
		expect(adapter.hydrate(broken)==null,"Changed immutable offer identity rejects")
		broken=payload.duplicate(true)
		for pair in broken.run.publisher_offers:
			if pair.value.publisher_id=="starwave":pair.value.state.result.remainder=str(int(pair.value.state.result.remainder)+1)
		expect(adapter.hydrate(broken)==null,"Changed exact completion receipt rejects")
		expect(adapter.capture(run)==payload,"Invalid payloads cannot mutate original checkpoint or live state")
		var next:=finished(run,"After Starwave",0)
		expect(run.register_release(next) and run.get_pending_promotion()==0,"Next launch consumes earlier awards once")
		roundtrip(run,"Starwave after promoted launch")
		phase.queue_free()
		await process_frame
	print("Starwave verification: %d failures"%failures)
	quit(0 if failures==0 else 1)
