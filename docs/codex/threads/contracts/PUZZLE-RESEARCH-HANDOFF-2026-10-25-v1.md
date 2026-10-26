# Puzzle Research — versioned review handoff v1

2026-10-25. **DESIGN review; zero canonical implementation delta.** [Finding](PUZZLE-RESEARCH-FINDINGS-2026-10-25-v1.md) · [preregistration](studies/puzzle-research-20261025-v1/PLAN.md) · [exact source/verification](studies/puzzle-research-20261025-v1/verification.json).

## Decision requested / recommendation

Retain8-bit Sound + Sprites as an additional access fixture, preserving the original8-bit Sound + General Combat fixture. Do not mandate either pair or change rewards. Sprites reaches Crown4/4 versus baseline3/4, including the original4417 failure, but does not reliably accelerate progression. The two unseen confirmation seeds both unlock with either pair: Sprites is1 cycle earlier in4418 and20 later in4522. Every Sprites comparison finishes with less cash. Only discovery selected this candidate; the extra seeds provide separate, mixed confirmation.

| Seed | Baseline Crown cycle | Sprites Crown cycle | Cycle difference | Final cash difference |
|---|---:|---:|---:|---:|
| 4417 | Not reached | 80 | New access | $-2,889.58 |
| 4521 | 67 | 65 | -2 | $-2,727.83 |
| 4418 | 63 | 62 | -1 | $-881.67 |
| 4522 | 63 | 83 | 20 | $-5,032.02 |

Cash is compared at the same four-release horizon, sometimes at different calendar cycles; it is not a fixed-calendar revenue estimate. Both pairs cost$900/two Research actions and begin Game2 with equal cash/cycle. All12 measured cases complete without arrears. No participant earns cash or Reputation from Crown Briefs in this study.

## Tasks and dependencies

| ID | Status | Task | Acceptance / dependencies |
|---|---|---|---|
| PR1 | **implemented and verified — evidence only** | Preserve8 discovery +4 confirmation campaigns and legal purchase fixtures | Exact original controls, four equal-start groups, eight shared-prefix checks, actual two purchases/$900/two actions/six Searches, all outcomes, fresh replays and Studio Continue. Source/policy hashes and commands retained. |
| PR2 | **proposed** | Retain Sprites as an additional accessibility fixture | Keep both routes; no canonical auto-shopping, starter grant, price/reward/Review-gate change or guarantee of optimality. Preserve the negative4522 pacing result and original4417 baseline failure. |
| PR3 | **proposed** | Test paid Crown Brief affordability from earlier earned access | Use actual first-unlock prefixes:4417 Sprites Game4/cycle80,4418 Sprites Game3/cycle62,4521 Sprites Game3/cycle65,4522 Sprites Game4/cycle83. Regenerate legal prefixes in the compatible private Crown runtime; prove source/state/RNG differences, then matched take/skip trials with predeclared horizon/cash/reputation/arrears measures. No synthetic R7/money/cards; no checkpointer identity edits. Do not count these study saves as cross-version compatible without verification. |
| PR4 | **approved — unchanged pilot terms only** | Retain Crown Brief numeric terms and current base rewards | [Approval](BALANCED-CRAFT-APPROVAL-2026-10-25-v1.md); canonical activation remains gated. No new reward formula or unlock gate is approved here. |
| PR5 | **proposed; gated** | Review preview and eventual canonical adoption | [Paid-Search preview v2](CROWN-PREVIEW-HANDOFF-2026-10-25-v2.md), [existing runtime packet](handoffs/crown-search-brief-20261025-v1/HANDOFF.md), named migration, atomic settlement, active-rival/world, current native/export/human acceptance. These are not closed by access-only policy results. |

## Source and precise delta

Main HEAD0132c4dab398a2a94dbeae3caa68a36505fbfa4f; dirty shared checkout preserved. Named simulator `puzzle-research-20261025-v1` retains immutable ancestry from `crown-access-policy-20261025-v1`; full source identity434971b9525f09fab3fa0846ed094f53d6ee778f76ae8b97740a136c7b0fda3f. Runtime delta: zero. External `studies/puzzle-research-20261025-v1/policy.gd` chooses explicit legal purchase pairs and adds observable Core diagnostics; card selection, phase exits and all rules stay unchanged. It is research code, not an approved gameplay patch. No new sealed gameplay adoption packet is necessary; preserve the existing Crown packet.

Review routing only. No cross-chat dispatch, automatic adoption, commit, push or release claim.
