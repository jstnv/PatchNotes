# Victory ledger candidate v1: structural decision and adoption boundary

**Date:** 2026-10-17 (America/Los_Angeles). **Status:** CANDIDATE implementation, for canonical review. **Authority:** the user's request to start the [five-victory design](2026-10-17-five-victory-conditions-v1.md). No Fan threshold, market share target, award ranking, Store capstone or provisional comeback rule is approved here.

## Selected first slice

Use the existing Founder/ownership world as the sole authority for victory claims. A new versioned, world-owned ledger records its activation cycle, immutable original Studio ID and once-only claims. The first evaluator is the user's fixed **10 subsidiaries** target: traverse valid acyclic cap tables from direct founder-majority roots through each corporate-majority child, count unique subsidiaries once, and require a committed ownership transaction before making the claim. Store the qualifying cap-table snapshot and transaction ID as historical evidence. Record the same milestone in `FounderProfile` within the ownership commit so checkpoint validation rejects a one-sided claim.

The candidate retains v1 Founder world reads while new explicit Founder worlds use v2. It validates the ledger on whole-world checkpoint capture and restore. A win adds no money, shares, IP, calendar step or forced ending. The other four routes have no evaluator in this version and cannot be claimed.

## Current reachability and rollout

The current `RivalWorldCheckpoint.MAX_RIVALS` is **8**, so at most nine Studios including the manually operated one can be saved. Ten subsidiaries are structurally unreachable in the canonical roster. This candidate does not raise that cap or fabricate Studios; a separate population/performance/checkpoint review must do so before enabling a player-facing subsidiary victory. The read-only count helper can be used by a later progress screen; no victory UI or annual award system is added here.

Implement the candidate only inside [victory-ledger-v1](simulators/victory-ledger-v1/). Its `project/` is editable; its baseline and manifests are sealed. Do not copy it directly into canonical source without a source-pinned reconciliation, focused source/checkpoint/Gameplay checks and approval of the capacity increase. The earlier DESIGN-only victory record remains the full plan.

## Acceptance for this slice

- Unconsented offers, previews, stale/unfunded transactions and a 50% tie leave claims empty.
- The tenth valid majority subsidiary produces one milestone after a committed transaction; indirect control and duplicate paths count correctly; replay and later sales cannot repeat or revoke it.
- Full-world save/restore round trips the empty ledger, rejects forged claims and an altered original Studio, and keeps v1 same-source Founder data readable.
- No non-Founder or incomplete world receives a victory, and unrelated Studio gameplay remains unchanged.

## Source-pinned candidate evidence

The final candidate is `founder-victory-ledger-v1`, creation/base identity `9382c90ec435272f4caf577d3c8bcd4b59ab89b0d86086db7f4b776c2c0bd1be`; the [final campaign report](sims/victory-ledger-campaign-v3/run-report.json) records its exact candidate identity and no canonical baseline drift. Godot 4.7.1 `a13da4feb` ran the bounded checks in isolated profiles:

- [Victory evaluator log](sims/victory-ledger-checks-v3/verify_founder_victory.log): 13/13.
- [Founder baseline log](sims/victory-ledger-checks-v3/verify_founder_foundation.log): 27/27.
- [World checkpoint log](sims/victory-ledger-checks-v3/verify_legacy_world.log): 30/30, with the saved [world frame](sims/victory-ledger-checks-v3/legacy-world-frame.json).
- [Fresh-process restore log](sims/victory-ledger-checks-v3/verify_founder_victory_cold.log): 6/6, including v1 same-source reads and rejection of fabricated claims.
- [Final isolated campaign](sims/victory-ledger-campaign-v3/run-report.json): one finite policy case, two releases, 36 commands, cycle 14. [Exact replay](sims/victory-ledger-replay-v3/run-report.json) passed all 36 recorded steps and the final-state digest.

The normal Gameplay verifier attempted a run on this candidate but the existing singleton checkpoint writer returned `writer_busy` (TCP port 62741), so Gameplay save/Continue acceptance is **BLOCKED**, not passed. It should be run in the coordinated canonical implementation slot. The 12-Studio cap-table case is a pure ownership fixture because the current world checkpoint cannot persist that population.

## Open after this slice

Save-compatible world population beyond ten subsidiaries; visible progress and Continue notice; annual Game of the Year and full industry market index; Feature Store Innovation Path; numeric `X` Fans and `Y%` influence; final comeback rule. The global Studio save-writer lease can block concurrent Gameplay verification and must be rerun under the coordinated implementation slot.
