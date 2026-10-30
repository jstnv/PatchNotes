from setup import HERE,ROOT,VAR,RAW,PAIRS,sha,write
import json,sys,collections
sys.path.insert(0,str(ROOT/'tools'))
import simulator_variant as variants
import compare_simulations as comparison
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))

def main():
    meta,base,current,integrity=variants.load_variant(VAR);delta=variants.delta(base,current)
    assert len(delta)==1 and delta[0]['path']=='scripts/debug/crown_access_legacy_v1.gd'
    pins=load(HERE/'source-pins.json')
    assert variants.identity(current)==pins['candidate_identity'] and sha(HERE/'policy.gd')==pins['policy_sha256']
    assert sha(HERE.parents[1]/'CROWN-FIRST-BETA-PLAN-2026-10-24-v1.md')==pins['plan_sha256']
    a=load(HERE/'analysis.json');p=load(HERE/'policy-audit.json')
    assert a['complete'] and p['complete'] and len(a['rows'])==6
    checks={'variant_protected':True,'policy_plan_unchanged':True,'candidate_identity':variants.identity(current),'delta':delta,'replays':[]}
    selections=load(HERE/'verification-selection.json')
    for s in selections:
        replay=load(RAW/s['folder']/'run-report.json');original=load(RAW/s['pair']/'cases'/s['case']/'result.json')
        assert replay['ok'] and replay['replay']['telemetry_verified']
        assert len(replay['replay']['steps'])==original['commands'] and replay['replay']['telemetry_samples']==original['commands']+1
        checks['replays'].append(s|{'commands':original['commands'],'samples':replay['replay']['telemetry_samples'],'exact':True})
    s=next(s for s in selections if s['original_ok'])
    original=load(RAW/s['pair']/'cases'/s['case']/'result.json');cold=load(RAW/'cold/cases/first-cold-next/result.json')
    context=comparison.load_bundle(RAW/'cold');comparison.load_case(RAW/'cold',context,'first-cold-next')
    assert context['source_identity']==a['identities'][0]['source'] and cold['initial_state']==original['final_state'] and cold['initial_rng']==original['final_rng']
    assert cold['ok'] and cold['final_release_count']==7 and cold['commands']<=80
    checks['cold']={'state_rng_exact':True,'commands':cold['commands'],'releases':cold['final_release_count'],'cycle':cold['final_run_cycle']}
    write(HERE/'verification.json',checks)
    files={};warnings=collections.Counter()
    for folder in RAW.iterdir():
        if not folder.is_dir():continue
        for path in folder.iterdir():
            if path.is_file() and path.suffix in ['.json','.log','.patch','.py']:
                files[path.relative_to(RAW).as_posix()]=sha(path)
                if path.suffix=='.log':
                    for line in path.read_text(encoding='utf-8-sig',errors='replace').splitlines():
                        if line.startswith(('WARNING:','ERROR:','SCRIPT ERROR:')):warnings[line]+=1
        for sub in ['cases','inputs','reduced']:
            for path in (folder/sub).rglob('*.json'):files[path.relative_to(RAW).as_posix()]=sha(path)
        for path in (folder/'profile').rglob('godot.log'):
            files[path.relative_to(RAW).as_posix()]=sha(path)
            for line in path.read_text(encoding='utf-8-sig',errors='replace').splitlines():
                if line.startswith(('WARNING:','ERROR:','SCRIPT ERROR:')):warnings[line]+=1
    write(HERE/'evidence-manifest.json',{'root':str(RAW),'files':files,'warnings':dict(warnings),'canonical_drift':variants.delta(base,variants.sim.source_hashes(ROOT/'patch-notes')),'variant_delta':delta})
    print(json.dumps({'status':'PASS','replays':checks['replays'],'cold':checks['cold'],'artifact_hashes':len(files),'warnings':dict(warnings)}))

if __name__=='__main__':main()
