from pathlib import Path
import importlib.util,subprocess
OUT=Path(__file__).resolve().parent;ROOT=OUT.parents[3]
spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py');sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
env=sim.isolated_environment(OUT/'native-campaign-profile')
engine=r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe'
prepare=[engine,'--headless','--audio-driver','Dummy','--path',str(OUT/'final/project'),'--script',str(OUT/'prepare_native_checkpoint.gd'),'--',str(OUT/'campaign-record.json.checkpoint.json'),str(OUT/'native-campaign-prepared.json')]
with (OUT/'native-campaign-prepare.log').open('wb') as log:r=subprocess.run(prepare,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=60)
if r.returncode:raise SystemExit(r.returncode)
command=[engine,'--path',str(OUT/'final/project'),'--rendering-method','gl_compatibility']
with (OUT/'native-campaign.log').open('wb') as log:
 p=subprocess.Popen(command,env=env,stdout=log,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
 sim.write_json(OUT/'native-campaign-process.json',{'pid':p.pid,'command':command,'profile':str(OUT/'native-campaign-profile')});print(p.pid,flush=True)
 sim.write_json(OUT/'native-campaign-exit.json',{'exit':p.wait()})
