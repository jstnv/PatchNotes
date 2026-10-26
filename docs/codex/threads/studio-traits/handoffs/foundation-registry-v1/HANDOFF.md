# Simulator candidate studio-traits-foundation-v1

Owner: studio-traits

**READY FOR IMPLEMENTATION REVIEW — not adopted.**

Base: `9ed255239a2dd365858be840af05b6d72053525be6bb43add3eb0847865d9b55`

Candidate: `e982f016f1fb3260ce61786b8351d9420f1ddce46801f6c4dc27236c56302a4b`

Canonical now: `3735422611d3fd368a41394239536924062967184dfb43e578af351d2f7a3f91`

Baseline drift: **True**. Conflicting changed paths: **0**. Review `handoff.json` for the exact list. Resolve drift explicitly before adoption; never overwrite current source from the archived project wholesale.

`source-review.patch` is for reading. `delta-files.zip` holds exact added/modified bytes; `handoff.json` records deletions and all before/after hashes. `base-source.zip` and `candidate-source.zip` preserve both revisions. Evidence references include actual success/failure and file hashes; preserve the linked bundles.

## Internal TODO handoff

Add a task in `docs/codex/TODO.md` referencing this HANDOFF, the thread's accepted design decision, intended rule changes, acceptance criteria, evidence and remaining OPEN values. The implementation thread reviews the delta, reconciles current canonical drift, runs focused/live-headless parity checks and updates canonical source and status. This tool does not edit TODO, commit, or apply source changes.

Candidate simulations are evidence, not balance approval. Continue remains Studio-only; no save migration is implied by this proposal.

## Proposed addition

Centralize each existing Studio Trait point amount, activation version and active-ID order in its registry definition; preserve behavior and saved-version reconstruction.

Design record: [retained decision](design-decision.md). Its contents require review; this tool does not infer approval.

## Acceptance criteria

- Reconcile only scripts/studio_traits.gd into current canonical source; treat the private snapshot driver as analysis-only.
- All 665 historical selection snapshots across saved versions 3-8 match exactly, including invalid choices.
- Focused trait, Cult and checkpoint checks pass; legal two-release route matches initial/final state, RNG, finance and telemetry; fresh-process replay passes.
