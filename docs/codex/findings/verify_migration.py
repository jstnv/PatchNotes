"""Focused migration audit; isolated preferences, no gameplay edits."""
from pathlib import Path
import hashlib, json, os, subprocess, tempfile

ROOT = Path(__file__).resolve().parents[3]
PROJECT = ROOT / 'patch-notes'
OUT = Path(__file__).parent / 'migration-2026-10-06'
GODOT = Path(r'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe')
SUITES = ['verify_alpha_exit_arrears', 'verify_zero_work_release', 'verify_studio_finance_integration', 'verify_outstanding_expenses', 'verify_monthly_sales_report', 'verify_game_lifespan_trial', 'verify_studio_traits', 'verify_studio_specialties', 'verify_sidestreet_scope_and_year', 'verify_publisher_list_progression', 'verify_feature_store_cycle_purchase', 'verify_candidate_retention', 'verify_demo_settings']

def manifest():
    return {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
            for folder in ['scripts', 'scenes', 'data'] for p in (PROJECT / folder).rglob('*') if p.is_file()}

def run(name, args):
    with tempfile.TemporaryDirectory(prefix='pn-memory-audit-') as profile:
        env = os.environ.copy()
        for key in ['APPDATA', 'LOCALAPPDATA']:
            path = Path(profile) / key
            path.mkdir()
            env[key] = str(path)
        command = [str(GODOT), '--headless', '--path', str(PROJECT), *args]
        try:
            process = subprocess.run(command, env=env, capture_output=True, timeout=180)
            code, output = process.returncode, process.stdout + process.stderr
        except subprocess.TimeoutExpired as exc:
            code, output = 'timeout', (exc.stdout or b'') + (exc.stderr or b'')
        (OUT / (name + '.log')).write_bytes(output)
        lines = output.decode(errors='replace').splitlines()
        failures = [line for line in lines if any(marker in line for marker in ['SCRIPT ERROR', 'Parse Error', 'FAIL:', 'Assertion failed', 'ERROR:']) and 'Failed to read the root certificate store.' not in line]
        result = {'name': name, 'command': command, 'exit': code, 'failures': failures, 'pass_lines': sum('PASS:' in line for line in lines)}
        print(name, code, len(failures), flush=True)
        return result

if __name__ == '__main__':
    OUT.mkdir(exist_ok=True)
    before = manifest()
    status = subprocess.check_output(['git', 'status', '--short'], cwd=ROOT).decode()
    results = [run('editor-import', ['--editor', '--import'])]
    if results[0]['exit'] == 0 and not results[0]['failures']:
        results += [run(name, ['--script', 'res://scripts/debug/' + name + '.gd']) for name in SUITES]
    after = manifest()
    report = {'head': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT).decode().strip(), 'initial_status': status, 'results': results, 'runtime_files_unchanged': before == after, 'runtime_sha256': after,
              'passed': len(results) == len(SUITES) + 1 and all(r['exit'] == 0 and not r['failures'] for r in results) and before == after}
    (OUT / 'verification.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    print('MIGRATION FOCUSED PASS', report['passed'], flush=True)
    raise SystemExit(0 if report['passed'] else 1)
