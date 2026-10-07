# Feature Store findings v3 — first expansion shortlist

Date: 2026-10-06 (America/Los_Angeles). **Read-only static source comparison and historical evidence review.** No new gameplay simulation, code, test, asset, config, or shared To Do List change.

## Exact source snapshot and method

- Branch `main`, HEAD `2b5717d0de737f77f1b1bc8c1a02da0db9f53942`. Existing uncommitted UI/Alpha/RunState changes remain in place. The historical studies below used earlier snapshots; this finding does not call them a current-source rerun.
- SHA-256 on inspected files: `card_ledger.json` `0F093B0BA907043120C3E6E529511322E6E0B99358ADF6D69C80D5C174CFC83C`; `feature_store_ledger.json` `547A1CBC408AC263F3CF3C3A9E96E8667F33993E211BBB492937716C7DF414CF`; `studio_specialties.gd` `D617066C2585DA1AB9C59D0C3CE3EBB20406A3136EFFCA337231EEFA01FFEBDF`; current `run_state.gd` `DDAE87856F7D5BD4DBBD424A9774E6DEB420390A1CE6A9CA384E98F0A9F33B84`; analysis catalog `feature_store_stage2_v1_catalog.json` `70FDE3A5734975D2CA9DCC48732E61BF5A3A21E8C5F188CF88DCCA43DCB90F03`.
- Read current data/source directly and recomputed the eight starter rosters from the six common IDs, favored-Core membership and signature IDs in `studio_specialties.gd`. Recomputed count/Scope pairs exactly match the locked roster table (Action 18/29, Adventure 19/26, Role-Playing 19/27, Strategy 17/26, Simulation 16/24, Puzzle 19/27, Sports 15/24, Racing 16/26).
- Trial node definitions came from the tracked analysis catalog, which labels them `ledger_authored`. Neither ID appears in the two live JSON ledgers. Candidate quote arithmetic below applies the current singular-parent discount formula to the historical center trial base price. It is a static conditional quote, not a playable purchase result.

## Candidate definitions and prerequisite reach

| Candidate | Authored printed definition | Parent and current automatic reach | Historical center price / analogue play fee | Capability boundary |
|---|---|---|---|---|
| **Sub-Areas** (`sub_areas`) | Alpha, World Design, Graphics 3 primary, Design 2 secondary, Scope 2, finite. | `levels`; Levels is granted by Action, Adventure, Role-Playing, Puzzle and Racing (5/8 specialties). Other specialties may buy Levels as a Primitive reserve for $450. | $1,700 / $90 per play as a sensitivity. Both **OPEN**. | One parent, two Core fields, no direct platform tag in the supplied catalog: representable by current schema if approved. It is absent from live supply. |
| **Background Music** (`background_music`) | Alpha, Audio, Sound 3 primary, Scope 1, finite. | `music`; Music is granted by Sports (1/8). Other specialties may buy Music as a Primitive reserve for $450. | $950 / $50 per play as a sensitivity. Both **OPEN**. | One parent, one Core field, no direct platform tag in the supplied catalog: representable by current schema if approved. It is absent from live supply. |

**Design identity:** live Levels is itself Alpha Graphics 3 / Design 2 / Scope 2. Sub-Areas repeats those exact printed values as a distinct finite Feature ID. Its proposed contribution is more access to that stat mix through a separate card in later projects, not a new stat shape. Retain the authored values in analysis; any differentiation needs an explicit design ruling. Background Music differs from its parent Music (Alpha Sound 7 / Scope 2).

## Conditional center-price quote, not an approved price

Current Store quote gives 10% off per distinct-project parent familiarity credit, capped at five credits/50%. Ownership alone gives zero credits. A missing Primitive parent costs $450 and one productive cycle after first-project departure; the candidate child would then cost a separate productive cycle. Parent purchase does not refund if the child later fails.

| Parent credits | Sub-Areas child at trial $1,700 | Background Music child at trial $950 |
|---:|---:|---:|
| 0 | $1,700 | $950 |
| 1 | $1,530 | $855 |
| 2 | $1,360 | $760 |
| 3 | $1,190 | $665 |
| 4 | $1,020 | $570 |
| 5+ | $850 | $475 |

With no parent owned and zero familiarity, the conditional full-chain quoted cash is $2,150 for Sub-Areas or $1,400 for Background Music, and each requires two productive purchases after departure. With the parent already owned, only the child purchase cycle is needed. These totals omit rent, ordinary development/play costs, and sales settlement on those cycles, so they are not affordability guarantees. The current Store spending advice is advisory and does not fully reserve missing ancestors.

## Historical outcome and interpretation

- The [staged read-only findings](https://drive.google.com/file/d/1bCo76oQnQqiTQROsPSg-LQIJhchmju1p/view) tested these as process-local cards on an older `608a2c6` source. A small 12-case screen reported whole-route Game 2 Review changes of +0.21 for Sub-Areas and +0.44 for Background Music at zero candidate play fee, with terminal cash lower by $1,099.17 and $726.43 respectively. Price/fee sensitivities were small and partly confounded by whether purchases crossed the policy's spending threshold. These are not intrinsic card effects or current-baseline estimates.
- The newer [retained-pool Task 2 rebaseline](https://drive.google.com/file/d/1yhZsWWijgNHXa1BELkgNt_b9Lj3n8O3X/view) used specialty starts and current rent on historical `e054791` plus pending retention. Among routes surviving to Game 2 release, matched Review gains were +0.277 for Sub-Areas (22 survivors) and +0.404 for Background Music (23). Game 4 completion was 4/32 and 3/32 for their immediate-buy arms versus 28/32 control. Early cash/timing and selection policy confound those comparisons; they do not justify a price or claim that the cards are harmful in every purchase window.
- A local Alpha free-exit repair now changes an affected blocked route, but the broad Store cohort has not been rerun. The parallel Feature Pools folder already owns a proposed repaired-source immediate/full-chain-reserve/deferred shopping trial. Its result is the appropriate next economics evidence.

## Recommendation for review — candidate only

Prepare **Sub-Areas as the first single-node design pilot**, preserving its authored printed values and making its duplicate-of-Levels role explicit. Study its purchase after a genuine settled-cash buffer and compare parent-owned versus parent-missing specialties. Keep **Background Music as a separate Audio pilot** so Sound-focus and rarer automatic Music ownership are measured independently. Do not pair-launch them from the old immediate-buy evidence.

Before any implementation handoff, rule explicitly on (1) whether Sub-Areas should intentionally duplicate Levels' printed stats, (2) exact base price and later-card play fee, (3) first-era eligibility and player-facing prerequisite/quote information, and (4) whether the new node remains outside the fixed Primitive Contract pool. For the read-only rerun, preserve both candidate IDs and authored effects without elevating center prices to approval. No broader 97-node or later-era unlock decision follows from this shortlist.

Limits: static roster/quote checks only on the stated source hashes; no native candidate purchase, draw, play, current-source balance rerun, human playtest, or artwork/UI review. Historical cohort counts, policies and survivor bias remain material.
