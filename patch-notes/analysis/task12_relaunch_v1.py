import json,os,subprocess,tempfile
from pathlib import Path
import tutorial_task17_verify_v1 as v
out=v.ROOT/'design-logs/task12-v1';profile=Path(tempfile.mkdtemp(prefix='pn-task12-relaunch-')); env=os.environ.copy()
for key in ['APPDATA','LOCALAPPDATA']:
 p=profile/key;p.mkdir();env[key]=str(p)
results=[]
for stage in ['write','read']:
 cmd=[v.GODOT,'--headless','--path',str(v.ROOT),'--script','res://analysis/task12_relaunch_v1.gd','--','--'+stage]
 p=subprocess.run(cmd,env=env,capture_output=True,timeout=30);text=(p.stdout+p.stderr).decode(errors='replace');(out/('relaunch-'+stage+'.log')).write_text(text,encoding='utf-8')
 result=dict(command=cmd,profile=str(profile),exit=p.returncode,errors=[x for x in text.splitlines() if ('ERROR:' in x or 'FAIL:' in x) and 'Failed to read the root certificate store.' not in x]);results.append(result)
(out/'relaunch-results.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
assert all(r['exit']==0 and not r['errors'] for r in results)
print('PASS: two separate Godot processes persist display, volume and mute using one isolated profile')
