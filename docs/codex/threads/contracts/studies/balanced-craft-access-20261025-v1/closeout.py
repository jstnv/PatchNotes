from run import *
analysis=load(HERE/'analysis.json')
checks={}
for row in analysis['cases']:
    p=RAW/'baseline/cases'/row['case']/'studio_checkpoint.json'
    state=load(p)['studio_payload']['run']
    assert int(state['founding_roster_version'])==3
    unlocked={x['key']:x['value'] for x in state['unlocked_publishers']}
    assert not unlocked.get('crown_quill',False)
checks['all_32_roster_version3_and_Crown_locked']='PASS'
for cid in analysis['representative_replays']:
    r=load(RAW/('replay-'+cid)/'run-report.json')
    assert r['ok'] and r['replay']['ok'] and r['replay']['telemetry_verified']
    checks['replay-'+cid]=dict(ok=True,steps=len(r['replay']['steps']),telemetry_samples=r['replay']['telemetry_samples'])
prior=load(RAW/'baseline/cases'/analysis['continuation_case']/'result.json')
continued=load(RAW/'continuation/cases/cold-continue/result.json')
assert continued['initial_state']==prior['final_state']
assert continued['initial_rng']==prior['final_rng']
assert continued['status']=='completed' and continued['final_release_count']==5
checks['cold_continue']=dict(ok=True,exact_initial_state_rng=True,commands=continued['commands'],final_release_count=5,final_run_cycle=continued['final_run_cycle'])
sys.path.insert(0,str(ROOT/'tools'))
import simulator_variant as sv
meta,base,current,integrity=sv.load_variant(VAR)
assert base==current
checks['variant_zero_gameplay_delta']='PASS'
canonical=sv.sim.source_hashes(ROOT/'patch-notes')
drift=sv.delta(current,canonical)
manifest=load(HERE/'evidence-manifest.json')
for p in list(HERE.glob('*-command.json'))+list(HERE.glob('*-exit.json'))+list(HERE.glob('*-driver.log')):
    manifest[str(p)]=hashlib.sha256(p.read_bytes()).hexdigest()
for folder in [RAW/'baseline',RAW/'continuation',*[RAW/('replay-'+c) for c in analysis['representative_replays']]]:
    for p in folder.glob('*.json'):
        manifest[str(p)]=hashlib.sha256(p.read_bytes()).hexdigest()
    for p in folder.glob('*.log'):
        manifest[str(p)]=hashlib.sha256(p.read_bytes()).hexdigest()
write(HERE/'evidence-manifest.json',manifest)
write(HERE/'closeout.json',dict(checks=checks,variant=meta,canonical_drift=drift,source_identity=prior['source_identity'],reduction='NOT APPLICABLE: no rejected cases'))
print(json.dumps(checks,indent=2))
