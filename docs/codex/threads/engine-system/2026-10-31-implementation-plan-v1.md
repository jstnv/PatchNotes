# Engine System and Marketplace Implementation Plan

> **For agentic workers:** Use a test-first, source-pinned implementation sequence in the one overlapping gameplay slot.

**Goal:** Add selectable owned/licensed engines, two real-rival opening listings, additive specialization, capacity, creator payments, persistent royalties and Studio Management controls.

**Architecture:** Fixed opening definitions resolve creator IDs against the current `RivalWorld`. Pure entitlement and quote data are committed through RunState/world finance and checkpoint boundaries. Each project freezes its selected engine and each release freezes royalty terms. Existing production and sales math remain the source of ordinary scoring and platform net.

**Tech Stack:** Godot GDScript, `RunState`, `ProjectState`, `RivalWorld`, `StudioFinanceLedger`, `ReleasedGameSales`, `StudioCheckpoint`, `ProductionHand`, current folder UI.

**Spec:** [Engine Marketplace design intake](../../design/engine-marketplace.md), based on the user-pasted implementation brief.

## Global constraints

- Opening Action/Puzzle engines: 25 Scope, $7,500 license, 20% royalty, +0.1 per dominant category only.
- Action creator `incumbent-action`; Puzzle creator `incumbent-puzzle`; validate live identity and specialty in both new and restored worlds.
- Keep review formula, Feature prices/Scope, Pass Budget, candidate rules, Beta and Engine Skill Tree unchanged.
- Royalties use platform-net sales; the starting engines impose a hard 25-Scope cap; unlicensed Studios keep a legacy engine with current behavior.
- Preserve inherited edits, existing checkpoints, certified rival opening bytes and prior player saves.

## Tasks

1. [x] **Opening catalog:** Add immutable definitions and verify exact real-owner IDs/specialties in both certified rival openings. `verify_engine_catalog.gd` passes.
2. [x] **Pure entitlement quote:** Validate one license per Studio/engine, exact $7,500 debit/creator credit, insufficient funds, creator mismatch and overflow before any mutation. `verify_engine_entitlements.gd` passes. This is not yet a live transaction.
3. [x] **Specialization arithmetic seam:** Accept optional category bonuses in the shared production calculator; sum the base 1.5, engine and future employee basis points only for qualifying Specialization. Verify Feature/Pass behavior, non-dominant categories and Balanced isolation. `verify_engine_specialization.gd` and existing production/score checks pass. No live engine is connected yet.
4. [ ] **Persistent engine state:** Typed entitlements, selected project/release IDs, creator receipts and legacy hydration are in current Studio/world checkpoints. Focused and existing Studio/Continue tests pass. Cross-owner malformed-save rejection remains a further hardening check.
5. [ ] **Live purchase:** World quote preflights buyer/creator ledgers and commits both balances and license. Insufficient funds, duplicates, real rival bankroll and cold Continue pass. Arrears/overflow recovery remains OPEN.
6. [ ] **Project selection and capacity:** Studio Management selection, project-setup capacity copy and the 25-Scope production cap are live; direct exact/over-cap and legacy tests pass. Mixed hands and phase-exit checks remain OPEN.
7. [x] **Live Specialization:** Selected engine bonuses enter Design/Alpha only through the shared calculator. Pure engine/employee additive, Pass and non-specialized checks pass; broader phase trace fixtures remain coupled to provisional Pass Budget changes.
8. [ ] **Royalty settlement:** Cumulative platform-net sales debit and creator credit with persisted per-release receipt are live; real first/later settlement, repeat, owned-engine exemption, support/commission arithmetic and saved creator receipt pass. Full publisher-deal careers, insolvency and full world cold royalty replay remain OPEN.
9. [ ] **UI and acceptance:** Engines page and basic headless navigation pass. Native visual/input checks, Godot4.4, broad career balance and maintained old-trace reconciliation remain OPEN. [Exact check record](../../logs/2026-10-31-engine-marketplace-implementation-v1.md).

## Confirmed rulings

The user selected platform-net royalties, the hard 25-Scope cap against the unchanged 30-Scope requirement, and a built-in legacy engine for unlicensed Studios on 2026-10-31. These supersede the pending questions in the intake log.
