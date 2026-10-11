from pathlib import Path
import json,os,subprocess
root=Path.cwd();out=root/'docs/codex/findings/overnight-export-v1'
source=(root/'docs/codex/findings/export-queue-v3/inspect.py').read_text()
exec(compile(source.replace("OUT=Path(__file__).resolve().parent","OUT=Path("+repr(str(out))+")"),'package-inspection','exec'))
m=json.loads((out/'build-manifest.json').read_text());w=Path(m['workspace']);env=os.environ.copy()
for k in ['APPDATA','LOCALAPPDATA']:
 p=out/'ui-profile'/k;p.mkdir(parents=True,exist_ok=True);env[k]=str(p)
env.pop('PN_CHECKPOINT_TEST_PORT',None)
cmd=[str(w/'demo/Patch Notes Demo.exe'),'--resolution','1280x720']
p=subprocess.Popen(cmd,cwd=w/'demo',env=env,stdout=(out/'ui-stdout.log').open('wb'),stderr=(out/'ui-stderr.log').open('wb'),creationflags=subprocess.CREATE_NO_WINDOW)
(out/'ui-launch.json').write_text(json.dumps(dict(command=cmd,pid=p.pid,profile={k:env[k] for k in ['APPDATA','LOCALAPPDATA']}),indent=2))
print('LAUNCHED',p.pid)
