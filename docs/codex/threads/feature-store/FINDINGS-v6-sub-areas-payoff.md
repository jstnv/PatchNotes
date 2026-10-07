# Feature Store findings v6 — Sub-Areas payoff through Game 5

Date: 2026-10-06 (America/Los_Angeles). **Read-only native follow-through and proposed economic scorecard.** The Sub-Areas duplicate printed identity is approved for a bounded design pilot; its price, fee, purchase trigger, parent semantics, rollout and implementation remain **OPEN**.

## Exact source and setup

- Branch `main`, HEAD `553d1a46f33d59641efa4c2e4ff141f958c1230d` before and after. [Predeclaration](sim-v4/predeclaration.json) records 593 tracked source hashes and driver SHA-256 `9c117f1a16e5251e4d24e4eb462ba1b8427b037a65db6eb01fbd14d864b9f7b1`. Examples: `scripts/phases/alpha_phase.gd` `81a1d9b591d42e1863231de614c7def5d3b6443ba4bdfce612761c2558cca903`; `scripts/run_state.gd` `ddae87856f7d5bd4dbbd424a9774e6deb420390a1ce6a9ca384e98f0a9f33b84`; `data/card_ledger.json` `0f093b0ba907043120c3e6e529511322e6e0b99358adf6d69c80d5c174cfc83c`; `data/feature_store_ledger.json` `547a1cbc408ac263f3cf3c3a9e96e8667f33993e211bbb492937716c7df414cf`. [Run report](sim-v4/run-report.json) retains exact commands, isolated profiles, exits, route hashes and unchanged tracked-source comparison.
- Eight paired Action routes: seeds 1104/4417 × ordinary/synergy × no purchase or analysis-only Sub-Areas bought after the [v5 settled-stronger trigger](FINDINGS-v5-timing-pilot.md). Both arms run through five native releases or first legal block. Game 1 uses the early budget; later games use 18-action budgets. Ironclad and eligible SideStreet use native actions. Current trait creation supplies genuine $5,700 startup cash; $500 monthly rent and exact-cent all-title earned/settled sales run natively. No borrowing, campaigns, free waits, or injected income.
- The process-local `sub_areas` shadow has approved-for-pilot printed Alpha World Design Graphics 3 / Design 2 / Scope 2, and analysis-catalog Levels parent. The $1,700 base and resulting $1,190 Game 3 quote are **trial values**. Current runtime charges $0 later-card play fee in these runs; proposed $90 per play was **not** simulated. This study cannot set price or prove affordability under a paid fee.
- The [summary](sim-v4/summary.csv) reports release cycles/Reviews, actual purchase/play, cash at a **common calendar checkpoint** four cycles after the later Game 4 launch (cycle 73 for these pairs), Game 4 per-title settled net at that checkpoint and at matched title age, and cash at each Game 5 launch. The launch milestones differ by three cycles, so final cash alone is not a matched-calendar comparison.

## Native paired results

All eight routes reached Game 5 with no unpaid rent or financial block. The four trial arms bought Sub-Areas at cycle 51 after Game 3 for a $1,190 trial quote; all supplied, drew and committed it in **both** Games 4 and 5. Their Game 4 launch moved from cycle 68 to 69 and Game 5 launch from cycle 86 to 89. The extra three cycles include the Store purchase and subsequent route timing; they should not be called pure Store cost.

| Seed / policy | Game 4 Review control → trial | Game 5 Review control → trial | Cash difference at common cycle 73 | Game 4 settled-net difference at cycle 73 | Cash difference at respective Game 5 launches |
|---|---:|---:|---:|---:|---:|
| 1104 / ordinary | 7.0 → 8.4 | 6.9 → 7.9 | +$731.50 | +$496.50 | +$2,447.03 |
| 1104 / synergy | 7.3 → 7.8 | 7.1 → 7.9 | −$113.67 | −$328.67 | +$566.96 |
| 4417 / ordinary | 6.1 → 5.9 | 7.8 → 7.6 | −$610.17 | −$825.17 | −$979.68 |
| 4417 / synergy | 7.9 → 8.3 | 7.7 → 8.1 | −$354.00 | −$496.50 | +$339.56 |

The Game 4 settled-net comparison at equal title age (four productive cycles after each Game 4 launch) has the same signs and differences as the common-cycle column here. By Game 5 launch, Game 4 cumulative settled-net differences are +$2,972.03, +$1,041.96, −$314.68 and +$937.06 respectively, but those launches occur at different calendar cycles. Cash, rent, other titles' settlement, card plays and decisions all affect the overall cash difference. A card play does **not** guarantee better Review or sales: seed 4417/ordinary was worse on both.

## Proposed payoff scorecard — not yet a numerical rule

For a bounded Store pilot, assess **three separate questions** instead of using Review alone:

1. **Legal access and solvency (required):** the purchased card reaches next-project supply, is drawn and committed at least once within two projects, and the route reaches the next release without extra arrears or an earlier financial block versus its paired control. Record any parent-chain purchase and its cycles separately.
2. **Quality and realized sales:** report both next-project Reviews/Scope and the candidate-influenced title's **actual settled net sales** at equal title age and a matched calendar checkpoint. A higher Review with lower realized sales is a mixed result, not an automatic win.
3. **Cash payback and risk:** compare net cash at matched calendar checkpoints and at the same release-count milestone, including purchase/play fees, extra rent and calendar delay. A **strong cash-payback case** has nonnegative paired cash by Game 5 launch with no solvency regression; show the matched-calendar deficit or surplus alongside it. Track the fraction of seeds with adverse outcomes before any price or fee ruling.

Under this proposed scorecard, all four trial routes passed the narrow solvency/access gate, but only **three of four** improved Game 4/5 Review and showed nonnegative cash by Game 5 launch. Only **one of four** had more cash at the common cycle-73 checkpoint. The sample is too small to set a success-rate threshold or claim the $1,700 base/$90 play fee is fair. The observation supports Sub-Areas as an **optional late-buy candidate** and argues against a universal purchase recommendation.

## Verification and limits

The [audit](sim-v4/audit.py) passed: 8/8 Godot exit 0 and valid, zero route errors/discrepancies, eight raw-trace hashes, genuine startup cash, five releases, exact final finance cash equality, nonzero native ledger/row checks, purchase/play in Games 4 and 5, unchanged HEAD/driver and no tracked source changes. Raw compressed traces and per-route logs are in [sim-v4](sim-v4/). `git diff --check` exited 0; unrelated concurrent files emitted line-ending warnings.

Limits: two seeds, one specialty, two policies, $5,700 start only, zero later-card play fee, four-to-five-game horizon, analysis-only card, no parent-missing route or current live-node control. The Game 5 launch cash comparison is a milestone view with different calendar cycles; the common cycle-73 comparison is phase-dependent. Store purchase, hand composition, RNG, release quality and all-title settlement vary together. The broader shared Task 2 read-only rerun remains incomplete. **Recommendation:** use this scorecard for that rerun, then decide whether the paid later-card fee and base price retain enough upside without early liquidity failure. Do not add Sub-Areas to live gameplay from this finding.
