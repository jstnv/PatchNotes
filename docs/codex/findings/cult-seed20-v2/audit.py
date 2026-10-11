from pathlib import Path
import copy, difflib, hashlib, importlib.util, json, subprocess, zipfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
spec = importlib.util.spec_from_file_location('sim', ROOT / 'tools/simulate.py')
sim = importlib.util.module_from_spec(spec); spec.loader.exec_module(sim)
checks = 0
def check(condition, label):
    global checks
    checks += 1
    if not condition: raise AssertionError(label)
def read(path): return json.loads(path.read_text())
def payload(case, mode='write'): return read(HERE / case / (mode + '.json'))['payload']
before = read(HERE / 'before-hashes.json')
current = sim.source_hashes(ROOT / 'patch-notes')
check(current == read(HERE / 'restart-v2-canonical-before.json'), 'Canonical source frozen throughout restart and final audit')
check((ROOT / 'patch-notes/.codex-godot-temp').is_dir(), 'Existing temp tree retained')
check(subprocess.check_output(['git','rev-parse','HEAD'], cwd=ROOT).decode().strip() == (HERE/'head.txt').read_text().strip(), 'HEAD unchanged')
changed = []
diff = []
with zipfile.ZipFile(HERE / 'before-source.zip') as old:
    for name, digest in before.items():
        if not name.startswith('patch-notes/'): continue
        now = ROOT / name
        if sim.sha(now) != digest:
            changed.append(name)
            diff.extend(difflib.unified_diff(old.read(name).decode('utf-8-sig').replace('\r\n','\n').splitlines(True), now.read_text(encoding='utf-8-sig').splitlines(True), fromfile='before/'+name, tofile='after/'+name))
        check(now.exists(), 'Pre-existing source retained: '+name)
check(set(changed) == {'patch-notes/scripts/studio_traits.gd','patch-notes/scripts/persistence/studio_checkpoint.gd','patch-notes/scripts/debug/campaign_stress_suite.gd'}, 'Only two mechanics files and stress expectation changed after capture')
(HERE / 'canonical-delta.patch').write_text(''.join(diff))
# The agent had already updated two focused verifier files when before-source.zip
# was taken; its result records retain that boundary. No gameplay/data was edited then.
old_control = payload('old-restart-control-v2')
new_control = payload('new-restart-control-v2')
normalized = copy.deepcopy(old_control)
normalized['content_revision'] = new_control['content_revision']
normalized['run']['studio_traits']['version'] = '8'
check(normalized == new_control, 'Two-release non-Cult negative control exact apart from version/revision')
checks_by_process = read(HERE / 'restart-summary.json')
check(checks_by_process['ok'] and checks_by_process['processes'] == 34 and checks_by_process['checks'] == 629, 'Restart matrix complete')
for record in checks_by_process['records']:
    result = read(HERE / record['folder'] / (record['mode']+'.json'))
    check(result['ok'] and result['failures'] == 0, 'Restart process passed')
for case in ['control','cult-creation','cult-launch','cult-months','cult-buzz','cult-graduate']:
    old = payload('old-restart-'+case+'-v2')
    new = payload('new-restart-'+case+'-v2')
    check(old['rng'] == new['rng'], 'Old/new exact RNG: '+case)
    for era in ['old','new']:
        written = payload(era+'-restart-'+case+'-v2')
        loaded = payload(era+'-restart-'+case+'-v2', 'read')
        expected = copy.deepcopy(written); expected['content_revision'] = loaded['content_revision']
        check(expected == loaded, 'Whole saved payload roundtrip: '+era+'/'+case)
for era, version, fans in [('old',7,40),('new',8,20)]:
    created = payload(era+'-restart-cult-creation-v2')['run']
    check(int(created['studio_traits']['version']) == version and int(created['fanbase']['fans']) == fans and int(created['cash_cents']) == 565000, 'Exact Cult creation: '+era)
for version in range(3,7):
    saved = payload('old-inactive-'+str(version)+'-v2','read')['run']
    check(int(saved['studio_traits']['version']) == version and int(saved['fanbase']['fans']) == 0 and int(saved['cash_cents']) == 570000, 'Inactive historical preview: '+str(version))
focused = read(HERE / 'focused-checks.json')
check(len(focused) == 8 and all(r['exit'] == 0 and not r['errors'] and r['source_unchanged'] for r in focused), 'Import and seven focused suites passed')
check(read(HERE / 'awareness-stage-order-01/summary.json') == {'ok':True,'pass_lines':19,'source_unchanged':True}, 'Constructed Cult/Buzz/Unknown and keyed Promotion checks passed')
identity = hashlib.sha256(json.dumps(current,sort_keys=True).encode()).hexdigest()
sim.write_json(HERE / 'after-source-manifest.json', current)
if (HERE / 'after-source.zip').exists():
    with zipfile.ZipFile(HERE / 'after-source.zip') as archive:
        if not all(archive.read(name) == (ROOT/name).read_bytes() for name in archive.namelist()):
            raise AssertionError('Retained after-source archive differs from current source')
else:
    with zipfile.ZipFile(HERE / 'after-source.zip','x',zipfile.ZIP_DEFLATED) as archive:
        for name in before:
            if name.startswith('patch-notes/'): archive.write(ROOT/name,name)
summary = {'ok':True,'checks':checks,'canonical_source_identity':identity,'mechanics_changed':['scripts/studio_traits.gd','scripts/persistence/studio_checkpoint.gd'],'after_capture_changed':changed,'negative_control':'36-command two-release whole payload identical except trait version and content revision','restart_processes':34,'restart_checks':629,'constructed_awareness_checks':19,'source_unchanged':True,'head':(HERE/'head.txt').read_text().strip()}
sim.write_json(HERE / 'audit.json', summary)
print(json.dumps(summary,indent=2))
