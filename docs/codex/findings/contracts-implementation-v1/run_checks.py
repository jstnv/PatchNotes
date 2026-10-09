"""Run current-worktree checks in isolated user profiles, retaining exact logs."""
from pathlib import Path
import json,os,subprocess,sys,tempfile

HERE=Path(__file__).resolve().parent
REPO=HERE.parents[3]
PROJECT=REPO/'patch-notes'
PROFILE=Path(r'C:\Users\64jus\Downloads\Patch Notes Design Folder\contracts-implementation-20261007')
GODOT=r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'

def run(name,args,timeout=240):
    env=os.environ.copy()
    PROFILE.mkdir(parents=True,exist_ok=True)
    unique=Path(tempfile.mkdtemp(prefix=name+"-",dir=PROFILE))
    for k in ('APPDATA','LOCALAPPDATA'):
        p=unique/k;p.mkdir(parents=True,exist_ok=True);env[k]=str(p)
    command=[GODOT,'--headless','--path',str(PROJECT),*args]
    with (HERE/(name+'.log')).open('wb') as log:
        result=subprocess.run(command,cwd=REPO,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=timeout)
    output=(HERE/(name+'.log')).read_text(errors='replace')
    errors=[x for x in output.splitlines() if ('SCRIPT ERROR' in x or x.startswith('ERROR:') or 'FAIL:' in x) and 'root certificate store' not in x]
    expected=[]
    if name=='verify_gameplay_transition':
        expected=['ERROR: Failed to instantiate scene state of "", node count is 0. Make sure the PackedScene resource is valid.']*2 + ['ERROR: Could not instantiate a valid AlphaPhase placeholder.','ERROR: Could not instantiate a valid BetaPhase placeholder.']
    if name=='verify_primitive_run_initialization':
        expected=['ERROR: Could not initialize the Primitive project snapshots.']
    classified=[]
    for line in expected:
        if line in errors:
            errors.remove(line)
            classified.append(line)
    record={'command':command,'exit':result.returncode,'errors':errors,'expected_negative_probe_errors':classified}
    (HERE/(name+'.command.json')).write_text(json.dumps(record,indent=2))
    print(name,result.returncode,output[-700:] if errors or result.returncode else [x for x in output.splitlines() if 'failures' in x][-2:],flush=True)
    if result.returncode or errors:raise RuntimeError(name)

if __name__=='__main__':
    for name in sys.argv[1:]:
        run(name,['--editor','--import','--quit'] if name=='import' else ['--script','res://scripts/debug/'+name+'.gd'])
