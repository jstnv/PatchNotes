"""Serial isolated follow-ups; the independent full matrix may run concurrently."""
from pathlib import Path
import importlib.util, json, subprocess, sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
RAW = Path('C:/Users/64jus/AppData/Local/Temp/pn-queue-closeout-20261024-v1')
PYTHON = sys.executable
GODOT = 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
VARIANT = ROOT / 'docs/codex/threads/simulation-engine/simulators/queue-crown-access-20261024-v1'
results = []


def run(name, command, timeout=360):
    with (RAW / (name + '-driver.log')).open('x', encoding='utf-8') as output:
        child = subprocess.run(command, cwd=ROOT, stdout=output, stderr=subprocess.STDOUT, timeout=timeout)
    results.append({'name': name, 'command': command, 'exit': child.returncode})
    (RAW / 'followups-result.json').write_text(json.dumps(results, indent=2) + '\n', encoding='utf-8')
    print(name, child.returncode, flush=True)
    if child.returncode:
        raise RuntimeError('Retained failing follow-up: ' + name)


for label, case in [('fresh', 'balanced_safe-action-4521-none'), ('failed', 'balanced_safe-puzzle-4521-none')]:
    run('crown-replay-' + label, [PYTHON, '-X', 'utf8', 'tools/simulate.py', 'replay', '--bundle', str(RAW / 'crown-conservative'),
                                '--case', case, '--output', str(RAW / ('crown-replay-' + label)), '--godot', GODOT, '--timeout', '240'])

cold_config = HERE / 'crown-cold.json'
run('prepare-crown-cold', [PYTHON, '-X', 'utf8', 'docs/codex/threads/simulation-engine/examples/prepare-continuation.py',
                         '--bundle', str(RAW / 'crown-conservative'), '--case', 'balanced_safe-action-4418-cult',
                         '--case-id', 'crown-cold-4418', '--target-release-count', '7', '--max-commands', '40', '--output', str(cold_config)])
run('crown-cold', [PYTHON, '-X', 'utf8', 'tools/simulate.py', 'run', '--variant', str(VARIANT), '--config', str(cold_config),
                   '--output', str(RAW / 'crown-cold'), '--godot', GODOT, '--timeout', '240'])

# Reproduce every shared-parent warm/cold combination through the corrected
# nondefault-port wrapper path. Do not use any production profile or port.
run('cold-wrapper-continuation', [PYTHON, '-X', 'utf8', 'docs/codex/findings/overnight-20261024-v1/all_checks.py',
     '--output', str(RAW / 'cold-wrappers'), '--port', '47737', '--tests',
     'verify_alpha_shop_pack', 'verify_alpha_shop_pack_cold', 'verify_legacy_world',
     'verify_founder_victory_cold', 'verify_world_restore_file', 'verify_market_release_index', 'verify_market_release_index_cold'], 900)

# The exporter keeps all outputs in its supplied fresh directory and uses the
# locally cached, hash-pinned official templates. It downloads nothing.
run('package', [PYTHON, '-X', 'utf8', str(HERE / 'package.py')], 600)
