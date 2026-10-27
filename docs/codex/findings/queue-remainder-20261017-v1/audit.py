from pathlib import Path
import ast, contextlib, hashlib, io, json, re, runpy, shutil

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[3]
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
manifest = json.loads((BASE / 'build-v3/build-manifest.json').read_text())
assert all(sha(ROOT / 'patch-notes' / k) == v for k,v in manifest['included'].items())
old = json.loads((BASE.parent / 'queue-execution-20261017-v2/final-delivery-v4/build-manifest.json').read_text())
delta = [k for k in set(old['included']) | set(manifest['included']) if old['included'].get(k) != manifest['included'].get(k)]
assert delta == ['scripts/ui/phase_workspace.gd'], delta
before = (BASE / 'phase_workspace.before.gd').read_bytes()
assert before.count('\u00c2'.encode()) == 5
assert before.replace('\u00c2'.encode(), b'') == (ROOT / 'patch-notes/scripts/ui/phase_workspace.gd').read_bytes()
startup = json.loads((BASE / 'build-v3/headless-startup.command.json').read_text())
assert startup['exit'] == 0 and not startup['errors']
pack = json.loads((BASE / 'build-v3/pack-manifest-verified.json').read_text())
assert pack['count'] == 297 and pack['files']['res://project.binary']['bytes'] >= 8

# Recheck the real failed package with the maintained inspector, without altering
# its historical logs or (insufficient) original MD5-only audit.
rejection = BASE / 'bad-package-recheck'
rejection.mkdir(exist_ok=False)
shutil.copy2(BASE / 'build/build-manifest.json', rejection / 'build-manifest.json')
shutil.copy2(ROOT / 'docs/codex/findings/export-queue-v3/inspect.py', rejection / 'inspect.py')
try:
    with contextlib.redirect_stdout(io.StringIO()):
        runpy.run_path(str(rejection / 'inspect.py'), run_name='__main__')
    raise RuntimeError('Corrupt retained package was incorrectly accepted')
except AssertionError as error:
    assert 'project.binary header' in str(error)
    rejection_message = str(error)

helpers = ['docs/codex/findings/export-queue-v3/export.py', 'docs/codex/findings/export-queue-v3/inspect.py', 'tools/tests/test_export_validation.py']
for relative in helpers:
    ast.parse((ROOT / relative).read_text(encoding='utf-8-sig'))
report = {'runtime_files': len(manifest['included']), 'runtime_delta_from_accepted_v4': delta,
          'all_other_runtime_hashes_match': len(manifest['included']) - len(delta),
          'five_prefixes_only': True, 'package_entries': pack['count'], 'project_binary_bytes': pack['files']['res://project.binary']['bytes'],
          'startup_exit': startup['exit'], 'retained_bad_package_rejection': rejection_message,
          'helper_hashes': {k: sha(ROOT / k) for k in helpers}}
(BASE / 'final-audit.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print(json.dumps(report, indent=2))
