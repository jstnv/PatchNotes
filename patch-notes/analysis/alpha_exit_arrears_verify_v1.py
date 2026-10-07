"""Alpha free-exit arrears regression gate."""
import concurrent.futures
import hashlib
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path
import tutorial_task17_verify_v1 as v

v.OUT = v.ROOT / 'design-logs/alpha-exit-arrears-v1'
v.OUT.mkdir(exist_ok=True)
(v.OUT / '.gdignore').touch()

def run_suite(path):
    return v.run(path.stem, v.ROOT, ['--script', 'res://scripts/debug/' + path.name], 180)

if __name__ == '__main__':
    if '--route' in sys.argv:
        stage = sys.argv[-1]
        result = v.run('route-' + stage, v.ROOT, ['--script', 'res://analysis/alpha_exit_arrears_route_v1.gd', '--', '--stage=' + stage], 180)
        sys.exit(0 if result['exit'] == 0 and not result['errors'] else 1)
    results = [v.run('editor-import', v.ROOT, ['--editor', '--import'])]
    assert results[0]['exit'] == 0 and not results[0]['errors']
    names = sys.argv[1:]
    paths = sorted((v.ROOT / 'scripts/debug').glob('verify_*.gd'))
    if names: paths = [p for p in paths if p.stem in names]
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        results += list(pool.map(run_suite, paths))
    for result in results:
        lines = (v.OUT / (result['name'] + '.log')).read_text(errors='replace').splitlines()
        result['generic_errors'] = [line for line in lines if 'ERROR:' in line]
        expected = {
            'verify_gameplay_transition': ['Failed to instantiate scene state', 'Could not instantiate a valid AlphaPhase', 'Could not instantiate a valid BetaPhase'],
            'verify_primitive_run_initialization': ['Could not initialize the Primitive project snapshots.'],
            'verify_run_calendar_and_studio_entry': ['Condition "!is_inside_tree()" is true.'],
        }.get(result['name'], [])
        result['unexpected_errors'] = [line for line in result['generic_errors']
            if 'Failed to read the root certificate store.' not in line
            and not any(marker in line for marker in expected)]
        result['assertion_passes'] = sum('PASS:' in line for line in lines)
    diff = subprocess.run(['git', 'diff', '--check'], cwd=v.ROOT, capture_output=True)
    (v.OUT / 'diff-check.log').write_bytes(diff.stdout + diff.stderr)
    report = {'results': results, 'diff_check': diff.returncode,
              'passed': all(r['exit'] == 0 and not r['errors'] and not r['unexpected_errors'] for r in results) and diff.returncode == 0}
    (v.OUT / ('focused-gate.json' if names else 'final-gate.json')).write_text(json.dumps(report, indent=2), encoding='utf-8')
    (v.OUT / 'source-final.json').write_text(json.dumps({'head': v.git('rev-parse','HEAD').decode().strip(),
        'files': {str(p.relative_to(v.ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
                  for folder in ['scripts','scenes','data'] for p in (v.ROOT/folder).rglob('*') if p.is_file()}}, indent=2))
    print('Alpha arrears gate:', report['passed'], flush=True)
    sys.exit(0 if report['passed'] else 1)
