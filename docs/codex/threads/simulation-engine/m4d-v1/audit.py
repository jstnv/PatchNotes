"""Bounded final M4d source, evidence and documentation audit."""
from pathlib import Path
import hashlib
import importlib.util
import json
import re
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[5]
HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('simulator_audit', ROOT / 'tools/simulate.py')
sim = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sim)
def read(path): return json.loads(path.read_text(encoding='utf-8-sig'))
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()

before = read(HERE / 'before-hashes.json')
changed = sorted(path for path, digest in before.items() if not (ROOT / path).is_file() or sha(ROOT / path) != digest)
allowed = {'AGENTS.md', 'docs/codex/CURRENT_STATE.md', 'docs/codex/README.md',
           'docs/codex/TODO.md', 'docs/codex/DECISIONS.md', 'tools/simulate.py',
           'patch-notes/scripts/debug/verify_campaign_live_parity.gd'}
assert set(changed) <= allowed, changed
head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT).decode().strip()
assert head == (HERE / 'head.txt').read_text().strip()
assert (ROOT / 'patch-notes/.codex-godot-temp').exists()
current = sim.source_hashes(ROOT / 'patch-notes')
mechanics = {p: digest for p, digest in current.items() if p.startswith(('scripts/', 'data/')) and not p.startswith('scripts/debug/') and p.endswith(('.gd', '.json'))}
assert all(before['patch-notes/' + p] == digest for p, digest in mechanics.items())
all_paths = sorted(set((ROOT / 'patch-notes/scripts').rglob('*.gd')) | set((ROOT / 'patch-notes/data').rglob('*.json')) | set((ROOT / 'tools').rglob('*.py')))
new_sources = sorted(p.relative_to(ROOT).as_posix() for p in all_paths if p.relative_to(ROOT).as_posix() not in before)
assert all(p.startswith(('patch-notes/scripts/debug/', 'tools/')) for p in new_sources), new_sources

stress = read(HERE / 'stress-split-audit.json')
assert stress['ok'] and len(stress['suites']) == 4
focused = [item for item in read(HERE / 'focused-checks.json') if item['suite'] != 'verify_campaign_stress.gd']
focused += [{'suite': Path(item['evidence']).name.replace('m4d-split-', 'verify_').replace('-', '_') + '.gd', 'evidence': item['evidence']} for item in stress['suites']]
assert len(focused) == 7
for item in focused:
    folder = ROOT / item['evidence']
    command = read(folder / 'command.json')
    assert command['exit'] == 0 and not command['errors'] and command['source_unchanged'] and command['drivers_unchanged'], item
    assert command['elapsed_seconds'] < 90, item
    tested = {p.replace('\\', '/'): digest for p, digest in read(folder / 'source-after.json').items()}
    assert all(tested['patch-notes/' + p] == digest for p, digest in mechanics.items()), item
    # Each tested entrypoint still has its exact current source. Stress helpers
    # use the later split evidence; the earlier unchanged adapter/reducer tests
    # do not depend on the replaced stress entrypoint.
    path = 'patch-notes/scripts/debug/' + item['suite']
    assert tested[path] == sha(ROOT / path), item
    for dependency in ['campaign_failure_reducer.gd', 'campaign_invariants.gd', 'verify_campaign_live_parity.gd']:
        path = 'patch-notes/scripts/debug/' + dependency
        assert tested[path] == sha(ROOT / path), item
    item.update(command=command['command'], elapsed_seconds=command['elapsed_seconds'], fit=read(folder / 'fit.json'))
    assert item['fit'].get('failures', 0) == 0
    lines = (folder / 'output.log').read_text(errors='replace').splitlines()
    item['warnings'] = [line for line in lines if line.startswith('WARNING:')]
assert sum(item['commands'] for item in stress['suites']) == 344
assert all(item['monolith_tape_unchanged'] and item['monolith_final_state_unchanged'] and item['replay_ok'] for item in stress['suites'])

imports = []
for label in ['m4d-import-01', 'm4d-split-import-01']:
    folder = ROOT / 'docs/codex/findings/card-presentation-v2' / label
    command = read(folder / 'command.json')
    assert command['exit'] == 0 and not command['errors']
    old, new = read(folder / 'source-before.json'), read(folder / 'source-after.json')
    differences = sorted(p for p in old.keys() | new.keys() if old.get(p) != new.get(p))
    assert all(p.endswith('.uid') for p in differences), (label, differences)
    imports.append({'label': label, 'only_generated_uids': differences})

python = read(HERE / 'python-tests-final-command.json')
assert python['exit'] == 0 and 'Ran 70 tests' in (HERE / 'python-tests-final.log').read_text()
assert all(sha(ROOT / path) == digest for path, digest in python['tool_hashes'].items())
variant = read(HERE / 'variant-audit.json')
overlap = read(HERE / 'variant-concurrency-audit.json')
reducer = read(HERE / 'reducer-integration-audit.json')
assert variant['ok'] and overlap['ok'] and overlap['actual_godot_experiment_overlap_seconds'] > 0
assert reducer['ok'] and reducer['fresh_process_confirmation'] and reducer['original_commands'] == 37 and reducer['reduced_commands'] == 1
assert reducer['reducer_sha256'] == sha(ROOT / 'tools/reduce_simulation.py')
assert reducer['runner_sha256'] == sha(ROOT / 'tools/simulate.py')
private_differences = {}
for label in ['variant-run-a', 'variant-run-b', 'reducer-original-run']:
    manifest = read(HERE / label / 'workspace-source-manifest.json')
    differences = sorted(p for p in manifest.keys() | current.keys() if manifest.get(p) != current.get(p))
    assert all(p.startswith('scripts/debug/') or (label.startswith('variant-') and p == 'scripts/run_state.gd') for p in differences), (label, differences)
    private_differences[label] = differences
    frozen = read(HERE / label / 'snapshot-manifest.json')
    sim.check_snapshot(HERE / label / 'project', frozen)

docs = [ROOT / p for p in ['AGENTS.md', 'docs/codex/README.md', 'docs/codex/CURRENT_STATE.md', 'docs/codex/TODO.md', 'docs/codex/DECISIONS.md']]
docs += [HERE.parent / p for p in ['README.md', 'USAGE.md', 'VARIANTS.md', '2026-10-11-extraction-m4d.md', '2026-10-11-session-log-v13.md']]
implementation_paths = sorted({ROOT / p for p in changed + new_sources} | set(docs))
command = ['git', 'diff', '--check', '--', *[p.relative_to(ROOT).as_posix() for p in implementation_paths]]
diff = subprocess.run(command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
assert diff.returncode == 0, diff.stdout.decode(errors='replace')
whitespace = []
for path in implementation_paths:
    if path.relative_to(ROOT).as_posix() in before: continue
    for number, line in enumerate(path.read_text(encoding='utf-8-sig').splitlines(), 1):
        if line.rstrip() != line: whitespace.append(f'{path.relative_to(ROOT)}:{number}')
assert not whitespace, whitespace
links = []
for path in docs:
    for target in re.findall(r'(?<!!)\[[^\]]+\]\(([^)]+)\)', path.read_text(encoding='utf-8-sig')):
        if '://' in target or target.startswith('#'): continue
        resolved = (path.parent / target.strip('<>').split('#')[0]).resolve()
        if resolved == HERE / 'acceptance.json': continue  # Written by this audit.
        assert resolved.exists(), (path, target)
        links.append({'from': str(path.relative_to(ROOT)), 'target': target})
sim.write_json(HERE / 'diff-check.json', {'exit': diff.returncode, 'command': command, 'stdout': diff.stdout.decode(errors='replace'), 'stderr': diff.stderr.decode(errors='replace'), 'new_file_whitespace_errors': whitespace, 'local_links_checked': len(links)})

result = {'ok': True, 'head': head, 'branch': subprocess.check_output(['git', 'branch', '--show-current'], cwd=ROOT).decode().strip(),
          'existing_changed_files': changed, 'new_source_files': new_sources, 'canonical_mechanics_and_data_unchanged': True,
          'mechanics_hashes': mechanics, 'focused': focused, 'imports': imports, 'stress': stress,
          'python_tests': 70, 'python_command': python, 'native_headless_boundaries': 232,
          'concurrent_variants': overlap, 'reducer_integration': reducer, 'private_source_differences': private_differences,
          'todo_scope': 'User-authorized ongoing variant handoff workflow only; no synthetic candidates queued',
          'limits': ['Bounded routes; no universal parity or balance approval', 'Concurrent isolated campaigns, not shared-world rivals', 'No full release gate, export, visible/audio acceptance or new throughput claim', 'Reduction minimum restricted to legal Studio suffixes']}
sim.write_json(HERE / 'acceptance.json', result)
archive_paths = sorted(set(all_paths) | set(docs))
with zipfile.ZipFile(HERE / 'after-source.zip', 'x', zipfile.ZIP_DEFLATED) as archive:
    for path in archive_paths: archive.write(path, path.relative_to(ROOT))
sim.write_json(HERE / 'after-hashes.json', {path.relative_to(ROOT).as_posix(): sha(path) for path in archive_paths})
(HERE / 'status-after.txt').write_bytes(subprocess.check_output(['git', 'status', '--short'], cwd=ROOT))
print(json.dumps({key: result[key] for key in ['ok', 'head', 'canonical_mechanics_and_data_unchanged', 'python_tests', 'native_headless_boundaries', 'existing_changed_files', 'new_source_files']}, indent=2))
