from pathlib import Path
import os, subprocess, tempfile, json
import tutorial_task17_verify_v1 as v
out=v.ROOT/'design-logs/task21-v1'
profile=Path(tempfile.mkdtemp(prefix='pn-task21-render-'))
env=os.environ.copy()
for key in ['APPDATA','LOCALAPPDATA']:
    p=profile/key; p.mkdir(); env[key]=str(p)
command=[v.GODOT,'--path',str(v.ROOT),'--rendering-method','gl_compatibility','--script','res://scripts/debug/verify_sidestreet_scope_and_year.gd','--','--capture']
p=subprocess.run(command,env=env,capture_output=True,timeout=120)
(out/'render.log').write_bytes(p.stdout+p.stderr)
(out/'render.command.json').write_text(json.dumps(dict(command=command,exit=p.returncode,profile=str(profile)),indent=2),encoding='utf-8')
print(p.returncode)
