# Simulator candidate publisher-support-renewal-v2

Owner: contracts

**READY FOR IMPLEMENTATION REVIEW — not adopted.**

Base: `5edfa7878cd17904281d7cf7f2cf907e67b5f40edb4d9db83b3f99580f2aa415`

Candidate: `c83714a675a200344418140475c13d5199844750fcd1ecfe6bfcb84ff62d5194`

Canonical now: `8162408cf020beb75f6fa404468ce25f4a5cc0bb09d131d18a1788a2c9243884`

Baseline drift: **True**. Conflicting changed paths: **9**. Review `handoff.json` for the exact list. Resolve drift explicitly before adoption; never overwrite current source from the archived project wholesale.

`source-review.patch` is for reading. `delta-files.zip` holds exact added/modified bytes; `handoff.json` records deletions and all before/after hashes. `base-source.zip` and `candidate-source.zip` preserve both revisions. Evidence references include actual success/failure and file hashes; preserve the linked bundles.

## Internal TODO handoff

Add a task in `docs/codex/TODO.md` referencing this HANDOFF, the thread's accepted design decision, intended rule changes, acceptance criteria, evidence and remaining OPEN values. The implementation thread reviews the delta, reconciles current canonical drift, runs focused/live-headless parity checks and updates canonical source and status. This tool does not edit TODO, commit, or apply source changes.

Candidate simulations are evidence, not balance approval. Continue remains Studio-only; no save migration is implied by this proposal.

## Proposed addition

PROPOSED P4 review: earned-result renewal and chronological repeated-support persistence; historical prototype, reconcile into current P1 rather than adopting its scalar ledgers

Design record: [retained decision](design-decision.md). Its contents require review; this tool does not infer approval.

## Acceptance criteria

- Require a P4 design ruling; preserve approved P2/P3 and current source; reconcile events with P1 ordinals and exact historical capacity
- Reproduce legal success, repeat save, missed assessment, full commission recovery and third support with exact durable Studio envelopes and fresh replays
- Complete funding transaction planning, full ledger reconstruction, named player/world migration, native disk and exported acceptance before activation
