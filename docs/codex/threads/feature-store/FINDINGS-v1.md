# Feature Store findings v1 — evidence intake

Date: 2026-10-06 (America/Los_Angeles). **Read-only source and log review; no new simulation.**

## Exact source and scope

- Repository branch `main`, HEAD `2b5717d0de737f77f1b1bc8c1a02da0db9f53942`.
- Inspected branch, HEAD, status, staged and unstaged diff stats before writing. Pre-existing modified gameplay/UI files and untracked docs/analysis were preserved. This thread changed documentation only in `docs/codex/threads/feature-store/`.
- Sources read: `docs/codex/CURRENT_STATE.md`, `TODO.md`, `README.md`, `design/feature-store-progression.md`, `design/genre-specialties.md`, `findings/current-balance-evidence.md`, `patch-notes/scripts/studio_specialties.gd`, `scripts/cards/feature_store_catalog.gd`, and relevant `scripts/run_state.gd` purchase/price/familiarity paths. Reviewed the recent Task 2 retained-pool and Task 24 era logs. No Google Drive read.

## Current rules verified against local authority and source

- Exactly one permanent Genre specialty grants a fixed Primitive roster once. Six common IDs and favored-Core/signature membership are defined in `studio_specialties.gd`; roster totals span 15–19 Features and 24–29 printed Scope across eight specialties. A future similarly tagged card is not automatically granted. Project Genre remains independent.
- Optional unowned Primitive purchases cost `(printed Scope + 1) × $150`: $300/$450/$600 at Scope 1/2/3. During initial selection they cost zero cycles; after departure they cost one productive cycle. Primitive Design/Alpha play fees are `$10 × (primary + secondary + 2 × Scope)`; Passes cost zero.
- Later Store nodes use permanent ownership and current parent/Gameplay-count unlocks. A successful purchase spends one productive cycle through the central transaction. Browsing, failed and duplicate purchases do not create a purchase. Parent familiarity comes from eligible committed project use once per project/ID; up to five parent credits reduce eligible child prices by 10% each, maximum 50%. Runtime does not charge a later-class play fee; that boundary is not approval of a free future card.
- Calendar years 1984/1990/2000/2010/2020/2026 correspond to cycles 96/240/480/720/960/1104 and are a necessary direction for later-era availability. Complementary qualifying-release/milestone numbers, multi-parent and three-Core mechanics, platform rules, new cards/prices, and later-card play fees are OPEN. The 97-node proposal is incomplete as local implementation authority.

## Evidence and limits

- Task 2 retained-pool rebaseline: 304 native routes, 810 releases; two seeds and prescribed production budgets. Candidate Background Music and Sub-Areas raised Game 2 Review among surviving routes, while early purchase timing often damaged liquidity and later-release access. Those cards and $950/$1,700 center prices are analysis candidates, absent from live catalog. Shopping eligibility, purchase, draw, and play must be measured separately.
- Task 24 calendar-era study modeled future access; no era-count or node number was approved. Its proposed count sequence `[1, 3, 6, 10, 14]` is a trial recommendation, not a rule.
- The older Task 2 Alpha-exit defect now has a local deterministic blocked/recovery verification described in `docs/codex/logs/2026-10-06-campaign-pool-ui-v1.md`; the historical shopping study was not rerun on this HEAD. No human route, current export, or full new Store simulation is claimed here.
- The current $500 monthly rent, $5,500 base plus genuine optional $200 unused-point financing receipt, actual settled portfolio cash, and one-cycle opportunity cost govern future comparisons. Do not reinterpret pre-rent or old starter-cap studies as the current baseline.

## Recommendation

Resolve a bounded next-catalog specification before any implementation task: exact node definitions, prerequisites, prices, play fees, and visibility. Then test the purchase-timing question with a predeclared rent buffer and parent-chain cost on a stable source snapshot. Keep all new values OPEN until an explicit design ruling.
