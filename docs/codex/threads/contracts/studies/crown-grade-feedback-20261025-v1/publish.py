from pathlib import Path
import json,hashlib
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[5];THREAD=HERE.parents[1]
assert json.loads((HERE/'run-v1/summary.json').read_text())['status']=='PASS'
assert json.loads((HERE/'cap-reminder-v1.json').read_text())['status']=='PASS'
assert not (HERE/'publication.json').exists()
summary='**2026-10-25 Crown grade feedback and zero-earned history — design/evidence complete; presentation PROPOSED.** [Finding](CROWN-GRADE-FEEDBACK-FINDINGS-2026-10-25-v1.md):36 recorded projections/18 results match; current-card enumeration identifies all8 final zero cases, while7 positive first-hand score values later end at zero. [Design](CROWN-GRADE-FEEDBACK-DESIGN-2026-10-25-v1.md) recommends exact selected-card feedback, a final-hand-only current-card warning and a quiet consecutive-two reminder derived from trusted earned results; cap-clipped positive awards do not count, and proactive advice is suppressed at R100. Use “Brief complete” for completed hands with partial Work completion. [GF1–GF6 handoff / preview v3](CROWN-PREVIEW-HANDOFF-2026-10-25-v3.md) retains unchanged rewards and normal controls. Offline48 constructed cases/603 arithmetic checks pass; native purity, live history/restore, current-source integration, human comprehension and canonical activation remain gated. Earlier preview specifications remain historical where this proposal clarifies them.'
indexes={}
for name in ['README.md','HANDOFF.md']:
    p=THREAD/name;old=p.read_bytes();nl=b'\r\n' if b'\r\n' in old else b'\n';end=old.index(nl+nl)+len(nl+nl);addition=summary.encode()+nl+nl
    (HERE/(name+'.before')).write_bytes(old);assert p.read_bytes()==old;p.write_bytes(old[:end]+addition+old[end:]);assert p.read_bytes().replace(addition,b'',1)==old
    indexes[name]=dict(addition=addition.decode(),before_sha256=hashlib.sha256(old).hexdigest())
# Preserve the entire current Crown paragraph; append one bounded review update.
p=ROOT/'docs/codex/TODO.md';old=p.read_bytes();matches=[r for r in old.splitlines(keepends=True) if r.startswith(b'**Crown paid-Search Brief')];assert len(matches)==1
original=matches[0];nl=b'\r\n' if original.endswith(b'\r\n') else b'\n'
addition=' Latest [grade-feedback design and fixtures](threads/contracts/CROWN-GRADE-FEEDBACK-FINDINGS-2026-10-25-v1.md) and [preview v3 / GF1–GF6 handoff](threads/contracts/CROWN-PREVIEW-HANDOFF-2026-10-25-v3.md) propose exact provisional/final grade feedback, a current-card zero warning on the final hand only, and a quiet consecutive-two zero-earned reminder with cap/history safeguards.36 recorded projections/18 results,1,260 current-card evaluations,48 constructed cases and603 arithmetic checks pass offline. Rewards unchanged; presentation/reminder threshold, native query purity, live history/restore and canonical exposure still require review/acceptance.'
replacement=original[:-len(nl)]+addition.encode()+nl
(HERE/'TODO.before.md').write_bytes(old);assert p.read_bytes()==old;p.write_bytes(old.replace(original,replacement,1));assert p.read_bytes().replace(replacement,original,1)==old
record=dict(indexes=indexes,todo_original=original.decode(),todo_replacement=replacement.decode(),unrelated_todo_bytes_preserved=True,old_index_bodies_preserved=True)
(HERE/'publication.json').write_text(json.dumps(record,indent=2)+'\n',encoding='utf-8')
print('Updated thread summaries and only the existing Crown DESIGN paragraph; original bytes preserved.')
