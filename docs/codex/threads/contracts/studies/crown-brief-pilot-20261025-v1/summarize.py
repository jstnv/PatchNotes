from run import *
from collections import Counter
data=load(HERE/'analysis.json');rows=data['rows'];facts=[]
for seed in ['4521','4522']:
    take=next(r for r in rows if r['case']=='balanced-'+seed)
    skip=next(r for r in rows if r['case']=='skip-'+seed)
    rp=load(RAW/('branches-'+seed)/'cases'/take['case']/'result.json')
    rs=load(RAW/('branches-'+seed)/'cases'/skip['case']/'result.json')
    finance_deltas={}
    def walk(a,b,p=''):
        if isinstance(a,dict) and isinstance(b,dict):
            for k in a.keys()&b.keys():walk(a[k],b[k],p+'/'+k)
        elif isinstance(a,(int,float)) and not isinstance(a,bool) and isinstance(b,(int,float)) and a!=b:finance_deltas[p]=a-b
    walk(rp['outcome']['finance'],rs['outcome']['finance'])
    comparison=load(HERE/('balanced-'+seed+'-comparison.json'))
    facts.append(dict(seed=seed,cycle_delta=take['final_cycle']-skip['final_cycle'],cash_delta_cents=take['cash']-skip['cash'],finance_deltas=finance_deltas,matched_calendar=comparison['matched_calendar'],matched_release_milestones=comparison['matched_release_milestones']))
results=[x for r in rows for x in r['results']]
notes=[]
for seed in ['4521','4522']:
    for line in (RAW/('branches-'+seed)/'experiment.log').read_text().splitlines():
        if line.startswith('PN_CB_HAND '):notes.append(json.loads(line.split(' ',1)[1]))
by_arm={}
for arm in ['balanced','completion','naive','passes']:
    rr=[r for r in rows if r['arm']==arm]
    hands=[h for h in notes if h['case'].startswith(arm+'-') and h['hand']==1]
    by_arm[arm]=dict(totals=[r['reputation_bp'] for r in rr],pass_cards=sum(r['passes'] for r in rr),feature_cards=sum(r['features'] for r in rr),final_hands_with_full_option=sum(h['full_options']>0 for h in hands),results=[dict(seed=r['seed'],grades=[x['grade'] for x in r['results']],scopes=[x['scope'] for x in r['results']]) for r in rr])
summary=dict(status='PASS',commands=sum(r['commands'] for r in rows),briefs=len(results),zero=sum(x['grade']==0 for x in results),partial=sum(0<x['grade']<10000 for x in results),full=sum(x['grade']==10000 for x in results),r20=sum(bool(r['r20']) for r in rows),arms=by_arm,pairs=facts)
write(HERE/'summary.json',summary)
print(json.dumps({k:v for k,v in summary.items() if k!='pairs'},indent=2))
