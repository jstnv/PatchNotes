"""Candidate-retention isolated-profile source gate; no gameplay values are altered."""
import concurrent.futures
import hashlib
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path
import tutorial_task17_verify_v1 as v

v.OUT = v.ROOT / 'design-logs/candidate-pool-repair-v1'
v.OUT.mkdir(exist_ok=True)
(v.OUT / '.gdignore').touch()

def run_suite(path):
    return v.run(path.stem, v.ROOT, ['--script', 'res://scripts/debug/' + path.name], 180)

if __name__ == '__main__':
    if '--render' in sys.argv:
        profile = Path(tempfile.mkdtemp(prefix='pn-candidate-retention-render-'))
        env = os.environ.copy()
        for key in ['APPDATA', 'LOCALAPPDATA']:
            folder = profile / key
            folder.mkdir()
            env[key] = str(folder)
        command = [v.GODOT, '--path', str(v.ROOT), '--rendering-method', 'gl_compatibility',
                   '--position', '-5000,-5000', '--script', 'res://scripts/debug/verify_card_motion.gd', '--', '--capture']
        try:
            process = subprocess.run(command, env=env, capture_output=True, timeout=180)
            code, output = process.returncode, process.stdout + process.stderr
        except subprocess.TimeoutExpired as error:
            code, output = 'timeout', (error.stdout or b'') + (error.stderr or b'')
        (v.OUT / 'render.log').write_bytes(output)
        result = dict(command=command, exit=code, profile=str(profile),
                      errors=[line for line in output.decode(errors='replace').splitlines()
                              if ('ERROR:' in line or 'FAIL:' in line) and 'Failed to read the root certificate store.' not in line])
        (v.OUT / 'render.command.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
        print(json.dumps(result), flush=True)
        sys.exit(0 if code == 0 and not result['errors'] else 1)
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
    print('Candidate retention gate:', report['passed'], flush=True)
    sys.exit(0 if report['passed'] else 1)
