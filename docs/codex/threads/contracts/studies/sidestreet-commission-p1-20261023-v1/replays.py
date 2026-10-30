from pathlib import Path
import sys,json,subprocess
from paths import bundle as selected_bundle
H=Path(__file__).resolve().parent;R=H.parents[5];T=H.parents[1];tag=sys.argv[1]
g='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
bundle=selected_bundle('delivery',tag)
results=[]
for case in ['long-commission','long-owned','short-commission']:
    out=T/f'sims/sidestreet-commission-p1-replay-{case}-20261023-{tag}'
    argv=[sys.executable,str(R/'tools/simulate.py'),'replay','--bundle',str(bundle),'--case',case,'--output',str(out),'--godot',g,'--timeout','600']
    p=subprocess.run(argv,cwd=R,capture_output=True,text=True)
    result=dict(case=case,argv=argv,exit=p.returncode,stdout=p.stdout,stderr=p.stderr)
    results.append(result)
    with (H/f'replay-{case}-{tag}.command.json').open('x') as f:json.dump(result,f,indent=2)
    print(json.dumps(result),flush=True)
with (H/f'replays-{tag}.json').open('x') as f:json.dump(results,f,indent=2)
sys.exit(0 if all(x['exit']==0 for x in results) else 1)
