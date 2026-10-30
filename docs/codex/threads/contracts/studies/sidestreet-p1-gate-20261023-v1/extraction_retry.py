from pathlib import Path
import sys,json,shutil
H=Path(__file__).resolve().parent;R=H.parents[5];T=H.parents[1]
sys.path.insert(0,str(R/'tools'));import simulate as sim
out=H/'extraction-v2';out.mkdir()
godot=Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')
env=sim.isolated_environment(out/'profile');env['PN_CARD_FRAME_OUTPUT']=str(out/'result.json')
source=T/'sims/sidestreet-p1-balanced-1-20261023-v1/project'
sim.write_json(out/'source-manifest.json',sim.copy_snapshot(source,out/'project'))
relative=Path('docs/codex/threads/simulation-engine/m3b-v1/contract_phase_oracle.gd')
target=out/relative;target.parent.mkdir(parents=True);shutil.copyfile(R/relative,target)
sim.write_json(out/'oracle-identity.json',{'original':str(R/relative),'sha256':sim.sha(target),'original_sha256':sim.sha(R/relative)})
sim.import_project(godot,out/'project',out,env,600)
sim.run_process('extraction',[str(godot),'--headless','--path',str(out/'project'),'--script','res://scripts/debug/verify_contract_extraction.gd'],out,env,600)
v=sim.read_json(out/'result.json');print(json.dumps({k:v[k] for k in ['failures','comparisons']}))
