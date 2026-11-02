# Engine Feature Implementation Tree layout plan

> Execute inline using the planning, test-driven-development and executing-plans workflows. No commit/push/export is requested.

**Goal:** Adopt the user-selected floating-controls v2 layout onto the current per-engine implementation workflow.

**Authority:** User's current instruction; selected candidate in `C:/Users/64jus/.codex/worktrees/613f/PatchNotes/docs/codex/logs/2026-11-01-feature-store-floating-controls-candidate-v2.md`; current `docs/codex/design/engine-features.md` supersession. The candidate's Research workflow is superseded. Canonical TODO did not yet contain its isolated queue entry at intake; record reconciliation rather than replacing current records.

**Architecture:** Change only FeatureStore and FeatureStoreMap presentation, preserving current RunState/Engine transactions. The graph fills the surface; Back/title/library and an engine-labelled Implementation Queue float above it, with opaque individual controls/text and gesture-transparent gaps. Compact zoom/Debug/help/legend float at the bottom. Open at74%; retain Show all and common Back. New completion supplies only its engine automatically; Public/licensed libraries remain read-only.

**Constraints:** Preserve existing edits, `.codex-godot-temp`, node/catalog positions/dependencies, prices, FIFO/down-payment/completion rules, Stage/Commit retirement, frozen projects/Contracts, saves/RNG and Studio-only Continue. Concurrent Audio owner controls Audio scripts/assets and GameplayHUD Studio cue; do not edit those. Retain failed checks. No automatic checks or new scheduling.

**Files:** Modify `patch-notes/scripts/ui/feature_store.gd`, `feature_store_map.gd`; add a focused layout/queue verifier under this finding. Reuse maintained Engine/Store/navigation checks. Record source snapshots, final scoped deltas, dated session log and canonical status.

**Review focus:** narrow/long-label layouts, engine switching with another engine at FIFO head, controls intercepting map gestures, rapid hide/reopen/detail transitions, public/licensed read-only access. Test each explicitly; native rendering and pointer acceptance are separate.

- [x] Save source baselines and add a focused geometry/engine-queue test; verify expected RED for current reserved layout/unnamed controls.
- [x] Transfer layout only, adapting current engine note and implementation controls; run focused test GREEN.
- [x] Run maintained Engine workflow, Store copy/navigation/grid and actual Studio-to-Engine-to-tree/Back checks; inspect native captures at supported sizes.
- [x] Review exact deltas/ownership, preserve explicit acceptance limits, update canonical task/design/state and dated log. Do not rebuild the previous ZIP without a new request.
