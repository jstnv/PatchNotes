"""One predeclared two-seed study and exact fresh-process replays; no retries."""
import json
from pathlib import Path
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[5]
HERE = Path(__file__).resolve().parent
GODOT = Path('C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe')
PYTHON = Path('C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe')
COMMANDS = []


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def run(label, arguments, allow_failure=False):
    command = [str(PYTHON), *map(str, arguments)]
    start = time.monotonic()
    print('Starting ' + label, flush=True)
    result = subprocess.run(command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=360)
    elapsed = time.monotonic() - start
    (HERE / (label + '.orchestration.log')).write_bytes(result.stdout)
    COMMANDS.append({'label': label, 'argv': command, 'cwd': str(ROOT), 'exit': result.returncode, 'elapsed_seconds': elapsed})
    (HERE / 'store-study-commands.json').write_text(json.dumps(COMMANDS, indent=2) + '\n', encoding='utf-8')
    print(f'{label}: exit {result.returncode}, {elapsed:.2f}s', flush=True)
    if result.returncode and not allow_failure:
        raise RuntimeError('No retry: ' + label + ' failed; retained output is authoritative')
    return result.returncode


def main():
    prefix = HERE / 'store-prefix-01'
    run('store-prefix-01', ['tools/simulate.py', 'run', '--config', 'docs/codex/threads/simulation-engine/examples/store-prefix.json', '--output', prefix, '--godot', GODOT, '--timeout', '240'])
    reports = []
    for seed in ('4417', '90210'):
        config = HERE / ('store-' + seed + '-input.json')
        bundle = HERE / ('store-' + seed + '-01')
        run('prepare-store-' + seed, ['tools/prepare_store_study.py', '--bundle', prefix, '--case', 'action-' + seed, '--feature', 'recorded_sounds', '--target-release-count', '2', '--max-commands', '100', '--output', config])
        run('store-' + seed + '-01', ['tools/simulate.py', 'run', '--config', config, '--output', bundle, '--godot', GODOT, '--timeout', '240'], allow_failure=True)
        cases = read(config)['cases']
        for case in cases:
            arm = case['study']['arm']
            result = read(bundle / 'cases' / case['case_id'] / 'result.json')
            reports.append({'seed': seed, 'arm': arm, 'bundle': str(bundle), 'case_id': case['case_id'], 'ok': result['ok'], 'status': result['status'], 'error': result['error'], 'commands': result['commands']})
            run('store-' + seed + '-' + arm + '-replay-01', ['tools/simulate.py', 'replay', '--bundle', bundle, '--case', case['case_id'], '--output', HERE / ('store-' + seed + '-' + arm + '-replay-01'), '--godot', GODOT, '--timeout', '240'])
    (HERE / 'store-study-runs.json').write_text(json.dumps(reports, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(reports, indent=2), flush=True)


if __name__ == '__main__':
    main()
