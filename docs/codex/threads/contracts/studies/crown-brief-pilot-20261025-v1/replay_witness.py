from run import *
rows=load(HERE/'witness-analysis.json')['rows']
row=next((r for r in rows if r['ok'] and r['full']>0),None)
assert row,'no full witness; preserve misses without more search'
write(HERE/'full-witness-selection.json',row)
name='replay-full-witness'
execute(name,[PY,'tools/simulate.py','replay','--bundle',str(RAW/'witness'),'--case',row['case'],'--output',str(RAW/name),'--timeout','480','--godot',GODOT])
