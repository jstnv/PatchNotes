## Candidate legal career policy. Decisions do not consume future RNG/draws.
extends RefCounted
const Synergy := preload("res://scripts/market/rival_synergy_choice.gd")
var specialty: StringName
var state := {"project_id":"","search_done":false,"beta_hands":0,"marketing_hands":0,"loan_project":-1}
var _search := 0
var _marketing := 0

func _init(genre: StringName = &"action") -> void: specialty=genre

func scope(run: RunState) -> int:
	var total := 0
	for id in run.get_future_project_feature_ids(): total+=int(run._feature_definitions[id].scope)
	return total

func _loan(run: RunState) -> Dictionary:
	for months in [24,36]:
		var quote := run.get_bank_quote(150000,months)
		if quote.get("accepted",false):return {"type":&"bank_borrow","payload":{"quote":quote}}
	return {}

func _shop(run: RunState,starter: bool,target: int) -> Dictionary:
	var best := {};var value := -INF
	for id: StringName in run._feature_definitions:
		if run.owns_feature(id) or not FeatureStoreCatalog.is_active(id): continue
		var card: Dictionary=run._feature_definitions[id]
		if card.get("phase","") not in ["design","alpha"] or int(card.get("scope",0))<=0:continue
		if run._feature_offers.get(id,{}).has("replaces_id"):continue
		var quote: Dictionary=run.get_primitive_reserve_offer(id) if starter else run.get_feature_research_quote(id)
		if not quote.get("can_purchase" if starter else "can_admit",false):continue
		var cost: int=int(quote.price_cents) if starter else int(quote.down_cents)+int(quote.remaining_cents)
		# Prefer inexpensive connected capability, and fund both installments.
		if cost>run.get_cash_cents():continue
		var score: float=float(mini(int(card.scope),target-scope(run)))/float(maxi(1,cost))
		if score>value or (score==value and (best.is_empty() or str(id)<str(best.id))):
			value=score;best={"id":id,"quote":quote}
	return {} if best.is_empty() else {"type":&"starter_purchase","payload":{"feature_id":best.id}} if starter else {"type":&"admit_research","payload":{"quote":best.quote}}

func _standards(session: RefCounted) -> Array:
	var result: Array=session.development.project.get_market_standards()
	return result if result.size()==4 else PrimitiveReviewCalculator.GENRE_TARGETS[session.development.project.get_genre_id()].duplicate()

func _rating(core: Dictionary,standards: Array,addition: Dictionary = {}) -> float:
	var ratios: Array=[];var mean:=0.0
	for i in range(4):
		var ratio:=clampf(float(int(core.get(i,0))+int(addition.get(i,0)))/float(standards[i]),0.0,1.25)
		ratios.append(ratio);mean+=ratio/4.0
	var variance:=0.0
	for r in ratios:variance+=pow(r-mean,2.0)/4.0
	return clampf((mean-0.5*sqrt(variance))*8.0,0.0,10.0)

func _priorities(session: RefCounted,view: Dictionary) -> Dictionary:
	if view.phase==&"beta":
		var limits:=BetaPriorityAllocation.bounds(session.run)
		return {&"qa":limits.y,&"marketing":100-limits.y,&"insider":0}
	var standards:=_standards(session);var core: Dictionary=view.development.core
	var limits:=PriorityAllocation.bounds(session.run)
	var result := {0:limits.x,1:limits.x,2:limits.x,3:limits.x}
	for step in range((100-4*limits.x)/5):
		var index:=0;var best:=-INF
		for i in range(4):
			var deficit: float=(float(standards[i])-float(core[i]))/float(standards[i])
			var score: float=deficit-float(result[i]-limits.x)/float(limits.y)
			if result[i]<limits.y and score>best:best=score;index=i
		result[index]+=5
	return result

func _hand(session: RefCounted,view: Dictionary,production: bool) -> Array[int]:
	var current: Dictionary=view.development;var cards: Array=current.candidates
	var best: Array[int]=[];var value:=-INF;var best_features:=-1
	var standards: Array=_standards(session);var goal:=6.5 if session.run.get_released_game_ids().is_empty() else 8.75
	var affordability := {}
	var by_token: Dictionary={}
	for i in range(session.development.hand.candidate_ids.size()):by_token[int(session.development.hand.candidate_ids[i])]=session.development.hand._candidate_cards[i]
	for a in range(cards.size()-3):
		for b in range(a+1,cards.size()-2):
			for c in range(b+1,cards.size()-1):
				for d in range(c+1,cards.size()):
					var offered: Array=[cards[a],cards[b],cards[c],cards[d]];var tokens: Array[int]=[];var selected: Array[CardData]=[];var features:=0
					for card: Dictionary in offered:
						if not by_token.has(int(card.token)):break
						selected.append(by_token[int(card.token)]);tokens.append(int(card.token))
						if card.type=="feature":features+=1
					if selected.size()!=4:continue
					# A strictly lower Feature count cannot beat an already legal best.
					if production and features<best_features:continue
					var score:=0.0
					if production:
						if not session.development.hand.calculate_base(selected).get("valid",false):continue
						var cost: int=session.run.primitive_feature_hand_cost_cents(selected,session.project_id())
						if cost<0:continue
						if not affordability.has(cost):affordability[cost]=session.run.can_complete_productive_cycle(-cost)
						if not affordability[cost]:continue
						var assessed:=Synergy._assess(current,offered)
						if assessed.is_empty():continue
						var predicted:=_rating(current.core,standards,assessed.final_core)
						score=minf(predicted,goal)-maxf(0.0,predicted-goal)*0.1
					else:
						var search:=0;var debug:=0;var marketing:=0;var valid:=true
						for card: Dictionary in offered:
							if card.type!="beta" or card.beta_category=="insider":valid=false;break
							if card.qa_operation=="search":search+=int(card.beta_value)
							elif card.qa_operation=="debug":debug+=int(card.beta_value)
							elif card.beta_category=="marketing":marketing+=int(card.beta_value)
						if not valid:continue
						if not state.search_done:score+=search*5.0
						score+=minf(debug,float(current.known_bugs+search))*6.0
						if state.search_done and int(current.known_bugs)==0:score+=marketing*4.0
						else:score+=marketing*0.1
						features=0
					if features>best_features or (features==best_features and score>value):best_features=features;value=score;best=tokens
	return best

func choose(session: RefCounted,view: Dictionary) -> Dictionary:
	_search=0;_marketing=0
	var run: RunState=session.run
	if view.phase==&"studio":
		if run.needs_starter_selection() and scope(run)<30:
			var shopping:=_shop(run,true,30)
			if not shopping.is_empty():return shopping
			var loan:=_loan(run)
			return loan if not loan.is_empty() else {"type":&"blocked","payload":{"reason":"No legal funded starting Scope"}}
		if not run.get_feature_research_queue().is_empty():
			var quote:=run.get_feature_research_quote(StringName(run.get_feature_research_queue()[0].feature_id))
			if quote.get("can_research",false):return {"type":&"research","payload":{"quote":quote}}
			var loan:=_loan(run)
			if not loan.is_empty():return loan
		if not run.needs_starter_selection() and scope(run)<(32 if view.releases.size()==1 else 35):
			var shopping:=_shop(run,false,32 if view.releases.size()==1 else 35)
			if not shopping.is_empty():return shopping
		var loan:=_loan(run) if not run.can_complete_productive_cycle(0) else {}
		if not loan.is_empty():return loan
		var plan:=_project_plan(session)
		if plan.is_empty():return {"type":&"blocked","payload":{"reason":"No funded four-Core project plan"}}
		if not run.can_complete_productive_cycle():
			var bridge:=_loan(run)
			return bridge if not bridge.is_empty() else {"type":&"blocked","payload":{"reason":"Project start unavailable"}}
		var themes: Array=PrimitivePredevelopment.catalog().themes
		var index: int=(str(run._bank_run_id).sha256_text().substr(0,8).hex_to_int()+run.get_released_game_ids().size())%themes.size()
		return {"type":&"begin_development","payload":{"name":"%s %d" % [run.get_studio_name(),view.releases.size()+1],"genre":str(plan.genre),"theme":str(themes[index].id)}}
	var current: Dictionary=view.development
	# Finance runway uses ordinary quotes before the short repayment basis decays.
	var rent: int=int(run._studio_finance.monthly_rent_cents)
	var reserve: int=rent+15000
	if run.get_released_game_ids().size()>0:
		reserve=rent*7+150000
	if run.get_cash_cents()<reserve and int(state.get("loan_project",-1))!=run.get_released_game_ids().size()+1:
		var loan:=_loan(run)
		if not loan.is_empty():return loan
	if str(view.project_id)!=str(state.project_id):
		var loan_project: int=int(state.loan_project)
		state.clear();state.merge({"version":"career-v1","project_id":str(view.project_id),"search_done":false,"beta_hands":0,"marketing_hands":0,"loan_project":loan_project})
	if current.finalized:return {"type":&"launch"} if view.phase==&"beta" else _dev(view,&"enter_next_phase")
	if current.confirmation_pending:return _dev(view,&"confirm_exit")
	if not current.active:
		var priorities:=_priorities(session,view)
		if priorities!=current.priorities:return _dev(view,&"priorities",{"distribution":priorities})
		return _dev(view,&"begin")
	if view.phase in [&"design",&"alpha"]:
		var finite: bool=not session.development.hand._available_features.is_empty()
		for card: Dictionary in current.candidates:
			if card.type=="feature":finite=true
		if view.phase==&"alpha" and not finite and int(current.scope)<int(current.required_scope):return {"type":&"blocked","payload":{"reason":"Frozen Feature supply cannot complete required Scope"}}
		var goal:=6.5 if run.get_released_game_ids().is_empty() else 8.75
		var needs_more: bool=view.phase==&"alpha" and _rating(current.core,_standards(session))<goal
		# can_exit includes the complete affordable visible/undrawn supply gate.
		if not needs_more and current.can_exit:return _dev(view,&"request_exit")
		var tokens:=_hand(session,view,true)
		if not tokens.is_empty():return _dev(view,&"play",{"candidate_ids":tokens})
		var loan:=_loan(run)
		return loan if not loan.is_empty() else {"type":&"blocked","payload":{"reason":"No affordable production progress"}}
	if beta_complete(view):return _dev(view,&"request_exit")
	if not run.can_complete_productive_cycle(0):
		var loan:=_loan(run)
		if not loan.is_empty():return loan
		if current.can_exit:return _dev(view,&"request_exit")
	var tokens:=_hand(session,view,false)
	for card: Dictionary in current.candidates:
		if int(card.token) in tokens:
			if card.qa_operation=="search":_search+=int(card.beta_value)
			if card.beta_category=="marketing":_marketing+=int(card.beta_value)
	return _dev(view,&"play",{"candidate_ids":tokens}) if tokens.size()==4 else {"type":&"blocked","payload":{"reason":"No legal Beta hand"}}

func observe_result(view: Dictionary,choice: Dictionary,result: Dictionary) -> void:
	if result.get("ok",false) and choice.get("type")==&"bank_borrow":state["loan_project"]=view.releases.size()+1
	if not result.get("ok",false) or view.phase!=&"beta" or choice.get("type")!=&"development" or choice.payload.request.type!=&"play":return
	state.beta_hands+=1
	if _search>0 and int(result.get("discovered",-1))==0:state.search_done=true
	if _marketing>0 and state.search_done and int(view.development.known_bugs)==0:state.marketing_hands+=1

func _dev(view: Dictionary,kind: StringName,payload: Dictionary={}) -> Dictionary:
	var current: Dictionary=view.development
	return {"type":&"development","payload":{"request":{"schema_version":1,"type":kind,"project_id":view.project_id,"phase":current.phase,"sequence":current.sequence,"project_cycle":current.project_cycle,"run_cycle":current.run_cycle,"payload":payload}}}

## Compare attainable public supply against the frozen four-Core market. Renewable
## Pass work is estimated in real 12-Core specialization hands, never granted.
## Prefer the specialty within one additional planned hand of the best funded fit.
func _project_plan(session: RefCounted) -> Dictionary:
	var run: RunState=session.run;var cards: Array[CardData]=[];var core: Dictionary={0:0,1:0,2:0,3:0}
	for id: StringName in run.get_future_project_feature_ids():
		var card: CardData=session.catalog.get_card(id)
		if card==null or card.phase not in [CardData.PHASE_DESIGN,CardData.PHASE_ALPHA]:continue
		cards.append(card)
		for contribution: Dictionary in card.core_contributions():
			var stat: int=[&"graphics",&"sound",&"technology",&"design"].find(contribution.stat)
			if contribution.stat==&"tech":stat=2
			if stat>=0:core[stat]+=int(contribution.value)
	var fee: int=run.primitive_feature_hand_cost_cents(cards)
	if fee<0:return {}
	var market: Dictionary=run._market_provider.call(run._bank_run_id,run.get_completed_run_cycles()+1) if run._market_provider.is_valid() else preload("res://scripts/market/market_transaction_trial.gd").neutral()
	var runway: Dictionary={}
	var plans: Array=[];var first: bool=run.get_released_game_ids().is_empty()
	for genre: StringName in PrimitiveReviewCalculator.GENRE_TARGETS:
		if first and genre!=specialty:continue
		var details: Dictionary=preload("res://scripts/market/market_transaction_trial.gd").targets(market,str(run._bank_run_id),genre)
		if details.is_empty():continue
		var hands:=0
		for i in range(4):hands+=ceili(maxf(0.0,float(details.standards[i])*(6.5 if first else 8.75)/8.0-float(core[i]))/12.0)
		var feature_hands:=ceili(float(cards.size())/4.0)
		var cycles:=feature_hands+hands+5
		var cost: int=fee+_known_dues(run,cycles)
		if not runway.has(cycles):runway[cycles]=cost<=run.get_cash_cents() or _funded_runway(run,market,fee,feature_hands,cycles)
		if runway[cycles]:plans.append({"genre":genre,"hands":hands,"cost":cost})
	if plans.is_empty():return {}
	plans.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return a.hands<b.hands if a.hands!=b.hands else str(a.genre)<str(b.genre))
	for plan: Dictionary in plans:
		if plan.genre==specialty and plan.hands<=int(plans[0].hands)+1:return plan
	return plans[0]

func _known_dues(run: RunState,cycles: int,planned_schedule: Dictionary={}) -> int:
	var ledger: Dictionary=run._studio_finance;var first:=run.get_completed_run_cycles();var last:=first+cycles
	var months: int=last/2-first/2
	var total: int=months*(int(ledger.monthly_rent_cents)+StudioFinanceLedger._monthly_payroll(ledger))
	for bill: Dictionary in ledger.obligations:total+=int(bill.unpaid_cents)
	var schedules: Array=[]
	for loan: Dictionary in ledger.bank_loans:
		if not loan.closed:schedules.append(loan.schedule)
	if not planned_schedule.is_empty():schedules.append(planned_schedule)
	var bank:=preload("res://scripts/finance/bank_loan.gd")
	for schedule: Dictionary in schedules:
		var start: int=maxi(1,(first-int(schedule.first_due_cycle))/2+2) if first>=int(schedule.first_due_cycle) else 1
		var stop: int=mini(int(schedule.term_months),(last-int(schedule.first_due_cycle))/2+1) if last>=int(schedule.first_due_cycle) else 0
		for number in range(start,stop+1):
			var due: Dictionary=bank.installment(schedule,number)
			if int(due.due_cycle)>first and int(due.due_cycle)<=last:total+=int(due.payment_cents)
	# Existing dated education payments, not a new course or tuition assumption.
	var dates: Dictionary=bank.schedule(maxi(bank.MIN_PRINCIPAL,months),maxi(1,months),first)
	if not dates.is_empty():total+=months*StudioFinanceLedger.Education.overlap_reserve(ledger.education,dates)
	return total

## Existing-title cash-flow scenario, not spendable forecast money. The shadow
## uses ordinary sales, dues and Bank qualification; no new-title proceeds or
## future draws/RNG are available. Prelude sales are exactly neutral. After1980
## only currently known Market facts are carried/aged: new rival releases are
## unknown, so actual commands must still recheck cash and recovery every tick.
func _funded_runway(run: RunState,market: Dictionary,fee: int,feature_hands: int,cycles: int) -> bool:
	if cycles<1 or cycles>64 or feature_hands<1:return false
	var shadow:=RunState.new()
	preload("res://scripts/simulation/transaction_projection.gd").copy_fields(run,shadow)
	shadow.random_streams=RunRandom.new();shadow.random_streams.restore(run.random_streams.snapshot())
	shadow.checkpoint_before_mutation=Callable();shadow.studio_departure_guard=Callable()
	shadow._market_provider=func(_owner: StringName,target: int)->Dictionary:
		var book:=preload("res://scripts/market/rival_standard_book.gd")
		var transaction:=preload("res://scripts/market/market_transaction_trial.gd")
		if market.get("version")==4:
			var world_cycle: int=target-int(market.epoch_offset)
			var month: int=world_cycle-world_cycle%2;var facts: Array=[]
			for fact: Dictionary in market.facts:
				if fact.release_cycle<month and month-fact.release_cycle<=12:facts.append(fact.duplicate(true))
			return book.snapshot(market.basis,world_cycle,market.epoch_offset,facts)
		return transaction.neutral()
	for step in range(cycles):
		# Begin costs no direct fee; reserve all finite Feature fees in the next
		# Feature hands. Exact dealing changes timing, never the authority checks.
		var cost: int=(fee/feature_hands+int(step<=fee%feature_hands)) if step>=1 and step<=feature_hands else 0
		var progressed:=false
		for attempt in range(3):
			if shadow.get_completed_run_cycles()-run.get_completed_run_cycles()>=64:return false
			if shadow.can_complete_productive_cycle(-cost):
				if not shadow.complete_productive_action(Callable(),-cost):return false
				progressed=true;break
			var borrowing:=_loan(shadow)
			if not borrowing.is_empty() and shadow.accept_bank_loan(borrowing.payload.quote):continue
			if not shadow.complete_productive_action():return false
		if not progressed:return false
	return true

func beta_complete(view: Dictionary) -> bool:
	if view.phase!=&"beta":return false
	return view.development.can_exit and ((state.search_done and int(view.development.known_bugs)==0 and int(state.marketing_hands)>=1) or int(state.beta_hands)>=12)
