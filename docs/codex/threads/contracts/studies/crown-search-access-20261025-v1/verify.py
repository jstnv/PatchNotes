from run import *
rows=load(HERE/'analysis.json')['rows']
available=[r for r in rows if r['access'] and r['status']=='completed']
failed=[r for r in rows if r['rejection']]
selected=([available[0]] if available else [])+([failed[0]] if failed else [])
write(HERE/'verification-selection.json',dict(replay=[r['case'] for r in selected],reduction=failed[0]['case'] if failed else None))
for row in selected:
 cid=row['case']
 execute('replay-'+cid,[sys.executable,'tools/simulate.py','replay','--bundle',str(RAW/row['pair']),'--case',cid,'--output',str(RAW/('replay-'+cid)),'--timeout','240','--godot',GODOT])
if failed:
 row=failed[0];cid=row['case']
 execute('reduce-'+cid,[sys.executable,'tools/reduce_simulation.py','--bundle',str(RAW/row['pair']),'--case',cid,'--kind','rejection','--max-commands','500','--output',str(RAW/('reduce-'+cid)),'--timeout','240','--godot',GODOT])
if available:
 row=available[0];cid=row['case']
 if execute('prepare-cold',[sys.executable,'docs/codex/threads/simulation-engine/examples/prepare-continuation.py','--bundle',str(RAW/row['pair']),'--case',cid,'--case-id','access-cold','--target-release-count',str(row['releases']+1),'--max-commands','30','--output',str(HERE/'cold.json')])==0:
  execute('cold',[sys.executable,'tools/simulate.py','run','--variant',str(VAR),'--config',str(HERE/'cold.json'),'--output',str(RAW/'cold'),'--timeout','240','--godot',GODOT])
