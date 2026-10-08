from pathlib import Path
import gzip,json,hashlib
HERE=Path(__file__).resolve().parent
d=json.loads(gzip.decompress((HERE/'route.json.gz').read_bytes()))
checks=0
def check(ok,label):
 global checks
 checks+=1
 if not ok:raise AssertionError(label)
check(d['valid'] and not d['errors'] and not d['discrepancies'],'Native route valid')
check(d['initial']['cash_cents']==565000 and len(d['releases'])==2,'Genuine combined startup and two releases')
ledger=d['final']['finance']
check(ledger['monthly_rent_cents']==51500,'Actual run rent')
check(len(ledger['obligations'])==16,'One bill each completed month')
for bill in ledger['obligations']:
 check(bill['expense_type']=='rent' and bill['due_cents']==51500,'Single actual-rent category')
paid=0
for action in d['actions']:
 if 'normal_cents' not in action:continue
 before=action['before'];after=action['after']
 if after['cycle']==before['cycle']:check(before==after,'Rejected action preserves state');continue
 op=after['finance']['actions'][-1];project=op['source_id']
 saved=before['lean_savings'].get(project,0)
 discount=min(action['normal_cents']//10,10000-saved)
 check(action['cost_cents']==action['normal_cents']-discount,'Independent discount and cap')
 check(op['direct_delta']==-action['cost_cents'] and op['kind']=='feature_play','Native expense matches quote')
 check(after['lean_savings'].get(project,0)==saved+discount,'Actual cumulative savings')
 check(after['cycle']==before['cycle']+1,'Ordinary single cycle')
 paid+=1
for release in d['releases']:
 check(release['awareness']==103+release['marketing'],'Buzz frozen in actual launch')
 sale=next(s for s in d['sales_records'] if s['release_id']==release['release_id'])
 check(sale['launch_awareness']==release['awareness'],'Same sales Awareness')
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
result=dict(checks=checks,paid_hands=paid,releases=[{k:r[k] for k in ['cycle','final_review','month_1_units','cash_cents','awareness']} for r in d['releases']],lean_savings=d['final']['lean_savings'],ending_cash_cents=d['final']['cash_cents'],native_ledger_checks=d['ledger_checks'],native_row_checks=d['row_checks'])
(HERE/'route-audit.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))
