# Founder Legacy & Corporate Ownership — source-pinned integration review handoff v3

**Date:** 2026-10-11 (America/Los_Angeles). **Status:** DESIGN integration review queued by the user's request to update the internal To Do List; no gameplay implementation or numerical balance approved. This is the current handoff. [Handoff v2](HANDOFF-v2.md) retains the phased F0–F7 dependency and acceptance map; the later [share-sales/control](2026-10-11-share-sales-and-control-v2.md) and [founder-role](2026-10-11-founder-role-transition-v1.md) decisions amend [SPEC-v2](SPEC-v2.md).

## Source and scope pin

- Local branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f` at review preparation. The relevant canonical source files below matched their HEAD blobs at inspection. The overall worktree was dirty from other threads, including shared TODO, AI records and unrelated audio/UI source; this is a **focused architecture reference**, not a frozen full-game build or latest-source acceptance claim.

| Current reusable source | HEAD Git blob |
|---|---|
| `patch-notes/scripts/run_state.gd` | `afcc7e660e2f8a2fad4a7f2d8b797e393a66c671` |
| `patch-notes/scripts/finance/studio_finance_ledger.gd` | `a68651ae18af97a41c7290eefc04f42233643b2f` |
| `patch-notes/scripts/finance/outstanding_expenses.gd` | `c4ca76690012e0948f309e77c56d9717a828deab` |
| `patch-notes/scripts/finance/bank_loan.gd` | `aa87012d17bd23db8bcf2fed081edae6fd1f6864` |
| `patch-notes/scripts/persistence/checkpoint_codec.gd` | `359bed173a7b240b41999932251aa68e55b9a51e` |
| `patch-notes/scripts/simulation/campaign_session.gd` | `7d5e1871daaf97f7e6e91036d82d950a280c08f2` |
| `patch-notes/scripts/market/competitor_definition.gd` | `f7ffa65f4b574db66a2d4878e5fd1a6cc93d3927` |

There is **no candidate simulator version or source delta** from this thread. The exact proposed delta is the design contract: a persistent founder and one manual operator over a world of separate Studios; equal-share ownership transactions and >50% direct control; valuation with distinct non-IP earnings and IP forecasts; Studio-owned startup loans/equity; paid voluntary founder sales and AI accumulation; a two-boundary ownership/CEO transition; autonomous former Studios and subsidiaries; and whole-world deterministic saving/evaluation. The detailed state, formulas, diagrams and exploit cases are in the linked specification and amendments. Existing card, Store, finance and AI development rules are reused, not silently rewritten by this handoff.

## Review action and stop gates

1. **F0 first:** map the selected world/ownership contract to the exact then-current AI Competitors G1–G5 state, Banking service, Studio checkpoint writer and legal campaign commands. Re-pin current source and preserve dirty changes. Audit the legal route from every active hand/Contract to a durable operator handoff, including an unaffordable continuation. Record any impossible route as a blocker rather than adding an unapproved mid-phase cancel.
2. Separate the first implementable slice from dependencies using [F1–F7 in handoff v2](HANDOFF-v2.md). The implementation owner should propose the smallest source delta, migration boundary and exact checks before touching canonical gameplay. One overlapping canonical gameplay implementation at a time still applies.
3. Keep formation split, CEO mandate term, acquisition premiums, warning thresholds, valuation/credit coefficients, AI buyer quotas, population/CPU limits and milestone content **CANDIDATE/OPEN** until source-pinned calibration and review. Do not substitute AI Competitors private fixture values. No design document, TODO entry or prototype establishes runtime adoption.

## Acceptance for this review, and later proof

The review is complete only with a dated source map and dependency disposition for F0–F7, the active-hand/Contract handoff audit, a clear first-slice boundary and a list of unresolved values owned by their proper design threads. Later implementation needs exact share/cash conservation, pre/post-money and dilution cases, 50% boundary, founder consent and rejection, bank eligibility/no duplicated funding, CEO/interlude/AI old-Studio continuation, world save/rollback/replay, and measured six-cycle corporate AI cost. Those are proposed future acceptance gates; **none were run by this design-only thread**.

The user authorized a concise internal TODO entry pointing to this packet. This handoff neither dispatches another chat nor authorizes a code edit, simulator variant, commit, push or release claim.
