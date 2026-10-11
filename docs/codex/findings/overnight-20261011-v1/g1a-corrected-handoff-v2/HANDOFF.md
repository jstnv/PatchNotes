# Simulator candidate g1a-archive-validation-v1

Owner: pn-implementation

**READY FOR IMPLEMENTATION REVIEW — not adopted.**

Base: `4162c70c12bf3d6af7587e5879759b54b127280c4ff224f4970ed7f8c2b895df`

Candidate: `38749eaf2397fece0c120c3ffcb454c73fd90ac4cf9e7dec4b5f287769a5abbb`

Canonical now: `6327c1134f5a00e480f6fcbd7db1ac3becc5892fb40fa34694b5f708ee81b303`

Baseline drift: **True**. Conflicting changed paths: **0**. Review `handoff.json` for the exact list. Resolve drift explicitly before adoption; never overwrite current source from the archived project wholesale.

`source-review.patch` is for reading. `delta-files.zip` holds exact added/modified bytes; `handoff.json` records deletions and all before/after hashes. `base-source.zip` and `candidate-source.zip` preserve both revisions. Evidence references include actual success/failure and file hashes; preserve the linked bundles.

## Internal TODO handoff

Add a task in `docs/codex/TODO.md` referencing this HANDOFF, the thread's accepted design decision, intended rule changes, acceptance criteria, evidence and remaining OPEN values. The implementation thread reviews the delta, reconciles current canonical drift, runs focused/live-headless parity checks and updates canonical source and status. This tool does not edit TODO, commit, or apply source changes.

Candidate simulations are evidence, not balance approval. Continue remains Studio-only; no save migration is implied by this proposal.

## Proposed addition

Private archive validation correction; no canonical cohort or migration adoption

Design record: [retained decision](design-decision.md). Its contents require review; this tool does not infer approval.

## Acceptance criteria

- Reject reserved live IDs and empty archives before mutation; preserve frozen archive across legal releases and Studio restart
- Canonical adoption still requires cohort authority, trusted migration and integrated shared-world acceptance
