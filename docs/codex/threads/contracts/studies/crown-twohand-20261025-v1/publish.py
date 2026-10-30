from run import *
assert load(HERE/'closeout.json')['status']=='PASS'
assert not (HERE/'publication.json').exists()
finding='CROWN-TWOHAND-FINDINGS-2026-10-25-v1.md';handoff='CROWN-TWOHAND-HANDOFF-2026-10-25-v1.md'
records=[]
def change(path,old,new,label):
    assert old.count(new)==0,label
    before=path.read_bytes();assert old in before and before.count(old)==1,label
    backup=HERE/(label+'-before.md');assert not backup.exists();backup.write_bytes(before)
    after=before.replace(old,new,1)
    assert path.read_bytes()==before,'Concurrent change: '+str(path)
    path.write_bytes(after)
    assert path.read_bytes()==after
    records.append(dict(path=str(path.relative_to(ROOT)),before=hashlib.sha256(before).hexdigest(),after=sha(path),old=old.decode('utf-8'),new=new.decode('utf-8'),outside_exact=True))

summary=f'**2026-10-25 Crown CB2b two-hand planning — COMPLETE privately; DESIGN review.** [Findings]({finding}) and [handoff]({handoff}): six matched cases, 654 accepted commands; mean/downside planning earns 12.50R versus greedy 10R on both legal Action starts. Both planners produce identical trajectories, one zero each and no R20 in three Briefs; cash/calendar unchanged. 2,135 audit assertions, 52 paired checks, two exact replays and cold Studio Continue pass. Retain simpler expected-grade planner as proposed private comparator; no demonstrated downside benefit. Rewards unchanged; redraws PARKED. Next: planning presentation/specification review and existing Crown adoption gates. Numerical/activation approval, broader accessibility, migration/active-rival/atomic rejection/UI/export and human comprehension remain OPEN. Older next-test labels below are historical.'
for filename,label in [('README.md','thread-readme'),('HANDOFF.md','thread-handoff')]:
    path=THREAD/filename;before=path.read_bytes();nl=b'\r\n' if b'\r\n' in before[:200] else b'\n'
    end=before.index(nl)+len(nl);heading=before[:end]
    change(path,heading,heading+nl+summary.encode('utf-8')+nl,label)

# Re-read the shared TODO only at the final minimal replacement; preserve all other bytes.
path=ROOT/'docs/codex/TODO.md';before=path.read_bytes();lines=before.splitlines(keepends=True)
matches=[line for line in lines if line.startswith('**Crown progression —'.encode('utf-8'))]
assert len(matches)==1
old=matches[0];nl=b'\r\n' if old.endswith(b'\r\n') else b'\n'
new=f'**Crown progression — CB2b stronger two-hand planning COMPLETE privately; DESIGN review, 2026-10-25.** [Findings](threads/contracts/{finding}), [next acceptance tasks](threads/contracts/{handoff}), [prior runtime review packet](threads/contracts/handoffs/crown-brief-pilot-20261025-v3/HANDOFF.md). Six matched legal Action cases/18 Briefs/654 accepted commands: both planners earn 12.50R versus greedy 10R per start, with identical mean/downside trajectories, one zero each and no R20 in three opportunities. Cash/calendar/rewards unchanged; redraw work PARKED. Exact controls, 2,135 audit assertions, 52 paired checks, two exact replays and cold Studio Continue pass; three unchanged CB2 runtime suites reused, not rerun. Proposed: retain simpler expected-grade research comparator and review player-facing planning specification plus existing structural adoption gates. Crown numerical/activation approval, broader accessibility, migration/active-rival/atomic rejection/UI/export and commissions/support remain OPEN. No canonical implementation queued.'
change(path,old,new.encode('utf-8')+nl,'todo')
write(HERE/'publication.json',dict(status='PASS',records=records,shared_todo_scope='one Crown DESIGN paragraph only'))
print('Thread summaries and one Crown DESIGN TODO paragraph updated; other bytes preserved.')
