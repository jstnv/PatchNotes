# Main Menu bar splices — 2026-11-02

The user clarified that the top/bottom title bars should split at the angled extrusions with space between pieces, and the purple bar segment should be orange for now. Branch `main`, HEAD `529aeac81bef9a36600761a35d8518f2a75f993c`; prior edits and `.codex-godot-temp` preserved. No commit, push or export.

`patch-notes/scripts/ui/arcade_backdrop.gd` removes the unrelated interior color divisions and draws orange/mint pieces separated by an 8 px gap where each ramp meets its plateau. Existing cream outlines, accent marks, entrance transform and the non-title single-color path remain. `patch-notes/scripts/market/rival_world_checkpoint.gd` accepts the verified exact pre-change source identity; no gameplay state or rules change.

Receipts in `docs/codex/findings/main-menu-bar-splices-20261102-v1/`: initial native RED had 16 failures of 22 checks; final native layout 22/0 checks colors, gaps and accents at 1152×648, 1280×720, 1920×1080 and 720×600, plus setup/return. Native button wave 49/0 and analyzer 36/0 pass. Exact preceding player/world pair 4/0 restores before and after, preserves finance/history/RNG and rejects unknown identities. `live/menu-live.png` is the inspected 1280×720 result with the live circuit background. Existing Godot shutdown warnings remain; physical-device and exported-build acceptance were not run.
