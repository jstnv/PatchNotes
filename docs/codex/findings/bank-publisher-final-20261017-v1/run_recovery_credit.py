from pathlib import Path
import os,json,subprocess
base=Path(__file__).resolve().parent
env=os.environ.copy()
for key in ('APPDATA','LOCALAPPDATA'):
 p=base/'recovery-credit-profile'/key;p.mkdir(parents=True,exist_ok=True);env[key]=str(p)
cmd=[r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe','--headless','--audio-driver','Dummy','--path',str(base.parent/'queue-execution-20261017-v2/final-ui-wire-v7/project'),'--script','res://scripts/debug/verify_outstanding_expenses.gd']
with (base/'recovery-credit.log').open('wb') as out:r=subprocess.run(cmd,env=env,stdout=out,stderr=subprocess.STDOUT,timeout=120)
log=(base/'recovery-credit.log').read_text(errors='replace')
errors=[s for s in log.splitlines() if 'ERROR:' in s or s.startswith('FAIL')]
result=dict(command=cmd,exit=r.returncode,errors=errors,summary=[s for s in log.splitlines() if 'checks' in s or 'failures' in s])
(base/'recovery-credit-result.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result));raise SystemExit(bool(errors) or r.returncode)
