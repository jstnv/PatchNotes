"""Read-only Task 24 catalog access snapshots; no candidate enters Godot supply.

python -B analysis/task24_catalog_access_v1.py [--schedules path.json]
Schedule JSON maps names to five qualifying-release thresholds, ordered
1984/1990/2000/2010/2020. Calendar-only is always included. Thresholds are
analysis inputs, never inferred or installed as gameplay rules.
"""
from pathlib import Path
import argparse
import json

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'design-logs/task24-v1'
YEARS = [1984,1990,2000,2010,2020]
RESERVE = 150000  # Disclosed analysis holdback, not an implemented payment.
DEFAULT_SCHEDULES = {'calendar_only':[0]*5, 'light':[1,3,6,12,18],
                     'middle':[2,6,12,24,36], 'demanding':[4,10,20,35,50]}

def price(node, familiarity, band=1):
    # Summed parent familiarity is a proposal. It reduces purchase quotes only.
    credit = 0 if node['gameplay_features_required'] else min(5,sum(int(familiarity.get(p,0)) for p in node['parents']))
    return node['prices_cents'][band]*(10-credit)//10

def missing_path(id_, owned, byid):
    path=[]; seen=set()
    def visit(x):
        if x in owned or x in seen: return
        seen.add(x)
        for parent in byid[x]['parents']: visit(parent)
        path.append(x)
    visit(id_)
    return path

def inspect(snapshot, byid, year, platform_all=False):
    owned=set(snapshot['owned_ids']); cash=int(snapshot['cash_cents'])
    familiarity=snapshot.get('familiarity',{})
    assert isinstance(familiarity,dict)
    out=[]
    for node in byid.values():
        # Existing 1981-83 Features have no live year gate. Task 24 never hides
        # their existing ownership/definition behind the proposed later gates.
        era_visible = node['era_year']<1984 or node['era_year']<=year
        parent_ready = all(p in owned for p in node['parents'])
        gameplay_count=sum(byid[x]['department']=='gameplay' for x in owned)
        parent_ready &= gameplay_count>=node['gameplay_features_required']
        supported = platform_all or not node['direct_tags']
        quote=[price(node,familiarity,b) for b in range(3)]
        path=missing_path(node['id'],owned,byid)
        path_era_ready=all(byid[x]['era_year']<1984 or byid[x]['era_year']<=year for x in path)
        path_platform_ready=platform_all or all(not byid[x]['direct_tags'] for x in path)
        path_special_ready=all(not byid[x]['gameplay_features_required'] or gameplay_count>=byid[x]['gameplay_features_required'] for x in path)
        path_prices=[sum(price(byid[x],familiarity,b) for x in path) for b in range(3)]
        shadow_can_quote=era_visible and parent_ready and supported and node['id'] not in owned
        path_ready=path_era_ready and path_platform_ready and path_special_ready
        out.append(dict(id=node['id'],name=node['name'],era_year=node['era_year'],owned_live=node['id'] in owned,
            actual_playable_definition=node['actual_playable_definition'],era_visible=era_visible,
            parents_owned=parent_ready,missing_direct_parents=[p for p in node['parents'] if p not in owned],
            direct_tags=node['direct_tags'],platform_fixture_all=platform_all,platform_allowed=supported,
            shadow_quote_available=shadow_can_quote,discount_percent=100-quote[1]*100//node['prices_cents'][1],
            quote_cents_low_center_high=quote,cash_covers_quote=[cash>=q for q in quote],
            quote_affordable=[shadow_can_quote and cash>=q for q in quote],
            quote_affordable_after_reserve=[shadow_can_quote and cash-RESERVE>=q for q in quote],
            hypothetical_path_ids=path,path_missing_purchase_cycles=len(path),path_gate_ready=path_ready,
            path_cents_low_center_high=path_prices,path_affordable=[path_ready and cash>=q for q in path_prices],
            path_affordable_after_reserve=[path_ready and cash-RESERVE>=q for q in path_prices]))
    return out

def fixture_checks(byid):
    snapshot=dict(owned_ids=['general_combat'],cash_cents=1000000,familiarity={})
    rows={x['id']:x for x in inspect(snapshot,byid,1984)}
    assert not rows['character_classes']['parents_owned']
    snapshot.update(owned_ids=['general_combat','save_files'],familiarity={'general_combat':2,'save_files':4})
    rows={x['id']:x for x in inspect(snapshot,byid,1984)}
    assert rows['character_classes']['quote_cents_low_center_high']==[70000,85000,100000]
    snapshot.update(owned_ids=['tile_based_backgrounds'],familiarity={})
    rows={x['id']:x for x in inspect(snapshot,byid,1984)}
    assert rows['isometric_room_view']['shadow_quote_available']
    assert not rows['wireframe_3d_space']['platform_allowed']
    assert not rows['polygon_models']['era_visible']
    assert all(not x['actual_playable_definition'] for x in rows.values() if x['era_year']>=1984)
    return ['all AND parents required','summed captured credits capped at50%','no ancestor tag inheritance',
            'no conditional no-fixture quote','no future era exposure','zero later actual-playable definitions']

def actual_played_before(row,cycle):
    if row.get('actions') is None:return None  # Censored native progress lacks full action dump.
    result=set()
    for action in row.get('actions',[]):
        if action.get('phase') not in ['design','alpha']:continue
        after=action.get('after',{})
        if after.get('cycle',10**12)<=cycle:
            result.update(c for c in action.get('selected',[]) if not c.endswith('_pass'))
    return sorted(result)

def run(schedules):
    catalog=json.loads((OUT/'catalog.json').read_text(encoding='utf-8'))
    byid={n['id']:n for n in catalog['nodes']}
    checks=fixture_checks(byid)
    records=[]
    sources=list(OUT.glob('normal_*.json'))+list(OUT.glob('stress*.json'))+list(OUT.glob('high_task21_1104.json'))
    for path in sorted(sources):
        if path.stem.endswith('_30') or 'replay' in path.stem: continue
        command=OUT/(path.stem+'.command.json')
        if command.exists() and json.loads(command.read_text())['exit']!=0:continue
        data=json.loads(path.read_text(encoding='utf-8'))
        if not isinstance(data,dict) or 'rows' not in data: continue
        for index,row in enumerate(data['rows']):
            if not isinstance(row,dict) or 'studio_visits' not in row: continue
            snapshots=sorted(row['studio_visits'],key=lambda s:s['cycle'])
            for name,counts in schedules.items():
                for year,threshold in zip(YEARS,counts):
                    cycle=(year-1980)*24
                    at=next((s for s in snapshots if s['cycle']>=cycle and s.get('qualifying_count',0)>=threshold),None)
                    record=dict(source_file=path.name,capture_censored=bool(data.get('censored')),policy=row.get('policy',row.get('arm')),case=row.get('case',index),
                        seed=row.get('seed'),store_gate=row.get('store_gate'),schedule=name,era_year=year,
                        calendar_cycle=cycle,required_qualifying_releases=threshold,reached=at is not None)
                    if at:
                        normal=[n for n in inspect(at,byid,year) if n['era_year']==year]
                        all_tags=[n for n in inspect(at,byid,year,True) if n['era_year']==year]
                        def summary(nodes):
                            band=[n for n in nodes if n['era_year']==year]
                            return dict(nodes=len(band),direct_parents_owned=sum(n['parents_owned'] for n in band),
                                platform_allowed=sum(n['platform_allowed'] for n in band),
                                quote_available=sum(n['shadow_quote_available'] for n in band),
                                quote_affordable_low_center_high=[sum(n['quote_affordable'][i] for n in band) for i in range(3)],
                                quote_affordable_after_reserve_low_center_high=[sum(n['quote_affordable_after_reserve'][i] for n in band) for i in range(3)],
                                whole_path_affordable_low_center_high=[sum(n['path_affordable'][i] for n in band) for i in range(3)],
                                whole_path_affordable_after_reserve_low_center_high=[sum(n['path_affordable_after_reserve'][i] for n in band) for i in range(3)])
                        record.update(cycle=at['cycle'],cash_cents=at['cash_cents'],qualifying_count=at.get('qualifying_count'),
                            actual_owned_ids=at['owned_ids'],actual_played_ids=actual_played_before(row,at['cycle']),
                            reserve_cents=RESERVE,normal_no_platform=normal,
                            synthetic_all_capabilities=all_tags,normal_summary=summary(normal),
                            synthetic_summary=summary(all_tags))
                    records.append(record)
    result=dict(mode='read_only_shadow_access_no_purchases_no_candidate_draws',schedules=schedules,
        warnings=[
            'Quotes are snapshot checks, not executed transactions or post-purchase cash forecasts.',
            'Hypothetical path prices use captured existing parent credits; newly shadow-bought parents get no unearned familiarity.',
            'No sales settlement is credited to pay an upfront quote. Each missing node needs one productive purchase cycle; those cycles are counted but not simulated.',
            'The $1500 reserve is an analysis holdback only; cash-before-reserve is also reported.',
            'No-platform control excludes directly conditional purchases. ALL is an explicit synthetic upper bound, not live capability support.',
            'Absent AND and tertiary support remain missing even for shadow-affordable nodes. Actual owned/played sets contain only live cards.',
            'A candidate era is the five table bands.2026 is a reachability observation horizon, not an additional catalog band.',
            'Snapshots do not model candidate supply dilution, costs to play, Reviews, ongoing affordability, or return on investment.'
        ],checks=checks,records=records)
    (OUT/'catalog-access.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps(dict(records=len(records),reached=sum(r['reached'] for r in records),checks=checks)))
    return result

if __name__=='__main__':
    args=argparse.ArgumentParser()
    args.add_argument('--schedules',type=Path)
    parsed=args.parse_args()
    schedules=DEFAULT_SCHEDULES.copy()
    if parsed.schedules:
        supplied=json.loads(parsed.schedules.read_text(encoding='utf-8'))
        assert all(len(v)==5 and all(isinstance(n,int) and n>=0 for n in v) for v in supplied.values())
        schedules.update(supplied)
    run(schedules)
