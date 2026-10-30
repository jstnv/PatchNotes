from pathlib import Path
import sys,json
H=Path(__file__).resolve().parent;R=H.parents[5];T=H.parents[1]
sys.path.insert(0,str(R/'tools'));import simulate as sim
out=H/'observer-v1';out.mkdir()
godot=Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')
env=sim.isolated_environment(out/'profile')
source=T/'sims/sidestreet-p1-balanced-1-20261023-v1'
sim.write_json(out/'source-manifest.json',sim.copy_snapshot(source/'project',out/'project'))
sim.import_project(godot,out/'project',out,env,600)
case=source/'cases/action-1104-balanced'
args=[str(godot),'--headless','--path',str(out/'project'),'--script',str(H/'observer_audit.gd'),'--',str(case/'case.variant.json'),str(case/'replay.tape.json'),str(out/'result.json')]
sim.run_process('observer',args,out,env,600)
v=sim.read_json(out/'result.json');print(json.dumps({'checks':len(v['checks']),'failures':v['failures'],'observed':v['observed']}))
