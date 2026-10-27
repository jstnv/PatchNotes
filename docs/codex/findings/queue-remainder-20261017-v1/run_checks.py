from pathlib import Path
import importlib.util, json, re, shutil, subprocess, sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[3]
GODOT = Path(r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe')
spec = importlib.util.spec_from_file_location('sim', ROOT / 'tools/simulate.py')
sim = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sim)
project = BASE / 'project'
resume = '--resume' in sys.argv
hashes = sim.read_json(BASE / 'source.json') if resume else sim.copy_snapshot(ROOT / 'patch-notes', project)
if resume:
    assert all(sim.sha(ROOT / 'patch-notes' / k) == v for k,v in hashes.items())
    assert all(sim.sha(project / k) == v for k,v in hashes.items())
sim.write_json(BASE / 'source.json', hashes)
sim.write_json(BASE / 'engine.json', {'version': subprocess.check_output([str(GODOT), '--version'], text=True).strip(), 'sha256': sim.sha(GODOT)})
results = sim.read_json(BASE / 'results.json') if resume else []

def run(name, args, graphical=False, extra=None):
    if any(r['name'] == name and r['exit'] == 0 and not r['errors'] for r in results): return
    env = sim.isolated_environment(ROOT / '.codex-godot-temp' / ('remainder-1017-' + name))
    env['PN_CARD_FRAME_OUTPUT'] = str(BASE / (name + '-result.json'))
    env.update(extra or {})
    cmd = [str(GODOT), *([] if graphical else ['--headless']), '--audio-driver', 'Dummy', '--path', str(project), *args]
    with (BASE / (name + '.log')).open('wb') as log:
        done = subprocess.run(cmd, env=env, stdout=log, stderr=subprocess.STDOUT, timeout=240)
    lines = (BASE / (name + '.log')).read_text(encoding='utf-8', errors='replace').splitlines()
    errors = [s for s in lines if re.search(r'SCRIPT ERROR|Parse Error|^ERROR:|FAIL:', s)]
    row = {'name': name, 'command': cmd, 'exit': done.returncode, 'errors': errors,
           'summary': [s for s in lines if re.search(r'passed|checks|failures', s, re.I)][-5:]}
    results.append(row)
    sim.write_json(BASE / 'results.json', results)
    print(json.dumps(row), flush=True)
    if done.returncode or errors: raise RuntimeError(name)

run('import', ['--editor', '--import', '--quit'])
for name in ['verify_gameplay_hud_overlay', 'verify_design_phase', 'verify_alpha_phase', 'verify_beta_base_hand_resolution', 'verify_three_core']:
    run(name, ['--script', 'res://scripts/debug/' + name + '.gd'])
for width in [1152, 1280]:
    run('render-' + str(width), ['--script', str(BASE / 'capture_workspace.gd')], graphical=True,
        extra={'PN_CAPTURE_WIDTH': str(width), 'PN_CAPTURE_DIR': str(BASE)})
changed = [k for k,v in hashes.items() if sim.sha(ROOT / 'patch-notes' / k) != v]
assert not changed, changed
sim.write_json(BASE / 'source-stability.json', {'changed': changed, 'files': len(hashes)})
