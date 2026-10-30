from pathlib import Path
import sys,json,subprocess
H=Path(__file__).resolve().parent;R=H.parents[5];T=H.parents[1]
g='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
results=[]
for case in ['sports-1112','action-1108']:
    out=T/f'sims/sidestreet-commission-p1-prefix-replay-{case}-20261023-v3'
    argv=[sys.executable,str(R/'tools/simulate.py'),'replay','--bundle',str(T/'sims/sidestreet-commission-p1-prefix-20261023-v3'),'--case',case,'--output',str(out),'--godot',g,'--timeout','600']
    p=subprocess.run(argv,cwd=R,capture_output=True,text=True)
    row=dict(case=case,argv=argv,exit=p.returncode,stdout=p.stdout,stderr=p.stderr);results.append(row)
    with (H/f'prefix-replay-{case}.command.json').open('x') as f:json.dump(row,f,indent=2)
    print(json.dumps(row),flush=True)
with (H/'prefix-replays.json').open('x') as f:json.dump(results,f,indent=2)
sys.exit(0 if all(x['exit']==0 for x in results) else 1)
