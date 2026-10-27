"""Isolated acceptance runner with sampled native Windows peak working set.

No project or player profile changes; the invoked legal harness owns its report.
"""
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
spec = importlib.util.spec_from_file_location('sim', ROOT / 'tools/simulate.py')
sim = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sim)
label, script = sys.argv[1:3]
if (OUT / (label + '-run.json')).exists():
    raise SystemExit('Use a fresh result label')
env = sim.isolated_environment(OUT / ('profile-' + label))
env['PN_CARD_FRAME_OUTPUT'] = str(OUT / (label + '.json'))
with socket.socket() as sock:
    sock.bind(('127.0.0.1', 0))
    env['PN_CHECKPOINT_TEST_PORT'] = str(sock.getsockname()[1])
command = [r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe',
           '--headless', '--audio-driver', 'Dummy', '--path', str(ROOT / 'patch-notes'),
           '--script', script, '--', *sys.argv[3:]]

class MemoryCounters(ctypes.Structure):
    _fields_ = [('cb', wintypes.DWORD), ('PageFaultCount', wintypes.DWORD)] + [
        (name, ctypes.c_size_t) for name in ['PeakWorkingSetSize', 'WorkingSetSize',
        'QuotaPeakPagedPoolUsage', 'QuotaPagedPoolUsage', 'QuotaPeakNonPagedPoolUsage',
        'QuotaNonPagedPoolUsage', 'PagefileUsage', 'PeakPagefileUsage']]

memory_samples = []
timed_out = False
with (OUT / (label + '.log')).open('wb') as log:
    started = time.perf_counter()
    process = subprocess.Popen(command, env=env, stdout=log, stderr=subprocess.STDOUT)
    (OUT / (label + '-process.json')).write_text(json.dumps({'pid': process.pid, 'command': command}), encoding='utf-8')
    while process.poll() is None:
        counters = MemoryCounters()
        counters.cb = ctypes.sizeof(counters)
        if ctypes.windll.psapi.GetProcessMemoryInfo(wintypes.HANDLE(int(process._handle)), ctypes.byref(counters), counters.cb):
            memory_samples.append({'elapsed_seconds': time.perf_counter()-started,
                'working_set_bytes': counters.WorkingSetSize,
                'peak_working_set_bytes': counters.PeakWorkingSetSize,
                'pagefile_bytes': counters.PagefileUsage,
                'peak_pagefile_bytes': counters.PeakPagefileUsage})
        if time.perf_counter()-started > 300:
            timed_out = True
            process.kill()
            break
        time.sleep(0.1)
    process.wait()
    elapsed = time.perf_counter()-started
    times = [wintypes.FILETIME() for _ in range(4)]
    got_times = ctypes.windll.kernel32.GetProcessTimes(wintypes.HANDLE(int(process._handle)), *[ctypes.byref(t) for t in times])
    cpu = sum((t.dwHighDateTime << 32)+t.dwLowDateTime for t in times[2:])/10000000 if got_times else None
lines = (OUT / (label + '.log')).read_text(encoding='utf-8', errors='replace').splitlines()
errors = [line for line in lines if any(x in line for x in ['SCRIPT ERROR', 'Parse Error', 'ERROR:', 'FAIL:'])]
record = {'elapsed_seconds': elapsed, 'process_cpu_seconds': cpu, 'command': command,
    'exit': process.returncode, 'timed_out': timed_out, 'errors': errors, 'tail': lines[-8:],
    'memory_measurement': 'Native Windows GetProcessMemoryInfo every 0.1 seconds; peak working set is resident pages including shared mappings; sampled before process exit.',
    'peak_working_set_bytes': max((x['peak_working_set_bytes'] for x in memory_samples), default=None),
    'peak_pagefile_bytes': max((x['peak_pagefile_bytes'] for x in memory_samples), default=None),
    'memory_samples': memory_samples}
(OUT / (label + '-run.json')).write_text(json.dumps(record, indent=2)+'\n', encoding='utf-8')
print(json.dumps({k: v for k, v in record.items() if k != 'memory_samples'}), flush=True)
sys.exit(1 if errors or timed_out else process.returncode)
