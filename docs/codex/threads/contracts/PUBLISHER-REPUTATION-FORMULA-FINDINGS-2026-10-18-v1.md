# Publisher Reputation formula shape — findings v1

2026-10-18 (America/Los_Angeles). **Completed read-only arithmetic comparison; recommendation is PROPOSED, not approved or implemented.** See the [predeclaration](PUBLISHER-REPUTATION-FORMULA-PLAN-2026-10-18-v1.md), [25-cell grid](PUBLISHER-REPUTATION-GRID-2026-10-18-v1.csv) and [ten verifier-grade projections](PUBLISHER-REPUTATION-PROJECTIONS-2026-10-18-v1.json).

## Exact setup and source

- `main` HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty shared worktree. No canonical or variant project was changed.
- The observed grade inputs are from `docs/codex/findings/queue-20261018-v1/challenges-v3/verify_contract_challenge_matrix.json`, SHA256 `4025887E0BBCD537DC14B5464D07204B39569D9A92BF227A7CBF16B513938B82`; verifier code SHA256 `B77B5F3238016F79795EED5F5FA06AFEEADB2F9CF952D75135417709FC0A4194`. Current challenge and definition source hashes are in the plan. The matrix is a verifier case set, not a legal Relationship Brief campaign.
- Exact command from repository root: `& 'docs/codex/threads/contracts/PUBLISHER-REPUTATION-FORMULA-CALC-2026-10-18-v1.ps1'`. It checked the matrix hash before computing, then audited grade bounds, monotonicity, zero boundaries and maxima. Result: **PASS**, 25 declared grid cells and ten projected verifier cases, with no rejected or timed-out cases. There were no seeds, RNG, game policies, starting saves, release limits or headless processes; this was deterministic arithmetic.
- Outputs: CSV SHA256 `7DEA0B33F2CAC4DF031BF3BE740496921BF3B087DE72CFE4A639DD263B8A99E5`; projection JSON SHA256 `D25F0E5A060E18E491DB038E70CFFF5AB73D7CA3FE55C84FE8980516AB1C5636`.

## Results

All values below use the **illustrative, unapproved** maximum of ten whole reputation points for one new reputation-bearing Contract. `C` is normalized completion and `G` the specific promise grade; both are basis points in `[0,10000]`.

| C | G | `floor(10×min(C,G)/10000)` | `floor(10×C×G/100000000)` | `floor(10×(C+G)/20000)` |
|---:|---:|---:|---:|---:|
| 0 | 10000 | 0 | 0 | 5 |
| 5000 | 5000 | 5 | 2 | 5 |
| 10000 | 0 | 0 | 0 | 5 |
| 10000 | 5000 | 5 | 5 | 7 |
| 10000 | 10000 | 10 | 10 | 10 |

The weakest-score and product formulas both give zero for a missed promise or zero completion. The average violates that intended boundary. Product cuts a dual 50% result to two points; weakest-score grants five and does not penalize the same shortfall twice. All formulas are monotone on the tested grid and give ten for two full grades. Weakest-score has five distinct outputs on this coarse grid, product seven and average nine. Its tradeoff is that improving the stronger axis alone has no effect until it exceeds the weaker axis.

With **hypothetical full completion** (`C=10000`), the ten existing challenge verifier cases project to four full awards of 10, three half awards of 5 under weakest/product (7 under average), and three misses of 0 under weakest/product (5 under average). These are score-shape projections, **not actual reputation outcomes**. The matrix does not contain `C`. Its Neon partial/miss challenge cases remain legally unreachable with the authored pool, and this study did not construct a Relationship Brief or legal route.

## Recommendation for design review

**PROPOSED formula shape:** for a newly accepted, explicitly reputation-bearing publisher Contract, freeze its versioned promise. At one committed completion, calculate `earned = floor(M × min(C,G) / 10000)` where `M` is that type's as-yet-unapproved maximum and both grades are clamped to `[0,10000]`. The award belongs only to the identified publisher; missed promises yield zero new reputation, not a negative balance. A duplicate or uncommitted outcome yields no second award. Current cash-first publisher Contracts, the independent cash brief, existing cash/Promotion rewards and historical completed Contracts earn no Publisher Reputation by default.

The arithmetic supports **the shape only**. Whole-point flooring at illustrative `M=10` loses fractional progress (two 75% briefs give 14 points instead of 15). Before trial adoption, decide whether the ledger stores finer fixed-point units (recommended), then set `M`, starting value, cap, display rounding, offer frequency, any losses and effects. An illustrative 0–100 display and 10-point full award would take ten perfect repeatable briefs to fill the meter; repeatability and that scale are not approved. If the first Relationship Brief is one-time, the progression design needs another earning source or a different scale. Do not choose magnitude from this grid.

## Remaining evidence and decisions

1. A Publishers owner should decide the per-publisher ledger, precision, cap, decay/loss policy, progression effects and old-save migration. Keep it distinct from Studio Prestige and the Founder's `reputation_events`.
2. This Contracts thread should define the first legally reachable Relationship Brief promise, scoring `C/G`, acceptance snapshot, cadence, cash/Promotion interaction and exact committed outcome schema. A new type need not reuse the current challenge grade.
3. After those decisions, build an isolated named candidate version and run legal headless campaigns with matched starts and fresh-process replay; check awards at commit, duplicate handling, zero-grade misses, restore, old saves and unchanged legacy rewards. A later implementing handoff requires an explicit user design ruling and source-pinned acceptance packet. Passing arithmetic or gameplay simulations cannot approve balance.

No shared `TODO.md`, design authority, gameplay source, test, asset or configuration change was made for this formula study.
