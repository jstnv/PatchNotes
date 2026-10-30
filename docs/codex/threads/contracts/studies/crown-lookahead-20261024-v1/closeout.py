from pathlib import Path
import hashlib,json,re,shutil

study=Path(__file__).resolve().parent
thread=study.parent.parent
raw=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-lookahead-20261024-v1')
load=lambda p:json.loads(p.read_text(encoding='utf-8'))
def sha(p):
    h=hashlib.sha256()
    with p.open('rb') as f:
        for chunk in iter(lambda:f.read(1024*1024),b''):h.update(chunk)
    return h.hexdigest()
checks=0
def check(value,reason):
    global checks
    assert value,reason
    checks+=1
report=load(raw/'candidates/run-report.json')
control_report=load(raw/'controls-v2/run-report.json')
paths={p.parent.name:p for folder in ['controls-v2','candidates'] for p in (raw/folder/'cases').glob('*/result.json')}
cases={label:load(p) for label,p in paths.items()}
check(len(cases)==18 and sum(r['ok'] for r in cases.values())==12,'all 18 cases retained, 12 completed')
check(all(r['error']=='Unaffordable hand' and r['commands']==53 and r['accepted_commands']==52 for r in cases.values() if not r['ok']),'same bounded intake failures')
replays={}
for label in ['lookahead-4417','lookahead_safe-4418']:
    steps=cases[label]['commands']
    r=load(raw/f'replay-{label}/replay-report.json')
    check(r['ok'] and len(r['steps'])==steps and r['final_state']==cases[label]['final_state'],label+' exact fresh replay')
    check(all(x['accepted'] for x in r['steps']),label+' accepted replay')
    replays[label]={'steps':steps,'final_state':r['final_state']}
    shutil.copyfile(raw/f'replay-{label}/replay-report.json',study/f'replay-{label}.json')
parent=cases['lookahead_safe-4418']
cold=load(raw/'cold-lookahead_safe-4418/cases/cold-lookahead_safe-4418/result.json')
check(cold['ok'] and cold['commands']==15 and cold['final_release_count']==7,'bounded cold Continue')
check(cold['initial_state']==parent['final_state'] and cold['initial_rng']==parent['final_rng'],'exact whole state/RNG cold boundary')
old=load(paths['lookahead_safe-4418'].parent/'studio_checkpoint.json')['studio_payload']['run']
new=load(raw/'cold-lookahead_safe-4418/cases/cold-lookahead_safe-4418/studio_checkpoint.json')['studio_payload']['run']
check(old['crown_briefs']==new['crown_briefs'],'completed Brief/redraws and pending offer unchanged')
check(old['publisher_relationships']==new['publisher_relationships'],'complete standing event history unchanged')
decode=lambda xs:{x['key']:x['value'] for x in xs}
for label,r in cases.items():
    if not r['ok']:continue
    cp=load(paths[label].parent/'studio_checkpoint.json')['studio_payload']['run']
    check('starwave' not in decode(cp['unlocked_publishers']),label+' no cash-Contract count leakage')
    check(cp['commission_deals']==[] and cp['support_deals']==[],label+' no unapproved game deals')
for name in ['crown-balance-base-v1','crown-balance-brief-v1','crown-planning-brief-v1','crown-lookahead-brief-v1']:
    folder=thread/'simulators'/name
    for rel,digest in load(folder/'integrity.json').items():check(sha(folder/rel)==digest,name+' immutable ancestry '+rel)
for change in load(study.parent/'crown-balance-20261024-v1/candidate-build.json'):
    check(sha(thread/'simulators/crown-balance-brief-v1/project'/change['path'])==change['after'],'parent original bytes '+change['path'])
manifest=load(raw/'candidates/workspace-source-manifest.json')
creation=load(raw/'candidates/variant-creation-manifest.json')
delta=[k for k in sorted(set(manifest)|set(creation)) if manifest.get(k)!=creation.get(k)]
check(delta==['scripts/simulation/contract_session.gd'],'only observation changed from parent')
for rel,digest in manifest.items():check(sha(thread/'simulators/crown-lookahead-brief-v1/project'/rel)==digest,'retained candidate source '+rel)
receipt=load(study/'prepare-receipt.json')
check(sha(thread/'simulators/crown-planning-brief-v1/project/scripts/simulation/contract_session.gd')==receipt['before'],'immediate parent observation unchanged')
check(sha(study/'policy.gd')==receipt['policy_sha256'],'policy remained frozen')
check(all(sha(study/f'{n}.json')==receipt['configs'][n] for n in ['controls','candidates']),'cases remained frozen')
check(sha(thread/'CROWN-LOOKAHEAD-PLAN-2026-10-24-v1.md')==receipt['plan_sha256'],'pre-run plan unchanged')
warnings=[]
for dirname in ['controls-v2','candidates','replay-lookahead-4417','replay-lookahead_safe-4418','cold-lookahead_safe-4418']:
    for p in (raw/dirname).glob('*.log'):
        lines=[s for s in p.read_text(encoding='utf-8',errors='replace').splitlines() if re.search(r'SCRIPT ERROR|ERROR:|WARNING:',s)]
        if lines:warnings.append({'path':str(p),'lines':lines})
check(load(raw/'controls/run-report.json')['error']=='Canonical source changed while recording drift; retry in a new output','retained capture abort')
check(report['frozen_source_identity']==control_report['frozen_source_identity'],'identical frozen code/policy across batches')
selected=[raw/'controls/run-report.json',raw/'controls-v2/run-report.json',raw/'controls-v2/experiment.log',raw/'candidates/run-report.json',raw/'candidates/workspace-source-manifest.json',raw/'candidates/snapshot-manifest.json',raw/'candidates/canonical-source-manifest.json',raw/'candidates/experiment.log',raw/'candidates/experiment.command.json',raw/'cold-lookahead_safe-4418/run-report.json']
for label in cases:selected.append(paths[label])
for label in replays:selected.append(raw/f'replay-{label}/replay-report.json')
shutil.copyfile(raw/'controls-v2/run-report.json',study/'control-run-report.json')
shutil.copyfile(raw/'controls/run-report.json',study/'failed-capture-report.json')
for name in ['run-report.json','workspace-source-manifest.json','canonical-source-manifest.json']:
    shutil.copyfile(raw/'candidates'/name,study/f'candidate-{name}')
shutil.copyfile(raw/'cold-lookahead_safe-4418/run-report.json',study/'cold-run-report.json')
out=dict(status='PASS',scope='bounded evidence/integrity closeout, not approval; six intake rejections and one aborted capture retained',checks=checks,
    recorded_commands=sum(x['commands'] for x in cases.values()),accepted_commands=sum(x['accepted_commands'] for x in cases.values()),
    identities={k:report['variant'][k] for k in ['base_identity','creation_identity','candidate_identity','canonical_identity']},
    frozen_source=report['frozen_source_identity'],mechanics=parent['source_identity'],policy=report['policy'],runner_sha256=report['runner_sha256'],godot_sha256=report['godot_sha256'],
    replay=replays,cold_commands=15,cold_exact_state_rng=True,cold_final_cycle=cold['final_run_cycle'],parent_relative_delta=delta,
    full_candidate_delta=report['variant']['delta'],control_canonical_identity=control_report['variant']['canonical_identity'],canonical_delta=report['variant']['canonical_delta'],
    raw_hashes={str(p):sha(p) for p in selected},warnings=warnings,script_sha256=sha(Path(__file__)))
with (study/'closeout.json').open('x',encoding='utf-8') as f:json.dump(out,f,indent=2);f.write('\n')
print(json.dumps({k:v for k,v in out.items() if k not in ['raw_hashes','full_candidate_delta','canonical_delta','warnings']},indent=2))
print('warnings',json.dumps(warnings))
