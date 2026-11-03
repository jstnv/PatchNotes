# Main Menu splice alignment — 2026-11-03

The user clarified that the diagonal gap must lie where the extrusion angle actually is, rather than parallel beside it. Branch `main`, HEAD `529aeac81bef9a36600761a35d8518f2a75f993c`; prior edits and `.codex-godot-temp` preserved. No commit, push or export.

`patch-notes/scripts/ui/arcade_backdrop.gd` positions each splice directly along its extrusion edge and simplifies the adjoining polygons to avoid a small extra colored plateau. Both parallel diagonals retain their 8 px horizontal separation, existing colors, outline and title-only behavior. `patch-notes/scripts/market/rival_world_checkpoint.gd` accepts the verified exact previous runtime identity; gameplay and saved state are unchanged.

Receipts in `docs/codex/findings/main-menu-splice-alignment-20261103-v1/`: native RED exposed 8 misaligned endpoints out of 22 checks; native GREEN 22/0 validates aligned endpoints, parallel angles, gap width and setup/return at four window sizes. Native analyzer 33/0 passes; the exact preceding player/world pair 4/0 passes before and after, preserving finance/history/RNG and rejecting unknown identities. `native/menu.png` shows the 1280×720 result. Existing Godot shutdown warnings remain; physical-device and exported-build acceptance were not run.
