# Unexecuted partial-status draft; finish.py records the later production-time witness.
raise SystemExit('Superseded by finish.py; do not publish this intermediate draft')
from pathlib import Path
import json,hashlib
H=Path(__file__).resolve().parent;R=H.parents[5];T=H.parents[1]
def read(p):return json.loads(p.read_text())
def write(p,s):
    with p.open('x',encoding='utf-8',newline='\n') as f:f.write(s)
v=read(H/'verification.json');a=read(H/'analysis-complete-v3.json')
assert v['failures']==a['failures']==0
last=a['rows'][-1];rel='studies/sidestreet-full-delivery-20261023-v1'
table='| Commission | Scope | Review | Fee | Credited Reputation | Credited Investment |\n| --- | ---: | ---: | ---: | ---: | ---: |\n'
for i,d in enumerate(last['commissions'],1):
    table+=f"| {i} | {d['scope']}/{d['required']} | {int(d['review_tenths'])/10:.1f} | ${int(d['fee_cents'])/100:,.2f} | {int(d['credited_rep'])/100:.2f} | {int(d['credited_inv'])/100:.2f} |\n"
finding=f'''# SideStreet full-delivery gate — findings v1

2026-10-23, America/Los_Angeles. **PASS: legal full delivery, positive production Reputation/Investment, second completion, exact cold continuation and actual Reputation clipping. Investment clipping passes the focused ledger fixture; an end-to-end Investment-cap completion remains UNREACHED.** The broader activation gate is partially closed, not fully signed off. Canonical adoption, migration, native/exported UI and populated ownership acceptance remain pending.

## Authority and source

User authorized completing the remaining gate. [Approved bounded terms](SIDESTREET-P2-P3-TRIAL-APPROVAL-2026-10-23-v1.md) are unchanged. Branch `main`, HEAD `{v['head']}`; shared dirty checkout preserved. Baseline `42ef00919a6af975d5e779030583189b0077130de1ab416350c0cf202c158847`; unchanged private v3 candidate `{v['candidate_identity']}`; mechanics `439ae519201eb5f4b5d487edd407722cb7b9ee0df723db16455c9999ca52140a`. Closeout canonical identity `{v['canonical_identity']}`, no conflicting candidate path at verification. No gameplay code changed in this follow-up.

[Original plan]({rel}/PLAN.md) records hypothesis, cases, policies, Sports1112 seed, legal starting conditions, measurements and limits. First cases use the unchanged legally earned release4 Studio/RNG envelope: cycle42, cash$5,440.05, Reputation29.37, Investment0, no traits. No money, Features, cards, standing or RNG was injected. Normal Store commands and visible quotes determine purchases; all development uses the same Feature-first5/7/6 hand policy. Source/RNG compatibility and Studio-only Continue remain enforced.

## Root cause and full delivery

The previous owned playable Feature pool totaled **26 finite Scope**, all of which was played. Extra hands cannot regenerate exhausted Features. Sprites (Design, Scope2) and General Combat (Alpha, Scope2) supply the missing four; their parents were already owned. The experiment verifies actual played Scope separately from ownership.

Maps, Sprites and General Combat each cost **$450 and one productive research cycle** through ordinary admission/completion. Total preparation is **$1,350 / three cycles**, or **$900 / two cycles more than the Maps-only control**. Rent, earlier title settlements and affordability remained active; no discount or free grant was used.

| First case | Commands | Cycle | Scope | Review | Fee | New R/I |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Maps-only commissioned control | 33 | 62 | 26/30 | 6.4 | $5,199.60 | 0/0 |
| Expanded portfolio, commissioned | 35 | 64 | 30/30 | 7.8 | $6,000 | +15/+15 |
| Same expanded portfolio, self-owned | 34 | 64 | 30/30 | 7.8 | None | 0/0 |

The ownership pair matches exact initial state/RNG, production/review, raw launch sales, Fans and final RNG. Its cash/arrears difference equals the full fee. Portfolio versus Maps-only comparisons include different costs/calendar exposure and are not free-upgrade comparisons. The original miss is reproduced and retained.

Cold Continue into the **second commission** preserves the exact prior final state/RNG and completes at cycle83 in29 commands: **Scope30/30, Review8.6, another$6,000 and +15/+15**. Both completed sources persist; idempotent event retries change no fee, standing, state or RNG.

## Repeat history and stopped hypotheses

The planned five-more-commission case finishes at cycle178/release11 in149 commands. Commission6 misses at29/30 Scope and Review6.7. Its$5,799.60 fee and zero standing are correct. The original study stops at its declared seven commissions with **R100/I90**. The [original analysis]({rel}/analysis-complete.json) retains two unsupported route expectations: all seven full, and both caps reached. Its other84 checks pass.

The user-authorized gate investigation then records and announces a **separate one-case follow-up** before execution: [follow-up plan]({rel}/FOLLOWUP-PLAN-v2.md). It starts from the exact cycle178 Studio/RNG with the same policy, seed progression, portfolio and terms. It also misses: **Scope29/30, Review5.7, $5,100, no standing**, ending at cycle197 in31 commands. Its [two unsupported Investment-cap expectations]({rel}/analysis-complete-v2.json) remain retained. The follow-up's stop condition is honored: no further gameplay continuation was run.

{table}

Eight commissioned completions contain **six full deliveries and two misses**, with total fees **${sum(int(d['fee_cents']) for d in last['commissions'])/100:,.2f}**. Final standing is **Reputation100 / Investment90**; cash${last['cash_cents']/100:,.2f}, arrears$0. Reputation credits clip to10.63 on commission5 and0 on a later full delivery. Missed commissions never gain a retroactive award. Publisher-owned sales remain excluded from Studio entitlement.

**Important limit:** full portfolio ownership is not a guarantee of playing all Features within these finite hand limits. This study demonstrates one legal full route and its repetition, not universal accessibility or a balance recommendation. The Investment90-to100 production path was not reached under the declared policy and bounds.

## Verification and failures retained

- Six campaign cases in four separate bundles completed without command rejection or timeout. Original maxima:180 commands/first or second case,400/repeat case; separate follow-up180. Every process/import cap600seconds; at most two concurrent processes and a10GiB free-space floor. No source-capture retry was used.
- **Four fresh-process exact replays** pass: first full delivery35 commands, second29, repeat history149 and follow-up31. Each verifies telemetry as well as final state/RNG. All three cold continuation boundaries equal the preceding exact final state/RNG.
- Completed-save audits reconstruct every actual grade, fee receipt, source event, clipped credit and publisher entitlement; retries are exact no-ops, and altered/duplicate/missing award history rejects. First full delivery additionally passes37 strict corruption/source checks and13 publication/duplicate-launch checks.
- Focused P1 ledger checks verify **both independent caps and zero credit at cap using constructed trusted fixture sources**. These fixtures are explicitly rejected by the production resolver. This verifies cap arithmetic/storage, not a legal Investment100 campaign.
- [Final actual-grade analysis]({rel}/analysis-complete-v3.json): {len(a['checks'])} checks, zero invariant failures; prior failed route hypotheses are carried forward separately. [Final evidence/source verification]({rel}/verification.json): {len(v['checks'])} checks, zero failures, with the remaining Investment-cap boundary explicitly recorded.
- The initial new audit had a **type-inference parse error** and executed no assertions. Original `gate_audit.gd`/`first-audit/gate.log` remain; v2 adds an explicit Dictionary annotation. Later audit revisions check actual proportional results rather than assuming every delivery is full. All prior versions remain. No failed gameplay command existed to reduce. Godot cleanup warnings remain; leak-free teardown is not claimed.

## Reproduction and evidence

Python executable: `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`. Helpers live under `{rel}/`.

- `run.py first`, `second`, `caps`, `recovery` retain exact `tools/simulate.py run --variant ... --config ... --output ... --godot ... --timeout 600` commands and outputs in their `*.command.json` files. First/second/caps are the original study; recovery is the explicit separate follow-up.
- `checks.py first audit` (retained parse failure; other jobs pass), `first auditfixed`, `second audit`, `caps audit`, `recovery audit`: isolated focused processes against frozen source. `caps audit` includes the maintained P1 ledger verifier.
- `checks.py first replay`, `second replay`, `caps replay`, `recovery replay`: full fresh-process replay commands retained in the stage replay folders.
- `analyze.py first`, `analyze.py complete`, `analyze_v2.py complete`, `analyze_v3.py complete`, `verify.py`: original hypotheses, follow-up hypotheses, final actual-grade invariants and source/seal checks retained separately.

Reports: [first](sims/sidestreet-full-delivery-first-20261023-v1/run-report.json), [second](sims/sidestreet-full-delivery-second-20261023-v1/run-report.json), [repeat](sims/sidestreet-full-delivery-caps-20261023-v1/run-report.json), [follow-up](sims/sidestreet-full-delivery-recovery-20261023-v1/run-report.json). Retain complete frozen bundles, tapes, profiles and manifests. [Execution record]({rel}/EXECUTION.md).

## Recommendation and remaining gate

Hand off the proven full/repeat route and the [v3 adoption addendum](SIDESTREET-P2-P3-ADOPTION-2026-10-23-v3.md). Keep all approved terms. The original full-delivery/positive-award/second-completion gap is closed at private scope. **Do not mark end-to-end Investment clipping verified:** it remains a specific canonical acceptance item, alongside existing transaction hardening, named migration, native/exported UI and populated ownership checks. Broader accessibility, balance and P4 support remain OPEN.
'''
write(T/'SIDESTREET-FULL-DELIVERY-FINDINGS-2026-10-23-v1.md',finding)
addendum='''# SideStreet P2/P3 adoption addendum — v3

2026-10-23. **APPROVED bounded scope; HANDED OFF. Full delivery and repeat completion verified privately; overall activation acceptance still PARTIAL.**

## Exact delta and authority

No new gameplay delta or value change. Use the original twelve-path [sealed v2 packet](handoffs/sidestreet-p2-p3-20261023-v2/HANDOFF.md), candidate `0d7276b32153e9184f25c4cacaa75e520a3119988af64262068741b245cb2567`, with the [approved terms](SIDESTREET-P2-P3-TRIAL-APPROVAL-2026-10-23-v1.md). This addendum updates evidence for Gate0 in [v2 adoption](SIDESTREET-P2-P3-ADOPTION-2026-10-23-v2.md). All tasks A–E remain applicable. Reconcile current source; never replace canonical code wholesale with the archived project.

## Status and acceptance

- **Implemented and verified privately:** legally earned Sports1112 release4 R29.37; research Maps, Sprites and General Combat for$450/one productive cycle each; ordinary Sports/Fantasy preparation; frozen Scope30/Review6/$6,000 quote. Visible Feature-first5/7/6 policy delivers30/30, Review7.8, exact$6,000/+15R/+15I. Cold Continue into a second full delivery (Review8.6), source history, idempotence, actual Reputation clipping and four exact replays pass.
- **Implemented and verified privately, fixture-only:** P1 ledger independent Reputation/Investment clipping, no-op retries and zero credits at cap. Fixture events cannot enter production. These checks do not prove an actual Investment100 campaign.
- **Still OPEN acceptance:** legal production Investment90-to100 clipping. The bounded seven-commission study and separate one-case follow-up both stop as planned; two29/30 misses leave R100/I90. Keep both misses and their proper proportional fees/zero standing. Do not rerun seeds or change contract terms merely to erase them.
- **Approved and handed off:** reproduce the full/repeat route on reconciled canonical source, regenerating legal prefixes if mechanics compatibility changes; retain source/RNG fences. Finish Investment-cap production acceptance, production transaction planning, named P1 player/world migration, visible Brief/quote/result/Finance flows, populated Studio/Founder ownership, real disk Continue and exported acceptance from v2 tasks A–E.
- **Proposed/Open:** Scope-readiness guidance may help players distinguish owned supply from actual played Scope. The researched trio is one demonstrated route, not a new prerequisite. No price, score, payout, hand-limit or balance change is authorized by these findings. P4 and broader tiers remain OPEN.

## Matching evidence

[Findings](SIDESTREET-FULL-DELIVERY-FINDINGS-2026-10-23-v1.md), [original plan](studies/sidestreet-full-delivery-20261023-v1/PLAN.md), [explicit follow-up](studies/sidestreet-full-delivery-20261023-v1/FOLLOWUP-PLAN-v2.md), [actual-grade analysis](studies/sidestreet-full-delivery-20261023-v1/analysis-complete-v3.json), [verification/hashes](studies/sidestreet-full-delivery-20261023-v1/verification.json). Original failed hypotheses, audit failure and sealed packet remain intact. No canonical activation, commit, push or chat dispatch occurred.
'''
write(T/'SIDESTREET-P2-P3-ADOPTION-2026-10-23-v3.md',addendum)
log=f'''# Contracts full-delivery follow-up session

2026-10-23, America/Los_Angeles. Branch main, HEAD `{v['head']}`; shared dirty worktree and `.codex-godot-temp` preserved. Canonical identity `{v['canonical_identity']}`. Private candidate remains `{v['candidate_identity']}`. No gameplay source change, canonical tests/assets/configuration edit, commit, push or chat dispatch.

Read current state/TODO, local workflow, simulator usage/variants, publisher authority and relevant prior findings/source. User authorized the remaining gate. [Plan]({rel}/PLAN.md), [separate follow-up plan]({rel}/FOLLOWUP-PLAN-v2.md), [findings](SIDESTREET-FULL-DELIVERY-FINDINGS-2026-10-23-v1.md) and [v3 handoff](SIDESTREET-P2-P3-ADOPTION-2026-10-23-v3.md) record exact commands, actual outcomes and bounds.

Changed: new study scripts/plans/configs/audits/results; four isolated run bundles containing six cases, four fresh replay bundles; versioned findings/adoption; thread README/HANDOFF and this log; one minimal TODO paragraph. The queue receipt proves unrelated bytes preserved. Existing sealed artifacts and earlier misses remain.

PASS: first legal30/30 Scope Review7.8 full$6,000/+15R/+15I; cold second full completion Review8.6; source/receipt/history/rights/observer/retry checks; actual Reputation clipping; both cap formulas in an explicitly constructed P1 fixture; four exact replays. Analysis {len(a['checks'])}/0 invariant failures; final verification {len(v['checks'])}/0 failures. Source-neutral audit parse failure and corrected harnesses retained.

UNSUPPORTED: all seven original commissions fully delivering, both caps reached in that study, and the separate follow-up reaching Investment100. Eight total completions contain six full and two misses; final R100/I90. Both stop conditions honored; no further gameplay extension. Final finding separates unsupported hypotheses from correct fee/ledger invariants. Cleanup warnings retained.

Remaining acceptance: actual production Investment-cap witness; canonical reconciliation, production transaction hardening, named migration, native/exported UI, populated ownership and human comprehension. No blocker to preparing the approved foundation; do not claim its full activation gate closed. No balance adjustment is proposed.
'''
write(T/'SESSION-LOG-2026-10-23-sidestreet-full-delivery-v1.md',log)
for filename,paragraph in [
('README.md','**2026-10-23 SideStreet full/repeat delivery PASS; activation gate PARTIAL.** [Findings](SIDESTREET-FULL-DELIVERY-FINDINGS-2026-10-23-v1.md) and [adoption v3](SIDESTREET-P2-P3-ADOPTION-2026-10-23-v3.md) prove legal 30/30 Scope, Review 7.8, $6,000/+15R/+15I and a second full completion. Eight retained completions include two misses; actual Reputation caps at100, Investment ends90. Both cap formulas pass focused fixtures; end-to-end Investment clipping remains open. Four fresh replays pass. Candidate code/values are unchanged. Canonical migration/UI/export/ownership acceptance and P4 remain open.'),
('HANDOFF.md','## 2026-10-23 full/repeat delivery evidence\n\n**Implemented and verified privately:** legal full delivery, positive R/I, cold second completion, actual Reputation clipping and four fresh replays. **Fixture-only:** Investment cap arithmetic. **OPEN acceptance:** end-to-end Investment clipping, plus existing canonical migration/native/export/ownership tasks. [v3 adoption addendum](SIDESTREET-P2-P3-ADOPTION-2026-10-23-v3.md) updates the original sealed candidate without changing code or terms. Retain both bounded-study misses; overall activation acceptance remains partial.')]:
    p=T/filename;s=p.read_text(encoding='utf-8');pos=s.index('\n')+1
    p.write_text(s[:pos]+'\n'+paragraph+'\n'+s[pos:],encoding='utf-8')
p=R/'docs/codex/TODO.md';before=p.read_bytes();s=before.decode('utf-8')
matches=[x for x in s.splitlines(keepends=True) if x.startswith('**2026-10-23 SideStreet P2/P3 —')]
assert len(matches)==1,'Review concurrent queue change'
old=matches[0];needle='**Before activation, demonstrate a legal full-Scope/Review6 delivery, positive production +15R/+15I with caps/Continue, and a second commission completion.**'
assert needle in old,'Review changed gate wording before editing'
new=old.replace(needle,'**Private full-delivery/positive-award/second-completion evidence now PASS:** [v3 adoption addendum](threads/contracts/SIDESTREET-P2-P3-ADOPTION-2026-10-23-v3.md) and [new findings](threads/contracts/SIDESTREET-FULL-DELIVERY-FINDINGS-2026-10-23-v1.md) show legal 30/30 Scope, Review 7.8, $6,000/+15R/+15I, cold repeat completion, actual Reputation clipping and four fresh replays. Both cap formulas pass focused fixtures; **production Investment-cap clipping remains unproven (R100/I90 after two retained misses)**. Reproduce adopted-source full/repeat evidence and finish that boundary plus existing migration/native/export/ownership acceptance before activation.',1)
new=new.replace('Current fixed routes verify','Earlier fixed routes verify',1).replace('none earns a full award.','those earlier routes earned no full award; the new legal portfolio now proves full delivery.',1)
assert p.read_bytes()==before,'TODO changed during narrow edit'
after=s.replace(old,new,1).encode('utf-8')
assert after.decode('utf-8').replace(new,old,1).encode('utf-8')==before
p.write_bytes(after)
write(H/'queue-edit.json',json.dumps(dict(before_sha256=hashlib.sha256(before).hexdigest(),after_sha256=hashlib.sha256(after).hexdigest(),before=old,after=new,unrelated_bytes_preserved=True),indent=2))
print('Documented full/repeat proof and remaining production Investment-cap boundary; unrelated TODO bytes preserved.')
