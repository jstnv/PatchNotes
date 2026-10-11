"""Independent high-Review audit: B6 original-due finance plus T7 Fan arithmetic."""
from pathlib import Path
from types import SimpleNamespace
import json,ast
import evidence as e
from run import BUILDS,GODOT
H=e.HERE
checks=0
def check(ok,label):
 global checks
 checks+=1
 if not ok:raise AssertionError(label)
def read(name):return json.loads((H/(name+'.json')).read_text(encoding='utf8'))
a=SimpleNamespace(check=check)

def ledger(f):
    """Reconcile original-due bill rows separately from payment-month cash."""
    cash = 0
    for i, t in enumerate(f["transactions"]):
        a.check(t["sequence"] == i + 1 and t["cash_before_cents"] == cash, "journal sequence and cash before")
        cash += t["cash_delta_cents"]
        a.check(cash == t["cash_after_cents"] and cash >= 0, "journal cash after")
    a.check(cash == f["cash_cents"], "closing cash")
    prior = 0
    for row in f["monthly_rows"]:
        tx = [t for t in f["transactions"] if t["month"] == row["month"]]
        delta = sum(t["cash_delta_cents"] for t in tx)
        a.check(row["opening_cash_cents"] == prior, "month continuity")
        a.check(row["cash_change_cents"] == delta and row["closing_cash_cents"] == prior + delta, "month actual cash movement")
        a.check(row["net_profit_cents"] == row["operating_revenue_cents"] - row["operating_expenses_cents"], "month accrued profit")
        for category in ("rent", "payroll"):
            bills = [b for b in f["obligations"] if b["expense_type"] == category and b["month"] == row["month"]]
            a.check(row[category + "_due_cents"] == sum(b["due_cents"] for b in bills), "original-month bill due")
            a.check(row[category + "_unpaid_cents"] == sum(b["unpaid_cents"] for b in bills), "original-month remaining arrears")
            a.check(row[category + "_paid_cents"] == sum(t["amount_cents"] for t in tx if t["kind"] == category + "_payment"), "actual-month bill payment cash")
        prior = row["closing_cash_cents"]
    for bill in f["obligations"]:
        a.check(bill["due_cents"] == bill["paid_cents"] + bill["unpaid_cents"], "original bill amount reconciles")
        a.check(sum(p["cents"] for p in bill["payments"]) == bill["paid_cents"], "original bill payment history")
    for category in ("rent", "payroll"):
        a.check(sum(r[category + "_paid_cents"] for r in f["monthly_rows"]) == sum(b["paid_cents"] for b in f["obligations"] if b["expense_type"] == category), "bill cash paid across all months")
    a.check(prior == cash, "monthly/journal final cash")
    a.check(sum(x["settled"] for x in f["actions"]) == sum(r["sales_settled_cents"] for r in f["monthly_rows"]), "sales settlement actions/rows")
finance=SimpleNamespace(ledger=ledger)
def fan_and_finance(data,initial_fans):
 prior_entries=data['initial']['fanbase']['releases'];prior_fans=initial_fans
 finance.ledger(data['initial']['finance'])
 for state in data['cycles']:
  finance.ledger(state['finance'])
  check(state['cash_cents']==state['finance']['cash_cents'],'independent finance closing cash')
  fan=state['fanbase'];cycle=state['cycle']
  check(fan['last_cycle']==cycle and fan['fans']==state['fans'],'Fan cycle/total')
  check(fan['initial_seed']==initial_fans,'one seed persists')
  records=state['sales']
  if isinstance(records,list):records={r['release_id']:r for r in records}
  if cycle%2:
   check(fan['fans']==prior_fans,'odd cycle publishes no Fan delta');continue
  row=fan['months'][-1];gains=losses=0;details=[]
  check(row['starting']==prior_fans,'shared starting snapshot')
  for rid in sorted(fan['releases']):
   entry=fan['releases'][rid];old=prior_entries.get(rid,dict(gained=0,lost=0,accounted_units=0,loss_exposure_accounted=0))
   record=data['sales'][rid]|records[rid];neutral=entry['neutral'];units=record['earned_units']
   check(neutral['review_tenths']==50 and neutral['launch_awareness']==record['launch_awareness'],'neutral frozen inputs')
   n=500*50*(200+record['launch_awareness'])*record['market_bp']//(70*200*10000)
   check(n==neutral['total_units'],'neutral first-month formula')
   age=cycle-data['metadata'][rid]['release_cycle'];reach=n if age>=2 else n//2 if age==1 else 0
   organic=record['launch_awareness']*5000+300000
   for age_month in range(2,(age+1)//2+1):
    if age_month>2:organic=organic*5250//10000
    monthly=500*50*organic*record['market_bp']//(70*200*10000*10000)
    reach+=monthly//2 if age==2*age_month-1 else monthly
   check(reach==neutral['earned_units'],'neutral cumulative exposure')
   gain_target=max(0,units-entry['launch_fans'])*8*min(30,max(0,entry['review_tenths']-50))//2000
   loss_target=min(entry['launch_fans'],reach)*15*max(0,50-entry['review_tenths'])//1000
   gain=gain_target-old['gained'];loss=min(row['starting']-losses,loss_target-old['loss_exposure_accounted'])
   earned=units-old['accounted_units']
   check(entry['gained']==gain_target and entry['loss_exposure_accounted']==loss_target,'cumulative Fan targets')
   check(entry['lost']==old['lost']+loss and entry['accounted_units']==units,'units and loss applied once')
   if earned or gain or loss:details.append(dict(release_id=rid,earned_units=earned,new_fans=gain,lost_fans=loss))
   gains+=gain;losses+=loss
  check(row['releases']==details,'stable lexical Fan release order')
  check(row['gained']==gains and row['lost']==losses and losses<=row['starting'] and row['ending']==row['starting']+gains-losses,'Fan conservation and shared cap')
  prior_entries=fan['releases'];prior_fans=fan['fans']
 finance.ledger(data['finance'])
 check(data['final']['fans']==prior_fans,'terminal total')
 for rid,record in data['sales'].items():
  review=data['metadata'][rid]['review']
  check(record['total_units']==500*record['review_tenths']*(200+record['launch_awareness'])*record['market_bp']//(70*200*10000),'single sales Awareness conversion')
  check(record['entitlement_cents']==record['earned_units']*999*70//100,'exact net entitlement')
  check(review['fan_awareness']==min(150,review['launch_fans']//4),'quarter/cap Awareness')
  check(record['campaign_count']==0 and not record['campaign_months'],'no undeclared campaign')


def trace(actions):
 keys=['phase','game','draw','final_draw','selected','redraws','priorities','rolls','printed_core','printed_scope','synergy','success','budget_curtailed']
 out=[]
 for action in actions:
  row={k:action[k] for k in keys if k in action}
  if 'hands' in action:row['hands']=[{k:h[k] for k in ['draw','selected']} for h in action['hands']]
  out.append(row)
 return out

def normalize(value):
 import re
 if isinstance(value,str):return re.sub(r'[0-9a-f]{32}:project:', 'RUN:project:',value)
 if isinstance(value,list):return [normalize(v) for v in value]
 if isinstance(value,dict):return {k:normalize(v) for k,v in value.items()}
 return value

def credit(ledger):
 score=600
 for row in ledger['credit']['history']:
  cycle=row['cycle'];penalties={}
  for bill in ledger['obligations']:
   if bill['due_cycle']>cycle or not bill['late']:continue
   if bill['unpaid_cents']==0 and bill['settled_cycle']<=cycle-2:continue
   evaluated=cycle if bill['unpaid_cents']>0 else min(cycle,bill['settled_cycle'])
   age=max(0,evaluated-bill['due_cycle'])
   kind=bill['expense_type'];check(kind=='rent','only rent is sampled')
   points=[5,10,20][min(age//2,2)]
   penalties[kind]=max(penalties.get(kind,0),points)
  requested=-sum(penalties.values()) if penalties else 3 if row['operating_profit_cents']>0 else 0
  after=max(300,min(850,score+requested))
  check(row['before']==score and row['requested_change']==requested and row['after']==after and row['change']==after-score,'independent original-due credit evaluation')
  check(row['operating_profit_cents']==ledger['monthly_rows'][row['month']-1]['net_profit_cents'],'credit recorded actual operating profit')
  score=after
 check(ledger['credit']['score']==score,'closing credit score')

import gzip
foundation=read('foundation');archive=Path(foundation['basis_archive']);raw=gzip.decompress(archive.read_bytes())
check(e.sha(archive)==foundation['basis_archive_sha256'],'existing B6 archive hash')
import hashlib
check(hashlib.sha256(raw).hexdigest()==foundation['basis_output_sha256'],'existing B6 output hash')
historic=json.loads(raw);source=e.capture();rows=[];reference=read('high-none')
check(normalize(reference['first_release']['finance'])==normalize(historic['first_release']['finance']),'no-Cult first release complete finance parity with B6')
check(reference['releases'][0]['month_1_units']==historic['releases'][0]['month_1_units']==925,'no-Cult original sales projection parity')
for build,seed,price,chosen in BUILDS:
 name='high-'+build;d=read(name);traits=chosen.split(',') if chosen else []
 command=[GODOT,'--headless','--path',str(e.COPY),'--script','res://scripts/debug/candidate_high.gd','--','--out='+str(H/(name+'.json')),'--build='+build,'--traits='+chosen,'--budget=5,6,6','--foundation='+str(H/'foundation.json')]
 e.accept(name,source,command,(build,seed,price,chosen));check(d['valid'] and d['foundation_parity'] and not d['stop'] and not d['errors'] and not d['blockers'],'valid legal high route')
 check(d['seed']==4417 and d['policy']=='synergy' and d['candidate']==dict(seed=seed,point_cost=price),'declared route inputs')
 check([c['cycle'] for c in d['cycles']]==list(range(1,21)),'all calendar snapshots1through20')
 check(trace(d['actions'][:-1])==trace(foundation['known_trace']),'actual archived first-release play')
 check(trace(d['actions'])==trace(reference['actions']) and d['checkpoint']['rng']==reference['checkpoint']['rng'],'matched play and terminal RNG')
 first=d['releases'][0];check(first['final_review']==8.5 and first['cycle']==18,'native high rating')
 for key in ['cores','scope','marketing','genre_fit','variance_roll','variance_modifier','pre_genre_review','production_rating','bug_multiplier']:
  check(first[key]==historic['releases'][0][key],'unchanged pre-Awareness release inputs: '+key)
 spent=price+(1 if 'studio_buzz' in traits else 0)+(2 if 'lean_production' in traits else 0)+(2 if 'family_funding' in traits else 0)
 funding=550000+(4-spent)*5000+(30000 if 'family_funding' in traits else 0)
 check(d['traits']['spent_points']==spent and d['traits']['point_cash_cents']==(4-spent)*5000 and d['initial']['cash_cents']==funding,'actual point cash')
 check(d['positive_slots']==len(traits) and d['three_positives_reject'],'actual positive slots')
 check(d['initial']['fans']==seed and not d['initial']['sales'],'initial one-time seed')
 check(first['metadata']['review']['launch_fans']==seed,'seed frozen at launch')
 check(first['awareness']==100+first['marketing']+min(150,seed//4)+(3 if 'studio_buzz' in traits else 0),'one Fan term plus trait bonus')
 fan_and_finance(d,seed)
 for state in [d['initial']]+d['cycles']+[d['final']]:credit(state['finance'])
 f=d['finance'];bills=f['obligations'];check(not f['bank_loans'] and not f['employees'],'no Bank/payroll')
 check(all(b['expense_type']=='rent' and b['unpaid_cents']==0 for b in bills),'all original bills recovered')
 check(f['credit']['history'][:9]==d['first_release']['finance']['credit']['history'],'late history preserved after recovery')
 sales=list(d['sales'].values())[0];check(sales['earned_units']==sales['total_units'] and sales['entitlement_cents']==sales['settled_cents'],'real first month fully earned and settled')
 check(d['fanbase']['months'][-1]['gained']==max(0,sales['earned_units']-seed)*8*30//2000 and d['fanbase']['months'][-1]['lost']==0,'high-Review capped gain minus reserve')
 rowsum=lambda k:sum(r[k] for r in f['monthly_rows'])
 check(rowsum('interest_cents')==0 and rowsum('interest_paid_cents')==0 and rowsum('payroll_due_cents')==0 and rowsum('principal_paid_cents')==0,'no undeclared interest/payroll/principal')
 check(rowsum('store_cents')==0 and rowsum('campaign_cents')==0 and rowsum('rent_paid_cents')==500000,'declared spending and ten months rent')
 check(d['final']['cash_cents']==funding+rowsum('publisher_income_cents')+rowsum('beta_income_cents')+sales['settled_cents']-rowsum('rent_paid_cents')-rowsum('feature_play_cents'),'independent terminal cash composition')
 restart=name+'-restart';r=read(restart);args=[GODOT,'--headless','--path',str(e.COPY),'--script','res://scripts/debug/candidate_restart.gd','--','high-final',str(H/(restart+'.json'))]
 e.accept(restart,source,args,(build,seed,price,chosen))
 check(r['passed'] and r['exact_payload'] and r['duplicate_creation_rejected'] and r['wrong_seed_rejected'] and r['fanbase']==d['fanbase'] and r['cash_cents']==d['final']['cash_cents'],'strict high endpoint restore')
 rows.append(dict(build=build,seed=seed,spent_points=spent,positive_slots=len(traits),initial_cash=funding,review=first['final_review'],launch_awareness=first['awareness'],units=sales['earned_units'],earned_net=sales['entitlement_cents'],settled=sales['settled_cents'],final_cash=d['final']['cash_cents'],final_fans=d['final']['fans'],gained=d['final']['fans']-seed,feature_cost=rowsum('feature_play_cents'),rent_paid=rowsum('rent_paid_cents'),rent_arrears_at18=sum(b['unpaid_cents'] for b in d['first_release']['finance']['obligations']),credit_at18=d['first_release']['finance']['credit']['score'],final_credit=f['credit']['score'],late_bills=[b for b in bills if b['late']]))
for row in rows:row['cash_delta_vs_none']=row['final_cash']-rows[0]['final_cash']
result=dict(passed=True,checks=checks,native_routes=10,cold_endpoints=10,review=8.5,searches=0,archived_finance_parity=True,original_due_credit_reconciliation=True,rows=rows,source=source)
(H/'audit.json').write_text(json.dumps(result,indent=2),encoding='utf8');print(json.dumps({k:v for k,v in result.items() if k not in ['rows','source']},indent=2))
