from pathlib import Path
import importlib.util, json, socket, subprocess, sys, time, ctypes

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
spec = importlib.util.spec_from_file_location('sim', ROOT / 'tools/simulate.py')
sim = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sim)
label = sys.argv[1]
script = sys.argv[2] if len(sys.argv) > 2 else str(OUT / 'probe.gd')
env = sim.isolated_environment(OUT / ('profile-' + label))
env['PN_CARD_FRAME_OUTPUT'] = str(OUT / (label + '.json'))
env['PN_ROSTER_PRIOR'] = str(ROOT / 'docs/codex/findings/queue-20261018-v2/prior-v2.json')
env['PN_ROSTER_OUTPUT'] = str(OUT)
env['PN_GAMEPLAY_PRIOR_SAVES'] = str(ROOT/'docs/codex/findings/store-gameplay-links-20261018-v1/before/produce_gameplay_prior.json')
with socket.socket() as sock:
    sock.bind(('127.0.0.1', 0))
    env['PN_CHECKPOINT_TEST_PORT'] = str(sock.getsockname()[1])
command = [r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe',
           '--headless', '--audio-driver', 'Dummy', '--path', str(ROOT / 'patch-notes'), '--script', script]
if label.startswith('native'):
    command.remove('--headless')
    command.extend(['--rendering-method', 'gl_compatibility', '--resolution', '1152x648', '--position', '80,80'])
if len(sys.argv) > 3: command.extend(['--']+sys.argv[3:])
with (OUT / (label + '.log')).open('wb') as log:
    started=time.perf_counter()
    result=subprocess.Popen(command,env=env,stdout=log,stderr=subprocess.STDOUT)
    (OUT / (label + '-process.json')).write_text(json.dumps({'pid':result.pid,'command':command}),encoding='utf-8')
    try:
        result.wait(timeout=300)
    except subprocess.TimeoutExpired:
        result.kill()
        result.wait()
    elapsed=time.perf_counter()-started
    from ctypes import wintypes
    times=[wintypes.FILETIME() for _ in range(4)]
    got_times=ctypes.windll.kernel32.GetProcessTimes(wintypes.HANDLE(int(result._handle)),*[ctypes.byref(t) for t in times])
    cpu=sum((t.dwHighDateTime << 32) + t.dwLowDateTime for t in times[2:])/10000000 if got_times else None
lines = (OUT / (label + '.log')).read_text(encoding='utf-8', errors='replace').splitlines()
errors = [line for line in lines if any(x in line for x in ['SCRIPT ERROR', 'Parse Error', 'ERROR:', 'FAIL:'])]
record = {'elapsed_seconds':elapsed,'process_cpu_seconds':cpu,'command': command, 'exit': result.returncode, 'errors': errors, 'tail': lines[-8:]}
(OUT / (label + '-run.json')).write_bytes((json.dumps(record, indent=2) + '\n').encode())
print(json.dumps(record), flush=True)
sys.exit(1 if errors else result.returncode)
