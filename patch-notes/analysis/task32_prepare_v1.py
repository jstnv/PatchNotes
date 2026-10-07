"""Exact candidate formulas and retained-pool shadows; no runtime changes."""
from pathlib import Path
import ast, hashlib, itertools, json, random
import remaining_publisher_contracts_rebaseline_v1 as rules
from task23_prepare_v1 import fixed, award
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'design-logs/task32-v1'
C=rules.CORES;L=rules.LEDGER
src=(ROOT/'analysis/task20_compare_v1.py').read_text(encoding='utf-8')
tree=ast.parse(src)
parts=[ast.get_source_segment(src,n) for n in tree.body if isinstance(n,ast.FunctionDef) and n.name in ['score','simulate']]
policy='\n\n'.join(parts).replace('def simulate(owned,name,focus,seed,policy):','def simulate(owned,name,focus,seed,policy,changed_priority=True):')
policy=policy.replace('cards=seven() # Current Contract draws before changed priorities.', '''remaining=list(cards)
            for id in chosen:remaining.remove(id)
            reserved=set(remaining)&owned
            for _ in range(4):
                id=draw(reserved);remaining.append(id)
                if id in owned:reserved.add(id)
            cards=remaining
            if not changed_priority:continue''')
policy=policy.replace('cycles=3,policy=policy','cycles=3 if changed_priority else 2,policy=policy')
ns=dict(random=random,itertools=itertools,rules=rules,L=L,C=C)
exec(compile(policy,'retained Task32 visible Contract policy','exec'),ns)
simulate=ns['simulate']

def load_routes():
    for p in sorted(OUT.glob('route_*.json')):
        if '.command.' in p.name:continue
        yield p.stem,json.loads(p.read_text(encoding='utf-8'))

routes=dict(load_routes());inputs=[];traces=[];evaluations=[];eligibility=[];variants={}
for rid,r in routes.items():
    assert r['valid'] and not r['discrepancies']
    frozen={x['release_id']:x for x in r['sales_records']}
    base=dict(id=rid+':baseline',route=rid,actions=r['final']['finance']['actions'],releases=r['releases'],frozen=frozen,
              trigger_game=0,contract_cycles=0,payout=0,promotion=0,expected_cash=r['final']['cash_cents'],expected_cycle=r['final']['cycle'])
    inputs.append(base)
    for name in ['crown','neon']:
        first=next((i for i,x in enumerate(r['releases'],1) if x['final_review']>=7 if name=='crown'),None) if name=='crown' else next((i for i,x in enumerate(r['releases'],1) if x['awareness']>=125),None)
        eligibility.append(dict(route=rid,publisher=name,first_game=first))
    # Bounded representative timelines, both native alignments, ordinary and synergy production.
    selected=(rid in ['route_early_ordinary_1104_available_0_0','route_early_synergy_1104_available_1_0',
                       'route_early_synergy_1104_available_0_1','route_early_synergy_1104_available_1_1'])
    if not selected:continue
    name='neon' if r['neon_policy'] else 'crown'
    first=next((e['first_game'] for e in eligibility if e['route']==rid and e['publisher']==name),None)
    if first is None:continue
    for timing,game in [('early',first),('after_game4',4)]:
        if game<first or game>len(r['releases']):continue
        owned=set(r['releases'][game-1]['owned_ids'])&rules.PRIMITIVE
        focus=max(C,key=lambda c:sum(L[id]['primary_value'] for id in owned if L[id]['primary_stat']==c))
        for cp in ['ordinary','synergy']:
            for seed in range(200929000,200929020):
                for changed in [False,True]:
                    trace=simulate(owned,name,focus,seed,cp,changed)
                    trace.update(name=name,focus=focus,timing=timing,route=rid,trigger_game=game)
                    ti=len(traces);traces.append(trace)
                    low=9 if name=='crown' else 10
                    previous=None
                    for target in [low,low+1]:
                        f=fixed(name,trace['scope'],trace['half'],focus,target);cash,promo=award(name,f)
                        if previous is not None:assert f<=previous
                        previous=f
                        ids={}
                        # Full reward versus cash-only isolates incremental Promotion from settlement.
                        for treatment,amount,prom in [('full',cash,promo),('cash_only',cash,0),('delay_only',0,0)]:
                            key=(rid,game,trace['cycles'],amount,prom)
                            if key not in variants:
                                vid='overlay:'+str(len(variants));variants[key]=vid
                                inputs.append({**base,'id':vid,'trigger_game':game,'contract_cycles':trace['cycles'],'payout':amount,'promotion':prom})
                            ids[treatment]=variants[key]
                        evaluations.append(dict(trace=ti,target=target,full=f==1,payout=cash,promotion=promo,numerator=f.numerator,denominator=f.denominator,variants=ids))
assert all(fixed(name,0,{c:0 for c in C},'graphics',9 if name=='crown' else 10)==0 for name in ['crown','neon'])
assert all(award(name,fixed(name,100,{c:100 for c in C},'graphics',9 if name=='crown' else 10))==list(rules.CAPS[name]) for name in ['crown','neon'])
(OUT/'contract_traces.json').write_text(json.dumps(traces),encoding='utf-8')
(OUT/'evaluations.json').write_text(json.dumps(evaluations),encoding='utf-8')
(OUT/'eligibility.json').write_text(json.dumps(eligibility,indent=2),encoding='utf-8')
(OUT/'overlay-inputs.json').write_text(json.dumps(inputs),encoding='utf-8')
(OUT/'contract-policy.py.txt').write_text(policy,encoding='utf-8')
# Existing native draw and ContractState verifier accepts pure retained-pool traces.
s=(ROOT/'analysis/task23_native_rules_v1.gd').read_text(encoding='utf-8').replace('task23-v1','task32-v1').replace('Task23','Task32')
(ROOT/'analysis/task32_native_rules_v1.gd').write_text(s,encoding='utf-8')
print('Prepared',len(routes),'native routes',len(traces),'candidate Contracts',len(evaluations),'target tests',len(inputs),'unique finance timelines')
