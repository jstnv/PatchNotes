"""Current-source UI regressions; every process uses an isolated Godot profile."""
import concurrent.futures
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import tutorial_task17_verify_v1 as v

v.OUT = v.ROOT / 'design-logs/campaign-pool-ui-v1'
v.OUT.mkdir(exist_ok=True)
(v.OUT / '.gdignore').touch()

if __name__ == '__main__':
    stage = sys.argv[1]
    if stage == 'snapshot':
        (v.OUT / 'initial-status.txt').write_bytes(v.git('status', '--short'))
        (v.OUT / 'initial-diff.patch').write_bytes(v.git('diff'))
        results = []
    elif stage == 'render':
        profile = Path(tempfile.mkdtemp(prefix='pn-campaign-pool-render-'))
        env = os.environ.copy()
        for key in ['APPDATA', 'LOCALAPPDATA']:
            p = profile / key
            p.mkdir()
            env[key] = str(p)
        command = [v.GODOT, '--path', str(v.ROOT), '--rendering-method', 'gl_compatibility',
                   '--position', '-5000,-5000', '--script', 'res://scripts/debug/verify_pool_organization.gd', '--', '--capture']
        proc = subprocess.run(command, env=env, capture_output=True, timeout=180)
        (v.OUT / 'render.log').write_bytes(proc.stdout + proc.stderr)
        results = [dict(name='render', command=command, profile=str(profile), exit=proc.returncode, errors=[])]
    else:
        results = [v.run('editor-import', v.ROOT, ['--editor', '--import'])]
        if results[0]['exit'] == 0 and not results[0]['errors']:
            names = sys.argv[2:]
            paths = sorted((v.ROOT / 'scripts/debug').glob('verify_*.gd'))
            if names: paths = [p for p in paths if p.stem in names]
            with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
                results += list(pool.map(lambda p: v.run(p.stem, v.ROOT, ['--script', 'res://scripts/debug/' + p.name], 180), paths))
    expected = {
        'verify_gameplay_transition': ['Failed to instantiate scene state', 'Could not instantiate a valid AlphaPhase', 'Could not instantiate a valid BetaPhase'],
        'verify_primitive_run_initialization': ['Could not initialize the Primitive project snapshots.'],
        'verify_run_calendar_and_studio_entry': ['Condition "!is_inside_tree()" is true.'],
    }
    for result in results:
        lines = (v.OUT / (result['name'] + '.log')).read_text(encoding='utf-8', errors='replace').splitlines()
        result['unexpected_errors'] = [line for line in lines if any(marker in line for marker in ['ERROR:', 'FAIL:', 'Assertion failed'])
            and 'Failed to read the root certificate store.' not in line
            and not any(marker in line for marker in expected.get(result['name'], []))]
        result['assertion_passes'] = sum('PASS:' in line for line in lines)
    diff = subprocess.run(['git', 'diff', '--check'], cwd=v.ROOT, capture_output=True)
    (v.OUT / (stage + '-diff-check.log')).write_bytes(diff.stdout + diff.stderr)
    report = {'results': results, 'diff_check': diff.returncode,
        'passed': all(r['exit'] == 0 and not r['errors'] and not r['unexpected_errors'] for r in results) and diff.returncode == 0}
    (v.OUT / (stage + '-gate.json')).write_text(json.dumps(report, indent=2), encoding='utf-8')
    (v.OUT / (stage + '-source.json')).write_text(json.dumps({'head': v.git('rev-parse', 'HEAD').decode().strip(),
        'files': {str(p.relative_to(v.ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
                  for folder in ['scripts', 'scenes', 'data'] for p in (v.ROOT / folder).rglob('*') if p.is_file()}}, indent=2), encoding='utf-8')
    print(stage, 'PASS' if report['passed'] else 'FAIL', flush=True)
    sys.exit(0 if report['passed'] else 1)
