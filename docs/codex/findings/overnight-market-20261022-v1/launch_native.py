from pathlib import Path
import importlib.util,json,subprocess
OUT=Path(__file__).resolve().parent;ROOT=OUT.parents[3]
spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py');sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
env=sim.isolated_environment(OUT/'native-profile')
command=[r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe','--path',str(OUT/'d/project'),'--rendering-method','gl_compatibility']
with (OUT/'native-play.log').open('wb') as log:
 process=subprocess.Popen(command,env=env,stdout=log,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
 sim.write_json(OUT/'native-process.json',{'pid':process.pid,'command':command,'profile':str(OUT/'native-profile')});print(process.pid,flush=True)
 code=process.wait();sim.write_json(OUT/'native-exit.json',{'exit':code})
