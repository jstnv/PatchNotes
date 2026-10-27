"""Reconcile fresh runs without relabeling their failed or interrupted records."""
from pathlib import Path
import hashlib,importlib.util,json,re,subprocess
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
TEMP=Path('C:/Users/64jus/AppData/Local/Temp')
def read(path):return json.loads(path.read_text(encoding='utf8'))
def module(name,path):
    spec=importlib.util.spec_from_file_location(name,path);result=importlib.util.module_from_spec(spec);spec.loader.exec_module(result);return result
def main():
    sim=module('audit_sim',ROOT/'tools/simulate.py');gate=module('audit_gate',ROOT/'tools/release_gate.py')
    selection=read(HERE/'selection.json');current=sim.source_hashes(ROOT/'patch-notes')
    # The continuation intentionally predates four later test corrections.
    # Validate both phase deltas and the final complete snapshot below.
    initial=Path(selection['first']);fixed=Path(selection['affected']);continued=Path(selection['continuation'])
    last=read(continued/'result.json');assert len(last['checks'])==len(selection['pending']) and not last['missing']
    assert read(continued/'canonical-source.json')==selection['source_fence']
    final=TEMP/'pn-overnight-20261024-final-fixes-v4'
    final_result=read(final/'result.json');assert final_result['pass'] and final_result['canonical_unchanged']
    assert read(final/'canonical-source.json')==current
    final_names={row['name'] for row in final_result['checks']}
    assert final_names=={'verify_gameplay_tree','verify_queue_source_migration','verify_sidestreet_contract','verify_simulation_efficiency'}
    assert {row['name'] for row in last['checks'] if not row['pass']}==final_names
    final_delta={'scripts/debug/'+name+'.gd' for name in final_names}
    assert {p for p in set(current)|set(selection['source_fence']) if current.get(p)!=selection['source_fence'].get(p)}==final_delta
    old=read(initial/'canonical-source.json')
    changed_project=set(selection['only_project_changes'])|final_delta
    assert {k for k in set(old)|set(current) if old.get(k)!=current.get(k)}==changed_project
    assert all(current[k]==v for k,v in old.items() if not k.startswith('scripts/debug/'))
    scripts={p.stem:p.read_text(encoding='utf8') for p in (ROOT/'patch-notes/scripts/debug').glob('verify_*.gd')}
    dependencies={name for name,text in scripts.items() if 'version7_oracle_digest(' in text}
    while True:
        expanded=set(dependencies)
        for name,text in scripts.items():
            parent=re.search(r'^extends "res://scripts/debug/([^"/]+)\.gd"',text,re.M)
            if parent and parent.group(1) in dependencies:expanded.add(name)
        if expanded==dependencies:break
        dependencies=expanded
    assert dependencies==set(selection['retained_fixed_dependency_closure']),dependencies
    results={}
    for folder,names in [(initial,selection['retained_unchanged']),(fixed,selection['retained_fixed_dependency_closure']),(continued,set(selection['pending'])-final_names),(final,final_names)]:
        rows={item['name']:item for item in read(folder/'result.json')['checks']}
        for name in names:
            assert rows[name]['pass'],name
            command=read(folder/(name+'.command.json'))
            assert command['exit']==0 and not command['errors'],name
            assert current['scripts/debug/'+Path(rows[name]['wrapper']['original']).name]==rows[name]['wrapper']['original_sha256']
            assert name not in results
            results[name]={'bundle':str(folder),'command_sha256':sim.sha(folder/(name+'.command.json')),'log_sha256':sim.sha(folder/(name+'.log'))}
    assert set(results)=={name for name,path in gate.verifier_jobs()} and len(results)==175
    creation=read(ROOT/'docs/codex/threads/contracts/simulators/publisher-p4-current-preflight-v1/creation-manifest.json')
    fixtures=[k for k in creation if k.startswith('scripts/debug/fixtures/') and k.endswith('oracle_digests.json')]
    assert len(fixtures)==4 and all(current[k]==creation[k] for k in fixtures)
    record=TEMP/'pn-overnight-new-game-20261024-v1';replay=TEMP/'pn-overnight-new-game-replay-20261024-v1'
    case=read(record/'cases/sports-1112/result.json');prior=read(TEMP/'pn-sidestreet-canonical-20261023-v5/prefix/cases/sports-1112/result.json')
    same=['initial_state','final_state','initial_rng','final_rng','commands','final_run_cycle','final_release_count','source_identity']
    assert case['ok'] and case['commands']==98 and case['final_run_cycle']==42 and case['final_release_count']==4
    assert all(case[k]==prior[k] for k in same)
    replay_result=read(replay/'run-report.json')['replay']
    assert replay_result['ok'] and len(replay_result['steps'])==98 and all(r['accepted'] for r in replay_result['steps'])
    assert replay_result['final_state']==case['final_state'] and replay_result['telemetry_verified'] and replay_result['telemetry_samples']==99
    assert read(HERE/'chooser-mutation.json')['pass']
    build=read(ROOT/'docs/codex/findings/sidestreet-p2-p3-20261023-v1/build-manifest.json')
    assert all(sim.sha(ROOT/'patch-notes'/k)==v for k,v in build['included'].items())
    assert all(sim.sha(ROOT/'patch-notes'/k)==v for k,v in build.get('import_settings',{}).items())
    assert all(sim.sha(Path(build['workspace'])/'demo'/k)==v['sha256'] for k,v in build['artifacts'].items())
    intake=read(HERE/'intake.json');assert intake['canonical_runtime_source']==current and intake['historical_packet_seals_verified']==13
    packet=ROOT/'docs/codex/threads/contracts/handoffs/publisher-support-renewal-20261023-v1'
    assert all(sim.sha(packet/k)==v for k,v in read(packet/'handoff-integrity.json').items())
    sim.write_json(HERE/'source.json',current)
    sim.write_json(HERE/'suite-evidence.json',results)
    sim.write_json(HERE/'campaign.json',{'record':str(record),'replay':str(replay),'commands':98,'productive_cycle':42,'releases':4,'replay_steps':98,'telemetry_samples':99,'previous_prefix_exact_fields':same,'source_identity':case['source_identity'],'final_state':case['final_state'],'rng_exact':True})
    result={'pass':True,'head':intake['head'],'canonical_source_identity':intake['source_identity'],'gameplay_bytes_unchanged':True,'changed_project_paths':sorted(changed_project),'maintained_suites':175,'retained_unchanged':len(selection['retained_unchanged']),'affected_dependency_closure':len(selection['retained_fixed_dependency_closure']),'continued_unchanged':len(selection['pending'])-len(final_names),'final_corrective_suites':len(final_names),'cult_checks':215,'fresh_campaign_commands':98,'fresh_replay_steps':98,'new_game_releases':4,'p4':'APPROVED / DEPENDENCY BLOCKED; intake complete, canonical mechanics not implemented','exe_interaction':'BLOCKED; original game writer/access preserved','existing_export_inputs_and_binary_hashes_match':True,'fresh_export_performed':False,'commit_push':False,'release_ready':False}
    sim.write_json(HERE/'audit.json',result);print(json.dumps(result),flush=True)
if __name__=='__main__':main()
