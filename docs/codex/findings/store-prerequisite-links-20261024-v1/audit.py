"""Retain compact source-pinned results without copying import caches or profiles."""
import difflib, json, shutil, subprocess
import checks

HERE, RAW, ROOT = checks.HERE, checks.RAW, checks.ROOT
read = lambda path: json.loads(path.read_text(encoding='utf-8'))
assertions = 0
def require(condition, message):
    global assertions
    assert condition, message
    assertions += 1

source = checks.sim.source_hashes(ROOT / 'patch-notes')
before = checks.sim.source_hashes(RAW / 'red/project')
delta = {name: {'before': before.get(name), 'after': source.get(name)}
         for name in sorted(before.keys() | source.keys()) if before.get(name) != source.get(name)}
require(set(delta) == {'scripts/ui/feature_store_map.gd', 'scripts/ui/menu_transitions.gd',
                       'scripts/market/rival_world_checkpoint.gd'}, 'Only three runtime changes against RED')
matrix = read(RAW / 'final-v2/result.json')
require(matrix['pass'] and matrix['canonical_unchanged'], 'Final unchanged maintained matrix')
require(len(matrix['checks']) == 11 and all(row['pass'] for row in matrix['checks']), 'All eleven suites pass')
require(source == read(RAW / 'final-v2/canonical-source.json'), 'Canonical equals final matrix input')
require(source == checks.sim.source_hashes(RAW / 'keyboard-green/project'), 'Native, keyboard and cold checks use final code')
native = read(RAW / 'final-audit.json')
require(native['pass'] and native['canonical_unchanged'], 'Final native/cold audit unchanged')
require('45 checks, 0 failures' in (RAW / 'native-v2/run.log').read_text(encoding='utf-8'), '45 native checks')
keyboard = (RAW / 'keyboard-green/run.log').read_text(encoding='utf-8')
require(read(RAW / 'keyboard-green/receipt.json')['pass'] and keyboard.count('PASS:') == 5, 'Five real keyboard checks')
require(not read(RAW / 'keyboard-red-v2/receipt.json')['pass'], 'Retain meaningful keyboard RED')
require(not read(RAW / 'red/result.json')['checks'][0]['pass'], 'Retain original layout RED')
for predecessor in ['previous-editor', 'previous-pack']:
    require(read(RAW / predecessor / 'receipt.json')['pass'], 'Actual previous-source campaign generated')
    receipt = read(RAW / ('final-' + predecessor) / 'result.json')
    require(receipt['pass'] and receipt['exact_state_rng'] and receipt['unknown_mixed_reject'], 'Exact cold world and strict rejection')
    require(read(RAW / predecessor / 'result.json')['commands'] == 36, 'Legal 36-command predecessor fixture')

checks.sim.write_json(HERE / 'source.json', source)
checks.sim.write_json(HERE / 'adoption-delta.json', delta)
patch = []
for name in delta:
    patch.extend(difflib.unified_diff((RAW/'red/project'/name).read_text(encoding='utf-8').splitlines(True),
        (ROOT/'patch-notes'/name).read_text(encoding='utf-8').splitlines(True), fromfile='before/'+name, tofile='after/'+name))
(HERE / 'runtime.patch').write_text(''.join(patch), encoding='utf-8')
for relative in ['final-v2/result.json', 'keyboard-red-v2/receipt.json', 'keyboard-green/receipt.json',
                 'final-previous-editor/result.json', 'final-previous-pack/result.json', 'native-v2/receipt.json']:
    target = HERE / 'receipts' / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(RAW / relative, target)
for width in [1152, 1280, 900]:
    path = RAW / 'native-v2/capture' / ('prerequisites-%s.png' % width)
    require(path.is_file(), 'Native capture exists')
    (HERE / 'captures').mkdir(exist_ok=True)
    shutil.copy2(path, HERE / 'captures' / path.name)
files = {}
for path in RAW.rglob('*'):
    if not path.is_file() or any(part in {'project', 'profile', 'profiles', 'import-profile', 'driver-profile', 'wrappers', 'docs'} for part in path.relative_to(RAW).parts): continue
    if path.suffix in {'.json', '.log', '.png'}:
        files[str(path.relative_to(RAW)).replace('\\', '/')] = {'bytes':path.stat().st_size, 'sha256':checks.sim.sha(path)}
checks.sim.write_json(HERE / 'external-artifacts.json', {'root':str(RAW), 'files':files})
report = {'pass':True, 'assertions':assertions, 'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
          'runtime_identity':read(RAW/'final-previous-editor/result.json')['source'],
          'matrix_suites':11,'native_checks':45,'keyboard_checks':5,'prior_worlds':2,
          'runtime_delta':list(delta),'release_ready':False}
checks.sim.write_json(HERE / 'audit.json', report)
print(json.dumps(report), flush=True)
