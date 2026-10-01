"""Render and inspect the specialty selection with the real game theme/HUD."""
import json,os,subprocess,tempfile
from pathlib import Path
import tutorial_task17_verify_v1 as v
out=v.ROOT/'design-logs/task25-v1'
profile=Path(tempfile.mkdtemp(prefix='pn-task25-render-'));env=os.environ.copy()
for key in ['APPDATA','LOCALAPPDATA']:
    folder=profile/key;folder.mkdir();env[key]=str(folder)
command=[v.GODOT,'--path',str(v.ROOT),'--rendering-method','gl_compatibility','--position','-5000,-5000','--script','res://scripts/debug/verify_studio_specialties.gd','--','--capture']
p=subprocess.run(command,env=env,capture_output=True,timeout=90)
output=p.stdout+p.stderr;(out/'render.log').write_bytes(output)
result=dict(command=command,exit=p.returncode,profile=str(profile),errors=[s for s in ['SCRIPT ERROR','Parse Error','FAIL:'] if s.encode() in output])
(out/'render.command.json').write_text(json.dumps(result,indent=2),encoding='utf-8');print(json.dumps(result))
assert p.returncode==0 and not result['errors']
