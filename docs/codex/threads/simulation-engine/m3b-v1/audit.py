from pathlib import Path
import difflib,hashlib,json,subprocess,zipfile
ROOT=Path(__file__).resolve().parents[5]
HERE=Path(__file__).resolve().parent
RUNS=ROOT/'docs/codex/findings/card-presentation-v2'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def save(name,v):(HERE/name).write_text(json.dumps(v,indent=2),encoding='utf-8')
checks=read(HERE/'m3b-accepted-checks.json')
assert len(checks)==28
checks.append({'suite':'verify_contract_presentation','evidence':'docs/codex/findings/card-presentation-v2/m3b-accepted-contract-presentation'})
for row in checks:
    report=read(ROOT/row['evidence']/'command.json')
    assert report['exit']==0 and not report['errors'] and report['source_unchanged'] and report['drivers_unchanged'],row
contract=read(RUNS/'m3b-accepted-contract-extraction/fit.json')
campaign=read(RUNS/'m3b-accepted-campaign-continuation/fit.json')
assert contract['failures']==0 and contract['comparisons']==52 and len(contract['cases'])==10
assert campaign['failures']==0 and campaign['continuation_replay']['ok'] and campaign['financial_comparisons']==9
fresh=[r for r in checks if r['suite']=='fresh_checkpoint_replay']
assert len(fresh)==6
assert read(ROOT/fresh[-1]['evidence']/'fit.json')==campaign['continuation_replay']
old=read(HERE/'before-hashes.json')
assert hashlib.sha256((ROOT/'docs/codex/TODO.md').read_bytes()).hexdigest()==old['docs/codex/TODO.md']
for name,digest in old.items():
    if name.startswith('patch-notes/data/'):assert hashlib.sha256((ROOT/name).read_bytes()).hexdigest()==digest
changed=[];patch=[]
with zipfile.ZipFile(HERE/'before-source.zip') as archive:
    original=archive.read('patch-notes/scripts/phases/contract_phase.gd').decode('utf-8').replace('\r\n','\n')
    assert (HERE/'contract_phase_oracle.gd').read_text(encoding='utf-8')==original.split('\n',1)[1]
    for path in sorted((ROOT/'patch-notes/scripts').rglob('*.gd')):
        name=path.relative_to(ROOT).as_posix()
        before=archive.read(name).decode('utf-8').replace('\r\n','\n') if name in archive.namelist() else ''
        after=path.read_text(encoding='utf-8')
        if before!=after:
            changed.append(name)
            patch.extend(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile='before/'+name,tofile='after/'+name))
expected={'patch-notes/scripts/'+p for p in ['run_state.gd','phases/contract_phase.gd',
 'simulation/contract_session.gd','simulation/studio_actions.gd','simulation/campaign_session.gd',
 'debug/campaign_replay_cli.gd','debug/verify_contract_extraction.gd','debug/verify_campaign_continuation.gd']}
assert set(changed)==expected,changed
head=subprocess.run(['git','rev-parse','HEAD'],cwd=ROOT,stdout=subprocess.PIPE,check=True).stdout.decode().strip()
assert head==(HERE/'head.txt').read_text().strip()
save('changed-scripts.json',changed)
(HERE/'turn.patch').write_text(''.join(patch),encoding='utf-8')
paths=list((ROOT/'patch-notes/scripts').rglob('*.gd'))+list((ROOT/'patch-notes/data').rglob('*.json'))+list(HERE.glob('*.py'))+[HERE/'contract_phase_oracle.gd']
save('source-after.json',{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths})
(HERE/'status-after.txt').write_bytes(subprocess.run(['git','status','--short'],cwd=ROOT,stdout=subprocess.PIPE,check=True).stdout)
result={'head':head,'contract_fixtures':10,'original_live_headless_comparisons':52,
 'campaign_prefix_steps':campaign['prefix_steps'],'campaign_suffix_steps':campaign['suffix_steps'],
 'financial_comparisons':9,'reentrant_checks':campaign['reentrant_checks'],
 'fresh_checkpoint_processes':6,'fresh_checkpoint_steps':sum(row['steps'] for row in fresh),
 'focused_verifications':len(checks),'todo_unchanged':True,'data_unchanged':True,'changed_scripts':changed,'checks':checks}
save('acceptance.json',result)
save('results.json',[{'label':folder.name,'report':read(folder/'command.json')} for folder in sorted(RUNS.glob('m3b-*')) if (folder/'command.json').exists()])
print(json.dumps({k:v for k,v in result.items() if k not in ['changed_scripts','checks']}))
