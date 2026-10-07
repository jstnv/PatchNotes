# Publishers and Contracts

Authority: cumulative §§39–44,47,55,57,59,61; current Tasks7,15,20,23,32,34. Source: [publisher catalog](../../../patch-notes/scripts/publishers/publisher_catalog.gd), [ContractState](../../../patch-notes/scripts/contracts/contract_state.gd), RunState and ContractPhase.

## Locked and implemented

Five profiles with monotonic run-level unlocks; passive browser/notifications free. Ironclad owns the one-shot balanced Primitive offer. SideStreet requires Ironclad committed completion (current code has an explicit Ironclad completion field); Crown unlock uses frozen released Review≥7.0; Neon frozen launch Awareness≥125; Starwave two distinct releases and three distinct committed Contracts. Later sales/campaigns do not change frozen unlock inputs.

Ironclad: $400 acceptance receipt, then floor(200,000c×completion numerator/96) on hand2; total≤$2,400. SideStreet: one persistent release-linked offer per new release meeting its size's required played Scope, existing entitlements preserved; no advance, floor(120,000c×N/96) on hand2. Legacy offer history remains valid. Ownership is not played Scope.

Two successful four-card hands, seven candidates, owned Primitive finite Features + Core Passes frozen at acceptance, Contract Feature play$0, finite exhaustion and run redraw/priority rules. Each committed hand one productive cycle, acceptance/browsing/results dismissal zero. Payout at completing hand's direct-effect stage before cycle/sales/rent; immutable offer/result IDs and payout once. Existing cash offers grant no Promotion. Contract-to-Store familiarity remains unimplemented/open.

## Accepted direction for future offers; numerical approval absent

§59: one non-expiring first-unlock offer each for Crown/Neon/Starwave; pending offers coexist, one active Contract, chooser needed. Crown/Neon two hands, Starwave three. Current owned Primitive pool frozen at acceptance; no later Feature-class enrollment, abandonment or minimum-completion gate. Distinct zero-formula-cash completions can count once.

Earned Promotion keyed by offer, additive without silent cap, consumed once by the next successful launch's Beta Marketing/Awareness commit, cleared atomically only then. Failed launch preserves it; earlier releases unchanged. None of this is runtime implemented.

Current fixed-share candidate (Tasks23/32): H_i=2×resolved Core.
Crown completion=(18×min(Scope/S,1)+Σmin(H_i,8)+2×min_i min(H_i,8))/66, S=9 or10.
Neon=(20×min(Scope/S,1)+3×min(H_focus,18)+Σother min(H_i,4))/86, S=10 or11; focus frozen at acceptance.
Clamp[0,1], exact rational arithmetic; separately floor cents and whole Promotion at end. Candidate caps Crown$1,920/12 Promotion, Neon$1,560/20. Increasing requirements must not increase payout for the same hand. Full completion exactly caps. Older §59 target-dependent weights and §47 larger Promotion amounts are historical trial arms, not locks. Starwave$2,240/14 and its Scope14/eachCore7 three-hand formula remain unapproved, outside Task34.

## Current Task34 and open implementation package

[Task34 exact brief](contract-advance-trial.md) is READY for bounded read-only acceptance-advance testing on verified current source, after stable snapshot. Compare A=$0/$150/$200/$300 while keeping maximum C fixed: acceptance A, final floor((C−A)×fixed_share_completion). Total A at zero completion, C at full; no extra/recouped/repeating advance. Compare no-trait$5,500 and genuine Task31$5,700 ledger creation. Values remain candidates; no runtime approval.

Task32’s legal9.0 route had$147.65 arrears; liquidity/first-hand access is a current economic question. Promotion was modeled, not earned in live game. Rerun only relevant cases after repair/source changes. [Evidence](../findings/current-balance-evidence.md) distinguishes native routes, shadow offers and historical models.

Open: targets/caps/advance per publisher, Promotion economics/stacking, chooser/transaction persistence, Starwave feasibility, broader publisher reputation/revenue share/recoupment/exclusivity/control (deferred). Keep Ironclad/SideStreet rules fixed and actual rent/lifespan settlement in all comparisons. Fresh publisher/Scope verifiers pass; [migration audit](../findings/migration-audit-2026-10-06.md).
