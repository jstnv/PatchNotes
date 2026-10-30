from pathlib import Path
import hashlib,json,re,subprocess
H=Path(__file__).resolve().parent; R=H.parents[5]; T=H.parents[1]
files=[T/'SIDESTREET-P2-P3-TRIAL-APPROVAL-2026-10-23-v1.md',T/'SIDESTREET-P2-P3-FINDINGS-2026-10-23-v2.md',T/'SIDESTREET-P2-P3-ADOPTION-2026-10-23-v2.md',T/'SESSION-LOG-2026-10-23-sidestreet-p2-p3-v1.md',H/'PLAN.md']
errors=[]; links=0
for p in files:
    s=p.read_text(encoding='utf-8')
    for n,line in enumerate(s.splitlines(),1):
        if line.rstrip()!=line:errors.append(f'{p.name}:{n}: trailing whitespace')
    for target in re.findall(r'\]\(([^)]+)\)',s):
        if '://' in target or target.startswith('#'):continue
        links+=1
        if not (p.parent/target.split('#')[0]).exists():errors.append(f'{p.name}: missing {target}')
q=json.loads((H/'queue-edit.json').read_text())
assert q['unrelated_bytes_preserved']
assert hashlib.sha256((R/'docs/codex/TODO.md').read_bytes()).hexdigest()==q['after_sha256'],'TODO changed since queue edit; inspect new owner edits'
verification=json.loads((H/'verification-complete.json').read_text())
assert verification['failures']==0
argv=['git','-c','core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol','diff','--check','--','docs/codex/TODO.md','docs/codex/threads/contracts/README.md','docs/codex/threads/contracts/HANDOFF.md']
p=subprocess.run(argv,cwd=R,capture_output=True,text=True)
if p.returncode:errors.append(p.stdout+p.stderr)
report=dict(files_checked=len(files),relative_links_checked=links,errors=errors,verification_checks=len(verification['checks']),verification_failures=verification['failures'],queue_unrelated_bytes_preserved=True,queue_sha256=q['after_sha256'],git_diff_check=dict(argv=argv,exit=p.returncode,stdout=p.stdout,stderr=p.stderr))
with (H/'closeout.json').open('x',encoding='utf-8') as f:json.dump(report,f,indent=2)
print(json.dumps(report,indent=2))
raise SystemExit(bool(errors))
