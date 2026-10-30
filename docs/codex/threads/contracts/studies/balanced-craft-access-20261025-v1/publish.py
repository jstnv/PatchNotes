from run import *
import re
assert not (HERE/'publication.json').exists()
summary='**2026-10-25 Balanced Craft terms APPROVED; new-roster access baseline complete.** [User approval](BALANCED-CRAFT-APPROVAL-2026-10-25-v1.md) retains the exact two-hand Scope9/Core4/spread2 up-to10R pilot, zero other rewards. [32-case finding](BALANCED-CRAFT-ACCESS-FINDINGS-2026-10-25-v1.md): all four-release routes finish, no Crown unlock under the restricted short policies, zero overdue;16 paired states/RNG,32 roster checks,two replays and cold Continue pass. [Next handoff](BALANCED-CRAFT-ACCESS-HANDOFF-2026-10-25-v1.md): Search still queued/absent; stronger legal access prefixes and accepted Search source needed for actual paid-search Brief affordability. Earlier pending numerical approval labels are superseded; player-exposure gates and other publisher terms remain open. Rewards unchanged, redraws parked.'
for name in ['README.md','HANDOFF.md']:
    p=THREAD/name;before=p.read_bytes();(HERE/(name+'.before')).write_bytes(before)
    nl=b'\r\n' if b'\r\n' in before[:200] else b'\n';i=before.index(nl+nl)+2*len(nl)
    extra=summary.encode()+nl+nl
    assert p.read_bytes()==before
    p.write_bytes(before[:i]+extra+before[i:])
    assert p.read_bytes()[:i]+p.read_bytes()[i+len(extra):]==before
todo=ROOT/'docs/codex/TODO.md'
# Read immediately before the narrow shared edit and stop on concurrent change.
before=todo.read_bytes();(HERE/'TODO.md.before').write_bytes(before)
marker=b'**Searchable publisher catalog and post-search pacing'
assert before.count(marker)==1
nl=b'\r\n' if b'\r\n' in before[:200] else b'\n'
start=before.index(marker);end=before.index(nl+nl,start)
paragraph='**Searchable publisher catalog and post-search pacing — Crown Brief terms APPROVED for bounded pilot; research follow-up, 2026-10-25.** [User approval](threads/contracts/BALANCED-CRAFT-APPROVAL-2026-10-25-v1.md) retains the [exact two-hand Scope9/Core4/spread2 terms](threads/contracts/BALANCED-CRAFT-PILOT-TERMS-2026-10-25-v1.md), up-to10R formula and zero cash/advance/Promotion/Investment. [Current-roster baseline](threads/contracts/BALANCED-CRAFT-ACCESS-FINDINGS-2026-10-25-v1.md):32 cases/four releases each, all16 initial state/RNG pairs and32 roster-v3 checks pass; no Crown unlock under restricted short policies, no overdue; two replays and cold Continue pass. This is not paid-search Brief affordability or optimal-access proof. [Follow-up handoff](threads/contracts/BALANCED-CRAFT-ACCESS-HANDOFF-2026-10-25-v1.md): develop legal quality-oriented new-roster access prefixes, then run the approved private Brief study after accepted Search source; preserve source/RNG fences and structural/native/export adoption gates. Search remains its separate queued implementation; no reward tuning or redraw research. Earlier pending Brief numerical approval is superseded. [Crown catalog](threads/contracts/CROWN-SEARCH-CATALOG-DESIGN-2026-10-25-v1.md), compact cash/commission gates and amounts, other publisher tiers and [preview acceptance](threads/contracts/CROWN-PREVIEW-HANDOFF-2026-10-25-v1.md) remain separately OPEN; [catalog workplan](threads/contracts/PUBLISHER-CATALOG-WORKPLAN-2026-10-25-v1.md) retained. No canonical Crown implementation claimed or duplicate Search queue.'
new=paragraph.encode()
assert todo.read_bytes()==before,'Concurrent TODO edit: reconcile'
todo.write_bytes(before[:start]+new+before[end:])
assert todo.read_bytes()[:start]==before[:start] and todo.read_bytes()[start+len(new):]==before[end:]
missing=[]
for p in [*THREAD.glob('BALANCED-CRAFT-ACCESS-*-2026-10-25-v1.md'),THREAD/'BALANCED-CRAFT-APPROVAL-2026-10-25-v1.md',THREAD/'SESSION-2026-10-25-BALANCED-CRAFT-ACCESS-v1.md']:
    for target in re.findall(r'\]\(([^)]+)\)',p.read_text(encoding='utf-8')):
        if '://' in target:continue
        q=(p.parent/target.split('#')[0]).resolve()
        if q!=HERE/'publication.json' and not q.exists():missing.append(str(q))
assert not missing,missing
cmd=['git','-c','core.whitespace=cr-at-eol','diff','--check','--','docs/codex/TODO.md','docs/codex/threads/contracts/README.md','docs/codex/threads/contracts/HANDOFF.md']
r=subprocess.run(cmd,cwd=ROOT,capture_output=True,text=True)
assert r.returncode==0,r.stdout+r.stderr
receipt=dict(todo_outside_paragraph='PASS: byte-exact',thread_prior_content='PASS: byte-exact',links='PASS',diff_check='PASS',
    todo_before_sha256=hashlib.sha256(before).hexdigest(),todo_after_sha256=hashlib.sha256(todo.read_bytes()).hexdigest(),command=cmd)
write(HERE/'publication.json',receipt);print(json.dumps(receipt,indent=2))
