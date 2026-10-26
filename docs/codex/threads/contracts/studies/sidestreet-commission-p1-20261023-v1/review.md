# Independent candidate review

2026-10-23. One fresh-context reviewer, read-only; required by the executing-plans workflow. Static review is separate from the runtime evidence.

Scope: v1 versus the P1-backed P2 parent, then precise v2/v3 corrections. RunState, BeginProject, CampaignSession, publisher commission/relationship rules, checkpoint schema and adapter.

1. **Resolved in v2:** original caller-owned quote could mutate inside the readiness callback after validation. The private fork now deep-copies it before callbacks and revalidates the prepared project/current quote before binding. `callback-v1/` reproduces the old defect on a legally earned R20 prefix.
2. **Resolved in v3:** checking only a `:commission` receipt suffix did not cover a renamed orphan receipt. Every publisher receipt must now map to a completed cash Contract or commission, with existing validators checking its amounts and provenance. `orphan-red-v1/` and `renamed-red-v2/` preserve the reproductions.
3. Reviewer confirmed the v3 source delta closes the renamed-source bypass. No further independent actionable defect was reported in the reviewed P1 event coverage, staged prior-event reconstruction, publication guards or raw-sales/Studio-finance separation. This is not an exhaustive proof.

Native quote/result UI, named canonical migration, full world/Founder acceptance and exported play remain implementation acceptance work. No candidate code was written by the reviewer; no other thread was messaged.
