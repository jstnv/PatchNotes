from run import *
rows=sorted(load(HERE/'analysis.json')['rows'],key=lambda r:r['case'])
assert len(rows)==18
success=next((r for r in rows if r['status']=='completed' and r['arm']!='control'),None)
failure=next((r for r in rows if r['rejection']),None)
write(HERE/'verification-selection.json',dict(success=success['case'] if success else None,failure=failure['case'] if failure else None))
for row in [success,failure]:
    if not row:continue
    cid=row['case'];execute('replay-'+cid,[sys.executable,'tools/simulate.py','replay','--bundle',str(RAW/row['bundle']),'--case',cid,'--output',str(RAW/('replay-'+cid)),'--timeout','240','--godot',GODOT])
if failure:
    cid=failure['case'];execute('reduce-'+cid,[sys.executable,'tools/reduce_simulation.py','--bundle',str(RAW/failure['bundle']),'--case',cid,'--kind','rejection','--max-commands','500','--output',str(RAW/('reduce-'+cid)),'--timeout','240','--godot',GODOT])
if success:
    c=next(c for c in load(HERE/(success['bundle']+'.json'))['cases'] if c['case_id']==success['case'])
    c['initial']={'checkpoint':load(RAW/success['bundle']/'cases'/success['case']/'studio_checkpoint.json')};c['case_id']='policy-cold';c['target_release_count']=success['releases']+1;c['max_commands']=100;c['policy']['config']['label']='policy-cold';c.pop('study',None)
    write(HERE/'cold.json',dict(schema_version='1',policy=dict(script='policy.gd',id='crown-access-policy',version='1'),cases=[c]))
    run('cold','240')
