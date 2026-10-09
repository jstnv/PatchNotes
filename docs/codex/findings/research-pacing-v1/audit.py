from pathlib import Path
import gzip,json,hashlib,sys,collections
H=Path(__file__).resolve().parent
sys.path.insert(0,str(H.parent/'queue-completion-v1'))
import finance_audit as audit
check=audit.check
manifest=json.loads((H/'source-manifest.json').read_text());copy=Path(manifest['analysis_copy'])
for name,digest in manifest['files'].items(): check(hashlib.sha256((copy/name).read_bytes()).hexdigest()==digest,'source '+name)
routes={};summary=[]
for spec in json.loads((H/'route-manifest.json').read_text()):
 name='-'.join(map(str,spec));d=json.loads(gzip.decompress((H/(name+'.json.gz')).read_bytes()));routes[tuple(spec)]=d
 command=json.loads((H/(name+'.command.json')).read_text());check(command['exit']==0 and not command['errors'],'command '+name)
 check(d['finance_valid'] and not d['errors'],'native validity '+name)
 check(d['initial']['cash_cents']==(550000 if spec[0]=='legacy' else 570000),'genuine startup cohort')
 audit.ledger(d['final']['finance'])
 for a in d['acquisitions']:
  before,after,q=a['before'],a['after'],a['quote'];check(a['rng_unchanged'],'shopping RNG')
  check(q['down_cents']==(q['base_cents']+1)//2,'half base admission')
  check(q['due_cents']==q['nominal_cents']*(100-q['discount_percent'])//100,'discounted installment')
  if not a['success']:
   check(before==after,'atomic failed shopping');continue
  op=a['operation'];id=a['id'];productive=op!='admit'
  check(after['cycle']==before['cycle']+int(productive),'shopping cycles')
  paid=q['down_cents'] if op=='admit' else q['due_cents'] if op=='research' else q['base_cents']*(100-q['discount_percent'])//100
  added=after['finance']['actions'][len(before['finance']['actions']):]
  check(len(added)==1 and added[0]['direct_delta']==-paid,'exact acquisition charge')
  check((id in after['owned'])==productive,'ownership only after completion')
  if op=='research':check(q['head'] and q['queued'],'only FIFO head')
  if d['acquisition']=='defer' and op=='research':
   check(len(d['releases'])>=2 and d['releases'][1]['final_review']>d['releases'][0]['final_review'],'stronger second release')
   check(before['cycle']>d['releases'][1]['cycle'],'settlement after stronger launch')
   release=d['releases'][1]['release_id'];check(any(t['release_id']==release and t['settled_cents']>0 for t in before['sales']),'actual stronger settlement')
 targets=['colored_text','recorded_sounds'] if spec[3]=='both' else [spec[3]]
 supply={id:any(id in a.get('eligible_supply',[]) for a in d['actions']) for id in targets}
 drawn={id:any(id in a.get('draw',[]) or id in a.get('final_draw',[]) for a in d['actions']) for id in targets}
 played={id:any(id in a.get('selected',[]) for a in d['actions']) for id in targets}
 for a in d['actions']:
  if 'eligible_supply' in a:
   for id in targets: check((id in a['eligible_supply'])==(id in a['after']['owned']),'future project supply')
 summary.append(dict(name=name,creation=spec[0],policy=spec[1],seed=spec[2],target=spec[3],acquisition=spec[4],releases=len(d['releases']),reviews=[r['final_review'] for r in d['releases']],cycle=d['final']['cycle'],cash=d['final']['cash_cents'],cash_low=min(s['cash_cents'] for s in [d['initial'],*d['cycles'],d['final']]),arrears=d['final']['finance_report']['total_overdue_cents'],stop=d['stop'],first_block=d['blockers'][:1],owned={id:id in d['final']['owned'] for id in targets},supply=supply,drawn=drawn,played=played,acquisition_failures=sum(not a['success'] for a in d['acquisitions'])))
# Matching is production policy/seed before acquisition, not invented identical
# post-acquisition draws. Normalize only random run identity fields out of signatures.
def signature(d,game):return [(a.get('phase'),a.get('draw'),a.get('selected')) for a in d['actions'] if a.get('game')==game]
comparisons=[]
for key,d in routes.items():
 if key[3]=='both' or key[4]=='none':continue
 base=routes[(*key[:4],'none')]
 check(signature(d,1)==signature(base,1),'matched pre-purchase Game1')
 def calendar(route):
  result={s['cycle']:s for s in route['cycles']}
  for a in route['acquisitions']:result[a['after']['cycle']]=a['after']
  result[route['final']['cycle']]=route['final'];return result
 left,right=calendar(d),calendar(base);common=sorted(set(left)&set(right));cycle=common[-1]
 x,y=left[cycle],right[cycle]
 comparisons.append(dict(name='-'.join(map(str,key)),matched_cycle=cycle,cash_delta=x['cash_cents']-y['cash_cents'],settled_delta=sum(r['sales_settled_cents'] for r in x['finance']['monthly_rows'])-sum(r['sales_settled_cents'] for r in y['finance']['monthly_rows']),arrears_delta=x['finance_report']['total_overdue_cents']-y['finance_report']['total_overdue_cents'],project_cycle_delta=x['project_cycle']-y['project_cycle']))
out=dict(checks=audit.checks,routes=summary,matched_calendar=comparisons,source=manifest['head'],analysis_sha256=hashlib.sha256((H/'pacing.gd').read_bytes()).hexdigest())
(H/'audit-summary.json').write_text(json.dumps(out,indent=2))
print('PASS',audit.checks,'checks',len(summary),'routes')
for acquisition in ['none','instant','immediate','defer','fifo','sequential']:
 rows=[r for r in summary if r['acquisition']==acquisition]
 print(acquisition,len(rows),'3 releases',sum(r['releases']==3 for r in rows),'owned',sum(any(r['owned'].values()) for r in rows),'played',sum(any(r['played'].values()) for r in rows),'arrears',sum(r['arrears']>0 for r in rows),'acquisition rejects',sum(r['acquisition_failures'] for r in rows))
