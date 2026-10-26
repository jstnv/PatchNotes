# Feature Store Technology row spacing — 2026-10-22

Branch `main`, HEAD `0132c4da`. Shared uncommitted work was preserved; `.codex-godot-temp` was untouched. This pass changed only Store map placement, its layout verifier, this design/status record and this log. No commit or push.

## Request and change

The user asked to lower the first Technology & Tools row to just above 4-Color Palette and Music without obstructing branches. `feature_store_map.gd` now places the Technology tree after the two side trees, using their root coordinates: the complete Technology card-and-label footprint ends 48 world pixels above the side roots. The whole Technology tree, its cone and heading move together; its five roots remain horizontally aligned and its descendants still branch upward. Visuals/Audio rotated heading control boxes are shortened and recentered, keeping their visible headings while clearing the closer Technology row. Store data and acquisition rules were not edited.

## Changed source

- `patch-notes/scripts/ui/feature_store_map.gd` — relative Technology placement and upper side heading bounds.
- `patch-notes/scripts/debug/verify_feature_store_radial.gd` — root-row gap and actual cross-tree card/header clearance checks. The old disjoint category bounding-box assertion was replaced because the tighter cones legitimately interleave in their empty corners; card and heading footprints remain nonoverlapping, and neutral category routes are still checked for interior crossings.
- `docs/codex/design/feature-store-progression.md`, `docs/codex/CURRENT_STATE.md`, this log.

## Verification

Runner: `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe -X utf8 docs/codex/findings/store-gameplay-links-20261018-v1/run.py <stage> ...`, using a fresh isolated project/profile and Godot 4.7.1. [Exact final commands and exits](../findings/store-gameplay-links-20261018-v1/f/results.json) and [source snapshot](../findings/store-gameplay-links-20261018-v1/f/source.json).

- **RED:** the new row-gap assertion failed at all three verifier sizes on the prior placement: [prechange log](../findings/store-gameplay-links-20261018-v1/r/verify_feature_store_radial.log).
- **PASS:** final import; `verify_feature_store_radial` (213 assertions, 0 failures at 1152×648, 900×600 and 1280×720); `verify_feature_store` (67 assertions, 0 failures); native `capture_store_cones` (450 assertions, 0 failures). Results have exit code 0 and no recorded script/runtime errors.
- The final capture positions have the Technology row at y=340 and both side roots at y=560. Their 172-pixel card-and-label footprint leaves 48 pixels. [Native 1280×720 overview](../findings/store-gameplay-links-20261018-v1/f/store-overview-1280.png) and [1152×648 overview](../findings/store-gameplay-links-20261018-v1/f/store-overview-1152.png) were visually reviewed; cards and headings do not cover neighboring branches. Individual tree zoom captures are in the same evidence folder.
- `git diff --check` passed for the two runtime/verifier files.

The direct shared-checkout Godot launch crashed before verification; the repository's isolated runner completed. Audible or extended gameplay acceptance was not part of this presentation-only change.
