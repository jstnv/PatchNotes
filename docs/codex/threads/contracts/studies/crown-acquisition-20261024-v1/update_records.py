from setup import HERE, ROOT, write
import json, re, hashlib
sha=lambda b:hashlib.sha256(b).hexdigest()

def main():
    a=json.loads((HERE/'analysis.json').read_text());v=json.loads((HERE/'verification.json').read_text())
    assert a['complete'] and len(a['rows'])==12 and v['cold_state_match'] and v['cold_rng_match']
    thread=HERE.parents[1];receipt=[]
    assert (thread/'CROWN-ACQUISITION-FINDINGS-2026-10-24-v1.md').exists()
    note='**2026-10-24 Crown affordable acquisition — CA1 COMPLETE bounded privately.** [Findings](CROWN-ACQUISITION-FINDINGS-2026-10-24-v1.md) and [proposed handoff](CROWN-ACQUISITION-HANDOFF-2026-10-24-v1.md):12/12 cases finish six releases with no rejected commands or observed arrears. Existing Primitive reserve purchases raise Crown access2/6→4/6, but delay Action4522 by15 cycles and reduce its cash. All purchase routes own potential Scope30; only10/36 games play full Scope. Next test one additional legal affordable Feature-bearing hand per Design/Alpha when completion is short, then separately test purchases aimed at weak Cores. Both remain proposed DESIGN work. Exact replay/cold state/RNG, source and telemetry checks pass. Keep Review7/rewards unchanged; Crown relationship activation/migration remain OPEN, with no canonical/default-AI adoption. Older next-question labels below are historical.'
    for name in ['README.md','HANDOFF.md']:
        p=thread/name;before=p.read_bytes();assert note.encode() not in before
        match=re.match(br'^#[^\r\n]*(\r*\n)\r*\n',before);assert match
        nl=match.group(1);insert=note.encode()+nl+nl;at=match.end();after=before[:at]+insert+before[at:]
        assert after[:at]+after[at+len(insert):]==before
        assert p.read_bytes()==before,'Concurrent owned-index edit'
        p.write_bytes(after);assert p.read_bytes()==after
        receipt.append({'path':str(p.relative_to(ROOT)),'before':sha(before),'after':sha(after),'unrelated_bytes_preserved':True})
    # Read the shared document immediately before a single-paragraph CAS edit.
    p=ROOT/'docs/codex/TODO.md';before=p.read_bytes()
    matches=list(re.finditer(br'(?m)^\*\*Crown progression[^\n]*',before));assert len(matches)==1
    match=matches[0];prior=match.group();ending=prior[len(prior.rstrip(b'\r')):]
    text='**Crown progression — CA1 COMPLETE bounded privately; owned-Feature utilization and selective acquisition DESIGN review needed,2026-10-24.** [12-case findings](threads/contracts/CROWN-ACQUISITION-FINDINGS-2026-10-24-v1.md) and [proposed tasks/acceptance](threads/contracts/CROWN-ACQUISITION-HANDOFF-2026-10-24-v1.md):all cases finish six releases; legal Primitive reserve purchases raise Crown access2/6→4/6 with no observed arrears, but delay Action4522 by15 cycles and reduce cash. All six purchase routes own Scope30; only10/36 games play full Scope. Next test at most one additional legal affordable Feature-bearing hand per Design/Alpha when completion is short, then separately evaluate weak-Core purchases. Keep Review7 and rewards unchanged; do not mandate shopping or adopt the policy as default AI. Source/telemetry,193-command exact replay and Studio-only cold state/RNG checks pass. [CP1c/earlier access evidence](threads/contracts/CROWN-ACCESS-FINDINGS-2026-10-24-v1.md) remains historical. Crown relationship terms/activation and predecessor migration stay OPEN; CP2 rewards remain held. SideStreet P2/P3/P4 retain accepted trial scope; no canonical implementation queued here.'
    replacement=text.encode()+ending;after=before[:match.start()]+replacement+before[match.end():]
    assert after[:match.start()]+prior+after[match.start()+len(replacement):]==before
    (HERE/'todo-entry-before.txt').write_bytes(prior)
    assert p.read_bytes()==before,'Concurrent TODO edit; stopped before write'
    p.write_bytes(after);assert p.read_bytes()==after
    receipt.append({'path':'docs/codex/TODO.md','before':sha(before),'after':sha(after),'changed_entries':1,'unrelated_bytes_preserved':True})
    with (HERE/'documentation-update.json').open('x',encoding='utf-8') as f:json.dump(receipt,f,indent=2)
    print('Updated two owned indexes and one Crown TODO paragraph; unrelated bytes preserved')

if __name__=='__main__':main()
