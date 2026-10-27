from pathlib import Path
import importlib.util,json,subprocess,sys,time

out=Path(__file__).resolve().parent
root=out.parents[3]
spec=importlib.util.spec_from_file_location('sim',root/'tools/simulate.py')
sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
label=sys.argv[1]
env=sim.isolated_environment(out/('profile-'+label))
env['PN_CARD_FRAME_OUTPUT']=str(out/(label+'.json'))
env['PN_BANK_AGE_DIR']=str(out)
cmd=[r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe','--headless','--audio-driver','Dummy','--path',str(root/'patch-notes'),'--script',str(out/sys.argv[2])]
if len(sys.argv)>3:cmd+=['--']+sys.argv[3:]
start=time.perf_counter()
with (out/(label+'.log')).open('wb') as log:r=subprocess.run(cmd,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=300)
lines=(out/(label+'.log')).read_text(encoding='utf-8',errors='replace').splitlines()
errors=[line for line in lines if any(x in line for x in ['ERROR:','SCRIPT ERROR','FAIL:'])]
record={'command':cmd,'exit':r.returncode,'elapsed':time.perf_counter()-start,'errors':errors,'tail':lines[-8:]}
(out/(label+'-run.json')).write_text(json.dumps(record,indent=2),encoding='utf-8')
print(json.dumps(record),flush=True)
sys.exit(1 if errors else r.returncode)
