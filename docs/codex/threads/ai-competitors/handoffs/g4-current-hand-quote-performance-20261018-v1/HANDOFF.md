# Simulator candidate g4-current-hand-20261018-v5

Owner: ai-competitors

**READY FOR IMPLEMENTATION REVIEW — not adopted.**

Base: `391cc6cf4bd6a7737ad73bd3d869c27516e79ae4f06da06efd138a03ea2ab0d6`

Candidate: `8e1e475d3b99395f3d46c71fc9619fca5889faa90eccdb5fbff50f835442bb17`

Canonical now: `3a79cda4fd564babbc43a6b12d8136ad0026bd3b01e03e995266cef9595525db`

Baseline drift: **True**. Conflicting changed paths: **0**. Review `handoff.json` for the exact list. Resolve drift explicitly before adoption; never overwrite current source from the archived project wholesale.

`source-review.patch` is for reading. `delta-files.zip` holds exact added/modified bytes; `handoff.json` records deletions and all before/after hashes. `base-source.zip` and `candidate-source.zip` preserve both revisions. Evidence references include actual success/failure and file hashes; preserve the linked bundles.

## Internal TODO handoff

Add a task in `docs/codex/TODO.md` referencing this HANDOFF, the thread's accepted design decision, intended rule changes, acceptance criteria, evidence and remaining OPEN values. The implementation thread reviews the delta, reconciles current canonical drift, runs focused/live-headless parity checks and updates canonical source and status. This tool does not edit TODO, commit, or apply source changes.

Candidate simulations are evidence, not balance approval. Continue remains Studio-only; no save migration is implied by this proposal.

## Proposed addition

DESIGN REVIEW ONLY: exact current-hand quote with observation-local price deduplication and shared next-cycle sales/Fan preflight; preserve price-specific finance and ordinary commit path

Design record: [retained decision](design-decision.md). Its contents require review; this tool does not infer approval.

## Acceptance criteria

- Reconcile both changed source files with current canonical drift; do not replace the project wholesale
- Specify and verify unavailable quote reasons and legal low-cash or arrears parity before any canonical adoption
- Set and pass a stable eight-rival world CPU and memory budget; current repeated elapsed screen is mixed
- Repeat exact quote-to-receipt, state/RNG, legal world, checkpoint and fresh-process replay checks on integrated source
