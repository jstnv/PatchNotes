"""Cross-source re-execution followed by independent current-source replay."""
from pathlib import Path
import json,subprocess,sys,time
out=Path(__file__).resolve().parent; root=out.parents[3]; checks=[]
deadline=time.monotonic()+1800
while not (out/'indexed-malformed-run.json').exists():
    if time.monotonic()>deadline:raise SystemExit('Final suite not complete')
    time.sleep(1)
assert all(x['exit']==0 for x in json.loads((out/'indexed-verification-index.json').read_text()))
def run(label,probe,arg):
    result=subprocess.run([sys.executable,str(out/'run.py'),label,'res://scripts/debug/'+probe,arg],cwd=root,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
    receipt=out/(label+'-run.json')
    checks.append({'label':label,'exit':result.returncode,'receipt':receipt.name})
    (out/'source-equivalence-index.json').write_text(json.dumps(checks,indent=2))
    print(label,'PASS' if result.returncode==0 else 'FAIL',flush=True)
    if result.returncode:print(result.stdout[-3000:]);sys.exit(result.returncode)
for tier in [1,2,3]:
    label='equivalence-tier'+str(tier)
    run(label,'verify_employee_course_source_equivalence.gd',str(out/('final-tier'+str(tier)+'.json')))
    run(label+'-replay','verify_employee_course_fixed_campaign.gd','--replay='+str(out/(label+'.json')))
print('SOURCE_EQUIVALENCE_COMPLETE',flush=True)
