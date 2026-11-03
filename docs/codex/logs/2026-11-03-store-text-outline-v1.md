# Feature Store floating text outline — 2026-11-03

Branch `main`, HEAD `529aeac81bef9a36600761a35d8518f2a75f993c`; preserved pre-existing edits and `.codex-godot-temp`. No commit, push, or export.

Following the user's screenshot, floating engine title, library summary, zoom/help, legend and budget text no longer paint opaque rectangles over the Feature map. Their text has a 2 px Electric Indigo outline and existing black shadow. Store buttons and explanatory tooltip surfaces remain. This supersedes the former opaque standalone text backgrounds, without changing graph data, actions or prices.

Changed `patch-notes/scripts/ui/feature_store.gd`, `patch-notes/scripts/ui/feature_store_map.gd`, the exact pre-change compatibility entry in `patch-notes/scripts/market/rival_world_checkpoint.gd`, `docs/codex/design/ui-design-system.md` and `docs/codex/CURRENT_STATE.md`. Checks and screenshot are retained in `docs/codex/findings/store-text-outline-20261103-v1/`.

Godot 4.7.1 isolated-profile checks with dummy audio:

- Red-before check: 8 expected label styling failures, queue/map and tooltip checks passed.
- Real Studio and Engine Feature Store check: headless 10/0 and native OpenGL 10/0; visually inspected `native/store.png`.
- Actual preceding paired save: 4/0; whole typed player/finance/history/RNG and rival world preserved, unknown source rejected. Only exact preceding source `df60dc3e95c17266d01069846c79109a605dd824e3cd7f58e9946072657c1f83` was added to the existing compatibility validation.

The focused UI check verifies presentation and existing control presence, not a new full transaction or export acceptance run. The current execution queue was not edited.
