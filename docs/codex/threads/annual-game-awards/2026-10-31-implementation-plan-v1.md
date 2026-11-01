# Annual Game Awards Implementation Plan

> REQUIRED execution workflow: superpowers:subagent-driven-development for isolated rules/receipt/UI tasks; primary agent integrates one canonical world implementation. Preserve existing edits. Do not commit, push or export without a new instruction.

**Goal:** Complete deterministic, durable annual awards and the shared-style ceremony.
**Architecture:** Pure ranking, chronological per-owner receipts, one world ledger, presentation-only shared UI. Existing RunState/finance/RNG authorities remain unchanged.
**Tech stack:** Godot4.7.1, GDScript, existing typed checkpoints and native verifier harness.
**Spec:**2026-10-31-implementation-contract-v1.md

## Global constraints

Frozen historical inputs, calendar/mechanics/finance values and Studio-only Continue stay intact. Rewards10/40 Fans and5 Awareness are ACTIVE/TRIAL; all rank/payout plans are deterministic and once-only. No UI mutation authority, no retroactive award migration.

## Tasks

- [x] 1. Capture genuine preceding players/eight-rival world and full source fence before implementation. Preserve source/input evidence.
- [x] 2. Test-first pure ranking/reward plan with0/1/2/3+ candidates, ties, year/cutoff filtering, repeat wins, exact Review and sales independence. Own annual_awards_rules.gd and verify_annual_awards_rules.gd.
- [x] 3. Test-first chronological Fan receipts and extended Promotion provenance. Own award_receipts.gd, studio_fanbase.gd, StudioCheckpoint award validation and focused receipt verifier. Preserve every no-award legacy result.
- [x] 4. Test-first global ledger/world/checkpoint integration and exact prior-source restoration. Preflight all recipients; prove December boundary, offsets, no catch-up, tamper rejection, once-only replay, failed/successful launch, deterministic current/old cold Continue. Primary owns rival_world.gd, rival_world_checkpoint.gd and annual_awards_ledger.gd.
- [x] 5. Test-first standalone shared-style ceremony and preference migration. Own annual_awards_ceremony.gd, settings store/menu and UI verifier. Native ten-stage long-name/sparse/tie/resize/skip checks at1152/1280.
- [x] 6. Integrate Gameplay-owned durable Studio overlay, hidden retained phase/HUD, Pause/F8 exclusion, saved-stage resume and shared entrance/exit. Main agent reconciles UI implementer's exact APIs; no duplicate implementation.
- [x] 7. Run focused/maintained regressions and actual legal world through first ceremony, exact failed/successful bank usage, current and genuine previous saves, then native full flow. Retain failures, inspect final diffs/source pins and obtain independent review.
- [x] 8. Update design/decisions/current state/TODO and dated session log with actual results/limits. No final balance/human pacing/package or no-lag claim from automated checks.

## Review focus

Same-cycle pre/post award launches must replay Fans/consume only future banks; reject partial/forged global results and duplicate owner receipts; yearly migration cannot pay catch-up; Settings/Continue cannot bypass first mandatory ceremony or duplicate rewards; UI async save/teardown/double input must preserve Studio visibility/focus and exact staged progress.

Completed2026-11-01. [Final evidence and boundaries](../../findings/annual-awards-20261031-v1/README.md). All eight tasks completed; final reward balance, human pacing, broad performance/device and export gates remain separate.
