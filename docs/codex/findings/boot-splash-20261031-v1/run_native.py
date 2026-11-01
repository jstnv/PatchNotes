"""Read-only native startup with an isolated profile and finite lifetime."""
from pathlib import Path
import argparse, json, socket, subprocess, sys, time

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT))
from tools import simulate as sim

p = argparse.ArgumentParser()
p.add_argument('--size', required=True)
p.add_argument('--frames', type=int, default=900)
p.add_argument('--output', type=Path, required=True)
a = p.parse_args()
out = a.output.resolve()
out.mkdir(exist_ok=False, parents=True)
env = sim.isolated_environment(out / 'profile')
with socket.socket() as s:
    s.bind(('127.0.0.1', 0))
    env['PN_CHECKPOINT_TEST_PORT'] = str(s.getsockname()[1])
argv = ['C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64.exe',
        '--path', str(ROOT / 'patch-notes'), '--audio-driver', 'Dummy',
        '--resolution', a.size, '--quit-after', str(a.frames)]
# Give the separate native-window observer time to start. No game setting changes.
time.sleep(2)
with (out / 'godot.log').open('wb') as f:
    result = subprocess.run(argv, env=env, stdout=f, stderr=subprocess.STDOUT, timeout=45)
log = (out / 'godot.log').read_text(encoding='utf-8', errors='replace')
errors = [line for line in log.splitlines() if line.startswith(('ERROR:', 'SCRIPT ERROR:'))]
report = {'argv': argv, 'exit': result.returncode, 'errors': errors, 'ok': result.returncode == 0 and not errors}
sim.write_json(out / 'result.json', report)
print(json.dumps(report))
sys.exit(0 if report['ok'] else 1)
