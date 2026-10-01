"""Independent chronology/cash/replay checks and tidy Task24 tables.
No gameplay mutation, no invented future route, no shadow sales credit.
"""
from pathlib import Path
from collections import Counter
import csv,json,re,statistics
ROOT=Path(__file__).resolve().parents[1]; OUT=ROOT/'design-logs/task24-v1'
CHECKPOINTS=[96,240,480,720,960,1104]
SCHEDULES={'calendar_only':[0]*5,'light':[1,3,6,12,18],
           'middle':[2,6,12,24,36],'demanding':[4,10,20,35,50],
           'posthoc_candidate':[1,3,6,10,14]}
def clean(x):
    return re.sub(r'release_[a-f0-9]+','RELEASE',json.dumps(x,sort_keys=True))
def settled(s):return sum(x['settled_cents'] for x in s.get('sales',[]))
def unpaid(s):return sum(x['entitlement_cents']-x['settled_cents'] for x in s.get('sales',[]))
def table(name,rows):
    assert rows
    fields=list(dict.fromkeys(k for r in rows for k in r))
    with (OUT/(name+'.csv')).open('w',newline='',encoding='utf-8') as f:
        w=csv.DictWriter(f,fieldnames=fields);w.writeheader();w.writerows(rows)
def production(row):return [a for a in row['actions'] if a.get('phase') in ['design','alpha','beta']]
summaries=[]; checkpoints=[]; gates=[]; release_rows=[]; months=[]; routes={}; checks=Counter()
for path in sorted(OUT.glob('normal_*.json'))+list(OUT.glob('high_task21_1104.json')):
    if path.stem.endswith('_30') or 'replay' in path.stem:continue
    command=OUT/(path.stem+'.command.json')
    if command.exists() and json.loads(command.read_text())['exit']!=0:continue
    data=json.loads(path.read_text())
    if 'rows' not in data:continue
    for row in data['rows']:
        key=f"{path.stem}:{row['case']}";routes[key]=row
        assert row['valid'] and not row['errors']
        assert row['stop']=='cycle_cap' or row['blockers']
        rel=row['releases']; visits=row['studio_visits']; cyc=row['live_cycles']
        assert len({r['release_id'] for r in rel})==len(rel)
        assert all(r['required_scope']==30 and r['qualifies']==(r['scope']>=r['required_scope']) for r in rel)
        assert [c['cycle'] for c in cyc]==list(range(1,row['final']['cycle']+1))
        assert all(c['year']==1980+c['cycle']//24 and c['cash_cents']>=0 for c in cyc)
        # Captured mid-signal before reconnected HUD listener; inherited Godot
        # _check_year verifies the completed action, not this transient sample.
        checks['mid_signal_old_hud_label']+=sum(not c['hud_year_visible'] for c in cyc)
        assert row['starter_summary']['scope'] in range(20,24) and row['starter_summary']['spent_cents']<=400000
        for s in visits:
            assert s['year']==1980+s['cycle']//24
            assert s['qualifying_count']==sum(r['qualifies'] for r in rel if r['cycle']<=s['cycle'])
            assert s.get('in_studio',True) and s['cash_cents']>=0 and unpaid(s)>=0
        exhausted=set()
        for a in production(row):
            assert len(a['selected'])==4 and len(a['draw'])==7
            assert a['after']['cycle']==a['before']['cycle']+1
            cost=a.get('cost_cents',0)
            rival_cash=100000*a['selected'].count('playtest_rival_games') if a['phase']=='beta' else 0
            assert a['after']['cash_cents']==a['before']['cash_cents']-cost+rival_cash+settled(a['after'])-settled(a['before'])
            checks['successful_hands']+=1
            if a['phase']=='beta':continue
            for id_ in a['selected']:
                if id_.endswith('_pass'):continue
                k=(a['game'],id_);assert k not in exhausted,(key,k)
                exhausted.add(k)
        for p in row.get('purchases',[]):
            if not all(k in p for k in ['kind','quote','before','after']):continue
            assert p['success']
            assert p['after']['cycle']-p['before']['cycle']==(0 if p['kind']=='starter' else 1)
            assert p['after']['cash_cents']==p['before']['cash_cents']-p['quote']['price_cents']+settled(p['after'])-settled(p['before'])
            if p['kind']=='store':assert p['before']['cycle']>=row['store_gate']
            checks['purchases']+=1
        for c in cyc:
            for s in c['sales']:assert 0<=s['settled_cents']<=s['entitlement_cents']
            if c['cycle']%2==0:
                assert unpaid(c)==0,(key,c['cycle'],unpaid(c))
                months.append(dict(route=key,cycle=c['cycle'],year=c['year'],cash_cents=c['cash_cents'],settled_cents=settled(c),unpaid_cents=unpaid(c)))
        for n,r in enumerate(rel,1):
            release_rows.append(dict(route=key,number=n,release_id=r['release_id'],cycle=r['cycle'],year=1980+r['cycle']//24,
                scope=r['scope'],required_scope=r['required_scope'],qualifies=r['qualifies'],review=r['final_review']))
        summaries.append(dict(route=key,policy=row['policy'],case=row['case'],seed=row['seed'],store_gate=row['store_gate'],cap=row['cap'],
            final_cycle=row['final']['cycle'],releases=len(rel),qualifying_releases=sum(r['qualifies'] for r in rel),
            first_qualifying_cycle=next((r['cycle'] for r in rel if r['qualifies']),None),
            final_cash_cents=row['final']['cash_cents'],final_unpaid_cents=unpaid(row['final']),owned=len(row['final']['owned_ids']),
            actual_played_features=len({k[1] for k in exhausted}),hands=len(production(row)),stop=row['stop'],
            minimum_cash_cents=min(c['cash_cents'] for c in cyc),
            rival_cash_cents=sum(100000*a['selected'].count('playtest_rival_games') for a in production(row) if a['phase']=='beta'),
            review_min=min(r['final_review'] for r in rel),
            review_median=statistics.median(r['final_review'] for r in rel),review_max=max(r['final_review'] for r in rel)))
        for boundary in CHECKPOINTS:
            s=next((s for s in visits if s['cycle']>=boundary),None)
            checkpoints.append(dict(route=key,calendar_cycle=boundary,year=1980+boundary//24,reached=bool(s),
                first_studio_cycle=s['cycle'] if s else None,delay_cycles=s['cycle']-boundary if s else None,
                qualifying_count=s['qualifying_count'] if s else None,cash_cents=s['cash_cents'] if s else None,
                unpaid_cents=unpaid(s) if s else None,owned_count=len(s['owned_ids']) if s else None))
        for schedule,counts in SCHEDULES.items():
            for i,(boundary,count) in enumerate(zip(CHECKPOINTS,counts)):
                s=next((s for s in visits if s['cycle']>=boundary and s['qualifying_count']>=count),None)
                gates.append(dict(route=key,schedule=schedule,era_year=1980+boundary//24,threshold=count,reached=bool(s),
                    first_studio_cycle=s['cycle'] if s else None,delay_cycles=s['cycle']-boundary if s else None,
                    year_overshoot=(s['cycle']-boundary)/24 if s else None,
                    cycles_before_next_boundary=max(0,CHECKPOINTS[i+1]-s['cycle']) if s else None,
                    cycles_before_next_era=max(0,CHECKPOINTS[i+1]-s['cycle']) if s and i<4 else None,
                    later_boundaries_crossed=sum(s['cycle']>=b for b in CHECKPOINTS[i+1:5]) if s else None,
                    qualifying_count=s['qualifying_count'] if s else None,cash_cents=s['cash_cents'] if s else None))
        checks['routes']+=1
pairs=[]
for key,a in routes.items():
    if a['policy']=='high_task21' or a['store_gate']!=0:continue
    other=key.replace('_0_'+str(a['cap']),'_24_'+str(a['cap']));b=routes.get(other)
    if b is None:continue
    firsta=next((p['before']['cycle'] for p in a['purchases'] if p.get('kind')=='store'),None)
    firstb=next((p['before']['cycle'] for p in b['purchases'] if p.get('kind')=='store'),None)
    pairs.append(dict(policy=a['policy'],case=a['case'],cap=a['cap'],first_store_immediate=firsta,first_store_24=firstb,
        cash_delta_cents=b['final']['cash_cents']-a['final']['cash_cents'],final_cycle_delta=b['final']['cycle']-a['final']['cycle'],
        qualifying_delta=b['final']['qualifying_count']-a['final']['qualifying_count'],
        release_scope_review_cycle_equal=clean([{k:r[k] for k in ['cycle','scope','final_review']} for r in a['releases']])==clean([{k:r[k] for k in ['cycle','scope','final_review']} for r in b['releases']])) )
replay=[]
for policy in ['cautious','ordinary','synergy']:
    for gate in [0,24]:
        short=routes.get(f'normal_{policy}_{gate}_240:0');long=routes.get(f'normal_{policy}_{gate}_1104:0')
        if not short or not long:continue
        n=len(short['actions'])
        assert clean(short['actions'])==clean(long['actions'][:n]),(policy,gate,'prefix')
        replay.append(dict(policy=policy,gate=gate,matching_actions=n))
high=routes.get('high_task21_1104:0')
if high:
    old=json.loads((ROOT/'design-logs/task21-v1/route_exact.json').read_text())['rows'][0]
    actual=[a for a in production(high) if a['game']<=2]; prior=production(old)
    assert clean(actual)==clean(prior)
    replay.append(dict(policy='high_task21',matching_actions=len(actual),first_two_release_reviews=[r['final_review'] for r in high['releases'][:2]]))
for name,data in [('route-summary',summaries),('calendar-checkpoints',checkpoints),('gate-access',gates),
                  ('first-era-pairs',pairs),('release-table',release_rows),('month-boundaries',months)]:table(name,data)
result=dict(checks=checks,replay=replay,routes=summaries,pairs=pairs,
            note='Long case0 captures extend the short cohort; do not count as independent seeds. Native current sales only; no later candidate bought or played.')
(OUT/'summary.json').write_text(json.dumps(result,indent=2))
print(json.dumps(dict(checks=checks,replay=replay),indent=2))
