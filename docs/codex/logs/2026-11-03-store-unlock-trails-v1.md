# Feature Store unlock trails — 2026-11-03

Branch `main`, HEAD `529aeac81bef9a36600761a35d8518f2a75f993c`. Existing edits and `.codex-godot-temp` preserved. No commit, push, or export.

The selected engine's implemented parents emit mint trails along existing same-category prerequisite routes toward unimplemented, unqueued children whose prerequisites and era gates are satisfied. Trails follow bends and a new pulse starts every 1.25 seconds. Eligibility is cached when the existing Store view refreshes; a separate non-interactive overlay redraws only while visible and eligible, without rebuilding offers or changing gameplay, finance, RNG, the catalog, or existing route geometry. Multiple parents each send a trail once the AND child is unlockable. Hidden Stores stop processing, and the selected engine controls ownership.

Changed `scripts/ui/feature_store_trails.gd` (new), `scripts/ui/feature_store.gd`, `scripts/ui/feature_store_map.gd`, the exact predecessor entry in `scripts/market/rival_world_checkpoint.gd`, `docs/codex/design/feature-store-progression.md`, `docs/codex/design/ui-design-system.md`, and `docs/codex/CURRENT_STATE.md`. Evidence is in `docs/codex/findings/store-unlock-trails-20261103-v1/`.

Checks with Godot 4.7.1, isolated profiles, and dummy audio:

- Red-before: actual Store check reported no trail layer. A first expanded check caught hidden/reopen processing and a rendered-pixel check caught a zero-sized overlay; both failures were fixed and retained in the findings.
- Final actual-Store behavior: 25/0 headless and 26/0 native OpenGL, including a real rendered pixel difference, 1.25-second cadence, path bend, queue/implementation transitions, AND prerequisites, engine switching, visibility lifecycle, input transparency, and unchanged real state/RNG during animation. Native screenshot `render-size/active-trail.png` visually inspected.
- Maintained `verify_feature_store_radial.gd`: 255/0 headless over three viewports, including navigation, map geometry, local prerequisite arrows, selection and unchanged passive finance state.
- Genuine immediately preceding paired player/world checkpoint: 4/0, including full finance/history/RNG equivalence and rejection of unknown identity. Only exact prior source `90d668d693c9a21af4f6f573b7fc22743d9391315a253a7e299a46308425f00c` added to existing compatibility validation.

These checks do not establish a broad frame-rate/performance guarantee, full exported-build behavior, or human/device acceptance. The execution queue was not edited.
