"""Declare narrow unapproved trait shadows; preserve native actions and cash sources."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]; OUT=ROOT/'design-logs/task22-v1'
def scenarios():
 s=[dict(id='neutral_native',cash=0),dict(id='cash_only_4',cash=20000),dict(id='family_reference',cash=50000)]
 for aw,points in [(3,1),(5,2),(7,3),(10,1)]:s.append(dict(id=f'buzz{aw}_p{points}',cash=(4-points)*5000,buzz=aw))
 for aw in [3,5,7,10]:s.append(dict(id=f'matching{aw}_p1',cash=15000,matching=aw))
 for aw in [3,5,7,10]:s.append(dict(id=f'matching{aw}_free_effect',cash=20000,matching=aw))
 s += [dict(id='buzz3_match3_p2',cash=10000,buzz=3,matching=3),dict(id='buzz5_match3_p3',cash=5000,buzz=5,matching=3),dict(id='loan_buzz3_p1',cash=25000,buzz=3,loan=True),dict(id='loan_cash_only',cash=30000,loan=True)]
 # Initial Cult endowment retention bounds only: no invented new buyers or fan gains.
 # neutral=100%, weak=99%, strong=95% monthly retention; floor each calendar boundary.
 for fans in [25,50,75,100,200]:
  for retention in [100,99,95]:s.append(dict(id=f'cult{fans}_retain{retention}',cash=20000,fans=fans,retention=retention))
 return s
def paid(s):return sum(int(x['settled_cents']) for x in s['sales'])
def events(r):
 es=[]
 def add(label,b,a,direct):
  assert int(a['cash_cents']-b['cash_cents'])==direct+paid(a)-paid(b),(label,b,a,direct)
  es.append(dict(label=label,before=b,after=a,direct=direct))
 for a in r['actions']:
  p=a['phase']
  if p in ['design','alpha'] and 'after' in a:add(p,a['before'],a['after'],-int(a['cost_cents']))
  elif p=='beta':add(p,a['before'],a['after'],100000*a['selected'].count('playtest_rival_games'))
  elif p in ['launch','predevelopment','design priorities','alpha priorities','beta priorities']:add(p,a['before'],a['after'],0)
 for a in r['purchases']:add('purchase:'+a['id'],a['before'],a['after'],-int(a['quote']['price_cents']) if a['success'] else 0)
 for key,c in r.items():
  if not isinstance(c,dict) or 'contract_id' not in c:continue
  add(key+':accept',c['before'],c['after_accept'],int(c['completion']['upfront_cents']))
  for i,a in enumerate(c['hands']):add(key+':hand'+str(i+1),a['before'],a['after'],int(a['planned_remainder_cents']))
  if 'priority_commit' in c:
   a=c['priority_commit'];add(key+':priorities',a['before'],a['after'],0)
  add(key+':dismiss',c['hands'][-1]['after'],c['after_dismiss'],0)
 for a in r.get('common_alignment',[]):
  if 'after' in a:add('campaign_alignment_purchase',a['before'],a['after'],-int(a['quote']['price_cents']) if a['success'] else 0)
 if 'opportunity' in r:
  a=r['opportunity']['action']
  if 'after' in a:add('campaign',a['before'],a['after'],-10000 if a['success'] else 0)
 # Reconstruct same-cycle transactions from their native before/after cash chain.
 result=[];cycle=0;cash=550000
 while es:
  candidates=[(i,e) for i,e in enumerate(es) if e['before']['cycle']==cycle and e['before']['cash_cents']==cash]
  assert candidates,('broken event chain',cycle,cash,len(es))
  i,e=min(candidates,key=lambda x:(x[1]['after']['cycle'],abs(x[1]['after']['cash_cents']-cash)))
  result.append(e);es.pop(i);cycle=int(e['after']['cycle']);cash=int(e['after']['cash_cents'])
 assert cycle==r['final']['cycle'] and cash==r['final']['cash_cents']
 return result
if __name__=='__main__':
 inputs=[];routes=[];ss=scenarios()
 for path in sorted(OUT.glob('route_*.json')):
  if '.command.' in path.name:continue
  r=json.loads(path.read_text(encoding='utf-8'));ev=events(r);rid=path.stem
  assert r['valid'] and not r['discrepancies']
  frozen={x['ledger']['release_id']:x['ledger'] for x in r['captures'][0]['titles']}
  profiles=[]
  for rel in r['releases']:
   f=frozen[rel['release_id']];assert int(f['total_units'])==500*int(f['review_tenths'])*(int(f['launch_awareness'])+200)*int(f['market_bp'])//(70*200*10000)
   profiles.append(dict(release=rel,frozen=f))
  horizon=int(r['releases'][1]['cycle'])+48
  # Native ledger inputs deduplicated by route/release/launch Awareness.
  needed=set()
  for s in ss:
   aws=[]
   for p in profiles:
    rel=p['release'];fans=s.get('fans',0)
    for _ in range(int(rel['cycle'])//2):fans=fans*s.get('retention',100)//100
    fan_aw=150*fans//(fans+300) if fans else 0
    aw=max(0,int(rel['awareness'])+s.get('buzz',0)+s.get('matching',0)*(rel['genre']==r['specialty'])+fan_aw)
    aws.append(aw);needed.add((rel['release_id'],aw))
   s.setdefault('awareness_by_route',{})[rid]=aws
  for relid,aw in sorted(needed):
   p=next(x for x in profiles if x['release']['release_id']==relid)
   inputs.append(dict(id=f'{rid}:{relid}:{aw}',route=rid,release_id=relid,release_cycle=int(p['release']['cycle']),awareness=aw,frozen=p['frozen'],horizon=horizon))
  routes.append(dict(id=rid,route=r,events=ev,profiles=profiles,horizon=horizon))
 (OUT/'inputs.json').write_text(json.dumps(inputs),encoding='utf-8');(OUT/'prepared.json').write_text(json.dumps(dict(routes=routes,scenarios=ss)),encoding='utf-8')
 print('Prepared',len(routes),'routes,',len(ss),'scenarios,',len(inputs),'unique native ledgers')
