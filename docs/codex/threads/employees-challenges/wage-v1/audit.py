from pathlib import Path
import gzip,json,hashlib,csv,itertools
HERE=Path(__file__).resolve().parent;REPO=HERE.parents[4]
checks=0
def check(ok,label):
 global checks
 checks+=1
 if not ok:raise AssertionError(label)
def read(p):return json.loads(gzip.decompress(p.read_bytes()))
def signature(a):
 return {k:a[k] for k in ['phase','game','draw','redraws','final_draw','selected','employee_plan','employee_plan_success','cost_cents','blocked'] if k in a}
results=[];datasets={};boundaries=[];pairs=[]
for p in sorted(HERE.glob('*.json.gz')):
 if not p.with_name(p.name.replace('.json.gz','.command.json')).exists():continue
 d=read(p);name=p.name[:-8];meta=json.loads((HERE/(name+'.command.json')).read_text());startup,band,policy,contracts,stratum,wage=meta['case'];datasets[name]=d
 check(meta['exit']==0 and not meta['errors'] and d['valid'] and not d['errors'] and not d['discrepancies'],name+' native validity')
 check(d['initial']['cash_cents']==(550000 if startup=='legacy' else 580000 if stratum=='lease' else 570000),name+' startup')
 f=d['final']['finance'];rows=f['monthly_rows'];bills=f['obligations'];employees=f['employees'];roster=d['final']['employees'];uses=0;trained=False;used=set()
 for event in roster['events']:
  if event['type']=='hire':continue
  cards=event['cards'];matches=any(p['type']=='pass' and c['type']=='feature' and p['primary'] in [c['primary'],c['secondary']] for p in cards for c in cards)
  if event['proposed']:
   check(trained and matches and event['project_id'] not in used,name+' legal plan');check(sum(event['proposed'].values())==100 and min(event['proposed'].values())>=0 and event['proposed']!=event['before'],name+' changed allocation');used.add(event['project_id']);uses+=1
  if event['phase']=='design' and matches:trained=True
 check(len(employees)<=1 and (wage!=0 or not employees),name+' roster cap/no hire')
 for e in employees:
  check(e['wage_cents']==wage,name+' candidate wage')
  check(e['first_due_cycle']==e['hire_cycle']+2+e['hire_cycle']%2,name+' full month')
  pay=[b for b in bills if b['expense_type']=='payroll'];check([b['due_cycle'] for b in pay]==list(range(e['first_due_cycle'],f['last_cycle']+1,2)),name+' recurring due cycles')
  check(all(b['due_cents']==wage for b in pay),name+' bill amount')
 for b in bills:
  check(b['paid_cents']+b['unpaid_cents']==b['due_cents'] and b['unpaid_cents']>=0,name+' bill balance');check(sum(x['cents'] for x in b['payments'])==b['paid_cents'],name+' payment provenance')
 for tx in f['transactions']:
  check(tx['cash_after_cents']==tx['cash_before_cents']+tx['cash_delta_cents'] and tx['cash_after_cents']>=0,name+' transaction cash')
 for r in rows:
  expense=sum(r[k] for k in ['feature_play_cents','store_cents','campaign_cents','playtest_cents','other_expense_cents','rent_due_cents','interest_cents','payroll_due_cents'])
  outflow=sum(r[k] for k in ['feature_play_cents','store_cents','campaign_cents','playtest_cents','other_expense_cents','rent_paid_cents','interest_paid_cents','principal_paid_cents','payroll_paid_cents'])
  check(r['operating_expenses_cents']==expense,name+' expense');check(r['net_profit_cents']==r['sales_net_earned_cents']+r['other_income_cents']-expense,name+' profit');check(r['closing_cash_cents']==r['opening_cash_cents']+r['sales_settled_cents']+r['other_income_cents']+r['financing_in_cents']-outflow,name+' monthly cash')
 check(sum(r['sales_net_earned_cents'] for r in rows)==sum(r['entitlement_cents'] for r in d['sales_records']),name+' earned');check(sum(r['sales_settled_cents'] for r in rows)==sum(r['settled_cents'] for r in d['sales_records']),name+' settled')
 for a in d['actions']:
  if a['phase']=='chosen_bank' and a['success']:
   q=a['quote'];basis=min(q['latest_sales_cents'],(q['latest_sales_cents']+q['older_sales_cents'])//2)
   check(q['basis_cents']==basis and q['capacity_cents']==max(0,basis-q['rent_cents']-q['obligations_cents'])//4,name+' payroll deducted once from bank capacity')
   check(a['before']['cycle']==a['after']['cycle'] and a['after']['cash_cents']-a['before']['cash_cents']==50000,name+' chosen financing receipt')
  if a['phase']=='hire_attempt' and a['success']:check(a['before']['cycle']==a['after']['cycle'] and a['before']['cash_cents']-a['after']['cash_cents']==10000,name+' zero cycle fee')
  if 'employee_plan' in a:check(a['employee_plan_success'] and a['after']['cycle']==a['before']['cycle']+1,name+' bundled action')
 for s in d['live_cycles']:
  boundaries.append(dict(case=name,cycle=s['cycle'],cash=s['cash_cents'],credit=s['finance']['credit']['score'],unpaid=sum(b['unpaid_cents'] for b in s['finance']['obligations']),sales=s['sales'],rows=s['finance']['monthly_rows']))
 item=dict(case=name,startup=startup,band=band,policy=policy,contracts=contracts,stratum=stratum,wage=wage,releases=len(d['releases']),cycles=[r['cycle'] for r in d['releases']],reviews=[r['final_review'] for r in d['releases']],hire_cycle=employees[0]['hire_cycle'] if employees else None,uses=uses,trained=trained,final_cycle=f['last_cycle'],final_cash=f['cash_cents'],cash_low=min(t['cash_after_cents'] for t in f['transactions']),unpaid=sum(b['unpaid_cents'] for b in bills),credit=f['credit']['score'],stop=d['stop'],earned=sum(r['sales_net_earned_cents'] for r in rows),settled=sum(r['sales_settled_cents'] for r in rows),contract_receipts=sum(r['publisher_income_cents'] for r in rows),rent_due=sum(r['rent_due_cents'] for r in rows),rent_paid=sum(r['rent_paid_cents'] for r in rows),payroll_due=sum(r['payroll_due_cents'] for r in rows),payroll_paid=sum(r['payroll_paid_cents'] for r in rows),bank_due=sum(b['due_cents'] for b in bills if b['expense_type']=='bank'),bank_paid=sum(b['paid_cents'] for b in bills if b['expense_type']=='bank'),bank_loans=len(f['bank_loans']),store_paid=sum(r['store_cents'] for r in rows),owned=d['owned_ids'],optional=[{k:a[k] for k in ['phase','quote','success']} for a in d['actions'] if a['phase'] in ['chosen_bank','chosen_store']])
 results.append(item)
 item['bank_due']=sum(b['due_cents'] for b in bills if b['expense_type']=='bank_installment')
 item['bank_paid']=sum(b['paid_cents'] for b in bills if b['expense_type']=='bank_installment')
 for loan in f['bank_loans']:
  schedule=loan['schedule'];principal=schedule['principal_cents'];term=schedule['term_months'];opening=principal
  for index,b in enumerate([b for b in bills if b['source_id']==loan['loan_id']]):
   portion=principal//term+(1 if index<principal%term else 0);interest=(opening+50)//100
   check(b['due_cycle']==schedule['first_due_cycle']+2*index and b['due_cents']==portion+interest,name+' exact bank schedule')
   opening-=portion
for key,group in itertools.groupby(results,key=lambda r:r['case'].rsplit('_',1)[0]):
 group=list(group);base=next((r for r in group if r['wage']==1000),None)
 if not base:continue
 aa=[signature(a) for a in datasets[base['case']]['actions'] if a['phase'] not in ['hire_attempt','chosen_bank','chosen_store']]
 for r in group:
  if r['wage']==0:continue
  bb=[signature(a) for a in datasets[r['case']]['actions'] if a['phase'] not in ['hire_attempt','chosen_bank','chosen_store']];n=next((i for i,(a,b) in enumerate(zip(aa,bb)) if a!=b),min(len(aa),len(bb)))
  pairs.append(dict(base=base['case'],candidate=r['case'],identical_actions=aa==bb,common_actions=n,base_next=aa[n] if n<len(aa) else None,candidate_next=bb[n] if n<len(bb) else None))
m=json.loads((HERE/'source.json').read_text())
for k,h in m['main'].items():check(hashlib.sha256((REPO/'patch-notes'/k).read_bytes()).hexdigest()==h,'main source preserved '+k)
for k,h in m['isolated'].items():check(hashlib.sha256((Path(m['project'])/k).read_bytes()).hexdigest()==h,'isolated source preserved '+k)
for k,h in json.loads((HERE/'harness-source.json').read_text()).items():
 check(hashlib.sha256((HERE/'harness'/k).read_bytes()).hexdigest()==h,'saved harness '+k)
 check(hashlib.sha256((Path(m['project'])/'analysis'/k).read_bytes()).hexdigest()==h,'executed harness '+k)
fixed=read(HERE/'fixed.json.gz')
for x in fixed:
 f=x['finance'];check(x['valid'] and f['cash_cents']>=0,'fixed native validity')
 if x['wage']==1000:check(f==datasets[x['case']]['final']['finance'],'fixed baseline exact reconstruction')
 for r in f['monthly_rows']:
  outflow=sum(r[k] for k in ['feature_play_cents','store_cents','campaign_cents','playtest_cents','other_expense_cents','rent_paid_cents','interest_paid_cents','principal_paid_cents','payroll_paid_cents'])
  check(r['closing_cash_cents']==r['opening_cash_cents']+r['sales_settled_cents']+r['other_income_cents']+r['financing_in_cents']-outflow,'fixed cash reconciliation')
 for b in f['obligations']:check(b['due_cents']==b['paid_cents']+b['unpaid_cents'] and b['unpaid_cents']>=0,'fixed bill balance')
(HERE/'audit.json').write_text(json.dumps(dict(checks=checks,routes=len(results),fixed_sensitivities=len(fixed),fixed_censored=[{k:x[k] for k in ['case','wage','committed','source_actions','stop']} for x in fixed if x['stop']],results=results,pairs=pairs),indent=2),encoding='utf-8')
(HERE/'boundaries.json.gz').write_bytes(gzip.compress(json.dumps(boundaries).encode()))
print('PASS',checks,'checks;',len(results),'routes')
for band in ['early','slow','stress']:
 for contracts in ['none','available']:
  print(band,contracts,[(w,sum(r['releases']==3 for r in results if r['band']==band and r['contracts']==contracts and r['stratum']=='base' and r['wage']==w)) for w in [0,1000,2500,5000,7500]])
