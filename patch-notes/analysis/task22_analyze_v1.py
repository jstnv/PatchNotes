"""Exact paired trait cash tables. Hypothetical traits never enter RunState."""
import json,csv,statistics
from task22_prepare_v1 import OUT,paid
class Loan:
 def __init__(self):self.dues=set();self.arrears=0;self.paid=0
 def apply(self,cash,cycle,committed=True):
  if not committed:return cash
  if cycle>0 and cycle%2==0 and cycle//2<=96 and cycle not in self.dues:
   self.dues.add(cycle);self.arrears+=1000
  payment=min(cash,self.arrears);self.arrears-=payment;self.paid+=payment
  assert cash>=payment>=0 and self.arrears>=0
  return cash-payment
def loan_tests():
 l=Loan();c=l.apply(300,2);assert c==0 and l.arrears==700
 assert l.apply(c,2)==0 and len(l.dues)==1
 assert l.apply(500,4,False)==500 and len(l.dues)==1
 c=l.apply(1200,3);assert c==500 and l.arrears==0 and l.paid==1000
 for cycle in range(4,193,2):c=l.apply(c+1000,cycle)
 assert len(l.dues)==96 and l.paid==96000 and l.arrears==0
 assert l.apply(c,194)==c and len(l.dues)==96
 return dict(passed=True,dues=len(l.dues),paid=l.paid,arrears=l.arrears,synthetic=True,description='300 available/1000 due; 700 arrears collected from later 1200 inflow; failed/duplicate boundary no extra due; no 97th due')
def main():
 doc=json.loads((OUT/'prepared.json').read_text(encoding='utf-8'));native=json.loads((OUT/'native-ledgers.json').read_text(encoding='utf-8'))
 tables=[];results=[];checks=0;attributions=[]
 for item in doc['routes']:
  r=item['route'];rid=item['id'];rels=r['releases']
  def ledger(i,aw,cycle):
   rel=rels[i]
   if cycle<=rel['cycle']:return [cycle,0,0,0,0]
   return native[f"{rid}:{rel['release_id']}:{aw}"]['rows'][int(cycle-rel['cycle']-1)]
  for sample in r['live_cycles']:
   for rec in sample['records']:
    i=next(i for i,rel in enumerate(rels) if rel['release_id']==rec['release_id'])
    row=ledger(i,rels[i]['awareness'],sample['cycle'])
    assert row[1:4]==[rec['earned_units'],rec['entitlement_cents'],rec['settled_cents']],(rid,sample['cycle'],row,rec)
    checks+=1
  neutral_by_cycle={0:550000}
  for e in item['events']:neutral_by_cycle[int(e['after']['cycle'])]=int(e['after']['cash_cents'])
  for s in doc['scenarios']:
   aws=s['awareness_by_route'][rid]
   def total(cycle,col):return sum(ledger(i,aw,cycle)[col] for i,aw in enumerate(aws))
   cash=550000+s['cash'];loan=Loan();first=None;boundaries={};previous_paid=0;launch_cash=[]
   for e in item['events']:
    b=e['before'];a=e['after'];cost=max(0,-e['direct'])
    if cash<cost and first is None:first=dict(cycle=b['cycle'],action=e['label'],cash=cash,required=cost)
    # After failure, later balances are diagnostic fixed-action arithmetic only.
    cash+=e['direct']+total(a['cycle'],3)-previous_paid;previous_paid=total(a['cycle'],3)
    if s.get('loan') and cash>=0:cash=loan.apply(cash,int(a['cycle']))
    if a['cycle']%2==0:boundaries[int(a['cycle'])]=cash
    if e['label']=='launch':launch_cash.append(dict(cycle=a['cycle'],cash_cents=cash,earned_cents=total(a['cycle'],2),settled_cents=total(a['cycle'],3)))
    if s['id']=='neutral_native':assert cash==a['cash_cents']
   endpoint=cash
   for cycle in range(int(r['final']['cycle'])+1,item['horizon']+1):
    cash+=total(cycle,3)-previous_paid;previous_paid=total(cycle,3)
    if s.get('loan'):cash=loan.apply(cash,cycle)
    if cycle%2==0:boundaries[cycle]=cash
   for cycle,c in sorted(boundaries.items()):
    earned=total(cycle,2);settled=total(cycle,3)
    tables.append(dict(route=rid,scenario=s['id'],cycle=cycle,label='observed-action shadow' if cycle<=r['final']['cycle'] else 'conditional frozen-portfolio projection',cash_cents=c,earned_cents=earned,settled_cents=settled,unpaid_cents=earned-settled,units=total(cycle,1)))
   projected=[native[f"{rid}:{rel['release_id']}:{aw}"]['month1_units'] for rel,aw in zip(rels,aws)]
   results.append(dict(route=rid,policy=r['policy'],scenario=s['id'],reviews=[x['final_review'] for x in rels],awareness=aws,month1_units=projected,launch_cash=launch_cash,post_game2_cents=endpoint,launch_game2_cycle=rels[1]['cycle'],endpoint_cycle=r['final']['cycle'],horizon=item['horizon'],month24_after_game2_cash=cash,first_unaffordable=first,loan_paid=loan.paid,arrears=loan.arrears))
   for i,rel in enumerate(rels):
    delta=ledger(i,aws[i],item['horizon'])[3]-ledger(i,rel['awareness'],item['horizon'])[3]
    attributions.append(dict(route=rid,scenario=s['id'],game=i+1,review=rel['final_review'],matching=rel['genre']==r['specialty'],incremental_settled_cents=delta))
 summaries=[]
 for s in doc['scenarios']:
  rows=[x for x in results if x['scenario']==s['id']]
  deltas=[];late=[]
  for row in rows:
   base=next(x for x in results if x['route']==row['route'] and x['scenario']=='cash_only_4')
   deltas.append(row['post_game2_cents']-base['post_game2_cents']);late.append(row['month24_after_game2_cash']-base['month24_after_game2_cash'])
  summaries.append(dict(scenario=s['id'],post_game2_delta_median=statistics.median(deltas),post_game2_delta_min=min(deltas),post_game2_delta_max=max(deltas),month24_delta_median=statistics.median(late),month24_delta_min=min(late),month24_delta_max=max(late),failures=sum(x['first_unaffordable'] is not None for x in rows)))
 for name,rows in [('monthly.csv',tables),('attribution.csv',attributions)]:
  with (OUT/name).open('w',encoding='utf-8',newline='') as f:w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
 output=dict(neutral_ledger_checks=checks,transactions=sum(len(r['events']) for r in doc['routes']),loan=loan_tests(),publisher_cap_examples=[dict(base=240000,external_15pct=36000,within_cap=0),dict(base=200000,external_15pct=30000,within_cap=30000)],summaries=summaries,results=results)
 (OUT/'results.json').write_text(json.dumps(output,indent=2),encoding='utf-8')
 print('PASS',checks,'native parity checks;',len(results),'paired shadows;',len(tables),'monthly rows')
 print(json.dumps(summaries[:15],indent=2))
if __name__=='__main__':main()
