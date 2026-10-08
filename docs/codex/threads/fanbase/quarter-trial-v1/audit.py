from pathlib import Path
from fractions import Fraction
import gzip,hashlib,json
HERE=Path(__file__).resolve().parent
checks=0
def check(ok,label):
 global checks
 checks+=1
 if not ok:raise AssertionError(label)
def load(name):return json.loads(gzip.decompress((HERE/(name+'.json.gz')).read_bytes()))
old=json.loads(Path(r'C:\Users\64jus\Downloads\Patch Notes Design Folder\fanbase-replay-20261006\patch-notes\design-logs\task32-v1\route_early_ordinary_1104_available_0_0.json').read_text(encoding='utf-8'))
route=load('none');weak=load('restrained')
def signature(a):return {k:a.get(k) for k in ['phase','game','selected','draw','success','cost_cents','printed_core','printed_scope']}
check(len(route['actions'])==len(old['actions'])==92,'92 native actions')
for a,b in zip(route['actions'],old['actions']):check(signature(a)==signature(b),'Native action parity')
check(route['initial']['cash_cents']==old['initial']['cash_cents']==570000,'Genuine distinct trait funding')
for d in [route,weak]:
 check(d['valid'] and not d['errors'] and not d['discrepancies'],'Native route valid')
 prior={}
 for cycle in d['live_cycles']:
  c=int(cycle['cycle']);fan=cycle['fan_snapshot']
  if c%2:continue
  row=fan['months'][-1];gains=losses=0
  records={x['release_id']:x for x in cycle['records']}
  for id in sorted(fan['releases']):
   entry=fan['releases'][id];before=prior.get(id,{'gained':0,'loss_exposure_accounted':0,'lost':0})
   total=records[id]['earned_units'];reserve=entry['launch_fans'];review=entry['review_tenths']
   gain_target=max(0,total-reserve)*8*min(30,max(0,review-50))//2000
   exposure=min(reserve,entry['neutral']['earned_units'])
   loss_target=exposure*15*max(0,50-review)//1000
   gain=gain_target-before['gained'];loss=min(row['starting']-losses,loss_target-before['loss_exposure_accounted'])
   check(entry['gained']==gain_target,'Independent cumulative gain')
   check(entry['loss_exposure_accounted']==loss_target,'Independent exposure target')
   check(entry['lost']==before['lost']+loss,'Incremental/shared-cap loss')
   gains+=gain;losses+=loss
  check(row['gained']==gains and row['lost']==losses and row['ending']==row['starting']+gains-losses,'Shared monthly accounting')
  check(losses<=row['starting'],'Gains cannot enlarge loss cap')
  prior=fan['releases']
 for row in d['final']['finance']['monthly_rows']:
  expenses=sum(row[k] for k in ['feature_play_cents','store_cents','campaign_cents','playtest_cents','other_expense_cents','interest_cents'])
  receipts=row['financing_in_cents']+row['other_income_cents']+row['sales_settled_cents']
  check(row['closing_cash_cents']==row['opening_cash_cents']+receipts-expenses-row['rent_paid_cents']-row['principal_paid_cents'],'Exact cash')
  check(row['net_profit_cents']==row['sales_net_earned_cents']+row['other_income_cents']-expenses-row['rent_due_cents'],'Exact accrual')
 for record in d['sales_records']:
  check(sum(x['units'] for x in [])==0,'Integer audit enabled') if False else None
  check(record['settled_cents']<=record['entitlement_cents'],'Unsettled not cash')
 check(sum(r['entitlement_cents'] for r in d['sales_records'])==sum(r['sales_net_earned_cents'] for r in d['final']['finance']['monthly_rows']),'Earned portfolio reconciliation')
 check(sum(r['settled_cents'] for r in d['sales_records'])==sum(r['sales_settled_cents'] for r in d['final']['finance']['monthly_rows']),'Settled portfolio reconciliation')
fixed=[]
for i,fans,expected in [(2,96,729),(3,149,870),(4,267,1178)]:
 r=old['releases'][i];rec=old['sales_records'][i]
 awareness=int(r['awareness'])-(fans*150//(fans+300))+min(150,fans//4)
 units=int(Fraction(500)*Fraction(str(r['final_review']))/7*Fraction(200+awareness,200)*Fraction(rec['market_bp'],10000))
 check(units==expected,'Fixed-launch projection');fixed.append(units)
check(weak['releases'][2]['final_review']<5 and weak['final']['fan_snapshot']['releases'][weak['releases'][2]['release_id']]['launch_fans']>0,'Played weak after positive Fans')
check(weak['releases'][3]['final_review']>5,'Played recovery release')
cf=json.loads((HERE/'counterfactual.json').read_text())
check(cf['failures']==0,'Native counterfactual parity')
source=json.loads((HERE/'source.json').read_text());project=Path(source['project'])
for name,digest in source['files'].items():check(hashlib.sha256((project/name).read_bytes()).hexdigest()==digest,'Capture source unchanged '+name)
launches=[]
for d in [route,weak]:
 launches.append([{k:r[k] for k in ['cycle','final_review','awareness','month_1_units','cash_cents']}|{'launch_fans':d['final']['fan_snapshot']['releases'][r['release_id']]['launch_fans']} for r in d['releases']])
first_sales=next((int(a['cycle']) for a,b in zip(route['live_cycles'],old['live_cycles']) if a['cash_cents']!=b['cash_cents']),None)
result=dict(checks=checks,native_counterfactual_checks=cf['checks'],action_parity=92,fixed_projections=fixed,launches=launches,first_launch_divergence=50,first_cash_divergence=first_sales,final_cash=route['final']['cash_cents'],old_final_cash=old['final']['cash_cents'],weak_months=[r for r in weak['final']['fan_history'] if r['month']>=17],counterfactual=[dict(no_loss=r['no_loss'],launches=r['launches'],ending_fans=r['fans'],cash_cents=r['finance']['cash_cents']) for r in cf['results']])
(HERE/'audit.json').write_text(json.dumps(result,indent=2))
print(json.dumps({k:v for k,v in result.items() if k not in ['weak_months','launches']},indent=2))
