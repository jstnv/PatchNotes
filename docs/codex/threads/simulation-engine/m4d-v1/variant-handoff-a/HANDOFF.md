# Simulator candidate isolation-a-v1

Owner: M4d synthetic verification

**READY FOR IMPLEMENTATION REVIEW — not adopted.**

Base: `d7ba6c5233238c22c39b73301d84787a60f760dc41d5302f56f1ee04fab48de8`

Candidate: `a9c3e3a3c5ac87a628a26d2a34b418fc147448e45b2a49c24e98a69a36d2d921`

Canonical now: `d7ba6c5233238c22c39b73301d84787a60f760dc41d5302f56f1ee04fab48de8`

Baseline drift: **False**. Conflicting changed paths: **0**. Review `handoff.json` for the exact list. Resolve drift explicitly before adoption; never overwrite current source from the archived project wholesale.

`source-review.patch` is for reading. `delta-files.zip` holds exact added/modified bytes; `handoff.json` records deletions and all before/after hashes. `base-source.zip` and `candidate-source.zip` preserve both revisions. Evidence references include actual success/failure and file hashes; preserve the linked bundles.

## Internal TODO handoff

Add a task in `docs/codex/TODO.md` referencing this HANDOFF, the thread's accepted design decision, intended rule changes, acceptance criteria, evidence and remaining OPEN values. The implementation thread reviews the delta, reconciles current canonical drift, runs focused/live-headless parity checks and updates canonical source and status. This tool does not edit TODO, commit, or apply source changes.

Candidate simulations are evidence, not balance approval. Continue remains Studio-only; no save migration is implied by this proposal.

## Proposed addition

Synthetic isolation fixture only; do not adopt its capital change

Design record: [retained decision](design-decision.md). Its contents require review; this tool does not infer approval.

## Acceptance criteria

- Two candidate processes overlap, canonical source remains unchanged and each exact replay passes
