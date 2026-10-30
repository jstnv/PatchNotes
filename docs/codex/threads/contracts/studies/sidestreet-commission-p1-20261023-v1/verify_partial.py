from pathlib import Path
import sys,json,hashlib,subprocess
H=Path(__file__).resolve().parent;R=H.parents[5];T=H.parents[1]
sys.path.insert(0,str(R/'tools'));import simulate as sim;import simulator_variant as variant
checks=[]
def check(ok,label):checks.append(dict(ok=bool(ok),check=label))
def read(p):return json.loads(p.read_text())
meta,base,current,integrity=variant.load_variant(T/'simulators/sidestreet-commission-p1-v3')
check(meta['base_identity']=='42ef00919a6af975d5e779030583189b0077130de1ab416350c0cf202c158847','canonical P1 ancestry intact')
check(meta['creation_identity']=='8c667d7df4f32d9eaed204f7a5acafa7d2f49fe7199ecad17971c05155ccbf18','v2 parent identity intact')
check(variant.identity(current)=='0d7276b32153e9184f25c4cacaa75e520a3119988af64262068741b245cb2567','tested v3 source unchanged')
for tag in ['v1','v2','v3']:
    b=T/f'sims/sidestreet-commission-p1-prefix-20261023-{tag}'
    check(read(b/'run-report.json')['ok'],tag+' prefix runner PASS')
    try:sim.check_snapshot(b/'project',read(b/'snapshot-manifest.json'));good=True
    except Exception:good=False
    check(good,tag+' prefix frozen source unchanged')
for group in ['preflight-v3','callback-v3']:
    for row in read(H/group/'results.json'):check(row['ok'],group+'/'+row['name'])
check(read(H/'callback-v3/quote-boundary.json')['failures']==0,'10 quote boundary assertions PASS')
for row in read(H/'prefix-analysis.json')['checks']:check(row['ok'],row['check'])
for name in ['red/probe.command.json','orphan-red-v1/orphan.command.json','callback-v1/callback.command.json','renamed-red-v2/renamed.command.json']:
    check(read(H/name)['exit']==1,'expected RED retained '+name)
for suffix in ['', '-retry1']:
    b=T/f'sims/sidestreet-commission-p1-delivery-20261023-v3{suffix}'
    report=read(b/'run-report.json')
    check(not report['ok'] and 'Canonical source changed' in report['error'],'capture race retained '+suffix)
    check(not (b/'experiment.command.json').exists() and not (b/'cases').exists(),'no delivery case ran '+suffix)
for case in ['sports-1112','action-1108']:
    b=T/f'sims/sidestreet-commission-p1-prefix-replay-{case}-20261023-v3'
    check(read(b/'run-report.json')['ok'],'fresh prefix replay '+case)
    original=read(T/'sims/sidestreet-commission-p1-prefix-20261023-v3/cases'/case/'result.json')
    replay=read(b/'replay-report.json')
    check(replay.get('final_state')==original['final_state'] and len(replay.get('steps',[]))==original['commands'],'exact replay final state and count '+case)
handoff=T/'handoffs/sidestreet-p2-p3-20261023-v1'
sealed=read(handoff/'handoff-integrity.json')
check(all(sim.sha(handoff/name)==digest for name,digest in sealed.items()),'sealed handoff file hashes intact')
h=read(handoff/'handoff.json')
check(h['candidate_identity']==variant.identity(current) and not h['adopted'],'handoff exact candidate, not adopted')
check(len(h['evidence'])==1,'handoff references completed prefix evidence only')
canonical=sim.source_hashes(R/'patch-notes')
delta=variant.delta(base,canonical)
overlap=[x['path'] for x in variant.delta(base,current) if canonical.get(x['path'])!=base.get(x['path']) and canonical.get(x['path'])!=current.get(x['path'])]
before=read(H/'canonical-before.json')
after={str(p.relative_to(R/'patch-notes')):hashlib.sha256(p.read_bytes()).hexdigest() for p in (R/'patch-notes').rglob('*') if p.is_file() and '.godot' not in p.parts and p.suffix in ['.gd','.json','.godot','.tscn']}
changed=sorted(p for p in before.keys()|after.keys() if before.get(p)!=after.get(p))
git={k:subprocess.check_output(['git',*v],cwd=R,text=True) for k,v in {'branch':['branch','--show-current'],'head':['rev-parse','HEAD'],'status':['status','--porcelain'],'diff':['diff','--stat']}.items()}
with (H/'git-after.json').open('x') as f:json.dump(git,f,indent=2)
result=dict(status='PARTIAL: gate and quote verified; delivery blocked before execution',checks=checks,failures=sum(not x['ok'] for x in checks),candidate_identity=variant.identity(current),canonical_identity=variant.identity(canonical),canonical_drift=delta,canonical_changed_during_study=changed,overlaps=overlap,not_run=['commission delivery cases','later-sales continuations','completed-deal save audit','settlement observer replay','three delivery replays','native/exported acceptance','named P1 migration'])
with (H/'verification.json').open('x') as f:json.dump(result,f,indent=2)
print(json.dumps(dict(status=result['status'],checks=len(checks),failures=result['failures'],canonical_changed=changed,overlaps=overlap),indent=2))
