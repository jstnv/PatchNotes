from pathlib import Path
import hashlib, importlib.util, json, struct, subprocess

ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('sim', ROOT / 'tools/simulate.py')
sim = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sim)
before = json.loads((OUT / 'before/source.json').read_text())
behavior = json.loads((OUT / 'final-v2/source.json').read_text())
tested = json.loads((OUT / 'render-final-v1/source.json').read_text())
current = sim.source_hashes(ROOT / 'patch-notes')
changed = sorted(k for k in before if tested.get(k) != before[k])
added = sorted(set(tested) - set(before))
expected_changed = {'scripts/ui/gameplay_hud.gd', 'scripts/ui/pause_menu.gd', 'scripts/gameplay.gd',
                    'scripts/phases/main_menu.gd', 'scripts/market/rival_world_checkpoint.gd',
                    'scripts/debug/verify_first_game_and_tips.gd'}
expected_added = {'scripts/ui/how_to_play_content.gd', 'scripts/ui/how_to_play_guide.gd',
                  'scripts/debug/verify_how_to_play.gd', 'scripts/debug/capture_how_to_play.gd'}
script_additions = expected_added.copy()
expected_added |= {k + '.uid' for k in script_additions}
assert set(changed) == expected_changed, changed
assert set(added) == expected_added, added
assert all(current.get(k) == v for k, v in tested.items()), 'Canonical differs from final tested input'
assert current == tested, 'Canonical source set differs from final input'
assert {k:v for k,v in behavior.items() if not k.startswith('scripts/debug/')} == {
    k:v for k,v in tested.items() if not k.startswith('scripts/debug/')}, 'Runtime changed after behavior tests'
uids = sorted(k + '.uid' for k in script_additions)
for k in uids:
    assert (OUT / 'render-final-v1/project' / k).read_bytes() == (ROOT / 'patch-notes' / k).read_bytes()
results = json.loads((OUT / 'final-v2/results.json').read_text())
assert len(results) == 6 and all(r['exit'] == 0 and not r['errors'] for r in results)
rendered = json.loads((OUT / 'render-final-v1/results.json').read_text())
assert len(rendered) == 2 and all(r['exit'] == 0 and not r['errors'] for r in rendered)
screenshots = {}
for p in sorted((OUT / 'render-final-v1').glob('*.png')):
    width, height = struct.unpack('>II', p.read_bytes()[16:24])
    assert p.stem.endswith(f'{width}x{height}'), p.name
    screenshots[p.name] = {'width': width, 'height': height, 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
assert len(screenshots) == 16
files = [str(ROOT / 'patch-notes' / k) for k in sorted(expected_changed | expected_added)]
files += [str(ROOT / 'docs/codex' / k) for k in ['TODO.md','CURRENT_STATE.md','design/core-and-studio.md','design/release-engineering.md']]
check = subprocess.run(['git', '-c', 'core.whitespace=cr-at-eol', 'diff', '--check', '--', *files], cwd=ROOT, capture_output=True, text=True)
(OUT / 'diff-check.log').write_text(check.stdout + check.stderr, encoding='utf-8')
assert check.returncode == 0
for k in expected_added:
    assert all(line == line.rstrip() for line in (ROOT / 'patch-notes' / k).read_text().splitlines()), k
sim.write_json(OUT / 'audit.json', {
    'branch': subprocess.check_output(['git','branch','--show-current'], cwd=ROOT, text=True).strip(),
    'head': subprocess.check_output(['git','rev-parse','HEAD'], cwd=ROOT, text=True).strip(),
    'changed_from_pre_edit': changed, 'added_to_pre_edit': added, 'verified_uid_sidecars': uids,
    'canonical_matches_tested': True, 'behavior_render_runtime_identical': True, 'diff_check_exit': check.returncode,
    'source': current, 'screenshots': screenshots})
print('PASS: exact scoped source delta, canonical/tested runtime match, verified UIDs, clean behavior/render processes and 16 native captures')
