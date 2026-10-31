from pathlib import Path
import importlib.util
import subprocess

ROOT = Path(__file__).resolve().parents[4]
SPEC = importlib.util.spec_from_file_location('sim', ROOT / 'tools/simulate.py')
sim = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(sim)
project = ROOT / 'docs/codex/threads/simulation-engine/simulators/action-pass-budget-base-20261030-v1/project'
script = Path(__file__).with_name('pass_budget_bank_probe.gd')
env = sim.isolated_environment(ROOT / 'docs/codex/threads/simulation-engine/pass-budget-bank-profile-2')
result = subprocess.run([
    r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe',
    '--headless', '--path', str(project), '--script', str(script)
], env=env, capture_output=True, text=True, timeout=60)
for line in (result.stdout + result.stderr).splitlines():
    if 'principal' in line or 'SCRIPT ERROR' in line or 'ERROR:' in line or 'Fresh session' in line:
        print(line[:2000])
print('exit', result.returncode)
