from run import *
from collections import Counter
sys.path.insert(0,str(ROOT/'tools'))
import simulator_variant as sv
import compare_simulations as comparison
analysis=load(HERE/'analysis.json');witness=load(HERE/'witness-analysis.json')
assert analysis['all_cases_complete'] and witness['all_cases_complete']
assert analysis['source']==witness['source']
checks=[]
for name in ['replay-balanced-4521','replay-completion-4521','replay-skip-4521','replay-full-witness']:
    report=load(RAW/name/'run-report.json')
    assert report['ok'] and report['replay']['telemetry_verified'],name
    checks.append(dict(name=name,commands=len(report['replay']['steps']),samples=report['replay']['telemetry_samples']))
cold=load(RAW/'cold/cases/cold-next/result.json')
original=load(RAW/'branches-4521/cases/balanced-4521/result.json')
assert cold['ok'] and cold['initial_state']==original['final_state'] and cold['initial_rng']==original['final_rng']
context=comparison.load_bundle(RAW/'cold')
# Cold continuation is not a paired-study arm; validate its artifact contract directly.
assert cold==context['summary']['results'][0]
assert load(RAW/'cold/cases/cold-next/case.json')==context['config']['cases'][0]
telemetry=RAW/'cold/cases/cold-next'/cold['artifacts']['telemetry']
assert sha(telemetry)==cold['telemetry_sha256']
comparison.validate_samples(load(telemetry),cold)
assert context['source_identity']==analysis['source']
suites=load(HERE/'focused-checks.json');assert suites['source_unchanged'] and all(s['ok'] for s in suites['suites'])
meta,base,current,integrity=sv.load_variant(VAR)
pins=load(HERE/'candidate-pins.json')
assert sv.identity(current)==pins['identity']
assert sha(HERE/'PLAN.md')==pins['plan']
assert sha(HERE/'policy.gd')==load(HERE/'policy-pins.json')['policy']
for k,f in [('policy','witness.gd'),('config','witness.json'),('plan','FULL-WITNESS-ADDENDUM.md')]:assert sha(HERE/f)==load(HERE/'witness-pins.json')[k]
canonical=sv.sim.source_hashes(ROOT/'patch-notes')
drift=sv.delta(base,canonical)
# Full witness final-hand selection is independently audited; also retain its observed proof.
full=[dict(case=r['case'],result=x) for r in witness['rows'] for x in r['results'] if x['grade']==10000]
files={};warnings=Counter()
for folder in RAW.iterdir():
    if not folder.is_dir():continue
    for p in folder.iterdir():
        if p.is_file() and p.suffix in ['.json','.log','.patch']:files[p.relative_to(RAW).as_posix()]=sha(p)
        if p.is_file() and p.suffix=='.log':
            for line in p.read_text(errors='replace').splitlines():
                if line.startswith(('WARNING:','SCRIPT ERROR:','ERROR:')):warnings[line]+=1
    for sub in ['cases','inputs','profile']:
        for p in (folder/sub).rglob('*.json'):files[p.relative_to(RAW).as_posix()]=sha(p)
for p in (RAW/'focused-checks').rglob('check.*'):files[p.relative_to(RAW).as_posix()]=sha(p)
write(HERE/'evidence-manifest.json',dict(raw_root=str(RAW),files=files,warnings=dict(warnings)))
record=dict(status='PASS',head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),branch=subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),variant=meta,candidate_identity=sv.identity(current),source_identity=analysis['source'],delta=sv.delta(base,current),canonical_drift=drift,main_checks=analysis['checks'],witness_checks=witness['checks'],replays=checks,cold=dict(exact_state=True,exact_rng=True,commands=cold['commands'],releases=cold['final_release_count'],cycle=cold['final_run_cycle']),suites=[s['suite'] for s in suites['suites']],full_witnesses=full,evidence_files=len(files),warnings=dict(warnings),rejected_cases=0,timeouts=0)
write(HERE/'closeout.json',record)
print(json.dumps({k:v for k,v in record.items() if k not in ['variant','delta','full_witnesses']},indent=2))
