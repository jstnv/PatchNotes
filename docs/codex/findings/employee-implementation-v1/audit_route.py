from pathlib import Path
import gzip,json,hashlib
HERE=Path(__file__).resolve().parent
d=json.loads(gzip.decompress((HERE/'route.json.gz').read_bytes()))
checks=0
def check(ok,label):
 global checks
 checks+=1
 if not ok:raise AssertionError(label)
check(d['valid'] and not d['errors'] and not d['discrepancies'],'Native route')
check(d['initial']['cash_cents']==570000,'Real base plus trait funding')
check(len(d['releases'])==3,'Three releases')
hire=next(a for a in d['actions'] if a['phase']=='hire')
check(hire['success'] and hire['before']['cycle']==hire['after']['cycle']==12,'Real zero-cycle post-release hire')
check(hire['before']['cash_cents']-hire['after']['cash_cents']==10000,'Hire fee once')
roster=d['final']['employees'];employee=next(iter(roster['employees'].values()))
check(len(roster['employees'])==1 and employee['trained'],'One trained permanent employee')
check(d['releases'][0]['release_id'] not in employee['projects'],'No retrospective Game1 progress')
uses=[];trained=False;seen=set();projects={}
for event in roster['events']:
 if event['type']=='hire':continue
 action=(event['project_id'],event['phase'],event['project_cycle'])
 check(action not in seen,'Unique committed hand identity');seen.add(action)
 cards=event['cards'];matches=any(p['type']=='pass' and f['type']=='feature' and p['primary'] in [f['primary'],f['secondary']] for p in cards for f in cards)
 if event['proposed']:
  check(trained and matches and event['project_id'] not in projects,'Qualified prior-trained once/project use')
  check(sum(event['proposed'].values())==100 and event['before']!=event['proposed'],'Changed valid priorities')
  projects[event['project_id']]=action
  uses.append(dict(project=event['project_id'],phase=event['phase'],cycle_before=event['cycle'],project_cycle=event['project_cycle'],cards=[c['id'] for c in cards],priorities=event['proposed']))
 if event['phase']=='design' and matches:trained=True
check(len(uses)==2,'Use in both later games')
for action in d['actions']:
 if 'employee_plan' in action:
  check(action['employee_plan_success'],'Accepted native bundled plan')
  check(action['after']['cycle']==action['before']['cycle']+1,'Exactly one productive cycle')
ledger=d['final']['finance'];bills=[b for b in ledger['obligations'] if b['expense_type']=='payroll']
check([b['due_cycle'] for b in bills]==list(range(14,51,2)),'First full month recurring payroll')
check(len({b['bill_id'] for b in bills})==len(bills),'Unique payroll identities')
for b in bills:check(b['due_cents']==b['paid_cents']==1000 and b['unpaid_cents']==0 and b['paid_on_time'],'Real paid salary')
for row in ledger['monthly_rows']:
 expense=sum(row[k] for k in ['feature_play_cents','store_cents','campaign_cents','playtest_cents','other_expense_cents','rent_due_cents','interest_cents','payroll_due_cents'])
 outflow=sum(row[k] for k in ['feature_play_cents','store_cents','campaign_cents','playtest_cents','other_expense_cents','rent_paid_cents','interest_paid_cents','principal_paid_cents','payroll_paid_cents'])
 check(row['operating_expenses_cents']==expense,'Accrual expense')
 check(row['net_profit_cents']==row['sales_net_earned_cents']+row['other_income_cents']-expense,'Accrual profit')
 check(row['closing_cash_cents']==row['opening_cash_cents']+row['sales_settled_cents']+row['other_income_cents']+row['financing_in_cents']-outflow,'Exact cash')
check(sum(r['sales_net_earned_cents'] for r in ledger['monthly_rows'])==sum(r['entitlement_cents'] for r in d['sales_records']),'Native earned reconciliation')
check(sum(r['sales_settled_cents'] for r in ledger['monthly_rows'])==sum(r['settled_cents'] for r in d['sales_records']),'Native settled reconciliation')
manifest=json.loads((HERE/'route-source.json').read_text());project=Path(manifest['project'])
for name,digest in manifest['files'].items():check(hashlib.sha256((project/name).read_bytes()).hexdigest()==digest,'Captured source unchanged '+name)
result=dict(checks=checks,releases=[{k:r[k] for k in ['cycle','final_review','month_1_units','cash_cents']} for r in d['releases']],hire_cycle=12,payroll_bills=len(bills),payroll_paid_cents=sum(b['paid_cents'] for b in bills),uses=uses,ending_cash_cents=d['final']['cash_cents'],native_ledger_checks=d['ledger_checks'],native_row_checks=d['row_checks'])
(HERE/'route-audit.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))
