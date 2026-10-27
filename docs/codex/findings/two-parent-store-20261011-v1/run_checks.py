"""Focused parent-graph acceptance; isolated profiles, no player saves."""
from pathlib import Path
import importlib.util,os,subprocess,json,shutil
HERE=Path(__file__).resolve().parent
REPO=HERE.parents[3]
PROJECT=REPO/'patch-notes'
spec=importlib.util.spec_from_file_location('checks',REPO/'docs/codex/findings/checkpoint-runtime-v1/run_checks.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);m.HERE=HERE;m.PROFILE=HERE/'profiles'

def invoke(name,args,profile,extra=None):
 env=os.environ.copy()
 for key in ['APPDATA','LOCALAPPDATA']:
  folder=HERE/'profiles'/profile/key;folder.mkdir(parents=True,exist_ok=True);env[key]=str(folder)
 env.update(extra or {})
 command=[m.GODOT,'--path',str(PROJECT),*args]
 with (HERE/(name+'.log')).open('wb') as log:
  result=subprocess.run(command,cwd=REPO,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=150)
 output=(HERE/(name+'.log')).read_text(errors='replace')
 errors=[line for line in output.splitlines() if ('SCRIPT ERROR' in line or line.startswith('ERROR:') or 'FAIL:' in line) and 'root certificate store' not in line]
 (HERE/(name+'.command.json')).write_text(json.dumps({'command':command,'exit':result.returncode,'errors':errors,'environment':extra or {},'profile':profile},indent=2))
 print(name,result.returncode,errors,flush=True)
 if errors or result.returncode: raise RuntimeError(name)

if __name__=='__main__':
 for mode in ['initial','admit','complete','owned']:
  invoke('restart-'+mode,['--headless','--script','res://scripts/debug/verify_feature_parents.gd'],'restart-v1',{'PN_PARENT_RESTART':mode})
 invoke('rendered',['--rendering-method','gl_compatibility','--audio-driver','Dummy','--script','res://scripts/debug/verify_feature_parents.gd','--','--capture'],'rendered-v1')
 for image in (HERE/'profiles'/'rendered-v1').rglob('two-parent-*.png'): shutil.copy2(image,HERE/image.name)
