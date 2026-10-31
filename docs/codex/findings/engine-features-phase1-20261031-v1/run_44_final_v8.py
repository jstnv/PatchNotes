import sys,json,subprocess
from pathlib import Path
sys.path.insert(0,str(Path.cwd()));from tools import simulate as sim
base=Path(__file__).resolve().parent;out=base/'godot44-check-final-v8';out.mkdir();project=base/'godot44-project';godot=base/'godot44/Godot_v4.4-stable_win64_console.exe';env=sim.isolated_environment(out/'profile')
try:
 hashes=sim.source_hashes(project);sim.write_json(out/"snapshot-manifest.json",hashes)
 args=[str(godot),'--headless','--audio-driver','Dummy','--path',str(project),'--script',str(base/'verify_phase1_v9.gd'),'--quit-after','1000','--','--output='+str(out/'report.json'),'--legacy='+str(base/'legacy-pending.json')]
 sim.run_process('acceptance',args,out,env,180);sim.check_snapshot(project,hashes);print('Godot4.4 PASS')
except Exception as e:
 print(type(e).__name__,str(e));sys.exit(1)
