from setup import HERE, ROOT, write
import json, re, hashlib
sha=lambda b:hashlib.sha256(b).hexdigest()

def main():
    a=json.loads((HERE/'analysis.json').read_text());v=json.loads((HERE/'verification.json').read_text());s=json.loads((HERE/'summary.json').read_text())
    assert a['complete'] and len(a['rows'])==12 and v['cold_state_match'] and v['cold_rng_match']
    assert all(r['ok'] and r['commands']==r['accepted_commands'] and r['arrears_max']==0 for r in a['rows'])
    thread=HERE.parents[1];receipt=[]
    assert (thread/'CROWN-EXTRA-HAND-FINDINGS-2026-10-24-v1.md').exists()
    c=s['arms']['control'];x=s['arms']['extra']
    results=f"12/12 source-pinned cases finish six releases; {s['extra_hand_accepted']} extra hands are legal, with no rejected commands or observed arrears. Crown access {c['crown_unlocks']}/6→{x['crown_unlocks']}/6; full-Scope releases {c['full_scope_releases']}/36→{x['full_scope_releases']}/36. Action4522 reaches Crown11 cycles sooner, but Action4521 takes3 cycles longer and loses cash; Puzzle4521 and Simulation4522 still miss."
    boundary='Next separately test visible-information Beta playtesting/QA for Simulation (full Scope/production7.142 but6 Bugs despite0 known at exit) and Core-aware purchases against the original Puzzle control (Sound9/13). Predeclare each policy; keep the interventions separate and regenerate legal starts after a source audit. Keep Review7/rewards unchanged; no universal extra-hand/default-AI adoption. Exact control reproduction, replay and Studio-only cold state/RNG pass; the two-runner .ico exception and concurrent canonical drift are documented. Crown relationship terms/activation/migration stay OPEN; CP2 rewards held and SideStreet P2/P3/P4 retain accepted trial scope. No canonical implementation queued.'
    note='**2026-10-24 Crown extra-hand utilization — CA1b COMPLETE bounded privately.** [Findings](CROWN-EXTRA-HAND-FINDINGS-2026-10-24-v1.md) and [proposed handoff](CROWN-EXTRA-HAND-HANDOFF-2026-10-24-v1.md): '+results+' '+boundary+' Older next-question labels below are historical.'
    for name in ['README.md','HANDOFF.md']:
        p=thread/name;before=p.read_bytes();assert note.encode() not in before
        match=re.match(br'^#[^\r\n]*(\r*\n)\r*\n',before);assert match
        nl=match.group(1);insert=note.encode()+nl+nl;at=match.end();after=before[:at]+insert+before[at:]
        assert after[:at]+after[at+len(insert):]==before
        assert p.read_bytes()==before,'Concurrent owned-index edit'
        p.write_bytes(after);assert p.read_bytes()==after
        receipt.append({'path':str(p.relative_to(ROOT)),'before':sha(before),'after':sha(after),'unrelated_bytes_preserved':True})
    # Immediate shared-document reread, unique paragraph match, compare before write.
    p=ROOT/'docs/codex/TODO.md';before=p.read_bytes()
    matches=list(re.finditer(br'(?m)^\*\*Crown progression[^\n]*',before));assert len(matches)==1
    match=matches[0];prior=match.group();ending=prior[len(prior.rstrip(b'\r')):]
    text='**Crown progression — CA1b COMPLETE bounded privately; separate QA/Core-acquisition DESIGN review needed,2026-10-24.** [12-case extra-hand findings](threads/contracts/CROWN-EXTRA-HAND-FINDINGS-2026-10-24-v1.md) and [proposed tasks/acceptance](threads/contracts/CROWN-EXTRA-HAND-HANDOFF-2026-10-24-v1.md): '+results+' '+boundary+' [CA1 acquisition evidence](threads/contracts/CROWN-ACQUISITION-FINDINGS-2026-10-24-v1.md) remains the control reference.'
    replacement=text.encode()+ending;after=before[:match.start()]+replacement+before[match.end():]
    assert after[:match.start()]+prior+after[match.start()+len(replacement):]==before
    (HERE/'todo-entry-before.txt').write_bytes(prior)
    assert p.read_bytes()==before,'Concurrent TODO edit; stopped before write'
    p.write_bytes(after);assert p.read_bytes()==after
    receipt.append({'path':'docs/codex/TODO.md','before':sha(before),'after':sha(after),'changed_entries':1,'unrelated_bytes_preserved':True})
    with (HERE/'documentation-update.json').open('x',encoding='utf-8') as f:json.dump(receipt,f,indent=2)
    print('Updated two owned indexes and one Crown TODO paragraph; unrelated bytes preserved')

if __name__=='__main__':main()
