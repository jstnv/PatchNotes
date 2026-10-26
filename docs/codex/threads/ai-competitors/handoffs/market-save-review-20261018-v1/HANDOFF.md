# Simulator candidate ai-market-migration-full-restore-20261018-v29

Owner: ai-competitors

**READY FOR IMPLEMENTATION REVIEW — not adopted.**

Base: `89d52a809a9f25613ecc7e269f28914d9c7edc8f4849aee31393170996cdc82c`

Candidate: `30508dba9e2d25cd701519defe814bc064759ceaf51eac4a59aa041ba1b932bd`

Canonical now: `20c1b1b5ac4214bb46800764a47f75b3be3c98097c9af45300b19f8371545a9f`

Baseline drift: **True**. Conflicting changed paths: **1**. Review `handoff.json` for the exact list. Resolve drift explicitly before adoption; never overwrite current source from the archived project wholesale.

`source-review.patch` is for reading. `delta-files.zip` holds exact added/modified bytes; `handoff.json` records deletions and all before/after hashes. `base-source.zip` and `candidate-source.zip` preserve both revisions. Evidence references include actual success/failure and file hashes; preserve the linked bundles.

## Internal TODO handoff

Add a task in `docs/codex/TODO.md` referencing this HANDOFF, the thread's accepted design decision, intended rule changes, acceptance criteria, evidence and remaining OPEN values. The implementation thread reviews the delta, reconciles current canonical drift, runs focused/live-headless parity checks and updates canonical source and status. This tool does not edit TODO, commit, or apply source changes.

Candidate simulations are evidence, not balance approval. Continue remains Studio-only; no save migration is implied by this proposal.

## Proposed addition

Source-pinned review candidate for month snapshot transaction, active market save revision, exact old Studio and world compatibility gates, full catalog-backed Store restoration, and atomic next-commit publication; numerical market factors remain OPEN/TRIAL and require a separate ruling before adoption.

Design record: [retained decision](design-decision.md). Its contents require review; this tool does not infer approval.

## Acceptance criteria

- Reconcile every changed file and data identity with current canonical source; do not copy trial coefficients without design approval.
- Normal Store inspection and Continue accept only named legal old shapes, preserve historical earned state and original generations, reject corrupted accounting, history, Founder owner and active hand definitions, and publish a new generation only on a later legal Studio commit.
- Rerun current-source focused, fresh-process, Gameplay and exported Continue acceptance including atomic write failure, explicit backup recovery, and unsupported-source rejection.
