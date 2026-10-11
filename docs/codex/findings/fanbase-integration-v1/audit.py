"""Independent integer reconciliation of the recorded integrated route."""
from pathlib import Path
import json, importlib.util
HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('finance',HERE.parent/'queue-completion-v1/finance_audit.py')
finance=importlib.util.module_from_spec(spec);spec.loader.exec_module(finance)
data=json.loads((HERE/'native-route.json').read_text(encoding='utf8'))
checks=0
def check(ok,label):
 global checks
 checks+=1
 if not ok:raise AssertionError(label)
check(data['valid'] and not data['errors'] and not data['blockers'],'native route valid')
check(data['initial']['cash_cents']==570000 and data['initial']['fans']==0,'genuine no-trait initial state')
check([s['cycle'] for s in data['cycles']]==list(range(1,29)),'one captured state for every productive cycle')
check(len(data['releases'])==3 and data['releases'][0]['final_review']>5 and data['releases'][1]['final_review']<5,'strong weak later sequence')
prior_entries={};prior_fans=0;weak=[]
weak_id=data['releases'][1]['release_id']
for state in data['cycles']:
 finance.ledger(state['finance'])
 check(state['cash_cents']==state['finance']['cash_cents'],'cash agrees with independent journal')
 fan=state['fanbase'];cycle=state['cycle']
 check(fan['last_cycle']==cycle and state['fans']==fan['fans'],'cycle and total Fan identity')
 records=state['sales']
 if isinstance(records,list):records={r['release_id']:r for r in records}
 if cycle%2:
  check(fan['fans']==prior_fans,'odd half publishes no Fan delta')
  continue
 row=fan['months'][-1];gains=losses=0;details=[]
 check(row['starting']==prior_fans,'shared pre-boundary Fan snapshot')
 for rid in sorted(fan['releases']):
  entry=fan['releases'][rid];old=prior_entries.get(rid,dict(gained=0,lost=0,accounted_units=0,loss_exposure_accounted=0))
  record=data['sales'][rid]|records[rid];neutral=entry['neutral'];units=record['earned_units']
  check(neutral['review_tenths']==50 and neutral['launch_awareness']==record['launch_awareness'],'neutral shadow launch inputs')
  n=500*50*(200+record['launch_awareness'])*record['market_bp']//(70*200*10000)
  check(n==neutral['total_units'],'independent neutral Month1 formula')
  age=cycle-data['metadata'][rid]['release_cycle'];reach=n if age>=2 else n//2 if age==1 else 0
  organic=record['launch_awareness']*5000+300000
  for age_month in range(2,(age+1)//2+1):
   if age_month>2:organic=organic*5250//10000
   monthly=500*50*organic*record['market_bp']//(70*200*10000*10000)
   reach+=monthly//2 if age==2*age_month-1 else monthly
  check(reach==neutral['earned_units'],'independent cumulative neutral exposure')
  gain_target=max(0,units-entry['launch_fans'])*8*min(30,max(0,entry['review_tenths']-50))//2000
  loss_target=min(entry['launch_fans'],reach)*15*max(0,50-entry['review_tenths'])//1000
  gain=gain_target-old['gained'];loss=min(row['starting']-losses,loss_target-old['loss_exposure_accounted'])
  earned=units-old['accounted_units']
  check(entry['gained']==gain_target and entry['loss_exposure_accounted']==loss_target,'cumulative integer targets')
  check(entry['lost']==old['lost']+loss and entry['accounted_units']==units,'incremental loss and units processed once')
  if earned or gain or loss:details.append(dict(release_id=rid,earned_units=earned,new_fans=gain,lost_fans=loss))
  gains+=gain;losses+=loss
  if rid==weak_id:weak.append(dict(cycle=cycle,starting=row['starting'],title_loss=loss,other_title_gains=row['gained']-gain,ending=row['ending']))
 check(row['releases']==details,'stable textual per-title order and details')
 check(row['gained']==gains and row['lost']==losses and losses<=row['starting'] and row['ending']==row['starting']+gains-losses,'shared cap and total conservation')
 prior_entries=fan['releases'];prior_fans=fan['fans']
for release in data['releases']:
 launch=next(a for a in data['actions'] if a.get('phase')=='launch' and a.get('game')==data['releases'].index(release)+1)
 review=release['metadata']['review'];record=data['sales'][release['release_id']]
 check(review['launch_fans']==launch['before']['fans'],'Fans frozen at launch')
 check(review['fan_awareness']==min(150,review['launch_fans']//4),'quarter mapping')
 check(record['total_units']==500*record['review_tenths']*(200+record['launch_awareness'])*record['market_bp']//(70*200*10000),'single Awareness sales conversion')
 check(record['entitlement_cents']==record['earned_units']*999*70//100,'exact net entitlement')
check(len(weak)>=2 and weak[0]['title_loss']==5 and weak[1]['title_loss']==0,'observed weak exposure lost once')
finance.ledger(data['finance'])
summary=dict(passed=True,checks=checks+finance.checks,fan_checks=checks,finance_checks=finance.checks,reviews=[r['final_review'] for r in data['releases']],weak_boundaries=weak,final_cash_cents=data['final']['cash_cents'],final_fans=data['final']['fans'],final_cycle=data['final']['cycle'])
(HERE/'audit.json').write_text(json.dumps(summary,indent=2),encoding='utf8')
print(json.dumps(summary,indent=2))
