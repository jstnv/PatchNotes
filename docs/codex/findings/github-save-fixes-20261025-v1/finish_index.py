"""Stage verified preset/case aliases, then verify the exact publication index."""
from pathlib import Path
import hashlib
import json
import subprocess

ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent


def git(*args, data=None):
    return subprocess.check_output(['git', *args], cwd=ROOT, input=data)


inventory = json.loads((OUT / 'publish-inputs.json').read_text())
assert git('rev-parse', 'HEAD').decode().strip() == inventory['base']
expected = {r['path'] for r in inventory['inputs']}
assert set(git('diff', '--cached', '--name-only', '-z').decode().strip('\0').split('\0')) <= expected

aliases = [r for r in inventory['inputs'] if '/Scenes/' in r['path']]
for record in aliases + [r for r in inventory['inputs'] if r['path'] == 'patch-notes/export_presets.cfg']:
    disk = OUT / 'verified-export-presets.cfg' if record['path'].endswith('export_presets.cfg') else ROOT / record['path']
    data = disk.read_bytes()
    assert hashlib.sha256(data).hexdigest() == record['sha256'], record['path']
    oid = git('hash-object', '-w', '--stdin', data=data).decode().strip()
    git('update-index', '--add', '--cacheinfo', '100644', oid, record['path'])

extras = ['publish-inputs.json', 'verified-export-presets.cfg', 'finish_index.py']
git('add', '--', *['docs/codex/findings/github-save-fixes-20261025-v1/' + x for x in extras])

index = {}
for entry in git('ls-files', '--stage', '-z').split(b'\0'):
    if entry:
        metadata, path = entry.split(b'\t', 1)
        mode, oid, stage = metadata.decode().split()
        assert stage == '0', path.decode()
        index[path.decode()] = oid

checked = {}
paths = dict(inventory['runtime'])
paths.update({r['path']: r['sha256'] for r in aliases})
for path, sha in paths.items():
    blob = git('cat-file', 'blob', index[path])
    assert hashlib.sha256(blob).hexdigest() == sha, path
    checked[path] = sha

allowed = expected | {'docs/codex/findings/github-save-fixes-20261025-v1/' + x for x in extras}
staged = set(git('diff', '--cached', '--name-only', '-z').decode().strip('\0').split('\0'))
assert staged <= allowed, sorted(staged - allowed)
assert not any('/project/' in x or '/.godot/' in x or x.lower().endswith(('.exe', '.zip', '.pck')) for x in staged)
result = {'ok': True, 'base': inventory['base'], 'staged_paths': len(staged),
          'runtime_inputs_exact': len(inventory['runtime']), 'updated_case_aliases_exact': len(aliases),
          'index_tree': git('write-tree').decode().strip(),
          'local_preset_preserved_sha256': hashlib.sha256((ROOT / 'patch-notes/export_presets.cfg').read_bytes()).hexdigest()}
(OUT / 'staged-check.json').write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps(result, indent=2))
