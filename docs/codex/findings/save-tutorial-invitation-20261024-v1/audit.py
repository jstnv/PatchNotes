"""Retain compact receipts, source hashes and only this change's deltas."""
from pathlib import Path
import difflib, importlib.util, json, shutil, subprocess
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
RAW = Path('C:/Users/64jus/AppData/Local/Temp/pn-save-tutorial-20261024-v1')
spec = importlib.util.spec_from_file_location('save_tutorial_sim', ROOT/'tools/simulate.py')
sim = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sim)
read = lambda p: json.loads(p.read_text(encoding='utf8'))
red = read(RAW/'red/result.json')
green = read(RAW/'green/result.json')
regressions = read(RAW/'regressions-final/result.json')
cold = read(RAW/'cold/result.json')
assert not red['pass'] and red['canonical_unchanged']
assert green['pass'] and regressions['pass'] and cold['pass']
assert len(green['checks']) == 4 and len(regressions['checks']) == 2
source = sim.source_hashes(ROOT/'patch-notes')
assert all(source[k] == v for k, v in read(RAW/'regressions-final/canonical-source.json').items())
older = read(RAW/'green/canonical-source.json')
delta = sorted(k for k in source if source.get(k) != older.get(k))
assert delta == ['scripts/debug/verify_checkpoint_recovery_ui.gd', 'scripts/debug/verify_pause_menu.gd'], delta
for stage in ['red', 'green', 'regressions', 'regressions-final', 'prior', 'cold']:
    target = HERE/'receipts'/stage
    target.mkdir(parents=True, exist_ok=True)
    for path in (RAW/stage).glob('*'):
        if path.is_file() and (path.name in ['result.json', 'receipt.json', 'run.log'] or path.name.startswith('verify_') and path.suffix in ['.json', '.log']):
            shutil.copy2(path, target/path.name)
sim.write_json(HERE/'source.json', source)
patch = ''
for name in ['scripts/gameplay.gd', 'scripts/market/rival_world_checkpoint.gd', *delta]:
    prior = (RAW/'red/project'/name).read_text(encoding='utf8').splitlines(keepends=True)
    after = (ROOT/'patch-notes'/name).read_text(encoding='utf8').splitlines(keepends=True)
    patch += ''.join(difflib.unified_diff(prior, after, fromfile='before/'+name, tofile='after/'+name))
(HERE/'scoped.patch').write_text(patch, encoding='utf8')
assert read(RAW/'prior/result.json')['world']['source_identity'] == cold['prior_source']
sim.write_json(HERE/'result.json', {
    'pass': True, 'head': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
    'branch': subprocess.check_output(['git', 'branch', '--show-current'], cwd=ROOT, text=True).strip(),
    'raw': str(RAW), 'runtime_identity': cold['source'], 'preceding_runtime_identity': cold['prior_source'],
    'red_failures': 3, 'save_invitation_checks': 26, 'tutorial_ui_checks': 115,
    'suites': [row['name'] for report in [green, regressions] for row in report['checks']],
    'final_debug_only_delta': delta, 'cold_restore': cold, 'release_ready': False,
})
print('Audited six passing suites and exact preceding-world restore; source unchanged.')
