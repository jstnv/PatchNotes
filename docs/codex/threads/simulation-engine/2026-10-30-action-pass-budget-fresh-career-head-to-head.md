# Action Pass Budget fresh-career head-to-head — 2026-10-30

**Status: RESEARCH / inconclusive.** No formula is approved. No canonical gameplay or project Scope requirement was changed.

## Setup

- Five paired seeds: 4417, 1104, 90210, 7, 20261030. Each arm starts from the same fresh Action Studio recipe for its seed, with no Studio traits. Target: eight full releases; cap: 500 policy commands.
- Arms: `1 + floor(printed Feature Core / 6)`, `2 + floor(printed Feature Core / 8)`, and generous reference `1 + floor(printed Feature Core / 5)`. Design and Alpha budgets reset independently and generate on Feature play. Passes spend one budget; candidates respect remaining budget. All other source and policy code is identical across arms.
- The common career policy makes legal starter purchases while retaining 400,000 cents, may take a public Bank quote and Ironclad contract, admits/researches Store Features only with a 650,000-cent reserve, chooses visible Feature/Pass hands with existing synergy helpers, and performs Beta QA. It uses ordinary weighted candidate draws, normal cash/calendar, Scope, Bugs, sales and reviews. It is one declared policy, not optimal career play.
- Isolated simulator variant: `simulators/action-pass-budget-career-20261030-v4`. Canonical baseline identity `b92167043abdfedb734455656510bdad5a0211b98ac14331294b2a27715eb396`; candidate identity `ea6313b477ac00a19d7c25c397a654138721e31083a96787b2c91a423a956154`; no baseline drift. The baseline was copied to a hash-matched read-only mirror to avoid a very slow shared-worktree status scan; variant provenance records this.
- Retained bundle: `sims/action-pass-career-matched-v4-20261030-h`. The first Godot experiment process terminated with Windows code `0x40010004` after four case results. The remaining eleven cases ran in four smaller groups against the **same imported snapshot** and isolated profile; the grouped reports and traces are retained. `action-pass-career-combined.json` records all 15 results.

## Results

| Formula | Releases across five careers | Mean releases | Mean review across releases | Highest review | Highest Scope | Careers reaching 30 Scope | Careers reaching 8.0 | Eight-release careers |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 1/K6 | 24 | 4.8 | 1.72 | 2.3 | 18 | 0/5 | 0/5 | 0/5 |
| 2/K8 | 26 | 5.2 | 1.69 | 2.3 | 18 | 0/5 | 0/5 | 0/5 |
| 1/K5 | 24 | 4.8 | 1.67 | 2.3 | 18 | 0/5 | 0/5 | 0/5 |

| Seed | 1/K6 releases | 2/K8 releases | 1/K5 releases |
|---|---:|---:|---:|
| 4417 | 4 | 4 | 5 |
| 1104 | 4 | 5 | 4 |
| 90210 | 4 | 6 | 5 |
| 7 | 6 | 6 | 5 |
| 20261030 | 6 | 5 | 5 |

All careers owned at most 13 Features and played at most 18 Scope, versus the unchanged 30-Scope project requirement. No career admitted a Store Feature under this cash policy. All 15 ended in a cash-related rejected action: unaffordable hand, inability to begin development, or inability to advance the calendar safely. The higher 2/K8 release count is a two-release difference across five seeds, with no middle or optimized career exposure and no corresponding higher mean review. It is insufficient evidence of healthier progression.

## Interpretation and next experiment

**No winner is established.** This full-career test covers only low-Scope early play. It cannot compare middle play or the 24-Feature optimized build, because cash and Feature acquisition prevented those states. The previously retained conditional post-Feature draw screen favored 1/K6 over 2/K8 at the optimized checkpoint (4.963% versus 2.316% reaching 8.0 over 100,000 paired draws), but it forced the 24-Feature build and excluded career economics. The two studies address different conditions and cannot be combined into an overall win rate.

A decision-quality head-to-head needs a common, validated fresh-career policy that reaches 30 Scope and eventually the 24-Feature Action build through normal purchases, or a separately labeled legal checkpoint experiment for middle and optimized play. It should also use more paired seeds and trace Pass activations by phase. Preserve current 30-Scope rules and do not implement any budget formula from this result.

## Reproduction and boundaries

- Config: `action-pass-career-matched-2026-10-30.json`.
- Summary script: `node docs/codex/threads/simulation-engine/combine_action_pass_careers.mjs docs/codex/threads/simulation-engine/sims/action-pass-career-matched-v4-20261030-h`.
- Group recovery script: `resume_action_pass_batch.py`; the grouped configs, logs, and case artifacts remain inside the bundle.
- Earlier v1–v3 variants and failed smoke/matched bundles were retained as policy-development evidence. None is treated as a balance outcome. The current comparison has only five seeds, a single policy, and no exposure to middle/optimized play.
