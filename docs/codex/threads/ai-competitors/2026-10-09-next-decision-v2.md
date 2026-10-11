# Next small decision: how should owned Features become a capability vector?

**Status: RESOLVED — B selected by the user on 2026-10-09.** [Dated decision](2026-10-09-legal-project-capability-decision-v1.md). The [selected basis](2026-10-09-owned-feature-capability-decision-v1.md) is the rival's owned, project-eligible Feature pool. This brief asked what that pool's four-Core vector should represent:

- **A — Raw inventory mix:** count the printed Core of each eligible owned Feature once. This is simple and stable, but a large catalog can appear strong even when those cards cannot fit into one legal project or hand.
- **B — Attainable project mix (recommended):** derive capability from Core that the owned pool could supply to a legal project under its card-use limits. This better reflects development capacity, while the exact calculation and CPU cost still need design.

The user's **B** choice sets the meaning of the vector, not its formula. Core aggregation, target normalization, candidate relevance, overshoot, prerequisite lookahead and performance bounds remain **OPEN**. The [next brief](2026-10-09-next-decision-v3.md) asks how to estimate that legal project potential.
