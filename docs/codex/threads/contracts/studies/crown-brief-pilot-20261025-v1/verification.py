from run import *
from concurrent.futures import ThreadPoolExecutor
rows=load(HERE/'analysis.json')['rows']
good=[r for r in rows if r['ok']]
best=max(good,key=lambda r:r['reputation_bp'])
weak=min([r for r in good if r['arm']!='skip'],key=lambda r:r['reputation_bp'])
skip=next(r for r in good if r['arm']=='skip' and r['seed']==best['seed'])
selection=[best,weak,skip]
write(HERE/'verification-selection.json',selection)
def replay(row):
    name='replay-'+row['case']
    return execute(name,[PY,'tools/simulate.py','replay','--bundle',str(RAW/('branches-'+row['seed'])),'--case',row['case'],'--output',str(RAW/name),'--timeout','480','--godot',GODOT])
with ThreadPoolExecutor(max_workers=2) as pool:list(pool.map(replay,selection[:2]))
replay(skip)
cp=load(RAW/('branches-'+best['seed'])/'cases'/best['case']/'studio_checkpoint.json')
c=dict(schema_version='1',case_id='cold-next',initial=dict(checkpoint=cp),max_commands=80,target_release_count=best['releases']+1,telemetry=True,policy=dict(config=dict(arm='skip',label='cold-next',starting_reputation=best['reputation_bp'])))
write(HERE/'cold.json',dict(schema_version='1',policy=dict(script='policy.gd',id='crown-brief-five-arm',version='1'),cases=[c]))
run('cold')
