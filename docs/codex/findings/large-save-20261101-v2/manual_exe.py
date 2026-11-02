"""Keep the actual release EXE open on the already-verified private save profile."""
from pathlib import Path
import json,os,subprocess,time
out=Path(__file__).resolve().parent;m=json.loads((out/'build-manifest.json').read_text(encoding='utf-8'));rows=json.loads((out/'export-acceptance.json').read_text(encoding='utf-8'))
env=os.environ.copy();env.update(rows[0]['profile']);exe=Path(m['artifact'])/'Patch Notes v0.03.exe'
start=time.monotonic()
with (out/'manual-exe.log').open('wb') as log:
    p=subprocess.Popen([str(exe),'--audio-driver','Dummy'],env=env,cwd=exe.parent,stdout=log,stderr=subprocess.STDOUT)
    (out/'manual-exe-launch.json').write_text(json.dumps({'exe':str(exe),'pid':p.pid,'private_profile':rows[0]['profile']},indent=2),encoding='utf-8',newline='\n')
    try:code=p.wait(timeout=600)
    except subprocess.TimeoutExpired:p.terminate();code=p.wait(timeout=20)
text=(out/'manual-exe.log').read_text(encoding='utf-8',errors='replace')
result={'exit':code,'seconds':time.monotonic()-start,'errors':[x for x in text.splitlines() if x.startswith(('ERROR:','SCRIPT ERROR:'))]}
(out/'manual-exe-exit.json').write_text(json.dumps(result,indent=2),encoding='utf-8',newline='\n');print(json.dumps(result),flush=True)
