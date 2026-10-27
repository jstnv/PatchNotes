from pathlib import Path
from collections import Counter
import hashlib
import json
import statistics

OUT=Path(__file__).resolve().parent

def age_units(record):
    """Exact observed-horizon units by age month, including a final half month."""
    result={}
    ages=(record['total_earned_cycles']+1)//2
    organic=0
    for age in range(1,ages+1):
        partial=age==ages and record['total_earned_cycles']%2==1
        factor=record['market_factors'][str(age)]['factor_bp']
        if age==1:
            units=(record['total_units']//2 if partial else record['total_units'])*factor//10000
        else:
            organic=record['launch_awareness']*5000+300000 if age==2 else organic*(2500+55*record['review_tenths'])//10000
            boost=100000//(record['campaign_months'][str(age)]+1) if str(age) in record['campaign_months'] else 0
            raw=500*record['review_tenths']*(organic+boost)*record['market_bp']//(70*200*10000*10000)
            units=raw*factor//10000
            if partial: units//=2
        result[age]=units
    assert sum(result.values())==record['earned_units']
    return result

cases=[]
for route in ['action-war','action-fantasy','puzzle-war','puzzle-fantasy']:
    for seed in ['4417','4418']:
        label=f'{route}-{seed}-v2'
        path=OUT/(label+'.json')
        process_path=OUT/(label+'-run.json')
        replay_path=OUT/('replay-'+label+'.json')
        replay_process_path=OUT/('replay-'+label+'-run.json')
        if not path.exists() or not process_path.exists():
            cases.append({'label':label,'status':'MISSING'}); continue
        data=json.loads(path.read_text()); execution=json.loads(process_path.read_text())
        replay=json.loads(replay_path.read_text()) if replay_path.exists() else {}
        replay_process=json.loads(replay_process_path.read_text()) if replay_process_path.exists() else {}
        player_id=data['recipe']['studio_id']
        rivals=[x for x in data.get('actual_publications',[]) if x['owner']!=player_id]
        review=data.get('review_counterfactuals',[])
        sales=data.get('sales_counterfactuals',[])
        factors=[row for title in sales for row in title['age_month_factors']]
        changed_age_months=0
        factual_positive_age_months=0
        age_attribution=[]
        for title in sales:
            actual_ages=age_units(title['actual'])
            own_ages=age_units(title['rival_facts_removed'])
            neutral_ages=age_units(title['all_facts_removed'])
            for factor_row in title['age_month_factors']:
                age=factor_row['age_month']
                changed_age_months+=actual_ages[age]<own_ages[age]
                factual_positive_age_months+=actual_ages[age]>0
                age_attribution.append({'release_id':title['release_id'],'age_month':age,
                    'rival_exclusive_counts':{k:factor_row['actual_factor'][k]-factor_row['own_title_only_factor'][k] for k in ['genre_only','theme_only','pair']},
                    'actual_units':actual_ages[age],'rival_facts_removed_units':own_ages[age],'all_facts_removed_units':neutral_ages[age]})
        checkpoints=[x for x in data['timings'] if 'checkpoint_bytes' in x]
        productive=[x for x in data['timings'] if x.get('world_wall_us',0)>0]
        cumulative={k:{metric:sum(x[k][metric] for x in sales) for metric in ['earned_units','entitlement_cents','settled_cents']} for k in ['actual','rival_facts_removed','all_facts_removed']}
        gains={k:sum(x['settled_gain_targets'][k] for x in sales) for k in ['actual','rival_facts_removed','all_facts_removed']}
        cases.append({'label':label,'status':'PASS' if data.get('completed') and not data.get('failures') and execution.get('exit')==0 and not execution.get('errors') and replay.get('final')==data.get('final') and not replay.get('failures') and replay_process.get('exit')==0 and not replay_process.get('errors') else 'INCOMPLETE',
            'source':data['source_identity'],'starting_source':data['starting_source_identity'],'harness_sha256':data['harness_sha256'],
            'checks':data['checks'],'replay_checks':replay.get('checks'),'commands':data.get('commands'),'cycle':max(x['cycle'] for x in data['timings']),
            'player_releases':len(review),'raised_target_releases':sum(x['actual_standards']!=x['base_standards'] for x in review),
            'actual_reviews':[x['actual']['final_review'] for x in review],'base_target_reviews':[x['genre_base_only']['final_review'] for x in review],
            'review_delta_tenths':[x['actual_minus_base_tenths'] for x in review],
            'rival_releases':len(rivals),'rival_genres':dict(Counter(x['metadata']['genre'] for x in rivals)),
            'rival_themes':dict(Counter(x['metadata']['theme'] for x in rivals)),
            'rival_review_tenths':[x['sales']['review_tenths'] for x in rivals],'rival_strong_releases':sum(x['sales']['review_tenths']>=70 for x in rivals),
            'age_months':len(factors),'rival_factor_reductions':sum(x['actual_factor']['factor_bp']<x['own_title_only_factor']['factor_bp'] for x in factors),
            'rival_changed_earned_age_months':changed_age_months,'factual_positive_earned_age_months':factual_positive_age_months,'age_attribution':age_attribution,
            'own_title_factor_reductions':sum(x['own_title_only_factor']['factor_bp']<10000 for x in factors),
            'floor_age_months':sum(x['actual_factor']['factor_bp']==7000 for x in factors),'cumulative_sales':cumulative,'settled_gain_targets':gains,
            'rival_units_lost':cumulative['rival_facts_removed']['earned_units']-cumulative['actual']['earned_units'],
            'rival_entitlement_cents_lost':cumulative['rival_facts_removed']['entitlement_cents']-cumulative['actual']['entitlement_cents'],
            'own_title_units_lost':cumulative['all_facts_removed']['earned_units']-cumulative['rival_facts_removed']['earned_units'],
            'actual_lost_fans':sum(x['actual_lost'] for x in sales),'final_cash_cents':data['releases'][-1]['cash_cents'] if data['releases'] else None,
            'final_fans':data['releases'][-1]['fans'] if data['releases'] else None,
            'wall_seconds':execution['elapsed_seconds'],'cpu_seconds':execution['process_cpu_seconds'],
            'replay_wall_seconds':replay_process.get('elapsed_seconds'),'replay_cpu_seconds':replay_process.get('process_cpu_seconds'),
            'world_wall_us_total':sum(x['world_wall_us'] for x in productive),
            'world_wall_us_max':max((x['world_wall_us'] for x in productive),default=0),
            'world_wall_us_median':statistics.median([x['world_wall_us'] for x in productive]) if productive else 0,
            'action_wall_us_total':sum(x.get('action_wall_us',0) for x in data['timings']),
            'hash_wall_us_total':sum(x.get('hash_wall_us',0) for x in data['timings']),
            'first_checkpoint_bytes':checkpoints[0]['checkpoint_bytes'] if checkpoints else None,
            'final_checkpoint_bytes':checkpoints[-1]['checkpoint_bytes'] if checkpoints else None,
            'checkpoint_wall_us_total':sum(x['checkpoint_wall_us'] for x in checkpoints),
            'peak_memory_bytes':max((x.get('peak_static_memory_bytes',0) for x in data['timings']),default=0),
            'report_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'coverage':data['coverage']})
summary={'cases':cases,'completed':sum(x['status']=='PASS' for x in cases),'planned_cases':8}
(OUT/'summary.json').write_text(json.dumps(summary,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'completed':summary['completed'],'planned_cases':8,'cases':[{key:case.get(key) for key in ['label','status','checks','replay_checks','rival_units_lost','rival_entitlement_cents_lost','rival_changed_earned_age_months']} for case in cases]},indent=2))
