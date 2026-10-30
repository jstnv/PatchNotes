from pathlib import Path
import importlib.util,json,hashlib,subprocess
ROOT=Path(__file__).resolve().parents[6];HERE=Path(__file__).resolve().parent
S=ROOT/'docs/codex/threads/contracts/sims'
B=S/'publisher-p1-baseline-20261023-v1';C=S/'publisher-p1-candidate-20261023-v2'
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
checks=[]
def check(ok,name): checks.append({'check':name,'pass':bool(ok)})
identities={}
for case in ('action-4417','sports-1112'):
    b=B/'cases'/case;c=C/'cases'/case
    br=read(b/'result.json');cr=read(c/'result.json')
    identities[case]={'baseline':br['source_identity'],'candidate':cr['source_identity']}
    check(br['ok'] and cr['ok'] and br['status']==cr['status']=='completed',case+' completed both')
    check(br['commands']==cr['commands']==36,case+' unchanged 36 commands')
    check(br['initial_rng']==cr['initial_rng'] and br['final_rng']==cr['final_rng'],case+' initial and final RNG equal')
    check(br['outcome']==cr['outcome'],case+' complete measured outcome equal')
    check(read(b/'case.json')['initial']==read(c/'case.json')['initial'],case+' exact legal starting recipe')
    check(bool(cr['artifacts']['studio_checkpoint']),case+' nonempty Studio checkpoint')
    bp=read(b/'studio_checkpoint.json')['studio_payload'];cp=read(c/'studio_checkpoint.json')['studio_payload']
    ledger=cp['run'].pop('publisher_relationships')
    check(ledger=={'version':'1','owner':cp['run']['bank_run_id'],'events':[]},case+' no new relationship awards')
    cp['content_revision']=bp['content_revision']
    check(cp==bp,case+' all preexisting native fields and RNG equal')
runtime=read(HERE/'runtime-audit-v2.json')
check(runtime['failures']==0 and len(runtime['checks'])==80,'native decoded runtime and command audit80/0')
for name in ['publisher-p1-baseline-replay-20261023-v1','publisher-p1-candidate-replay-20261023-v2']:
    report=read(S/name/'run-report.json');check(report['ok'],name+' exact replay')
spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py');sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
baseline_manifest=read(ROOT/'docs/codex/threads/contracts/simulators/publisher-relationships-foundation-v2/base-manifest.json')
canonical=sim.source_hashes(ROOT/'patch-notes')
changed=sorted(k for k in set(canonical)|set(baseline_manifest) if canonical.get(k)!=baseline_manifest.get(k))
check(not changed,'canonical source unchanged since captured baseline')
focused={p.parent.name:read(p) for p in sorted((HERE/'checks').glob('*/result.json'))}
check(len(focused)<=14,'focused process amended bound')
check(len(list(S.glob('publisher-p1-*/run-report.json')))<=6,'run/replay bound')
report={'scope':'cross-revision dormant-ledger parity; no balance inference','identities':identities,'checks':checks,'failed':[c for c in checks if not c['pass']],'canonical_changed_paths':changed,'focused_results':focused,'canonical_identity':hashlib.sha256(json.dumps(canonical,sort_keys=True).encode()).hexdigest()}
with (HERE/'audit-final.json').open('x',encoding='utf-8') as f: json.dump(report,f,indent=2)
print(json.dumps({'checks':len(checks),'failed':report['failed'],'canonical_changed_paths':changed,'identities':identities,'focused_processes':len(focused)},indent=2))
raise SystemExit(bool(report['failed']))
