"""Final M4b scope, focused evidence and source-identity audit."""
from pathlib import Path
import hashlib, json, subprocess, zipfile
root = Path(__file__).resolve().parents[5]
here = Path(__file__).resolve().parent
def read(path): return json.loads(path.read_text(encoding='utf-8'))
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
before = read(here / 'before-hashes.json')
changed = sorted(path for path, value in before.items() if sha(root / path) != value)
allowed = {
    'docs/codex/CURRENT_STATE.md', 'docs/codex/README.md',
    'patch-notes/scripts/finance/studio_finance_ledger.gd',
    'patch-notes/scripts/run_state.gd',
    'patch-notes/scripts/simulation/studio_actions.gd',
    'patch-notes/scripts/simulation/development_replay.gd',
    'patch-notes/scripts/simulation/campaign_session.gd',
    'patch-notes/scripts/simulation/campaign_batch.gd',
    'patch-notes/scripts/debug/verify_campaign_batch.gd',
    'patch-notes/scripts/debug/campaign_replay_cli.gd',
}
assert set(changed) <= allowed, changed
assert sha(root / 'docs/codex/TODO.md') == before['docs/codex/TODO.md']
assert (root / 'patch-notes/.codex-godot-temp').exists()
head = subprocess.check_output(['git','rev-parse','HEAD'],cwd=root).decode().strip()
assert head == (here / 'head.txt').read_text().strip()
paths = sorted([p for p in (root/'patch-notes/scripts').rglob('*.gd') if '/debug/' not in p.as_posix()] + list((root/'patch-notes/data').rglob('*.json')))
mechanics = {p.relative_to(root/'patch-notes').as_posix():sha(p) for p in paths}
focused = read(here / 'focused-checks.json')
assert len(focused) == 9
for item in focused:
    folder = root / item['evidence']
    command = read(folder / 'command.json')
    assert command['exit'] == 0 and not command['errors'] and command['source_unchanged'] and command['drivers_unchanged'], item
    manifest = read(folder / 'source-after.json')
    assert all(manifest[str(Path('patch-notes')/path)] == value for path,value in mechanics.items()), item
    item['command'] = command['command']
    item['elapsed_seconds'] = command['elapsed_seconds']
    lines = (folder / 'output.log').read_text(errors='replace').splitlines()
    item['check_summaries'] = [line for line in lines if any(marker in line.lower() for marker in [' checks', ' comparisons', 'boundaries', ' passed', 'failures'])]
    item['warnings'] = [line for line in lines if line.startswith('WARNING:')]
runner = read(here / 'runner-acceptance.json')
assert runner['ok'] and runner['strict_replay_commands'] == 91
for label in ['runner-fixture-01','runner-custom-01','runner-continuation-01']:
    frozen = read(here / label / 'workspace-source-manifest.json')
    assert all(frozen[path] == value for path,value in mechanics.items()), label
profile = read(here / 'profile-comparison.json')
assert profile['canonical_mismatches'] == 0
for label, source in [('baseline-final',before), ('optimized-final',None)]:
    manifest = read(here / label / 'source.json')
    if source is not None:
        assert all(manifest[path] == source['patch-notes/'+path] for path in mechanics)
    else:
        assert all(manifest[path] == value for path,value in mechanics.items())
    assert all(row['exit'] == 0 and not row['errors'] for row in read(here / label / 'commands.json'))
result = {'ok':True,'branch':subprocess.check_output(['git','branch','--show-current'],cwd=root).decode().strip(), 'head':head,
    'todo_unchanged':True,'data_unchanged':all(sha(root/path)==value for path,value in before.items() if path.startswith('patch-notes/data/')),
    'existing_changed_files':changed,'mechanics_hashes':mechanics, 'focused':focused,
    'runner_audit_checks':runner['checks'],'python_unit_checks':runner['python_unit_checks'],
    'strict_fresh_replay_commands':runner['strict_replay_commands'], 'profile':profile,
    'limits':['Independent campaigns only; unresolved AI policy and shared-world scheduler remain OPEN','No export, computer control, human or audible acceptance','Existing ObjectDB exit warnings prevent leak-free claim'],
    'rejected_attempts':['m4b-import-01 and optimized-01: Run getter bool inference annotation','m4b-finance-01: verifier Variant annotations, 240s timeout','m4b-finance-02: fixture missing cash initialization; guarded failure path added; 240s timeout','optimized-02: canonical comparisons passed but overlapped other verification, excluded from final timing comparison']}
(here/'acceptance.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
with zipfile.ZipFile(here/'after-source.zip','x',zipfile.ZIP_DEFLATED) as archive:
    for p in sorted(set((root/'patch-notes/scripts').rglob('*.gd')) | set((root/'patch-notes/data').rglob('*.json')) | set((root/'tools').rglob('*.py'))):
        archive.write(p,p.relative_to(root))
print(json.dumps({key:result[key] for key in ['ok','head','todo_unchanged','data_unchanged','runner_audit_checks','python_unit_checks','strict_fresh_replay_commands']},indent=2))
