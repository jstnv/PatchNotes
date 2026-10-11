"""Focused M4 evidence; each Godot process gets its own isolated profile.

Run stages serially after source is frozen. Existing directories are never reused.
"""
from pathlib import Path
import importlib.util, json, os, sys

ROOT = Path(__file__).resolve().parents[5]
HERE = Path(__file__).resolve().parent
RUNS = ROOT / 'docs/codex/findings/card-presentation-v2'
spec = importlib.util.spec_from_file_location('isolated', RUNS / 'run.py')
harness = importlib.util.module_from_spec(spec)
spec.loader.exec_module(harness)

def read(path):
    return json.loads(path.read_text(encoding='utf-8'))

def save(name, value):
    (HERE / name).write_text(json.dumps(value, indent=2), encoding='utf-8')

def invoke(label, script, environment=None):
    environment = environment or {}
    old = {key: os.environ.get(key) for key in environment}
    try:
        os.environ.update({key: str(value) for key, value in environment.items()})
        harness.run(label, script)
    finally:
        for key, value in old.items():
            if value is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = value
    return {'suite': script, 'evidence': (RUNS / label).relative_to(ROOT).as_posix()}

def focused():
    # The repaired batch verifier already passed on this frozen source.
    checks = [{'suite':'verify_campaign_batch.gd', 'evidence':'docs/codex/findings/card-presentation-v2/m4-batch-02'}]
    for name in ['campaign_live_parity', 'campaign_session',
                 'campaign_continuation', 'development_protocol', 'development_replay',
                 'contract_extraction', 'checkpoint_runtime', 'studio_checkpoint']:
        checks.append(invoke('m4-accepted-' + name.replace('_', '-'), 'verify_' + name + '.gd'))
        save('focused-checks.json', checks)

def replay(label, initial, tape):
    assert len(initial) == 1
    kind, payload = next(iter(initial.items()))
    path = HERE / (label + '.' + kind + '.json')
    path.write_text(json.dumps(payload, indent=2), encoding='utf-8')
    row = invoke(label, 'campaign_replay_cli.gd', {
        'PN_CAMPAIGN_RECIPE': path if kind == 'recipe' else '',
        'PN_CAMPAIGN_CHECKPOINT': path if kind == 'checkpoint' else '',
        'PN_CAMPAIGN_TAPE': tape})
    report = read(ROOT / row['evidence'] / 'fit.json')
    assert report['ok'], report
    row['report'] = report
    return row

def fresh():
    checks = []
    live = RUNS / 'm4-accepted-campaign-live-parity'
    for seed in [4417, 90210]:
        for segment in range(3):
            prefix = live / f'fit.json.campaign_{seed}'
            if segment == 0:
                initial = {'recipe': read(Path(str(prefix) + '.recipe.json'))}
            else:
                initial = {'checkpoint': read(Path(str(prefix) + f'.segment-{segment}.checkpoint.json'))}
            checks.append(replay(f'm4-fresh-live-{seed}-{segment}', initial,
                Path(str(prefix) + f'.segment-{segment}.tape.json')))
            save('fresh-checks.json', checks)
    batch = RUNS / 'm4-batch-02/fit.json.artifacts'
    for group, case in [('original', 'first'), ('original', 'second'), ('checkpoint', 'checkpoint'),
                        ('idle', 'bound'), ('rejected', 'rejected'), ('malformed', 'malformed')]:
        folder = batch / group / case
        checks.append(replay(f'm4-fresh-batch-{case}', read(folder / 'initial.json'), folder / 'replay.tape.json'))
        save('fresh-checks.json', checks)

if __name__ == '__main__':
    {'focused': focused, 'fresh': fresh}[sys.argv[1]]()
