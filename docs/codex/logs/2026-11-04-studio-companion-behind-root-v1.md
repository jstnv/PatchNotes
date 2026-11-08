# 2026-11-04 — Studio submenu behind the root panel

Starting branch `main`, HEAD `2ad3cf2b2bb63d324a970b10864b0f69843dcb1a`. Preserved existing edits and `.codex-godot-temp`. The user corrected the previous companion treatment: Studio submenus must be behind the main Studio panel.

Changed `scripts/ui/studio_hub.gd` so the existing full-size, unclipped, fading midpoint slide renders below the Studio root, preserving the normal right-hand resting position, pointer passthrough, notices and HUD. The root retains its previously requested translucent fill; submenu content can be faintly visible through it during overlap. This supersedes the foreground layering in `2026-11-04-studio-companion-uncropped-v1.md`. Updated the related motion and real-Studio debug verifiers for the corrected layer.

One exact predecessor source identity, `032b72509e9e5587a463c64277edabd08e070d2139f1da9fcf6d15a2ccaa09d6`, was captured before runtime edits and added to the existing validated checkpoint predecessor list. This is a presentation-only change.

## Checks

- Pre-fix regression failed the corrected behind-root assertion (56/57): `sims/studio-behind-root-20261104/red/`.
- Final isolated headless Studio motion passed 57/57, including midpoint, fade, root layering, input, notice and navigation checks: `sims/studio-behind-root-20261104/motion-headless/`.
- Native real-Studio 1280×720 check passed 26/26, including entry and exit behind the root, no separate clipping boundary outside it, all four settled groups and pointer navigation into Engines. Inspected captures: `sims/studio-behind-root-20261104/real-native/captures/`.
- Native destination/HUD/Bank layering passed 68/68, including pointer/focus and finance/calendar/RNG preservation: `sims/studio-behind-root-20261104/layer-native/`. That run also reproduced the separately tracked Feature Store trail `Invalid polygon data, triangulation failed` renderer errors; its stderr is not clean.
- The preceding player/eight-rival pair restored with `player_exact=true`, `world_except_stamp_exact=true`, `unknown_rejected=true`, eight Studios: `sims/studio-behind-layer-20261104/restore/`. The previously added new-engine starter/old-save/Contract verifier passed 43/43 against this source: `sims/studio-behind-layer-20261104/engine-compat/`.

Existing gameplay scene UID fallback and test-exit ObjectDB warnings remain. Exported-build and other-device acceptance were not performed. The separate cleanup and performance audit remain paused. No commit, push or release build was made.
