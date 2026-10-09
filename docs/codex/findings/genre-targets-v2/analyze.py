"""Audit legal purchases, matching and fixed-action counterfactual ratings."""
from pathlib import Path
from collections import Counter
import gzip, hashlib, json, math, statistics

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
V1=HERE.parent/'genre-targets-v1'
def load(folder,name):
    p=folder/(name+'.json')
    return json.loads(p.read_bytes() if p.exists() else gzip.decompress(p.with_suffix('.json.gz').read_bytes()))
def save(name,value): (HERE/(name+'.json')).write_text(json.dumps(value,indent=2))
def hashes():
    return {str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for base in ['patch-notes/scripts','patch-notes/data','patch-notes/scenes','patch-notes/analysis'] for p in (ROOT/base).rglob('*') if p.is_file() and p.suffix in ['.gd','.json','.tscn']}
if __import__('sys').argv[-1]=='--snapshot':
    save('source-before',hashes())
    raise SystemExit
catalog=json.loads((ROOT/'patch-notes/data/primitive_predevelopment.json').read_text())['genres']
targets=load(V1,'summary')['targets']
ledger={e['id']:e for e in json.loads((ROOT/'patch-notes/data/card_ledger.json').read_text())}
before=load(HERE,'source-before'); after=hashes()
assert before==after, 'Source changed during study'
save('source-after',after)
old=load(V1,'source-sha256')
runtime_diffs=[k for k,v in old.items() if k.startswith(('patch-notes\\scripts','patch-notes\\data','patch-notes\\scenes','patch-notes/scripts','patch-notes/data','patch-notes/scenes')) and after.get(k)!=v]
assert not runtime_diffs, runtime_diffs
baseline=load(V1,'routes')
for r in baseline: r['arm']='none'; r['spent']=0
fresh=sum([load(HERE,a) for a in ['buy','action','adventure']],[])
rows=baseline+fresh
checks=0
def check(value):
    global checks
    assert value
    checks+=1
def prod(scores,ts):
    q=[min(1.25,s/t) for s,t in zip(scores,ts)]
    return max(0,min(10,8*(statistics.mean(q)-.5*statistics.pstdev(q))))
def review(p,r): return math.floor(max(0,min(10,p*r['scope_factor']*r['bug_factor']+r['variance']))*10+.5)/10
def action_signature(r):
    return [{k:a[k] for k in ['phase','draw','final_draw','selected','redraws','priorities','distribution','cost_cents','success','budget_curtailed'] if k in a} for a in r['actions']]
for r in rows:
    check(r['launched'] and r['ledger_valid'])
    check(not r['errors'])
    check(r['initial']['cash_cents']==570000)
    native=prod(r['scores'],[33]*4)
    check(abs(native-r['production'])<1e-7)
    ratio=next(g['ratios'] for g in catalog if g['id']==r['genre'])
    total=sum(r['scores'])
    deviation=sum(abs(100*s/total-t) for s,t in zip(r['scores'],ratio))/2 if total else 0
    native_final=max(0,min(10,native*r['scope_factor']*r['bug_factor']+r['variance']))*max(.75,1-.01*max(0,deviation-6))
    check(math.floor(native_final*10+.5)/10==r['review'])
    r['candidate_production']=prod(r['scores'],targets[r['genre']]['proposed'])
    r['candidate_review']=review(r['candidate_production'],r)
    r['curtailed']=any(a.get('budget_curtailed',False) for a in r['actions'])
    for a in r['actions']:
        if a.get('phase') in ['design','alpha'] and 'selected' in a:
            check(len(a['selected'])==4)
            check(not (Counter(a['selected'])-Counter(a['final_draw'])))
            check(a['after']['cycle']==a['before']['cycle']+1)
            check(a['cost_cents']<=a['before']['cash_cents'])
            check(all(x in r['owned'] for x in a['selected'] if ledger[x]['type']=='feature'))
            cost=sum((ledger[x]['primary_value']+ledger[x]['secondary_value']+2*ledger[x]['scope'])*1000 for x in a['selected'] if ledger[x]['type']=='feature')
            check(cost==a['cost_cents'])
    cash=0
    for tx in r['final']['finance']['transactions']:
        check(tx['cash_before_cents']==cash)
        cash+=tx['cash_delta_cents']
        check(tx['cash_after_cents']==cash)
    check(cash==r['final']['cash_cents'])
    if r['arm']=='buy':
        spent=0
        owned=set(r['initial_owned'])
        for p in r['purchases']:
            check(p['success'] and p['cycle']==0)
            check(p['id'] not in owned)
            owned.add(p['id'])
            cost=(ledger[p['id']]['scope']+1)*15000
            check(p['quote']['price_cents']==cost)
            check(p['cash_before']-p['cash_after']==cost)
            spent+=cost
        check(spent==r['spent'] and spent<=150000)
        check(r['before_project']['cash_cents']==570000-spent)
        check(owned==set(r['owned']))
        check(sum(ledger[x]['scope'] for x in owned)==r['starter_summary']['scope'])
for arm in ['action','adventure']:
    for seed in [1104,2208,3312]:
        for pace in ['early','slow']:
            group=[r for r in fresh if r['arm']==arm and r['seed']==seed and r['pace']==pace]
            check(len(group)==8)
            ref=group[0]
            for r in group[1:]:
                for key in ['owned','scores','cycles','scope_factor','bug_factor','variance']:
                    check(r[key]==ref[key])
                check(action_signature(r)==action_signature(ref))
                check(r['final']['cash_cents']==ref['final']['cash_cents'])
def metrics(rs):
    return {'n':len(rs), 'review':round(statistics.mean(r['candidate_review'] for r in rs),3),'production':round(statistics.mean(r['candidate_production'] for r in rs),3),'scope':round(statistics.mean(r['scope_factor'] for r in rs),3),'bugs':round(statistics.mean(r['bug_factor'] for r in rs),3),'curtailed':sum(r['curtailed'] for r in rs),'cash':round(statistics.mean(r['final']['cash_cents'] for r in rs),1)}
summary={arm:{g['id']:metrics([r for r in rows if r['arm']==arm and r['genre']==g['id']]) for g in catalog} for arm in ['none','buy','action','adventure']}
paired=[]
for r in fresh:
    if r['arm']!='buy': continue
    b=next(b for b in baseline if all(b[k]==r[k] for k in ['genre','seed','pace','policy']))
    paired.append({**{k:r[k] for k in ['genre','seed','pace','policy']},'review_delta':round(r['candidate_review']-b['candidate_review'],3),'production_delta':round(r['candidate_production']-b['candidate_production'],3),'scope_delta':r['scope_factor']-b['scope_factor'],'cash_delta':r['final']['cash_cents']-b['final']['cash_cents'],'curtailed':r['curtailed'],'baseline_curtailed':b['curtailed'],'spent':r['spent'],'purchases':[p['id'] for p in r['purchases']],'roster_scope':r['starter_summary']['scope']})
cohorts={}
for policy in ['ordinary','synergy']:
    for pace in ['early','slow']:
        ps=[p for p in paired if p['policy']==policy and p['pace']==pace]
        cohorts[policy+'_'+pace]={'review_delta':round(statistics.mean(p['review_delta'] for p in ps),4),'negative':sum(p['review_delta']<0 for p in ps),'curtailed':sum(p['curtailed'] for p in ps),'baseline_curtailed':sum(p['baseline_curtailed'] for p in ps)}
report={'fresh_routes':len(fresh),'reused_routes':len(baseline),'checks':checks,'runtime_v1_hashes_match':True,'summary':summary,'paired':paired,'cohorts':cohorts}
save('summary',report)
save('counterfactuals',[{k:r[k] for k in ['arm','genre','policy','pace','seed','scores','candidate_review','candidate_production','review','production','scope_factor','bug_factor','variance','cycles','spent','curtailed']} for r in rows])
for name in ['buy','action','adventure']:
    p=HERE/(name+'.json')
    if p.exists():
        raw=p.read_bytes(); packed=gzip.compress(raw,mtime=0)
        check(gzip.decompress(packed)==raw)
        p.with_suffix('.json.gz').write_bytes(packed); p.unlink()
print(json.dumps({'fresh':len(fresh),'reused':len(baseline),'audit_checks':report['checks'],'summary':summary},indent=2))
