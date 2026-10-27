"""Run one bounded study process with isolated files and actual process CPU."""
from pathlib import Path
import ctypes
from ctypes import wintypes
import importlib.util
import json
import socket
import subprocess
import sys
import time

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
spec = importlib.util.spec_from_file_location('sim', ROOT/'tools/simulate.py')
sim = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sim)
label, *arguments = sys.argv[1:]
output = OUT/(label+'.json')
if output.exists() or (OUT/(label+'.log')).exists():
    raise SystemExit('New output tag required; prior evidence is retained.')
env = sim.isolated_environment(OUT/('profile-'+label))
with socket.socket() as sock:
    sock.bind(('127.0.0.1', 0))
    env['PN_CHECKPOINT_TEST_PORT'] = str(sock.getsockname()[1])
command = [r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe',
           '--headless','--audio-driver','Dummy','--path',str(ROOT/'patch-notes'),
           '--script',str(OUT/'exposure.gd'),'--','--output='+str(output),*arguments]
started = time.perf_counter()
timed_out = False
with (OUT/(label+'.log')).open('wb') as log:
    process = subprocess.Popen(command,env=env,stdout=log,stderr=subprocess.STDOUT)
    (OUT/(label+'-process.json')).write_text(json.dumps({'pid':process.pid,'command':command}),encoding='utf-8')
    try:
        process.wait(timeout=210)
    except subprocess.TimeoutExpired:
        timed_out = True
        process.kill()
        process.wait()
    elapsed = time.perf_counter()-started
    times = [wintypes.FILETIME() for _ in range(4)]
    got_times = ctypes.windll.kernel32.GetProcessTimes(wintypes.HANDLE(int(process._handle)),*[ctypes.byref(t) for t in times])
    cpu = sum((t.dwHighDateTime<<32)+t.dwLowDateTime for t in times[2:])/10000000 if got_times else None
lines = (OUT/(label+'.log')).read_text(encoding='utf-8',errors='replace').splitlines()
errors = [line for line in lines if any(x in line for x in ['SCRIPT ERROR','Parse Error','ERROR:','FAIL:'])]
report = {'elapsed_seconds':elapsed,'process_cpu_seconds':cpu,'command':command,
          'exit':process.returncode,'timed_out':timed_out,'errors':errors,'tail':lines[-8:]}
(OUT/(label+'-run.json')).write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report),flush=True)
raise SystemExit(1 if errors or timed_out else process.returncode)
