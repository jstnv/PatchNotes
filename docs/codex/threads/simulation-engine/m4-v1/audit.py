from pathlib import Path
import difflib, hashlib, json, statistics, subprocess, zipfile

ROOT = Path(__file__).resolve().parents[5]
HERE = Path(__file__).resolve().parent
RUNS = ROOT / 'docs/codex/findings/card-presentation-v2'
def read(path): return json.loads(path.read_text(encoding='utf-8'))
def save(name, value): (HERE/name).write_text(json.dumps(value, indent=2), encoding='utf-8')
def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()

focused = read(HERE/'focused-checks.json')
fresh = read(HERE/'fresh-checks.json')
pilots = [read(path) for path in sorted(HERE.glob('m4-pilot-*.check.json'))]
assert len(focused) == 9 and len(fresh) == 12 and pilots
for row in focused + fresh + pilots:
    report = read(ROOT/row['evidence']/'command.json')
    assert report['exit'] == 0 and not report['errors'] and report['source_unchanged'] and report['drivers_unchanged'], row
    # Every accepted run must use this exact final source, including the verifier.
    for name, expected in read(ROOT/row['evidence']/'source-after.json').items():
        assert digest(ROOT/name) == expected, (row['evidence'], name)

live = read(RUNS/'m4-accepted-campaign-live-parity/fit.json')
batch = read(RUNS/'m4-batch-02/fit.json')
assert live['failures'] == 0 and live['comparisons'] == 94
assert all(row['matched'] and row['native'] == row['headless'] and row['live_signals'] == row['sim_signals'] for row in live['traces'])
assert batch['ok'] and batch['failures'] == 0
for row in fresh: assert row['report']['ok']

measurements = []
for row in pilots:
    report = read(ROOT/row['evidence']/'fit.json')
    assert report['ok'] and len(report['samples']) == 3 and len(report['warmups']) == 1
    reference = report['warmups'][0]['results']
    for sample in report['samples']:
        assert sample['results'] == reference and sample['ok']
        assert len(sample['results']) == row['cohort']
        assert all(case['ok'] and case['final_release_count'] == row['release_horizon'] for case in sample['results'])
    metrics = [metric for sample in report['samples'] for metric in sample['metrics']]
    elapsed = report['measurement']['elapsed_seconds']
    throughput = report['measurement']['instrumented_commands_per_second']
    artifact_root = ROOT/row['evidence']/'fit.json.batch'
    measurements.append({
        'cohort': row['cohort'], 'release_horizon': row['release_horizon'], 'samples': 3, 'warmups': 1,
        'commands_per_sample': sum(case['commands'] for case in reference),
        'elapsed_seconds': elapsed, 'median_seconds': statistics.median(elapsed),
        'instrumented_commands_per_second': throughput, 'median_commands_per_second': statistics.median(throughput),
        'worst_productive_command_us': max(metric['productive_command_max_us'] for metric in metrics),
        'peak_godot_static_bytes': max(metric['process_cumulative_peak_godot_static_bytes'] for metric in metrics),
        'retained_object_deltas': sorted({metric['objects_after_release'] - metric['objects_before'] for metric in metrics}),
        'total_artifact_bytes_including_warmup': sum(path.stat().st_size for path in artifact_root.rglob('*') if path.is_file()),
        'measurement_totals_us': {field: sum(metric[field] for metric in metrics) for field in
            ['setup_us', 'policy_and_observation_us', 'execute_and_trace_us', 'finalization_us', 'artifact_write_us']},
        'hardware': {field: metrics[0][field] for field in ['os', 'processor', 'processor_count']},
        'evidence': row['evidence']})

before = read(HERE/'before-hashes.json')
assert digest(ROOT/'docs/codex/TODO.md') == before['docs/codex/TODO.md']
for name, expected in before.items():
    if name.startswith('patch-notes/data/'): assert digest(ROOT/name) == expected, name
changed, patch = [], []
with zipfile.ZipFile(HERE/'before-source.zip') as archive:
    for path in sorted((ROOT/'patch-notes/scripts').rglob('*.gd')):
        name = path.relative_to(ROOT).as_posix()
        old = archive.read(name).decode('utf-8').replace('\r\n','\n') if name in archive.namelist() else ''
        new = path.read_text(encoding='utf-8')
        if old != new:
            changed.append(name)
            patch.extend(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/'+name,tofile='after/'+name))
expected = {'patch-notes/scripts/'+name for name in [
    'simulation/run_factory.gd', 'simulation/campaign_batch.gd', 'simulation/finite_fixture_policy.gd',
    'debug/campaign_replay_cli.gd', 'debug/campaign_batch_cli.gd', 'debug/verify_campaign_batch.gd', 'debug/verify_campaign_live_parity.gd']}
assert set(changed) == expected, changed
head = subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
assert head == (HERE/'head.txt').read_text().strip()
save('changed-scripts.json', changed)
(HERE/'turn.patch').write_text(''.join(patch),encoding='utf-8')
paths = list((ROOT/'patch-notes/scripts').rglob('*.gd')) + list((ROOT/'patch-notes/data').rglob('*.json')) + list(HERE.glob('*.py'))
save('source-after.json',{path.relative_to(ROOT).as_posix():digest(path) for path in paths})
(HERE/'status-after.txt').write_bytes(subprocess.check_output(['git','status','--short'],cwd=ROOT))
summary = {'head':head, 'focused_suites':len(focused), 'live_campaign_boundaries':94,
    'batch_checks':batch['checks'], 'fresh_processes':len(fresh),
    'fresh_replayed_commands':sum(len(row['report']['steps']) for row in fresh),
    'todo_unchanged':True, 'data_unchanged':True,
    'changed_scripts':changed, 'pilot_measurements':measurements, 'checks':focused+fresh+pilots}
save('acceptance.json',summary)
save('results.json',[{'label':path.name,'report':read(path/'command.json')} for path in sorted(RUNS.glob('m4-*')) if (path/'command.json').exists()])
print(json.dumps({key:value for key,value in summary.items() if key not in ['changed_scripts','checks']},indent=2))
