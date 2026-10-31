"""Run one candidate verifier in a private profile with exact manifests and logs."""
import argparse, json, subprocess, sys, time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[4]
sys.path.insert(0,str(ROOT))
from tools import simulate as sim
def main():
    p=argparse.ArgumentParser();p.add_argument('--project',type=Path,required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--script',required=True);p.add_argument('--timeout',type=int,default=240);p.add_argument('--no-import',action='store_true');p.add_argument('extra',nargs='*');a=p.parse_args()
    a.output=a.output.resolve();a.output.mkdir(parents=True,exist_ok=False)
    env=sim.isolated_environment(a.output/'profile');godot=sim.resolve_godot('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64.exe')
    if a.no_import:
        hashes=sim.source_hashes(a.project.resolve());sim.write_json(a.output/'snapshot-manifest.json',hashes)
    else:hashes=sim.import_project(godot,a.project.resolve(),a.output,env,a.timeout)
    argv=[str(godot),'--headless','--audio-driver','Dummy','--path',str(a.project.resolve()),'--script',a.script,'--quit-after','60','--']+a.extra
    started=time.monotonic();result={}
    try:
        with (a.output/'godot.log').open('wb') as stream:
            c=subprocess.run(argv,env=env,cwd=ROOT,stdout=stream,stderr=subprocess.STDOUT,timeout=a.timeout)
        result={'exit':c.returncode,'seconds':time.monotonic()-started,'argv':argv,'log_sha256':sim.sha(a.output/'godot.log')}
    except subprocess.TimeoutExpired as e:
        if not (a.output/'godot.log').exists():(a.output/'godot.log').write_bytes(e.stdout or b'')
        result={'exit':None,'timeout':True,'argv':argv}
    sim.check_snapshot(a.project.resolve(),hashes)
    script=a.project.resolve()/a.script[6:] if a.script.startswith('res://') else Path(a.script)
    log_text=(a.output/'godot.log').read_text(errors='replace')
    result['engine_errors']=[line for line in log_text.splitlines() if line.startswith(('SCRIPT ERROR:','ERROR:'))]
    result['ok']=result.get('exit')==0 and not result['engine_errors']
    result['probe_sha256']=sim.sha(script);result['runner_sha256']=sim.sha(Path(__file__))
    result['source_unchanged']=True;sim.write_json(a.output/'result.json',result)
    print(json.dumps(result));print(log_text[-4000:])
    if not result['ok']:sys.exit(1)
if __name__=='__main__':main()
