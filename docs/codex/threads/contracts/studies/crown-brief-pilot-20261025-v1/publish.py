from run import *
import re,ast
assert load(HERE/'seal-design-review-v3-exit.json')['exit_code']==0
packet=THREAD/'handoffs/crown-brief-pilot-20261025-v3/HANDOFF.md'
assert packet.exists()
receipt=[]
def update(path,transform):
    before=path.read_bytes();old=before.decode('utf-8-sig')
    after=transform(old).encode('utf-8')
    assert before!=after
    assert path.read_bytes()==before,'concurrent change; retry from new content'
    (HERE/(path.stem+'-before-publication.txt')).write_bytes(before)
    path.write_bytes(after)
    receipt.append(dict(path=str(path.relative_to(ROOT)),before=hashlib.sha256(before).hexdigest(),after=sha(path)))
notice='**2026-10-25 Crown Brief simulator pilot — COMPLETE bounded privately; DESIGN review.** [Findings](CROWN-BRIEF-PILOT-FINDINGS-2026-10-25-v1.md) and [handoff](CROWN-BRIEF-PILOT-HANDOFF-2026-10-25-v1.md): two freshly reproduced Action unlock states, ten matched policy runs,24Briefs; greedy balance earns10R each and no main arm reachesR20 in three opportunities. Separate targeted final-hand witnesses earn full10R and12.50R total, still belowR20. Rewards unchanged; Beta redraw work parked. Three maintained suites,696independent main/witness checks, four exact replays and cold Studio Continue pass. Next proposed work is two-hand planning; Crown approval, migration/UI/export and later deals remain OPEN. Earlier untested/pending-study labels below are historical.'
for name in ['README.md','HANDOFF.md']:
    def prepend(s):
        i=s.index('\n')+1
        nl='\r\n' if '\r\n' in s else '\n'
        return s[:i]+nl+notice+nl+s[i:]
    update(THREAD/name,prepend)
todo=ROOT/'docs/codex/TODO.md'
entry='**Crown progression — CB2 private Brief accessibility/pacing COMPLETE; DESIGN review,2026-10-25.** [Findings](threads/contracts/CROWN-BRIEF-PILOT-FINDINGS-2026-10-25-v1.md), [next acceptance tasks](threads/contracts/CROWN-BRIEF-PILOT-HANDOFF-2026-10-25-v1.md), [sealed source review packet](threads/contracts/handoffs/crown-brief-pilot-20261025-v1/HANDOFF.md). Legal Action4521/4522 prefixes preserve baseline outcomes/RNG; ten same-state branches/24Briefs show greedy balance10R each, noR20 in three opportunities. Separate targeted final-hand witnesses earn full10R and12.50R total. Six added productive cycles; equal-release cash gaps include sales/rent timing, not direct Brief fees. Three maintained suites,696main/witness assertions,four exact replays and cold Studio Continue pass. Rewards unchanged; Beta redraw work PARKED. Proposed next: bounded two-hand planning on these legal starts, without hidden draw reads or reward/redraw changes. Crown numerical/activation approval, named migration/active-rival/atomic rejection/UI/export acceptance and commissions/support remain OPEN; no canonical implementation queued. Preserve SideStreet ACTIVE/TRIAL authority and all original results.'
def replace_crown(s):
    global entry
    entry=entry.replace('handoffs/crown-brief-pilot-20261025-v1/','handoffs/crown-brief-pilot-20261025-v3/')
    matches=list(re.finditer(r'^\*\*Crown progression[^\r\n]*',s,re.M))
    assert len(matches)==1,'Crown paragraph ambiguous'
    m=matches[0];new=s[:m.start()]+entry+s[m.end():]
    assert new[:m.start()]==s[:m.start()] and new[m.start()+len(entry):]==s[m.end():]
    return new
update(todo,replace_crown)
links=[]
for name in ['CROWN-BRIEF-PILOT-FINDINGS-2026-10-25-v1.md','CROWN-BRIEF-PILOT-HANDOFF-2026-10-25-v1.md','SESSION-LOG-2026-10-25-crown-brief-pilot-v1.md']:
    p=THREAD/name
    for link in re.findall(r'\]\(([^)]+)\)',p.read_text()):
        if link.startswith(('https:','http:','#')):continue
        assert (p.parent/link.split('#')[0]).exists(),(name,link)
        links.append(link)
for p in HERE.glob('*.py'):ast.parse(p.read_text(encoding='utf-8-sig'))
r=subprocess.run(['git','diff','--check','--','docs/codex/TODO.md','docs/codex/threads/contracts/README.md','docs/codex/threads/contracts/HANDOFF.md'],cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace')
assert r.returncode==0,r.stdout+r.stderr
write(HERE/'publication.json',dict(status='PASS',files=receipt,links_checked=len(links),python_scripts_parsed=len(list(HERE.glob('*.py'))),diff_check_exit=r.returncode,only_todo_crown_paragraph_changed=True))
print(json.dumps(dict(status='PASS',shared_entries_changed=1,links_checked=len(links))))
