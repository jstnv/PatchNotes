from run import *
import re
receipts=load(HERE/'publication.json')
for r in receipts['records']:
    path=ROOT/r['path'];current=path.read_bytes()
    assert sha(path)==r['after'],path
    old=r['old'].encode();new=r['new'].encode();backup=next(p for p in HERE.glob('*-before.md') if sha(p)==r['before'])
    assert current.replace(new,old,1)==backup.read_bytes(),path
docs=[THREAD/'CROWN-TWOHAND-FINDINGS-2026-10-25-v1.md',THREAD/'CROWN-TWOHAND-HANDOFF-2026-10-25-v1.md',THREAD/'SESSION-LOG-2026-10-25-crown-twohand-v1.md']
links=0
for p in docs:
    content=p.read_text(encoding='utf-8')
    for target in re.findall(r'\]\(([^)]+)\)',content):
        if '://' not in target:
            assert (p.parent/target.split('#')[0]).exists(),(p,target);links+=1
    assert all(line==line.rstrip() for line in content.splitlines()),p
result=subprocess.run(['git','-c','core.whitespace=cr-at-eol','diff','--check','--','docs/codex/TODO.md','docs/codex/threads/contracts/README.md','docs/codex/threads/contracts/HANDOFF.md'],cwd=ROOT,capture_output=True,text=True)
assert result.returncode==0,result.stdout+result.stderr
for name,digest in load(HERE/'policy-pins.json').items():assert sha(HERE/name)==digest
write(HERE/'final-verification.json',dict(status='PASS',links=links,shared_other_bytes_preserved=True,policy_inputs_unchanged=True,scoped_diff_check=result.returncode,docs={p.name:sha(p) for p in docs},head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()))
print('PASS: publication scope, links, source policy pins and scoped diff check.')
