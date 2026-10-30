from run import *
from itertools import combinations
STATS={'graphics':0,'sound':1,'technology':2,'design':3}
def grade(scope,cores):
    n=2*min(scope,9)+sum(min(h,8) for h in cores)+2*min(min(cores),8)
    completion=10000*n//66;balance=max(0,10000-1250*max(0,max(cores)-min(cores)-4))
    return min(completion,balance)
def project(start,cards):
    cores=start['cores'].copy();scope=start['scope'];multiplier=3 if len({c['primary_stat'] for c in cards})==1 else 2
    for card in cards:
        scope+=card['scope'];cores[STATS[card['primary_stat']]]+=multiplier*card['primary_value']
        if card['secondary_stat']:cores[STATS[card['secondary_stat']]]+=multiplier*card['secondary_value']
    return dict(scope=scope,cores=cores)
events={}
for group in GROUPS:
    for line in (RAW/('branches-'+group)/'experiment.log').read_text(encoding='utf-8').splitlines():
        if not line.startswith(('PN_CB_PLAN ','PN_CB_HAND ','PN_CB_RESULT ')):continue
        kind,raw=line.split(' ',1);e=json.loads(raw);events.setdefault((e['case'],e['offer']),{}).setdefault(kind,[]).append(e)
assert len(events)==18
rows=[]
for (case,offer),types in events.items():
    hands=types['PN_CB_HAND'];plan=types['PN_CB_PLAN'][0];result=types['PN_CB_RESULT'][0]
    assert len(hands)==2 and [h['hand'] for h in hands]==[0,1]
    state=dict(scope=0,cores=[0,0,0,0])
    for h in hands:
        selected=[c for c in h['visible'] if c['token'] in h['chosen']]
        projected=project(state,selected);assert projected==h['projected']
        grades=[grade(**project(state,[h['visible'][i] for i in combo])) for combo in combinations(range(7),4)]
        if h['hand']==1:
            assert grade(**projected)==result['grade']==max(grades)
            final_positive=sum(g>0 for g in grades);final_max=max(grades)
        state=projected
    tokens=[plan['visible'][i]['token'] for i in plan['chosen_indices']]
    chosen=next(r for r in plan['ranking'] if r['tokens']==tokens)
    assert len(chosen['grades'])==256
    rows.append(dict(case=case,offer=offer,ordinal=result['ordinal'],scope=result['scope'],core_half_units=result['cores'],completion_bp=result['completion'],balance_bp=result['promise'],grade_bp=result['grade'],credited_reputation_bp=result['award'],final_visible_quartets=35,final_positive_quartets=final_positive,final_max_grade_bp=final_max,first_hand_model_mean_reputation=sum(g//10 for g in chosen['grades'])/256/100,first_hand_model_zero_scenarios=sum(g==0 for g in chosen['grades']),model_scenarios=256))
write(HERE/'hand-audit.json',dict(status='PASS',briefs=len(rows),exact_hand_projections=36,final_quartets_enumerated=18*35,rows=rows,limits='Final-hand maximum is conditional on the reached first hand. Public planning scenarios are hypothetical, not calibrated success probabilities or actual future RNG.'))
for r in rows:print(json.dumps(r))
