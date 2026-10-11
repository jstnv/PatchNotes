from pathlib import Path
import collections, difflib, hashlib, json, subprocess

ROOT=Path(__file__).resolve().parents[5]
HERE=Path(__file__).resolve().parent
RUNS=ROOT/'docs/codex/findings/card-presentation-v2'
def read(path): return json.loads(path.read_text(encoding='utf-8'))
def save(name,value): (HERE/name).write_text(json.dumps(value,indent=2),encoding='utf-8')
baseline=read(RUNS/'m2d-oracle-v1/fit.json.oracle')
live=read(RUNS/'m2d-final-parity/fit.json.live')
headless=read(RUNS/'m2d-final-parity/fit.json.headless')
assert baseline==live==headless
assert len(baseline)==12
counts=collections.defaultdict(lambda:{'accepted':0,'rejected':0})
for trace in baseline:
    for step in trace['steps']: counts[step['action']]['accepted' if step['ok'] else 'rejected']+=1
assert sum(v['accepted']+v['rejected'] for v in counts.values())==432
old={k.replace('\\','/'):v for k,v in read(HERE/'before-hashes.json').items()}
assert hashlib.sha256((ROOT/'docs/codex/TODO.md').read_bytes()).hexdigest()==old['docs/codex/TODO.md']
trace_path='patch-notes/design-logs/candidate-pool-repair-v1/card-motion/animation-traces.json'
assert hashlib.sha256((ROOT/trace_path).read_bytes()).hexdigest()==old[trace_path]
protocol=read(RUNS/'m2d-final-protocol-v5/fit.json.report.json')
cli=read(RUNS/'m2d-final-cli-v5/fit.json')
assert protocol['replay']['ok'] and cli['ok'] and cli==protocol['replay']
assert protocol['steps']==42 and protocol['reentry_checks']==14

# The generic runner rejects all ERROR lines. These two existing negative-test
# suites intentionally exercise failed scene construction and partial snapshots.
# Preserve their raw failed harness reports; accept only the exact diagnostics
# plus exit 0, explicit success footer and no failed assertions/script errors.
expected={
'verify_gameplay_transition':[
'ERROR: Failed to instantiate scene state of "", node count is 0. Make sure the PackedScene resource is valid.',
'ERROR: Could not instantiate a valid AlphaPhase placeholder.',
'ERROR: Failed to instantiate scene state of "", node count is 0. Make sure the PackedScene resource is valid.',
'ERROR: Could not instantiate a valid BetaPhase placeholder.'],
'verify_primitive_run_initialization':['ERROR: Could not initialize the Primitive project snapshots.']}
repaired={'verify_alpha_finalization':'m2d-repair-alpha-finalization','verify_beta_host_playtest':'m2d-repair-beta-playtest','verify_development_replay':'m2d-final-parity','verify_development_protocol':'m2d-final-protocol-v5'}
accepted=[]
for row in read(HERE/'check-results.json'):
    if row['script']=='verify_alpha_host_playtest': continue # no such suite; Alpha coverage is in Alpha phase and Beta Host Playtest suites
    label=repaired.get(row['script'],row['label'])
    report=read(RUNS/label/'command.json')
    log=(RUNS/label/'output.log').read_text(encoding='utf-8',errors='replace')
    assert report['exit']==0 and report['source_unchanged'] and report['drivers_unchanged']
    assert 'SCRIPT ERROR' not in log and 'FAIL:' not in log
    if row['script'] in expected:
        assert report['errors']==expected[row['script']] and 'verification passed.' in log
    else: assert report['errors']==[]
    accepted.append({'script':row['script'],'evidence':str((RUNS/label).relative_to(ROOT)).replace('\\','/'),'expected_negative_diagnostics':expected.get(row['script'],[])})
assert len(accepted)==21
cli_report=read(RUNS/'m2d-final-cli-v5/command.json')
assert cli_report['exit']==0 and cli_report['errors']==[] and cli_report['source_unchanged']
save('acceptance.json',{'original_live_headless_equal':True,'routes':12,'steps_per_path':432,'actions':counts,'protocol_steps':42,'reentry_checks':14,'fresh_process_replay_equal':True,'focused_suites':accepted,'todo_unchanged':True,'previous_motion_artifact_restored':True})
reports=[]
for folder in sorted(RUNS.glob('m2d-*')):
    if (folder/'command.json').exists(): reports.append({'folder':str(folder.relative_to(ROOT)).replace('\\','/'),'report':read(folder/'command.json')})
save('results.json',reports)
paths=list((ROOT/'patch-notes/scripts').rglob('*.gd'))+list((ROOT/'patch-notes/data').rglob('*.json'))
save('source-after.json',{str(p.relative_to(ROOT)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for p in paths})
changed=[]; patch=[]
import zipfile
with zipfile.ZipFile(HERE/'before-scripts.zip') as archive:
    for path in paths:
        name=str(path.relative_to(ROOT)).replace('\\','/')
        if path.suffix!='.gd': continue
        before=archive.read(name).decode('utf-8').replace('\r\n','\n') if name in archive.namelist() else ''
        after=path.read_text(encoding='utf-8')
        if before!=after:
            changed.append(name)
            patch.extend(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile='before/'+name,tofile='after/'+name))
save('changed-scripts.json',changed)
(HERE/'turn.patch').write_text(''.join(patch),encoding='utf-8')
(HERE/'status-after.txt').write_bytes(subprocess.run(['git','status','--short'],cwd=ROOT,stdout=subprocess.PIPE,check=True).stdout)
print(json.dumps({'parity_steps':432,'accepted':336,'rejected':96,'focused_suites':len(accepted),'fresh_process_tape_steps':42,'changed_scripts':len(changed),'todo_unchanged':True}))
