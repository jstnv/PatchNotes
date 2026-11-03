# Feature Store lower-tree layout — 2026-11-03

Branch `main`, HEAD `529aeac81bef9a36600761a35d8518f2a75f993c`. Existing worktree edits and `.codex-godot-temp` preserved. No commit, push, or export.

The user requested more horizontally spread Gameplay and Story & World trees with their main roots aligned two tiles below Scrolling. Lives System and Simple Story now occupy symmetric x=-3 and x=3, y=2 on the existing 212 px grid, while Scrolling remains y=0. Both branches fan farther outward; other independent roots remain in their existing branch families. A neutral four-segment stem routes from each lower side of the center around its outside edge to the adjacent main root. All nodes and headers remain outside/inside the center respectively, as intended; prerequisites, card data, prices, actions, and saves do not change.

Changed `patch-notes/scripts/ui/feature_store_layout.gd`, `patch-notes/scripts/ui/feature_store_map.gd`, the exact predecessor entry in `patch-notes/scripts/market/rival_world_checkpoint.gd`, `docs/codex/design/feature-store-progression.md`, `docs/codex/design/ui-design-system.md`, and `docs/codex/CURRENT_STATE.md`. Evidence and screenshot: `docs/codex/findings/store-lower-trees-20261103-v1/`.

Godot 4.7.1, isolated profiles and dummy audio:

- A first full-new-save red attempt timed out during the existing asynchronous fixture setup; retained as `before`. A separate real Feature Store mounted from a fresh legal simulation session produced three expected red checks for the old row, asymmetry and narrow branches.
- Final direct real-Store layout: 19/0 headless and 19/0 native OpenGL. Checked anchor row and symmetry, wider branches, all header orientations, empty center, non-overlapping card footprints, local edge coverage, and clear orthogonal stems. Inspected `native/store.png`.
- Maintained three-viewport `verify_feature_store_radial.gd`: 255/0 headless, including same-category prerequisites/outward branches, overview, zoom, inspection, Back and unchanged passive finance state.
- Genuine immediately preceding paired save: 4/0, preserving whole typed player/finance/history/RNG and rival world while rejecting an unknown identity. Only source `885e752317658d9f7749c0caf9cde052910ac62cc475e0cdeb472ea8c20565ae` was added to the existing exact predecessor validation.

The native check mounts the actual Store directly rather than replaying a complete career. Full exported-build, performance and device acceptance remain outside this pass. The queue was not edited.
