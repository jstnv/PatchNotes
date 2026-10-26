# Simulator candidate contracts-foundation-v1

Owner: contracts

**READY FOR IMPLEMENTATION REVIEW — not adopted.**

Base: `ab7b4324cb93c94d3a65c935b353917f94590bc8b5d59bbf5ab4a2c672140ed8`

Candidate: `aeac243b2384f4b740583559f1b104b6b835ce15d67195281697d6d8e8a4648c`

Canonical now: `c7fd3db19210122f2e00aab9745cc6e075c6e38267fb99f8ef1cca0ff138b35d`

Baseline drift: **True**. Conflicting changed paths: **0**. Review `handoff.json` for the exact list. Resolve drift explicitly before adoption; never overwrite current source from the archived project wholesale.

`source-review.patch` is for reading. `delta-files.zip` holds exact added/modified bytes; `handoff.json` records deletions and all before/after hashes. `base-source.zip` and `candidate-source.zip` preserve both revisions. Evidence references include actual success/failure and file hashes; preserve the linked bundles.

## Internal TODO handoff

Add a task in `docs/codex/TODO.md` referencing this HANDOFF, the thread's accepted design decision, intended rule changes, acceptance criteria, evidence and remaining OPEN values. The implementation thread reviews the delta, reconciles current canonical drift, runs focused/live-headless parity checks and updates canonical source and status. This tool does not edit TODO, commit, or apply source changes.

Candidate simulations are evidence, not balance approval. Continue remains Studio-only; no save migration is implied by this proposal.

## Proposed addition

Adopt the code-owned versioned definitions for the five current Contracts and compatible ContractState/PublisherTrialTerms routing; preserve offer terms, scoring, payouts, Promotion, hand and save behavior.

Design record: [retained decision](design-decision.md). Its contents require review; this tool does not infer approval.

## Acceptance criteria

- All five existing Contract focused suites and the definition verifier pass with zero failures on the integrated source.
- A legal fresh Crown campaign and exact fresh-process replay preserve all 85 accepted state digests and the final state against the current baseline route, or document justified drift.
- Existing checkpoint fields and frozen trial terms remain byte/field compatible; no new offer or balance value is adopted.
