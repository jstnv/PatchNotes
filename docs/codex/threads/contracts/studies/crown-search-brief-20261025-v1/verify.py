from run import *
rows=load(HERE/'analysis.json')['rows']
selected=['skip-action-4417-cash18','mean-simulation-4417-cash18']
write(HERE/'replay-selection.json',selected)
for cid in selected:
 execute('replay-'+cid,[sys.executable,'tools/simulate.py','replay','--bundle',str(RAW/'branches'),'--case',cid,'--output',str(RAW/('replay-'+cid)),'--timeout','240','--godot',GODOT])
source=next(c for c in load(HERE/'branches.json')['cases'] if c['case_id']=='mean-action-4417-cash18')
source['case_id']='brief-cold';source['initial']={'checkpoint':load(RAW/'branches/cases/mean-action-4417-cash18/studio_checkpoint.json')};source['target_release_count']=4;source['max_commands']=80;source['policy']['config'].update(arm='skip',label='brief-cold',starting_reputation=1250);source.pop('study',None)
write(HERE/'cold.json',dict(schema_version='1',policy=dict(script='policy.gd',id='crown-search-brief-public-mean256',version='1'),cases=[source]))
run('cold')
