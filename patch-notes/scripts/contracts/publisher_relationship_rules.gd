## Approved SideStreet trial: trusted producers from code-owned source results.
extends RefCounted
const KIND := &"sidestreet_brief_completion_v1"

static func facts(run: Variant, id: StringName) -> Dictionary:
	var briefs: Dictionary = run.get("sidestreet_briefs",{}) if run is Dictionary else run._sidestreet_briefs
	if not briefs.has(id): return {}
	var offer: Dictionary = briefs[id]
	if offer.state == null: return {}
	var c: Dictionary = {}
	if run is Dictionary:
		c = offer.state
	else:
		var state: ContractState = offer.state
		if not state.is_completed(): return {}
		var result := state.get_result()
		var cores := {}
		for i in range(4): cores[i] = state.get_core_score_half_units(i)
		c = {"contract_id":state.get_contract_id(),"offer_id":state.get_offer_id(),"source_release_id":state.get_source_release_id(),"hands":state.get_successful_hand_count(),"upfront":state.is_upfront_committed(),"paid":state.is_payout_committed(),"scope":state.get_scope(),"cores":cores,"challenge_terms":state.get_challenge_terms(),"challenge_redraws":state.get_challenge_redraws(),"result":{"numerator":result.get_completion_numerator(),"denominator":64,"payout":result.get_payout_cents(),"promotion":result.get_promotion(),"challenge_grade_bp":result.get_challenge_grade_bp()}}
	var owner: StringName = run.bank_run_id if run is Dictionary else run._bank_run_id
	var releases: Dictionary = run.released_games if run is Dictionary else run._released_games
	var finance: Dictionary = run.studio_finance if run is Dictionary else run._studio_finance
	var cycle: int = run.completed_run_cycles if run is Dictionary else run._completed_run_cycles
	var searched:=preload("res://scripts/contracts/contract_search.gd").source(run,id,&"brief")
	if searched.is_empty():
		if id != StringName("%s:sidestreet-brief:%s" % [owner,offer.source_release_id]) or not releases.has(offer.source_release_id): return {}
	elif not offer.source_release_id.is_empty():return {}
	if c.contract_id != ContractDefinitions.SIDESTREET_BRIEF or c.offer_id != id or c.source_release_id != offer.source_release_id or c.hands != 2 or not c.upfront or not c.paid: return {}
	if c.challenge_terms != ContractChallenges.terms_for_contract(ContractDefinitions.SIDESTREET_BRIEF): return {}
	var calculated := ContractDefinitions.evaluate(ContractDefinitions.SIDESTREET_BRIEF,c.scope,c.cores,-1,0)
	var reward := ContractChallenges.reward(c.challenge_terms,c.scope,c.cores,c.challenge_redraws)
	if calculated.is_empty() or reward.is_empty(): return {}
	if c.result.numerator != calculated.numerator or c.result.denominator != 64 or c.result.payout != 0 or c.result.promotion != 0 or c.result.challenge_grade_bp != reward.grade_bp: return {}
	var hands := 0
	var completed_cycle := 0
	for action: Dictionary in finance.actions:
		if action.source_id != id: continue
		if action.productive and action.kind == &"contract_hand":
			if action.direct_delta != 0: return {}
			hands += 1
			completed_cycle = action.cycle
	if hands != 2 or completed_cycle > cycle or completed_cycle <= 0: return {}
	var grade: int = mini(10000 * int(calculated.numerator) / 64,int(reward.grade_bp))
	return {"cycle":completed_cycle,"award":1000 * grade / 10000}

static func request_for(run: Variant,id: StringName) -> Dictionary:
	var found := facts(run,id)
	if found.is_empty(): return {}
	return {"event_id":StringName(str(id)+":reputation"),"source_id":id,"publisher_id":&"sidestreet","kind":KIND,"cycle":found.cycle}

static func resolve(run: Variant,request: Dictionary) -> Dictionary:
	if request.get("kind") == preload("res://scripts/contracts/publisher_support.gd").KIND: return preload("res://scripts/contracts/publisher_support.gd").resolve(run,request)
	if request.get("kind") == preload("res://scripts/contracts/publisher_commission_trial.gd").KIND: return preload("res://scripts/contracts/publisher_commission_trial.gd").resolve(run,request)
	if request.size() != 5 or request.get("publisher_id") != &"sidestreet" or request.get("kind") != KIND or not request.get("source_id") is StringName: return {}
	var expected := request_for(run,request.source_id)
	if expected.is_empty() or expected != request: return {}
	return {"reputation_bp":int(facts(run,request.source_id).award),"investment_bp":0}
