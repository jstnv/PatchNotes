# Post-game priority overlay teardown — 2026-11-03

Branch `main`, HEAD `529aeac81bef9a36600761a35d8518f2a75f993c`. Pre-existing edits and `.codex-godot-temp` preserved. No commit, push, or export.

The user reported `PriorityOverlay._layout_cover: Cannot call method 'get_visible_rect' on a null value` after completing a game. The production priority overlay was connected to persistent HUD and viewport layout signals; after a phase was detached but before its queued deletion, those signals could call it with no viewport. The red test reproduced the same runtime exception by detaching a phase-owned overlay then emitting HUD/viewport signals. Overlay teardown now disconnects those observers, re-entry reconnects them, rebinding replaces old observers, and detached callbacks are guarded.

The screenshot also showed repeated missing-artwork warnings. The referenced artwork files are absent; the existing background fallback remains. `CardView` now warns once per missing/invalid resource path per session instead of once on every view refresh; a later successfully available resource is still loaded and clears its warning state. No art assets were invented or replaced.

Changed `patch-notes/scripts/ui/priority_overlay.gd`, `patch-notes/scripts/cards/card_view.gd`, the exact preceding compatibility entry in `patch-notes/scripts/market/rival_world_checkpoint.gd`, `docs/codex/design/ui-design-system.md`, and `docs/codex/CURRENT_STATE.md`. Findings and exact receipts are under `docs/codex/findings/priority-overlay-exit-20261103-v1/`.

Godot 4.7.1, isolated profiles and dummy audio:

- Reproduction before fix: detached callbacks produced the exact null-viewport script error. Final lifecycle checks: 5/0 headless and 5/0 native, including late callbacks, re-entry and rebinding.
- Real Gameplay/HUD transition with a synthetic finalized Beta project: maintained release-menu check 49/0 headless and 49/0 native, including Launch to Review/Studio. This is not a complete played career.
- Priority influence regression 306/0 headless; initial priority cover native 3/0; card-frame regression 2257/0. Repeating the missing-art fixture emitted 16 identical warnings before versus one after across eight refreshed/reused views; real available art and fallback checks passed.
- Genuine prior paired checkpoint 4/0, including exact player/finance/history/RNG and rival state, with unknown identity rejected. Only exact predecessor `4f63f0aa608ce7bf418a3cf780641a0f0187016e874c1f9ad6d79a6ecaa621b7` was added to existing compatibility validation.
- `verify_gameplay_hud_overlay.gd` reported 17 failures in its broader legacy fixture. It still expects enabled initial Design priority editing, 10–75 slider bounds and old redraw labels, whereas current phase-flow/priority rules use different UI/bounds. The maintained priority chart and release transition suites above pass; the legacy fixture was not changed or claimed passing.

Known missing art still produces one warning per missing path; it has not been supplied in this pass. Full played-career, exported-build and device acceptance remain unverified. The execution queue was not edited.
