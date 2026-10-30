from run import *
rows=load(HERE/'analysis.json')['rows'];winner=load(HERE/'selection.json')['selected']
selected=[next(r for r in rows if r['arm']==winner and r['pair']=='puzzle-4417')]
if (HERE/'confirmation.json').exists():selected.append(next(r for r in rows if r['arm']==winner and r['pair']=='puzzle-4418'))
for row in selected:
    execute('replay-'+row['case'],[sys.executable,'tools/simulate.py','replay','--bundle',str(RAW/row['bundle']),'--case',row['case'],'--output',str(RAW/('replay-'+row['case'])),'--timeout','240','--godot',GODOT])
failed=next((r for r in sorted(rows,key=lambda r:r['case']) if r['rejection']),None)
if failed:
    execute('reduce-'+failed['case'],[sys.executable,'tools/reduce_simulation.py','--bundle',str(RAW/failed['bundle']),'--case',failed['case'],'--kind','rejection','--max-commands','500','--output',str(RAW/('reduce-'+failed['case'])),'--timeout','240','--godot',GODOT])
success=next((r for r in sorted(rows,key=lambda r:r['case']) if r['arm']==winner and r['status']=='completed'),None)
write(HERE/'verification-selection.json',dict(replays=[r['case'] for r in selected],reduction=failed['case'] if failed else None,cold=success['case'] if success else None))
if success:
    c=next(c for c in load(HERE/(success['bundle']+'.json'))['cases'] if c['case_id']==success['case']);c=copy.deepcopy(c)
    c['initial']={'checkpoint':load(RAW/success['bundle']/'cases'/success['case']/'studio_checkpoint.json')};c['case_id']='puzzle-cold';c['target_release_count']=5;c['max_commands']=100;c['policy']['config']['label']='puzzle-cold';c.pop('study',None)
    write(HERE/'cold.json',config([c]));run('cold','240')
