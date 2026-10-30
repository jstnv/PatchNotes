from pathlib import Path
import json,sys,subprocess
H=Path(__file__).resolve().parent;R=H.parents[5];T=H.parents[1]
godot='C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
results=[]
for index,case in enumerate(['action-1108-balanced','adventure-1104-balanced'],1):
    out=T/f'sims/sidestreet-p1-replay-{index}-20261023-v1'
    args=[sys.executable,str(R/'tools/simulate.py'),'replay','--bundle',str(T/'sims/sidestreet-p1-balanced-1-20261023-v1'),'--case',case,'--output',str(out),'--godot',godot,'--timeout','600']
    p=subprocess.run(args,cwd=R,capture_output=True,text=True)
    value={'case':case,'argv':args,'exit':p.returncode,'stdout':p.stdout,'stderr':p.stderr}
    (H/f'replay-{index}.command.json').write_text(json.dumps(value,indent=2),encoding='utf-8')
    results.append(value);print(json.dumps(value),flush=True)
(H/'replays.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
