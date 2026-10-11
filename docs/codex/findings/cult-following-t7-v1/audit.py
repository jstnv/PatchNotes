"""Independent integer Fan, finance, opportunity-cost and evidence reconciliation."""
from pathlib import Path
import json,importlib.util,sys
import provenance
HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('finance',HERE.parent/'queue-completion-v1/finance_audit.py')
finance=importlib.util.module_from_spec(spec);spec.loader.exec_module(finance)
checks=0
def check(ok,label):
 global checks
 checks+=1
 if not ok:raise AssertionError(label)
def read(name):return json.loads((HERE/(name+'.json')).read_text(encoding='utf8'))
def trace(data):
 result=[]
 for action in data['actions']:
  result.append({k:v for k,v in action.items() if k in ['phase','game','offer_id','draw','final_draw','selected','redraws','printed_core','printed_scope','synergy','success','budget_curtailed']})
  if 'hands' in action:result[-1]['hands']=[{k:h[k] for k in ['draw','selected']} for h in action['hands']]
 return result
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
 f=data['finance'];credit=600
 check(not f['bank_loans'] and not f['employees'],'no undeclared Bank/payroll')
 for bill in f['obligations']:
  check(bill['expense_type']=='rent' and bill['paid_on_time'] and not bill['late'] and bill['unpaid_cents']==0,'rent paid on time')
 for row in f['credit']['history']:
  change=3 if row['operating_profit_cents']>0 else 0
  check(row['before']==credit and row['change']==change,'credit clean profit delta')
  credit=min(850,credit+change);check(row['after']==credit,'credit history balance')
 check(f['credit']['score']==credit,'credit closing score')
 for state in data['cycles']:
  if state['cycle']%2==0:
   c=state['finance']['credit']['history'][-1];r=state['finance']['monthly_rows'][c['month']-1]
   check(c['operating_profit_cents']==r['net_profit_cents'],'credit uses boundary operating profit')
 return dict(cash_cents=data['final']['cash_cents'],fans=data['final']['fans'],cycle=data['final']['cycle'],earned_units=sum(r['earned_units'] for r in data['sales'].values()),earned_net_cents=sum(r['entitlement_cents'] for r in data['sales'].values()),settled_cents=sum(r['settled_cents'] for r in data['sales'].values()),unsettled_cents=f['unsettled_sales_net_cents'],feature_cents=sum(r['feature_play_cents'] for r in f['monthly_rows']),store_cents=sum(r['store_cents'] for r in f['monthly_rows']),rent_cents=sum(r['rent_paid_cents'] for r in f['monthly_rows']),publisher_cents=sum(r['publisher_income_cents'] for r in f['monthly_rows']),beta_cents=sum(r['beta_income_cents'] for r in f['monthly_rows']),credit=credit)

builds=[('none',0,0,''),('cult40p1',40,1,'cult_following'),('cult80p1',80,1,'cult_following'),('cult80p2',80,2,'cult_following'),('cult160p2',160,2,'cult_following'),('buzz',0,0,'studio_buzz'),('lean',0,0,'lean_production'),('family',0,0,'family_funding'),('cult80p1-buzz',80,1,'cult_following,studio_buzz'),('buzz-lean',0,0,'studio_buzz,lean_production')]
rows=[];restart_count=0
for seed in [1104,4417]:
 reference=read(f'route-{seed}-none')
 for build,fan_seed,cost,chosen in builds:
  name=f'route-{seed}-{build}';d=read(name)
  check(d['valid'] and not d['errors'] and not d['blockers'] and not d['stop'],name+' valid')
  check(d['seed']==seed and d['build']==build and d['candidate']==dict(seed=fan_seed,point_cost=cost),'declared seed/build inputs')
  check([s['cycle'] for s in d['cycles']]==list(range(1,29)),'all calendar snapshots')
  traits=chosen.split(',') if chosen else [];price=cost+(1 if 'studio_buzz' in traits else 0)+(2 if 'lean_production' in traits else 0)+(2 if 'family_funding' in traits else 0)
  point_cash=(4-price)*5000;family=30000 if 'family_funding' in traits else 0
  check(d['traits']['spent_points']==price and d['traits']['point_cash_cents']==point_cash,'actual point conversion')
  check(d['initial']['cash_cents']==550000+point_cash+family,'genuine initial cash cohort')
  check(d['initial']['fans']==fan_seed and not d['initial']['sales'],'no-sale ordinary seed')
  check(d['positive_slots']==len(traits)<=2 and d['three_positives_reject'],'positive slot cost and cap')
  check(trace(d)==trace(reference),name+' exact normalized actions/draws/redraws/selections')
  check(d['checkpoint']['rng']==reference['checkpoint']['rng'],name+' exact terminal RNG')
  check([r['final_review'] for r in d['releases']]==[r['final_review'] for r in reference['releases']],'matched native Reviews')
  for number,release in enumerate(d['releases'],1):
   review=release['metadata']['review'];launch=next(a for a in d['actions'] if a.get('phase')=='launch' and a.get('game')==number)
   check(review['launch_fans']==launch['before']['fans'],'launch fans frozen')
   check(review['awareness']==100+review['launch_marketing']+review['fan_awareness']+(3 if 'studio_buzz' in traits else 0),'one Fan term then approved trait bonus')
  row=fan_and_finance(d,fan_seed)
  check(row['store_cents']==0 and row['rent_cents']==700000,'zero Store and fourteen rent months')
  check(row['cash_cents']==550000+point_cash+family+row['beta_cents']+row['publisher_cents']+row['settled_cents']-row['feature_cents']-row['rent_cents'],'independent terminal cash composition')
  row.update(seed=seed,build=build,initial_fans=fan_seed,point_price=price,point_cash_cents=point_cash,initial_cash_cents=d['initial']['cash_cents'],positive_slots=len(traits),reviews=[r['final_review'] for r in d['releases']],launch_fans=[r['metadata']['review']['launch_fans'] for r in d['releases']],launch_awareness=[r['awareness'] for r in d['releases']],fan_gained=sum(r['gained'] for r in d['fanbase']['months']),fan_lost=sum(r['lost'] for r in d['fanbase']['months']))
  for label in ['initial','final']:
   restart=read(name+'-restart-'+label)
   check(restart['passed'] and restart['exact_payload'] and restart['duplicate_creation_rejected'] and restart['wrong_seed_rejected'],'strict cold restart')
   check(restart['fanbase']==d[label]['fanbase'] and restart['cash_cents']==d[label]['cash_cents'],'restart exact Fan/finance state')
   restart_count+=1
  rows.append(row)
for row in rows:
 baseline=next(r for r in rows if r['seed']==row['seed'] and r['build']=='none')
 row['cash_delta_vs_none_cents']=row['cash_cents']-baseline['cash_cents']
 row['sales_delta_vs_none_cents']=row['earned_net_cents']-baseline['earned_net_cents']
neutral=read('neutral-search');check(len(neutral['attempts'])==2 and neutral['found']==dict(name='neutral-1104-334',seed=1104,budget='3,3,4',review=5.0),'predeclared search stops at first native5.0')
neutral_rows=[]
for build,fan_seed,cost,chosen in builds:
 base=read('neutral-matched-'+build);d=read('neutral-earned-'+build)
 check(base['releases'][0]['final_review']==5.0 and base['valid'],'actual native neutral first release')
 check(trace(base)==trace(read('neutral-matched-none')) and base['checkpoint']['rng']==read('neutral-matched-none')['checkpoint']['rng'],'matched neutral RNG and play')
 check(d['valid'] and d['foundation_exact'] and d['foundation']==base['checkpoint'],'neutral begins from exact recorded foundation')
 for key in ['cash_cents','fans','fanbase','cycle','finance','finance_report','financial_block','redraws','sales']:
  check(d['initial'][key]==base['final'][key],'neutral exact restored persistent state: '+key)
 check([c['cycle'] for c in d['cycles']]==[12,13] and len(d['actions'])==1 and len(d['actions'][0]['hands'])==2,'two genuine Ironclad hands')
 check(trace(d)==trace(read('neutral-earned-none')) and d['checkpoint']['rng']==read('neutral-earned-none')['checkpoint']['rng'],'matched continuation play/RNG')
 row=fan_and_finance(d,fan_seed)
 check(row['fans']==fan_seed and all(m['gained']==0 and m['lost']==0 for m in d['fanbase']['months']),'neutral preserves seed at earned boundary')
 check(row['earned_units']>0 and row['earned_net_cents']>row['settled_cents']>0,'actual neutral earned and settled amounts distinct')
 check(d['metadata']==base['metadata'],'neutral launch metadata untouched')
 restart=read('neutral-earned-'+build+'-restart')
 check(restart['passed'] and restart['fanbase']==d['fanbase'] and restart['cash_cents']==row['cash_cents'],'neutral cold restore')
 restart_count+=1;row.update(build=build,initial_fans=fan_seed,review=5.0);neutral_rows.append(row)
# Runtime-source and result binding is separate from outcome calculations.
sources={name:provenance.capture(name) for name in ['candidate_route.gd','candidate_restart.gd','candidate_neutral_continue.gd']}
expected={}
def expect(name,build,driver,args):expected[name]=(build,driver,args)
for seed in [1104,4417]:
 for build in builds:
  name=f'route-{seed}-{build[0]}'
  expect(name,build,'candidate_route.gd',['--out='+str(HERE/(name+'.json')),'--build='+build[0],'--traits='+build[3],'--seed='+str(seed),'--budget=3,4,4','--search=0'])
  for label in ['initial','final']:
   restart=name+'-restart-'+label;expect(restart,build,'candidate_restart.gd',[label,str(HERE/(restart+'.json'))])
for attempt in neutral['attempts']:
 name=attempt['name'];expect(name,builds[0],'candidate_route.gd',['--out='+str(HERE/(name+'.json')),'--build=none','--traits=','--seed='+str(attempt['seed']),'--budget='+attempt['budget'],'--search=1'])
for build in builds:
 name='neutral-matched-'+build[0];expect(name,build,'candidate_route.gd',['--out='+str(HERE/(name+'.json')),'--build='+build[0],'--traits='+build[3],'--seed=1104','--budget=3,3,4','--search=1'])
 name='neutral-earned-'+build[0];expect(name,build,'candidate_neutral_continue.gd',['--out='+str(HERE/(name+'.json'))])
 name+='-restart';expect(name,build,'candidate_restart.gd',['neutral-earned',str(HERE/(name+'.json'))])
provenance_rows=[]
for path in sorted(HERE.glob('*.result-manifest.json')):
 name=path.name.removesuffix('.result-manifest.json');record=json.loads(path.read_text(encoding='utf8'));command=read(name+'.command')
 build,driver,args=expected[name]
 check(record['source']['driver']==driver and command['command'][4:]==['--script','res://scripts/debug/'+driver,'--']+args,'independent declared native command')
 provenance.validate(name,sources[driver],command['command'],build)
 check(command['exit_code']==0,'native exit and hashes')
 provenance_rows.append(dict(name=name,mode=record['mode'],log=provenance.validate_log((HERE/(name+'.log')).read_text(encoding='utf8'))))
check(len(provenance_rows)==92,'20routes+40restarts+2search+10neutral+10continuations+10restarts')
result=dict(passed=True,checks=checks+finance.checks,fan_finance_opportunity_checks=checks,finance_journal_checks=finance.checks,three_release_routes=20,neutral_search_attempts=2,neutral_matched_launches=10,neutral_continuations=10,fresh_process_restarts=restart_count,native_processes=92,posthoc_bindings=sum(r['mode'].startswith('post-hoc') for r in provenance_rows),pre_and_post_bindings=sum(not r['mode'].startswith('post-hoc') for r in provenance_rows),routes=rows,neutral=neutral_rows,provenance=provenance_rows)
(HERE/'audit.json').write_text(json.dumps(result,indent=2),encoding='utf8')
print(json.dumps({k:v for k,v in result.items() if k not in ['routes','neutral','provenance']},indent=2))
