from pathlib import Path
import difflib
import hashlib
import json
import subprocess

out = Path(__file__).resolve().parent
root = out.parents[3]
project = root / 'patch-notes'
runtime = [
    'scripts/ui/card_score_floats.gd', 'scripts/ui/hand_presentation.gd',
    'scripts/ui/production_scoreboard.gd', 'scripts/ui/gameplay_hud.gd',
    'scripts/ui/guided_production_tutorial.gd', 'scripts/ui/phase_workspace.gd',
    'scripts/phases/contract_phase.gd', 'scripts/market/rival_world_checkpoint.gd',
]
tests = ['scripts/debug/' + name + '.gd' for name in [
    'verify_score_floats', 'verify_soundtrack_sync', 'verify_card_motion',
    'verify_gameplay_hud_overlay',
]]
sha = lambda blob: hashlib.sha256(blob).hexdigest()
files, patches = {}, []
for name in runtime + tests:
    current = (project / name).read_bytes()
    before = out / 'before' / name
    is_new = name in [runtime[0], tests[0]]
    original = b'' if is_new else before.read_bytes()
    files[name] = {'sha256': sha(current), 'before_sha256': None if is_new else sha(original), 'new': is_new}
    patches.extend(difflib.unified_diff(original.decode('utf-8-sig').splitlines(True), current.decode('utf-8-sig').splitlines(True), fromfile='before/' + name, tofile='after/' + name))
(out / 'scoped.patch').write_text(''.join(patches), encoding='utf-8', newline='')

paths = sorted([*project.joinpath('scripts').rglob('*'), *project.joinpath('data').rglob('*'), project / 'queries/market_release_index.gd'])
rows, old_rows = [], []
for path in paths:
    name = path.relative_to(project).as_posix()
    if not path.is_file() or name.startswith('scripts/debug/') or path.suffix not in ['.gd', '.gdc', '.remap', '.json']:
        continue
    rows.append(['res://' + name, sha(path.read_bytes())])
    if name == runtime[0]: continue
    baseline = out / 'before' / name
    old_rows.append(['res://' + name, sha(baseline.read_bytes() if name in runtime and baseline.exists() else path.read_bytes())])
rows.sort(key=lambda row: row[0])
old_rows.sort(key=lambda row: row[0])
identity = lambda items: sha(json.dumps(items, ensure_ascii=False, separators=(',', ':')).encode('utf-8'))
actual = json.loads((out / 'identity.json').read_text())
assert rows == actual['rows'], {'extra_python': [row for row in rows if row not in actual['rows']], 'extra_godot': [row for row in actual['rows'] if row not in rows]}
assert identity(rows) == actual['identity'], (identity(rows), actual['identity'])
expected_before = json.loads((out / 'before-pair.json').read_text())['rival_world']['source_identity']
labels = ['native-final', 'sync-final', 'motion-final', 'tutorial-final', 'cold-final', 'card-pop', 'design', 'alpha', 'qa', 'marketing', 'contract-model', 'contract-ui', 'hud-current', 'checkpoint']
runs = {label: json.loads((out / (label + '-run.json')).read_text()) for label in labels}
assert all(receipt['exit'] == 0 and not receipt['errors'] for receipt in runs.values())
assert identity(old_rows) == expected_before, (identity(old_rows), expected_before)
whitespace = subprocess.run(['git', '-c', 'core.whitespace=cr-at-eol', 'diff', '--check', '--', *['patch-notes/' + name for name in runtime + tests]], cwd=root, capture_output=True, text=True)
assert whitespace.returncode == 0, whitespace.stdout + whitespace.stderr
result = {'branch': subprocess.check_output(['git', 'branch', '--show-current'], cwd=root, text=True).strip(),
          'head': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip(),
          'source_identity': identity(rows), 'reconstructed_before_identity': identity(old_rows),
          'exact_before_identity_verified': True, 'files': files,
          'passing_labels': labels, 'whitespace_exit': whitespace.returncode,
          'player_exports_changed': False, 'commit_or_push': False}
(out / 'audit.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
print(json.dumps({key: value for key, value in result.items() if key != 'files'}, indent=2))
