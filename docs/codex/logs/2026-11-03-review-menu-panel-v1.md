# Post Game Review menu panel — 2026-11-03

Started on `main`, HEAD `df2448cc7a1c9490aa2880b5d413a3ba73ab588a`, preserving the existing uncommitted Store, window-preference and other work. Added the shared `FolderPanel` surface behind the existing Review layout in `scenes/phases/post_game_review.tscn`, with inset content and no input interception. The Review root owns both surface and content so existing entry/exit motion moves them together. Existing review tabs, reveal, Back, HUD and release values remain in place.

- Added `scripts/debug/verify_review_surface.gd`: 27/0 headless and 30/0 native at 900×600, 1152×648 and 1280×720, checking theme, bounds, input, tabs, entry motion and Back. Native screenshot inspected. Baseline without the panel failed 3/6 checks. Evidence: `.codex-godot-temp/review-surface-final-{headless,native}/`.
- Maintained `verify_release_menus.gd` passed 49/0 headless and 49/0 native, including launch Review, timed reveal, historical Summary/Review navigation and shared HUD. Evidence: `.codex-godot-temp/review-panel-release-{headless,native}/`.
- The scene-only change leaves runtime source identity `4e8abae4d9f9720b6d585094a317aed924d54be813b0b19e283fb347259b60e7` unchanged. A genuine isolated eight-rival predecessor pair restored exact player, finance, history and RNG state; unknown-source rejection passed. Evidence: `.codex-godot-temp/review-panel-source-identity/`.
- `git -c core.whitespace=cr-at-eol diff --check` passed. Native checks used isolated profiles and Dummy audio; no exported-build or physical-device acceptance is claimed.
