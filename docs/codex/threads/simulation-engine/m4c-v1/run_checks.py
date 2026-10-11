"""Focused M4c regression; serial isolated maintained Godot harness."""
from pathlib import Path
import importlib.util
import json
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[5]
HERE = Path(__file__).resolve().parent
EVIDENCE = ROOT / 'docs/codex/findings/card-presentation-v2'
spec = importlib.util.spec_from_file_location('isolated', EVIDENCE / 'run.py')
harness = importlib.util.module_from_spec(spec)
spec.loader.exec_module(harness)
checks = [{'suite': 'verify_campaign_telemetry.gd', 'evidence': 'docs/codex/findings/card-presentation-v2/m4c-telemetry-01'}]
for name in ['store_study', 'campaign_batch', 'campaign_live_parity', 'campaign_continuation']:
    label = 'm4c-accepted-' + name.replace('_', '-')
    harness.run(label, 'verify_' + name + '.gd')
    checks.append({'suite': 'verify_' + name + '.gd', 'evidence': (EVIDENCE / label).relative_to(ROOT).as_posix()})
    (HERE / 'focused-checks.json').write_text(json.dumps(checks, indent=2), encoding='utf-8')
argv = [sys.executable, '-m', 'unittest', 'discover', '-s', 'tools/tests', '-v']
result = subprocess.run(argv, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60)
(HERE / 'python-tests.log').write_bytes(result.stdout)
(HERE / 'python-tests-command.json').write_text(json.dumps({'argv': argv, 'exit': result.returncode}, indent=2), encoding='utf-8')
assert result.returncode == 0
print(result.stdout.decode(errors='replace'))
