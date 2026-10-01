import json,hashlib,subprocess
import tutorial_task17_verify_v1 as v
v.OUT=v.ROOT/'design-logs/task20-v1'
results=json.loads((v.OUT/'verification.json').read_text())[:2]
results.append(v.run('import',v.ROOT,['--editor','--import']))
results.append(v.run('native-contract-replay',v.ROOT,['--script','res://analysis/task20_native_rules_v1.gd'],60))
for name in ['balanced_primitive_contract','sidestreet_contract','sidestreet_scope_and_year','sales_earning_and_settlement','game_lifespan_trial']:
    results.append(v.run('verify_'+name,v.ROOT,['--script','res://scripts/debug/verify_'+name+'.gd']))
(v.OUT/'verification.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
assert all(x['exit']==0 and not x['errors'] for x in results)
assert all(hashlib.sha256((v.ROOT/p).read_bytes()).hexdigest()==h for p,h in json.loads((v.OUT/'source-before.json').read_text()).items())
r=subprocess.run(['git','diff','--check'],cwd=v.ROOT,capture_output=True); (v.OUT/'diff-check.log').write_bytes(r.stdout+r.stderr); assert r.returncode==0
