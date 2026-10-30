from pathlib import Path
import hashlib,json,copy
study=Path(__file__).resolve().parent
thread=study.parent.parent
prior=study.parent/'crown-planning-20261024-v1'
project=thread/'simulators/crown-lookahead-brief-v1/project'
sha=lambda b:hashlib.sha256(b).hexdigest()
p=project/'scripts/simulation/contract_session.gd'
old=p.read_bytes();text=old.decode('utf-8')
needle='"available_redraws":_run.get_available_redraws(),'
assert text.count(needle)==1
text=text.replace(needle,needle+'"planning_pool":planning_pool(),')
text+='''

# Detached public owned/eligible definitions for observation-only planning.
# No random stream, future draw or mutable CardData reference is exposed.
func planning_pool() -> Array:
	var result: Array = []
	var ids: Array = []
	for id in _state.get_eligible_feature_ids():
		if not _state.is_feature_exhausted(id): ids.append(id)
	ids.append_array(ContractState.PASS_IDS)
	for id in ids:
		var card: CardData = catalog.get_card(id)
		if card == null: continue
		result.append({"definition":card.id,"card_type":card.card_type,"primary_stat":card.primary_stat,"primary_value":card.primary_value,"secondary_stat":card.secondary_stat,"secondary_value":card.secondary_value,"scope":card.scope,"renewable":card.renewable})
	return result
'''
p.write_bytes(text.encode('utf-8'))
policy=(prior/'policy.gd').read_text(encoding='utf-8')
policy=policy.replace('var redraw_expected: Dictionary = {}','var redraw_expected: Dictionary = {}\nvar safe_floor := -1')
policy=policy.replace('var chosen := [cards[0],cards[1],cards[2],cards[3]]','''var planning: Array = []
	if int(state.hand_count)==0 and str(config.arm).begins_with("lookahead"): planning=plan_first(state,cards)
	var planning_index := 0
	var chosen := [cards[0],cards[1],cards[2],cards[3]]''')
policy=policy.replace('\t\t\t\t\tif config.arm=="completion":', '''\t\t\t\t\tif not planning.is_empty(): rank=int(planning[planning_index].rank)
					planning_index+=1
					if config.arm=="completion":''')
start=policy.index('\tvar prospective := project(state,chosen)')
end=policy.index('\tprediction = project(state,chosen)',start)
policy=policy[:start]+'''\tvar prospective := project(state,chosen)
	var current_grade := int(grade(prospective.scope,prospective.cores).grade)
	if safe_floor>=0:
		if current_grade<safe_floor: return fail("conservative redraw lost best achievable grade")
		note("SAFE_MONOTONE",{"offer":state.offer_id,"before":safe_floor,"after":current_grade})
		safe_floor=-1
	var conservative := str(config.arm).ends_with("_safe")
	if int(state.hand_count)==1 and (str(config.arm).ends_with("_redraw") or conservative) and int(state.available_redraws)>0 and int(state.successful_redraws)<2 and current_grade<10000:
		var token := int(chosen[excess_card(chosen,prospective.cores)].token)
		var decision: Dictionary = {}
		if conservative:
			decision=safe_redraw(state,cards,chosen,current_grade)
			token=int(decision.token)
			note("SAFE_DECISION",{"offer":state.offer_id,"visible":cards,"pool":state.planning_pool,"priorities":state.priorities,"scope":state.scope,"cores":state.core_half_units,"before_grade":current_grade,"decision":decision})
		if token>=0:
			redraw_expected={"budget":state.available_redraws,"used":state.successful_redraws,"scope":state.scope,"cores":state.core_half_units.duplicate(true)}
			if conservative: safe_floor=current_grade
			note("REDRAW",{"offer":state.offer_id,"hand":state.hand_count,"before_grade":current_grade,"token":token,"budget":state.available_redraws,"used":state.successful_redraws,"visible":cards,"best":prospective,"cycle":view.run_cycle,"safe":conservative,"decision":decision})
			return command(view,&"redraw",{"candidate_ids":[token]})
'''+policy[end:]
policy+='\n'+(study/'policy_extra.gd').read_text(encoding='utf-8')
with (study/'policy.gd').open('x',encoding='utf-8',newline='\n') as f:f.write(policy)
oldcases=json.loads((prior/'cases.json').read_text())
for name,arms in [('controls',['balanced','balanced_redraw','skip']),('candidates',['balanced_safe','lookahead','lookahead_safe'])]:
    cases=[]
    for arm in arms:
        for seed in ['4417','4418','4419']:
            c=copy.deepcopy(next(c for c in oldcases['cases'] if c['case_id']==f'balanced-{seed}'))
            c['case_id']=f'{arm}-{seed}';c['policy']['config']={'arm':arm,'label':c['case_id']};cases.append(c)
    cfg={'schema_version':'1','policy':{'script':'policy.gd','id':'crown-two-hand-lookahead','version':'1'},'cases':cases}
    with (study/f'{name}.json').open('x',encoding='utf-8') as f:json.dump(cfg,f,indent=2);f.write('\n')
receipt={'path':'scripts/simulation/contract_session.gd','before':sha(old),'after':sha(p.read_bytes()),'policy_sha256':sha((study/'policy.gd').read_bytes()),'plan_sha256':sha((thread/'CROWN-LOOKAHEAD-PLAN-2026-10-24-v1.md').read_bytes()),'configs':{n:sha((study/f'{n}.json').read_bytes()) for n in ['controls','candidates']}}
with (study/'prepare-receipt.json').open('x',encoding='utf-8') as f:json.dump(receipt,f,indent=2);f.write('\n')
print(json.dumps(receipt,indent=2))
