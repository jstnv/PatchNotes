from pathlib import Path
P=Path(__file__).parent/'simulators/rival-quality-1977-20261030-v6/project'
f=P/'scripts/market/rival_career_policy.gd'
s=f.read_text(encoding='utf-8')
old='return {"type":&"begin_development","payload":{"name":"%s %d" % [run.get_studio_name(),view.releases.size()+1],"genre":str(specialty),"theme":"fantasy"}}'
assert old in s
s=s.replace(old,'''var plan:=_project_plan(session)
		if plan.is_empty():return {"type":&"blocked","payload":{"reason":"No funded four-Core project plan"}}
		if int(plan.cost)>run.get_cash_cents():
			var bridge:=_loan(run)
			return bridge if not bridge.is_empty() else {"type":&"blocked","payload":{"reason":"Project runway unavailable"}}
		var themes: Array=PrimitivePredevelopment.catalog().themes
		var index: int=(str(run._bank_run_id).sha256_text().substr(0,8).hex_to_int()+run.get_released_game_ids().size())%themes.size()
		return {"type":&"begin_development","payload":{"name":"%s %d" % [run.get_studio_name(),view.releases.size()+1],"genre":str(plan.genre),"theme":str(themes[index].id)}}''',1)
s+='''
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
	var reserve:=run.get_cash_cents();var loan:=_loan(run)
	if not loan.is_empty():reserve+=int(loan.payload.quote.get("net_proceeds_cents",0))
	var plans: Array=[];var first: bool=run.get_released_game_ids().is_empty()
	for genre: StringName in PrimitiveReviewCalculator.GENRE_TARGETS:
		if first and genre!=specialty:continue
		var details: Dictionary=preload("res://scripts/market/market_transaction_trial.gd").targets(market,str(run._bank_run_id),genre)
		if details.is_empty():continue
		var hands:=0
		for i in range(4):hands+=ceili(maxf(0.0,float(details.standards[i])*(6.5 if first else 8.75)/8.0-float(core[i]))/12.0)
		var cycles:=ceili(float(cards.size())/4.0)+hands+4
		var cost: int=fee+int(run._studio_finance.monthly_rent_cents)*ceili(float(cycles)/2.0)
		if cost<=reserve:plans.append({"genre":genre,"hands":hands,"cost":cost})
	if plans.is_empty():return {}
	plans.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return a.hands<b.hands if a.hands!=b.hands else str(a.genre)<str(b.genre))
	for plan: Dictionary in plans:
		if plan.genre==specialty and plan.hands<=int(plans[0].hands)+1:return plan
	return plans[0]
'''
f.write_bytes(s.encode());print('Funded four-Core Genre selection and deterministic catalog Theme variety added.')
