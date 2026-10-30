from pathlib import Path
import hashlib, json, re, subprocess
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[5]
THREAD=HERE.parents[1]
def read(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
checks=[]
def check(value,label):
    checks.append({'pass':bool(value),'check':label})
analysis=read(HERE/'analysis.json')
check(analysis['failures']==0 and len(analysis['checks'])==948,'948 analysis checks pass')
check(len(analysis['rows'])==72 and len({r['case'] for r in analysis['rows']})==72,'72 unique fixed recipes')
check(sum(r['accepted'] for r in analysis['rows'])==6696,'6696 accepted commands in final candidate records')
for name,digest in read(HERE/'input-hashes.json').items(): check(sha(HERE/name)==digest,'unchanged pre-result input '+name)
records=read(HERE/'replay-results.json');check(len(records)==3,'three representative fresh replays')
replay_summary=[]
for record in records:
    report=read(Path(record['output'])/'run-report.json')
    result=read(Path(record['bundle'])/'cases'/record['case']/'result.json')
    check(record['exit']==0 and report['ok'] and report['replay']['ok'],record['case']+' replay PASS')
    check(report['replay']['final_state']==result['final_state'],record['case']+' exact final state')
    check(len(report['replay']['steps'])==result['commands'],record['case']+' all recorded steps replayed')
    check(report['replay']['telemetry_verified'],record['case']+' telemetry verified')
    replay_summary.append({'case':record['case'],'steps':len(report['replay']['steps']),'telemetry_samples':report['replay']['telemetry_samples'],'final_state':report['replay']['final_state'],'bundle':record['bundle'],'output':record['output']})
docs=[THREAD/'SIDESTREET-ACCESSIBILITY-AND-PACING-FINDINGS-2026-10-23-v1.md',THREAD/'SIDESTREET-REPUTATION-BRIEF-RECOMMENDATION-2026-10-23-v1.md',THREAD/'SESSION-LOG-2026-10-23-sidestreet-access-v1.md',HERE/'ADOPTION-NOTES.md',HERE/'PLAN.md',HERE/'SETUP-RETRY-AMENDMENT.md',HERE/'TIMEOUT-COVERAGE-AMENDMENT.md']
for doc in docs:
    content=doc.read_text(encoding='utf-8')
    check(not any(line.rstrip()!=line for line in content.splitlines()),doc.name+' no trailing whitespace')
    for link in re.findall(r'\]\(([^)]+)\)',content):
        if '://' not in link and not link.startswith('#'):
            check((doc.parent/link.split('#')[0]).exists(),doc.name+' link '+link)
    if doc.name.startswith('SIDESTREET-'): check('pending' not in content.lower().split('\n\n')[1],doc.name+' closed research header')
verification={'checks':checks,'failures':sum(not c['pass'] for c in checks),'replays':replay_summary,'analysis_checks':len(analysis['checks'])}
(HERE/'verification.json').write_text(json.dumps(verification,indent=2),encoding='utf-8')
if verification['failures']:
    print(json.dumps([c for c in checks if not c['pass']],indent=2));raise SystemExit(1)
files=set(docs)
files.update(p for p in HERE.iterdir() if p.is_file() and p.name not in ['evidence-index.json','git-after.json'])
coverage=read(HERE/'coverage.json')
bundles={Path(folder) for folders in coverage.values() for folder in folders}
bundles.update(Path(r['output']) for r in records)
bundles.update(THREAD/'sims'/name for name in ['sidestreet-access-balanced-20261023-v1','sidestreet-access-completion-20261023-v1','sidestreet-access-canonical-20261023-v1'])
for folder in bundles:
    files.update(p for p in folder.iterdir() if p.is_file() and p.suffix in ['.json','.log'])
    for result in (folder/'cases').glob('*/result.json'):
        files.update(p for p in result.parent.iterdir() if p.is_file() and p.suffix=='.json')
index={p.relative_to(ROOT).as_posix():sha(p) for p in sorted(files)}
(HERE/'evidence-index.json').write_text(json.dumps({'files':index,'scope':'Closed research inputs, documents, process reports, complete case artifacts and retained failure logs; source archives/manifests remain in their original variants/bundles.'},indent=2),encoding='utf-8')
git={k:subprocess.check_output(['git',*args],cwd=ROOT,text=True) for k,args in {'branch':['branch','--show-current'],'head':['rev-parse','HEAD'],'status':['status','--porcelain']}.items()}
(HERE/'git-after.json').write_text(json.dumps(git,indent=2),encoding='utf-8')
print(json.dumps({'checks':len(checks),'failures':0,'sealed_files':len(index),'replayed_steps':sum(r['steps'] for r in replay_summary),'head':git['head'].strip()},indent=2))
