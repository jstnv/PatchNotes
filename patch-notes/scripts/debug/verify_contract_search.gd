extends SceneTree
const Factory=preload("res://scripts/simulation/run_factory.gd")
const Policy=preload("res://scripts/simulation/finite_fixture_policy.gd")
const Replay=preload("res://scripts/simulation/development_replay.gd")
const Session=preload("res://scripts/simulation/campaign_session.gd")
const Begin=preload("res://scripts/simulation/begin_project.gd")
var failures:=0
var checks:=0
var tape: Dictionary
var output: String=OS.get_environment("PN_CARD_FRAME_OUTPUT")
var session: RefCounted
var recipe={"schema_version":1,"studio_id":"contract_search_checks","studio_name":"Search Studio","specialty":"action","traits":[],"seed":"4417"}
func expect(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func act(kind: StringName,payload: Dictionary={},accepted: bool=true) -> Dictionary:
	var before:=Replay.state(session)
	var result:=Replay.record(session,tape,session.command(kind,payload))
	expect(result.ok==accepted,"Expected acceptance: %s %s"%[kind,str(result.get("error",""))])
	if not result.ok:expect(Replay.state(session)==before,"Rejected action preserves state and every RNG")
	return result
func contract(offer: Dictionary) -> bool:
	if not act(&"accept_contract",offer).ok:return false
	if not act(&"contract",{"request":session.contract.command(&"begin")}).ok:return false
	for hand_index in range(session.contract._state.get_required_hands()):
		var state: ContractState=session.contract._state
		var cards: Array=session.contract.cards
		var best: Array[int]=[];var best_value: float=-1e12
		var brief: bool=state.get_contract_id()==ContractDefinitions.SIDESTREET_BRIEF
		var target:=10 if brief else 12
		for a in range(4):
			for b in range(a+1,5):
				for c in range(b+1,6):
					for d in range(c+1,7):
						var plan:=state.plan_hand([cards[a],cards[b],cards[c],cards[d]] as Array[CardData])
						if plan.is_empty():continue
						var scope: int=state.get_scope()+plan.scope_addition
						var value: float=4*mini(scope,target/2 if hand_index==0 else target)
						for category in range(4):value+=mini(state.get_core_score_half_units(category)+int(plan.score_additions[category]),6 if brief else 12)
						if brief and scope>10:value-=1000*(scope-10)
						if value>best_value:best_value=value;best.assign([session.contract.candidate_ids[a],session.contract.candidate_ids[b],session.contract.candidate_ids[c],session.contract.candidate_ids[d]])
		if not act(&"contract",{"request":session.contract.command(&"play",{"candidate_ids":best})}).ok:return false
	return act(&"dismiss_contract").ok
func search(work: StringName) -> bool:
	var quote: Dictionary=session.run.get_contract_search_quote(&"sidestreet",work)
	return act(&"search_contracts",{"quote":quote}).ok
func cash_work() -> bool:
	if not search(&"cash"):return false
	return contract({"kind":&"sidestreet","offer_id":session.run.get_next_sidestreet_offer().offer_id})
func ensure_cash(cents: int) -> bool:
	# Reserve-aware public cash work; no injected funding or relaxed Bank gate.
	for attempt in range(150):
		if attempt%10==0: print("COMMISSION_RESERVE target=",cents," cash=",session.run.get_cash_cents()," attempt=",attempt)
		if session.run.get_cash_cents()>=cents:return true
		if not cash_work():return false
	expect(false,"Declared cash-work reserve bound reached")
	return false
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
	var probe:=RunState.new()
	expect(probe.has_method("get_contract_search_quote"),"Contract Search authority exists")
	if not probe.has_method("get_contract_search_quote"):quit(1);return
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	session=Factory.create_fresh_session(recipe,catalog);tape=Replay.begin(session)
	var choose:=Policy.factory({"genre":"action","theme":"fantasy","name_prefix":"Search Prefix","selection":"features_first","hands":{"design":2,"alpha":2,"beta":2}})
	for n in range(100):
		if session.in_studio and session.run.get_released_game_ids().size()==2:break
		var decision: Dictionary=choose.call(session.observation())
		if not act(decision.type,decision.get("payload",{})).ok:quit(1);return
	expect(session.run.get_contract_search_quote(&"sidestreet",&"cash").is_empty(),"Search locked before SideStreet unlock")
	expect(session.run._sidestreet_entitlements.is_empty(),"New releases do not auto-generate repeatable cash work")
	if not contract({"kind":&"ironclad"}):quit(1);return
	expect(session.run.can_browse_contract_search() and not session.run.get_sidestreet_brief_offer().is_empty(),"Original qualifying one-time unlock Brief is preserved")
	expect(session.run.get_contract_search_quote(&"sidestreet",&"brief").is_empty(),"Pending introductory Brief blocks duplicate discovery")
	expect(session.run.get_contract_search_quote(&"sidestreet",&"commission").is_empty(),"Commission search keeps R20 gate")
	var quote: Dictionary=session.run.get_contract_search_quote(&"sidestreet",&"cash")
	var before: int=session.run.get_completed_run_cycles();var standing: Dictionary=session.run.get_publisher_relationships()
	var request: Dictionary=session.command(&"search_contracts",{"quote":quote})
	var result:=Replay.record(session,tape,request)
	expect(result.ok and session.run.get_completed_run_cycles()==before+1 and session.run.get_publisher_relationships()==standing,"Search advances one cycle and awards no standing")
	var receipt: Dictionary=session.run.get_contract_search_state().receipts[-1]
	var action: Dictionary=session.run._studio_finance.actions[-1]
	expect(action.kind==&"contract_search" and action.direct_delta==0 and action.source_id==receipt.receipt_id,"Search has one typed zero-fee productive receipt")
	var unchanged:=Replay.state(session)
	expect(not session.execute(request).ok and unchanged==Replay.state(session),"Repeated request cannot charge or generate twice")
	act(&"search_contracts",{"quote":quote},false)
	expect(not session.run._released_games.has(receipt.receipt_id) and session.run.get_next_sidestreet_offer().release_id.is_empty(),"Search identity is not a fake released game")
	var saved: Dictionary=session.export_checkpoint()
	expect(not saved.is_empty(),"Found cash offer is a valid durable Studio boundary")
	var restored:=Session.new()
	expect(restored.restore_checkpoint(saved,catalog,session.snapshots) and Replay.state(restored)==Replay.state(session),"Found work restores exactly without regeneration")
	if not contract({"kind":&"sidestreet","offer_id":receipt.offer_id}):quit(1);return
	expect(session.run._sidestreet_results[receipt.offer_id].search_receipt_id==receipt.receipt_id and session.run.get_completed_run_cycles()==before+3,"Searched cash work uses ordinary two extra hand cycles")
	if not cash_work():quit(1);return
	expect(session.run.get_released_game_ids().size()==2,"Repeat cash search needs no intervening release")
	var intro: Dictionary=session.run.get_sidestreet_brief_offer()
	if not contract({"kind":&"sidestreet_brief","offer_id":intro.offer_id}):quit(1);return
	for attempt in range(12):
		if session.run.get_publisher_relationships()[&"sidestreet"].reputation_bp>=2000:break
		if session.run.get_cash_cents()<120000:
			if not cash_work():quit(1);return
		if not search(&"brief"):quit(1);return
		var brief: Dictionary=session.run.get_sidestreet_brief_offer()
		if not contract({"kind":&"sidestreet_brief","offer_id":brief.offer_id}):quit(1);return
	expect(session.run.get_publisher_relationships()[&"sidestreet"].reputation_bp>=2000,"Legal searched Briefs reach R20 within declared twelve-Brief bound")
	if session.run.get_publisher_relationships()[&"sidestreet"].reputation_bp<2000:quit(1);return
	expect(session.run.get_commission_quote("Commission",&"action",&"fantasy").is_empty(),"R20 alone does not bypass paid commission discovery")
	if not search(&"commission"):quit(1);return
	var invitation: Dictionary=session.run.ContractSearch.invitation(session.run)
	var quote_a: Dictionary=session.run.get_commission_quote("Commission",&"action",&"fantasy")
	unchanged=Replay.state(session)
	var quote_b: Dictionary=session.run.get_commission_quote("Changed name",&"puzzle",&"fantasy")
	expect(not quote_a.is_empty() and not quote_b.is_empty() and quote_a.search_offer_id==invitation.offer_id and Replay.state(session)==unchanged,"Free cancel/reprepare retains the same unconsumed invitation")
	var failed: Dictionary=Begin.execute(session.run,session.snapshots,"Commission",&"action",&"fantasy",func(_project):return false,[],quote_a)
	expect(not failed.ok and Replay.state(session)==unchanged,"Rejected scene readiness preserves invitation, cash, serial and RNG")
	# Supply/finance changed with v4 starts. Acquire legal printed Scope before
	# this full-delivery commission fixture and reserve its normal production bill.
	for id: StringName in [&"lives_system",&"enemies",&"general_combat",&"scrolling",&"menu_system",&"split_screen",&"power_ups",&"maps",&"dialogue",&"character_backstories",&"secrets",&"music",&"8_bit_sound",&"8_bit_music",&"colored_text",&"save_files",&"animated_sprites"]:
		var total_scope:=0
		for owned: StringName in session.run.get_owned_feature_ids():total_scope+=int(session.run._feature_definitions[owned].scope)
		if total_scope>=30:break
		if session.run.owns_feature(id):continue
		if not ensure_cash(400000):quit(1);return
		var research:Dictionary=session.run.get_feature_research_quote(id)
		if not research.can_admit:continue
		if not act(&"admit_research",{"quote":research}).ok:quit(1);return
		if not act(&"research",{"quote":session.run.get_feature_research_quote(id)}).ok:quit(1);return
	if not ensure_cash(1000000):quit(1);return
	# Research/cash work invalidates the earlier preview: refresh exact quote.
	quote_a=session.run.get_commission_quote("Commission",&"action",&"fantasy")
	var era_before:Dictionary=session.run._store_era_receipts.duplicate(true)
	var commission_policy:=Policy.factory({"genre":"action","theme":"fantasy","name_prefix":"Commission","selection":"features_first","hands":{"design":12,"alpha":12,"beta":2}})
	act(&"quote_commission",{"name":"Commission","genre":&"action","theme":&"fantasy"})
	if not act(&"begin_development",{"name":"Commission","genre":&"action","theme":&"fantasy","commission_quote":quote_a}).ok:quit(1);return
	expect(session.run.ContractSearch.invitation(session.run).is_empty() and session.run._contract_search.offers[invitation.offer_id].project_id==session.development.project.get_release_id(),"Successful Begin binds the paid invitation once")
	for n in range(70):
		if session.in_studio:break
		var decision: Dictionary=commission_policy.call(session.observation())
		if not act(decision.type,decision.get("payload",{})).ok:quit(1);return
	var commission_meta:Dictionary=session.run.get_release_metadata(session.development.project.get_release_id())
	expect(session.in_studio and commission_meta.get("owner")==&"publisher" and commission_meta.review.scope>=commission_meta.review.required_scope,"Actual publisher-owned commission commits full required Scope")
	expect(session.run._store_era_receipts==era_before,"Actual full-Scope commission publication earns no Studio era receipt")
	var adapter:=StudioCheckpoint.new();var dto:=adapter.capture(session.run)
	expect(not dto.is_empty(),"Completed searched cash/Brief/commission sources validate: "+adapter.error)
	var cold:=adapter.hydrate(dto)
	expect(cold!=null and adapter.capture(cold)==dto,"Full searched career checkpoint roundtrip is exact")
	expect(cold!=null and cold._store_era_receipts==era_before,"Cold commission restore preserves exclusion from era receipts")
	# Adversarial fixtures are separate from the legal career above.
	for mutation in ["orphan", "fee", "standing", "publisher", "receipt", "duplicate"]:
		var altered: Dictionary=bytes_to_var(var_to_bytes(session.run.get_contract_search_state()))
		match mutation:
			"orphan":altered.offers.erase(altered.offers.keys()[0])
			"fee":altered.receipts[0].terms.cash_cents+=1
			"standing":altered.receipts[0].standing_bp+=1
			"publisher":altered.receipts[0].publisher_id=&"neon_circuit"
			"receipt":altered.receipts[0].receipt_id=&"forged"
			"duplicate":altered.receipts.append(altered.receipts[0].duplicate(true))
		var data: Dictionary=session.run.ContractSearch.data(session.run).duplicate(true);data.contract_search=altered
		expect(not session.run.ContractSearch.valid(data),"Forged Search source rejects: "+mutation)
	var synthetic:=Factory.create_fresh_session(recipe,catalog)
	synthetic.run._unlocked_publishers[&"sidestreet"]=true
	expect(synthetic.run.complete_productive_action(),"Synthetic odd-cycle accounting setup")
	var eligible: Dictionary=synthetic.run.get_contract_search_quote(&"sidestreet",&"cash")
	expect(not eligible.is_empty(),"Pre-search quote exists before synthetic funding loss")
	expect(synthetic.run.spend_cash_cents(synthetic.run.get_cash_cents()-100),"Synthetic low-cash accounting fixture")
	var frozen:=Replay.state(synthetic)
	expect(not synthetic.run.search_contracts(eligible) and Replay.state(synthetic)==frozen,"Funding-changed stale search rejects atomically before rent boundary")
	# Ordinary productive rules may issue a new partial bill, but existing arrears
	# must be recoverable on the following action. Search preserves that policy.
	var current: Dictionary=synthetic.run.get_contract_search_quote(&"sidestreet",&"cash")
	expect(synthetic.run.search_contracts(current) and synthetic.run.get_studio_finance_report().total_overdue_cents>0,"Search follows ordinary first partial-bill behavior at month boundary")
	frozen=Replay.state(synthetic)
	expect(synthetic.run.get_contract_search_quote(&"sidestreet",&"brief").is_empty() and not synthetic.run.search_contracts(eligible) and Replay.state(synthetic)==frozen,"Blocking arrears cannot be financed from a future Contract payout")
	var replayed:=Factory.create_fresh_session(recipe,catalog);var replay_result:=Replay.replay(replayed,tape)
	expect(replay_result.ok and Replay.state(replayed)==Replay.state(session),"Full legal Search career tape replays exactly")
	if not output.is_empty():
		Replay.save_tape(output+".tape.json",tape)
		FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"source":Replay.source_identity(),"checks":checks,"failures":failures,"recipe":recipe,"replay":replay_result,"search":Replay.freeze(session.run.get_contract_search_state()),"finance":session.run.get_studio_finance_report(),"checkpoint":dto},"	"))
	print("CONTRACT_SEARCH checks=%d failures=%d commands=%d cycle=%d"%[checks,failures,tape.steps.size(),session.run.get_completed_run_cycles()]);quit(failures)
