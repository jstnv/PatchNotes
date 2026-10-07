# Feature Store working notes

Status: **OPEN discussion**, started 2026-10-06 (America/Los_Angeles). This file does not approve new Store content, prices, gates, or gameplay implementation.

## Questions to resolve

1. Which new Feature nodes belong in the next bounded catalog, with exact card effects, parents, prices, play fees, and Contract-pool eligibility?
2. What additional qualifying-release or milestone conditions accompany the locked later-era calendar years? How should the player see unmet conditions?
3. How do multi-parent unlocks and three-Core requirements work, including familiarity credits and discounts?
4. What platform rules and Store-map presentation are needed for the expanded catalog?
5. How should purchase timing, actual draw/play access, settled cash, rent buffer, and cycle cost be compared at matched calendar checkpoints? The current retained-pool study and repaired Alpha-exit behavior are the starting evidence.

## Decision record

| Date | Topic | Status | Ruling / evidence | Design update |
|---|---|---|---|---|
| 2026-10-06 | Thread setup | OPEN | Existing Store behavior and progression direction are documented; expanded content and numbers remain unapproved. | No new ruling |
| 2026-10-06 | Sub-Areas bounded-pilot identity | APPROVED for bounded design pilot | After reviewing both choices, user explicitly ruled: “Then lets keep the identical stats for a bounded pilot.” `sub_areas` stays a distinct finite Alpha World Design ID with Levels' exact printed Graphics 3 / Design 2 / Scope 2. The earlier “I think yes” was only a leaning and is superseded by this ruling. The analysis catalog lists Levels as parent, but final parent semantics, price, play fee, unlock, UI, Contract-pool eligibility, balance return and gameplay implementation remain OPEN. | [Feature Store design](../../design/feature-store-progression.md) updated; no shared TODO edit |
| 2026-10-06 | Sub-Areas economic success criterion | OPEN — proposed scorecard | [Findings v6](FINDINGS-v6-sub-areas-payoff.md) followed two seeds through Game 5. Propose separate solvency/access, actual title settlement/quality, and matched-calendar plus same-release-count cash-payback checks. Three of four late-buy routes improved both Reviews and Game 5 launch cash; one worsened. A $90 play fee was not simulated. No threshold, price or fee approved. | Review scorecard with user before numerical ruling |
| 2026-10-06 | Sub-Areas fee sensitivity and optional-upgrade criterion | OPEN — proposed | [Findings v7](FINDINGS-v7-sub-areas-fee-sensitivity.md) applies $0/$50/$90 per actual commit to four fixed native routes. $90 leaves cash-result signs unchanged, but is an accounting overlay only. Propose hard legal-access/solvency gate, separate Review and actual settled-sales evidence, and Game 5 cash payback as a broader-sample target rather than a per-seed mandate; expose matched-calendar downside. No fee or criterion approved. | User review; broader Task 2 native evidence |
| 2026-10-06 | Sub-Areas bounded-pilot evaluation standard | APPROVED — ACTIVE/TRIAL evaluation only | User replied “Alright sure thing” to the proposed hard access/solvency gate, separate Review/settled-sales/cash measures, and Game 5 payback as a broader-sample target rather than a per-seed requirement. This resolves the v6/v7 criterion proposal, **not** the $1,700/$90 candidates, any numerical pass rate, purchase trigger or implementation. | [Decision v1](DECISION-v1-optional-upgrade-standard.md) and [Store design](../../design/feature-store-progression.md) updated; no shared TODO edit |
| 2026-10-06 | Sub-Areas bounded-pilot access | APPROVED — ACTIVE/TRIAL design only | User delegated an evidence-based choice: “Run sims and Ill go with what you recommend.” [Findings v8](FINDINGS-v8-sub-areas-parent-rule.md) compared 24 current-source routes. Hard Levels parent let only 1/4 Strategy routes afford the $2,150 chain and that buyer blocked; no parent let 3/4 buy, two reach Game 5 without arrears. Recommend/record independent Store-only node, no Levels parent discount, no Contract supply. The $1,700/$90 and availability remain OPEN. | [Decision v2](DECISION-v2-sub-areas-access.md) and [Store design](../../design/feature-store-progression.md) updated; no shared TODO or DECISIONS edit |

## Proposed work for later TODO contribution

Add scoped design and implementation tasks here as decisions settle. Include dependencies, exact behavior, UI implications, and focused acceptance checks. Transfer them to the internal TODO only when the user prompts it.
