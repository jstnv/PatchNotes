import concurrent.futures,json
import tutorial_task17_verify_v1 as v
v.OUT=v.ROOT/'design-logs/task27-v1'
plans=[(p,i,a,'main','normal','native') for p in ['cautious','ordinary','synergy'] for i in [0,1] for a in ['next','newer','older','store']]
plans += [(p,0,a,'repeat','normal','native') for p in ['ordinary','synergy'] for a in ['next','older']]
plans += [('synergy',i,'next','budget_'+choice,'fixed',choice) for i in [0,1] for choice in ['ordinary','native']]
def execute(plan):
 p,i,a,e,b,c=plan
 return v.run(f'{e}-{p}-{i}-{a}',v.ROOT,['--script','res://analysis/task27_routes_v1.gd','--',f'--policy={p}',f'--case={i}',f'--arm={a}',f'--experiment={e}',f'--budget={b}',f'--choice={c}'],180)
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
 results=list(pool.map(execute,plans))
(v.OUT/'route-commands.json').write_text(json.dumps(results,indent=2))
print('TASK27 ROUTES PASS',sum(x['exit']==0 and not x['errors'] for x in results),'OF',len(results))
