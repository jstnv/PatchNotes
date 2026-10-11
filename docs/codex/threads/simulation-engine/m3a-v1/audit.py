from pathlib import Path
import collections,difflib,hashlib,json,subprocess,zipfile
ROOT=Path(__file__).resolve().parents[5]
HERE=Path(__file__).resolve().parent
RUNS=ROOT/'docs/codex/findings/card-presentation-v2'
PREFIX='m3a-accepted'
def read(p): return json.loads(p.read_text(encoding='utf-8'))
def save(name,value): (HERE/name).write_text(json.dumps(value,indent=2),encoding='utf-8')
checks=read(HERE/'check-results.json')
assert len(checks)==19 and all(row['passed'] for row in checks)
for row in checks:
    report=read(RUNS/row['label']/'command.json')
    assert report['exit']==0 and not report['errors'] and report['source_unchanged'] and report['drivers_unchanged']
launch=read(RUNS/(PREFIX+'-verify_launch_extraction')/'fit.json')
begin=read(RUNS/(PREFIX+'-verify_begin_project_extraction')/'fit.json')
assert len(launch)==9 and len(begin)==6
for row in launch+begin: assert row['original']==row['live']==row['headless']
campaign=read(RUNS/(PREFIX+'-verify_campaign_session')/'fit.json')
cli=read(RUNS/(PREFIX+'-cli')/'fit.json')
cli_command=read(RUNS/(PREFIX+'-cli')/'command.json')
assert cli==campaign['replay'] and cli['ok'] and len(cli['steps'])==81
assert cli_command['exit']==0 and not cli_command['errors'] and cli_command['source_unchanged']
assert campaign['reentry_checks']==55
old=read(HERE/'before-hashes.json')
assert hashlib.sha256((ROOT/'docs/codex/TODO.md').read_bytes()).hexdigest()==old['docs/codex/TODO.md']
assert hashlib.sha256((HERE/'gameplay_oracle.gd').read_bytes()).hexdigest()==old['patch-notes/scripts/gameplay.gd']
for name,digest in old.items():
    if name.startswith('patch-notes/data/'): assert hashlib.sha256((ROOT/name).read_bytes()).hexdigest()==digest
changed=[];patch=[]
with zipfile.ZipFile(HERE/'before-source.zip') as archive:
    for path in sorted((ROOT/'patch-notes/scripts').rglob('*.gd')):
        name=path.relative_to(ROOT).as_posix()
        before=archive.read(name).decode('utf-8').replace('\r\n','\n') if name in archive.namelist() else ''
        after=path.read_text(encoding='utf-8')
        if before!=after:
            changed.append(name)
            patch.extend(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile='before/'+name,tofile='after/'+name))
expected={'patch-notes/scripts/gameplay.gd','patch-notes/scripts/simulation/development_replay.gd','patch-notes/scripts/simulation/launch_settlement.gd','patch-notes/scripts/simulation/begin_project.gd','patch-notes/scripts/simulation/campaign_session.gd','patch-notes/scripts/debug/campaign_replay_cli.gd','patch-notes/scripts/debug/verify_launch_extraction.gd','patch-notes/scripts/debug/verify_begin_project_extraction.gd','patch-notes/scripts/debug/verify_campaign_session.gd'}
assert set(changed)==expected
head=subprocess.run(['git','rev-parse','HEAD'],cwd=ROOT,stdout=subprocess.PIPE,check=True).stdout.decode().strip()
assert head==(HERE/'head.txt').read_text().strip()
save('changed-scripts.json',changed)
(HERE/'turn.patch').write_text(''.join(patch),encoding='utf-8')
paths=list((ROOT/'patch-notes/scripts').rglob('*.gd'))+list((ROOT/'patch-notes/data').rglob('*.json'))
save('source-after.json',{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths})
(HERE/'status-after.txt').write_bytes(subprocess.run(['git','status','--short'],cwd=ROOT,stdout=subprocess.PIPE,check=True).stdout)
accepted=sum(row['accepted'] for row in cli['steps'])
result={'launch_original_live_headless_fixtures':9,'begin_original_live_headless_fixtures':6,'campaign_projects':3,'campaign_steps':81,'accepted':accepted,'rejected':81-accepted,'reentry_checks':55,'fresh_process_equal':True,'focused_suites':checks,'todo_unchanged':True,'data_unchanged':True,'head':head,'changed_scripts':changed}
save('acceptance.json',result)
save('results.json',[{'label':folder.name,'report':read(folder/'command.json')} for folder in sorted(RUNS.glob('m3a-*')) if (folder/'command.json').exists()])
print(json.dumps({k:v for k,v in result.items() if k not in ['focused_suites','changed_scripts']}))
