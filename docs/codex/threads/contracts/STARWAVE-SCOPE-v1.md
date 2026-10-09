# Starwave first-offer scope — design question v1

2026-10-08 (America/Los_Angeles). **Proposed discussion, not an approved Starwave reward or implementation handoff.** Read-only review of `main` HEAD `91ce539978b87ac0a6efe3a1e028cae5f1360f19` plus the existing dirty worktree. The inspected `run_state.gd` SHA-256 is `4AB5286F78F7A4AA7D778E99CEBBD917161874A6934EDBE89FEA2CE6D4064577`; `publisher_catalog.gd` is `D30743C4D477AD9C59B2CF0DB962E7C076E798D64D5CC29F5C580E7C74702CB2`. No simulation was run for this note.

## Established boundary

[Publisher authority](../../design/publishers-contracts.md) fixes Starwave's profile gate at two distinct releases and three distinct completed Contracts. Its accepted future-offer structure is one persistent first-unlock offer, three successful hands, the owned Primitive pool frozen at acceptance and one active Contract at a time. In the [v7 legal chain](FINDINGS-v7-crown-neon-offer-chain.md), completing Neon as the third Contract unlocked the Starwave **profile**; Promotion did not cause that unlock. Current source creates first-unlock offers for Crown and Neon, but [RunState](../../../../patch-notes/scripts/run_state.gd) does not create one for Starwave, and [the catalog](../../../../patch-notes/scripts/publishers/publisher_catalog.gd) says no offer is implemented. The historical $2,240/14, Scope 14/each Core 7 and three-hand formula are **OPEN candidates**, not live or approved rewards.

## Decision to make before numbers

What role should the first Starwave offer play when the profile unlocks?

| Direction | Benefit | Cost or design risk |
|---|---|---|
| **A. Bounded three-hand cash/Promotion offer using current Contract mechanics** | Gives the unlock an actionable deal and allows matched-calendar balance tests without inventing reputation, revenue share or exclusivity systems. | Three hands delay the next release; a reward comparable to a two-hand offer could be unattractive, while an excessive cash or Promotion reward could dominate other offers. The advance, completion pool, targets and reward mix all need separate decisions. |
| **B. Defer the offer until broader mass-market deal mechanics are defined** | Protects Starwave's distinct publisher identity and avoids a provisional reward that may need redesign. | The profile unlock stays informational for now, including after a player completes a third Contract. The timing and scope of those broader mechanics are still open. |

**Recommendation, proposed:** select A as a bounded first playable slice, with a distinct longer-commitment purpose and an explicit cash-timing question. The current Contract system and accepted three-hand structure make that a narrower design step. This does **not** approve a cap, advance, formula, Promotion amount or implementation. If Starwave is meant primarily to introduce new commercial terms, choose B explicitly and record why its profile currently has no playable offer.

If A is selected, define the player's reason to accept a three-hand deal, what cash arrives at acceptance versus completion, whether it earns next-launch Promotion, and how its payout compares with leaving it pending. Then predeclare one legal route from the existing Starwave unlock and compare Starwave acceptance with legal available offers and immediate project work at matched calendar checkpoints, including actual settlements and all three hand cycles. Use the current source and cash/Bank/Store state; do not promote historical $2,240/14 or Scope/Core targets from old notes. Human Crown/Neon pilot feedback is still needed before final tuning of those existing offers.

No gameplay, shared TODO, design-authority or configuration file was changed by this scope note.

## Later read-only follow-up

[V10](FINDINGS-v10-starwave-shadow-timing.md) measures three analysis-only productive cycles from a legal post-Neon Starwave-profile checkpoint. It supports the proposed cash-first direction as a question worth developing and shows that even a historical full-cap fixed receipt leaves the next release three cycles later. Its synthetic reward and lack of scored Starwave hands leave all numerical and implementation decisions OPEN. The next evidence step is three-hand frozen-pool draw/completion feasibility, followed by reward selection and user review.
