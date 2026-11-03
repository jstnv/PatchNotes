# Feature Store horizontal lower headings — 2026-11-03

Branch `main`, HEAD `529aeac81bef9a36600761a35d8518f2a75f993c`. Existing worktree edits and `.codex-godot-temp` preserved; no commit, push, or export.

The user's requested Gameplay and Story & World headers now read horizontally along the lower interior of the existing center square. Visuals and Audio remain vertical, and Technology & Tools remains horizontal. Store nodes, connections, actions, gameplay and save data are unchanged. Updated the maintained radial check's expected orientations.

Changed `patch-notes/scripts/ui/feature_store_map.gd`, `patch-notes/scripts/debug/verify_feature_store_radial.gd`, the exact preceding compatibility entry in `patch-notes/scripts/market/rival_world_checkpoint.gd`, `docs/codex/design/ui-design-system.md`, and `docs/codex/CURRENT_STATE.md`. Evidence lives in `docs/codex/findings/store-horizontal-headings-20261103-v1/`.

Godot 4.7.1, isolated profiles and dummy audio:

- Before: focused real-Store check showed the two requested orientation failures.
- After: headless 14/0 and native OpenGL 14/0; all headings inside the square, both changed labels fit without overlapping cards or headers, all 50 nodes and queue controls present. Native screenshot inspected at `native/store.png`.
- Genuine immediately preceding paired save 4/0: complete typed player, finance, history, RNG and rival state retained; unknown source rejected. Added only exact preceding source `2e56c2a16fe44e056f10a78a1a38f48793c4d987102d9c76b1236982a3a1772a` to existing compatibility validation.

The focused checks are not a full Store transaction, release, or exported-build acceptance. The execution queue was not edited.
