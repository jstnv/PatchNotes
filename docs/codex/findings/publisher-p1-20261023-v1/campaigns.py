"""Two fixed legal cases and one exact replay per revision; immutable bundles."""
from pathlib import Path
import json, subprocess, sys
from check import ROOT,OUT,GODOT,sim

for label,args in [
    ('baseline-run',['run','--repo',str(OUT/'baseline-repo'),'--config',str(OUT/'cases.json')]),
    ('integrated-run',['run','--config',str(OUT/'cases.json')]),
    ('baseline-replay',['replay','--bundle',str(OUT/'baseline-run'),'--case','action-4417']),
    ('integrated-replay',['replay','--bundle',str(OUT/'integrated-run'),'--case','action-4417']),
]:
    command=[sys.executable,'-X','utf8',str(ROOT/'tools/simulate.py'),*args,'--godot',GODOT,'--output',str(OUT/label),'--timeout','300']
    with (OUT/(label+'-process.log')).open('wb') as log:
        result=subprocess.run(command,stdout=log,stderr=subprocess.STDOUT)
    sim.write_json(OUT/(label+'-process.json'),dict(command=command,exit=result.returncode))
    print(label,result.returncode,flush=True)
    if result.returncode:raise SystemExit(result.returncode)

checks=[]
for case in ['action-4417','sports-1112']:
    old=OUT/'baseline-run/cases'/case;new=OUT/'integrated-run/cases'/case
    a=sim.read_json(old/'result.json');b=sim.read_json(new/'result.json')
    before=sim.read_json(old/'studio_checkpoint.json')['studio_payload']
    after=sim.read_json(new/'studio_checkpoint.json')['studio_payload']
    ledger=after['run'].pop('publisher_relationships')
    after['content_revision']=before['content_revision']
    value=dict(case=case,commands=a['commands'],outcome_equal=a['outcome']==b['outcome'],rng_equal=a['initial_rng']==b['initial_rng'] and a['final_rng']==b['final_rng'],all_existing_fields_equal=before==after,empty_ledger=ledger=={'version':'1','owner':before['run']['bank_run_id'],'events':[]},completed=a['ok'] and b['ok'] and a['status']==b['status']=='completed',identities=[a['source_identity'],b['source_identity']])
    checks.append(value)
    assert all(value[k] for k in ['outcome_equal','rng_equal','all_existing_fields_equal','empty_ledger','completed']),value
sim.write_json(OUT/'campaign-parity.json',dict(cases=checks,passed=True,scope='Fixed legal recipes only; no general balance or performance claim.'))
print('P1 CAMPAIGN PARITY PASS',flush=True)
