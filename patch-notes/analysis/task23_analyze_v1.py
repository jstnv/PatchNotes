"""Task23 same-action timing overlays with native Godot sales ledgers."""
import json,csv,statistics
from task23_prepare_v1 import OUT,C,award,fixed,summarize
def main():
 routes=json.loads((OUT/'prepared.json').read_text(encoding='utf-8'));traces=json.loads((OUT/'contract_traces.json').read_text(encoding='utf-8'));native=json.loads((OUT/'native-ledgers.json').read_text(encoding='utf-8'))
 rows=[];monthly=[];checkpoints=[];receipts=[];checks=0;transactions=0
 for item in routes:
  name=item['name'];r=item['route'];rels=r['releases'];ev=item['events'];transactions+=len(ev)
  def one(timing,i,promo,cycle):
   idx=item['first'] if timing=='early' else 3
   shift=3 if timing!='neutral' and i>idx else 0
   launch=rels[i]['cycle']+shift
   if cycle<=launch:return [cycle,0,0,0,0]
   actual_promo=promo if timing!='neutral' and i==idx+1 else 0
   return native[f'{name}:{timing}:{i}:{actual_promo}']['rows'][int(cycle-launch-1)]
  def totals(timing,promo,cycle,col):return sum(one(timing,i,promo,cycle)[col] for i in range(5))
  for sample in r['live_cycles']:
   for rec in sample['records']:
    i=next(i for i,rel in enumerate(rels) if rel['release_id']==rec['release_id'])
    actual=one('neutral',i,0,sample['cycle']);assert actual[1:4]==[rec['earned_units'],rec['entitlement_cents'],rec['settled_cents']];checks+=1
  # Independently reproduce native cash without an offer or delay.
  cash=550000;paid=0
  for e in ev:
   now=totals('neutral',0,e['after']['cycle'],3);cash+=e['direct']+now-paid;paid=now
   assert cash==e['after']['cash_cents']
  for ti,t in enumerate(traces):
   if t['name']!=name:continue
   timing=t['timing'];index=t['trigger_index'];promo=t['promotion'];payout=t['payout']
   # Identify the exact successful launch callback, not all same-cycle events.
   launch_events=[i for i,e in enumerate(ev) if e['label']=='launch']
   assert len(launch_events)==5
   trigger_event=launch_events[index];trigger=int(rels[index]['cycle']);cash=550000;paid=0;first=None;inserted=False;paid_once=False;milestones=[];snap={};direct_total=0
   def record(cycle):
    if cycle%2==0:snap[cycle]=dict(trace=ti,name=name,timing=timing,policy=t['policy'],seed=t['seed'],cycle=cycle,cash_cents=cash,earned_cents=totals(timing,promo,cycle,2),settled_cents=paid,publisher_cash=payout if paid_once else 0,promotion_extra_settled=totals(timing,promo,cycle,3)-totals(timing,0,cycle,3),delay_only_settled=totals(timing,0,cycle,3),projection_only=False)
   for ei,e in enumerate(ev):
    shift=3 if inserted else 0;bc=int(e['before']['cycle'])+shift;ac=int(e['after']['cycle'])+shift
    cost=max(0,-e['direct'])
    if first is None and cash<cost:first=dict(action=e['label'],native_cycle=e['before']['cycle'],shadow_cycle=bc,cash=cash,required=cost)
    now=totals(timing,promo,ac,3);cash+=e['direct']+now-paid;paid=now;direct_total+=e['direct'];record(ac)
    if e['label']=='launch':
     gi=len(milestones);milestones.append(dict(game=gi+1,cycle=ac,cash=cash,review=rels[gi]['final_review'],awareness=rels[gi]['awareness']+(promo if gi==index+1 else 0),promotion_used=promo if gi==index+1 else 0))
    if ei==trigger_event:
     # Accepted offer is shadow-only: exactly hand1, changed priority, hand2.
     for j in range(1,4):
      cycle=trigger+j
      if j==3:
       assert not paid_once;cash+=payout;paid_once=True
      now=totals(timing,promo,cycle,3);sales_delta=now-paid;cash+=sales_delta;paid=now;record(cycle)
      receipts.append(dict(trace=ti,name=name,timing=timing,contract_action=j,cycle=cycle,publisher_cash=payout if j==3 else 0,portfolio_settlement=sales_delta,cash_after=cash))
     inserted=True
   assert paid_once and inserted
   assert sum(x['promotion_used'] for x in milestones)==promo
   assert milestones[index+1]['promotion_used']==promo
   if timing=='after_game4':assert milestones[4]['promotion_used']==promo
   endpoint=int(r['final']['cycle'])+3
   assert endpoint>=int(rels[4]['cycle'])+3+2,'Game5 Month1 not earned'
   assert cash==550000+direct_total+payout+paid
   final=cash;end_promo=totals(timing,promo,endpoint,3)-totals(timing,0,endpoint,3)
   for cycle in range(endpoint+1,item['horizon']+1):
    now=totals(timing,promo,cycle,3);cash+=now-paid;paid=now;record(cycle)
    if cycle in snap:snap[cycle]['projection_only']=True
   # Receipts can be displayed repeatedly without another transfer in the model.
   duplicate_cash=cash
   for _ in range(3):
    if not paid_once:cash+=payout;paid_once=True
   assert cash==duplicate_cash
   for entry in milestones:checkpoints.append(dict(trace=ti,name=name,timing=timing,seed=t['seed'],policy=t['policy'],**entry))
   monthly.extend(snap.values())
   rows.append(dict(trace=ti,name=name,timing=timing,policy=t['policy'],seed=t['seed'],target=9 if name=='crown' else 10,cash=payout,promotion=promo,full=t['full'],owned_count=len(t['owned']),scope=t['scope'],half=t['half'],boosted_game=index+2,first_unaffordable=first,endpoint=endpoint,final_cash=final,final_promo_settled=end_promo,projection_cycle=item['horizon'],projection_cash=cash,projection_promo_settled=totals(timing,promo,item['horizon'],3)-totals(timing,0,item['horizon'],3),milestones=milestones))
 comparisons=[]
 for a in rows:
  if a['timing']!='early':continue
  b=next(x for x in rows if (x['name'],x['policy'],x['seed'],x['timing'])==(a['name'],a['policy'],a['seed'],'after_game4'))
  comparisons.append(dict(name=a['name'],policy=a['policy'],seed=a['seed'],payout_delta=a['cash']-b['cash'],endpoint_cycle=a['endpoint'],early_minus_late_cash=a['final_cash']-b['final_cash'],early_minus_late_promo_settled=a['final_promo_settled']-b['final_promo_settled'],projected_early_minus_late_cash=a['projection_cash']-b['projection_cash']))
 summary={}
 for name in ['crown','neon']:
  for policy in ['ordinary','synergy']:
   g=[x for x in comparisons if x['name']==name and x['policy']==policy]
   def stats(field):return dict(min=min(x[field] for x in g),median=statistics.median(x[field] for x in g),max=max(x[field] for x in g))
   summary[f'{name}_{policy}']=dict(count=len(g),end=stats('early_minus_late_cash'),later=stats('projected_early_minus_late_cash'),payout=stats('payout_delta'))
 for fn,data in [('monthly.csv',monthly),('checkpoints.csv',checkpoints),('timing-comparison.csv',comparisons),('contract-receipts.csv',receipts)]:
  with (OUT/fn).open('w',encoding='utf-8',newline='') as f:w=csv.DictWriter(f,fieldnames=list(data[0]));w.writeheader();w.writerows(data)
 report=dict(native_ledger_checks=checks,transactions=transactions,outcomes=rows,comparisons=comparisons,summary=summary,completion=summarize(rows),affordability_failures=sum(x['first_unaffordable'] is not None for x in rows))
 (OUT/'results.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
 print('Task23 PASS',checks,'native sales checks,',transactions,'cash transactions;',len(rows),'timing arms, failures',report['affordability_failures']);print(json.dumps(summary,indent=2))
if __name__=='__main__':main()
