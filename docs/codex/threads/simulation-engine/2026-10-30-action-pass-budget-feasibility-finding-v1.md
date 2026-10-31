# Action Pass Budget formula feasibility — fixed Primitive build, 2026-10-30

**Status: RESEARCH / formula screen only.** No gameplay files, card data, 30-Scope project requirement, Pass Budget mechanic, conversion threshold, or initial allowance were changed or approved.

## Pinned baseline and printed contributions

Use the exact six Feature hands in the [Action Feature build](2026-10-30-action-feature-build-finding-v1.md) and the [12-Pass minimum](2026-10-30-action-pass-requirement-finding-v1.md). The fixed hand-enhanced Feature result is G27/S10/T46/D35, 35 played Scope against 30 required, with neutral base Action standards, zero remaining Bugs and zero review variance. A Pass-only hand of four matching Pass instances yields +12 in its Core by current specialization. One Graphics hand and two Sound hands reach G39/S34/T46/D35 and 8.8 displayed Review. That minimum assumes the six Feature hands remain intact; no Pass may be placed into them without changing their composition and synergies.

Read `CardData.core_contributions()` from `patch-notes/data/card_ledger.json` for each selected Feature, once. **Printed values**, not hand-enhanced production values, fund the hypothetical budget:

| Phase | Printed G/S/T/D from 12 Features | Hand 1 | Hand 2 | Hand 3 | Cumulative printed Core |
|---|---|---:|---:|---:|---:|
| Design | 12 / 5 / 22 / 11 | 19 | 13 | 18 | **50** (prefix 19, 32, 50) |
| Alpha | 9 / 3 / 9 / 18 | 11 | 11 | 17 | **39** (prefix 11, 22, 39) |

The combined printed Feature Core is 89, but the budget scopes are independent. At the Design-to-Alpha transition, Alpha receives its own initial allowance and begins its cumulative printed count at zero. A successfully played Feature updates that phase's available budget immediately; a successfully played Pass spends one. Candidate draws and redraws spend none.

## Complete requested grid

In each phase, **total generated budget** is `I + floor(phase printed Core / K)`, with I the starting budget. `D bonus/A bonus` excludes the starting allowance. `D total/A total` includes it. `4/8?` tests the original four-Graphics-in-Design, eight-Sound-in-Alpha sequence. `Chosen split` uses 4/8 where possible, otherwise the score-equivalent **8 Design / 4 Alpha** sequence (one Graphics and one Sound hand in Design, one Sound hand in Alpha). `Unused` is remaining Design/Alpha budget after those 12 activations. All feasible rows pass the ordering/reservation construction below; **No** means no allocation of the required three complete Pass hands is funded.

| I | K | D bonus / A bonus | D total / A total | 4/8? | Chosen split | Unused D / A | 12-Pass sequence? |
|---:|---:|---:|---:|:---:|:---:|---:|:---:|
| 1 | 3 | 16 / 13 | 17 / 14 | Yes | 4 / 8 | 13 / 6 | Yes |
| 1 | 4 | 12 / 9 | 13 / 10 | Yes | 4 / 8 | 9 / 2 | Yes |
| 1 | 5 | 10 / 7 | 11 / 8 | Yes | 4 / 8 | 7 / 0 | Yes |
| 1 | 6 | 8 / 6 | 9 / 7 | No | 8 / 4 | 1 / 3 | Yes |
| 1 | 8 | 6 / 4 | 7 / 5 | No | — | — | **No** |
| 1 | 10 | 5 / 3 | 6 / 4 | No | — | — | **No** |
| 2 | 3 | 16 / 13 | 18 / 15 | Yes | 4 / 8 | 14 / 7 | Yes |
| 2 | 4 | 12 / 9 | 14 / 11 | Yes | 4 / 8 | 10 / 3 | Yes |
| 2 | 5 | 10 / 7 | 12 / 9 | Yes | 4 / 8 | 8 / 1 | Yes |
| 2 | 6 | 8 / 6 | 10 / 8 | Yes | 4 / 8 | 6 / 0 | Yes |
| 2 | 8 | 6 / 4 | 8 / 6 | No | 8 / 4 | 0 / 2 | Yes |
| 2 | 10 | 5 / 3 | 7 / 5 | No | — | — | **No** |
| 3 | 3 | 16 / 13 | 19 / 16 | Yes | 4 / 8 | 15 / 8 | Yes |
| 3 | 4 | 12 / 9 | 15 / 12 | Yes | 4 / 8 | 11 / 4 | Yes |
| 3 | 5 | 10 / 7 | 13 / 10 | Yes | 4 / 8 | 9 / 2 | Yes |
| 3 | 6 | 8 / 6 | 11 / 9 | Yes | 4 / 8 | 7 / 1 | Yes |
| 3 | 8 | 6 / 4 | 9 / 7 | No | 8 / 4 | 1 / 3 | Yes |
| 3 | 10 | 5 / 3 | 8 / 6 | No | 8 / 4 | 0 / 2 | Yes |

There is **no trade between phase budgets**: for example I=1, K=8 has 12 total generated across the two phases (7+5) but cannot pay for either 4/8 or 8/4. Both phases need complete four-Pass hands, and the Sound/Graphics hand count must be allocated phase by phase.

## Required order and candidate reservations

For a chosen split, the three Feature hands in each phase occur first, unchanged. Their cumulative printed Core advances that phase budget at prefixes 19/32/50 or 11/22/39. The minimum budget after the **second** Feature hand over all 18 tested settings is three in Alpha (I=1,K=10); that suffices to reserve three matching Pass candidates while the last four Features are supplied. After the third Feature hand, every feasible chosen phase has at least four unspent budget per planned Pass hand. A two-Pass-hand phase has at least eight total, leaving at least four after the first.

A constructive candidate pattern respects the seven maximum and retained-card accounting: begin a phase with the first four prescribed Features plus three Features from its final Feature hand; refill the four Features for the second hand; then refill the last Feature plus three Passes of the later needed type. After the third Feature hand, those three Passes are retained. Draw up to four more Pass candidates, **capped by total unspent budget minus retained Pass candidates**. For 4/8, the Design refill needs one Graphics Pass and the Alpha refill can draw four Sound Passes. For 8/4, the Design refill can draw four Graphics Passes beside three retained Sound Passes; after playing Graphics, four budget remains, so at most one new Sound Pass is drawn beside the three retained. The final Alpha Sound hand needs only one new Sound Pass beside three retained. This produces the needed four-card hands without counting draws as consumption. Candidate pools may shrink below seven after Features exhaust and Pass budget falls; no minimum-size draw is assumed.

Every needed Feature and Pass has positive weighted draw probability at ordinary positive priorities, and Pass definitions are renewable. Thus **each Yes row is logically Pass-order-feasible under the stated hypothetical budget and candidate rules**, not a guarantee or measured likelihood under the current weighted RNG. A separate integration dependency remains: current `DevelopmentActions.valid_pool()` requires exactly seven candidates, and Alpha `can_finalize()` calls it (`patch-notes/scripts/simulation/development_actions.gd:223-249`). If the budget leaves fewer than seven eligible candidates after the final Pass hand, that current guard would reject Alpha finalization. The proposed short-pool rule would have to reconcile this guard before any full release claim. The current production game has no Pass Budget cap, so this construction is not a live gameplay acceptance test. Actual acquisition, Store ancestors, cash, redraw choices, Beta cleanup, Market pressure, and seed-specific draw frequencies remain outside this formula screen.

## Feasibility boundary and later simulation candidates

Within the requested I=1/2/3 grid, the lowest tested starting allowance is **1**. For **I=1**, K=6 is the least efficient tested conversion that funds 12 Passes, but it requires the 8/4 split; the original 4/8 split needs K≤5. For **I=2**, the least efficient feasible tested value is K=8; for **I=3**, K=10. Considering positive integer K between grid points, the exact maximum feasible thresholds are **K=7, 8, 10** for I=1,2,3 respectively via 8/4. A zero starting allowance, if permitted outside this requested grid, could also fund 8/4 at K≤6 after all Features are played; therefore an initial allowance of one is **not a mathematical necessity** for this fixed route.

The most useful later simulation comparisons are **I=1,K=5** (preserves the previously chosen 4/8 split with Alpha exactly exhausted), **I=1,K=6** (lower overall surplus, but moves a Pass hand to Design), and **I=2,K=8** (D8/A6 with just two unused Passes). **I=3,K=10** has the same terminal D8/A6 budget as I=2,K=8 but grants more budget before Feature investment; include it as an early-budget comparison, not an endorsed balance value. **I=1,K=7** is an untested-grid mathematical boundary worth adding only if a later study broadens the threshold set. K=3/4 produce large unused allowances on this optimized route and should be checked as potential Pass-heavy stress cases if simulated. None of these arithmetic successes establishes an 8.0 ordinary-play success rate.

Reproduction: `node docs/codex/threads/simulation-engine/action_pass_budget_feasibility.mjs`; [retained complete per-hand and per-cell data](action-pass-budget-feasibility-2026-10-30.json).
