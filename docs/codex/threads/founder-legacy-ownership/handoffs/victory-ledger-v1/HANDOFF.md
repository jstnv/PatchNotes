# Simulator candidate founder-victory-ledger-v1

Owner: founder-legacy-ownership

**READY FOR IMPLEMENTATION REVIEW — not adopted.**

Base: `9382c90ec435272f4caf577d3c8bcd4b59ab89b0d86086db7f4b776c2c0bd1be`

Candidate: `88b54414bdea9d24c242a286d39293b196eba9b663ae8556de7f5a4675575b32`

Canonical now: `9382c90ec435272f4caf577d3c8bcd4b59ab89b0d86086db7f4b776c2c0bd1be`

Baseline drift: **False**. Conflicting changed paths: **0**. Review `handoff.json` for the exact list. Resolve drift explicitly before adoption; never overwrite current source from the archived project wholesale.

`source-review.patch` is for reading. `delta-files.zip` holds exact added/modified bytes; `handoff.json` records deletions and all before/after hashes. `base-source.zip` and `candidate-source.zip` preserve both revisions. Evidence references include actual success/failure and file hashes; preserve the linked bundles.

## Internal TODO handoff

Add a task in `docs/codex/TODO.md` referencing this HANDOFF, the thread's accepted design decision, intended rule changes, acceptance criteria, evidence and remaining OPEN values. The implementation thread reviews the delta, reconciles current canonical drift, runs focused/live-headless parity checks and updates canonical source and status. This tool does not edit TODO, commit, or apply source changes.

Candidate simulations are evidence, not balance approval. Continue remains Studio-only; no save migration is implied by this proposal.

## Proposed addition

Versioned founder victory ledger with a committed-ownership evaluator for the ten-subsidiary milestone; other routes remain inactive

Design record: [retained decision](design-decision.md). Its contents require review; this tool does not infer approval.

## Acceptance criteria

- Tenth unique majority-controlled subsidiary records one founder claim only after valid atomic ownership settlement; ties, offers, repeats and corrupt evidence reject
- Whole-world checkpoint and fresh-process Continue preserve the ledger; same-source v1 Founder data remains readable; ordinary Studio gameplay remains unchanged
