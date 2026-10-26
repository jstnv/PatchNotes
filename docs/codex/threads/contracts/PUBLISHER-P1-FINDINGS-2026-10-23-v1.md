# P1 publisher relationship foundation findings

2026-10-23. **Private prototype verified at the bounded scope below; canonical adoption and representation policy remain PROPOSED.** [Specification](PUBLISHER-P1-FOUNDATION-SPEC-2026-10-23-v1.md), [predeclared plan and amendments](studies/publisher-p1-20261023-v1/PLAN.md).

## Question and result

Can dormant per-Studio/per-publisher relationship storage preserve existing gameplay, reject invented awards, and migrate existing saves without loss? **Yes for the recorded two legal campaigns, pure ledger fixtures and named native predecessor/world.** No Reputation or Investment award producer is enabled. The code resolves all proposed award requests to rejection until a separately approved producer supplies verifiable committed facts.

The foundation stores ordered typed events and derives separate balances for the five current publishers. It validates owner, kind/source/event identity, order, credit arithmetic and cycle. Future event resolution must work from both live RunState and decoded checkpoint facts. The 0..10000 integer representation, nonnegative credits and at-cap clipping are candidate structural choices exercised only by synthetic fixtures; no payout, cap gameplay or unlock is approved by this result.

## Source and legal inputs

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, shared dirty checkout. Original canonical manifest identity `c6335182cad1b0fe9ade502fa8c7ac31a7a364d27be5f0a8e27415eb01f48a4a`; canonical mechanics identity `652f14adf47d7b305e40503e6f624ce1acfe8813fe72d31e249e8572930de14f`.

Final private variant [publisher-relationships-foundation-v2](simulators/publisher-relationships-foundation-v2/variant.json), parent v1 manifest `bf4694c304df180eee92db75218f00aa998a574429ef9d2b2d227ad77deca298`. V2 candidate manifest `83765c5752a09e1b6630923d25c5829b40491df17ea323adf948c1d321268b98`; mechanics `ab9287814c3fa1cd6d2ca389ac6c701a44981838ea154fe9c4852325cb80c0f2`. Original baseline, ancestry and failed v1 remain intact. [Final audit](studies/publisher-p1-20261023-v1/audit-final.json) finds zero canonical source changes since capture.

[Fixed cases](studies/publisher-p1-20261023-v1/cases.json): Action seed4417 and Sports seed1112, explicit stable Studio IDs, no traits, legal current founding grants/cash; finite visible features-first policy, Fantasy, two hands per phase, two releases and100 commands maximum. Each version starts from a fresh recipe; no old simulation envelope has its source identity changed.

## Outcomes

| Check | Actual result |
| --- | --- |
| Existing baseline | Both cases complete36 commands, two releases, cycle14; Action fresh replay exact36 steps. |
| Private v1 and final v2 | Same completion counts; each retained a nonempty Studio checkpoint. V1 has the world migration defect below and is superseded for adoption. |
| V2 gameplay parity | [22-check JSON audit](studies/publisher-p1-20261023-v1/audit-final.json) passes. Same exact recipes, initial/final RNG and measured outcomes. Native DTOs match after removing only the empty relationship field and normalizing the named content revision. |
| Deeper parity/source checks | [80-check decoded audit](studies/publisher-p1-20261023-v1/runtime-audit-v2.json) passes: all72 command/result/RNG steps and full final runtime state match, excluding only the new empty ledger and false commit guard. Old simulation envelopes continue to reject; two mixed predecessor world/content pairs reject. |
| Final fresh replay | [V2 Action replay](sims/publisher-p1-candidate-replay-20261023-v2/run-report.json) exactly reproduces all36 steps. Source/state checks remain enforced. |
| Pure ledger and native runtime | [Final focused run](studies/publisher-p1-20261023-v1/checks/foundation-v2/output.log):40 checks,0 failures. Covers independent credits, clipping, zero-credit event at cap, duplicate no-op, collision/forgery rejection, detached reads, typed nonzero fixture roundtrip and empty production native roundtrip. |
| Exact predecessor player | [V1 migration check](studies/publisher-p1-20261023-v1/checks/migration-action-v1/output.log):8 checks,0 failures; actual baseline campaign native payload migrates preserving every prior field/RNG. V2's whole-world tests also exercise this same migration path. |
| Native current cold restore | [Fresh V1 process](studies/publisher-p1-20261023-v1/checks/cold-v1/output.log):3 checks,0 failures; exact valid native payload restores without award. V2 cold whole-world evidence follows. |
| Whole-world predecessor and cold continuation | [V2 migration](studies/publisher-p1-20261023-v1/checks/world-candidate-v2/output.log) and [next fresh process](studies/publisher-p1-20261023-v1/checks/world-cold-v2/output.log):16 checks each,0 failures. A legal one-cycle predecessor with two active incumbents preserves player, rivals, RNG, market and existing ownership fields. Migrated cycle2 then cold cycle3 continue normally. |
| Disk generation rejection | Both world checks use actual StudioCheckpointStore/coordinator validation, private profile/directory and OS-assigned test-only TCP port. Valid generation publishes; wrong relationship owner rejects; last valid disk generation remains exact. Production fixed-port exclusion and crash recovery are not tested here. |
| Existing publisher challenges | [Final focused regression](studies/publisher-p1-20261023-v1/checks/challenge-regression-v2/output.log):52 passing assertions,0 failures. Cash, Promotion, frozen terms, old nonretroactive results and native restores retain their behavior. |

Five simulator run/replay invocations stayed below the six-invocation limit: baseline, baseline replay, v1 candidate, v2 candidate, v2 replay. Together they executed288 accepted commands, including the superseded v1. Thirteen focused processes stayed below the explicitly amended14 limit. No timeout or rejected campaign command occurred. No seed or campaign budget changed.

## Failures retained and resolved

- [Initial red check](studies/publisher-p1-20261023-v1/checks/red-baseline/output.log): baseline lacks the relationship observation API, as expected.
- [V1 historical challenge regression](studies/publisher-p1-20261023-v1/checks/challenge-regression-v1/output.log): the constructed old-rule fixture retained the new ledger and failed strict old-schema validation. V2 removes that field only when constructing this historical fixture. Runtime migration validation was not weakened.
- [V1 whole-world rejection](studies/publisher-p1-20261023-v1/checks/world-candidate-v1/output.log): player migration alone did not admit the predecessor rival-world source. V2 adds exactly the captured source, requires its old content revision on player/all rival rows, and routes direct predecessor decoding through frozen validation. Unknown world sources still reject.
- [External world-probe parse error](studies/publisher-p1-20261023-v1/checks/world-baseline-v1/output.log): missing explicit Dictionary type; retained original probe. V2 fixes typing; probe v3 uses Store's actual `status` return field before reaching disk assertions.
- [Initial audit error](studies/publisher-p1-20261023-v1/audit-initial-error.txt): attempted plain JSON tape access; replaced with object-disabled native Variant decoding and a separate JSON audit. Neither tape nor identity was modified.
- All observed Godot processes retain the existing six-ObjectDB-instance exit warning; this study does not claim it fixed.

A separate read-only review identified the whole-world gap before v2 and found no remaining blocker in the corrected dormant scope. It cautioned that the two tested mismatched predecessor pairs do not prove rejection of every possible source/content combination: current-source worlds can still use the adapter's supported old-content migration path.

## Remaining acceptance and recommendation

Recommend **DESIGN review of the narrow P1 foundation** before canonical adoption. No enabled rule means successful runtime reward notification/reentry and nonzero whole-game save settlement cannot be established by this prototype; pure fixture evidence is explicitly separate. P2 must connect an approved producer, freeze its terms, reconstruct awards from authoritative source facts and test that complete path.

Whole-world tests cover the current two-incumbent cohort at cycles1-3, not every historical world/source, populated Founder career/ownership transition, exported build, UI, or human comprehension. Disk generation publication/rejection is verified within each private process; the cold process restores the retained combined DTO, not the preceding process's generation directory. Native main-menu cold disk Continue, production writer contention and crash recovery remain adoption acceptance. Coordinator callbacks or rejected producers may flush a valid prior Studio checkpoint; the checks establish no gameplay/RNG mutation, not zero filesystem activity.

P3/P4 commission/support values, rights/finance integration, active producer atomicity, second-support save defect and v4 renewal remain separate. This dormant P1 does not repair the older support candidate or approve balance. Preserve the independent-client cash Brief commitment. No canonical gameplay, player saves, commit or push changed.
