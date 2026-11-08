# Translucent main-panel experiment — 2026-11-04

The user requested an experiment allowing the persistent circuit threads to show through main panels. Started on `main`, HEAD `2ad3cf2b2bb63d324a970b10864b0f69843dcb1a`, preserving existing edits, real saves and `.codex-godot-temp`.

The shared `FolderPanel` now has a separate copy of the established indigo style with a 0.70 background alpha and its original fully opaque border, corners and margins. The existing `DocumentPanel`, ordinary popup/list theme styles, buttons and HUD styles retain their previous fills. A custom confirmation that duplicates `FolderPanel` also inherits the translucent background. The underlying resource was previously shared with lists and windows, so the new style avoids changing those shared resources. This is a local visual trial; the user's preferred opacity remains open.

Checks used isolated profiles under `sims/panel-transparency-20261104/`:

- The theme probe failed on the original fully opaque main panel (`red/stdout.log`); the final probe passes at 0.70 fill alpha and 1.0 border, document and popup alpha (`final-theme/stdout.log`).
- A native actual Studio render with fixed test pulses compared frames with the thread ribbon on and off: 125 sampled pixels within the root and 347 within the companion differed (`final-render/stdout.log`, `final-render/studio.png`). These are controlled test pulses, not a live-audio/device acceptance claim. The image was visually inspected.
- Native Studio motion: 59/59 (`final-motion/stdout.log`); native actual Studio destination/HUD/Bank layering: 56/56 (`final-slide-layer/stdout.log`); native Post Game Review: 30/30 across three sizes (`review-native/stdout.log`). The Studio scene emitted an existing invalid-UID fallback warning.
- The earlier 0.78-opacity renders are retained as comparison evidence, not the final trial.

Inspected transition captures show underlying panel content faintly through a translucent panel while they overlap; this is an observed visual tradeoff of the trial and can be revisited. The resource is a `.tres` theme; the current checkpoint source-identity algorithm hashes script and JSON inputs rather than this theme. No gameplay rules, save data, real profiles, commit, push or export were changed. The broader performance audit and cleanup remain paused; other-device and exported-build visual acceptance are open.
