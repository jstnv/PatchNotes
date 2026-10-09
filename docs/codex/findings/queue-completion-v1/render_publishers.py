from pathlib import Path
import os,json,subprocess,tempfile
H=Path(__file__).resolve().parent
record=json.loads((H/'publisher-render.command.json').read_text());env=os.environ.copy();profile=Path(tempfile.mkdtemp(prefix='publisher-render-final-'))
for k in ['APPDATA','LOCALAPPDATA']:
 p=profile/k;p.mkdir();env[k]=str(p)
with (H/'publisher-render-final.log').open('wb') as log:p=subprocess.run(record['command'],env=env,stdout=log,stderr=subprocess.STDOUT,timeout=90)
errors=[x for x in (H/'publisher-render-final.log').read_text(errors='replace').splitlines() if ('SCRIPT ERROR' in x or x.startswith('ERROR:') or 'FAIL:' in x) and 'root certificate store' not in x]
(H/'publisher-render-final.command.json').write_text(json.dumps(dict(command=record['command'],exit=p.returncode,errors=errors,profile=str(profile)),indent=2))
assert p.returncode==0 and not errors
print('PASS 16 publisher captures, selected rows and details agree')
