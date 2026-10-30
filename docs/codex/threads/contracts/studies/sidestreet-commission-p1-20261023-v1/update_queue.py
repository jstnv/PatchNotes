from pathlib import Path
import hashlib,json
H=Path(__file__).resolve().parent;R=H.parents[5];T=H.parents[1]
assert (T/'handoffs/sidestreet-p2-p3-20261023-v2/handoff-integrity.json').exists()
p=R/'docs/codex/TODO.md';before=p.read_bytes();s=before.decode('utf-8')
lines=s.splitlines(keepends=True)
matches=[x for x in lines if x.startswith('**2026-10-23 SideStreet P2 on completed P1 — DESIGN review needed;')]
assert len(matches)==1
old=matches[0];eol='\r\n' if old.endswith('\r\n') else '\n'
new='**2026-10-23 SideStreet P2/P3 — QUEUED gated implementation; bounded pilot APPROVED.** Follow the [approved adoption specification](threads/contracts/SIDESTREET-P2-P3-ADOPTION-2026-10-23-v2.md), [stable-window findings](threads/contracts/SIDESTREET-P2-P3-FINDINGS-2026-10-23-v2.md) and [sealed twelve-path v3 candidate](threads/contracts/handoffs/sidestreet-p2-p3-20261023-v2/HANDOFF.md). Reconcile the completed Continue-loading work; preserve other edits. Implement the separate two-hand Reputation Brief, frozen R20 commission quote, proportional fee, full-only R/I, ownership-aware sales/Finance, production transaction planning, named P1 player/world migration and native/exported acceptance. **Before activation, demonstrate a legal full-Scope/Review6 delivery, positive production +15R/+15I with caps/Continue, and a second commission completion.** Current fixed routes verify $5,199.60/$1,500/$0 settlements, coherent observers, strict saves, matched later sales and five exact fresh replays; none earns a full award. Keep the misses and approved terms. Existing cash Contracts remain intact; P4 support and broader tiers stay OPEN. Private evidence is not canonical implementation, final balance or activation.'+eol
changes=[dict(before=old,after=new)]
s=s.replace(old,new,1)
old2='P2–P4 remain OPEN. No other approved runnable implementation remains unstarted in this queue.'
new2='The bounded P2/P3 pilot is now approved and queued above; P4 and broader publisher scope remain OPEN.'
assert old2 in s;s=s.replace(old2,new2,1);changes.append(dict(before=old2,after=new2))
old3='- **DESIGN:** publisher P2–P4 progression and adoption handoffs (P1 dormant foundation is complete above);'
new3='- **DESIGN:** publisher P4 support and broader progression/tiers (P1 is complete; approved bounded P2/P3 implementation and its remaining full-delivery gate are queued above);'
assert old3 in s;s=s.replace(old3,new3,1);changes.append(dict(before=old3,after=new3))
assert p.read_bytes()==before,'TODO changed during narrow edit; reread before retry'
p.write_bytes(s.encode('utf-8'))
restored=s
for item in reversed(changes):restored=restored.replace(item['after'],item['before'],1)
assert restored.encode('utf-8')==before,'Unrelated TODO bytes changed'
with (H/'queue-edit.json').open('x',encoding='utf-8') as f:json.dump(dict(before_sha256=hashlib.sha256(before).hexdigest(),after_sha256=hashlib.sha256(p.read_bytes()).hexdigest(),changes=changes,unrelated_bytes_preserved=True),f,indent=2)
print('Queued approved bounded P2/P3 with full-delivery gate; unrelated TODO bytes preserved')
