"""Read back current export evidence and the task's before-source manifest."""
from pathlib import Path
import hashlib
import json
import struct
import subprocess
import sys

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
PROJECT = ROOT/'patch-notes'
EXPORT = OUT/'export-v6'
COMPILED = 'd259a6545d3802f5a2493f96547d9e10ad26984f4342270724232a3764fbec72'
EDITOR = '5783246fcb2ecd6612eccf8e06cde72490db3ebb2944b8592e0943bfdaf94536'
def read(path):
    return json.loads(path.read_text(encoding='utf-8'))
def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

manifest = read(EXPORT/'build-manifest.json')
for name, info in manifest['artifacts'].items():
    path = EXPORT/'clean/demo'/name
    assert path.stat().st_size == info['bytes'] and sha(path) == info['sha256'], name
subprocess.run([sys.executable, str(EXPORT/'inspect.py')], check=True)
pack = read(EXPORT/'pack-manifest-verified.json')
assert pack['count'] == 331 and pack['all_payload_md5_valid'] and not pack['missing_runtime_files'] and not pack['unexpected_files']
source_mismatches = []
for name, expected in manifest['included'].items():
    path = PROJECT/name
    if not path.is_file() or sha(path) != expected:
        source_mismatches.append(name)
assert not source_mismatches, source_mismatches
build_results = {}
for name in ['clean-import', 'export-release']:
    report = read(EXPORT/(name+'.command.json'))
    assert report['exit'] == 0 and report['errors'] == []
    build_results[name] = {'exit': report['exit'], 'errors': report['errors']}

reports = {}
artifact_hashes = {}
for label in ['pack-identity-v6', 'pack-campaign-v6', 'pack-replay-v6', 'native-pack-market-v6',
              'pack-old-store-v6', 'native-pack-old-continue-v6']:
    run = read(OUT/(label+'-run.json'))
    assert run['exit'] == 0 and run['errors'] == []
    assert run['command'][1] == '--main-pack'
    report = read(OUT/(label+'.json')) if (OUT/(label+'.json')).exists() else {}
    if report:
        assert report.get('source_identity', report.get('source')) == COMPILED
        assert report.get('failures', 0) == 0
    reports[label] = {'checks': report.get('checks'), 'failures': report.get('failures'),
        'exit': run['exit'], 'errors': run['errors'], 'process_cpu_seconds': run['process_cpu_seconds'],
        'elapsed_seconds': run['elapsed_seconds']}
    for suffix in ['.json', '-run.json', '-process.json', '.log']:
        path = OUT/(label+suffix)
        if path.is_file(): artifact_hashes[path.name] = {'bytes': path.stat().st_size, 'sha256': sha(path)}
record = read(OUT/'pack-campaign-v6.json')
replay = read(OUT/'pack-replay-v6.json')
assert record['checks'] == 1071 and replay['checks'] == 1100
assert record['starting_source_identity'] == replay['starting_source_identity'] == COMPILED
assert not record['source_drift'] and not replay['source_drift']
assert record['completed'] and record['commands'] == replay['commands'] == 54
assert record['final'] == replay['final'] and record['releases'] == replay['releases']
assert record['observations'] == replay['observations'] and record['projects'] == replay['projects']
assert len(record['releases']) == 3 and record['releases'][-1]['cycle'] == 21
editor_record_path = OUT/'acceptance-pinned-v2-action-war.json'
editor_record = read(editor_record_path)
parity_fields = ['recipe', 'releases', 'projects', 'observations', 'coverage']
for field in parity_fields:
    assert editor_record[field] == record[field], 'Editor/compiled outcome mismatch: '+field
editor_checkpoint_path = OUT/'acceptance-pinned-v2-action-war.json.checkpoint.json'
compiled_checkpoint_path = OUT/'pack-campaign-v6.json.checkpoint.json'
editor_pair = read(editor_checkpoint_path)
compiled_pair = read(compiled_checkpoint_path)
assert editor_pair['player'] == compiled_pair['player'], 'Editor/compiled player checkpoint mismatch'
assert editor_pair['world']['source_identity'] == EDITOR
assert compiled_pair['world']['source_identity'] == COMPILED
editor_world = editor_pair['world'].copy()
compiled_world = compiled_pair['world'].copy()
editor_world.pop('source_identity')
compiled_world.pop('source_identity')
assert editor_world == compiled_world, 'Editor/compiled world checkpoint mismatch beyond build identity'
parity = {'status': 'PASS', 'fields_compared_exactly': parity_fields,
    'player_checkpoint_exact': True, 'world_checkpoint_exact_except': ['world.source_identity'],
    'editor_source_identity': EDITOR, 'compiled_source_identity': COMPILED,
    'commands': record['commands'], 'player_releases': len(record['releases']),
    'excluded_report_fields': ['timings', 'source_identity', 'starting_source_identity', 'final digest containing build identity'],
    'excluded_checkpoint_fields': ['top-level digest containing build identity'],
    'inputs': {p.name: {'bytes': p.stat().st_size, 'sha256': sha(p)} for p in [editor_record_path,
        OUT/'pack-campaign-v6.json', editor_checkpoint_path, compiled_checkpoint_path]}}
(OUT/'editor-compiled-parity-v6.json').write_text(json.dumps(parity, indent=2)+'\n', encoding='utf-8')
native = read(OUT/'native-pack-market-v6.json')
assert native['checks'] == 32 and native['failures'] == 0
assert {c['viewport'] for c in native['captures']} == {'(1152, 648)', '(1280, 720)'}
for width in [1152, 1280]:
    state = read(OUT/f'native-pack-market-v6-state-{width}.json')
    for key in ['before', 'after']: state[key]['run'].pop('seen_tutorial_topics', None)
    assert state['before'] == state['after']
store = read(OUT/'pack-old-store-v6.json')
assert store['inspection'] == 'valid' and store['restored'] and store['original_unchanged']
original = ROOT/'docs/codex/findings/queue-20261018-v2/roster-closeout.json'
assert sha(original) == store['original_sha256']
assert sha(Path(store['save']['path'])) == store['generation_sha256_before'] == store['generation_sha256_after']
assert store['generation'] == 1 and store['cycle'] == 1
continued = read(OUT/'native-pack-old-continue-v6.json')
assert continued['checks'] == 14 and continued['failures'] == 0
assert len(continued['results']) == 2 and all(r['generation'] == 1 and r['cycle'] == 1 for r in continued['results'])
captures = []
for capture in native['captures']+[{'path': r['capture'], 'viewport': r['dimensions']} for r in continued['results']]:
    path = Path(capture['path'])
    data = path.read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n'
    width,height = struct.unpack('>II', data[16:24])
    captures.append({'file': path.name, 'logical_viewport': capture['viewport'], 'raster_pixels': [width,height],
        'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()})

before_path = OUT/'before-source.json'
before = read(before_path)
current_paths = {p.relative_to(PROJECT).as_posix(): p for prefix, pattern in [('scripts','*.gd'), ('data','*.json'), ('queries','*.gd')]
    for p in (PROJECT/prefix).rglob(pattern)}
changed = []
for name in sorted(set(before)|set(current_paths)):
    current = sha(current_paths[name]) if name in current_paths else None
    old = before.get(name)
    if current != old:
        changed.append({'path': 'patch-notes/'+name, 'status': 'added' if old is None else 'removed' if current is None else 'modified',
            'before_sha256': old, 'current_sha256': current,
            'current_bytes': current_paths[name].stat().st_size if name in current_paths else None})
delta = {'date': '2026-10-22', 'branch': 'main', 'head': '0132c4dab398a2a94dbeae3caa68a36505fbfa4f',
    'baseline': 'before-source.json', 'baseline_sha256': sha(before_path), 'editor_mechanics_identity': EDITOR,
    'scope': 'scripts/**/*.gd including debug, data/**/*.json and queries/**/*.gd; comparison to this task baseline, not HEAD or whole worktree.',
    'before_count': len(before), 'current_count': len(current_paths), 'changed_count': len(changed),
    'status_counts': {s: sum(r['status'] == s for r in changed) for s in ['modified','added','removed']}, 'files': changed}
(OUT/'changed-source-manifest-20261022.json').write_text(json.dumps(delta, indent=2)+'\n', encoding='utf-8')
audit = {'date': '2026-10-22', 'status': 'PASS at compiled-package harness boundary',
    'compiled_source_identity': COMPILED, 'editor_source_identity': EDITOR,
    'artifacts': manifest['artifacts'], 'build_results': build_results, 'package_entries': pack['count'],
    'current_included_files': len(manifest['included']), 'current_included_mismatches': source_mismatches,
    'reports': reports, 'original_fixture_sha256': store['original_sha256'], 'unchanged_generation_sha256': store['generation_sha256_after'],
    'editor_compiled_parity': parity,
    'captures': captures, 'artifact_hashes': artifact_hashes,
    'limits': ['External harnesses run in the Godot editor executable loading the actual compiled PCK.',
               'Visual inspection of captures is owned by the root implementation pass.',
               'Direct release EXE startup is logged, but physical-input Continue is blocked and is not passing evidence.',
               'Player UI comparisons exclude existing seen_tutorial_topics metadata only.']}
(OUT/'export-v6-evidence-audit.json').write_text(json.dumps(audit, indent=2)+'\n', encoding='utf-8')
print(json.dumps({'package_entries': pack['count'], 'included_source_matches': len(manifest['included']),
    'delta_counts': delta['status_counts'], 'delta_total': len(changed), 'reports': reports,
    'artifacts': manifest['artifacts'], 'captures': len(captures)}))
