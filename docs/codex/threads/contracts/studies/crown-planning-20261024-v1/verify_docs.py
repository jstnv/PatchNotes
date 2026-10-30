from pathlib import Path
import hashlib,json,re,subprocess
study=Path(__file__).resolve().parent
thread=study.parent.parent
repo=Path.cwd()
sha=lambda b:hashlib.sha256(b).hexdigest()
checks=[]
files=[thread/x for x in ['CROWN-PLANNING-PLAN-2026-10-24-v1.md','CROWN-PLANNING-FINDINGS-2026-10-24-v1.md','CROWN-PLANNING-HANDOFF-2026-10-24-v1.md','SESSION-LOG-2026-10-24-crown-planning-v1.md']]+[study/'COMMANDS.md']
for p in files:
    text=p.read_text(encoding='utf-8')
    for target in re.findall(r'\]\(([^)]+)\)',text):
        if target.startswith(('http:', 'https:')):continue
        target=target.split('#')[0]
        assert (p.parent/target).exists(),(p,target)
        checks.append('link '+str(p.name)+' '+target)
    assert all(line==line.rstrip() for line in text.splitlines()),p
for p in study.glob('*.json'):json.loads(p.read_text(encoding='utf-8'));checks.append('json '+p.name)
for r in json.loads((study/'queue-update-receipt.json').read_text()):
    p=Path(r['path']);b=p.read_bytes();assert sha(b)==r['after_sha256'],p
    restored=b[:r['insertion_offset']]+b[r['insertion_offset']+r['inserted_bytes']:]
    assert sha(restored)==r['before_sha256'],p
    checks.append('all original bytes preserved '+p.name)
args=['git','-c','core.safecrlf=false','-c','core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol','diff','--check','--','docs/codex/TODO.md','docs/codex/threads/contracts/README.md','docs/codex/threads/contracts/HANDOFF.md']
proc=subprocess.run(args,capture_output=True)
source=json.loads((study/'candidate-canonical-source-manifest.json').read_text())
drift=[]
for rel,digest in source.items():
    p=repo/'patch-notes'/rel
    if not p.exists() or sha(p.read_bytes())!=digest:drift.append(rel)
out={'status':'PASS' if proc.returncode==0 else 'WHITESPACE_REVIEW_NEEDED','checks':len(checks),'checks_detail':checks,'diff_check_argv':args,'diff_check_exit':proc.returncode,'diff_check_output':(proc.stdout+proc.stderr).decode('utf-8',errors='replace'),'canonical_manifest_changes_since_capture':drift,'document_hashes':{str(p):sha(p.read_bytes()) for p in files}}
with (study/'document-verification.json').open('x',encoding='utf-8') as f:json.dump(out,f,indent=2);f.write('\n')
print(json.dumps({k:v for k,v in out.items() if k not in ['checks_detail','document_hashes']},indent=2))
assert proc.returncode==0,'inspect preserved-existing whitespace diagnostics'
