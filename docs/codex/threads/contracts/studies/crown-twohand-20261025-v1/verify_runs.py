from run import *
from concurrent.futures import ThreadPoolExecutor
data=load(HERE/'analysis.json');assert data['status']=='PASS'
selected=[]
for arm in ['mean','downside']:
    rows=sorted([r for r in data['rows'] if r['arm']==arm],key=lambda r:r['seed'])
    for r in [max(rows,key=lambda r:r['reputation_bp']),min(rows,key=lambda r:r['reputation_bp'])]:
        if r not in selected:selected.append(r)
write(HERE/'replay-selection.json',dict(rule='Best/worst earned total per planner, ties4521; deduplicate ties.',cases=[r['case'] for r in selected]))
def replay(r):
    name='replay-'+r['case']
    return execute(name,[PY,'tools/simulate.py','replay','--bundle',str(RAW/r['batch']),'--case',r['case'],'--output',str(RAW/name),'--timeout','600','--godot',GODOT])
with ThreadPoolExecutor(max_workers=2) as pool:codes=list(pool.map(replay,selected))
assert all(x==0 for x in codes),codes
best=max([r for r in data['rows'] if r['arm'] in ['mean','downside']],key=lambda r:r['reputation_bp'])
checkpoint=load(RAW/best['batch']/'cases'/best['case']/'studio_checkpoint.json')
c=dict(schema_version='1',case_id='cold-next',initial=dict(checkpoint=checkpoint),max_commands=80,target_release_count=best['releases']+1,telemetry=True,study=dict(pair_id='cold',arm='skip'),policy=dict(config=dict(arm='skip',label='cold-next',starting_reputation=best['reputation_bp'])))
write(HERE/'cold.json',dict(schema_version='1',policy=dict(script='policy.gd',id='crown-twohand-halton256',version='1'),cases=[c]))
write(HERE/'cold-selection.json',dict(source_case=best['case'],source_batch=best['batch'],config_sha256=sha(HERE/'cold.json')))
assert run('cold')==0
