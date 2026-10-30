from pathlib import Path
import json,hashlib,re,subprocess
H=Path(__file__).resolve().parent;R=H.parents[5];T=H.parents[1]
files=[T/'SIDESTREET-FULL-DELIVERY-FINDINGS-2026-10-23-v1.md',T/'SIDESTREET-P2-P3-ADOPTION-2026-10-23-v3.md',T/'SESSION-LOG-2026-10-23-sidestreet-full-delivery-v1.md',H/'PLAN.md',H/'FOLLOWUP-PLAN-v2.md',H/'READINESS-PLAN-v3.md']
errors=[];links=0;manifest={}
for p in files:
    s=p.read_text(encoding='utf-8');manifest[str(p.relative_to(T))]=hashlib.sha256(p.read_bytes()).hexdigest()
    for n,line in enumerate(s.splitlines(),1):
        if line.rstrip()!=line:errors.append(f'{p.name}:{n}: whitespace')
    for target in re.findall(r'\]\(([^)]+)\)',s):
        if '://' in target or target.startswith('#'):continue
        links+=1
        if not (p.parent/target.split('#')[0]).exists():errors.append(f'{p.name}: missing {target}')
q=json.loads((H/'queue-edit.json').read_text())
assert q['unrelated_bytes_preserved'] and hashlib.sha256((R/'docs/codex/TODO.md').read_bytes()).hexdigest()==q['after_sha256']
argv=['git','-c','core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol','diff','--check','--','docs/codex/TODO.md','docs/codex/threads/contracts/README.md','docs/codex/threads/contracts/HANDOFF.md']
p=subprocess.run(argv,cwd=R,capture_output=True,text=True)
if p.returncode:errors.append(p.stdout+p.stderr)
report=dict(files=len(files),links=links,errors=errors,document_hashes=manifest,queue_unrelated_bytes_preserved=True,diff_check=dict(argv=argv,exit=p.returncode,stdout=p.stdout,stderr=p.stderr))
with (H/'closeout.json').open('x',encoding='utf-8') as f:json.dump(report,f,indent=2)
print(json.dumps({k:v for k,v in report.items() if k!='document_hashes'},indent=2))
raise SystemExit(bool(errors))
