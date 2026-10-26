# Simulator candidate parent-gate-proto-v4

Owner: feature-pools

**READY FOR IMPLEMENTATION REVIEW — not adopted.**

Base: `ab152c2c263867e6b19da0446488bd47469a85e017dc4f4db47de50030aa779e`

Candidate: `65386bf34d045586c9d954120a3cb45ab80fbcdd59cae88e144a3b29fac5d3a4`

Canonical now: `ab152c2c263867e6b19da0446488bd47469a85e017dc4f4db47de50030aa779e`

Baseline drift: **False**. Conflicting changed paths: **0**. Review `handoff.json` for the exact list. Resolve drift explicitly before adoption; never overwrite current source from the archived project wholesale.

`source-review.patch` is for reading. `delta-files.zip` holds exact added/modified bytes; `handoff.json` records deletions and all before/after hashes. `base-source.zip` and `candidate-source.zip` preserve both revisions. Evidence references include actual success/failure and file hashes; preserve the linked bundles.

## Internal TODO handoff

Add a task in `docs/codex/TODO.md` referencing this HANDOFF, the thread's accepted design decision, intended rule changes, acceptance criteria, evidence and remaining OPEN values. The implementation thread reviews the delta, reconciles current canonical drift, runs focused/live-headless parity checks and updates canonical source and status. This tool does not edit TODO, commit, or apply source changes.

Candidate simulations are evidence, not balance approval. Continue remains Studio-only; no save migration is implied by this proposal.

## Proposed addition

Add dormant two-parent Store quote and acquisition-path capability: AND ownership and one shared familiarity cap; keep live ledger unchanged and complete UI and graph validation during canonical adoption.

Design record: [retained decision](design-decision.md). Its contents require review; this tool does not infer approval.

## Acceptance criteria

- All named parents are owned before admission; a queued parent never unlocks a child; rejected quotes do not mutate cash, cycle, queue, ownership or RNG.
- Sum committed distinct-project credits per named parent under one 50 percent cap; recompute only unpaid Research installments and preserve the half-base down payment and existing single-parent and Gameplay-count rules.
- Validate duplicate, missing, self and cyclic named-parent graphs; show each parent, credit contribution and blocker in Store details with an additional-parent AND badge and no duplicated map node.
- Run focused mechanics, current Store regressions, native and checkpoint continuation, both supported rendered sizes and representative fresh-process replays on the integrated source; add no new live card or price.
