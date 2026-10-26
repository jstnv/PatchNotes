# Simulator candidate contracts-challenges-runtime-v1

Owner: contracts

**READY FOR IMPLEMENTATION REVIEW — not adopted.**

Base: `89d52a809a9f25613ecc7e269f28914d9c7edc8f4849aee31393170996cdc82c`

Candidate: `91f4394bad033863e2505232636e72332bb486284d04e84667274b2dcf86db2c`

Canonical now: `8bd8dd308be71df3dba3a5c3b46cbd4fa6a59c131b61535fc61dd7d8611404fb`

Baseline drift: **True**. Conflicting changed paths: **0**. Review `handoff.json` for the exact list. Resolve drift explicitly before adoption; never overwrite current source from the archived project wholesale.

`source-review.patch` is for reading. `delta-files.zip` holds exact added/modified bytes; `handoff.json` records deletions and all before/after hashes. `base-source.zip` and `candidate-source.zip` preserve both revisions. Evidence references include actual success/failure and file hashes; preserve the linked bundles.

## Internal TODO handoff

Add a task in `docs/codex/TODO.md` referencing this HANDOFF, the thread's accepted design decision, intended rule changes, acceptance criteria, evidence and remaining OPEN values. The implementation thread reviews the delta, reconciles current canonical drift, runs focused/live-headless parity checks and updates canonical source and status. This tool does not edit TODO, commit, or apply source changes.

Candidate simulations are evidence, not balance approval. Continue remains Studio-only; no save migration is implied by this proposal.

## Proposed addition

Activate the five approved trial challenge kinds for SideStreet, Crown, Neon and Starwave; keep Ironclad introductory and existing base rewards intact; settle bounded cash and Promotion bonus on final hand with checkpoint and UI support.

Design record: [retained decision](design-decision.md). Its contents require review; this tool does not infer approval.

## Acceptance criteria

- Reconcile current canonical source before adoption; exactly preserve existing base receipts and Promotion, pay bonus at most once, and ensure accepted terms and successful SideStreet redraw count determine final grade.
- Verify full, partial and missed challenges, legal hand and redraw rollback, exact finance and keyed next-successful-launch Promotion, legacy completed saves, forged bonus rejection, and both supported UI sizes.
- Run focused affected checks, a legal four-release campaign with exact fresh-process replay, and exported acceptance after integration.
