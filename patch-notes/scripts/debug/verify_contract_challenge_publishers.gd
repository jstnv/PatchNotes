extends "res://scripts/debug/verify_starwave.gd"

func _run() -> void:
	for publisher in [PublisherCatalog.CROWN_QUILL,PublisherCatalog.NEON_CIRCUIT]:
		var run := trial_run()
		var quote := offer_for(run,publisher)
		var state := run.accept_publisher_contract(quote)
		expect(state!=null,"Publisher accepts with frozen challenge")
		if state==null: continue
		expect(state.get_challenge_terms()==ContractChallenges.terms_for_contract(state.get_contract_id()),"Publisher terms freeze at acceptance")
		var cards := passes()
		for i in range(2):
			var plan := state.plan_hand(cards)
			expect(commit_native_hand(run,state,cards,plan.remainder_cents),"Publisher hand commits with bonus-aware finance")
		var result := state.get_result()
		var base := PublisherTrialTerms.completion(state.get_contract_id(),state.get_scope(),result._core_half_units,state._neon_focus)
		var bonus := ContractChallenges.reward(state.get_challenge_terms(),state.get_scope(),result._core_half_units,0)
		expect(result.get_bonus_cash_cents()==bonus.cash_cents and result.get_bonus_promotion()==bonus.promotion,"Publisher bonus matches final grade")
		expect(result.get_payout_cents()==int(base.payout_cents)+int(bonus.cash_cents) and result.get_promotion()==int(base.promotion)+int(bonus.promotion),"Publisher base and bonus add exactly")
		expect(run.get_pending_promotion_awards().get(state.get_offer_id(),-1)==result.get_promotion(),"Publisher Promotion banks once")
		roundtrip(run,"Challenged "+String(publisher))
		var adapter := StudioCheckpoint.new()
		var saved := adapter.capture(run)
		if not saved.is_empty():
			var forged := saved.duplicate(true)
			for pair: Dictionary in forged.run.publisher_offers:
				if pair.key==String(state.get_offer_id()): pair.value.state.result.bonus_cash_cents = str(result.get_bonus_cash_cents()+1)
			expect(adapter.hydrate(forged)==null,"Forged challenge cash rejects on restore")
			forged = saved.duplicate(true)
			for pair: Dictionary in forged.run.publisher_offers:
				if pair.key==String(state.get_offer_id()): pair.value.state.challenge_redraws = "1"
			expect(adapter.hydrate(forged)==null,"Forged redraw history rejects on restore")
	var wave_run := starwave_fixture()
	var wave := wave_run.accept_publisher_contract(offer_for(wave_run,PublisherCatalog.STARWAVE))
	expect(wave!=null and wave.get_challenge_terms()==ContractChallenges.terms_for_contract(PublisherTrialTerms.STARWAVE),"Starwave challenge freezes on acceptance")
	if wave!=null:
		var wave_cards := passes()
		for i in range(3):
			var plan := wave.plan_hand(wave_cards)
			expect(commit_native_hand(wave_run,wave,wave_cards,plan.remainder_cents),"Starwave productive hand commits")
		var wave_result := wave.get_result()
		var wave_base := PublisherTrialTerms.completion(PublisherTrialTerms.STARWAVE,wave.get_scope(),wave_result._core_half_units)
		var wave_bonus := ContractChallenges.reward(wave.get_challenge_terms(),wave.get_scope(),wave_result._core_half_units,0)
		expect(wave_result.get_payout_cents()==int(wave_base.payout_cents)+int(wave_bonus.cash_cents),"Starwave cash includes separate challenge bonus")
		expect(wave_result.get_promotion()==wave_bonus.promotion and wave_run.get_pending_promotion_awards().get(wave.get_offer_id(),-1)==wave_bonus.promotion,"Starwave challenge Promotion banks without base Promotion")
		roundtrip(wave_run,"Challenged Starwave")
	var legacy_run := trial_run()
	var legacy := legacy_run.accept_publisher_contract(offer_for(legacy_run,PublisherCatalog.CROWN_QUILL))
	if legacy!=null:
		legacy._challenge_terms.clear() # Model a completed pre-challenge Contract.
		for i in range(2):
			var legacy_plan := legacy.plan_hand(passes())
			expect(commit_native_hand(legacy_run,legacy,passes(),legacy_plan.remainder_cents),"Historical base hand commits")
		var old_adapter := StudioCheckpoint.new()
		var old_record := old_adapter.capture(legacy_run)
		expect(not old_record.is_empty(),"Historical-shaped completed Contract captures")
		if not old_record.is_empty():
			old_record.content_revision = old_adapter._rules_revision(StudioCheckpoint.PRE_CHALLENGE_RULES)
			old_record.run.erase("store_era_receipts") # Not present in this named predecessor.
			old_record.run.erase("contract_search") # Actual historical schema predates Search.
			old_record.run.erase("publisher_relationships") # Constructed old shape predates P1.
			old_record.run.erase("sidestreet_briefs") # Also predates the bounded pilot.
			old_record.run.erase("commission_deals")
			for field: String in ["support_deals","support_rights","support_assessments"]:
				expect(old_record.run[field] == [],"Historical challenge fixture has no P4 activity: "+field)
				old_record.run.erase(field)
			old_record.run.erase("founding_roster_version") # Constructed historical Action roster predates v2.
			# This constructed legacy fixture predates market ledgers too. Current
			# fields under an old revision must fail the real migration validator.
			for sale: Dictionary in old_record.run.released_games: sale.value.erase("market_factors")
			for fan: Dictionary in old_record.run.fanbase.releases: fan.value.neutral.erase("market_factors")
			for meta: Dictionary in old_record.run.release_metadata: meta.value.review.erase("market")
			var old_restored := old_adapter.hydrate(old_record)
			expect(old_restored!=null and old_restored.get_pending_promotion()==legacy.get_result().get_promotion(),"Historical rule revision restores without retroactive bonus")
	print("Contract challenge publishers: %d failures" % failures)
	quit(0 if failures==0 else 1)
