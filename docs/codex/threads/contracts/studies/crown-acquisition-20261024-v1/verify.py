from setup import HERE, ROOT, VAR, RAW, write
from pathlib import Path
import json, hashlib, sys, collections
sys.path.insert(0,str(ROOT/'tools'))
import simulator_variant as variants
import compare_simulations as comparison
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()

def main():
    meta,base,current,integrity=variants.load_variant(VAR)
    delta=variants.delta(base,current)
    assert len(delta)==1 and delta[0]['path']=='scripts/debug/crown_access_legacy_v1.gd' and delta[0]['change']=='added'
    checks={'variant_protected_and_only_helper_delta':True,'variant_base':meta['base_identity'],'variant_candidate':variants.identity(current),'variant_delta':delta,'protected_integrity':integrity}
    analysis=load(HERE/'analysis.json')
    assert analysis['complete'] and len(analysis['rows'])==12
    checks['all_declared_cases_audited']=True
    replay=load(RAW/'replay/run-report.json')
    checks['replay_ok']=replay['ok']
    checks['replay_commands']=len(replay['replay']['steps'])
    checks['replay_telemetry_samples']=replay['replay']['telemetry_samples']
    checks['replay_telemetry_verified']=replay['replay']['telemetry_verified']
    selected=load(HERE/'verification-selection.json')
    original=load(RAW/selected['pair']/'cases'/selected['case']/'result.json')
    assert checks['replay_commands']==original['commands'] and checks['replay_telemetry_samples']==original['commands']+1 and checks['replay_telemetry_verified']
    cold=load(RAW/'cold/cases/acquisition-cold-next/result.json')
    context=comparison.load_bundle(RAW/'cold')
    comparison.load_case(RAW/'cold',context,'acquisition-cold-next')
    assert context['source_identity']==analysis['identities'][0]['source']
    checks['cold_ok']=cold['ok']
    checks['cold_state_match']=cold['initial_state']==original['final_state']
    checks['cold_rng_match']=cold['initial_rng']==original['final_rng']
    checks['cold_commands']=cold['commands'];checks['cold_releases']=cold['final_release_count'];checks['cold_cycle']=cold['final_run_cycle']
    assert all(checks[k] for k in ['replay_ok','cold_ok','cold_state_match','cold_rng_match'])
    assert cold['final_release_count']==7
    write(HERE/'verification.json',checks)
    files={};warnings=collections.Counter()
    for folder in sorted(RAW.iterdir()):
        if not folder.is_dir():continue
        for p in sorted(folder.iterdir()):
            if p.is_file() and p.suffix in ['.json','.log','.patch']:files[p.relative_to(RAW).as_posix()]=sha(p)
            if p.is_file() and p.suffix=='.log':
                for line in p.read_text(encoding='utf-8-sig',errors='replace').splitlines():
                    if line.startswith(('WARNING:','ERROR:','SCRIPT ERROR:')):warnings[line]+=1
        for sub in ['cases','inputs','reduced']:
            for p in sorted((folder/sub).rglob('*.json')):files[p.relative_to(RAW).as_posix()]=sha(p)
    canonical=variants.sim.source_hashes(ROOT/'patch-notes')
    write(HERE/'evidence-manifest.json',{'status':'PASS','root':str(RAW),'files':files,'warnings':dict(warnings),'canonical_drift_at_closeout':variants.delta(base,canonical),'base':meta['base_identity'],'candidate':variants.identity(current),'delta':delta})
    print(json.dumps({'status':'PASS','evidence_files':len(files),'checks':analysis['checks'],'replay_ok':checks['replay_ok'],'cold_state_rng_exact':checks['cold_state_match'] and checks['cold_rng_match'],'canonical_drift':[d['path'] for d in variants.delta(base,canonical)]}))

if __name__=='__main__':main()
