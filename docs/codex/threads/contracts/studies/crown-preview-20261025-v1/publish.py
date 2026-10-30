from pathlib import Path
import hashlib,json
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[5];THREAD=HERE.parents[1]
load=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def write(name,value):(HERE/name).write_text(json.dumps(value,indent=2)+'\n',encoding='utf-8')
design='CROWN-PREVIEW-DESIGN-2026-10-25-v1.md';findings='CROWN-PREVIEW-FINDINGS-2026-10-25-v1.md';handoff='CROWN-PREVIEW-HANDOFF-2026-10-25-v1.md'
assert load(HERE/'evidence.json')['status']=='PASS'
assert not (HERE/'publication.json').exists()
import hashlib
receipts=[]
def replace(path,old,new,label):
    before=path.read_bytes();assert before.count(old)==1
    backup=HERE/(label+'-before.md');assert not backup.exists();backup.write_bytes(before)
    after=before.replace(old,new,1);assert path.read_bytes()==before,'Concurrent edit: '+str(path)
    path.write_bytes(after);assert path.read_bytes()==after
    receipts.append(dict(path=str(path.relative_to(ROOT)),before=hashlib.sha256(before).hexdigest(),after=sha(path),old=old.decode(),new=new.decode(),backup=backup.name))
summary=f'**2026-10-25 Crown selected-hand preview — specification drafted; PROPOSED.** [Design]({design}), [source/evidence]({findings}) and [review handoff]({handoff}). Recommend current→selected scores, separate completion/balance and limiting-factor explanation, provisional hand-1 value, exact conditional final award and requested/credited cap distinction. Twelve archived legal selections and eight constructed display examples checked; 16 assertions, no new campaigns or UI implementation. One recorded interim +5.00 ends at zero, so the estimate is never banked standing. Rewards unchanged; redraw research parked. Crown numerical/activation approval, structural acceptance and human comprehension remain OPEN. This supersedes the earlier “preview specification next” label, not prior simulator findings.'
for name,label in [('README.md','readme'),('HANDOFF.md','handoff')]:
    path=THREAD/name;before=path.read_bytes();nl=b'\r\n' if b'\r\n' in before[:200] else b'\n';heading=before[:before.index(nl)+len(nl)]
    replace(path,heading,heading+nl+summary.encode()+nl,label)
# Standing user authorization permits a minimal DESIGN review update, not a QUEUED implementation entry.
path=ROOT/'docs/codex/TODO.md';before=path.read_bytes()
old=b'Proposed: retain simpler expected-grade research comparator and review player-facing planning specification plus existing structural adoption gates.'
new=f'Proposed: retain simpler expected-grade research comparator. [Selected-hand preview specification](threads/contracts/{design}) and [acceptance handoff](threads/contracts/{handoff}) are drafted for DESIGN review: provisional hand-1 value, exact final award, completion/balance explanation and cap distinction; 12 archived selections/eight constructed examples checked, no new campaigns or UI implementation. Existing structural adoption gates remain required.'.encode()
replace(path,old,new,'todo')
write('publication.json',dict(status='PASS',records=receipts,shared_scope='One sentence inside existing Crown DESIGN paragraph; no implementation queue'))
print('Thread summaries and Crown DESIGN reference updated; unrelated bytes preserved.')
