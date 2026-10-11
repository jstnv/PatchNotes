from pathlib import Path
import json,hashlib
HERE=Path(__file__).resolve().parent
checks=0

def check(ok,label):
 global checks
 checks+=1
 assert ok,label

routes={arm:json.loads((HERE/('route-'+arm)/'fit.json').read_text(encoding='utf-8')) for arm in ['control','cult']}
summary={}
for arm,d in routes.items():
 check(d['valid'] and not d['errors'] and not d['blockers'],'route complete')
 f=d['finance'];cash=0
 for tx in f['transactions']:
  check(tx['cash_before_cents']==cash,'transaction continuity')
  cash+=tx['cash_delta_cents']
  check(tx['cash_after_cents']==cash,'transaction arithmetic')
 check(cash==f['cash_cents']==d['final']['cash_cents'],'final exact cash')
 check(sum(a['productive'] for a in f['actions'])==d['final']['cycle']==28,'productive cycle count')
 for bill in f['obligations']:
  check(bill['expense_type']=='rent' and bill['due_cents']==50000 and bill['due_cycle']==2*bill['month'],'actual rent')
  check(sum(p['cents'] for p in bill['payments'])==bill['paid_cents']==bill['due_cents'],'rent paid')
 check(len(f['obligations'])==14,'14 rent months')
 check(not f['bank_loans'] and not f['employees'] and not f['education'],'no hidden optional liabilities')
 fans=40 if arm=='cult' else 0
 for row in d['fanbase']['months']:
  check(row['starting']==fans and row['lost']<=fans,'shared starting Fans')
  check(sum(r['new_fans'] for r in row['releases'])==row['gained'] and sum(r['lost_fans'] for r in row['releases'])==row['lost'],'monthly sums')
  fans+=row['gained']-row['lost'];check(fans==row['ending'] and row['net']==row['gained']-row['lost'],'monthly delta')
 check(fans==d['final']['fans'],'final Fans')
 sales_earned=sum(s['entitlement_cents'] for s in d['sales'].values());sales_settled=sum(s['settled_cents'] for s in d['sales'].values())
 check(sales_earned==sum(a['sales_earned'] for a in f['actions']),'earned ledger')
 check(sales_settled==sum(a['settled'] for a in f['actions']),'settled ledger')
 check(sales_earned-sales_settled==f['unsettled_sales_net_cents'],'unsettled exact')
 for release in d['releases']:
  review=release['metadata']['review'];check(review['fan_awareness']==min(150,review['launch_fans']//4),'frozen quarter mapping')
 for snap in d['checkpoints'].values():
  check(snap['run']['studio_traits']['version']=='7','new version')
 summary[arm]=dict(initial_cash=d['initial']['cash_cents'],final_cash=cash,final_fans=fans,credit=f['credit']['score'],reviews=[r['final_review'] for r in d['releases']],launch_fans=[r['metadata']['review']['launch_fans'] for r in d['releases']],earned_cents=sales_earned,settled_cents=sales_settled,low_cash=min(t['cash_after_cents'] for t in f['transactions']),rent_cents=700000,store_cents=sum(r['store_cents'] for r in f['monthly_rows']),feature_play_cents=sum(r['feature_play_cents'] for r in f['monthly_rows']))
a,b=routes.values();check(len(a['actions'])==len(b['actions']),'matched action length')
for x,y in zip(a['actions'],b['actions']):
 for key in ['phase','game','selected','cost_cents','normal_cents','draw','final_draw','redraws']:
  check(x.get(key)==y.get(key),'matched '+key)
 check(x['after']['cycle']==y['after']['cycle'] and x['after']['cores']==y['after']['cores'],'matched cycles and Core output')
# Verify audio credits were the sole changed data JSON since the supported education snapshot.
old=json.loads((HERE.parent/'education-implementation-v1/ui-v3/source-before.json').read_text(encoding='utf-8'))
root=HERE.parents[3];changed=[];count=0
for name,expected in old.items():
 if name.startswith('patch-notes/data/') and name.endswith('.json'):
  count+=1
  if hashlib.sha256((root/name).read_bytes()).hexdigest()!=expected:changed.append(name)
check(changed==['patch-notes/data/audio_credits.json'],'only credits changed in data')
result=dict(checks=checks,routes=summary,compared_data_files=count,data_differences=changed,limitation='One deterministic three-release starter route; no Store, Bank or payroll activation, no long-run balance claim')
(HERE/'audit.json').write_text(json.dumps(result,indent=2),encoding='utf-8');print(json.dumps(result,indent=2))
