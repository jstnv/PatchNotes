# Feature Store findings v11 — Sub-Areas lower-price sensitivity

Date: 2026-10-06 (America/Los_Angeles). **Read-only native comparison; candidate prices and cash floors remain OPEN.** The user accepted the [reserve-screen recommendation](FINDINGS-v10-sub-areas-reserve-screen.md) to continue the design analysis here.

## Exact source and method

Predeclared on branch `main` at HEAD `553d1a46f33d59641efa4c2e4ff141f958c1230d`. A concurrent documentation commit advanced HEAD to `b84d1a5b4e4957b044b4b52c41553cf611aff3ae` while routes ran. The [predeclaration](sim-v9/predeclaration.json) and [run report](sim-v9/run-report.json) verify that **all 593 tracked gameplay/source file SHA-256 hashes were identical before/after and exactly matched the previous `sim-v8` controls**; `git diff` between those commits under `patch-notes` was empty. The concurrent commit was not initiated by this design session. Godot 4.7.1 used a process-local driver and shadow card; no gameplay source, catalog, tests, assets or configuration was edited here.

Native Strategy matrix: seeds 1104/4417/2203 × ordinary/synergy policies × genuine current trait-flow $5,700 and legacy no-trait $5,500 startups × **candidate $1,200/$1,450** base × **experimental $500/$1,000 post-quote floors** = 48 new routes. Each can buy after Game 3 or, if still unowned and financially eligible, after Game 4. Pair to the exact native no-buy and $1,700/$1,000-floor routes from [the earlier reserve screen](FINDINGS-v10-sub-areas-reserve-screen.md), whose source hashes match. Keep approved independent Store-only card identity (Alpha World Design Graphics 3 / Design 2 / Scope 2), no Levels discount, one-cycle purchase, $500 rent, exact-cent portfolio settlements, finite retained hands and current Ironclad/SideStreet. Candidate later-card play fee is $0 in native source; $90 remains untested. No loans, campaigns, injected income or free waits. Five-release horizon or first legal financial block.

## Paired results

All 48 new routes exited 0/valid. Each row below has six distinct seed/policy routes per startup. “Clean” means bought and committed Sub-Areas, with no extra arrears or earlier financial block versus its own no-buy control. It does **not** mean financial payback.

| Startup | Candidate quote | Post-quote floor | Buyers / 6 | Clean played buyers / 6 | Extra-arrears / earlier-block routes |
|---|---:|---:|---:|---:|---:|
| $5,700 current | $1,700 | $1,000 | 1 | 1 | 0 / 0 |
| $5,700 current | $1,450 | $1,000 | 1 | 1 | 0 / 0 |
| $5,700 current | **$1,200** | **$1,000** | **2** | **2** | **0 / 0** |
| $5,700 current | $1,450 | $500 | 3 | 2 | 1 / 1 |
| $5,700 current | $1,200 | $500 | 4 | 3 | 1 / 1 |
| $5,500 legacy | $1,700 | $1,000 | 1 | 1 | 0 / 0 |
| $5,500 legacy | $1,450 | $1,000 | 1 | 1 | 0 / 0 |
| $5,500 legacy | $1,200 | $1,000 | 1 | 1 | 0 / 0 |
| $5,500 legacy | $1,450 | $500 | 1 | 1 | 0 / 0 |
| $5,500 legacy | $1,200 | $500 | 2 | 1 | 1 / 1 |

At **$1,200/$1,000** the new clean buyer is current-flow seed 1104/ordinary. It waits until after Game 4, buys with $1,103.09 left, draws and commits the card in Game 5, and finishes with $354.13 cash/no arrears versus $1,554.13/no arrears in its no-buy control. Game 5 Review improves 5.5→6.0, but the purchase has **not paid back in cash by Game 5 launch**; Game 5 sales are still unsettled. The other clean buyer is seed 1104/synergy in both startup ledgers, already accessible at $1,700/$1,000. At $1,200 its Game 4 Review improves 4.7→5.3, Game 5 Review 5.2→6.8, and actual equal-age Game 4 settled net improves only $20.98; it still has $325.88 less cash than no-buy at Game 5 launch. The repeated startup version is the same underlying seed/policy, not independent replication.

The lighter $500 floor gains access but does not pass the approved downside gate. Current-flow 2203/synergy buys at $1,200 and stops after Game 4 with **$270.22 extra arrears**; at $1,450 it stops with **$34.21 extra**. Legacy 2203/synergy buys at $1,200 and stops with **$470.22 extra arrears**. These are earlier blocks than their matched no-buy controls. Current-flow 4417/ordinary at $1,200/$500 is a clean buyer and plays in Games 4–5, but the 2203 downside prevents recommending that floor as a general rule. The $1,450/$1,000 arm does not improve buyer reach over $1,700/$1,000 on these routes.

[Exact paired rows](sim-v9/summary.csv) record purchase stage/quote, supply/draw/committed play, release timing/Review/Scope, actual Game 4 equal-age settled net, matched-calendar cash, Game 5 launch cash, arrears/credit and baseline comparison. [Aggregates](sim-v9/aggregate.json) retain denominators. A $5,500 no-buy route already blocks after Game 2 and another has arrears without buying; “no extra” is strictly relative to each control, not universal solvency.

## Verification, recommendation and limits

`sim-v9/audit.py` passed **48/48** raw trace hashes, source/driver stability, correct genuine startup funding, exact process-local prices/no-parent quotes, native finance/ledger reconciliation and zero candidate Contract hits. It counted **15 purchases and 25 committed plays**. `sim-v9/analyze.py` asserted identical pre-purchase release prefixes and no-buy-equivalent terminal cash for abstainers. The runner reported zero tracked gameplay/source changes across the concurrent HEAD advance. No shared To Do List or implementation authority was edited by this session.

**Recommendation:** retain **$1,200 with a $1,000 post-quote floor only as the leading bounded research arm**, because it modestly improves harm-free access versus the $1,700 center without an observed added block. Do **not** approve the price or floor for gameplay: the gain is one additional independent current-flow route, cash is still below control at Game 5 launch, and the proposed $90 play fee has not been applied natively. Test Game 5 actual settlement and behavior-faithful paid play on this arm (with no-buy and $1,700 comparators) before ruling on price, play fee or first-era availability. The $500-floor arms expose a concrete downside and should not be recommended as general purchase advice from this sample.

Limits: three seeds, Strategy only, two action policies, two startup ledgers, two prices and two floor probes. Shop opportunities are fixed to after Games 3/4. Game 5 settled sales, Action/live-node controls, Background Music's parent chain and full shared Task 2 historical Alpha case remain untested here. This does not complete Task 2 or grant implementation approval.
