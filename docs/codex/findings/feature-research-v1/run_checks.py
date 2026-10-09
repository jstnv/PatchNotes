"""Focused checks and seven separate-process checkpoint boundaries."""
from pathlib import Path
import json, os, subprocess, sys, tempfile

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / 'checkpoint-runtime-v1'))
import run_checks as checks
checks.HERE = HERE
NAMES = [
    'verify_feature_research', 'verify_research_integration', 'verify_research_ui',
    'verify_studio_checkpoint', 'verify_studio_traits', 'verify_studio_folder_menu',
    'verify_feature_store_cycle_purchase', 'verify_first_studio_feature_economy',
    'verify_studio_specialties', 'verify_feature_spending_guidance',
    'verify_store_shopping_guidance', 'verify_predevelopment',
    'verify_sidestreet_scope_and_year', 'verify_feature_store',
    'verify_feature_store_navigation', 'verify_feature_store_radial', 'verify_first_game_and_tips',
]

def main():
    for name in NAMES:
        checks.run(name, ['--script', 'res://scripts/debug/' + name + '.gd'], timeout=120)
    profile = Path(tempfile.mkdtemp(prefix='research-restart-', dir=checks.PROFILE))
    env = os.environ.copy()
    for key in ('APPDATA', 'LOCALAPPDATA'):
        path = profile / key
        path.mkdir()
        env[key] = str(path)
    records = []
    for index, mode in enumerate(['initial', 'admit', 'inspect-admission', 'partial', 'inspect-partial', 'complete', 'inspect-completion']):
        command = [checks.GODOT, '--headless', '--path', str(checks.PROJECT), '--script', 'res://scripts/debug/research_restart_probe.gd', '--', mode]
        result = subprocess.run(command, env=env, capture_output=True, timeout=60)
        output = (result.stdout + result.stderr).decode(errors='replace')
        (HERE / f'restart-{index}-{mode}.log').write_text(output, encoding='utf-8')
        errors = [line for line in output.splitlines() if ('ERROR:' in line or 'FAIL:' in line) and 'root certificate store' not in line]
        records.append({'command': command, 'exit': result.returncode, 'errors': errors})
        (HERE / 'restart-results.json').write_text(json.dumps(records, indent=2), encoding='utf-8')
        print(mode, result.returncode, errors, flush=True)
        if result.returncode or errors:
            raise RuntimeError(mode)

if __name__ == '__main__':
    main()
