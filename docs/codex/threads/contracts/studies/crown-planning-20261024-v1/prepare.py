"""Create the predeclared observation-only fork delta and study policy once."""
from pathlib import Path
import hashlib,json,copy

study=Path(__file__).resolve().parent
thread=study.parent.parent
prior=study.parent/'crown-balance-20261024-v1'
project=thread/'simulators/crown-planning-brief-v1/project'
sha=lambda b:hashlib.sha256(b).hexdigest()
p=project/'scripts/simulation/contract_session.gd'
old=p.read_bytes(); text=old.decode('utf-8')
needle='"challenge_terms":_state.get_challenge_terms(),"successful_redraws":_state.get_challenge_redraws(),'
assert text.count(needle)==1
text=text.replace(needle,needle+'"available_redraws":_run.get_available_redraws(),')
p.write_bytes(text.encode('utf-8'))
policy=(prior/'policy.gd').read_text(encoding='utf-8')
policy=policy.replace('var reached := false','var reached := false\nvar redraw_expected: Dictionary = {}')
policy=policy.replace('var state: Dictionary = view.contract\n\tif not prediction.is_empty():','''var state: Dictionary = view.contract
	if not redraw_expected.is_empty():
		if int(state.available_redraws) != int(redraw_expected.budget)-1 or int(state.successful_redraws) != int(redraw_expected.used)+1: return fail("redraw debit mismatch")
		if int(state.scope) != int(redraw_expected.scope) or state.core_half_units != redraw_expected.cores: return fail("redraw altered scores")
		note("REDRAW_AFTER",{"offer":state.offer_id,"remaining":state.available_redraws,"used":state.successful_redraws,"cycle":view.run_cycle})
		redraw_expected = {}
	if not prediction.is_empty():''',1)
policy=policy.replace('"redraws":state.successful_redraws}', '"redraws":state.successful_redraws,"remaining_redraws":state.available_redraws}')
needle='\t\t\t\t\tif config.arm=="completion":'
assert policy.count(needle)==1
policy=policy.replace(needle,'''\t\t\t\t\tif int(state.hand_count)==0 and str(config.arm).begins_with("retained"):
						rank = int(forecast(projected,hand,cards)*1000000.0)+int(score.grade)*100-spread
'''+needle)
needle='\tprediction = project(state,chosen)'
assert policy.count(needle)==1
policy=policy.replace(needle,'''\tvar prospective := project(state,chosen)
	if int(state.hand_count)==1 and str(config.arm).ends_with("_redraw") and int(state.available_redraws)>0 and int(state.successful_redraws)<2 and int(grade(prospective.scope,prospective.cores).grade)<10000:
		var index := excess_card(chosen,prospective.cores)
		redraw_expected = {"budget":state.available_redraws,"used":state.successful_redraws,"scope":state.scope,"cores":state.core_half_units.duplicate(true)}
		note("REDRAW",{"offer":state.offer_id,"hand":state.hand_count,"before_grade":grade(prospective.scope,prospective.cores).grade,"token":chosen[index].token,"budget":state.available_redraws,"used":state.successful_redraws,"visible":cards,"best":prospective,"cycle":view.run_cycle})
		return command(view,&"redraw",{"candidate_ids":[int(chosen[index].token)]})
'''+needle)
policy+='''
static func contribution(card: Dictionary) -> Array[float]:
	var values: Array[float] = [0.0,0.0,0.0,0.0]
	values[STATS[str(card.primary_stat)]] += 2.0*float(card.primary_value)
	if not str(card.secondary_stat).is_empty(): values[STATS[str(card.secondary_stat)]] += 2.0*float(card.secondary_value)
	return values

static func forecast(projected: Dictionary, hand: Array, cards: Array) -> float:
	var mean: Array[float] = [0.0,0.0,0.0,0.0]
	var mean_scope := 0.0
	var retained: Array = []
	for card: Dictionary in cards:
		var values := contribution(card)
		for i in range(4): mean[i] += values[i]/7.0
		mean_scope += float(card.scope)/7.0
		if card not in hand: retained.append(card)
	var best := -1.0
	for mask in range(8):
		var cores: Array[float] = []
		for h: int in projected.cores: cores.append(float(h))
		var scope := float(projected.scope)
		var kept := 0
		for j in range(3):
			if mask & (1 << j):
				kept += 1
				var values := contribution(retained[j])
				for i in range(4): cores[i] += values[i]
				scope += float(retained[j].scope)
		for i in range(4): cores[i] += float(4-kept)*mean[i]
		scope += float(4-kept)*mean_scope
		var n: float = 2.0*minf(scope,9.0)+2.0*minf(float(cores.min()),8.0)
		for h: float in cores: n += minf(h,8.0)
		var completion := 10000.0*n/66.0
		var promise := clampf(10000.0-1250.0*maxf(0.0,float(cores.max())-float(cores.min())-4.0),0.0,10000.0)
		best = maxf(best,minf(completion,promise))
	return best

static func excess_card(hand: Array, cores: Array) -> int:
	var mean := 0.0
	for h: int in cores: mean += float(h)/4.0
	var best := -INF
	var selected := 0
	for j in range(hand.size()):
		var values := contribution(hand[j])
		var rank := 0.0
		for i in range(4): rank += values[i]*(float(cores[i])-mean)
		if rank>best:
			best=rank
			selected=j
	return selected
'''
with (study/'policy.gd').open('x',encoding='utf-8',newline='\n') as f:f.write(policy)
oldcases=json.loads((prior/'cases.json').read_text())
cases=[]
# Controls execute before candidate arms, without altering seeds/recipes.
for arm in ['balanced','skip','retained','balanced_redraw','retained_redraw']:
    for seed in ['4417','4418','4419']:
        c=copy.deepcopy(next(c for c in oldcases['cases'] if c['case_id']==f'balanced-{seed}'))
        c['case_id']=f'{arm}-{seed}'; c['policy']['config']={'arm':arm,'label':c['case_id']}
        cases.append(c)
cfg={'schema_version':'1','policy':{'script':'policy.gd','id':'crown-visible-planning','version':'1'},'cases':cases}
with (study/'cases.json').open('x',encoding='utf-8') as f:json.dump(cfg,f,indent=2);f.write('\n')
receipt={'path':'scripts/simulation/contract_session.gd','before':sha(old),'after':sha(p.read_bytes()),'policy_sha256':sha((study/'policy.gd').read_bytes()),'config_sha256':sha((study/'cases.json').read_bytes()),'plan_sha256':sha((thread/'CROWN-PLANNING-PLAN-2026-10-24-v1.md').read_bytes())}
with (study/'prepare-receipt.json').open('x',encoding='utf-8') as f:json.dump(receipt,f,indent=2);f.write('\n')
print(json.dumps(receipt,indent=2))
