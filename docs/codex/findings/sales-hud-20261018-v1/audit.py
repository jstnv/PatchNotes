from pathlib import Path
import hashlib, importlib.util, json, struct, subprocess

ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('sim', ROOT / 'tools/simulate.py')
sim = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sim)
before = json.loads((OUT / 'before/source.json').read_text())
behavior = json.loads((OUT / 'check-v1/source.json').read_text())
tested = json.loads((OUT / 'render-v2/source.json').read_text())
current = sim.source_hashes(ROOT / 'patch-notes')
changed = sorted(k for k in before if tested.get(k) != before[k])
added = sorted(set(tested) - set(before))
expected_changed = {'scripts/ui/gameplay_hud.gd', 'scripts/market/rival_world_checkpoint.gd'}
expected_added = {'scripts/ui/sales_revenue_model.gd', 'scripts/ui/sales_revenue_hud.gd',
                  'scripts/debug/verify_sales_revenue_hud.gd', 'scripts/debug/capture_sales_hud.gd'}
assert set(changed) == expected_changed, changed
assert set(added) == expected_added, added
assert all(current.get(k) == v for k, v in tested.items()), 'Canonical differs from rendered input'
assert {k:v for k,v in behavior.items() if not k.startswith('scripts/debug/')} == {
    k:v for k,v in tested.items() if not k.startswith('scripts/debug/')}, 'Runtime changed after behavior checks'
uids = sorted(set(current) - set(tested))
assert set(uids) == {k + '.uid' for k in expected_added}, uids
for k in uids:
    assert (OUT / 'render-v2/project' / k).read_bytes() == (ROOT / 'patch-notes' / k).read_bytes()
results = []
for stage, count in [('before', 2), ('check-v1', 5), ('render-v2', 2)]:
    rows = json.loads((OUT / stage / 'results.json').read_text())
    assert len(rows) == count and all(r['exit'] == 0 and not r['errors'] for r in rows)
    results.extend(rows)
screenshots = {}
for p in sorted((OUT / 'render-v2').glob('*.png')):
    width, height = struct.unpack('>II', p.read_bytes()[16:24])
    assert p.stem.endswith(f'{width}x{height}'), p.name
    screenshots[p.name] = {'width': width, 'height': height, 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
assert len(screenshots) == 10
files = [str(ROOT / 'patch-notes' / k) for k in sorted(expected_changed | expected_added)]
check = subprocess.run(['git', '-c', 'core.whitespace=cr-at-eol', 'diff', '--check', '--', *files], cwd=ROOT, capture_output=True, text=True)
(OUT / 'diff-check.log').write_text(check.stdout + check.stderr, encoding='utf-8')
assert check.returncode == 0
for k in expected_added:
    assert all(line == line.rstrip() for line in (ROOT / 'patch-notes' / k).read_text().splitlines()), k
sim.write_json(OUT / 'audit.json', {
    'branch': subprocess.check_output(['git','branch','--show-current'], cwd=ROOT, text=True).strip(),
    'head': subprocess.check_output(['git','rev-parse','HEAD'], cwd=ROOT, text=True).strip(),
    'changed_from_pre_edit': changed, 'added_to_pre_edit': added, 'verified_uid_sidecars': uids,
    'canonical_matches_tested': True, 'behavior_and_render_runtime_identical': True,
    'diff_check_exit': check.returncode, 'source': current, 'screenshots': screenshots})
print('PASS: exact scoped delta; canonical and tested runtime match; UID sidecars, checks, native captures and whitespace verified')
