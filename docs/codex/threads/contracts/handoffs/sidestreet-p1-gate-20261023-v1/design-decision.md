# SideStreet Reputation Brief and first commissioned-game offer

2026-10-23. **PROPOSED bounded pilot, not approved numerical gameplay.** User authorized private work after P1 completion. P1's structural foundation is approved and implemented; this document does not extend that approval to P2/P3 values. [Study plan](studies/sidestreet-p1-gate-20261023-v1/PLAN.md), [current-source analysis](studies/sidestreet-p1-gate-20261023-v1/analysis.json), [prior offer/finance specification](PUBLISHER-OFFER-AND-FINANCE-SPEC-2026-10-22-v1.md).

## Decision recommended

Retain the two-hand partial-credit Reputation Brief. Treat R20 as **access to commissioned work**, not proof that the next game will satisfy the commission. Make the first SideStreet commission and its ownership/underdelivery explanations available in the same player-facing pilot as Reputation-only briefs. Engineering may integrate the pieces in stages behind disabled activation, but players should not spend six cycles on a standing meter with no enabled use.

This recommendation uses the existing proposed $6,000/Review6 tier rather than lowering the target to fit the short six-hand policy. No post-gate short release in the new study meets that delivery promise; this shows that the brief policy is not a delivery strategy. Historical source-pinned commission evidence includes a legal Scope30/Review8.8 route, but that older revision is not current-P1 delivery or balance proof.

## P2 terms to rule on

- Separate optional SideStreet Reputation Brief; existing cash Contract and Ironclad remain unchanged.
- Two committed hands, one productive cycle per hand, eligible owned Primitive Features plus existing Pass rules. No cash, Promotion or Investment award.
- Aggregate targets: Scope10 and3 points in each Core. With Core scores in half-units H_i, completion `C=floor(10000*(4*min(S,10)+sum(min(H_i,6)))/64)`.
- Promise grade `G=10000` for Scope<=10 and no successful redraw, `G=5000` at Scope11, otherwise0. Any successful redraw makes G0; rejected requests do not.
- Reputation award in hundredths `floor(1000*min(C,G)/10000)`, maximum10.00. Positive partials are useful delivery, not total failure. The award is not a fee taken from existing Contract rewards.
- First opportunity after introductory Ironclad, then release-based opportunities; one pending/active Brief, no completion refill or accumulated backlog. Pending offers persist while the player does something else. A single global active Contract remains enforced.
- Reputation is not spent. Reaching20.00 makes a SideStreet commission eligible. Extra Briefs remain optional; do not automatically accept them or imply that more Reputation is required for the first tier.
- Store all standing in P1's Studio-owned ledger. Resolve an event only from its committed, frozen versioned Brief result and exact productive-action provenance. Zero-grade completion still has one event with zero credit, so it cannot be retried for a new award.
- Old saves receive prospective offers only. Old Contracts/releases never receive retroactive Reputation.

## First commissioned-game offer

Recommended bounded catalog: one SideStreet tier at R20, currently legal Genre/Theme, no additional authored Feature or era requirement. One globally active project/Contract. Quote during project preparation; atomic acceptance starts exactly that prepared project. Completed work may lead to a new quote for a later project; no stacked offer backlog or acceptance advance. Repeat-offer/cancellation rules require explicit implementation review before activation.

The quote freezes publisher, Studio owner, project/release ID, selected legal setup, positive project-required Scope, Review target6.0, fee600000 cents, standing awards1500 hundredths each, ownership and formula revision. **Do not hardcode30 Scope:** use that prepared project's actual positive requirement. Reject stale or invalid quotes without spending cash, advancing cycles, consuming RNG or binding a deal.

At successful launch, with delivered Scope S, frozen required Scope Q>0 and final one-decimal Review r in tenths:

`scope_bp=min(10000,floor(10000*S/Q))`

`review_bp=clamp(500*(r-40),0,10000)`

`delivery_bp=min(scope_bp,review_bp)`

`fee_cents=floor(600000*delivery_bp/10000)`

Only full delivery grants +15.00 Reputation and +15.00 Investment, capped by P1. Partial work can earn the quoted salvage fee but no standing. Full Scope/Review5.0 pays$3,000; Review5.9 pays$5,700; Review<=4.0 pays$0. These remain proposed terms, not a claim of fair economics.

Publisher owns this title's sales. Preserve observed units and Fanbase effects, but Studio earned/settled title sales and Bank-qualifying sales are zero; the commission fee is a distinct receipt. Existing next-launch Promotion is consumed at this launch and must be disclosed. Studio-paid post-launch campaigns are unavailable. Do not award a legacy completed work Contract toward Starwave. P4 support/funding/marketing/recoup stays outside this slice.

## Player-facing explanations

Before a Brief: show “2 hands · 2 productive cycles · up to10.00 SideStreet Reputation · no cash reward.” Preview the actual enabled first commission and R20 progress. After each hand show cumulative Scope/Cores, successful redraw status and projected earned Reputation; the next draw is unknown. Completion shows the exact partial award and total.

At R20: “SideStreet commissions unlocked” opens the offer details at the next safe Studio boundary. It must not say the Studio is ready to deliver. The quote prominently shows fee, Scope, Review, no advance, publisher ownership and the partial-payment examples. A recent game below the requirements may inform a warning, never a fabricated prediction or hidden hard gate. The player can keep developing/self-publishing and return later without losing access.

At launch: separate completion fee, standing and publisher-owned sales. At zero fee, show which Scope/Review condition limited delivery. Support eligibility is not advertised as usable until its separate implementation exists.

## Alternatives considered

1. **Chosen recommendation: keep brief partials and distinguish access from delivery.** Current routes can reach R20 while the commission remains a later production challenge. Requires clear quote UX and a verified current-source delivery route.
2. Lower R20 or Review target to make the short study policy succeed. Rejected for this pass: access already succeeds, and the study deliberately uses short later projects rather than a quality-seeking delivery policy.
3. Add cash to Reputation Briefs or auto-grant a commission success. Not recommended: neither addresses delivery readiness, and both introduce reward changes without economic evidence.

## Implementation dependencies and acceptance

1. Explicit trial ruling on P2 terms, R20 and tier1 commission economics/ownership; findings do not supply this ruling.
2. Review the current-P1 P2 packet. Canonical adoption must replace the private producer's assert-only internal assumptions with validated transaction planning consistent with the existing engine, and retain exactly-once coverage and observer guards. Keep unchanged existing Contract/RNG controls.
3. Add named migration from the exact completed P1 source, including player and active rivals, empty prospective Brief histories, no retroactive awards, and malformed/mixed-version rejection preserving the last valid generation. The research candidate intentionally does not claim predecessor migration.
4. Build the commission producer against P1 and the current owner-aware release/finance path. The historical commission prototype is reference evidence; do not copy its former standing dictionaries. Reconcile prior quote/binding, signal-order and rights-to-finance review issues.
5. Before player activation, demonstrate a legally earned-R20 current-source campaign that satisfies a real quoted commission, plus a miss with exact salvage and no standing. Pair ownership arms from a common legal checkpoint, record early liquidity and later lost sales, and fresh-replay both. Do not rewrite old checkpoint identities.
6. Verify actual native Studio cold Continue, exported offer/result/ownership presentation at supported sizes and human comprehension. Current headless passes do not close these.

## Status

P1: **implemented and verified at its recorded dormant scope**. P2 research: **private prototype tested; proposed for review**. P3 terms/UX and the activation coupling: **proposed**. P4: **OPEN**, no implementation in this pass. None of P2/P3's values are labeled approved or ACTIVE/TRIAL here.
