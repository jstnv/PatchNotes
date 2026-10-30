from run import *
import re,ast
receipt=[]
for name in ['README.md','HANDOFF.md']:
    p=THREAD/name;before=(HERE/(p.stem+'-before-publication.txt')).read_bytes();current=p.read_bytes()
    i=before.index(b'\n')+1
    nl=b'\r\n' if b'\r\n' in before else b'\n'
    assert current.startswith(before[:i]+nl)
    end=current.index(nl,i+len(nl))
    inserted=current[i+len(nl):end]
    assert inserted.startswith(b'**2026-10-25 Crown Brief simulator pilot')
    assert current[end+len(nl):]==before[i:],'another edit detected; preserve and re-read'
    fixed=before[:i]+nl+inserted+nl+before[i:]
    assert p.read_bytes()==current
    p.write_bytes(fixed)
    receipt.append(dict(path=str(p.relative_to(ROOT)),before=hashlib.sha256(before).hexdigest(),after=sha(p),outside_insert_bytes_preserved=True))
p=ROOT/'docs/codex/TODO.md';before=(HERE/'TODO-before-publication.txt').read_bytes();current=p.read_bytes()
pattern=rb'^\*\*Crown progression[^\r\n]*'
old=re.search(pattern,before,re.M);new=re.search(pattern,current,re.M)
assert old and new
assert before[:old.start()]==current[:new.start()] and before[old.end():]==current[new.end():]
receipt.append(dict(path=str(p.relative_to(ROOT)),before=hashlib.sha256(before).hexdigest(),after=sha(p),outside_crown_paragraph_bytes_preserved=True))
links=[]
for name in ['CROWN-BRIEF-PILOT-FINDINGS-2026-10-25-v1.md','CROWN-BRIEF-PILOT-HANDOFF-2026-10-25-v1.md','SESSION-LOG-2026-10-25-crown-brief-pilot-v1.md']:
    p=THREAD/name
    for link in re.findall(r'\]\(([^)]+)\)',p.read_text(encoding='utf-8')):
        if link.startswith(('https:','http:','#')):continue
        assert (p.parent/link.split('#')[0]).exists(),(name,link)
        links.append(link)
for p in HERE.glob('*.py'):ast.parse(p.read_text(encoding='utf-8-sig'))
r=subprocess.run(['git','-c','core.whitespace=cr-at-eol','diff','--check','--','docs/codex/TODO.md','docs/codex/threads/contracts/README.md','docs/codex/threads/contracts/HANDOFF.md'],cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace')
(HERE/'publication-diff-check.log').write_text(r.stdout+r.stderr,encoding='utf-8')
assert r.returncode==0,r.stdout+r.stderr
write(HERE/'publication.json',dict(status='PASS',files=receipt,links_checked=len(links),python_scripts_parsed=len(list(HERE.glob('*.py'))),diff_check_exit=r.returncode,diff_check_cr_at_eol=True,only_todo_crown_paragraph_changed=True,sealed_packet='handoffs/crown-brief-pilot-20261025-v3'))
print(json.dumps(dict(status='PASS',shared_entries_changed=1,links_checked=len(links),diff_check_exit=0)))
