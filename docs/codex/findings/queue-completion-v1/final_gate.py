from pathlib import Path
import hashlib,json,sys
BASE=Path(__file__).resolve().parent
REPO=BASE.parents[3]
sys.path.insert(0,str(REPO/'docs/codex/findings/checkpoint-runtime-v1'))
import run_checks as r
r.HERE=BASE/'final-gate';r.HERE.mkdir(exist_ok=True)
paths=[p for base in ['scripts','scenes','data'] for p in (r.PROJECT/base).rglob('*') if p.is_file()]
(r.HERE/'source.json').write_text(json.dumps({str(p.relative_to(r.PROJECT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in paths},indent=2))
records=[]
for path in sorted((r.PROJECT/'scripts/debug').glob('verify_*.gd')):
 r.run(path.stem,['--script','res://scripts/debug/'+path.name])
 records.append(json.loads((r.HERE/(path.stem+'.command.json')).read_text()))
 (r.HERE/'gate.json').write_text(json.dumps(records,indent=2))
print('PASS',len(records),'suites',flush=True)
