from pathlib import Path
import concurrent.futures,hashlib,json,os,subprocess
import run_checks as v
OUT=v.HERE/'full';OUT.mkdir(exist_ok=True)
EXPECTED={
 'verify_gameplay_transition':['Failed to instantiate scene state','Could not instantiate a valid AlphaPhase','Could not instantiate a valid BetaPhase'],
 'verify_primitive_run_initialization':['Could not initialize the Primitive project snapshots.'],
 'verify_run_calendar_and_studio_entry':['Condition "!is_inside_tree()" is true.']}
def run(path):
 name=path.stem
 env=os.environ.copy()
 for key in ('APPDATA','LOCALAPPDATA'):
  profile=v.PROFILE/'full'/name/key;profile.mkdir(parents=True,exist_ok=True);env[key]=str(profile)
 command=[v.GODOT,'--headless','--path',str(v.PROJECT),'--script','res://scripts/debug/'+path.name]
 try:
  result=subprocess.run(command,env=env,capture_output=True,timeout=180)
  code,output=result.returncode,result.stdout+result.stderr
 except subprocess.TimeoutExpired as error:
  code,output='timeout',(error.stdout or b'')+(error.stderr or b'')
 (OUT/(name+'.log')).write_bytes(output)
 lines=output.decode('utf-8',errors='replace').splitlines()
 errors=[line for line in lines if any(x in line for x in ['ERROR:','FAIL:','Assertion failed']) and 'Failed to read the root certificate store.' not in line and not any(x in line for x in EXPECTED.get(name,[]))]
 record=dict(name=name,command=command,exit=code,errors=errors,passes=sum('PASS:' in x for x in lines))
 (OUT/(name+'.json')).write_text(json.dumps(record,indent=2))
 print(name,code,len(errors),flush=True)
 return record
paths=sorted((v.PROJECT/'scripts/debug').glob('verify_*.gd'))
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool: results=list(pool.map(run,paths))
manifest={str(p.relative_to(v.PROJECT)):hashlib.sha256(p.read_bytes()).hexdigest() for directory in ['scripts','scenes','data'] for p in (v.PROJECT/directory).rglob('*') if p.is_file()}
report=dict(results=results,passed=all(r['exit']==0 and not r['errors'] for r in results),source=manifest,head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=v.REPO).decode().strip())
(OUT/'gate.json').write_text(json.dumps(report,indent=2))
print('FULL',report['passed'],len(results),flush=True)
raise SystemExit(0 if report['passed'] else 1)
