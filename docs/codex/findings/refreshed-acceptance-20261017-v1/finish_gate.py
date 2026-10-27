"""Finish the pinned gate with a separately pinned verifier cleanup correction.

The original gate's failure/source manifest remain untouched. No runtime edit.
The new cold-Continue verifier must consume the prior activation process profile.
"""
from pathlib import Path
import difflib, hashlib, importlib.util, json, os, shutil, subprocess, sys

BASE = Path(__file__).resolve().parent
REPO = BASE.parents[3]
SNAP = BASE / 'snapshot'
OUT = BASE / 'gate-continuation'
resume = '--resume' in sys.argv
OUT.mkdir(exist_ok=resume)

def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

gate = load('pinned_gate', SNAP / 'tools/release_gate.py')
checks = load('pinned_checks', SNAP / 'docs/codex/findings/checkpoint-runtime-v1/run_checks.py')
checks.HERE = OUT
checks.PROFILE = OUT / 'profiles'
os.environ['PN_CHECKPOINT_TEST_PORT'] = '47733'
original = json.loads((BASE / 'gate/gate-result.json').read_text())
done = original['checks']
report = json.loads((OUT / 'result.json').read_text()) if resume else {'prior_gate': '../gate/gate-result.json', 'prior_passed': done, 'checks': [],
          'runtime_changed': False, 'pass': False, 'limits': ['Split verification evidence; original gate failure is retained.']}
fixed_name = 'verify_rival_trial_activation'
old = SNAP / f'patch-notes/scripts/debug/{fixed_name}.gd'
new = REPO / f'patch-notes/scripts/debug/{fixed_name}.gd'
old_text, new_text = old.read_text(), new.read_text()
assert [x for x in new_text.splitlines() if x.strip() != 'coordinator.free()'] == old_text.splitlines(), 'Unexpected assertion/runtime change in verifier correction'
fixed = OUT / (fixed_name + '.gd')
shutil.copy2(new, fixed)
(OUT / 'verifier-cleanup.diff').write_text(''.join(difflib.unified_diff(old_text.splitlines(True),new_text.splitlines(True),fromfile='pinned',tofile='canonical-cleanup')))
report['corrected_verifier'] = {'path':str(fixed), 'old_sha256':sha(old), 'sha256':sha(fixed)}

def record():
    (OUT / 'result.json').write_text(json.dumps(report,indent=2)+'\n')

try:
    for path in sorted((SNAP / 'patch-notes/scripts/debug').glob('verify_*.gd')):
        if path.stem in done or path.stem in report['checks']:
            continue
        evidence = OUT / 'verifier-artifacts' / path.stem
        evidence.mkdir(parents=True,exist_ok=resume)
        os.environ['PN_CARD_FRAME_OUTPUT'] = str(evidence / 'result.json')
        if path.stem == fixed_name:
            script = fixed
        else:
            script, metadata = gate.checkpoint_wrapper(path, OUT / 'wrappers')
            report.setdefault('wrappers', {})[path.stem] = metadata
        timeout = 1200 if path.stem == 'verify_sidestreet_scope_and_year' else 240
        previous_log = OUT / (path.stem + '.log')
        if previous_log.exists():
            archive = OUT / 'attempts'
            archive.mkdir(exist_ok=True)
            retained = archive / (path.stem + '-240s.log')
            assert not retained.exists(), 'Do not overwrite prior attempts'
            shutil.copy2(previous_log,retained)
        report.setdefault('timeouts_seconds',{})[path.stem] = timeout
        checks.run(path.stem, ['--script',str(script)],timeout=timeout)
        report['checks'].append(path.stem)
        record()

    cold = OUT / 'verify_rival_gameplay_cold_continue.gd'
    shutil.copy2(REPO / 'patch-notes/scripts/debug' / cold.name,cold)
    profiles = list((BASE / 'gate/profiles').glob('verify_rival_gameplay_activation-*'))
    assert len(profiles) == 1, profiles
    env = os.environ.copy()
    for key in ('APPDATA','LOCALAPPDATA'):
        env[key] = str(profiles[0] / key)
    command = [checks.GODOT,'--headless','--path',str(checks.PROJECT),'--script',str(cold)]
    with (OUT / 'verify_rival_gameplay_cold_continue.log').open('wb') as log:
        result = subprocess.run(command,cwd=SNAP,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=90)
    output = (OUT / 'verify_rival_gameplay_cold_continue.log').read_text()
    errors = [line for line in output.splitlines() if line.startswith('ERROR:') or 'SCRIPT ERROR' in line]
    report['cold_continue'] = {'command':command,'profile':str(profiles[0]),'sha256':sha(cold),'exit':result.returncode,'errors':errors}
    assert result.returncode == 0 and not errors, output[-2000:]
    report['checks'].append(cold.stem)
    report['pass'] = True
finally:
    record()
print(json.dumps({'pass':report['pass'],'prior_suites':len(done),'continued_suites':len(report['checks'])}))
