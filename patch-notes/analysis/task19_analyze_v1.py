"""Exact-cent fixed-action trait shadows on current Scope-gated Godot traces."""
from pathlib import Path
from functools import lru_cache
import json,csv,statistics,hashlib,subprocess
import studio_trait_post_integration_recheck_v1 as sales
ROOT=Path(__file__).resolve().parents[1]; OUT=ROOT/'design-logs/task19-v1'
rows=json.loads((OUT/'routes_short.json').read_text())['rows']
for i,r in enumerate(rows): r['route_label']='strong_'+str(i)
for tag in ['long','campaign']:
    r=json.loads((OUT/f'routes_{tag}.json').read_text())['rows'][0]; r['route_label']=tag; rows.append(r)
# Fresh low-review control with the same current tutorial/Scope-gate baseline.
r=json.loads((ROOT/'design-logs/task18-v1/ordinary_normal.json').read_text())['rows'][0]; r['route_label']='current_low_control'; rows.append(r)
r=json.loads((OUT/'routes_historical_policy.json').read_text())['rows'][0]; r['route_label']='historical_policy_current_source'; rows.append(r)
scenarios={'neutral':{},'family_300':{'cash':30000},'cult_200_shadow':{'aw':60},'publisher_15_external':{'pub':'external'},'publisher_15_within_2400':{'pub':'within'},'genre_specialty_10_separate':{'aw':10},'buzz_1point_10':{'aw':10,'cash':-5000},'unknown_2point_minus15_all':{'aw':-15,'cash':10000},'unknown_2point_minus10_first':{'first_aw':-10,'cash':10000},'resourceful_1point_100':{'cash':-5000,'resourceful':10000},'lean_2point_10pct_cap100':{'cash':-10000,'lean':True},'hypothetical_bill75_salary100':{'bill':7500,'salary':10000}}
for refund in [1,2]:
    for due in [500,1000,1500]: scenarios[f'loan_{refund}point_{due//100}']={'cash':refund*5000,'due':due}
for budget in [4,6]:
    for conversion in [0,5000,10000]:
        for cap in [30000,None]:
            value=budget*conversion if cap is None else min(cap,budget*conversion)
            scenarios[f'budget{budget}_unit{conversion}_cap{cap}']={'cash':value}
            for refund in [1,2]:
                value=(budget+refund)*conversion if cap is None else min(cap,(budget+refund)*conversion)
                scenarios[f'budget{budget}_unit{conversion}_cap{cap}_loan{refund}']={'cash':value,'due':1000}
outcomes=[]; monthly=[]; checkpoints=[]; parity=0
for r in rows:
    assert r['valid']; records={s['release_id']:s for s in r['frozen_sales_records']}
    releases={r[k]['release_id']:r[k] for k in ['game_1','game_2','game_3','game_4'] if k in r}
    @lru_cache(None)
    def amount(id,cycle,delta=0):
        rel=releases[id]; rec=records[id]
        return sales.net(sales.age_units(rel,rec['market_bp'],cycle,delta,{int(k):v for k,v in rec['campaign_months'].items()}))
    def sale_delta(c,spec,settled=True):
        if settled: c-=c%2
        return sum(amount(id,c,spec.get('aw',0)+(spec.get('first_aw',0) if rel is r['game_1'] else 0))-amount(id,c,0) for id,rel in releases.items())
    timeline=r['live_cycles']
    for snap in timeline:
        for s in snap['sales']:
            assert amount(s['release_id'],snap['cycle'])==s['entitlement_cents'],(r['route_label'],snap['cycle'],s)
            assert amount(s['release_id'],snap['cycle']-snap['cycle']%2)==s['settled_cents']
            parity+=1
    actions=[a for a in r['actions'] if 'before'in a and 'after'in a]
    actions += [dict(r[k],phase=k) for k in ['store_purchase','reserve_purchase']]
    actions += [dict(p,phase='starter_purchase') for p in r['starter_purchases']]
    actions.sort(key=lambda a:a['before']['cycle'])
    spend={}
    for a in actions:
        if a['phase'] in ['design','alpha']:
            spend.setdefault(a['game'],[]).append((a['after']['cycle'],a['cost_cents']))
    store=r['store_purchase']; store_cycle=store['after']['cycle'] if store['success'] else 10**9
    iron=r['ironclad']['completion']['payout_cents']; iron_cycle=r['ironclad']['after_dismiss']['cycle']
    for name,spec in scenarios.items():
        bonus=iron*15//100 if spec.get('pub') else 0
        if spec.get('pub')=='within': bonus=min(bonus,max(0,240000-iron))
        def delta(c,stage='after'):
            relief=sum(min(10000,sum(cost//10 for cyc,cost in purchases if cyc<=c)) for purchases in spend.values()) if spec.get('lean') else 0
            resource=min(spec.get('resourceful',0),store['offer'].get('price_cents',0)) if c>=store_cycle else 0
            return spec.get('cash',0)+sale_delta(c,spec)+relief+resource+(bonus if c>=iron_cycle else 0)-min(96,c//2)*spec.get('due',0)-(c//2)*spec.get('bill',0)-max(0,c//2-r['game_1']['cycle']//2)*spec.get('salary',0)
        first=None; minimum=10**18
        for a in actions:
            b,aft=a['before'],a['after']; c=b['cycle']; ac=aft['cycle']
            settlement=sum(s['settled_cents'] for s in aft['sales'])-sum(s['settled_cents'] for s in b['sales'])
            expense=max(0,b['cash_cents']+settlement-aft['cash_cents'])
            # Resourceful and Lean relief apply directly to eligible costs before payment.
            relief=0
            if spec.get('resourceful') and a['phase']=='store_purchase' and store['success']: relief=min(spec['resourceful'],expense)
            if spec.get('lean') and a['phase'] in ['design','alpha']:
                already=sum(cost//10 for cyc,cost in spend[a['game']] if cyc<=c)
                relief=min(max(0,10000-already),expense//10)
            available=b['cash_cents']+delta(c)
            if first is None and available<expense-relief: first={'cycle':c,'phase':a['phase'],'shortfall_cents':expense-relief-available,'kind':'preflight'}
            cash=aft['cash_cents']+delta(ac); minimum=min(minimum,cash)
            if first is None and cash<0: first={'cycle':ac,'phase':a['phase'],'shortfall_cents':-cash,'kind':'boundary'}
        for snap in timeline:
            c=snap['cycle']; cash=snap['cash_cents']+delta(c)
            record={'route':r['route_label'],'scenario':name,'cycle':c,'run_calendar_month':c//2+1,'paid_loan_dues':min(96,c//2) if spec.get('due') else 0,'loan_dues_cents':min(96,c//2)*spec.get('due',0),'native_cash_cents':snap['cash_cents'],'shadow_cash_cents':cash,'settled_delta_cents':sale_delta(c,spec),'earned_delta_cents':sale_delta(c,spec,False)}
            if c%2==0: monthly.append(record)
            if c in [8,24,48,192]: checkpoints.append(dict(record,checkpoint='paid month '+str(c//2)))
            if c in [6,22,46,190]: checkpoints.append(dict(record,checkpoint='calendar month '+str(c//2+1)))
        for k in ['game_1','game_2','game_3','game_4']:
            if k in r:
                rel=r[k]; checkpoints.append({'route':r['route_label'],'scenario':name,'checkpoint':k+' launch','cycle':rel['cycle'],'native_cash_cents':rel['cash_cents'],'shadow_cash_cents':rel['cash_cents']+delta(rel['cycle'])})
        final=timeline[-1]
        outcomes.append({'route':r['route_label'],'scenario':name,'first_unaffordable':first,'minimum_shadow_cents':minimum,'last_cycle':final['cycle'],'final_native_cents':final['cash_cents'],'final_shadow_cents':final['cash_cents']+delta(final['cycle']),'delta_cents':delta(final['cycle']),'publisher_bonus_cents':bonus,'full_96_dues_reached':final['cycle']>=192 and bool(spec.get('due')),'dues_obligation_cents':96*spec.get('due',0)})
summary={'source':'main 608a2c6 + local verified Task21','routes':len(rows),'neutral_sales_parity_checks':parity,'scenario_count':len(scenarios),'outcome_count':len(outcomes),'strong_launches':[{k:r[k] for k in ['game_1','game_2']} for r in rows[:6]],'scenarios':{}}
for name in scenarios:
    group=[x for x in outcomes if x['scenario']==name and x['route'].startswith('strong_')]
    summary['scenarios'][name]={'mean_short_end_delta_cents':statistics.mean(x['delta_cents'] for x in group),'min':min(x['delta_cents'] for x in group),'max':max(x['delta_cents'] for x in group),'shortfalls':sum(x['first_unaffordable'] is not None for x in group)}
summary['long_loan_checkpoints']=[x for x in checkpoints if x['route']=='long' and x['scenario'].startswith('loan_') and x['checkpoint'].startswith('paid month')]
for name,data in [('summary',summary),('outcomes',outcomes),('monthly',monthly),('checkpoints',checkpoints),('trial_scenarios',scenarios)]: (OUT/(name+'.json')).write_text(json.dumps(data,indent=2),encoding='utf-8')
with (OUT/'monthly.csv').open('w',newline='',encoding='utf-8') as f:
    w=csv.DictWriter(f,fieldnames=monthly[0].keys()); w.writeheader(); w.writerows(monthly)
assert all(hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==h for p,h in json.loads((OUT/'source-before.json').read_text()).items())
print(json.dumps({'parity':parity,'scenarios':len(scenarios),'rows':len(outcomes),'long_loans':summary['long_loan_checkpoints'][-4:]},indent=2))
