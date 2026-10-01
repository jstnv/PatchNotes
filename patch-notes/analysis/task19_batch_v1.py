from pathlib import Path
import json,hashlib
import tutorial_task17_verify_v1 as v
v.OUT=v.ROOT/'design-logs/task19-v1'; v.OUT.mkdir(exist_ok=True); (v.OUT/'.gdignore').touch()
manifest={str(p.relative_to(v.ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for f in ['scripts','scenes','data'] for p in (v.ROOT/f).rglob('*') if p.is_file()}
(v.OUT/'source-before.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
for name,args in [('head',['rev-parse','HEAD']),('status',['status','--short']),('diff',['diff'])]: (v.OUT/('initial-'+name+'.txt')).write_bytes(v.git(*args))
results=[v.run('six-strong',v.ROOT,['--script','res://analysis/task19_routes_v1.gd','--','--mode=exact','--count=6','--tag=short'],180)]
results.append(v.run('long-strong',v.ROOT,['--script','res://analysis/task19_routes_v1.gd','--','--mode=exact','--count=1','--arm=next_game','--tag=long'],180))
for name in ['game_lifespan_trial','sales_earning_and_settlement','sidestreet_scope_and_year','first_studio_feature_economy']:
    results.append(v.run('verify_'+name,v.ROOT,['--script','res://scripts/debug/verify_'+name+'.gd']))
results.append(v.run('import',v.ROOT,['--editor','--import']))
(v.OUT/'verification.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
assert all(r['exit']==0 and not r['errors'] for r in results)
assert all(hashlib.sha256((v.ROOT/p).read_bytes()).hexdigest()==h for p,h in manifest.items())
