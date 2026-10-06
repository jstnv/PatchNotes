from pathlib import Path
import json,csv,hashlib,subprocess
ROOT=Path(__file__).resolve().parents[1]; OUT=ROOT/'design-logs/task27-v1'
def read(n):return json.loads((OUT/n).read_text())
def normalize(x,ids):
 if isinstance(x,dict):return {k:normalize(v,ids) for k,v in x.items()}
 if isinstance(x,list):return [normalize(v,ids) for v in x]
 return ids.get(x,x) if isinstance(x,str) else x
def norm(x,r):return normalize(x,{q['release_id']:f'release{i}' for i,q in enumerate(r['releases'])})
def csvwrite(name,rows):
 if not rows:return
 with (OUT/name).open('w',newline='',encoding='utf-8') as f:
  w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
pro=read('projections.json'); port=read('portfolio.json'); pair_checks=[];comparisons=[];boundaries=[];route_summary=[]
portfolios={(x['policy'],x['case'],x['arm']):x for x in port['outputs']}
for policy in ['cautious','ordinary','synergy']:
 for case in [0,1]:
  base=read(f'route_main_{policy}_next_{case}.json')
  bpoints={int(x['cycle']):x for x in base['live_cycles']}
  for arm in ['next','newer','older','store']:
   r=read(f'route_main_{policy}_{arm}_{case}.json');o=r['opportunity'];a=o['action']
   paired=norm(o['before'],r)==norm(base['opportunity']['before'],base) and norm(o['records'],r)==norm(base['opportunity']['records'],base)
   pair_checks.append(paired);assert paired,(policy,case,arm)
   margin=None;units=None
   if arm in ['newer','older'] and a['success']:
    f=next(x for x in o['records'] if x['release_id']==a['id']);z=a['record_after']
    organic=int(z['organic_awareness_scaled']);review=int(f['review_tenths']);market=int(f['market_bp'])
    native_units=500*review*organic*market//(70*200*10000*10000)
    units=int(z['monthly_units'])-native_units
    net=lambda u:u*999*70//100
    margin=net(int(f['earned_units'])+int(z['monthly_units']))-net(int(f['earned_units'])+native_units)-10000
   end=portfolios[(policy,case,arm)];bend=portfolios[(policy,case,'next')]
   comparisons.append(dict(policy=policy,case=case,arm=arm,success=a['success'],start_cycle=o['before']['cycle'],start_cash_cents=o['before']['cash_cents'],immediate_cash_change=o['after']['cash_cents']-o['before']['cash_cents'],campaign_extra_units=units,campaign_full_month_margin_cents=margin,g3_review=r['releases'][2]['final_review'],g3_cycle=r['releases'][2]['cycle'],g3_delay=r['releases'][2]['cycle']-base['releases'][2]['cycle'],final_native_cash_cents=r['final']['cash_cents'],conditional_common_cycle=end['end_cycle'],conditional_cash_delta=end['final_cash_cents']-bend['final_cash_cents']))
   for point in r['live_cycles']:
    c=int(point['cycle'])
    if c%2 or c<o['before']['cycle'] or c not in bpoints:continue
    vals=dict(policy=policy,case=case,arm=arm,cycle=c,cash_cents=point['cash_cents'],base_cash_cents=bpoints[c]['cash_cents'],delta_cash_cents=point['cash_cents']-bpoints[c]['cash_cents'],earned_cents=sum(x['entitlement_cents'] for x in point['records']),settled_cents=sum(x['settled_cents'] for x in point['records']))
    boundaries.append(vals)
   for i,release in enumerate(r['releases'],1):
    actions=[a for a in r['actions'] if a.get('game')==i and a.get('phase') in ['design','alpha','beta']]
    route_summary.append(dict(policy=policy,case=case,arm=arm,game=i,review=release['final_review'],cycle=release['cycle'],scope=release['scope'],cores=json.dumps(release['cores']),awareness=release['awareness'],cash_cents=release['cash_cents'],hands=len(actions),blockers=json.dumps(r['blockers'])))
projection_rows=[];monthly=[]
for r in pro['results']:
 base=next(x for x in pro['results'] if x['profile']==r['profile'] and x['variant']==r['variant'] and x['schedule']=='none' and x['horizon']==r['horizon'])
 profile=next(x for x in pro['profiles'] if x['id']==r['profile'])
 projection_rows.append(dict(profile=r['profile'],review=profile['release']['final_review'],market_bp=profile['frozen']['market_bp'],variant=r['variant'],schedule=r['schedule'],fee_cents=r['fee_cents'],horizon=r['horizon'],first_zero_month=r['first_zero_month'],first_unaffordable_month=r['first_unaffordable_month'],units=r['final']['earned_units'],earned_cents=r['final']['entitlement_cents'],settled_cents=r['final']['settled_cents'],cost_cents=r['cost_cents'],incremental_units=r['final']['earned_units']-base['final']['earned_units'],margin_cents=r['final']['entitlement_cents']-base['final']['entitlement_cents']-r['cost_cents']))
 for x in r['rows']:monthly.append(dict(profile=r['profile'],variant=r['variant'],schedule=r['schedule'],fee_cents=r['fee_cents'],horizon=r['horizon'],**x))
budget=[]
for case in [0,1]:
 for mode in ['ordinary','native']:
  r=read(f'route_budget_{mode}_synergy_next_{case}.json')
  for i,x in enumerate(r['releases'],1):
   actions=[a for a in r['actions'] if a.get('game')==i and a.get('phase') in ['design','alpha','beta']]
   budget.append(dict(case=case,choice=mode,game=i,review=x['final_review'],cycle=x['cycle'],cores=x['cores'],hands=len(actions)))
repeat=[]
for policy in ['ordinary','synergy']:
 for arm in ['next','older']:
  r=read(f'route_repeat_{policy}_{arm}_0.json');repeat.append(dict(policy=policy,arm=arm,first_success=r['repeat_preparation']['success'],second_success=r['opportunity']['action']['success'],campaign_count=r['sales_records'][0]['campaign_count'],release3=r['releases'][2],final_cash=r['final']['cash_cents']))
for name,rows in [('opportunity.csv',comparisons),('native-calendar-boundaries.csv',boundaries),('releases.csv',route_summary),('projection-summary.csv',projection_rows),('monthly.csv',monthly)]:csvwrite(name,rows)
source_before=read('source-before.json'); changed=[]
for raw,h in source_before.items():
 p=Path(raw)
 if hashlib.sha256(p.read_bytes()).hexdigest()!=h:changed.append(raw)
assert not changed,changed
report=dict(pair_checks=len(pair_checks),all_paired=all(pair_checks),native_trace_parity=port['native_trace_parity_checks'],native_trace_failures=port['failures'],projection_parity=pro['native_parity_cycles'],projection_failures=pro['failures'],source_unchanged=not changed,opportunity=comparisons,budget=budget,repeat=repeat,projection=projection_rows)
(OUT/'summary.json').write_text(json.dumps(report,indent=2))
print(json.dumps({k:v for k,v in report.items() if k not in ['projection','budget','repeat']},indent=2))
