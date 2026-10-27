from pathlib import Path
import datetime,hashlib,json
BASE=Path(__file__).resolve().parent;ROOT=BASE.parents[3]
checks=0; failures=[]; files={}
def check(ok,label):
 global checks
 checks+=1
 if not ok:failures.append(label)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def load(p):
 x=json.loads(p.read_text());files[str(p.relative_to(ROOT))]=sha(p)
 if 'payload_utf8' in x:
  check(hashlib.sha256(x['payload_utf8'].encode()).hexdigest()==x['payload_sha256'],str(p)+' envelope hash')
  return json.loads(x['payload_utf8'])
 return x
def finance(f,label):
 cash=0
 for i,t in enumerate(f['transactions']):
  check(int(t['sequence'])==i+1,label+' transaction sequence')
  check(int(t['cash_before_cents'])==cash,label+' cash continuity')
  check(int(t['cash_before_cents'])+int(t['cash_delta_cents'])==int(t['cash_after_cents']),label+' cash arithmetic')
  cash=int(t['cash_after_cents']);check(cash>=0,label+' nonnegative cash')
 check(cash==int(f['cash_cents']),label+' closing cash')
 for bill in f['obligations']:
  check(int(bill['paid_cents'])+int(bill['unpaid_cents'])==int(bill['due_cents']),label+' original bill')
  check(sum(int(p['cents']) for p in bill['payments'])==int(bill['paid_cents']),label+' payment history')
def save(p,label):
 x=load(p);finance(x['run']['studio_finance'],label)
 if 'rival_world' in x:
  for studio in x['rival_world']['studios']:finance(studio['run']['run']['studio_finance'],label+'/'+studio['id'])
 return x
milestones=[]
for cycle,seq in [(7,2),(9,3)]:
 p=BASE/'milestones'/f'long-ai-studio{cycle}.json';x=save(p,f'ai{cycle}');milestones.append(x)
 after=next((BASE/'profiles/long-ai').rglob(f'checkpoint.{seq}.json'))
 check(p.read_bytes()==after.read_bytes(),f'AI{cycle} unmodified after cold Continue')
 check(int(x['run']['completed_run_cycles'])==cycle,'AI cycle')
 check(len(x['rival_world']['history'])==2,'Exactly two live rival releases')
 for studio in x['rival_world']['studios']:
  check(len(studio['archive'])==2,'Frozen archive preserved')
  check(int(studio['run']['run']['completed_run_cycles'])==cycle,'Rival calendar matches')
check(milestones[0]['rival_world']['history']==milestones[1]['rival_world']['history'],'Contract continuation does not repeat rival launches')
promo=next((BASE/'profiles/promotion').rglob('checkpoint.3.json'));p=save(promo,'promotion')
check(int(p['run']['completed_run_cycles'])==17 and int(p['run']['cash_cents'])==540244,'Promotion rollback exact Studio/cash')
origins=[]
for old in (ROOT/'docs/codex/findings/queue-completion-20261011-v1/checkpoints').rglob('checkpoint.*.json'):
 if old.stat().st_size==promo.stat().st_size and sha(old)==sha(promo):origins.append(str(old.relative_to(ROOT)))
check(bool(origins),'Promotion checkpoint equals retained legal origin bytes')
for profile in ['profiles/long-ai','profiles/promotion','final-profiles/long-ai']:
 for log in (BASE/profile).rglob('godot*.log'):
  errors=[l for l in log.read_text(errors='replace').splitlines() if l.startswith(('ERROR:','SCRIPT ERROR:'))]
  check(not errors,str(log)+' runtime log')
for row in map(json.loads,(BASE/'ui-processes.jsonl').read_text().splitlines()):check(row['exit_code']==0,'Retained-build UI process exit')
final=[json.loads(l) for l in (BASE/'final-ui-processes.jsonl').read_text().splitlines()]
check(len(final)>=4 and [r['exit_code'] for r in final[:2]]==[1,1] and all(r['exit_code']==0 for r in final[2:]),'Two failed export launches retained; corrected both-size launches pass')
for case in ['crown','traits-control','traits-selected']:
 r=load(BASE/f'comparison-{case}-v2.json');check(r['ok'] and r['initial'] and all(r['steps']),case+' normalized legacy state parity')
for pair in ['integrated-crown-v2-replay','integrated-traits-v1-replay']:
 r=load(BASE/pair/'replay-report.json');check(r['ok'],pair+' exact current replay')
for r in load(BASE/'fresh-world-v3/results.json'):check(r['exit']==0 and not r['errors'],'Fresh process '+r['label'])
manifest=load(BASE/'final-delivery-v4/build-manifest.json');drift=[]
for path,digest in manifest['included'].items():
 if not (ROOT/'patch-notes'/path).exists() or sha(ROOT/'patch-notes'/path)!=digest:drift.append(path)
check(all(p.endswith('.uid') for p in drift),'Final gameplay scripts/data/scenes/assets match canonical')
pack=load(BASE/'final-delivery-v4/pack-manifest-verified.json');check(pack['count']==297 and pack['files']['res://project.binary']['bytes']>0,'Final package contains project configuration')
result=dict(checks=checks,failures=failures,files=files,promotion_origins=origins,runtime_metadata_drift=drift,captures=len((BASE/'captures/index.jsonl').read_text().splitlines()),utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
(BASE/'audit-result.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2)[:800]);raise SystemExit(bool(failures))
