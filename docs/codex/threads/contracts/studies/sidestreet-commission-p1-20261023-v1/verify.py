from pathlib import Path
import sys,json,hashlib
from paths import bundle
H=Path(__file__).resolve().parent;R=H.parents[5];T=H.parents[1]
sys.path.insert(0,str(R/'tools'));import simulate as sim;import simulator_variant as variant
checks=[]
def check(ok,label):checks.append(dict(ok=bool(ok),check=label))
def read(p):return json.loads(p.read_text())
meta,base,current,integrity=variant.load_variant(T/'simulators/sidestreet-commission-p1-v3')
check(meta['base_identity']=='42ef00919a6af975d5e779030583189b0077130de1ab416350c0cf202c158847','canonical P1 ancestry preserved')
check(meta['creation_identity']=='8c667d7df4f32d9eaed204f7a5acafa7d2f49fe7199ecad17971c05155ccbf18','v2 parent preserved')
check(variant.identity(current)=='0d7276b32153e9184f25c4cacaa75e520a3119988af64262068741b245cb2567','tested v3 candidate unchanged')
for stage in ['prefix','delivery','continue']:
    b=bundle(stage)
    check(read(b/'run-report.json')['ok'],stage+' runner PASS')
    check(read(b/'variant-provenance.json')['candidate_identity']==variant.identity(current),stage+' exact candidate identity')
    try:sim.check_snapshot(b/'project',read(b/'snapshot-manifest.json'));good=True
    except Exception:good=False
    check(good,stage+' frozen source unchanged')
for name in ['preflight-v3','callback-v3','focused-v3','continued-audit-v3']:
    for item in read(H/name/'results.json'):check(item['ok'],name+'/'+item['name'])
for name in ['prefix-analysis.json','analysis-v3.json']:
    value=read(H/name)
    for item in value['checks']:check(item['ok'],name+': '+item['check'])
for case in ['long-commission','long-owned','short-commission']:
    b=T/f'sims/sidestreet-commission-p1-replay-{case}-20261023-v3'
    check(read(b/'run-report.json')['ok'],'fresh replay '+case)
for case in ['long-commission','long-owned']:
    prior=read(bundle('delivery')/'cases'/case/'result.json')
    later=read(bundle('continue')/'cases'/case/'result.json')
    check(prior['final_state']==later['initial_state'],'exact cold Continue state '+case)
    check(prior['final_rng']==later['initial_rng'],'exact cold Continue RNG '+case)
for name in ['red/probe.command.json','orphan-red-v1/orphan.command.json','callback-v1/callback.command.json','renamed-red-v2/renamed.command.json']:
    check(read(H/name)['exit']==1,'expected RED preserved '+name)
handoff=T/'handoffs/sidestreet-p2-p3-20261023-v2'
sealed=read(handoff/'handoff-integrity.json')
check(all(sim.sha(handoff/name)==digest for name,digest in sealed.items()),'v2 handoff seal intact')
check(read(handoff/'handoff.json')['candidate_identity']==variant.identity(current),'handoff exact candidate')
canonical=sim.source_hashes(R/'patch-notes')
delta=variant.delta(base,canonical)
overlap=[x['path'] for x in variant.delta(base,current) if canonical.get(x['path'])!=base.get(x['path']) and canonical.get(x['path'])!=current.get(x['path'])]
before=read(H/'canonical-before.json')
after={str(p.relative_to(R/'patch-notes')):hashlib.sha256(p.read_bytes()).hexdigest() for p in (R/'patch-notes').rglob('*') if p.is_file() and '.godot' not in p.parts and p.suffix in ['.gd','.json','.godot','.tscn']}
changed=sorted(p for p in before.keys()|after.keys() if before.get(p)!=after.get(p))
check(not overlap,'no conflicting canonical path changed in candidate')
result=dict(checks=checks,failures=sum(not x['ok'] for x in checks),hypotheses=read(H/'analysis-v3.json')['hypotheses'],remaining_gates=['legal full delivery and positive production R/I','second commission completion','named current-P1 migration','native and exported acceptance'],candidate_identity=variant.identity(current),canonical_identity=variant.identity(canonical),canonical_drift=delta,canonical_changed_during_study=changed,overlaps=overlap)
with (H/'verification-complete.json').open('x') as f:json.dump(result,f,indent=2)
print(json.dumps(dict(checks=len(checks),failures=result['failures'],canonical_changed=changed,overlaps=overlap),indent=2))
