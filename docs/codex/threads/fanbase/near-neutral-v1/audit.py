from pathlib import Path
import gzip,json,hashlib,subprocess,shutil
HERE=Path(__file__).resolve().parent;OLD=HERE.parent/'quarter-trial-v1';checks=0
def check(ok,label):
 global checks
 checks+=1
 if not ok:raise AssertionError(label)
def load(p):return json.loads(gzip.decompress(p.read_bytes()))
old=load(OLD/'restrained.json.gz');results=[]
def signature(a):return {k:a.get(k) for k in ['phase','game','selected','draw','redraws','success','cost_cents','printed_core','printed_scope']}
def normalized(value,d):
 s=json.dumps(value,sort_keys=True)
 for i,r in enumerate(d['releases']):s=s.replace(r['release_id'],'release_'+str(i+1))
 return json.loads(s)
for name in ['primary','alternate']:
 d=load(HERE/(name+'.json.gz'));check(d['valid'] and not d['errors'] and not d['discrepancies'],'native validity')
 aa=[signature(a) for a in d['actions'] if a.get('game',0)<3];bb=[signature(a) for a in old['actions'] if a.get('game',0)<3];check(aa==bb,'verified prefix action identity')
 for a,b in zip(d['live_cycles'][:32],old['live_cycles'][:32]):
  check(a['cash_cents']==b['cash_cents'] and a['fans']==b['fans'] and normalized(a['fan_snapshot'],d)==normalized(b['fan_snapshot'],old),'prefix cash/fans exact after release identity normalization')
 prior={};boundaries=[];weak=d['releases'][2];wid=weak['release_id']
 for state in d['live_cycles']:
  if state['cycle']%2:continue
  fan=state['fan_snapshot'];month=fan['months'][-1];gains=losses=0
  records={r['release_id']:r for r in state['records']}
  for id in sorted(fan['releases']):
   e=fan['releases'][id];before=prior.get(id,{'gained':0,'loss_exposure_accounted':0,'lost':0,'accounted_units':0,'neutral':{'earned_units':0}})
   units=records[id]['earned_units'];exposure=min(e['launch_fans'],e['neutral']['earned_units']);target=exposure*15*max(0,50-e['review_tenths'])//1000
   gain_target=max(0,units-e['launch_fans'])*8*min(30,max(0,e['review_tenths']-50))//2000
   gain=gain_target-before['gained'];loss=min(month['starting']-losses,target-before['loss_exposure_accounted'])
   check(e['gained']==gain_target and e['loss_exposure_accounted']==target,'cumulative integer targets');check(e['lost']==before['lost']+loss,'incremental loss/shared cap');gains+=gain;losses+=loss
   if id==wid:
    boundaries.append(dict(cycle=state['cycle'],month=month['month'],starting=month['starting'],earned_units=units-before['accounted_units'],cumulative_units=units,neutral_cumulative_units=e['neutral']['earned_units'],incremental_neutral_units=e['neutral']['earned_units']-before['neutral']['earned_units'],exposure=exposure,new_exposure=exposure-min(e['launch_fans'],before['neutral']['earned_units']),loss_target=target,title_loss=loss,title_gain=gain,all_gains=month['gained'],all_losses=month['lost'],net=month['net'],ending=month['ending'],cash=state['cash_cents'],title_earned_cents=records[id]['entitlement_cents'],title_settled_cents=records[id]['settled_cents']))
  check(month['gained']==gains and month['lost']==losses and month['ending']==month['starting']+gains-losses and losses<=month['starting'],'shared monthly reconciliation');prior=fan['releases']
 for r in d['final']['finance']['monthly_rows']:
  costs=sum(r[k] for k in ['feature_play_cents','store_cents','campaign_cents','playtest_cents','other_expense_cents','interest_cents']);check(r['closing_cash_cents']==r['opening_cash_cents']+r['financing_in_cents']+r['other_income_cents']+r['sales_settled_cents']-costs-r['rent_paid_cents']-r['principal_paid_cents'],'cash');check(r['net_profit_cents']==r['sales_net_earned_cents']+r['other_income_cents']-costs-r['rent_due_cents'],'accrual')
 check(sum(r['entitlement_cents'] for r in d['sales_records'])==sum(r['sales_net_earned_cents'] for r in d['final']['finance']['monthly_rows']),'earned sales');check(sum(r['settled_cents'] for r in d['sales_records'])==sum(r['sales_settled_cents'] for r in d['final']['finance']['monthly_rows']),'settled sales')
 results.append(dict(attempt=name,prefix_actions=len(aa),target_hit=4<=weak['final_review']<5,launches=[{k:r[k] for k in ['cycle','final_review','awareness','month_1_units','cash_cents']}|{'fans':d['final']['fan_snapshot']['releases'][r['release_id']]['launch_fans']} for r in d['releases']],boundaries=boundaries,stop=d['stop'],blockers=d['blockers'],final_cash=d['final']['cash_cents'],final_fans=d['final']['fans'],native_ledger_checks=d['ledger_checks'],native_row_checks=d['row_checks']))
m=json.loads((HERE/'source.json').read_text());project=Path(m['project']);oldm=json.loads((OLD/'source.json').read_text());work=Path(r'C:/Users/64jus/.codex/worktrees/fanbase-quarter/PatchNotes')
for k,h in m['files'].items():
 check(hashlib.sha256((project/k).read_bytes()).hexdigest()==h,'captured source unchanged '+k)
 if not k.startswith('analysis'):
  check(h==oldm['files'][k],'runtime matches prior quarter capture '+k)
  check(hashlib.sha256((work/'patch-notes'/k).read_bytes()).hexdigest()==h,'branch runtime preserved '+k)
git=['git','-c','safe.directory='+str(work),'-C',str(work)]
(HERE/'branch.patch').write_bytes(subprocess.check_output(git+['diff']))
(HERE/'branch-status.txt').write_bytes(subprocess.check_output(git+['status','--short']))
for name in ['task29_routes_v1.gd','task32_routes_v1.gd','fanbase_quarter_capture.gd']:shutil.copy2(project/'analysis'/name,HERE/name)
(HERE/'audit.json').write_text(json.dumps(dict(checks=checks,results=results),indent=2));print('PASS',checks,'independent checks');print(json.dumps(results,indent=2))
