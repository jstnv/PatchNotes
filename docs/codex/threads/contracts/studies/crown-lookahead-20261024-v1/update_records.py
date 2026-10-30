from pathlib import Path
import hashlib,json,re
study=Path(__file__).resolve().parent
thread=study.parent.parent
todo=thread.parent.parent/'TODO.md'
sha=lambda b:hashlib.sha256(b).hexdigest()
entry='**Crown progression — CP1 study COMPLETE privately; broader DESIGN review needed, 2026-10-24.** [Current handoff](threads/contracts/CROWN-LOOKAHEAD-HANDOFF-2026-10-24-v1.md) and [unchanged-reward evidence](threads/contracts/CROWN-LOOKAHEAD-FINDINGS-2026-10-24-v1.md): conservative redraw reaches proposedR20 in three Briefs on both reachable seeds;19 redraws preserve or improve the best available grade.18 cases retained,12 complete/six shared pre-Crown affordability rejections; two exact replays/cold Continue pass. CP1b next: reconcile concurrent usability/priority/trait source, predeclare a broader legal-start cohort and compare conservative redraw against no-redraw while keeping rewards unchanged. CP2 reward changes are held; Crown commissions/support/activation remain OPEN pending explicit approval and their own evidence. SideStreet P2/P3/P4 remain complete at approved trial scope. This is DESIGN review, not a canonical gameplay queue.'
index='**2026-10-24 Crown lookahead/conservative redraw — private evidence complete; review handoff updated.** [Finding](CROWN-LOOKAHEAD-FINDINGS-2026-10-24-v1.md) and [CP1–CP4 status](CROWN-LOOKAHEAD-HANDOFF-2026-10-24-v1.md): conservative redraw reaches proposedR20 in three Briefs on both reachable seeds with unchanged rewards. Stronger first-hand planning alone does not improve totals;19 conservative redraws never reduce available grade.18 cases retained,12 complete/six pre-Crown rejections, two exact replays and cold Continue pass. Earlier no-access/pending-CP1 labels are superseded only at this cohort/source scope. Next review broadens current-source access; reward changes are held and Crown activation remains OPEN.'
receipts=[]
p=todo;old=p.read_bytes()
assert b'CROWN-LOOKAHEAD-HANDOFF-2026-10-24-v1.md' not in old
match=re.search(br'\*\*Crown progression[^\r\n]+',old)
assert match and b'CROWN-PLANNING-HANDOFF-2026-10-24-v1.md' in match.group()
replacement=entry.encode('utf-8');new=old[:match.start()]+replacement+old[match.end():]
assert p.read_bytes()==old,'concurrent TODO change; stop and reconcile'
p.write_bytes(new);actual=p.read_bytes();assert actual==new
assert actual[:match.start()]+match.group()+actual[match.start()+len(replacement):]==old
receipts.append({'path':str(p),'before_sha256':sha(old),'after_sha256':sha(new),'offset':match.start(),'old_text':match.group().decode('utf-8'),'new_text':entry,'all_unrelated_bytes_preserved':True})
for p in [thread/'README.md',thread/'HANDOFF.md']:
    old=p.read_bytes();assert b'CROWN-LOOKAHEAD-HANDOFF-2026-10-24-v1.md' not in old
    blank=re.search(br'(\r*\n)\r*\n',old);assert blank
    addition=index.encode('utf-8')+blank.group(1)*2;split=blank.end()
    new=old[:split]+addition+old[split:]
    assert p.read_bytes()==old,'concurrent owned index change'
    p.write_bytes(new);actual=p.read_bytes();assert actual==new
    assert actual[:split]+actual[split+len(addition):]==old
    receipts.append({'path':str(p),'before_sha256':sha(old),'after_sha256':sha(new),'offset':split,'old_text':'','new_text':addition.decode('utf-8'),'all_unrelated_bytes_preserved':True})
with (study/'record-update-receipt.json').open('x',encoding='utf-8') as f:json.dump(receipts,f,indent=2);f.write('\n')
print(json.dumps([{k:v for k,v in r.items() if k not in ['old_text','new_text']} for r in receipts],indent=2))
