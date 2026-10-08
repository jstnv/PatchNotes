"""Run current-worktree checks in isolated user profiles, retaining exact logs."""
from pathlib import Path
import json,os,subprocess,sys,tempfile

HERE=Path(__file__).resolve().parent
REPO=HERE.parents[3]
PROJECT=REPO/'patch-notes'
PROFILE=Path(r'C:\Users\64jus\Downloads\Patch Notes Design Folder\card-tempo-20261007')
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
    errors=[x for x in output.splitlines() if ('SCRIPT ERROR' in x or x.startswith('ERROR:')) and 'root certificate store' not in x]
    record={'command':command,'exit':result.returncode,'errors':errors}
    (HERE/(name+'.command.json')).write_text(json.dumps(record,indent=2))
    print(name,result.returncode,output[-700:] if errors or result.returncode else [x for x in output.splitlines() if 'failures' in x][-2:],flush=True)
    if result.returncode or errors:raise RuntimeError(name)

if __name__=='__main__':
    for name in sys.argv[1:]:
        run(name,['--editor','--import','--quit'] if name=='import' else ['--script','res://scripts/debug/'+name+'.gd'])
