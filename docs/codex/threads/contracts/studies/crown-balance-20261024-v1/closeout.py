from pathlib import Path
import hashlib,json,re,shutil

study=Path(__file__).resolve().parent
raw=Path('C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-balance-20261024-v1')
load=lambda p:json.loads(p.read_text(encoding='utf-8'))
checks=0
def check(value,reason):
    global checks
    assert value,reason
    checks+=1
def sha(p):
    h=hashlib.sha256()
    with p.open('rb') as f:
        for chunk in iter(lambda:f.read(1024*1024),b''): h.update(chunk)
    return h.hexdigest()
report=load(raw/'candidate-v1/run-report.json')
cases={p.parent.name:load(p) for p in (raw/'candidate-v1/cases').glob('*/result.json')}
check(len(cases)==12,'retained case count')
check(sum(r['ok'] for r in cases.values())==8,'eight completed, four failed prefix cases')
replays={}
for label in ['balanced-4417','naive-4417']:
    r=load(raw/f'replay-{label}/replay-report.json')
    check(r['ok'] and len(r['steps'])==130 and r['final_state']==cases[label]['final_state'],label+' exact replay')
    check(all(x['accepted'] for x in r['steps']),label+' accepted replay')
    replays[label]={'steps':len(r['steps']),'final_state':r['final_state']}
    shutil.copyfile(raw/f'replay-{label}/replay-report.json',study/f'replay-{label}.json')
parent=cases['balanced-4417']; cold=load(raw/'cold-balanced-4417/cases/cold-balanced-4417/result.json')
check(cold['ok'] and cold['commands']==15 and cold['final_release_count']==7,'cold continuation')
check(cold['initial_state']==parent['final_state'] and cold['initial_rng']==parent['final_rng'],'whole Studio boundary and RNG exact')
decode=lambda xs:{x['key']:x['value'] for x in xs}
old=load(raw/'candidate-v1/cases/balanced-4417/studio_checkpoint.json')['studio_payload']['run']
new=load(raw/'cold-balanced-4417/cases/cold-balanced-4417/studio_checkpoint.json')['studio_payload']['run']
check(old['crown_briefs']==new['crown_briefs'],'pending and completed Briefs persist without backlog')
check(old['publisher_relationships']==new['publisher_relationships'],'standing source history persists unchanged')
for label,r in cases.items():
    if not r['ok']: continue
    cp=load(raw/f'candidate-v1/cases/{label}/studio_checkpoint.json')['studio_payload']['run']
    check('starwave' not in decode(cp['unlocked_publishers']),label+' Briefs not legacy Contract unlocks')
    check(cp['commission_deals']==[] and cp['support_deals']==[],label+' no new game deals')
warnings=[]
for dirname in ['baseline','candidate-v1','replay-balanced-4417','replay-naive-4417','cold-balanced-4417']:
    for p in (raw/dirname).glob('*.log'):
        lines=[x for x in p.read_text(encoding='utf-8',errors='replace').splitlines() if re.search(r'SCRIPT ERROR|ERROR:|WARNING:',x)]
        if lines: warnings.append({'path':str(p),'lines':lines})
for variant in ['crown-balance-base-v1','crown-balance-brief-v1']:
    root=study.parent.parent/'simulators'/variant
    integrity=load(root/'integrity.json')
    for name,digest in integrity.items(): check(sha(root/name)==digest,variant+' immutable '+name)
for change in load(study/'candidate-build.json'):
    candidate=study.parent.parent/'simulators/crown-balance-brief-v1/project'/change['path']
    check(sha(candidate)==change['after'],'candidate file unchanged '+change['path'])
selected=[raw/'baseline/run-report.json',raw/'candidate-v1/run-report.json',raw/'candidate-v1/workspace-source-manifest.json',raw/'candidate-v1/snapshot-manifest.json',raw/'candidate-v1/experiment.command.json',raw/'cold-balanced-4417/run-report.json']
for label in cases:
    selected.append(raw/f'candidate-v1/cases/{label}/result.json')
hashes={str(p):sha(p) for p in selected}
shutil.copyfile(raw/'candidate-v1/run-report.json',study/'candidate-run-report.json')
shutil.copyfile(raw/'baseline/run-report.json',study/'baseline-run-report.json')
shutil.copyfile(raw/'cold-balanced-4417/run-report.json',study/'cold-run-report.json')
out=dict(status='PASS',scope='structural/replay closeout; R20 design aim missed and four prefix rejections retained',checks=checks,
         base_identity=report['variant']['base_identity'],candidate_identity=report['variant']['candidate_identity'],
         frozen_source=report['frozen_source_identity'],mechanics=parent['source_identity'],
         runner_sha256=report['runner_sha256'],godot_sha256=report['godot_sha256'],
         replay=replays,cold_commands=15,cold_initial_state=cold['initial_state'],cold_final_state=cold['final_state'],
         cold_exact_state_rng=True,raw_hashes=hashes,warnings=warnings,
         candidate_delta=report['variant']['delta'],script_sha256=sha(Path(__file__)))
with (study/'closeout.json').open('x',encoding='utf-8') as f: json.dump(out,f,indent=2); f.write('\n')
print(json.dumps({k:v for k,v in out.items() if k not in ['raw_hashes','candidate_delta','warnings']},indent=2))
print('diagnostics',json.dumps(warnings)[:1800])
