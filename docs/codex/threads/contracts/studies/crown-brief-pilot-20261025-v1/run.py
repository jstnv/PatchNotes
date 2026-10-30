from pathlib import Path
import json, subprocess, sys, time, hashlib
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[5]
THREAD=HERE.parents[1]
BASE=THREAD/'simulators/crown-brief-access-20261025-v1'
VAR=THREAD/'simulators/crown-brief-pilot-20261025-v1'
RAW=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-brief-pilot-20261025-v1')
PY=sys.executable
GODOT='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
write=lambda p,x:p.write_text(json.dumps(x,indent=2)+'\n',encoding='utf-8')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def execute(name,args):
    assert not (HERE/(name+'-command.json')).exists(),name
    write(HERE/(name+'-command.json'),args)
    start=time.time(); print('START '+name,flush=True)
    r=subprocess.run(args,cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace')
    (HERE/(name+'-driver.log')).write_text(r.stdout+'\n'+r.stderr,encoding='utf-8')
    write(HERE/(name+'-exit.json'),dict(exit_code=r.returncode,seconds=time.time()-start))
    print('END '+name+' '+str(r.returncode),flush=True)
    return r.returncode
def run(name,variant=VAR):
    return execute(name,[PY,'tools/simulate.py','run','--variant',str(variant),'--config',str(HERE/(name+'.json')),'--output',str(RAW/name),'--timeout','480','--godot',GODOT])
if __name__=='__main__':run(sys.argv[1],BASE if sys.argv[1]=='baseline' else VAR)
