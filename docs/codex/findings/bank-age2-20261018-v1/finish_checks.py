from pathlib import Path
import subprocess,sys,json
out=Path(__file__).resolve().parent
jobs=[('cold-recovered-v2','cold_store.gd',['restore','route-v1.json.studio.json']),('save-last-studio-v2','cold_store.gd',['save','bank-only-v1.json.initial.json']),('cold-last-studio-v2','cold_store.gd',['restore','bank-only-v1.json.initial.json']),('cold-replay-ironclad','cold_replay.gd',['route-v1']),('cold-replay-bank-only','cold_replay.gd',['bank-only-v1'])]
results=[]
for label,script,args in jobs:
    r=subprocess.run([sys.executable,str(out/'run.py'),label,script,*args],capture_output=True,text=True)
    results.append({'label':label,'exit':r.returncode,'stdout':r.stdout,'stderr':r.stderr})
    (out/'finish-checks.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
    print(label,r.returncode,flush=True)
    if r.returncode:break
