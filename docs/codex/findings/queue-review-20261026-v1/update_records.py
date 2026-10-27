from pathlib import Path
out=Path(__file__).resolve().parent
root=out.parents[3]
def update(name,transform):
    p=root/'docs/codex'/name
    data=p.read_bytes();nl='\r\n' if b'\r\n' in data else '\n'
    text=data.decode().replace('\r\n','\n')
    p.write_bytes(transform(text).replace('\n',nl).encode())

entry='**2026-10-26 remaining-queue technical review / regression — COMPLETE at actionable scope.** No approved canonical gameplay implementation remains pending. Crown CP1/CP3 technical intake is complete; proposed terms/trust activation, employee Research accounting and AI full-supply/full-Scope policy retain their explicit design gates. Repaired the maintained Market fixture to enter visible Studio instead of opening behind first-run onboarding; no production-rule/UI change. A fresh unfunded canonical route passes209 commands/three releases/cycle119 with $19,822.42 and no arrears; independent replay verifies209 commands/210 telemetry samples. Research/shared-world/background-save checks,106 headless/106 native Market and64 headless/64 native Employee pointer checks pass. [Review, source, exact evidence and remaining gates](logs/2026-10-26-queue-review-v1.md). Human/device/inaccessible/deferred work remains open; EXE/ZIP unchanged.\n\n'
for name in ['TODO.md','CURRENT_STATE.md']:
    # Re-read each shared ledger immediately before the minimal prepend.
    update(name,lambda text:text.replace('\n\n','\n\n'+entry,1))

old='**Crown paid-work package — DESIGN review needed,2026-10-26; concrete terms proposed.**'
new='**Crown paid-work package — technical intake COMPLETE,2026-10-26; terms/activation DESIGN review still needed.** [Implementation-side source review](findings/queue-review-20261026-v1/REVIEW.md) confirms reusable CP1/CP3 arithmetic and CP4/CP5 trust/terms blockers; no numerical or catalog adoption. Concrete terms remain proposed.'
def crown(text):
    assert old in text
    return text.replace(old,new,1)
update('TODO.md',crown)

plan=root/'docs/codex/logs/2026-10-26-queue-review-plan-v1.md'
plan.write_bytes(plan.read_bytes().replace(b'- [ ]',b'- [x]'))
