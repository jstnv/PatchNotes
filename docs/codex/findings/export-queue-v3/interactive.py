from pathlib import Path
import json,os,subprocess
HERE=Path(__file__).resolve().parent
build=Path(json.loads((HERE/'delivery.json').read_text())['directory'])
profile=build/'interactive-profile';profile.mkdir(exist_ok=True)
env=os.environ.copy()
for key in ['APPDATA','LOCALAPPDATA']:
 p=profile/key;p.mkdir(exist_ok=True);env[key]=str(p)
command=[str(build/'Patch Notes Demo.exe'),'--rendering-method','gl_compatibility']
log=(HERE/'interactive.log').open('ab')
p=subprocess.Popen(command,env=env,stdout=log,stderr=subprocess.STDOUT)
(HERE/'interactive-process.json').write_text(json.dumps(dict(pid=p.pid,command=command,profile=str(profile)),indent=2))
print(p.pid)
