"""Paired current/native historical starts. Gameplay snapshot stays isolated."""
from pathlib import Path
import json,shutil,sys
import tutorial_task17_verify_v1 as v
v.OUT=v.ROOT/'design-logs/task25-v1'
old=v.OUT/'before'
dependencies=['task25_routes_v1.gd','task24_normal_v1.gd','task21_route_v1.gd','task17_strong_route_v1.gd','contract_synergy_first_capture_v1.gd']
(old/'analysis').mkdir(exist_ok=True)
(old/'design-logs/task25-v1').mkdir(parents=True,exist_ok=True)
for name in dependencies:shutil.copy2(v.ROOT/'analysis'/name,old/'analysis'/name)
shutil.copy2(v.ROOT/'icon.svg',old/'icon.svg')
shutil.copytree(v.ROOT/'assets',old/'assets',dirs_exist_ok=True)
count=1 if '--smoke' in sys.argv else 24
policies=['ordinary'] if '--smoke' in sys.argv else ['cautious','ordinary','synergy']
results=[]
for arm,project in [('historical',old),('specialty',v.ROOT)]:
    results.append(v.run(arm+'-import',project,['--editor','--import']))
    for policy in policies:
        results.append(v.run(arm+'-'+policy,project,['--script','res://analysis/task25_routes_v1.gd','--','--arm='+arm,'--policy='+policy,'--count='+str(count)],180))
        if results[-1]['exit']!=0 or results[-1]['errors']:break
    if results[-1]['exit']!=0 or results[-1]['errors']:break
(v.OUT/('routes-smoke-verification.json' if '--smoke' in sys.argv else 'routes-verification.json')).write_text(json.dumps(results,indent=2),encoding='utf-8')
assert all(r['exit']==0 and not r['errors'] for r in results)
