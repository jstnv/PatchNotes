"""Bounded 32-route cohort; isolated Godot profiles, exact commands retained."""
import concurrent.futures,json,time
import tutorial_task17_verify_v1 as v
v.OUT=v.ROOT/'design-logs/lifespan-verification-v2'
started=time.monotonic()
def execute(job):
 policy,index=job
 if time.monotonic()-started>25*60:return {'skipped':job,'reason':'declared wall bound'}
 return v.run('cohort-%s-%d'%job,v.ROOT,['--script','res://analysis/lifespan_verify_routes_v2.gd','--','--policy='+policy,'--case='+str(index)],180)
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:results=list(pool.map(execute,[(p,i) for i in range(16) for p in ['ordinary','synergy']]))
(v.OUT/'cohort-commands.json').write_text(json.dumps(results,indent=2))
print('COHORT',sum(r.get('exit')==0 and not r.get('errors') for r in results),'/',len(results))
