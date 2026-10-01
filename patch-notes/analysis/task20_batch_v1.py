import json,hashlib
import tutorial_task17_verify_v1 as v
v.OUT=v.ROOT/'design-logs/task20-v1'; v.OUT.mkdir(exist_ok=True); (v.OUT/'.gdignore').touch()
manifest={str(p.relative_to(v.ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for f in ['scripts','scenes','data'] for p in (v.ROOT/f).rglob('*') if p.is_file()}
(v.OUT/'source-before.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
for name,args in [('head',['rev-parse','HEAD']),('status',['status','--short']),('diff',['diff'])]: (v.OUT/('initial-'+name+'.txt')).write_bytes(v.git(*args))
results=[]
for neon in ['0','1']:
    results.append(v.run('routes-'+neon,v.ROOT,['--script','res://analysis/task20_routes_v1.gd','--','--mode=exact','--count=6','--arm=next_game','--neon='+neon],180))
(v.OUT/'verification.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
assert all(r['exit']==0 and not r['errors'] for r in results)
