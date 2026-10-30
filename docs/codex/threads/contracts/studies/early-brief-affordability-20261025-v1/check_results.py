from run import *
sys.path.insert(0,str(ROOT/'tools'));import simulator_variant as variant
a=load(HERE/'analysis.json');selected=load(HERE/'verification-selection.json')
assert len(a['rows'])==12 and len(a['prefixes'])==6 and a['matched_pairs']==6
records={};manifest=load(HERE/'evidence-manifest.json')
for row in load(HERE/'cross-checks.json'):
    r=load(Path(row['receipt']));assert row['ok'] and r['ok'] and r['all_other_final_state_and_rng_exact']
    records['cross-'+row['route']]=r
for cid in selected['replays']+load(HERE/'verification-addendum.json')['replays']:
    folder=RAW/('replay-'+cid);r=load(folder/'replay-report.json');assert r['ok'] and load(folder/'run-report.json')['ok']
    row=next(x for x in a['rows'] if x['case']==cid);original=load(RAW/('branches-'+row['group'])/'cases'/cid/'result.json')
    assert len(r['steps'])==row['commands'] and r['final_state']==original['final_state']
    records['replay-'+cid]=dict(ok=True,commands=len(r['steps']),final_state_exact=True)
r=load(RAW/'structural/receipt.json');assert load(HERE/'structural.json')['ok'] and r['checks']==32 and r['failures']==0
records['structural']=r
cold=load(RAW/'cold/cases/early-brief-cold/result.json');origin=load(HERE/'cold-source.json')
base=load(RAW/('branches-'+origin['group'])/'cases'/origin['case']/'result.json')
assert load(RAW/'cold/run-report.json')['ok'] and cold['status']=='completed'
assert cold['initial_state']==base['final_state'] and cold['initial_rng']==base['final_rng']
assert cold['final_release_count']==base['final_release_count']+1
records['cold']=dict(status=cold['status'],commands=cold['commands'],initial_state_rng_exact=True,releases=cold['final_release_count'],excluded_from_measured_comparison=True)
source('source-after');before=load(HERE/'source-before.json');after=load(HERE/'source-after.json');pins=load(HERE/'policy-pin.json')
for name,args in [('status',['git','status','--short']),('diff',['git','diff','--stat']),('head',['git','rev-parse','HEAD']),('branch',['git','branch','--show-current'])]:
    result=subprocess.run(args,cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace');assert result.returncode==0
    (HERE/(name+'-after.txt')).write_text(result.stdout,encoding='utf-8')
assert before['candidate']==after['candidate'] and before['parent']==after['parent']
assert hashlib.sha256((HERE/'PLAN.md').read_bytes()).hexdigest()==pins['plan_sha256']
assert hashlib.sha256((HERE/'policy.gd').read_bytes()).hexdigest()==pins['brief_policy_sha256']
diagnostics=[]
for folder in sorted(RAW.iterdir()):
    if not folder.is_dir():continue
    for p in sorted(folder.glob('*.log')):
        messages=[x for x in p.read_text(encoding='utf-8',errors='replace').splitlines() if any(key in x for key in ['WARNING:','ERROR:','SCRIPT ERROR:'])]
        diagnostics.append(dict(file=str(p),messages=messages))
    for p in folder.glob('*.json'):manifest[str(p)]=hashlib.sha256(p.read_bytes()).hexdigest()
    for p in folder.glob('cases/*/*.json'):manifest[str(p)]=hashlib.sha256(p.read_bytes()).hexdigest()
for p in HERE.glob('*-command.json'):manifest[str(p)]=hashlib.sha256(p.read_bytes()).hexdigest()
failed_setup=load(RAW/'prefix-puzzle-a/run-report.json')
assert not failed_setup['ok'] and failed_setup['error']=='Canonical source changed while recording drift; retry in a new output'
out=dict(status='PASS_WITH_RETAINED_SETUP_FAILURE',receipts=records,paired_start_state_rng_checks=6,independent_brief_formula_checks=sum(len(r['briefs']) for r in a['rows']),frozen_candidate_unchanged=True,policy_and_plan_unchanged=True,canonical_delta_during_study=variant.delta(before['canonical'],after['canonical']),retained_setup_failure=failed_setup['error'],failure_reduction=selected['reduction'],diagnostics=diagnostics)
write(HERE/'verification.json',out);write(HERE/'evidence-manifest.json',manifest)
print(json.dumps({k:v for k,v in out.items() if k not in ['receipts','diagnostics']}))
