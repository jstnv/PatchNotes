# Feature Store findings v9 — delaying Sub-Areas one release

Date: 2026-10-06 (America/Los_Angeles). **Read-only native timing probe, not a price or unlock ruling.**

## Exact source and setup

Branch `main`, HEAD `553d1a46f33d59641efa4c2e4ff141f958c1230d` before and after. The [predeclaration](sim-v7/predeclaration.json) records four jobs, the process-local driver SHA-256 and hashes of all 593 tracked gameplay/source files. Those source hashes exactly match the earlier [v8 parent comparison](FINDINGS-v8-sub-areas-parent-rule.md). The [run report](sim-v7/run-report.json) records each Godot 4.7.1 command, isolated user profile, trace hash and unchanged source comparison. No gameplay file, ledger, test, asset or configuration was edited.

Question: if independent, Store-only Sub-Areas remains at the **candidate $1,700 base** and has zero later-card play fee in native source, does waiting from the fixed post-Game-3 shopping point until **after Game 4** avoid the earlier Strategy financial block while still allowing a real Game 5 play? Four new Strategy routes use seeds 1104/4417 × ordinary/synergy. Pair each with its already captured native no-buy and fixed-post-Game-3 route from `sim-v6/` on identical source hashes. All use genuine current MainMenu $5,700 start, $500 rent, one-cycle Store purchase, exact-cent all-title sales settlement, current Ironclad/SideStreet and 18-action later development. Fixed windows are comparison devices, **not candidate player unlock or advice rules**.

## Results

All four new routes exited 0, passed finance/ledger checks and reached five releases. **Only two bought Sub-Areas**; both supplied, drew and committed it once in Game 5. The other two were below the $1,700 quote at the delayed shopping point and abstained. All four match their no-buy controls on the first four release cycles, Reviews and Scopes before the purchase decision.

| Strategy route | Cash after Game 4 before decision | Delayed purchase / Game 5 play | Game 5 Review (no-buy → delayed) | Final cash / unpaid rent (delayed) | Earlier post-Game-3 result |
|---|---:|---|---|---:|---|
| 1104 ordinary | $2,303.09 | Bought; $603.09 after purchase; played | 5.5 → 6.0 | $0 / **$145.87** | Bought/played in Games 4–5; Game 5, no arrears |
| 1104 synergy | $2,324.38 | Bought; $624.38 after purchase; played | 5.2 → 6.8 | $574.72 / $0 | Bought/played in Games 4–5; Game 5, no arrears |
| 4417 ordinary | $1,384.42 | Could not buy; no play | 5.3 → 5.3 | $2,076.02 / $0 | Bought/played Game 4; blocked before Game 5 with $315.58 overdue rent |
| 4417 synergy | $645.92 | Could not buy; no play | 4.6 → 4.6 | $36.82 / $0 | Also abstained after Game 3; Game 5, no arrears |

The delayed card improved the two buyer routes' Game 5 Review and Scope (26→28), but **one of the two buyers accrued rent arrears**. That fails the approved bounded-pilot hard solvency gate against its no-buy control despite reaching Game 5. At the matched post-Game-4 cycle checkpoints, Game 4's settled net sales are identical between each delayed and no-buy pair because their first four releases are identical. Game 5 sales have **not settled** by these five-release traces, so no realized Game 5 cash payback can be claimed. [Exact paired CSV](sim-v7/summary.csv) retains cycles, cash, actual Game 4 settlement, draw/play, arrears and credit.

## Verification, recommendation and limits

`sim-v7/audit.py` passed four SHA-256 raw trace, source/driver stability, genuine startup, exact cash/finance, nonzero ledger checks and zero Contract candidate hits. `sim-v7/analyze.py` generated the paired CSV and asserted each delayed route's four-release prefix matched its no-buy control. Native totals: **2 purchases, 2 Game 5 committed plays, 4 five-release routes, 1 route with unpaid rent**. The analysis-only shadow never entered the live catalog.

**Recommendation:** do not approve a first-era fixed post-Game-4 purchase window or the $1,700 price from this probe. A simple delay trades away access in two routes and still causes arrears in one buyer. The next meaningful read-only question is whether an explicit full-next-project/rent reserve can select solvent purchases at the independent-node quote; the already-queued Task 2 broader comparison owns that route, with genuine separate $5,500 starts, more seeds and a live-node control. If its deferred/reserve buyers remain unsafe, compare narrower lower candidate prices on the same paired routes before discussing a play fee or first-era purchase eligibility.

Limits: two seeds, one specialty, two policies, one fixed delayed window, zero candidate play fee, and no Game 5 post-launch settlement. This probe does not establish a success rate, an optimal price, a reserve amount, a purchase trigger, a calendar/era unlock or gameplay implementation authority. Its completed release count cannot substitute for the no-arrears gate.
