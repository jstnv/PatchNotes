"""Inventory an explicit source publication without traversing simulator copies."""
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent
BUILD = ROOT / 'docs/codex/findings/background-checkpoint-20261025-v1/build-manifest.json'
OVERRIDE = 'patch-notes/export_presets.cfg'


def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)


def blocked(path):
    return any(p.lower() in {'project', '.godot', 'profiles', 'appdata', 'localappdata', '__pycache__'}
               or p.lower().startswith('variants') for p in path.parts)


def files(folder, suffixes):
    # rg prunes excluded directories before descent.
    command = ['rg', '--files', str(folder), '-g', '!**/project/**', '-g', '!**/variants*/**',
               '-g', '!**/.godot/**', '-g', '!**/profiles/**', '-g', '!**/APPDATA/**',
               '-g', '!**/LOCALAPPDATA/**', '-g', '!**/__pycache__/**']
    for suffix in suffixes:
        command += ['-g', '*' + suffix]
    result = subprocess.run(command, cwd=ROOT, capture_output=True, check=False)
    assert result.returncode in (0, 1), result.stderr
    for name in result.stdout.decode('utf-8').splitlines():
        path = Path(name)
        rel = path.relative_to(ROOT) if path.is_absolute() else path
        if not blocked(rel):
            yield rel.as_posix()


manifest = json.loads(BUILD.read_text())
runtime = {}
for group in ('included', 'import_settings'):
    for path, expected in manifest.get(group, {}).items():
        rel = 'patch-notes/' + path
        disk = OUT / 'verified-export-presets.cfg' if rel == OVERRIDE else ROOT / rel
        actual = hashlib.sha256(disk.read_bytes()).hexdigest()
        assert actual == expected, (rel, actual, expected)
        runtime[rel] = expected

assert not git('diff', '--cached', '--name-only'), 'Preserve an unexpected existing index'
selected = set(runtime)
selected.update(x.decode('utf-8') for x in git('diff', '--name-only', '-z').split(b'\0') if x)
selected.update(files('patch-notes/scripts/debug', ('.gd', '.uid', '.json')))
selected.update(files('tools', ('.py', '.md', '.json')))
selected.update(files('patch-notes/assets', ('.md', '.txt', '.mid')))
selected.update(files('docs/codex', ('.md',)))
for folder in ('campaign-latency-20261025-v1', 'background-checkpoint-20261025-v1'):
    selected.update(files('docs/codex/findings/' + folder, ('.md', '.json', '.gd', '.py', '.txt', '.log', '.png')))
selected.update({
    'docs/codex/findings/export-queue-v3/export.py',
    'docs/codex/findings/export-queue-v3/inspect.py',
    'docs/codex/findings/contract-search-20261025-v1/v003/package_probe.gd',
    'docs/codex/findings/logo-icon-20261024-v1/inspect_icon.py',
    'docs/codex/findings/github-save-fixes-20261025-v1/prepare_publication.py',
})
for path in ('.gitignore', '.gitattributes', 'AGENTS.md', 'patch-notes/.gitignore', 'patch-notes/.gitattributes'):
    if (ROOT / path).is_file():
        selected.add(path)

secrets = re.compile(rb'(?:github_pat_[A-Za-z0-9_]{30,}|gh[pousr]_[A-Za-z0-9]{30,}|sk-[A-Za-z0-9]{30,}|-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----|AKIA[A-Z0-9]{16})')
records = []
for path in sorted(selected):
    rel = Path(path)
    assert not blocked(rel), path
    disk = OUT / 'verified-export-presets.cfg' if path == OVERRIDE else ROOT / path
    assert disk.resolve().is_relative_to(ROOT), path
    assert disk.is_file(), path
    data = disk.read_bytes()
    assert len(data) < 95 * 1024 * 1024, ('oversized', path, len(data))
    if disk.suffix.lower() in {'.gd', '.json', '.py', '.md', '.txt', '.cfg', '.log', '.godot', '.tscn', '.tres'}:
        assert not secrets.search(data), ('potential credential; inspect locally without printing', path)
    records.append({'path': path, 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()})

result = {'base': git('rev-parse', 'HEAD').decode().strip(), 'runtime': runtime,
          'verified_export_override': OVERRIDE, 'inputs': records}
(OUT / 'publish-inputs.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
(OUT / 'paths.nul').write_bytes(b'\0'.join(x['path'].encode() for x in records if x['path'] != OVERRIDE) + b'\0')
print(json.dumps({'files': len(records), 'runtime_inputs': len(runtime),
                  'total_bytes': sum(x['bytes'] for x in records),
                  'largest': sorted(records, key=lambda x: x['bytes'], reverse=True)[:8]}, indent=2))
