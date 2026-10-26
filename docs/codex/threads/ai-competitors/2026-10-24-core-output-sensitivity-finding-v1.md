# AI Competitors: modest Core-output sensitivity — 2026-10-24

**COMPLETE bounded DESIGN counterfactual; exact Core bonus remains OPEN.** The user's proposal is to give rivals a small Core-output increase so their early releases score well without costly decision search, while retaining progression. The [pre-run plan](2026-10-24-core-output-sensitivity-plan-v1.md) tested that idea against the frozen [current-source legal-world audit](sims/rival-core-review-audit-20261024-v9.json). A modest boost helps an already longer, better-selected project plan, but cannot rescue the current short plan or guarantee steady progression. No gameplay or Review coefficients changed.

## Source and method

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; shared dirty worktree preserved. The underlying v9 variant was captured from canonical identity `975b3be9228c938032cce307c8410b4d57d03c77df9880b86f63e325807d05eb`; frozen replay source `52f17193654e59b9a3313b745919a86a8d769f1c667ff491a7f14d802ad04b1d`. Two seed pairs (4417/4418) have equal full legal starting state/RNG within each pair and complete world runs. The [read-only script](2026-10-24-core-output-sensitivity-v1.py) reproduces all 48 actual Reviews with a unique legal variance modifier and then adds a hypothetical +2/+4/+6/+8 to **each of the four final Core values** before the current ratio cap and Review formula. Actual frozen targets, Scope, remaining Bugs, variance, titles and calendar are held fixed. The [machine output](sims/rival-core-output-sensitivity-20261024-v1.json) passes all source/formula checks. This is a scoring sensitivity, not a legal played-card rule; player sales/Fans and runtime CPU cannot be inferred from it.

| Uniform Core points per category | Current 2/2/2: Review mean; 6.0+ /32 | Thirteen-cycle 4/6/2: Review mean; 6.0+ /16 | 4/6/2 first two per studio at 6.0+ /8 | 4/6/2 7.0+ /16 |
| --- | ---: | ---: | ---: | ---: |
| +0 actual | 2.49; 0 | 5.59; 5 | 2 | 1 |
| +2 | 2.84; 0 | 5.96; 9 | 5 | 2 |
| +4 | 3.16; 0 | 6.31; 11 | 6 | 5 |
| +6 | 3.50; 0 | 6.61; 11 | 6 | 6 |
| +8 | 3.82; 0 | 6.90; 11 | 6 | 8 |

The +4 proxy raises the long-plan mean into the 6s, but five of sixteen releases remain below 6.0 even at +8. Those five retain 7–10 Bugs; they require +9 to +14 **in every Core category** under the frozen formula to reach 6.0. The short plan remains at **0/32** 6.0+ even at +8; nine of its 32 releases still miss with a uniform +32. A separate read-only cap check finds seven still miss at +100, where all four ratios are saturated. Scope and Bugs set a ceiling for those seven. These are numerical counterfactuals, not recommendations to add nine or more points.

The first four long-plan Reviews (one per incumbent/seed) are `5.7, 4.5, 5.5, 6.4`; at +4 they become `6.4, 5.2, 6.1, 7.3`. This would improve some openings while leaving one weak. Across the two seeds, only **8 of 12 adjacent release pairs** are nondecreasing at every +0/+2/+4/+6/+8 setting. A constant Core lift preserves the uneven quality trajectory; it does not itself create steady progression. It also does not restore the eight rival publications lost by the thirteen-cycle route by player cycle 56, so the prior measured player-market challenge remains unresolved.

## Disposition

Treat a **small, visible rival production-efficiency rule** as a possible later ingredient, not a standalone fix or a hidden Review award. If tried, apply it to Core produced by actual legal cards, bound its total per project, record it in saved project/release details, and keep the same formula and market targets for player and rivals. Its magnitude and whether incumbents, entrants or later releases receive it remain **OPEN**. First find a legal ≥10-cycle plan that controls residual Bugs and enough actual titles to pressure the market. Then compare a no-bonus control with a modest Core-efficiency candidate under equal starts, market routes and population limits, measuring early and later Reviews, publication density, player sales/cash, checkpoint size and CPU. A completed simulation would still not approve final balance.

No adoption handoff or internal TODO queue entry follows this read-only screen. The first ad hoc Python summary command failed with an unterminated string before reading the output; a PowerShell JSON summary succeeded, and both the original script and output remain unchanged. No simulator process or canonical gameplay source was altered in this follow-up.

## Exact check

```powershell
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' docs/codex/threads/ai-competitors/2026-10-24-core-output-sensitivity-v1.py
```

The script refuses to overwrite its existing output; use a new named output for a new revision. Underlying legal worlds, exact replay and resource limits are recorded in the [v9 finding](2026-10-24-core-review-current-source-finding-v1.md).
