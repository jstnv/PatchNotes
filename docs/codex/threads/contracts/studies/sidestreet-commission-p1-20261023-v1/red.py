from pathlib import Path
import sys,json
H=Path(__file__).resolve().parent; R=H.parents[5]; T=H.parents[1]
sys.path.insert(0,str(R/'tools'));import simulate as sim
out=H/'red';out.mkdir()
godot=Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')
env=sim.isolated_environment(out/'profile')
sim.write_json(out/'source-manifest.json',sim.copy_snapshot(T/'simulators/sidestreet-p1-gate-v1/project',out/'project'))
sim.import_project(godot,out/'project',out,env,600)
try:sim.run_process('probe',[str(godot),'--headless','--path',str(out/'project'),'--script',str(H/'probe.gd')],out,env,600)
except RuntimeError as e:print(str(e))
v=sim.read_json(out/'probe.command.json');assert v['exit']==1 and 'COMMISSION_API_PRESENT=false' in (out/'probe.log').read_text()
print('Expected missing commission API RED confirmed')
