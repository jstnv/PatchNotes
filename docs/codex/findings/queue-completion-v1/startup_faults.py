from pathlib import Path
import os,json,shutil,tempfile,subprocess,hashlib
H=Path(__file__).resolve().parent;repo=H.parents[3]
m=json.loads((H.parent/'export-queue-v3/build-manifest.json').read_text())
workspace=Path(tempfile.mkdtemp(prefix='startup-data-acceptance-'))
project=workspace/'project';shutil.copytree(Path(m['workspace'])/'source',project)
# Restore main's display/configuration so this is the main-source startup check.
shutil.copy2(repo/'patch-notes/project.godot',project/'project.godot')
shutil.copy2(repo/'patch-notes/scripts/gameplay.gd',project/'scripts/gameplay.gd')
(project/'scripts/debug').mkdir(exist_ok=True)
shutil.copy2(H/'startup_fault_probe.gd',project/'scripts/debug/startup_fault_probe.gd')
env=os.environ.copy()
for k in ['APPDATA','LOCALAPPDATA']:
 p=workspace/k;p.mkdir();env[k]=str(p)
godot=r'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
records=[]
def run(name,args,graphical=False):
 command=[godot,*(['--rendering-method','gl_compatibility'] if graphical else ['--headless']),'--path',str(project),*args]
 with (H/(name+'.log')).open('wb') as log:p=subprocess.run(command,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=90)
 errors=[s for s in (H/(name+'.log')).read_text(errors='replace').splitlines() if (s.startswith('ERROR:') or 'SCRIPT ERROR' in s or 'FAIL:' in s) and 'root certificate store' not in s]
 expected=[s for s in errors if s.startswith('ERROR: Could not open card file:') or s=='ERROR: Failed to parse cards.json' or s.startswith('ERROR: Error parsing JSON') or s.startswith('ERROR: Parse JSON failed.') or s.startswith('ERROR: Could not open Feature Store')]
 unexpected=[s for s in errors if s not in expected]
 records.append(dict(name=name,command=command,exit=p.returncode,expected_missing_data_errors=expected,errors=unexpected))
 (H/'startup-fault-results.json').write_text(json.dumps(dict(workspace=str(workspace),runs=records),indent=2))
 print(name,p.returncode,unexpected,flush=True)
 assert p.returncode==0 and not unexpected
run('startup-fault-import',['--editor','--import','--quit'])
script=['--script','res://scripts/debug/startup_fault_probe.gd','--']
run('startup-prepare',script+['prepare','1152','648'])
save=workspace/'APPDATA/Godot/app_userdata/Patch Notes/saves/studio'
digest=lambda:{str(p.relative_to(save)):hashlib.sha256(p.read_bytes()).hexdigest() for p in save.rglob('*') if p.is_file()}
baseline=digest();assert baseline
files=['card_ledger.json','feature_store_ledger.json','primitive_predevelopment.json','primitive_competitor_ledger.json','primitive_market_forecasts.json']
# Resolve the actual market paths directly from StartupDataCheck's source constants.
market=(project/'scripts/market/primitive_snapshot_database.gd').read_text()
import re
files=files[:3]+[re.search(r'const '+key+r' := "res://data/([^"]+)"',market).group(1) for key in ['COMPETITOR_LEDGER_PATH','FORECAST_LEDGER_PATH']]
for file in files:
 path=project/'data'/file;backup=workspace/(file+'.good');shutil.copy2(path,backup)
 for kind in ['missing','malformed']:
  if kind=='missing':path.unlink()
  else:path.write_text('{')
  name='startup-'+file.removesuffix('.json')+'-'+kind
  graphical=file=='card_ledger.json';size=['1152','648'] if kind=='missing' else ['1280','720']
  try:run(name,script+['fault',*size,str(path),str(backup),str(H/(name+'.png'))],graphical)
  finally:shutil.copy2(backup,path)
  assert digest()==baseline,'Saved Studio bytes changed: '+name
print('PASS 10 cold-start data faults, repair/retry/Continue; saved bytes unchanged')
