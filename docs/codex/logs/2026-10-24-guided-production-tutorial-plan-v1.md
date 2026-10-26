# Guided production tutorial implementation plan

> **For agentic workers:** execute inline with the executing-plans skill, one overlapping canonical implementation. Preserve the shared dirty checkout and `.codex-godot-temp`; use immutable test copies/private profiles. No commit/push.

**Goal:** offer a first-Studio optional scripted practice tutorial and return to the identical real Studio.

**Architecture:** scene-independent practice state machine using canonical card definitions/shared production resolvers; a dedicated tutorial CanvasLayer reusing CardFan/CardView/HandPresentation; separate local onboarding preferences. Gameplay owns invitation, visibility and return. Existing Studio tips provide replay.

**Tech Stack:** Godot4.7.1 GDScript, existing native/headless frozen-copy checks.

**Spec:** [guided-production-tutorial.md](../design/guided-production-tutorial.md).

## Constraints and review focus

No actual Studio/calendar/finance/rival/RNG/checkpoint mutation during practice; no real release or live draw override; no new save schema; Beta retains Marketing/QA. Review stale/double clicks, early exit during animations, first-entry/load races, preference write errors, focus/layout and exact source compatibility. User-authorized private screenshot uploads are a separate completed delivery, recorded with metadata readback.

- [x] **1. Model RED → GREEN:** new `scripts/debug/verify_guided_tutorial_model.gd`; implement `scripts/tutorial/guided_production_model.gd` and `onboarding_preferences.gd`. Pin four-/seven-card pools, shared formulas, redraw and all legal/rejected transitions; preferences read/write/corruption/failure.
- [x] **2. UI and lifecycle:** `scripts/ui/guided_production_tutorial.gd`; integrate `gameplay.gd`, `ui/tutorial_overlay.gd`. Two questions, scripted interactive practice, existing rhythm/SFX, busy/focus/Exit gating and Studio tips replay. Implement exact prior editor/compiled source compatibility in the world codec.
- [x] **3. Focused behavior/native acceptance:** maintained UI verifier plus current phase/help/pause/checkpoint suites on immutable final source. Complete/skip/replay/early Exit and disk/full-state/RNG identity checks; capture/inspect both sizes. Review and repair concrete failures, preserving originals.
- [x] **4. Closeout:** dated source-pinned findings/log, minimal TODO/CURRENT_STATE/core design updates, exact checks/limits and phone-accessible screenshot links. Keep the existing v0.02 package immutable; do not claim its screenshots/build contain this later tutorial.
