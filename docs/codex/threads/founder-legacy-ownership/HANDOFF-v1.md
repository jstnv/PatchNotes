# Founder Legacy & Corporate Ownership — phased design handoff v1

**Date:** 2026-10-11. **Status:** PROPOSED dependency plan, not queued implementation. This file is internal to this design thread; `docs/codex/TODO.md` remains untouched. [Specification](SPEC-v1.md) and [open approvals](SPEC-v1.md#11-approvals-required) govern every phase.

| Phase | Dependency and proposed task | Reviewable acceptance gate |
|---|---|---|
| 0 — decisions and source contract | Resolve founder consideration, startup funding, control/CEO rights, valuation inputs, historical save treatment and first later-era package. Reconcile AI Competitors G1–G5 and Simulation Engine shared-world contracts. | Versioned user decisions distinguish LOCKED/ACTIVE/TRIAL/OPEN and identify which existing first-Studio rules remain. No numerical candidate silently becomes gameplay. |
| 1 — world identity and persistence | Introduce founder/world/Studio stable IDs and one world-owned calendar around separately owned Studio states. Define atomic world snapshot and versioned old-save treatment. | Existing single-Studio behavior and supported Continue stay source-parity; two independent Studio ledgers, RNGs and saved active phases restore without duplicate income, bills or events. Old bytes are preserved on incompatibility. |
| 2 — ownership ledger and transaction core | Equal-share cap tables, primary issue, secondary transfer, exact majority, acyclic corporate graph, journals and immutable transaction IDs. Keep AI deal policy disabled. | Property/invariant checks cover conservation, 50% boundary, rounding, cash location, stale/duplicate offers, overflow, failed atomicity and save/replay. A full purchase changes control but not target asset ownership. |
| 3 — valuation and founding finance | Implement approved normalized-earnings/IP method, cached input snapshots, distinct presales startup underwriting, loan/equity receipt paths and era-appropriate formation. | Independent exact-cent examples show no double-counting; primary `V_post=V_pre+I` and actual dilution; buyer/target/seller cash and debt reconcile. A new Studio with no sales can form only through approved loan/equity commitments, without minting repeat starter cash. Ordinary Bank rules remain source-parity. |
| 4 — corporate AI and acquisitions | At six-cycle boundaries, filter candidates, obtain real funding/seller consent, create friendly/hostile offers, issue warnings, and commit valid control transitions. | Seeded fresh-process replay matches ordered events and state; no warning/offer alone changes votes; concurrent offers revalidate; no graph cycle; benchmarks meet approved target population and hardware limits. Development AI still uses legal commands. |
| 5 — founder role transition | Studio-boundary voluntary departure, CEO mandate/negotiated exit and loss-of-control routes; switch exactly one manual operator and leave old Studio AI-operated. | In-progress hands/contracts cannot be abandoned; old Studio keeps cash, Features, IP, employees, subsidiaries and obligations; founder history/milestones persist; no owner cash silently crosses. Save/rollback and repeated migration preserve IDs and funding history. |
| 6 — subsidiaries and continuation | Parent policies/commissions with independent subsidiary development; eventual specialized operating roles; milestone Continue and long-horizon validation. | Intercompany payable/receivable entries net correctly, no duplicated revenue or card team, valid autonomous actions after control changes, milestones once-only and endless continuation. Specialized economics need their own approval. |

## Integration order and ownership

The implementation thread must first establish the shared-world/AI foundation and coordinate its single overlapping canonical gameplay slot. This design thread may later provide an isolated simulator variant and source-pinned review packet only under a newly authorized scoped task. Adoption requires a fresh shared TODO handoff authorized by the user, canonical drift reconciliation and focused/native/save validation. Do not copy a private AI Competitors candidate or this specification into production as an implicit approval.

## Proposed proof set, not executed here

- Pure ledger examples: 50% tie, one-unit majority, partial/full purchase, chained primary dilution, corporate seller and founder settlement, zero-value target and stale offers.
- Finance examples: earned versus settled revenue, unpaid rent/payroll/Bank and loan principal, normalized IP baseline, startup loan/equity receipts, debt-bearing acquisition and intercompany commissions.
- Deterministic campaign routes: voluntary departure, hostile warning then valid majority, CEO stay then exit, old-Studio AI continuation, new-Studio era start, milestone Continue, world checkpoint/rollback and prior-save policy.
- Profiling: declared population/age/dense ownership cases with cache hit/invalidations, per-quarter/total-cycle timing, memory and save size; bounds chosen after measurement.

Passing any proposed check would show only its stated scope. It would not itself settle valuation balance, takeover feel, final AI policy or release readiness.
