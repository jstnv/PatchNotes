"""Final bounded M4c evidence, scope and frozen-source audit."""
from pathlib import Path
import hashlib
import importlib.util
import json
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[5]
HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('simulator', ROOT / 'tools/simulate.py')
simulator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(simulator)

def read(path): return json.loads(path.read_text(encoding='utf-8-sig'))
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()

before = read(HERE / 'before-hashes.json')
changed = sorted(path for path, digest in before.items() if sha(ROOT / path) != digest)
allowed = {
    'docs/codex/CURRENT_STATE.md', 'docs/codex/README.md',
    'patch-notes/scripts/simulation/campaign_batch.gd',
    'patch-notes/scripts/debug/campaign_replay_cli.gd',
    'tools/simulate.py',
}
assert set(changed) <= allowed, changed
assert sha(ROOT / 'docs/codex/TODO.md') == before['docs/codex/TODO.md']
assert (ROOT / 'patch-notes/.codex-godot-temp').exists()
head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT).decode().strip()
assert head == (HERE / 'head.txt').read_text().strip()
source = simulator.source_hashes(ROOT / 'patch-notes')
mechanics = {path: digest for path, digest in source.items()
             if path.startswith(('scripts/', 'data/')) and not path.startswith('scripts/debug/') and path.endswith(('.gd', '.json'))}
focused = read(HERE / 'focused-checks.json')
assert len(focused) == 5
for item in focused:
    folder = ROOT / item['evidence']
    command = read(folder / 'command.json')
    assert command['exit'] == 0 and not command['errors'] and command['source_unchanged'] and command['drivers_unchanged'], item
    manifest = read(folder / 'source-after.json')
    assert all(manifest[str(Path('patch-notes') / path)] == digest for path, digest in mechanics.items()), item
    item['argv'] = command['command']
    item['elapsed_seconds'] = command['elapsed_seconds']
    lines = (folder / 'output.log').read_text(errors='replace').splitlines()
    item['summaries'] = [line for line in lines if any(word in line.lower() for word in [' checks', ' comparisons', 'boundaries', ' passed', 'failures'])]
    item['warnings'] = [line for line in lines if line.startswith('WARNING:')]
imports = []
for label in ['m4c-import-01', 'm4c-import-02']:
    folder = ROOT / 'docs/codex/findings/card-presentation-v2' / label
    command = read(folder / 'command.json')
    assert command['exit'] == 0 and not command['errors']
    old, new = read(folder / 'source-before.json'), read(folder / 'source-after.json')
    differences = sorted(path for path in old.keys() | new.keys() if old.get(path) != new.get(path))
    permitted_debug_revision = 'patch-notes/scripts/debug/verify_campaign_telemetry.gd'
    assert all(path.endswith('.uid') or (label == 'm4c-import-01' and path.replace('\\', '/') == permitted_debug_revision and old.get(path) == '1f66978e1be10f5f347fb9ee78fdcea8021474368c6018dd6fd4f78a4e5ba9cb' and new[path] == sha(ROOT / permitted_debug_revision)) for path in differences), differences
    imports.append({'label': label, 'source_changes': differences, 'note': 'First import overlapped a telemetry verifier revision only; second import and all focused tests use the completed verifier. Other differences are generated UIDs.'})
store = read(HERE / 'store-study-audit.json')
assert store['ok'] and store['check_count'] == 90
negative = read(HERE / 'store-negative-telemetry-01/negative-audit.json')
assert negative['ok'] and negative['actual_exit'] == 1 and negative['original_bundle_unchanged'] and negative['private_source_unchanged']
assert read(HERE / 'python-tests-command.json')['exit'] == 0
assert 'Ran 38 tests' in (HERE / 'python-tests.log').read_text()
private_differences = {}
for label in ['store-prefix-01', 'store-4417-01', 'store-90210-01']:
    manifest = read(HERE / label / 'workspace-source-manifest.json')
    assert all(manifest[path] == digest for path, digest in mechanics.items()), label
    differences = sorted(path for path in manifest.keys() | source.keys() if manifest.get(path) != source.get(path))
    assert all(path.startswith('scripts/debug/verify_store_study.gd') for path in differences), (label, differences)
    private_differences[label] = differences
replays = []
for seed in ['4417', '90210']:
    comparison = read(HERE / ('store-' + seed + '-comparison-01/comparison.json'))
    for arm in ['research_now', 'defer']:
        folder = HERE / ('store-' + seed + '-' + arm + '-replay-01')
        report = read(folder / 'replay-report.json')
        assert report['ok'] and report['telemetry_verified']
        replays.append({'seed': seed, 'arm': arm, 'report': report})
result = {
    'ok': True, 'branch': subprocess.check_output(['git', 'branch', '--show-current'], cwd=ROOT).decode().strip(), 'head': head,
    'todo_unchanged': True, 'data_unchanged': all(sha(ROOT / path) == digest for path, digest in before.items() if path.startswith('patch-notes/data/')),
    'existing_changed_files': changed, 'mechanics_hashes': mechanics, 'focused': focused,
    'imports': imports, 'private_debug_only_differences': private_differences,
    'python_tests': 38, 'store_audit_checks': 90, 'fresh_replays': replays,
    'negative_telemetry': negative,
    'limits': ['Two explicit finite Store pairs; no balance or AI policy approval', 'Old frozen replay verifies old source; rerun declared study on new source for regression', 'No full release gate, export, human/audio/UI acceptance, scaling or leak-free claim'],
}
(HERE / 'acceptance.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
paths = sorted(set((ROOT / 'patch-notes/scripts').rglob('*.gd')) | set((ROOT / 'patch-notes/data').rglob('*.json')) | set((ROOT / 'tools').rglob('*.py')))
with zipfile.ZipFile(HERE / 'after-source.zip', 'x', zipfile.ZIP_DEFLATED) as archive:
    for path in paths: archive.write(path, path.relative_to(ROOT))
(HERE / 'after-hashes.json').write_text(json.dumps({path.relative_to(ROOT).as_posix(): sha(path) for path in paths}, indent=2), encoding='utf-8')
print(json.dumps({key: result[key] for key in ['ok', 'head', 'todo_unchanged', 'data_unchanged', 'python_tests', 'store_audit_checks', 'existing_changed_files']}, indent=2))
