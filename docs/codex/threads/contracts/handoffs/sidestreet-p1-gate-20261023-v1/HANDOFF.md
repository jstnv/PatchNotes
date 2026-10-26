# Simulator candidate sidestreet-p1-gate-v1

Owner: contracts

**READY FOR IMPLEMENTATION REVIEW — not adopted.**

Base: `42ef00919a6af975d5e779030583189b0077130de1ab416350c0cf202c158847`

Candidate: `544cb959ac35a6a121ad6e676b6494facb2ecd9e34b668aafb744c58b5a74244`

Canonical now: `42ef00919a6af975d5e779030583189b0077130de1ab416350c0cf202c158847`

Baseline drift: **False**. Conflicting changed paths: **0**. Review `handoff.json` for the exact list. Resolve drift explicitly before adoption; never overwrite current source from the archived project wholesale.

`source-review.patch` is for reading. `delta-files.zip` holds exact added/modified bytes; `handoff.json` records deletions and all before/after hashes. `base-source.zip` and `candidate-source.zip` preserve both revisions. Evidence references include actual success/failure and file hashes; preserve the linked bundles.

## Internal TODO handoff

Add a task in `docs/codex/TODO.md` referencing this HANDOFF, the thread's accepted design decision, intended rule changes, acceptance criteria, evidence and remaining OPEN values. The implementation thread reviews the delta, reconciles current canonical drift, runs focused/live-headless parity checks and updates canonical source and status. This tool does not edit TODO, commit, or apply source changes.

Candidate simulations are evidence, not balance approval. Continue remains Studio-only; no save migration is implied by this proposal.

## Proposed addition

DESIGN REVIEW ONLY: P1-backed SideStreet Reputation Brief private candidate; numerical terms and first commissioned-game activation remain proposed. Reconcile ten changed paths; do not adopt historical Reputation dictionaries or enable P2 without a trial ruling.

Design record: [retained decision](design-decision.md). Its contents require review; this tool does not infer approval.

## Acceptance criteria

- Retain current existing-Contract and RNG controls; exactly-once trusted awards, coherent observer signals, rejection atomicity and typed Studio roundtrip must pass.
- Add named current-P1 player and active-rival migration, prospective offers, no retroactive awards, forged-save rejection and real native cold Continue before adoption.
- Resolve assert-only internal transaction assumptions and implement visible Brief/partial reward presentation; verify supported sizes and exported acceptance.
- Approve proposed P2/P3 terms separately and provide an enabled first commission plus verified current-source delivery/miss and owner-aware finance before activating Reputation-only play.
