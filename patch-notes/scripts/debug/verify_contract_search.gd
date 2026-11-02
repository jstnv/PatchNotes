extends SceneTree
const Factory=preload("res://scripts/debug/search_career_factory.gd")
const Policy=preload("res://scripts/simulation/finite_fixture_policy.gd")
const Replay=preload("res://scripts/simulation/development_replay.gd")
const Session=preload("res://scripts/simulation/campaign_session.gd")
const Begin=preload("res://scripts/simulation/begin_project.gd")
var failures:=0
var checks:=0
var tape: Dictionary
var output: String=OS.get_environment("PN_CARD_FRAME_OUTPUT")
var session: RefCounted
var engine: StringName
var cash_works:=0
var owned_projects:=0
var case_bounds={"seed":"4417","max_commands":1800,"public_prefix_steps":100,"briefs":12,"cash_works":100,"cash_reserve_attempts":30,"owned_projects":6,"phase_actions":64,"commission_commands":100}
var recipe={"schema_version":1,"studio_id":"contract_search_checks","studio_name":"Search Studio","specialty":"action","traits":[],"seed":"4417"}
func expect(ok: bool,label: String) -> void:
	checks+=1
	print("PASS: " if ok else "FAIL: ",label)
	if not ok:failures+=1;push_error(label)
func act(kind: StringName,payload: Dictionary={},accepted: bool=true) -> Dictionary:
	if tape.steps.size()>=1800:
		expect(false,"Declared1800-command bound reached");return {"ok":false,"error":"command_bound"}
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
	cash_works+=1
	if cash_works>100:expect(false,"Declared100 cash-work bound reached");return false
	if not search(&"cash"):return false
	return contract({"kind":&"sidestreet","offer_id":session.run.get_next_sidestreet_offer().offer_id})
func ensure_cash(cents: int) -> bool:
	# Reserve-aware public cash work; no injected funding or relaxed Bank gate.
	for attempt in range(30):
		if attempt%10==0: print("COMMISSION_RESERVE target=",cents," cash=",session.run.get_cash_cents()," attempt=",attempt)
		if session.run.get_cash_cents()>=cents:return true
		if not cash_work():return false
	expect(false,"Declared cash-work reserve bound reached")
	return false
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
		if arg.begins_with("--output="):output=arg.trim_prefix("--output=")
	# The maintained suite passes --out as an existing artifact directory.
	if DirAccess.dir_exists_absolute(output): output=output.path_join("result.json")
	var probe:=RunState.new()
	expect(probe.has_method("get_contract_search_quote"),"Contract Search authority exists")
	if not probe.has_method("get_contract_search_quote"):finish_failure();return
	var catalog=root.get_node("CardDatabase").get_development_catalog()
	session=Factory.create_fresh_session(recipe,catalog)
	if session==null:expect(false,"Canonical Factory and local transport initialization match");finish_failure();return
	tape=Replay.begin(session)
	var choose:=Policy.factory({"genre":"action","theme":"fantasy","name_prefix":"Search Prefix","selection":"features_first","hands":{"design":2,"alpha":2,"beta":2}})
	for n in range(100):
		if session.in_studio and session.run.get_released_game_ids().size()==2:break
		var decision: Dictionary=choose.call(session.observation())
		if not act(decision.type,decision.get("payload",{})).ok:finish_failure();return
	expect(session.run.get_contract_search_quote(&"sidestreet",&"cash").is_empty(),"Search locked before SideStreet unlock")
	expect(session.run._sidestreet_entitlements.is_empty(),"New releases do not auto-generate repeatable cash work")
	if not contract({"kind":&"ironclad"}):finish_failure();return
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
	if not contract({"kind":&"sidestreet","offer_id":receipt.offer_id}):finish_failure();return
	expect(session.run._sidestreet_results[receipt.offer_id].search_receipt_id==receipt.receipt_id and session.run.get_completed_run_cycles()==before+3,"Searched cash work uses ordinary two extra hand cycles")
	if not cash_work():finish_failure();return
	expect(session.run.get_released_game_ids().size()==2,"Repeat cash search needs no intervening release")
	var intro: Dictionary=session.run.get_sidestreet_brief_offer()
	if not contract({"kind":&"sidestreet_brief","offer_id":intro.offer_id}):finish_failure();return
	for attempt in range(12):
		if session.run.get_publisher_relationships()[&"sidestreet"].reputation_bp>=2000:break
		if session.run.get_cash_cents()<120000:
			if not cash_work():finish_failure();return
		if not search(&"brief"):finish_failure();return
		var brief: Dictionary=session.run.get_sidestreet_brief_offer()
		if not contract({"kind":&"sidestreet_brief","offer_id":brief.offer_id}):finish_failure();return
	expect(session.run.get_publisher_relationships()[&"sidestreet"].reputation_bp>=2000,"Legal searched Briefs reach R20 within declared twelve-Brief bound")
	if session.run.get_publisher_relationships()[&"sidestreet"].reputation_bp<2000:finish_failure();return
	expect(session.run.get_commission_quote("Commission",&"action",&"fantasy").is_empty(),"R20 alone does not bypass paid commission discovery")
	if not prepare_current_engine(catalog):finish_failure();return
	if not fund_with_public(1000000):finish_failure();return
	if not select_engine(engine):finish_failure();return
	expect(session.run.get_selected_engine_capacity()==30 and active_scope(catalog)>=30,"Paid all-four GenI capacity30 and committed active Feature Scope30 before commission discovery")
	if not search(&"commission"):finish_failure();return
	var invitation: Dictionary=session.run.ContractSearch.invitation(session.run)
	var quote_a: Dictionary=session.run.get_commission_quote("Commission",&"action",&"fantasy")
	unchanged=Replay.state(session)
	var quote_b: Dictionary=session.run.get_commission_quote("Changed name",&"puzzle",&"fantasy")
	expect(not quote_a.is_empty() and not quote_b.is_empty() and quote_a.search_offer_id==invitation.offer_id and Replay.state(session)==unchanged,"Free cancel/reprepare retains the same unconsumed invitation")
	var failed: Dictionary=Begin.execute(session.run,session.snapshots,"Commission",&"action",&"fantasy",func(_project):return false,[],quote_a)
	expect(not failed.ok and Replay.state(session)==unchanged,"Rejected scene readiness preserves invitation, cash, serial and RNG")
	# Exact quote remains bound to the latest normal training release and paid invitation.
	quote_a=session.run.get_commission_quote("Commission",&"action",&"fantasy")
	var commission_standing_before: Dictionary=session.run.get_publisher_relationships()[&"sidestreet"].duplicate(true)
	var era_before:Dictionary=session.run._store_era_receipts.duplicate(true)
	var commission_policy:=Policy.factory({"genre":"action","theme":"fantasy","name_prefix":"Commission","selection":"features_first","hands":{"design":12,"alpha":12,"beta":2}})
	act(&"quote_commission",{"name":"Commission","genre":&"action","theme":&"fantasy"})
	if not act(&"begin_development",{"name":"Commission","genre":&"action","theme":&"fantasy","commission_quote":quote_a}).ok:finish_failure();return
	expect(session.run.ContractSearch.invitation(session.run).is_empty() and session.run._contract_search.offers[invitation.offer_id].project_id==session.development.project.get_release_id(),"Successful Begin binds the paid invitation once")
	for n in range(100):
		if session.in_studio:break
		var decision: Dictionary=commission_policy.call(session.observation())
		if not act(decision.type,decision.get("payload",{})).ok:finish_failure();return
	var commission_meta:Dictionary=session.run.get_release_metadata(session.development.project.get_release_id())
	if not session.in_studio or commission_meta.is_empty():
		expect(false,"Commission did not finish within100-command bound");finish_failure();return
	expect(session.in_studio and commission_meta.get("owner")==&"publisher" and commission_meta.review.scope>=commission_meta.review.required_scope,"Actual publisher-owned commission commits full required Scope")
	expect(session.run._store_era_receipts==era_before,"Actual full-Scope commission publication earns no Studio era receipt")
	var release_id: StringName=session.development.project.get_release_id()
	var deal: Dictionary=session.run.get_commission_deals().get(release_id,{})
	var grade: Dictionary=session.run.Commission.grade(int(quote_a.required_scope),int(commission_meta.review.scope),roundi(float(commission_meta.review.final_review)*10.0))
	expect(not deal.is_empty() and deal.result.fee_paid_cents==grade.fee_paid_cents,"Commission fee matches full Scope and actual frozen Review delivery")
	var fee_sum:=0;var fee_receipts:=0
	for paid: Dictionary in session.run._studio_finance.actions:
		if paid.source_id==quote_a.quote_id and paid.kind==&"publisher_receipt":fee_sum+=int(paid.direct_delta);fee_receipts+=1
	expect(fee_receipts==1 and fee_sum==int(grade.fee_paid_cents),"Actual commission fee has one exact finance receipt")
	var standing_after: Dictionary=session.run.get_publisher_relationships()[&"sidestreet"]
	expect(standing_after.reputation_bp==mini(10000,int(commission_standing_before.reputation_bp)+int(grade.relationship_award_bp)) and standing_after.investment_bp==mini(10000,int(commission_standing_before.investment_bp)+int(grade.relationship_award_bp)),"Commission standing award matches actual delivery once")

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
	for setup in range(3):
		expect(synthetic.run.complete_productive_action(),"Separate adversarial setup reaches current quarter-month before rent")
	expect(preload("res://scripts/calendar/calendar_clock.gd").is_boundary(synthetic.run.get_completed_run_cycles()+1,synthetic.run.get_calendar_profile()),"Adversarial Search really crosses a current month boundary")
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
	var regression_before: Dictionary=Replay.state(session)
	var royalty_regressions: Dictionary=preload("res://scripts/debug/search_royalty_regressions.gd").new().run_for(session.run)
	checks+=int(royalty_regressions.checks);failures+=int(royalty_regressions.failures)
	expect(Replay.state(session)==regression_before,"Detached royalty regression fixtures preserve live Run and every RNG")

	if not output.is_empty():
		Replay.save_tape(output+".tape.json",tape)
		FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"ok":failures==0,"results":[{"case_id":"current-search-career-4417","ok":failures==0,"status":"PASS" if failures==0 else "FAIL","commands":tape.steps.size(),"final_run_cycle":session.run.get_completed_run_cycles(),"final_release_count":session.run.get_released_game_ids().size()}],"royalty_regressions":royalty_regressions,"bounds":case_bounds,"owned_engine":engine,"owned_projects":owned_projects,"cash_works":cash_works,"source":Replay.source_identity(),"checks":checks,"failures":failures,"recipe":recipe,"replay":replay_result,"search":Replay.freeze(session.run.get_contract_search_state()),"finance":session.run.get_studio_finance_report(),"checkpoint":dto},"	"))
	print("CONTRACT_SEARCH checks=%d failures=%d commands=%d cycle=%d"%[checks,failures,tape.steps.size(),session.run.get_completed_run_cycles()]);quit(failures)

func select_engine(id: StringName) -> bool:
	if session.run.get_selected_engine_id()==id:return true
	return act(&"select_engine",{"engine_id":id}).ok
func fund_with_public(cents: int) -> bool:
	if not select_engine(&"public_action"):return false
	return ensure_cash(cents)
func active_scope(catalog: RefCounted) -> int:
	var total:=0
	for id: StringName in session.run.get_future_project_feature_ids(engine):
		var card: CardData=catalog.get_card(id)
		if card!=null and FeatureStoreCatalog.is_active(id):total+=int(card.scope)
	return total
func implement(id: StringName) -> bool:
	if session.run.owns_feature(id,engine):return true
	if not fund_with_public(400000):return false
	var q: Dictionary=session.run.get_feature_research_quote(id,engine)
	if q.is_empty() or not q.get("can_admit",false):
		expect(false,"Current connected Feature quote unavailable: "+str(id)+" "+str(q));return false
	if not act(&"admit_research",{"quote":q}).ok:return false
	q=session.run.get_feature_research_quote(id,engine)
	if not act(&"research",{"quote":q}).ok:return false
	return true
func dev(kind: StringName,payload: Dictionary={}) -> Dictionary:
	return act(&"development",{"request":session.development.command(kind,payload)})
func training_project(catalog: RefCounted) -> bool:
	owned_projects+=1
	if not fund_with_public(650000) or not select_engine(engine):return false
	if not act(&"begin_development",{"name":"Earned GenI project "+str(owned_projects),"genre":&"action","theme":&"fantasy"}).ok:return false
	for phase_index in 3:
		if phase_index>0 and not dev(&"enter_next_phase").ok:return false
		if not dev(&"begin").ok:return false
		var seen: Dictionary={};var played:=0
		for step in 64:
			var hand: RefCounted=session.development.hand
			var selected: Array[int]=[]
			var cards: Array[CardData]=[]
			if phase_index<2:
				for index in hand.candidate_ids.size():
					var card: CardData=hand._candidate_cards[index]
					if card.card_type==&"feature":selected.append(hand.candidate_ids[index]);cards.append(card)
					if selected.size()==4:break
				if selected.is_empty() and played>0:
					var done:=true
					for card: CardData in catalog.get_project_features_for_phase(session.development.project,session.development.PHASES[phase_index]):
						if not seen.has(card.id):done=false
					if done:break
			if selected.is_empty():
				for index in hand.candidate_ids.size():
					var card: CardData=hand._candidate_cards[index]
					if phase_index==2 and card.card_type==&"beta" and not BetaPriorityAllocation.category_enabled(card.beta_category):continue
					var proposed: Array[CardData]=cards.duplicate();proposed.append(card)
					if phase_index<2 and not hand.can_play_pass_budget(proposed):continue
					selected.append(hand.candidate_ids[index]);cards.append(card)
					if selected.size()==4:break
			if selected.is_empty():break
			if not dev(&"play",{"candidate_ids":selected}).ok:return false
			played+=1
			for card: CardData in cards:
				if card.card_type==&"feature":seen[card.id]=true
			if phase_index==2 and played>=2:break
		expect(played>0,"Owned training project actually plays phase "+str(phase_index))
		if not dev(&"request_exit").ok:return false
		if session.development.awaiting_confirmation and not dev(&"confirm_exit").ok:return false
	if not act(&"launch").ok:return false
	return true
func prepare_current_engine(catalog: RefCounted) -> bool:
	if not fund_with_public(650000):return false
	var created: Dictionary=session.run.get_proprietary_engine_creation_quote("Search full-delivery engine")
	if not act(&"create_engine",{"quote":created}).ok:return false
	engine=created.id
	act(&"create_engine",{"quote":created},false)
	for id: StringName in [&"text",&"4_color_palette",&"8_bit_sound",&"keyboard_and_mouse",&"menu_system",&"score_system",&"timer_system",&"main_theme"]:
		if not implement(id):return false
	for attempt in 6:
		if not training_project(catalog):return false
		for branch: StringName in session.run.ProprietaryEngines.BRANCHES:
			if int(session.run.get_proprietary_engine_row(engine).branch_progress.get(branch,0))>0:continue
			var q: Dictionary=session.run.get_engine_skill_quote(engine,branch)
			if q.is_empty():continue
			var cash: int=session.run.get_cash_cents();var cycle: int=session.run.get_completed_run_cycles()
			if not act(&"purchase_engine_skill",{"quote":q}).ok:return false
			expect(session.run.get_cash_cents()==cash-int(q.cost_cents) and session.run.get_completed_run_cycles()==cycle,"Earned GenI node charges exact fee and zero cycles: "+str(branch))
			act(&"purchase_engine_skill",{"quote":q},false)
		if session.run.ProprietaryEngines.milestone(session.run.get_proprietary_engine_row(engine))>=1:break
	expect(session.run.get_engine_feature_state().engines[engine].capacity==30,"Four legally earned and paid GenI nodes grant30 capacity within six projects")
	if session.run.get_engine_feature_state().engines[engine].capacity!=30:return false
	for id: StringName in [&"sprites",&"controller",&"lives_system",&"simple_story",&"dialogue",&"character_backstories",&"controls",&"enemies",&"general_combat",&"levels",&"maps",&"exploration",&"secrets",&"high_scores"]:
		if active_scope(catalog)>=30:break
		if not implement(id):return false
	expect(active_scope(catalog)>=30,"Legal current connected paid library supplies30 active printed Scope")
	return active_scope(catalog)>=30
func finish_failure() -> void:
	if not output.is_empty():
		var report: Dictionary={"ok":false,"results":[{"case_id":"current-search-career-4417","ok":false,"status":"FAIL","commands":tape.get("steps",[]).size()}],"checks":checks,"failures":failures,"bounds":case_bounds,"owned_projects":owned_projects,"cash_works":cash_works}
		if session!=null:report["last_state"]=Replay.state(session)
		FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
		if not tape.is_empty():Replay.save_tape(output+".tape.json",tape)
	quit(1)
