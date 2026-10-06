"""Independent transaction accounting over captured native actions, not a gameplay model."""
from pathlib import Path
import json,csv,statistics
OUT=Path(__file__).resolve().parents[1]/'design-logs/lifespan-verification-v2'
def paid(s):return sum(int(x['settled_cents']) for x in s['sales'])
summary=[];all_events=[];problems=[];monthly=[]
for path in sorted(OUT.glob('route_*.json')):
 r=json.loads(path.read_text(encoding='utf-8'));events=[]
 def add(label,b,a,direct):
  expected=direct+paid(a)-paid(b);actual=a['cash_cents']-b['cash_cents']
  e=dict(route=path.stem,action=label,before_cycle=b['cycle'],after_cycle=a['cycle'],before_cash=b['cash_cents'],after_cash=a['cash_cents'],direct_cents=direct,settlement_cents=paid(a)-paid(b),expected_delta=expected,actual_delta=actual)
  events.append(e)
  if expected!=actual:problems.append(e)
 for a in r['actions']:
  phase=a['phase']
  if phase in ['design','alpha'] and 'after' in a:add(phase,a['before'],a['after'],-a['cost_cents'])
  elif phase=='beta':add(phase,a['before'],a['after'],100000*a['selected'].count('playtest_rival_games'))
  elif phase in ['launch','predevelopment','design priorities','alpha priorities']:add(phase,a['before'],a['after'],0)
 for a in r['purchases']:add('purchase:'+a['id'],a['before'],a['after'],-int(a['quote']['price_cents']) if a['success'] else 0)
 for key,c in r.items():
  if not isinstance(c,dict) or 'contract_id' not in c:continue
  add(key+':accept',c['before'],c['after_accept'],int(c['completion']['upfront_cents']))
  for i,a in enumerate(c['hands']):add(key+':hand'+str(i+1),a['before'],a['after'],int(a['planned_remainder_cents']))
  if 'priority_commit' in c:
   a=c['priority_commit'];add(key+':priorities',a['before'],a['after'],0)
  add(key+':dismiss',c['hands'][-1]['after'],c['after_dismiss'],0)
 for a in r.get('common_alignment',[])+r.get('repeat_alignment',[]):
  if 'after' in a:add('campaign_alignment_purchase',a['before'],a['after'],-int(a['quote']['price_cents']) if a['success'] else 0)
 if 'repeat_preparation' in r:
  a=r['repeat_preparation'];add('first_campaign',a['before'],a['after'],-10000 if a['success'] else 0)
 if 'opportunity' in r:
  a=r['opportunity']['action']
  if 'after' in a:add('campaign',a['before'],a['after'],-10000 if a['success'] else 0)
 cycles=[e['after_cycle'] for e in events if e['after_cycle']>e['before_cycle']]
 expected_cycles=list(range(1,int(r['final']['cycle'])+1))
 if sorted(cycles)!=expected_cycles:problems.append({'route':path.stem,'kind':'cycle_coverage','missing':sorted(set(expected_cycles)-set(cycles)),'duplicates':sorted({c for c in cycles if cycles.count(c)>1})})
 final_expected=550000+sum(e['direct_cents'] for e in events)+sum(x['settled_cents'] for x in r['sales_records'])
 if final_expected!=r['final']['cash_cents']:problems.append({'route':path.stem,'kind':'whole_run_cash','expected':final_expected,'actual':r['final']['cash_cents']})
 for sample in r['live_cycles']:
  for report in sample['monthly_reports']:
   for row in report['rows']:monthly.append(dict(route=path.stem,run_cycle=sample['cycle'],release_id=report['release_id'],age_month=row['age_month'],halves=row['earned_halves'],units=row['units'],gross_cents=row['gross_cents'],net_cents=row['net_cents'],paid_cents=row['settled_cents'],unpaid_cents=row['unpaid_cents']))
 summary.append(dict(route=path.stem,specialty=r['specialty'],policy=r['policy'],case=r['case'],reviews=[x['final_review'] for x in r['releases']],release_cycles=[x['cycle'] for x in r['releases']],cycle=r['final']['cycle'],cash_cents=r['final']['cash_cents'],ledger_checks=r['ledger_checks'],row_checks=r['row_checks'],actions=len(events),blockers=r['blockers']))
 all_events+=events
for name,rows in [('transaction-audit.csv',all_events),('observed-monthly-rows.csv',monthly)]:
 with (OUT/name).open('w',newline='',encoding='utf-8') as f:
  w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
result={'routes':summary,'transactions':len(all_events),'monthly_rows':len(monthly),'discrepancies':problems}
(OUT/'accounting-audit.json').write_text(json.dumps(result,indent=2))
print('Accounting',len(summary),'routes',len(all_events),'transactions',len(monthly),'rows',len(problems),'discrepancies')
print(json.dumps(problems[:8],indent=2))
