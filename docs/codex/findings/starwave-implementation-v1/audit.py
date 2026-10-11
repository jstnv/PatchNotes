"""Independent integer audit of native cards, receipts, monthly cash and Fans."""
from pathlib import Path
from collections import Counter
import argparse,json,hashlib,importlib.util
HERE=Path(__file__).resolve().parent
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--source-root',type=Path,help='Root of the complete 1190-file native-v3 copy; defaults to the recorded durable copy')
parser.add_argument('--output',type=Path,default=HERE/'audit-recheck-v3.json',help='Distinct recheck result; original audit summary cannot be overwritten')
args=parser.parse_args()
recovery_path=HERE/'source-pin-recovery-v3.json'
recovery=json.loads(recovery_path.read_text(encoding='utf-8'))
ROOT=args.source_root.resolve() if args.source_root else Path(recovery['destination'])
original_summary=HERE/'audit-summary-v3.json'
original_summary_bytes=original_summary.read_bytes()
if args.output.resolve() in {original_summary.resolve(),(HERE/'source-manifest-v3.json').resolve()}:
 raise ValueError('Rechecks must preserve the original manifest and audit summary')
assert hashlib.sha256(original_summary_bytes).hexdigest()==recovery['original_audit_summary_sha256']
NATIVE=HERE/'native-v3'
spec=importlib.util.spec_from_file_location('finance',HERE/'finance-audit-v3.py')
finance=importlib.util.module_from_spec(spec);spec.loader.exec_module(finance)
checks=0
def check(ok,label):
 global checks
 checks+=1
 if not ok:raise AssertionError(label)
def load(path):return json.loads(path.read_text(encoding='utf-8'))
manifest=load(HERE/'source-manifest-v3.json')
assert hashlib.sha256((HERE/'source-manifest-v3.json').read_bytes()).hexdigest()==recovery['source_manifest_sha256']
for path,digest in manifest['files'].items():check(hashlib.sha256((ROOT/path).read_bytes()).hexdigest()==digest,'source unchanged: '+path)
d=load(NATIVE/'native-route.json')
check(d['valid'] and not d['stop'] and not d['errors'] and not d['blockers'],'complete native route')
check(d['initial']['cash_cents']==565000 and d['initial']['fans']==0,'genuine Lean/Buzz/Lease trait initial funds')
check([s['cycle'] for s in d['cycles']]==list(range(1,d['final']['cycle']+1)),'every native productive boundary recorded once')
defs={c['id']:c for c in load(ROOT/'patch-notes/data/card_ledger.json')}
core_names=['graphics','sound','technology','design']
contracts=[a for a in d['actions'] if a.get('phase')=='contract']
check(len(contracts)==4 and [len(a['hands']) for a in contracts]==[2,2,2,3],'three distinct prerequisites then native three-hand offer')
for contract in contracts:
 scope=0;cores=[0]*4;exhausted=set();retained=None
 for index,hand in enumerate(contract['hands']):
  check(len(hand['draw'])==7 and len(hand['selected'])==4,'seven/four hand size')
  remainder=list(hand['draw'])
  for cid in hand['selected']:remainder.remove(cid)
  check(len(remainder)==3,'three unselected candidates')
  if retained is not None:check(hand['draw'][:3]==retained,'unselected candidates retained in order')
  selected=[defs[cid] for cid in hand['selected']]
  multiplier=3 if len({c['primary_stat'] for c in selected})==1 else 2
  for card in selected:
   if not card['renewable']:
    check(card['id'] in contract['pool'] and card['id'] not in exhausted,'eligible owned finite Feature used once')
    exhausted.add(card['id'])
   scope+=card['scope'];cores[core_names.index(card['primary_stat'])]+=multiplier*card['primary_value']
   if card['secondary_stat']:cores[core_names.index(card['secondary_stat'])]+=multiplier*card['secondary_value']
  check(hand['after']['cycle']==hand['before']['cycle']+1,'one productive cycle per hand')
  retained=remainder
 check(scope==contract['result']['scope'] and cores==[contract['result']['cores'][str(i)] for i in range(4)],'independent Scope and half-unit scores')
star=contracts[-1];sid=star['offer_id']
n=4*min(star['result']['scope'],14)+sum(min(star['result']['cores'][str(i)],14) for i in range(4))
check(n==star['result']['numerator'] and star['result']['cash']==224000*n//112 and star['result']['promotion']==0,'approved exact Starwave formula')
check(star['before']['cash_cents']==star['accepted']['cash_cents'] and star['before']['cycle']==star['accepted']['cycle'],'zero advance and acceptance cycles')
payments=[a for a in d['finance']['actions'] if a['source_id']==sid]
check(len(payments)==3 and [a['direct_delta'] for a in payments]==[0,0,224000*n//112],'zero first/two receipts then final exact cash once')
check([a['kind'] for a in payments]==['contract_hand','contract_hand','publisher_receipt'],'hand/payment journal identity')
check(d['pending_promotion'] and sum(d['pending_promotion'].values())==18 and d['next_launch_promotion']==18,'Neon award survives Starwave and consumes on next release')
check(d['late_loan_accepted'] and d['hired'],'real eligible loan and actual hire')
loan=d['finance']['bank_loans'][0]
check(loan['closed'] and loan['principal_paid_cents']==50000 and loan['interest_paid_cents']==3250,'all twelve actual installments reconcile')
check(loan['schedule']['accepted_cycle']==54 and loan['schedule']['first_due_cycle']==56,'first installment overlaps second Starwave hand')
for state in d['cycles']:
 finance.ledger(state['finance'])
 check(state['cash_cents']==state['finance']['cash_cents'],'cycle cash agrees with journal')
finance.ledger(d['finance'])
# Fan provenance: same shared-boundary cap and independent integer cumulative
# gain/exposure targets. No campaign was selected by this declared route.
prior_entries={};prior_fans=0
for state in d['cycles']:
 fan=state['fanbase'];cycle=state['cycle']
 check(fan['last_cycle']==cycle and state['fans']==fan['fans'],'Fan cycle identity')
 if cycle%2:
  check(fan['fans']==prior_fans,'odd half grants no monthly delta');continue
 row=fan['months'][-1];gains=losses=0;details=[]
 check(row['starting']==prior_fans,'shared prior Fan snapshot')
 records={r['release_id']:r for r in state['sales']} if isinstance(state['sales'],list) else state['sales']
 for rid in sorted(fan['releases']):
  entry=fan['releases'][rid];old=prior_entries.get(rid,dict(gained=0,lost=0,accounted_units=0,loss_exposure_accounted=0))
  record=d['sales'][rid]|records[rid]
  check(not record['campaign_months'],'declared no-campaign policy')
  first=500*50*(200+record['launch_awareness'])*record['market_bp']//(70*200*10000)
  age=cycle-d['metadata'][rid]['release_cycle']
  reach=first if age>=2 else first//2 if age==1 else 0
  organic=record['launch_awareness']*5000+300000
  for month in range(2,(age+1)//2+1):
   if month>2:organic=organic*5250//10000
   units=500*50*organic*record['market_bp']//(70*200*10000*10000)
   reach+=units//2 if age==2*month-1 else units
  check(first==entry['neutral']['total_units'] and reach==entry['neutral']['earned_units'],'independent neutral reach')
  actual=record['earned_units'];gain_target=max(0,actual-entry['launch_fans'])*8*min(30,max(0,entry['review_tenths']-50))//2000
  loss_target=min(entry['launch_fans'],reach)*15*max(0,50-entry['review_tenths'])//1000
  gain=gain_target-old['gained'];loss=min(row['starting']-losses,loss_target-old['loss_exposure_accounted'])
  check(entry['gained']==gain_target and entry['loss_exposure_accounted']==loss_target,'cumulative integer targets')
  check(entry['lost']==old['lost']+loss and entry['accounted_units']==actual,'incremental exposure once')
  earned=actual-old['accounted_units']
  if earned or gain or loss:details.append(dict(release_id=rid,earned_units=earned,new_fans=gain,lost_fans=loss))
  gains+=gain;losses+=loss
 check(row['releases']==details and row['gained']==gains and row['lost']==losses and row['ending']==row['starting']+gains-losses,'monthly Fan conservation and textual identity order')
 prior_entries=fan['releases'];prior_fans=fan['fans']
for release in d['releases']:
 record=d['sales'][release['release_id']];review=d['metadata'][release['release_id']]['review']
 check(review['fan_awareness']==min(150,review['launch_fans']//4),'frozen quarter Fan Awareness')
 check(record['total_units']==500*record['review_tenths']*(200+record['launch_awareness'])*record['market_bp']//(70*200*10000),'single total Awareness sales conversion')
 check(record['entitlement_cents']==record['earned_units']*999*70//100,'exact earned net entitlement')
restarts=load(HERE/'native-v3-restart-results.json')
check(len(restarts)==10 and not any(restarts.values()),'ten successful fresh-process stages')
for path in sorted(NATIVE.glob('restart-*.json')):
 trace=load(path);finance.ledger(trace['finance'])
 if trace['mode'].startswith('rollback'):
  check(trace['before']['cycle']==54 and trace['after']['cycle']==54+len(trace['hands']),'restored uncommitted hand count')
for name in ['before-starwave.payload.json','before-starwave.checkpoint.1.json']:
 check((NATIVE/name).exists(),'preserved genuine export seed '+name)
summary={'passed':True,'independent_checks':checks+finance.checks,'logic_checks':checks,'finance_checks':finance.checks,'source_files':len(manifest['files']),'reviews':[r['final_review'] for r in d['releases']],'before_starwave_cycle':d['before_starwave']['cycle'],'starwave_numerator':n,'payout_cents':star['result']['cash'],'existing_promotion':18,'final_cycle':d['final']['cycle'],'loan_principal_paid_cents':loan['principal_paid_cents'],'loan_interest_paid_cents':loan['interest_paid_cents'],'restart_processes':10,'checkpoint_sha256':{name:hashlib.sha256((NATIVE/name).read_bytes()).hexdigest() for name in ['before-starwave.payload.json','before-starwave.checkpoint.1.json']}}
summary.update({'source_copy':str(ROOT),'source_manifest_sha256':recovery['source_manifest_sha256'],'original_audit_summary_sha256':recovery['original_audit_summary_sha256'],'source_recovery_record_sha256':hashlib.sha256(recovery_path.read_bytes()).hexdigest(),'finance_auditor_sha256':hashlib.sha256((HERE/'finance-audit-v3.py').read_bytes()).hexdigest(),'reproduction_auditor_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'provenance_recheck':True})
assert original_summary.read_bytes()==original_summary_bytes
args.output.write_text(json.dumps(summary,indent=2),encoding='utf-8')
print(json.dumps(summary,indent=2))
