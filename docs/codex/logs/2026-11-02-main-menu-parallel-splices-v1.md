# Parallel Main Menu splices — 2026-11-02

The user requested that the title-bar splices follow the angles of their adjacent ramps. Branch `main`, HEAD `529aeac81bef9a36600761a35d8518f2a75f993c`; prior edits and `.codex-godot-temp` preserved. No commit, push or export.

`patch-notes/scripts/ui/arcade_backdrop.gd` derives the top and bottom splice slopes from their existing ramp geometry, centers each gap at its extrusion and maintains the existing 8 px horizontal separation, orange/mint fills and cream outlines. Other menu destinations retain their prior appearance. `patch-notes/scripts/market/rival_world_checkpoint.gd` accepts the exact verified preceding runtime identity; no gameplay data or rules change.

Receipts in `docs/codex/findings/main-menu-parallel-splices-20261102-v1/`: initial native RED lacked angled splice geometry. Native 19/0 verifies both cross products, separation, joint positions and title/setup navigation at four window sizes; `native/menu.png` is the inspected 1280×720 result. Native analyzer 33/0 and genuine preceding player/world pair 4/0 pass; finance/history/RNG remain intact and an unknown source is rejected. Existing Godot shutdown warnings remain. Physical-device and exported-build acceptance were not run.
