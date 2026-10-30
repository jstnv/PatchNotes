"""Minimal authorized TODO and owned-index inserts, preserving prior bytes."""
from pathlib import Path
import hashlib,json,re
study=Path(__file__).resolve().parent
thread=study.parent.parent
todo=thread.parent.parent/'TODO.md'
sha=lambda b:hashlib.sha256(b).hexdigest()
entry='**Crown progression — DESIGN review needed, 2026-10-24.** [CP1–CP4 review handoff](threads/contracts/CROWN-PLANNING-HANDOFF-2026-10-24-v1.md) and [completed planning/redraw evidence](threads/contracts/CROWN-PLANNING-FINDINGS-2026-10-24-v1.md):15 cases retained,10 complete/five shared pre-Crown affordability rejections; no R20 in three Briefs. First compare a conservative redraw that preserves the best four visible cards against the controls; only then review completion-plus-balance standing if needed. Exact policies, legal-start/state/RNG gates, bounds and acceptance are in the handoff. SideStreet P2/P3/P4 remain complete at approved trial scope. Crown terms/commissions/support and canonical adoption remain OPEN and held for explicit approval; this queues DESIGN review, not gameplay activation.'
index='**2026-10-24 Crown planning/redraw — evidence complete; DESIGN review handed off through TODO.** [Finding](CROWN-PLANNING-FINDINGS-2026-10-24-v1.md) and [CP1–CP4 handoff](CROWN-PLANNING-HANDOFF-2026-10-24-v1.md): retained-card forecasting leaves standing totals unchanged; aggressive bounded redraw helps one reachable seed and harms the other, with no R20 in three Briefs. Next test preserves the best four cards before reviewing rewards. Ten completed/five pre-Crown rejected cases, two exact replays and cold Studio Continue retained. Canonical-at-capture matches the original baseline; earlier intermediate-source concern requires no rebase for this comparison. Crown rules remain OPEN; older “no TODO entry” labels are superseded only for review routing.'
receipts=[]
for p,text in [(todo,entry),(thread/'README.md',index),(thread/'HANDOFF.md',index)]:
    old=p.read_bytes()
    assert b'CROWN-PLANNING-HANDOFF-2026-10-24-v1.md' not in old, 'avoid duplicate/concurrent insertion'
    blank=re.search(br'(\r*\n)\r*\n',old)
    assert blank is not None,'expected heading and blank line'
    newline=blank.group(1)
    split=blank.end()
    addition=text.encode('utf-8')+newline+newline
    new=old[:split]+addition+old[split:]
    assert p.read_bytes()==old,'concurrent update: stop and reconcile'
    p.write_bytes(new)
    actual=p.read_bytes()
    assert actual==new and actual[:split]+actual[split+len(addition):]==old
    receipts.append({'path':str(p),'before_sha256':sha(old),'after_sha256':sha(actual),'insertion_offset':split,'inserted_bytes':len(addition),'all_prior_bytes_preserved':True})
with (study/'queue-update-receipt.json').open('x',encoding='utf-8') as f:json.dump(receipts,f,indent=2);f.write('\n')
print(json.dumps(receipts,indent=2))
