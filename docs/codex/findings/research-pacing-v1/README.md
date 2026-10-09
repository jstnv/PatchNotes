# Feature research pacing — bounded findings, 2026-10-08

**Handoff004 complete at its read-only scope.** No gameplay or balance values changed. Source: main `91ce539978b87ac0a6efe3a1e028cae5f1360f19` plus the exact dirty-source hashes in `source-manifest.json`; isolated copy shared with the Starwave screen, before the later startup recovery edit. [Predeclaration](PLAN.md), [80 route definitions](route-manifest.json), [independent audit and per-route/calendar results](audit-summary.json).

## Results

| Acquisition policy | Routes | Reached three launches | Obtained target(s) | Played target(s) | Ended with arrears |
|---|---:|---:|---:|---:|---:|
| None | 16 | 14 | 0 | 0 | 0 |
| Historical instant purchase, current economy | 16 | 11 | 15 | 15 | 4 |
| Immediate admission and Research | 16 | 6 | 10 | 10 | 9 |
| Admission now, Research after stronger settled release | 16 | 7 | 7 | 4 | 6 |
| Two-entry FIFO, front-loaded admissions | 8 | 2 | 3 | 3 | 4 |
| Two-entry sequential admission/Research | 8 | 4 | 8 | 8 | 4 |

“Reached three launches” includes curtailed legal launches after a first blocked hand; it does not imply three fully developed games. Acquisition failures remain in the denominator. The two no-acquisition target labels are duplicate controls within each cohort/policy/seed, so 16 rows represent eight distinct baseline routes, not 16 independent samples. These are fixed policies, not estimated player failure rates.

| Genuine start / production policy | None | Instant | Immediate Research | Deferred Research |
|---|---:|---:|---:|---:|
| $5,500 / ordinary | 2/4 | 1/4 | 0/4 | 0/4 |
| $5,500 / synergy | 4/4 | 4/4 | 3/4 | 3/4 |
| $5,700 / ordinary | 4/4 | 2/4 | 0/4 | 1/4 |
| $5,700 / synergy | 4/4 | 4/4 | 3/4 | 3/4 |

The table reports three-launch reachability. The ordinary $5,500 seed1104 no-acquisition control stops during development at cycle31 with $183.14 and no overdue bills: lack of affordable next action and arrears are different outcomes. Per-route first blockers, cash lows, exact common-calendar cash/settlement/arrears differences and project progress are retained in the audit summary. No blocked run is extended with invented waiting or funding.

## Interpretation and recommendation

Immediate research makes the early cash constraint materially tighter in this sample. The new down payment is based on the undiscounted base; only the remaining installment receives familiarity discounts. Both old instant purchase and live one-action Research cost one productive cycle, but their cash charge and ownership timing differ. Deferring only Research still ties up the irreversible down payment early and supplies no card until completion. That policy therefore does not reliably solve early pressure. A stronger release can qualify during development; shopping waits for the next Studio visit, preserving legal access.

Front-loading two admissions is especially restrictive: it obtains either target in 3/8 runs, versus 8/8 sequentially. Even with current one-action nodes, FIFO and upfront cash create real ordering consequences. Keep the queue's approved correctness rules; **do not call its pacing balanced or introduce a mandatory reserve from this screen**. Present the down payment and incomplete ownership clearly, and take a separate design ruling before changing acquisition prices, duration or fees. A future question would be delaying admission itself until settlement; that policy was not silently substituted into this commissioned comparison.

## Verification and limits

All80 Godot commands exit0 with no unclassified errors. `audit.py` passes **43,635 independent checks**, including pinned source, genuine initial funding, journal continuity, monthly cash/profit, due/paid/unpaid bills, settlement totals, exact admission/installment charges, atomic rejected shopping, acquisition RNG neutrality, FIFO head, stronger-title positive actual settlement, ownership/supply and pre-purchase Game1 draw/selection matching. One audit implementation correction used per-title sales records rather than assuming the aggregate finance journal carries a release ID; game traces were unchanged.

Reproduce from this folder with `run.py`, then `audit.py` using Python; Godot4.7.1 and the pinned copy are declared in the runner. Every `.command.json`, `.log` and compressed `.json.gz` trace is retained. The instant adapter copies the former transaction semantics into the isolated harness and uses current native finance; it is not a live queue entry or a save-compatibility test. Policies share pre-purchase production; later changed ownership changes draws and choices legitimately. Common-calendar comparisons stop at the last shared observed cycle and do not equate unequal work progress.

Coverage: two seeds, Action, ordinary/synergy, genuine $5,500/$5,700 starts; Text→Colored Text and 8-bit Sound→Recorded Sounds (costlier path, both parents owned); three releases plus up to two Game4 Design hands. No parent-missing specialty, new card, employee, Contract or loan in these routes. Longer-term balance, broader Genres, real player preference and mandatory buying rules remain outside this result.
