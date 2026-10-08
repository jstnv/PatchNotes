from pathlib import Path
import gzip,hashlib,json,os,shutil,subprocess,sys
HERE=Path(__file__).resolve().parent
ROOT=Path(r'C:\Users\64jus\Downloads\Patch Notes Design Folder\fanbase-quarter-20261007')
PROJECT=ROOT/'patch-notes'
GODOT=r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
def run(name,args,timeout=240):
 env=os.environ.copy()
 for key in ('APPDATA','LOCALAPPDATA'):
  p=ROOT/'profiles'/name/key;p.mkdir(parents=True,exist_ok=True);env[key]=str(p)
 command=[GODOT,'--headless','--path',str(PROJECT),*args]
 with (HERE/(name+'.log')).open('wb') as output: result=subprocess.run(command,env=env,stdout=output,stderr=subprocess.STDOUT,timeout=timeout)
 lines=(HERE/(name+'.log')).read_text(encoding='utf-8',errors='replace').splitlines()
 errors=[line for line in lines if ('ERROR:' in line or 'FAIL:' in line) and 'root certificate store' not in line]
 record=dict(command=command,exit=result.returncode,errors=errors)
 (HERE/(name+'.command.json')).write_text(json.dumps(record,indent=2))
 print(name,result.returncode,errors[-4:],lines[-2:],flush=True)
 if result.returncode or errors:raise RuntimeError(name)
for name in sys.argv[1:]:
 if name=='import':run(name,['--editor','--import','--quit'])
 elif name.startswith('verify_'):run(name,['--script','res://scripts/debug/'+name+'.gd'])
 else:
  run(name,['--script','res://analysis/fanbase_quarter_capture.gd','--','--policy=ordinary','--band=early','--seed=1104','--specialty=action','--contracts=available','--alignment=0','--neon=0','--weak='+name],600)
  raw=PROJECT/'design-logs/task32-v1/route_early_ordinary_1104_available_0_0.json'
  shutil.copy2(raw,ROOT/(name+'.json'))
  with raw.open('rb') as source,gzip.open(HERE/(name+'.json.gz'),'wb',compresslevel=9) as target:shutil.copyfileobj(source,target)
  data=json.loads(raw.read_text(encoding='utf-8'))
  print(name,'valid',data['valid'],'releases',[(r.get('review'),r.get('cycle')) for r in data['releases']],flush=True)
