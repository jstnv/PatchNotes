from pathlib import Path
import hashlib,json,re,subprocess
study=Path(__file__).resolve().parent
thread=study.parent.parent
sha=lambda b:hashlib.sha256(b).hexdigest()
checks=[]
files=[thread/n for n in ['CROWN-LOOKAHEAD-PLAN-2026-10-24-v1.md','CROWN-LOOKAHEAD-FINDINGS-2026-10-24-v1.md','CROWN-LOOKAHEAD-HANDOFF-2026-10-24-v1.md','SESSION-LOG-2026-10-24-crown-lookahead-v1.md']]+[study/'COMMANDS.md',study/'CAPTURE-RETRY.md']
for p in files:
    text=p.read_text(encoding='utf-8')
    for target in re.findall(r'\]\(([^)]+)\)',text):
        if target.startswith(('http:','https:')):continue
        assert (p.parent/target.split('#')[0]).exists(),(p,target)
        checks.append('link '+p.name+' '+target)
    assert all(line==line.rstrip() for line in text.splitlines()),p
    checks.append('new document whitespace '+p.name)
for p in study.glob('*.json'):
    json.loads(p.read_text(encoding='utf-8'));checks.append('json '+p.name)
for r in json.loads((study/'record-update-receipt.json').read_text()):
    p=Path(r['path']);b=p.read_bytes();assert sha(b)==r['after_sha256'],p
    old=r['old_text'].encode('utf-8');new=r['new_text'].encode('utf-8');offset=r['offset']
    assert b[offset:offset+len(new)]==new
    restored=b[:offset]+old+b[offset+len(new):]
    assert sha(restored)==r['before_sha256'],p
    checks.append('inverse replacement preserves all unrelated bytes '+p.name)
args=['git','-c','core.safecrlf=false','-c','core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol','diff','--check','--','docs/codex/TODO.md','docs/codex/threads/contracts/README.md','docs/codex/threads/contracts/HANDOFF.md']
proc=subprocess.run(args,capture_output=True)
manifest=json.loads((study/'candidate-canonical-source-manifest.json').read_text())
changes=[]
for rel,digest in manifest.items():
    p=Path('patch-notes')/rel
    if not p.exists() or sha(p.read_bytes())!=digest:changes.append(rel)
out={'status':'PASS' if proc.returncode==0 else 'WHITESPACE_REVIEW_NEEDED','checks':len(checks),'details':checks,'diff_check_argv':args,'diff_check_exit':proc.returncode,'diff_check_output':(proc.stdout+proc.stderr).decode('utf-8',errors='replace'),'canonical_manifest_changed_paths_since_candidate_capture':changes,'document_hashes':{str(p):sha(p.read_bytes()) for p in files}}
with (study/'document-verification.json').open('x',encoding='utf-8') as f:json.dump(out,f,indent=2);f.write('\n')
print(json.dumps({k:v for k,v in out.items() if k not in ['details','document_hashes']},indent=2))
assert proc.returncode==0
