"""Continue after the retained pre-import source-capture collision."""
from pathlib import Path
import json, subprocess, sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
RAW = Path('C:/Users/64jus/AppData/Local/Temp/pn-queue-closeout-20261024-v1')
PYTHON = sys.executable
GODOT = 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
results = []
jobs = [
    ('crown-cold-v2', [PYTHON, '-X', 'utf8', 'tools/simulate.py', 'run', '--variant',
     'docs/codex/threads/simulation-engine/simulators/queue-crown-access-20261024-v1', '--config', str(HERE / 'crown-cold.json'),
     '--output', str(RAW / 'crown-cold-v2'), '--godot', GODOT, '--timeout', '240'], 360),
    ('corrected-continuation', [PYTHON, '-X', 'utf8', 'docs/codex/findings/overnight-20261024-v1/all_checks.py',
     '--output', str(RAW / 'corrected-continuation'), '--port', '47737', '--tests',
     'verify_alpha_shop_pack', 'verify_alpha_shop_pack_cold', 'verify_legacy_world',
     'verify_founder_victory_cold', 'verify_world_restore_file', 'verify_market_release_index',
     'verify_market_release_index_cold', 'verify_market_browser'], 900),
    ('package', [PYTHON, '-X', 'utf8', str(HERE / 'package.py')], 600),
]
for name, command, timeout in jobs:
    with (RAW / (name + '-driver.log')).open('x', encoding='utf-8') as stream:
        child = subprocess.run(command, cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT, timeout=timeout)
    results.append({'name': name, 'command': command, 'exit': child.returncode})
    (RAW / 'followups-continuation-result.json').write_text(json.dumps(results, indent=2) + '\n', encoding='utf-8')
    print(name, child.returncode, flush=True)
    if child.returncode:
        raise RuntimeError('Retained failure: ' + name)
