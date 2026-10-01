from pathlib import Path
import json,sys,hashlib
import tutorial_task17_verify_v1 as v
v.OUT=v.ROOT/'design-logs/task24-v1'; v.OUT.mkdir(exist_ok=True); (v.OUT/'.gdignore').touch()
if '--snapshot' in sys.argv:
 for name,args in [('head',['rev-parse','HEAD']),('branch',['branch','--show-current']),('status',['status','--short']),('diff',['diff'])]: (v.OUT/('initial-'+name+'.txt')).write_bytes(v.git(*args))
 manifest={str(p.relative_to(v.ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for f in ['scripts','scenes','data'] for p in (v.ROOT/f).rglob('*') if p.is_file()}
 (v.OUT/'source-before.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
results=[]
if '--smoke' in sys.argv:
 jobs=[('ordinary',0,30,1)]
elif '--long' in sys.argv:
 jobs=[(policy,gate,1104,1) for policy in ['cautious','ordinary','synergy'] for gate in [0,24]]
else:
 jobs=[(policy,gate,240,6) for policy in ['cautious','ordinary','synergy'] for gate in [0,24]]
for policy,gate,cap,count in jobs:
 name=f'normal_{policy}_{gate}_{cap}'
 results.append(v.run(name,v.ROOT,['--script','res://analysis/task24_normal_v1.gd','--',f'--policy={policy}',f'--store-gate={gate}',f'--cap={cap}',f'--count={count}'],300))
 if results[-1]['exit']!=0 or results[-1]['errors']: break
(v.OUT/('verification-long.json' if '--long' in sys.argv else 'verification-smoke.json' if '--smoke' in sys.argv else 'verification-normal.json')).write_text(json.dumps(results,indent=2),encoding='utf-8')
assert all(x['exit']==0 and not x['errors'] for x in results)
