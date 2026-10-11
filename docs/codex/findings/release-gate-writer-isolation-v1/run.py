from pathlib import Path
import hashlib,json,os,sys,socket,subprocess,importlib.util
H=Path(__file__).resolve().parent;ROOT=H.parents[3];PROJECT=ROOT/'patch-notes'
GODOT=Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')
def load(name,path):
    spec=importlib.util.spec_from_file_location(name,path);module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module
def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def write(path,obj):Path(path).write_text(json.dumps(obj,indent=2)+'\n',encoding='utf8')
def capture():
    files=[PROJECT/'project.godot']+list((PROJECT/'scripts').rglob('*.gd'))+list((PROJECT/'scenes').rglob('*.tscn'))+list((PROJECT/'data').rglob('*.json'))+[ROOT/'tools/release_gate.py',H/'run.py',H/'lease_collision.gd',H/'PLAN.md']
    return {str(p.relative_to(ROOT)):sha(p) for p in sorted(files)}
if __name__=='__main__':
    assert not (H/'source-before.json').exists(),'preserve prior attempt'
    gate=load('isolated_gate',ROOT/'tools/release_gate.py');wrappers={}
    for path in sorted((PROJECT/'scripts/debug').glob('verify_*.gd')):
        _,metadata=gate.checkpoint_wrapper(path,H/'wrappers');wrappers[path.stem]=metadata
    write(H/'wrappers.json',wrappers);source=capture();write(H/'source-before.json',source)
    for label,options in [('default-production-held',[]),('explicit-test-held',['--isolate-checkpoint-writer'])]:
        lease=None
        if options:
            lease=socket.socket();lease.bind(('127.0.0.1',47733));lease.listen(1)
        else:
            probe=socket.socket()
            try:probe.bind(('127.0.0.1',62741));raise AssertionError('Expected parent-reported production owner still active')
            except OSError:pass
            finally:probe.close()
        try:
            cmd=[sys.executable,str(ROOT/'tools/release_gate.py'),'--godot',str(GODOT),'--output',str(H/label),'--defer-graphical-startup',*options]
            r=subprocess.run(cmd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=30)
            write(H/(label+'.command.json'),{'command':cmd,'exit':r.returncode,'output':r.stdout.decode('utf8',errors='replace')})
            report=json.loads((H/label/'gate-result.json').read_text())
            assert r.returncode==2 and report['checks']==[] and report.get('blocked') and not (H/label/'import.log').exists()
            assert report['checkpoint_writer_instrumentation']['enabled']==bool(options)
        finally:
            if lease:lease.close()
    checks=load('focused_checks',ROOT/'docs/codex/findings/checkpoint-runtime-v1/run_checks.py')
    checks.HERE=H;checks.GODOT=str(GODOT);checks.PROFILE=H/'profiles';os.environ['PN_CHECKPOINT_TEST_PORT']='47733'
    for name,script in [('verify_main_menu_history',H/'wrappers/verify_main_menu_history.gd'),('verify_checkpoint_runtime',H/'wrappers/verify_checkpoint_runtime.gd'),('verify_genre_checkpoint',H/'wrappers/verify_genre_checkpoint.gd'),('lease_collision',H/'lease_collision.gd')]:
        assert capture()==source,'source drift before '+name
        checks.run(name,['--script',str(script)])
        assert capture()==source,'source drift during '+name
        for metadata in wrappers.values():assert sha(metadata['path'])==metadata['sha256']
        write(H/(name+'.manifest.json'),{'source_sha256':sha(H/'source-before.json'),'script_sha256':sha(script),'artifacts':{ext:sha(H/(name+'.'+ext)) for ext in ['command.json','log']}})
    write(H/'source-after.json',capture());write(H/'result.json',{'passed':True,'native_processes':4,'preflight_negative_controls':2,'wrappers_generated':len(wrappers),'helper_sha256':sha(ROOT/'tools/release_gate.py'),'source_unchanged':capture()==source})
    print('Gate writer isolation focused acceptance passed',flush=True)
