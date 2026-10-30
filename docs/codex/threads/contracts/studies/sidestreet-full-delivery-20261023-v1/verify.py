from pathlib import Path
import json,sys,hashlib,subprocess
H=Path(__file__).resolve().parent;R=H.parents[5];T=H.parents[1]
sys.path.insert(0,str(R/'tools'));import simulate as sim;import simulator_variant as variant
def read(p):return json.loads(p.read_text())
checks=[]
def check(ok,label):checks.append(dict(ok=bool(ok),check=label))
meta,base,current,integrity=variant.load_variant(T/'simulators/sidestreet-commission-p1-v3')
expected='0d7276b32153e9184f25c4cacaa75e520a3119988af64262068741b245cb2567'
check(variant.identity(current)==expected,'private gameplay candidate unchanged')
check(meta['base_identity']=='42ef00919a6af975d5e779030583189b0077130de1ab416350c0cf202c158847','original P1 baseline preserved')
for stage in ['first','second','caps','recovery','readiness']:
    b=T/f'sims/sidestreet-full-delivery-{stage}-20261023-v1'
    check(read(b/'run-report.json')['ok'],stage+' runner completed')
    check(read(b/'variant-provenance.json')['candidate_identity']==expected,stage+' exact candidate identity')
    try:sim.check_snapshot(b/'project',read(b/'snapshot-manifest.json'));ok=True
    except Exception as e:ok=False;print(e)
    check(ok,stage+' frozen source intact')
    replay=T/f'sims/sidestreet-full-delivery-{stage}-replay-20261023-v1'
    check(read(replay/'run-report.json')['ok'],stage+' fresh exact replay')
for folder,names in [('first-auditfixed',['gate']),('first-audit',['strict-save','observer']),('second-audit',['gate']),('caps-audit',['gate']),('recovery-audit',['gate']),('readiness-audit',['gate'])]:
    for name in names:
        v=read(H/folder/(name+'.json'))
        check(v['failures']==0,folder+'/'+name+' all '+str(len(v['checks']))+' assertions pass')
check(read(H/'first-audit/gate.command.json')['exit']==1,'original audit parse failure retained')
check((H/'gate_audit.gd').exists() and (H/'gate_audit_v2.gd').exists(),'both source-neutral harness revisions retained')
check(read(H/'analysis-complete.json')['failures']==2,'two unsupported seven-commission route expectations retained')
check(read(H/'analysis-complete-v2.json')['failures']==2,'two unsupported follow-up cap expectations retained')
check(all(x['ok'] for x in read(H/'caps-audit/results.json')),'focused P1 fixture cap checks pass separately from legal production')
analysis=read(H/'analysis-complete-v4.json')
checks+=analysis['checks']
packet=T/'handoffs/sidestreet-p2-p3-20261023-v2'
check(all(sim.sha(packet/name)==digest for name,digest in read(packet/'handoff-integrity.json').items()),'existing sealed adoption packet intact')
check(read(packet/'handoff.json')['candidate_identity']==expected,'new evidence matches sealed candidate')
canonical=sim.source_hashes(R/'patch-notes')
overlap=[x['path'] for x in variant.delta(base,current) if canonical.get(x['path']) not in [base.get(x['path']),current.get(x['path'])]]
check(not overlap,'no conflicting canonical path at evidence closeout')
manifest={}
for p in H.rglob('*'):
    if p.is_file() and 'profile' not in p.parts and p.suffix in ['.json','.gd','.py','.md','.log']:
        manifest[str(p.relative_to(H))]=sim.sha(p)
result=dict(checks=checks,failures=sum(not x['ok'] for x in checks),remaining_gate=analysis['remaining_gate'],candidate_identity=expected,canonical_identity=variant.identity(canonical),canonical_conflicts=overlap,head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=R,text=True).strip(),study_manifest=manifest)
with (H/'verification.json').open('x',encoding='utf-8') as f:json.dump(result,f,indent=2)
print(json.dumps({k:v for k,v in result.items() if k not in ['checks','study_manifest']}|dict(check_count=len(checks)),indent=2))
raise SystemExit(bool(result['failures']))
