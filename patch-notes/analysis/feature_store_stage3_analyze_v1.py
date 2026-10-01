"""Summarize finite legal era routes; do not extrapolate censored paths."""
from pathlib import Path
import csv, gzip, hashlib, json, math, statistics

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'design-logs/feature-store-staged-v1'
ERAS = [(1984,96),(1990,240),(2000,480),(2010,720),(2020,960),(2026,1104)]
POLICIES = ['cautious','ordinary','optimizer']

def load(name):
    path = OUT/name
    return json.loads(path.read_text())['rows'] if path.exists() else []

def total_settled(state):
    return sum(s['settled_cents'] for s in state['sales'])

def median(values): return statistics.median(values) if values else None

def snapshot(row, cycle):
    return next((s for s in row['cycle_rows'] if s['cycle']==cycle),None)

def played_before(row, cycle):
    return sorted({c for a in row['actions'] if a.get('phase') in ['design','alpha'] and a.get('after',{}).get('cycle',10**9)<=cycle for c in a.get('selected',[]) if not c.endswith('_pass')})

def studio_opportunities(row):
    result=[dict(s,store_opened=True) for s in row['studio_visits']]
    for key,contract in row.items():
        if key!='ironclad' and not key.startswith('sidestreet_'): continue
        s=dict(contract['after_dismiss'])
        s['store_opened']=False
        s['spendable_after_reserve_cents']=max(0,s['cash_cents']-150000)
        result.append(s)
    return sorted(result,key=lambda s:s['cycle'])

def checkpoints(rows):
    result=[]
    for year,cycle in ERAS:
        reached=[(r,snapshot(r,cycle)) for r in rows if snapshot(r,cycle)]
        studio=[next((s for s in studio_opportunities(r) if s['cycle']>=cycle),None) for r,_ in reached]
        eligible=[s for s in studio if s]
        result.append(dict(year=year,cycle=cycle,denominator=len(rows),reached=len(reached),censored=sum(r['final']['cycle']<cycle and r['stop'].startswith('bounded') for r in rows),first_studio_observed=len(eligible),releases_at_boundary=[s['release_count'] for _,s in reached],cash_cents=[s['cash_cents'] for _,s in reached],owned_counts=[len(s['owned_ids']) for _,s in reached],played_counts=[len(played_before(r,cycle)) for r,_ in reached],first_studio_cycles=[s['cycle'] for s in eligible],first_studio_spendable_cents=[s['spendable_after_reserve_cents'] for s in eligible]))
    return result

def main():
    cohorts={p:load(f'stage3_{p}_production_0_240.json') for p in POLICIES}
    primary=[r for rows in cohorts.values() for r in rows]
    priority=load('stage3_ordinary_priority_0_1104.json')
    minimal=load('stage3_cautious_minimal_0_96.json')
    long=load('stage3_ordinary_production_0_1104.json')
    all_rows=primary+priority+minimal+long
    checks=[]
    cash_attribution=[]
    for row in all_rows:
        cohort_label='production_long' if row['route']=='production' and row['final']['cycle']>300 else row['route']
        assert row['valid'] and not row['errors'], row['errors']
        cycles=[s['cycle'] for s in row['cycle_rows']]
        assert cycles==list(range(1,row['final']['cycle']+1)), (row['policy'],row['case'])
        assert row['starter_summary']['scope'] in range(20,24)
        assert row['starter_summary']['spent_cents']<=400000
        finite_plays={}
        for action in row['actions']:
            if action.get('phase') not in ['design','alpha']: continue
            key=(action['game'],action['phase'])
            used=finite_plays.setdefault(key,set())
            features={c for c in action.get('selected',[]) if not c.endswith('_pass')}
            assert not used.intersection(features), (key,features)
            used.update(features)
        for s in row['cycle_rows']:
            assert s['cash_cents']>=0 and s['redraws'] in range(5)
            assert all(0<=sale['settled_cents']<=sale['entitlement_cents'] for sale in s['sales'])
        for key,contract in row.items():
            if key!='ironclad' and not key.startswith('sidestreet_'): continue
            assert contract['dismiss_passive']
            assert contract['after_accept']==contract['hands'][0]['before']
            assert contract.get('seeded_initial_deal_passive',True)
            assert contract['completion']['payout_cents']==contract['independent_payout_cents']
            assert all(hand['cash_parity'] for hand in contract['hands'])
        buys=sum(int(p['quote'].get('price_cents',0)) for p in row['purchases'] if p['success'])
        play_costs=sum(int(a.get('cost_cents',0)) for a in row['actions'] if a.get('phase') in ['design','alpha'] and 'selected' in a)
        beta_income=sum(a['after']['cash_cents']-a['before']['cash_cents']-(total_settled(a['after'])-total_settled(a['before'])) for a in row['actions'] if a.get('phase')=='beta' and a.get('success'))
        contract_income=sum(v['completion']['payout_cents'] for k,v in row.items() if k=='ironclad' or k.startswith('sidestreet_'))
        settled_income=total_settled(row['final'])
        expected=550000-buys-play_costs+beta_income+contract_income+settled_income
        assert expected==row['final']['cash_cents'], (row['policy'],row['case'],expected,row['final']['cash_cents'])
        cash_attribution.append(dict(policy=row['policy'],route=cohort_label,case=row['case'],starting_cash_cents=550000,purchases_cents=buys,
            feature_play_cents=play_costs,beta_rival_cash_cents=beta_income,contract_cash_cents=contract_income,settled_sales_cents=settled_income,
            final_cash_cents=expected,residual_cents=0))
        checks.append(dict(policy=row['policy'],route=cohort_label,case=row['case'],cycles=len(cycles),contracts=1+sum(k.startswith('sidestreet_') for k in row),valid=True))
    # Each matched route has equal weight, rather than over-weighting the fast
    # cautious policy because it releases more games inside the bounded horizon.
    cadences=[median([b['cycle']-a['cycle'] for a,b in zip(r['releases'],r['releases'][1:])]) for r in primary]
    cadence=median(cadences)
    stride=math.ceil(96/cadence) if cadence else 6
    tiers={'short':[2,3,4,5,6,7],'long':[stride*i for i in range(1,7)]}
    schedules={}
    for label,thresholds in tiers.items():
        schedules[label]=[]
        for (year,_),release_count in zip(ERAS,thresholds):
            seen=[r['releases'][release_count-1] for r in primary if len(r['releases'])>=release_count]
            schedules[label].append(dict(label=year,required_releases=release_count,reached=len(seen),denominator=len(primary),cycle_median=median([s['cycle'] for s in seen]),cycle_range=[min(s['cycle'] for s in seen),max(s['cycle'] for s in seen)] if seen else [],cash_median_cents=median([s['cash_cents'] for s in seen])))
    loop_segments=[]
    for row in minimal:
        for number,release in enumerate(row['releases'],1):
            if number==1: continue
            contract=row.get(f'sidestreet_{number}')
            if not contract: continue
            start=next(a['before'] for a in row['actions'] if a.get('phase')=='predevelopment' and a.get('game')==f'Era Game {number}')
            end=contract['after_dismiss']
            settlement=total_settled(end)-total_settled(start)
            delta=end['cash_cents']-start['cash_cents']
            payout=contract['completion']['payout_cents']
            assert delta-settlement==payout
            assert release['production_rating']==0 and release['scope']==0
            new_sales=sum(s['settled_cents'] for s in end['sales'] if s['release_id']==release['release_id'])
            loop_segments.append(dict(case=row['case'],release_number=number,cycles=end['cycle']-start['cycle'],cash_delta_cents=delta,
                total_sales_settlement_cents=settlement,older_sales_settlement_cents=settlement-new_sales,new_release_settlement_cents=new_sales,
                contract_only_cents=payout,review=release['final_review'],new_release_earned_units=next(s['earned_units'] for s in end['sales'] if s['release_id']==release['release_id'])))
    policy_summary={p:dict(n=len(rs),ending_cycles=[r['final']['cycle'] for r in rs],releases=[len(r['releases']) for r in rs],end_cash_cents=[r['final']['cash_cents'] for r in rs],blockers=[r['blockers'] for r in rs],checkpoints=checkpoints(rs)) for p,rs in cohorts.items()}
    loop_summary=dict(n=len(loop_segments),all_profitable=all(s['contract_only_cents']>0 for s in loop_segments),
        payout_min_cents=min((s['contract_only_cents'] for s in loop_segments),default=None),
        payout_max_cents=max((s['contract_only_cents'] for s in loop_segments),default=None),
        payout_median_cents=median([s['contract_only_cents'] for s in loop_segments]),
        cycles=sorted({s['cycles'] for s in loop_segments}))
    summary=dict(source_revision='608a2c62ab0850cf607f7ff627b042a49b5d2dfb',
        scope='Current Godot actions; no candidate card injected. Controlled RNG only. Headless scene signals, no native graphical input.',
        origin=1980,normal=policy_summary,primary_n=len(primary),all_checks=checks,priority=checkpoints(priority),
        minimal=checkpoints(minimal),long_ordinary=checkpoints(long),cadence_median=cadence,long_tier_stride=stride,
        tier_rules=tiers,tier_results=schedules,loop_segments=loop_segments,loop_summary=loop_summary)
    summary['cash_attribution']=cash_attribution
    summary['long_route_tiers']={label:[dict(required_releases=n,cycle=r['releases'][n-1]['cycle'],cash_cents=r['releases'][n-1]['cash_cents'])
        for r in long for n in thresholds if len(r['releases'])>=n] for label,thresholds in tiers.items()}
    with gzip.open(OUT/'stage3_month_boundaries_v1.csv.gz','wt',newline='',encoding='utf-8') as f:
        writer=csv.writer(f)
        writer.writerow(['cohort','policy','case','run_cycle','year','release_count','run_cash_cents','production_reserve_cents','spendable_after_reserve_cents','release_id','age_cycles','earned_units','entitlement_cents','settled_cents','monthly_units'])
        for r in all_rows:
            cohort_label='production_long' if r['route']=='production' and r['final']['cycle']>300 else r['route']
            for s in r['cycle_rows']:
                if s['cycle']%2: continue
                common=[cohort_label,r['policy'],r['case'],s['cycle'],s['calendar_year'],s['release_count'],s['cash_cents'],150000,max(0,s['cash_cents']-150000)]
                if not s['sales']:
                    # Retain actual pre-launch cash/calendar boundaries even
                    # though there is no release-specific sales record yet.
                    writer.writerow(common+['']*6)
                for sales in s['sales']:
                    writer.writerow(common+[sales['release_id'],sales['earned_cycles'],sales['earned_units'],sales['entitlement_cents'],sales['settled_cents'],sales['monthly_units']])
    expected={}
    for r in all_rows:
        cohort_label='production_long' if r['route']=='production' and r['final']['cycle']>300 else r['route']
        key=(cohort_label,r['policy'],r['case'])
        assert key not in expected
        expected[key]={s['cycle']:s for s in r['cycle_rows'] if s['cycle']%2==0}
        assert set(expected[key])==set(range(2,r['final']['cycle']+1,2))
    observed={key:set() for key in expected}
    pre_release_rows=0
    csv_rows=0
    with gzip.open(OUT/'stage3_month_boundaries_v1.csv.gz','rt',newline='',encoding='utf-8') as f:
        for record in csv.DictReader(f):
            key=(record['cohort'],record['policy'],int(record['case']))
            cycle=int(record['run_cycle'])
            state=expected[key][cycle]
            assert int(record['run_cash_cents'])==state['cash_cents']
            assert int(record['year'])==state['calendar_year']
            assert int(record['release_count'])==state['release_count']
            if not state['sales']:
                assert all(record[field]=='' for field in ['release_id','age_cycles','earned_units','entitlement_cents','settled_cents','monthly_units'])
                assert cycle not in observed[key]
                pre_release_rows+=1
            else:
                assert record['release_id']
            observed[key].add(cycle)
            csv_rows+=1
    assert all(observed[key]==set(states) for key,states in expected.items())
    coverage=dict(pass_all=True,routes=len(expected),even_boundaries=sum(len(s) for s in expected.values()),
        csv_rows=csv_rows,pre_release_cash_calendar_rows=pre_release_rows,
        per_route=[dict(cohort=key[0],policy=key[1],case=key[2],expected_even_boundaries=len(states),
            observed_even_boundaries=len(observed[key])) for key,states in expected.items()])
    summary['month_boundary_export_coverage']=coverage
    (OUT/'stage3_month_boundary_coverage_v1.json').write_text(json.dumps(coverage,indent=2))
    (OUT/'stage3_summary_v1.json').write_text(json.dumps(summary,indent=2))
    harness_files=sorted(p for p in (ROOT/'analysis').glob('feature_store_stage3*') if p.suffix in ['.py','.gd'])+[ROOT/'analysis/feature_pair_game3_trial_v1.gd']
    manifest={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in harness_files}
    (OUT/'stage3_harness_manifest_v1.json').write_text(json.dumps(manifest,indent=2))
    print(json.dumps({'primary':len(primary),'priority':len(priority),'minimal':len(minimal),'long':len(long),'validated':len(checks),'loop':summary['loop_summary'],'median_cadence':cadence,'tiers':tiers}),flush=True)

if __name__=='__main__':main()
