from pathlib import Path
import sys,json
H=Path(__file__).resolve().parent;R=H.parents[5];T=H.parents[1]
sys.path.insert(0,str(R/'tools'));import simulate as sim
source=T/'sims/sidestreet-p1-balanced-1-20261023-v1'
out=H/'checks-v1';out.mkdir()
godot=Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')
env=sim.isolated_environment(out/'profile')
manifest=sim.copy_snapshot(source/'project',out/'project')
sim.write_json(out/'source-manifest.json',manifest)
sim.import_project(godot,out/'project',out,env,600)
results=[]
jobs=[('audit',str(H/'audit.gd'),[str(source/'cases/action-1104-balanced/studio_checkpoint.json'),str(out/'audit.json')]),('challenge-matrix','res://scripts/debug/verify_contract_challenge_matrix.gd',[]),('contract-extraction','res://scripts/debug/verify_contract_extraction.gd',[])]
for name,script,args in jobs:
    job=out/name;job.mkdir()
    jobenv=sim.isolated_environment(job/'profile');jobenv['PN_CARD_FRAME_OUTPUT']=str(job/'result.json')
    argv=[str(godot),'--headless','--path',str(out/'project'),'--script',script,'--',*args]
    try:
        sim.run_process(name,argv,job,jobenv,600);results.append({'job':name,'ok':True})
    except RuntimeError as e: results.append({'job':name,'ok':False,'error':str(e)})
    print(json.dumps(results[-1]),flush=True)
sim.write_json(out/'results.json',results)
