from pathlib import Path
import ctypes, importlib.util, json, socket, subprocess, sys, time
from ctypes import wintypes
OUT=Path(__file__).resolve().parent;ROOT=OUT.parents[3]
spec=importlib.util.spec_from_file_location('sim',ROOT/'tools/simulate.py')
sim=importlib.util.module_from_spec(spec);spec.loader.exec_module(sim)
label,script=sys.argv[1:3]
user_args=sys.argv[3:]
profile=next((x.removeprefix('--profile=') for x in user_args if x.startswith('--profile=')),label)
user_args=[x for x in user_args if not x.startswith('--profile=')]
env=sim.isolated_environment(OUT/('profile-'+profile))
with socket.socket() as sock:
    sock.bind(('127.0.0.1',0));env['PN_CHECKPOINT_TEST_PORT']=str(sock.getsockname()[1])
pack=OUT/'export-v6/clean/demo/Patch Notes Demo.pck'
exe=pack.with_suffix('.exe')
command=[str(exe),'--audio-driver','Dummy','--script',str(Path(script).resolve())]
if 'pack-' in label:
    command=[r'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64.exe','--main-pack',str(pack),'--audio-driver','Dummy','--script',str(Path(script).resolve())]
if label=='release-smoke':command=[str(exe),'--audio-driver','Dummy','--quit-after','30']
if label.startswith('native'):
    command.extend(['--rendering-method','gl_compatibility','--resolution','1152x648','--position','80,80'])
else:command.append('--headless')
if user_args:command.extend(['--']+user_args)
with (OUT/(label+'.log')).open('wb') as log:
    start=time.perf_counter();process=subprocess.Popen(command,cwd=OUT,env=env,stdout=log,stderr=subprocess.STDOUT)
    (OUT/(label+'-process.json')).write_text(json.dumps({'pid':process.pid,'command':command}),encoding='utf-8')
    try:process.wait(timeout=300)
    except subprocess.TimeoutExpired:process.kill();process.wait()
    elapsed=time.perf_counter()-start
    times=[wintypes.FILETIME() for _ in range(4)]
    ok=ctypes.windll.kernel32.GetProcessTimes(wintypes.HANDLE(int(process._handle)),*[ctypes.byref(t) for t in times])
    cpu=sum((t.dwHighDateTime<<32)+t.dwLowDateTime for t in times[2:])/10000000 if ok else None
lines=(OUT/(label+'.log')).read_text(encoding='utf-8',errors='replace').splitlines()
errors=[line for line in lines if any(x in line for x in ['SCRIPT ERROR','Parse Error','ERROR:','FAIL:'])]
record={'command':command,'exit':process.returncode,'errors':errors,'elapsed_seconds':elapsed,'process_cpu_seconds':cpu,'tail':lines[-10:]}
(OUT/(label+'-run.json')).write_text(json.dumps(record,indent=2),encoding='utf-8')
print(json.dumps(record),flush=True)
sys.exit(1 if errors else process.returncode)
