from pathlib import Path
import sys,json
H=Path(__file__).resolve().parent;R=H.parents[5];T=H.parents[1]
sys.path.insert(0,str(R/'tools'));import simulate as sim
out=H/'assembly-v1';out.mkdir()
godot=Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')
env=sim.isolated_environment(out/'profile')
sim.write_json(out/'source-manifest.json',sim.copy_snapshot(T/'simulators/sidestreet-commission-p1-v1/project',out/'project'))
sim.import_project(godot,out/'project',out,env,600)
sim.run_process('arithmetic',[str(godot),'--headless','--path',str(out/'project'),'--script',str(H/'arithmetic.gd')],out,env,600)
print('Assembly arithmetic and API PASS')
