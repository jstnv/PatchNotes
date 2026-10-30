from run import *
from collections import Counter
sys.path.insert(0,str(ROOT/'tools'));import simulator_variant as sv;import compare_simulations as cp
a=load(HERE/'analysis.json');assert a['status']=='PASS'
for name,digest in load(HERE/'policy-pins.json').items():assert sha(HERE/name)==digest,name
meta,base,current,integrity=sv.load_variant(VAR);_,pb,pc,_=sv.load_variant(PARENT)
assert current==pc and base==pb
assert sv.identity(current)==load(HERE/'intake.json')['candidate']
replays=[]
for cid in load(HERE/'replay-selection.json')['cases']:
    r=load(RAW/('replay-'+cid)/'run-report.json');assert r['ok'] and r['replay']['telemetry_verified']
    replays.append(dict(case=cid,commands=len(r['replay']['steps']),samples=r['replay']['telemetry_samples']))
selection=load(HERE/'cold-selection.json');original=load(RAW/selection['source_batch']/'cases'/selection['source_case']/'result.json')
context=cp.load_bundle(RAW/'cold');cold=cp.load_case(RAW/'cold',context,'cold-next')['result']
assert cold['ok'] and cold['initial_state']==original['final_state'] and cold['initial_rng']==original['final_rng']
assert cold['commands']<=80 and cold['commands']==cold['accepted_commands'] and cold['final_release_count']==original['final_release_count']+1
assert context['source_identity']==a['source_identity']
old=load(PRIOR/'closeout.json');assert old['candidate_identity']==sv.identity(current) and old['source_identity']==a['source_identity']
warnings=Counter();files={}
for folder in RAW.iterdir():
    if not folder.is_dir():continue
    for p in folder.iterdir():
        if p.is_file() and p.suffix in ['.json','.log','.patch']:files[p.relative_to(RAW).as_posix()]=sha(p)
        if p.is_file() and p.suffix=='.log':
            for line in p.read_text(encoding='utf-8',errors='replace').splitlines():
                if line.startswith(('WARNING:','SCRIPT ERROR:','ERROR:')):warnings[line]+=1
    for sub in ['cases','inputs','profile']:
        for p in (folder/sub).rglob('*.json'):files[p.relative_to(RAW).as_posix()]=sha(p)
write(HERE/'evidence-manifest.json',dict(raw_root=str(RAW),files=files,warnings=dict(warnings)))
commands=[]
for p in sorted(HERE.glob('*-command.json')):
    exitfile=p.with_name(p.name.replace('-command','-exit'));commands.append(dict(name=p.name,command=load(p),result=load(exitfile) if exitfile.exists() else None))
canonical=sv.sim.source_hashes(ROOT/'patch-notes')
record=dict(status='PASS',head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),branch=subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),candidate_identity=sv.identity(current),source_identity=a['source_identity'],parent_project_exact=True,base_identity=sv.identity(base),variant=meta,canonical_drift=sv.delta(base,canonical),checks=a['checks'],replays=replays,cold=dict(source_case=selection['source_case'],exact_state=True,exact_rng=True,commands=cold['commands'],releases=cold['final_release_count'],cycle=cold['final_run_cycle']),reused_suites=old['suites'],fresh_suite_runs=0,evidence_files=len(files),warnings=dict(warnings),commands=commands,rejected_cases=sum(not r['ok'] for r in a['rows']),timeouts=sum(c['result'] is None or c['result']['exit_code']!=0 for c in commands))
write(HERE/'closeout.json',record)
print(json.dumps({k:v for k,v in record.items() if k not in ['variant','commands','canonical_drift']},indent=2))
