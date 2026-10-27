"""Fence final runtime, seals, bounded evidence, export and original disk bytes."""
from pathlib import Path
import hashlib,importlib.util,json,shutil,subprocess
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
HOME=Path('C:/Users/64jus/AppData/Local/Temp/pn-sidestreet-canonical-20261023-v5')
def read(path):return json.loads(path.read_text(encoding='utf8'))
def main():
    spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py');sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
    source=sim.source_hashes(ROOT/'patch-notes');frozen=sim.source_hashes(HOME/'prefix/project')
    assert all(source.get(k)==v for k,v in frozen.items() if not k.startswith('scripts/debug/'))
    before=read(Path('C:/Users/64jus/AppData/Local/Temp/pn-sidestreet-adoption-20261023-v1/baseline-source.json'))
    delta={k:{'before':before.get(k),'after':source.get(k)} for k in sorted(set(before)|set(source)) if before.get(k)!=source.get(k)}
    sim.write_json(HERE/'final-source.json',source);sim.write_json(HERE/'source-delta.json',delta)
    packet=ROOT/'docs/codex/threads/contracts/handoffs/sidestreet-p2-p3-20261023-v2'
    seals=read(packet/'handoff-integrity.json');assert all(sim.sha(packet/k)==v for k,v in seals.items())
    assert read(HOME/'analysis.json')['failures']==0
    for group,count in [('replays',6),('audits',10)]:
        rows=read(HOME/group/'summary.json');assert len(rows)==count and all(row['pass'] for row in rows)
    first=read(HOME/'focused-final/result.json');second=read(HOME/'focused-ui/result.json')
    assert len(first['checks'])==28 and all(c['pass'] for c in first['checks']) and first['missing']==['verify_rival_world']
    assert second['pass'] and len(second['checks'])==8
    suites={c['name'] for c in first['checks']+second['checks']};assert len(suites)==36 and 'verify_rival_world_foundation' in suites
    native=['native-1152-v3','native-1280','compiled-1152','compiled-1280','compiled-1152-v2']
    focused=['transactions-final','boundaries-final','p1_matrix-final','compiled-p1_matrix-v2','world-operator','compiled-world']
    for tag in native+focused:assert read(HOME/tag/'result.json')['failures']==0,tag
    assert read(HOME/'cold-matrix-result.json')['pass']
    cold=[];disk=[]
    for folder in HOME.iterdir():
        result=folder/'result.json'
        if folder.name.startswith('cold-') and result.is_file() and read(result).get('failures')==0:
            old=read(folder/'original.json');assert sim.sha(Path(old['source']))==old['sha256']==sim.sha(Path(old['destination']))
            cold.append(folder.name)
        if folder.name.startswith('disk-') and result.is_file():assert read(result)['pass'];disk.append(folder.name)
    assert len(cold)==20,(len(cold),cold)
    build=read(HOME/'export-v4/build-manifest.json')
    assert all(sim.sha(ROOT/'patch-notes'/k)==v for k,v in build['included'].items())
    assert all(sim.sha(ROOT/'patch-notes'/k)==v for k,v in build.get('import_settings',{}).items())
    assert read(HOME/'export-v4/pack-manifest-verified.json')['count']==359
    for kind in ['headless','graphical']:
        result=read(HOME/'export-v4'/(kind+'-startup.command.json'));assert result['exit']==0 and not result['errors']
    for name,metadata in build['artifacts'].items():assert sim.sha(Path(build['workspace'])/'demo'/name)==metadata['sha256']
    assert read(HOME/'actual-exe-v2/ui-result.json')['status']=='BLOCKED' and read(HOME/'actual-exe-v2/exit.json')['exit']==0 and read(HOME/'actual-exe-v2/exit.json')['original_generation_preserved']
    for relative in delta:
        path=ROOT/'patch-notes'/relative
        if path.suffix in {'.gd','.uid'} and path.exists():
            assert not any(line.rstrip()!=line for line in path.read_text(encoding='utf8').splitlines()),relative
    whitespace=subprocess.run(['git','-c','core.whitespace=cr-at-eol','diff','--check','--',*[str(Path('patch-notes')/k) for k in delta]],cwd=ROOT,capture_output=True)
    assert whitespace.returncode==0,whitespace.stdout.decode(errors='replace')
    summaries={'analysis':read(HOME/'analysis.json'),'maintained':{'passed_suites':sorted(suites),'count':len(suites),'scope':'36 affected suites across two frozen runs; first runner had a nonexistent name, corrected by actual foundation check in second run; not a full release gate'},'native':{tag:{k:v for k,v in read(HOME/tag/'result.json').items() if k!='traces'} for tag in native},'focused':{tag:read(HOME/tag/'result.json') for tag in focused},'cold_pass':cold,'disk_pass':disk,'exe_interaction':read(HOME/'actual-exe-v2/ui-result.json')}
    sim.write_json(HERE/'verification.json',summaries)
    for name in ['build-manifest.json','pack-manifest-verified.json']:shutil.copy2(HOME/'export-v4'/name,HERE/name)
    pictures={'compiled-quote-1152.png':HOME/'compiled-1152-v2/quote-1152.png','compiled-result-1280.png':HOME/'compiled-1280/commission-result-1280.png','brief-1152.png':HOME/'native-1152-v3/brief-1152.png','market-1152.png':HOME/'compiled-1152-v2/market-1152.png','writer-busy-exe.png':HOME/'actual-exe-v2/writer-busy.png','partial-1280.png':HOME/'cold-compiled-partial-1280/result.json.png','zero-1280.png':HOME/'cold-compiled-zero-1280/result.json.png'}
    for name,path in pictures.items():shutil.copy2(path,HERE/name)
    skip={'project','source','profile','profiles','import-profile','APPDATA','LOCALAPPDATA','TMP','TEMP','TMPDIR','HOME','USERPROFILE','XDG_DATA_HOME','XDG_CONFIG_HOME','XDG_CACHE_HOME','template-cache','.godot'}
    artifacts={}
    for path in HOME.rglob('*'):
        rel=path.relative_to(HOME)
        if not path.is_file() or any(part in skip or part.startswith('patch-notes-demo-') for part in rel.parts):continue
        if path.suffix in {'.json','.log','.gd','.png'}:artifacts[rel.as_posix()]={'bytes':path.stat().st_size,'sha256':sim.sha(path)}
    sim.write_json(HERE/'external-artifacts.json',{'root':str(HOME),'files':artifacts,'scope':'Raw caches/profiles/build binaries stay outside the synced checkout; key logs, commands, tapes, reports and captures are pinned here.'})
    result={'pass':True,'branch':subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip(),'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'source_paths_changed':len(delta),'sealed_packet_files_unchanged':len(seals),'maintained_suites':36,'analysis_checks':224,'fresh_replays':6,'focused_audit_jobs':10,'native_routes':len(native),'cold_processes':len(cold),'disk_writers':len(disk),'scoped_whitespace_exit':whitespace.returncode,'canonical_source_manifest_identity':hashlib.sha256(json.dumps(source,sort_keys=True).encode()).hexdigest(),'editor_mechanics':read(HOME/'native-1152-v3/result.json')['source'],'compiled_mechanics':read(HOME/'compiled-1152-v2/result.json')['source'],'actual_exe_continue':'BLOCKED: another running game owns production save writer62741; isolated actual EXE showed recovery and exited0, original bytes preserved','commit_or_push_performed':False,'release_ready':False}
    sim.write_json(HERE/'final-audit.json',result);print(json.dumps(result),flush=True)
if __name__=='__main__':main()
