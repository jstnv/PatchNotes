"""Independent B6 cents, quote, debt and matched-calendar analysis."""
from pathlib import Path
import json,gzip,hashlib,sys
H=Path(__file__).resolve().parent
sys.path.insert(0,str(H.parent/'queue-completion-v1'))
import finance_audit as a
m=json.loads((H/'source-manifest.json').read_text());copy=Path(m['analysis_copy'])
for name,digest in m['files'].items():a.check(hashlib.sha256((copy/name).read_bytes()).hexdigest()==digest,'source hash '+name)
summary=[];comparisons=[]
def money(s):
 f=s['finance'];loans=f.get('bank_loans',[])
 return dict(cycle=s['cycle'],cash=s['cash_cents'],debt=sum(x['schedule']['principal_cents']-x['principal_paid_cents'] for x in loans),arrears=s['finance_report']['total_overdue_cents'],credit=f['credit'],settled=sum(r['sales_settled_cents'] for r in f['monthly_rows']),earned=sum(x['entitlement_cents'] for x in s['sales']))
for spec in json.loads((H/'route-manifest.json').read_text()):
 name='-'.join(map(str,spec));d=json.loads(gzip.decompress((H/(name+'.json.gz')).read_bytes()))
 c=json.loads((H/(name+'.command.json')).read_text());a.check(c['exit']==0 and not c['errors'],'native process')
 a.check(d['valid'] and not d['errors'],'native validity');a.ledger(d['final']['finance'])
 a.check(d['initial']['cash_cents']==(550000 if spec[0]=='legacy' else 570000),'genuine creation')
 first=d.get('first_release',d['final']);low=min([d['initial']['cash_cents']]+[s['cash_cents'] for s in d['cycles'] if s['cycle']<=first['cycle']])
 tx=first['finance']['transactions']
 summary.append(dict(name=name,release=d['releases'][:1],first=money(first),low_cents=low,feature_play_cents=-sum(t['cash_delta_cents'] for t in tx if t['kind']=='feature_play'),first_block=d['blockers'][:1],quote=d.get('quote',{}),eligible=money(d.get('eligible_state',d['final'])),arms=len(d['loans'])))
 for arm in d['loans']:
  a.check(arm['restored_exact'],'identical full captured Studio')
  for field in ['cycle','cash_cents','redraws','sales','finance','finance_report']:
   a.check(arm['initial'][field]==d['eligible_state'][field],'identical hydrated '+field)
  a.check(arm['valid'] and not arm['errors'],'arm native validity');a.ledger(arm['final']['finance'])
  before,after,q=arm['initial'],arm['after_accept'],arm['quote'];p=arm['principal']
  a.check(after['cycle']==before['cycle'],'borrowing zero cycles')
  a.check(after['cash_cents']-before['cash_cents']==p,'cash financing distinct')
  if p:
   a.check(arm['accepted'] and q['accepted'],'quote accepted')
   older,latest=q['older_sales_cents'],q['latest_sales_cents']
   basis=min(latest,(older+latest)//2);a.check(q['basis_cents']==basis,'conservative quote basis')
   a.check(q['capacity_cents']==max(0,basis-q['rent_cents']-q['obligations_cents'])//4,'capacity')
   a.check(q['obligations_cents']==0,'no employees live')
   sch=q['schedule'];a.check(sch['first_due_cycle']==before['cycle']+2+before['cycle']%2,'first full month')
   n=sch['term_months'];base,extra=divmod(p,n);opening=p;interest=0
   for i in range(n):interest+=(opening+50)//100;opening-=base+int(i<extra)
   a.check(opening==0 and interest==sch['total_interest_cents'],'independent schedule')
   if arm['payoff']:
    loan=arm['final']['finance']['bank_loans'][-1];a.check(loan['closed'] and loan['principal_paid_cents']==p,'explicit payoff closure')
  a.check(money(after)['debt']==p,'financing is debt')
 if d['loans']:
  base=d['loans'][0]
  for arm in d['loans'][1:]:
   def calendar(x):return {s['cycle']:s for s in [x['after_accept'],*x['cycles'],x['before_payoff']]}
   x,y=calendar(base),calendar(arm);common=sorted(set(x)&set(y));a.check(bool(common),'matched calendar exists')
   cycle=common[-1];left,right=money(x[cycle]),money(y[cycle])
   comparisons.append(dict(name=name,principal=arm['principal'],cycle=cycle,no_loan=left,loan=right,cash_delta=right['cash']-left['cash'],cash_less_debt_delta=(right['cash']-right['debt'])-(left['cash']-left['debt']),second_reviews=arm['releases'],first_block=arm['blockers'][:1],payoff=arm.get('payoff',False),final=money(arm['final'])))
result={'pass':True,'checks':a.checks,'foundations':summary,'comparisons':comparisons}
(H/'audit-result.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print('PASS',a.checks,'checks',len(summary),'foundations',len(comparisons),'loan comparisons')
