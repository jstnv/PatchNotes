# Feature Store findings v10 — Sub-Areas cash-floor screen

Date: 2026-10-06 (America/Los_Angeles). **Read-only native evidence; no reserve, price, fee, unlock or gameplay rule approved.** The user asked to run the reserve comparison in this design thread before another shared To Do List update.

## Exact source, assumptions and method

Branch `main`, HEAD `553d1a46f33d59641efa4c2e4ff141f958c1230d` before and after. [Predeclaration](sim-v8/predeclaration.json) records the 48 jobs, 593 tracked-source SHA-256 hashes and process-local driver hash. [Run report](sim-v8/run-report.json) records Godot 4.7.1 commands, isolated profiles, each raw-trace hash, exits and zero tracked source changes. No gameplay source, ledger, test, asset or configuration changed.

Strategy is the specialty where previous independent Sub-Areas buyers encountered the liquidity problem. Matrix: seeds 1104/4417/2203 × ordinary/synergy policies × genuine current MainMenu trait-flow **$5,700** versus current `RunState.set_studio_name` legacy no-trait **$5,500** × four arms = **48 five-release native routes** or first legal block. Each group has its own native no-buy control. The bounded pilot card remains independent, Store-only, printed Alpha World Design Graphics 3 / Design 2 / Scope 2, process-local at the **candidate $1,700** quote with zero native later-card play fee. Current $500 monthly rent, one-cycle purchase, finite retained hands, Ironclad/eligible SideStreet and actual exact-cent portfolio sales settlements all run normally. No loans, campaigns, invented cash, free waits or card-catalog edit.

Policy arms: (1) no buy; (2) quote-only purchase opportunity after Game 3; (3) first after-Game-3-or-Game-4 opportunity with at least **$1,000 left after the quoted price** and no already-unpaid rent; (4) same with **$5,000 left**. The $5,000 floor is a conservative proxy for roughly nine months of rent plus $500 action headroom, **not** an exact project-cost forecast or guarantee. These cash floors are analysis probes, not proposed automatic shopping behavior. A failed affordability check can be retried after Game 4 in guarded arms.

## Native results

All 48 traces exited 0 and passed the finance and source audit. The table counts six matched routes per startup ledger. A “clean played buyer” acquired and committed the card, reached at least as far as its no-buy control and added no arrears; it is **not** a payback claim.

| Startup | Policy | Buyers / 6 | Played buyers / 6 | Clean played buyers / 6 | Extra-arrears / earlier-block routes | Five-release routes / 6 |
|---|---|---:|---:|---:|---:|---:|
| $5,700 current | No buy | 0 | 0 | 0 | 0 / 0 | 6 |
| $5,700 current | Quote after Game 3 | 4 | 4 | 2 | 2 / 2 | 4 |
| $5,700 current | $1,000 post-quote floor | 1 | 1 | 1 | 0 / 0 | 6 |
| $5,700 current | $5,000 post-quote floor | 0 | 0 | 0 | 0 / 0 | 6 |
| $5,500 legacy | No buy | 0 | 0 | 0 | 0 / 0 | 5 |
| $5,500 legacy | Quote after Game 3 | 2 | 2 | 1 | 1 / 1 | 4 |
| $5,500 legacy | $1,000 post-quote floor | 1 | 1 | 1 | 0 / 0 | 5 |
| $5,500 legacy | $5,000 post-quote floor | 0 | 0 | 0 | 0 / 0 | 5 |

The **same seed 1104/synergy route** is the only $1,000-floor buyer in each startup ledger. It buys after Game 3, supplies/draws/commits Sub-Areas in Games 4 and 5 and adds no arrears. Its Game 4 Review improves 4.7→5.3 and Game 5 Review 5.2→6.8 against the paired no-buy route; actual Game 4 net settled at equal title age improves only **$20.98** ($4,650.34→$4,671.32). At Game 5 launch it still has **$825.88 less cash** than control in both startups. Game 5 sales have not yet settled, so realized payback remains unknown. The two startup variants are not independent seeds.

Quote-only buying exposes the downside: at the $5,700 start, seed 4417/ordinary and 2203/synergy both buy and play but stop after Game 4 with extra unpaid rent ($315.58 and $284.21 respectively). At the $5,500 start, 2203/synergy buys and plays but stops with $444.21 extra unpaid rent. The legacy 1104/ordinary no-buy control itself blocks after Game 2 with $7.38 arrears; legacy 4417/synergy reaches five releases with $163.18 arrears **without buying**. Thus a guarded arm matching its control does not prove the whole economy is healthy. [Exact paired rows](sim-v8/summary.csv) include decision cash, quote/purchase timing, supply/draw/play, Review, actual Game 4 settled net, matched-calendar cash, Game 5 launch cash, arrears, credit and blockers. [Aggregates](sim-v8/aggregate.json) retain denominators.

## Verification, interpretation and next experiment

`sim-v8/audit.py` passed **48/48** raw SHA-256 traces, unchanged driver/source hashes, genuine distinct startup ledgers, native quote/no-parent checks, exact cash/finance reconciliation, nonzero ledger/row checks and zero candidate Contract hits. It counted **8 actual purchases and 13 committed plays**. `sim-v8/analyze.py` generated the paired table, asserted identical pre-purchase release prefixes and exact no-buy-equivalent endings for nonbuyers. All selected candidate plays followed legal purchases. No shared To Do List edit or implementation occurred.

**Recommendation:** reject quote affordability alone as purchase advice at this trial price. The $1,000 floor screened out added financial failures in these routes but allowed card use in only **one of six distinct seed/policy cases**; the $5,000 floor allowed none. Do **not** approve either floor or a fixed first-era purchase date. Next run a narrow, predeclared **native lower-price sensitivity** at the same independent card identity and matched controls, retaining the $1,000-floor and a lighter-access comparison. This tests whether price, rather than calendar timing alone, can improve safe access; $1,200/$1,450/$1,700 are study values only. Alternatively defer the card if safe purchase remains rare. Keep the proposed paid-play fee and availability ruling after price/access evidence.

Limits: three seeds, Strategy only, two policies, two startup modes, fixed shopping opportunities after Games 3/4, candidate fee $0 and five-release horizon. The $5,000 proxy ignores future title sales uncertainty and exact action-cost variance. Game 5 realized sales are absent. This is a focused design-thread screen, **not** completion of shared Task 2's full cross-specialty/Background Music/live-node and historical repaired-Alpha comparison; do not mark that queue entry complete from these results.
