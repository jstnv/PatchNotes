from pathlib import Path
import importlib.util, json, socket, subprocess, sys

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
spec = importlib.util.spec_from_file_location('sim', ROOT / 'tools/simulate.py')
sim = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sim)
label = sys.argv[1]
script = sys.argv[2] if len(sys.argv) > 2 else str(OUT / 'probe.gd')
env = sim.isolated_environment(OUT / ('profile-' + label))
env['PN_CARD_FRAME_OUTPUT'] = str(OUT / (label + '.json'))
env['PN_PAUSE_FILTER_CANDIDATE'] = '1' if label == 'candidate' else '0'
with socket.socket() as sock:
    sock.bind(('127.0.0.1', 0))
    env['PN_CHECKPOINT_TEST_PORT'] = str(sock.getsockname()[1])
command = [r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe',
           '--headless', '--audio-driver', 'WASAPI', '--path', str(ROOT / 'patch-notes'), '--script', script]
if label == 'native':
    command.remove('--headless')
    command.extend(['--rendering-method', 'gl_compatibility', '--resolution', '1152x648', '--position', '80,80'])
elif label in ['pause_music', 'pause_menu', 'sync', 'regression-old']:
    command[command.index('WASAPI')] = 'Dummy'
with (OUT / (label + '.log')).open('wb') as log:
    result = subprocess.run(command, env=env, stdout=log, stderr=subprocess.STDOUT, timeout=130)
lines = (OUT / (label + '.log')).read_text(encoding='utf-8', errors='replace').splitlines()
errors = [line for line in lines if any(x in line for x in ['SCRIPT ERROR', 'Parse Error', 'ERROR:', 'FAIL:'])]
record = {'command': command, 'exit': result.returncode, 'errors': errors, 'tail': lines[-8:]}
(OUT / (label + '-run.json')).write_bytes((json.dumps(record, indent=2) + '\n').encode())
print(json.dumps(record), flush=True)
sys.exit(1 if errors else result.returncode)
