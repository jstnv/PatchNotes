"""Seal explicit source/evidence boundaries; never rewrite failed receipts."""
from pathlib import Path
import importlib.util,json,shutil,subprocess
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
HOME=Path('C:/Users/64jus/AppData/Local/Temp/pn-p4-execution-20261024-v1')
def module(name,path):
    spec=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
def main():
    sim=module('sim',ROOT/'tools/simulate.py');current=sim.source_hashes(ROOT/'patch-notes')
    regression=sim.read_json(HOME/'regression-v2/result.json')
    assert regression['pass'] and len(regression['checks'])==177
    old=sim.read_json(HOME/'regression-v2/canonical-source.json')
    delta=sorted(p for p in set(old)|set(current) if old.get(p)!=current.get(p))
    assert delta==['scripts/contracts/commission_presentation.gd','scripts/ui/how_to_play_content.gd'],delta
    # Only presentation strings may differ from the full regression source.
    for leaf in delta:
        prior=(HOME/'regression-v2/project'/leaf).read_text(encoding='utf8')
        if leaf.endswith('commission_presentation.gd'):
            for a,b in [('from20%%','from 20%%'),('cycle24','cycle 24'),('age%d','age %d'),('cycle6','cycle 6'),('Review%.1f','Review %.1f'),('/7.0','/ 7.0'),('units%d','units %d'),('/1,000','/ 1,000'),('cap100','cap 100'),('Review7.0 AND1,000','Review 7.0 AND 1,000')]:prior=prior.replace(a,b)
        else:
            prior=prior.replace('through release-age month 24','through earning cycle 24').replace('At release-age month 6','At earning cycle 6')
        assert prior==(ROOT/'patch-notes'/leaf).read_text(encoding='utf8'),leaf
    continuation=sim.read_json(HOME/'presentation-final-v1/result.json')
    assert continuation['canonical_unchanged'] and continuation['missing']==['verify_publisher_browser'] and len(continuation['checks'])==5 and all(x['pass'] for x in continuation['checks'])
    assert sim.read_json(HOME/'presentation-final-v1/canonical-source.json')==current
    browser=sim.read_json(HOME/'presentation-final-v2/result.json')
    assert browser['pass'] and [x['name'] for x in browser['checks']]==['verify_publisher_browser_states']
    assert sim.read_json(HOME/'presentation-final-v2/canonical-source.json')==current
    build=HOME/'p4-build-v1/p2-p3-export'
    assert sim.read_json(build/'source.json')==current
    package=sim.read_json(build/'pack-manifest-verified.json')
    assert package['count']==371 and package['all_payload_md5_valid'] and not package['missing_runtime_files'] and not package['unexpected_files']
    manifest=sim.read_json(build/'build-manifest.json')
    for name,meta in manifest['artifacts'].items():assert sim.sha(Path(manifest['workspace'])/'demo'/name)==meta['sha256']
    for path,sha in manifest['included'].items():assert sim.sha(ROOT/'patch-notes'/path)==sha,path
    for label in ['clean-import','export-release','headless-startup','graphical-startup']:
        receipt=sim.read_json(build/(label+'.command.json'));assert receipt['exit']==0 and not receipt['errors']
    reports={}
    for folder,leaf in [('p4-native-final-v1','native-result.json'),('p4-edges-v4','edges-result.json'),('p4-migration-v2','migration-result.json'),('p4-rejection-green-v1','rejection-result.json'),('p4-world-v7','world-result.json')]:
        report=sim.read_json(HOME/folder/leaf);assert report['failures']==0,(folder,report['failures'])
        source=sim.read_json(HOME/folder/'source.json')
        diff=sorted(p for p in set(source)|set(current) if source.get(p)!=current.get(p))
        assert diff in [[],delta],(folder,diff)
        receipt=sim.read_json(HOME/folder/'result.json');assert receipt['pass']
        reports[folder]={'checks':len(report['checks']),'failures':0,'source_delta_to_final':diff}
    for folder in ['p4-route-v4','p4-compiled-route-v1']:
        route=sim.read_json(HOME/folder/'route-result.json');assert route['pass'] and route['steps']==241 and len(route['stages'])==7
        replay=sim.read_json(HOME/folder/('fresh-process-v2' if folder=='p4-compiled-route-v1' else 'fresh-process')/'replay-result.json');assert replay['ok']
        reports[folder]={'steps':241,'boundaries':7,'fresh_process_replay':replay,'source':route['source']}
    # Source identities differ across editor/PCK, but persisted gameplay fields
    # are compared directly without dropping identity, finance or RNG fields.
    for label in ['pre-support','support-launched','first-assessed','second-launched','second-assessed','recovery-commission','third-launched']:
        assert sim.read_json(HOME/'p4-route-v4'/(label+'.json'))==sim.read_json(HOME/'p4-compiled-route-v1'/(label+'.json')),label
    original=sim.read_json(HOME/'p4-production-save-v1/production-save-result.json');assert original['pass'] and not original['support_backfill']
    reports['original_player_read_only']=original
    for folder,leaf in [('p4-compiled-world-v1','world-result.json'),('p4-compiled-native-v1','native-result.json'),('p4-compiled-edges-v1','edges-result.json'),('p4-compiled-migration-v1','migration-result.json')]:
        report=sim.read_json(HOME/folder/leaf);assert report['failures']==0
        receipt=sim.read_json(HOME/folder/'compiled.command.json');assert receipt['exit']==0 and receipt['errors']==[]
        reports[folder]={'checks':len(report['checks']),'failures':0}
    actual=sim.read_json(HOME/'p4-actual-closeout.json');assert actual['pass']
    reports['actual_exe']=actual
    sim.write_json(HERE/'source.json',current)
    helpers=[ROOT/'tools/simulate.py',ROOT/'tools/release_gate.py',ROOT/'docs/codex/findings/export-queue-v3/export.py',ROOT/'docs/codex/findings/sidestreet-p2-p3-20261023-v1/native.gd',ROOT/'patch-notes/scripts/debug/verify_campaign_live_parity.gd',ROOT/'docs/codex/threads/contracts/studies/sidestreet-commission-p1-20261023-v1/prefix_policy.gd',ROOT/'docs/codex/threads/contracts/studies/sidestreet-full-delivery-20261023-v1/policy.gd']
    sim.write_json(HERE/'helper-source.json',{str(p.relative_to(ROOT)):sim.sha(p) for p in helpers})
    baseline=sim.read_json(HOME/'pre-p4-accepted/source.json')
    sim.write_json(HERE/'adoption-delta.json',{path:{'before':baseline.get(path),'after':current.get(path)} for path in sorted(set(baseline)|set(current)) if baseline.get(path)!=current.get(path)})
    sim.write_json(HERE/'verification.json',{'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'pass':True,'release_ready':False,'full_matrix':{'checks':177,'source':str(HOME/'regression-v2'),'source_delta_to_final':delta},'final_presentation_suites':[x['name'] for x in continuation['checks']+browser['checks']],'reports':reports})
    # Inventory compact receipts/captures plus bulky tape hashes, without
    # enumerating import caches/profiles or copying those into OneDrive.
    files=[]
    for folder in [*reports,'regression-v1','regression-v2','presentation-final-v1','presentation-final-v2','p4-rejection-red-v1','p4-migration-v1','p4-native-v1','p4-world-v1','p4-world-v2','p4-world-v3','p4-world-v4','p4-world-v5','p4-world-v6','actual-p4-1152','actual-p4-cold-1152','actual-p4-cold-1280','p4-compiled-reference-v1','p4-compiled-seed-v1','p4-production-save-v1']:
        directory=HOME/folder
        if directory.is_dir():
            files += [p for p in directory.iterdir() if p.is_file() and p.suffix in {'.json','.log','.gd','.png'}]
            for nested in ['fresh-process','fresh-process-v2']:
                files += [p for p in (directory/nested).glob('*') if p.suffix in {'.json','.log','.gd'}]
    files += [HOME/'p4-actual-closeout.json',*build.glob('*.json'),*build.glob('*.log')]
    sim.write_json(HERE/'external-artifacts.json',{str(p):{'sha256':sim.sha(p),'bytes':p.stat().st_size} for p in sorted(set(files)) if p.exists()})
    for folder,label in [('p4-native-final-v1','support-quote-1152'),('p4-native-final-v1','support-result-1280'),('p4-native-final-v1','support-sales-1280')]:
        shutil.copy2(HOME/folder/(label+'.png'),HERE/(label+'.png'))
    for folder,label in [('actual-p4-1152','support-earned-recoup-1152'),('actual-p4-1152','support-funding-finance-1152'),('actual-p4-cold-1280','support-cold-1280')]:
        shutil.copy2(HOME/folder/(label+'.png'),HERE/(label+'.png'))
    print(json.dumps({'pass':True,'matrix':177,'final_presentation_suites':6,'source_delta':delta,'reports':list(reports),'release_ready':False}),flush=True)
if __name__=='__main__':main()
