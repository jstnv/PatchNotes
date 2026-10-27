"""Launch the actual release binary with one explicitly isolated acceptance profile."""
from pathlib import Path
import importlib.util,json,subprocess,sys,time
OUT=Path(__file__).resolve().parent;ROOT=OUT.parents[3]
spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py')
sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
label,profile=sys.argv[1:3]
env=sim.isolated_environment(OUT/('profile-'+profile))
exe=OUT/'export-v6/clean/demo/Patch Notes Demo.exe'
command=[str(exe),'--audio-driver','Dummy','--rendering-method','gl_compatibility','--resolution','1152x648','--position','80,80']
with (OUT/(label+'.log')).open('wb') as log:
    process=subprocess.Popen(command,cwd=exe.parent,env=env,stdout=log,stderr=subprocess.STDOUT)
    (OUT/(label+'-process.json')).write_text(json.dumps({'pid':process.pid,'command':command,'profile':profile}),encoding='utf-8')
    print('RELEASE_PID',process.pid,flush=True)
    start=time.perf_counter()
    try:process.wait(timeout=600)
    except subprocess.TimeoutExpired:process.kill();process.wait()
lines=(OUT/(label+'.log')).read_text(encoding='utf-8',errors='replace').splitlines()
errors=[x for x in lines if 'ERROR:' in x or 'SCRIPT ERROR' in x]
result={'exit':process.returncode,'errors':errors,'elapsed_seconds':time.perf_counter()-start,'profile':profile}
(OUT/(label+'-run.json')).write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps(result),flush=True)
sys.exit(1 if errors else process.returncode)
