"""One predeclared ordinary six-release world, then exact fresh-process replay."""
from pathlib import Path
import hashlib,importlib.util,json,subprocess,time
ROOT=Path(__file__).resolve().parents[4];OUT=Path(__file__).resolve().parent
def load(name,path):
 spec=importlib.util.spec_from_file_location(name,path);module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module);return module
sim=load('sim',ROOT/'tools/simulate.py');compare=load('compare',ROOT/'tools/compare_simulations.py')
project=OUT/'final2/project';harness=ROOT/'docs/codex/findings/market-exposure-20261022-v1/exposure.gd'
script=OUT/'campaign.gd';script.write_bytes(harness.read_bytes())
identity=compare.mechanics_identity(sim.read_json(OUT/'final2/source.json'))
sim.write_json(OUT/'campaign-final-plan.json',{'source_identity':identity,'harness_sha256':sim.sha(script),'source_snapshot':'final2/source.json','route':'action-fantasy','seed':'4417','releases':6,'command_bound':180,'cycle_bound':48,'Godot_wall_bound_seconds':180,'process_guard_seconds':210,'scope':'Fresh legal world acceptance after UI changes; no new balance study or population claim.'})
for name,extra in [('campaign-final-record',[]),('campaign-final-replay',['--mode=replay','--input='+str(OUT/'campaign-final-record.json.tape.json')])]:
 env=sim.isolated_environment(OUT/(name+'-profile'))
 command=[r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe','--headless','--audio-driver','Dummy','--path',str(project),'--script',str(script),'--','--route=action-fantasy','--seed=4417','--source='+identity,'--output='+str(OUT/(name+'.json')),*extra]
 start=time.perf_counter()
 with (OUT/(name+'.log')).open('wb') as log:result=subprocess.run(command,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=210)
 lines=(OUT/(name+'.log')).read_text(encoding='utf8',errors='replace').splitlines()
 row={'command':command,'exit':result.returncode,'elapsed_seconds':time.perf_counter()-start,'errors':[x for x in lines if 'SCRIPT ERROR' in x or x.startswith('ERROR:')],'tail':lines[-5:]}
 sim.write_json(OUT/(name+'-process.json'),row);print(json.dumps(row),flush=True)
 if row['exit'] or row['errors']:raise SystemExit(1)
