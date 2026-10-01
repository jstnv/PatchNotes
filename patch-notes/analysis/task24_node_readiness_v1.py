"""First observed shadow node readiness over unchanged Task 24 Studio traces.

No candidate is bought, owned, drawn, or played. Run with bundled Python:
python -B analysis/task24_node_readiness_v1.py
"""
from pathlib import Path
import collections
import csv
import json
import statistics

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'design-logs/task24-v1'
YEARS=[1984,1990,2000,2010,2020]
SCHEDULES={'calendar_only':[0]*5,'light':[1,3,6,12,18],
           'middle':[2,6,12,24,36],'demanding':[4,10,20,35,50],
           'posthoc_candidate':[1,3,6,10,14]}
PRICE_NAMES=['low','center','high']

def command_for(path):
    direct=path.with_suffix('.command.json')
    if direct.exists(): return direct
    name=path.stem.replace('_','-')+'.command.json'
    return OUT/name

def accepted(path):
    if path.name=='stress_repeat_censored981.json' and path.exists():
        data=json.loads(path.read_text(encoding='utf-8'))
        return bool(data.get('censored') and all(r.get('completed_prefix_validated') and r.get('censored') for r in data['rows']))
    command=command_for(path)
    if not path.exists() or not command.exists():return False
    result=json.loads(command.read_text(encoding='utf-8'))
    return result.get('exit')==0 and not result.get('errors',[])

def source_files():
    paths=[]; excluded=[]
    for path in sorted(OUT.glob('normal_*.json')):
        if 'command' in path.name or 'replay' in path.name or path.stem.endswith('_30'):continue
        if accepted(path):paths.append(path)
        else:excluded.append(dict(file=path.name,reason='not a verified completed native command'))
    high=OUT/'high_task21_1104.json'
    if accepted(high):paths.append(high)
    priority=OUT/'stress_priority.json'
    if accepted(priority):paths.append(priority)
    for choices in [('stress_empty.json','stress_empty_checkpoint240.json'),
                    ('stress_repeat_independent.json','stress_repeat.json','stress_repeat_censored981.json','stress_repeat_checkpoint96.json')]:
        selected=next((OUT/n for n in choices if accepted(OUT/n)),None)
        if selected:paths.append(selected)
        for name in choices:
            if (OUT/name).exists() and OUT/name!=selected:
                excluded.append(dict(file=name,reason='superseded duplicate arm or unverified/incomplete capture'))
    excluded.extend(dict(file=p.name,reason='partial progress is not a completed trace') for p in OUT.glob('*_progress_*.json'))
    return paths,excluded

def quote(node,snapshot,band):
    credits=min(5,sum(int(snapshot.get('familiarity',{}).get(parent,0)) for parent in node['parents']))
    return node['prices_cents'][band]*(10-credits)//10

def scan(node,visits,threshold,band,all_capabilities):
    era_cycle=(node['era_year']-1980)*24
    era_visits=[v for v in visits if v['cycle']>=era_cycle and v['qualifying_count']>=threshold]
    platform_ok=all_capabilities or not node['direct_tags']
    ready=[]
    for s in era_visits:
        if platform_ok and set(node['parents'])<=set(s['owned_ids']) and int(s['cash_cents'])>=quote(node,s,band):
            ready.append(s)
    first=ready[0] if ready else None
    era_first=era_visits[0] if era_visits else None
    last=visits[-1] if visits else None
    reasons=[]
    if not first:
        if last is None:reasons.append('no_studio_snapshot')
        elif last['cycle']<era_cycle:reasons.append('calendar_boundary_not_observed')
        if last and last['qualifying_count']<threshold:reasons.append('qualifying_count_not_observed')
        if not platform_ok:reasons.append('no_direct_platform_fixture')
        if last and not set(node['parents'])<=set(last['owned_ids']):reasons.append('direct_parent_ownership_not_observed')
        if last and int(last['cash_cents'])<quote(node,last,band):reasons.append('cash_below_latest_shadow_quote')
        if not reasons:reasons.append('combined_readiness_not_observed')
    return dict(status='observed_shadow_ready' if first else 'not_observed_within_trace',
        first_era_studio_cycle=era_first['cycle'] if era_first else '',
        first_era_cash_cents=era_first['cash_cents'] if era_first else '',
        first_era_quote_cents=quote(node,era_first,band) if era_first else '',
        first_era_missing_parents='|'.join(p for p in node['parents'] if era_first is None or p not in era_first['owned_ids']),
        direct_platform_condition_satisfied=platform_ok,
        first_ready_cycle=first['cycle'] if first else '',
        delay_after_first_era_studio_cycles=first['cycle']-era_first['cycle'] if first else '',
        ready_at_first_era_studio=bool(first and first['cycle']==era_first['cycle']),
        qualifying_count_at_ready=first['qualifying_count'] if first else '',
        cash_at_ready_cents=first['cash_cents'] if first else '',
        price_at_ready_cents=quote(node,first,band) if first else '',
        last_studio_cycle=last['cycle'] if last else '',
        missing_parents_last='|'.join(p for p in node['parents'] if last is None or p not in last['owned_ids']),
        not_observed_reasons='|'.join(reasons),actual_candidate_purchases=0,actual_candidate_plays=0,
        candidate_implemented=False)

def self_checks(catalog):
    byid={n['id']:n for n in catalog['nodes']}
    candidate=byid['narrative_cutscenes']
    visits=[dict(cycle=96,qualifying_count=1,owned_ids=['simple_story'],familiarity={},cash_cents=1000000),
            dict(cycle=100,qualifying_count=1,owned_ids=['simple_story','animated_sprites'],familiarity={},cash_cents=189999),
            dict(cycle=102,qualifying_count=1,owned_ids=['simple_story','animated_sprites'],familiarity={},cash_cents=190000)]
    result=scan(candidate,visits,1,1,False)
    assert result['first_ready_cycle']==102 and result['delay_after_first_era_studio_cycles']==6
    assert scan(candidate,visits,2,1,False)['status']=='not_observed_within_trace'
    # Two-parent sum is a shadow price rule, not a live RunState quote.
    visits[-1]['familiarity']={'simple_story':4,'animated_sprites':3}
    assert quote(candidate,visits[-1],1)==95000
    assert scan(byid['wireframe_3d_space'],visits,1,1,False)['first_ready_cycle']==''
    assert scan(byid['wireframe_3d_space'],visits,1,1,True)['first_ready_cycle']==96
    assert scan(byid['isometric_room_view'],visits,1,1,True)['first_ready_cycle']==''
    return ['first actual parent purchase observed','exact-cent affordability boundary',
        'qualifying gate retained','combined familiarity50%cap','direct platform conditional',
        'missing proposed parent never invented']

def main():
    catalog=json.loads((OUT/'catalog.json').read_text(encoding='utf-8'))
    nodes=[n for n in catalog['nodes'] if n['era_year'] in YEARS]
    assert len(nodes)==38 and not any(n['actual_playable_definition'] for n in nodes)
    checks=self_checks(catalog)
    paths,excluded=source_files()
    records=[]; routes=[]
    for path in paths:
        data=json.loads(path.read_text(encoding='utf-8'))
        assert not data.get('failures'),path
        for r in data.get('rows',[]):
            assert r.get('valid',not r.get('errors')) and not r.get('errors'),path
            visits=sorted(r['studio_visits'],key=lambda v:v['cycle'])
            assert all(v['year']==1980+int(v['cycle'])//24 for v in visits)
            assert all(not (set(v['owned_ids']) & {n['id'] for n in nodes}) for v in visits)
            family='normal_short' if path.name.startswith('normal') and '_240.' in path.name else 'normal_matched_long' if path.name.startswith('normal') else 'high_sensitivity' if path.name.startswith('high') else 'stress_censored_prefix' if data.get('censored') else 'stress'
            route_id=f"{path.stem}:case{r.get('case',0)}"
            routes.append(dict(route_id=route_id,source_file=path.name,family=family,
                stop=r.get('stop'),last_studio_cycle=visits[-1]['cycle'] if visits else None))
            for schedule,thresholds in SCHEDULES.items():
                for node in nodes:
                    count=thresholds[YEARS.index(node['era_year'])]
                    for all_tags in [False,True]:
                        for band,price_name in enumerate(PRICE_NAMES):
                            row=dict(route_id=route_id,source_file=path.name,family=family,
                                policy=r.get('policy','stress'),case=r.get('case',0),seed=r.get('seed',''),
                                store_gate=r.get('store_gate',''),schedule=schedule,
                                era_year=node['era_year'],calendar_cycle=(node['era_year']-1980)*24,
                                required_qualifying_releases=count,node_id=node['id'],node_name=node['name'],
                                direct_parents='|'.join(node['parents']),direct_tags='|'.join(node['direct_tags']),
                                platform_fixture='ALL_synthetic' if all_tags else 'none',price_band=price_name)
                            row.update(scan(node,visits,count,band,all_tags))
                            records.append(row)
    with (OUT/'candidate-first-ready.csv').open('w',newline='',encoding='utf-8') as f:
        writer=csv.DictWriter(f,fieldnames=list(records[0]) if records else [])
        writer.writeheader();writer.writerows(records)
    stats=[]
    for route in routes:
        for platform in ['none','ALL_synthetic']:
            for schedule in SCHEDULES:
                sample=[r for r in records if r['route_id']==route['route_id'] and r['platform_fixture']==platform and r['price_band']=='center' and r['schedule']==schedule]
                ready=[r for r in sample if r['status']=='observed_shadow_ready']
                delayed=[r for r in ready if r['delay_after_first_era_studio_cycles']>0]
                stats.append(dict(route_id=route['route_id'],family=route['family'],platform_fixture=platform,schedule=schedule,
                    later_nodes=38,ready_at_first_era_studio=sum(r['ready_at_first_era_studio'] for r in ready),
                    first_ready_later=len(delayed),not_observed=38-len(ready),
                    delayed_nodes=[dict(id=r['node_id'],first=r['first_ready_cycle'],delay=r['delay_after_first_era_studio_cycles'],
                        initially_missing_parents=r['first_era_missing_parents'],initial_cash_covers_quote=r['first_era_cash_cents']>=r['first_era_quote_cents']) for r in delayed]))
    summary=dict(mode='read_only_first_shadow_node_readiness',checks=checks,schedules=SCHEDULES,
        selected_sources=[p.name for p in paths],excluded_sources=excluded,route_executions=len(routes),rows=len(records),
        limitations=[
            'Readiness is a shadow quote over actual captured Studio ownership and spendable cash. No candidate purchase or play is claimed.',
            'Missing proposed ancestors are never bought or granted; ALL changes only direct platform support.',
            'No reserve, future settlement, purchase cycle, production return or new-card draw is simulated here.',
            'Not observed means censored by the captured route and fixed fixture, never a permanent lock.',
            'Matched long routes share short prefixes and are not independent samples. Stress and high arms stay separate.',
            'stress_censored_prefix is audited completed native progress from a timed-out command; it is not a successful1104 execution. Short replay validates its release and batch-complete Studio prefix, not individual reserve purchase order.',
            'Price bands and combined-parent familiarity are unapproved proposal rules; no runtime catalog was modified.',
            'The posthoc1/3/6/10/14 schedule is a candidate chosen after seeing the high route, not an independent confirmation.'
        ],routes=routes,center_band_by_route=stats)
    (OUT/'candidate-first-ready-summary.json').write_text(json.dumps(summary,indent=2),encoding='utf-8')
    print(json.dumps(dict(routes=len(routes),rows=len(records),checks=checks,
        delayed_center_rows=sum(s['first_ready_later'] for s in stats))))

if __name__=='__main__':main()
