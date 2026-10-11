# Next small decision: how should project potential be estimated?

**Status: RESOLVED — A selected by the user on 2026-10-09.** [Dated decision](2026-10-09-deterministic-ceiling-decision-v1.md). The [chosen B direction](2026-10-09-legal-project-capability-decision-v1.md) constrains capability to Core attainable within one legal project. This brief asked whether the estimate should reflect a ceiling or a typical draw:

- **A — Deterministic legal ceiling (recommended for the first design pass):** estimate the strongest attainable specialty-oriented Core mix under legal project limits, without weighting how likely the card sequence is. Stable for shopping, but it may overstate hard-to-draw combinations.
- **B — Representative draw-aware mix:** estimate what ordinary legal hands are likely to produce. This may better match released games, but depends on unresolved hand-choice policy, draw probabilities and CPU budget.

The user's **A** choice sets the estimate's intent, not its exact algorithm or numbers. The ceiling must use a jointly attainable four-Core mix; independent per-Core maxima cannot be combined into an impossible vector. Hand generation, costs, cash, cycle limits, vector selection, Core aggregation, normalization, candidate relevance and CPU limits remain **OPEN**. The [next brief](2026-10-09-next-decision-v4.md) asks when a candidate is relevant.
