from pathlib import Path
import concurrent.futures,json,time,sys
import tutorial_task17_verify_v1 as v
v.OUT=v.ROOT/'design-logs/task24-current-v2'
kind=sys.argv[1] if len(sys.argv)>1 else 'main'
plans=[]
if kind=='main':
    plans=[(p,i,1,0,0) for p in ['cautious','ordinary','synergy'] for i in range(16)]
elif kind=='continuations':
    plans=[(p,i,1,240,0) for p in ['ordinary','synergy'] for i in range(8)]
elif kind=='long':
    plans=[(p,i,1,1104,0) for p in ['ordinary','synergy'] for i in [0,1]]
elif kind=='sensitivity':
    plans=[('high',i,1,0,0) for i in [0,1]]+[(p,i,1,0,24) for p in ['ordinary','synergy'] for i in [0,1]]
else:raise ValueError(kind)
def execute(plan):
    policy,start,count,cap,gate=plan
    return v.run(f'{kind}-{policy}-{start}-{cap}-{gate}',v.ROOT,
       ['--script','res://analysis/task24_current_v2.gd','--',f'--policy={policy}',f'--start={start}',f'--count={count}',f'--cap={cap}',f'--store-gate={gate}'],240 if cap else 120)
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
    results=list(pool.map(execute,plans))
(v.OUT/(kind+'-commands.json')).write_text(json.dumps(results,indent=2),encoding='utf-8')
print('BATCH',kind,'PASS',sum(r['exit']==0 and not r['errors'] for r in results),'OF',len(results),flush=True)
