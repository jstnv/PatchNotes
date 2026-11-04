# Studio notice clearance — 2026-11-04

Started on `main` at HEAD `72edd6b4eb0f139fca2d1803248d957b1f737f18`, with the earlier Dream Synth visualizer work still uncommitted. Preserved that work and `.codex-godot-temp`.

The publisher unlock notice was inside the companion's clipped region, which starts before the idle Studio root's right edge. Its host was also below the companion in draw order. The notice could therefore be partly behind the idle Studio panel or covered by an open companion. The current publisher notice is the only user of this host; focused tours and challenge notices use separate layers.

Moved the existing notice host to a foreground sibling, positioned beyond the Studio panel's maximum idle offset, without changing the menu's slide behavior or the notification's dismissal and one-shot logic. Added a focused presentation regression and the exact captured preceding source `35b2bd3ce642ac9d99865692a7a9b1bb85aabbff6c5588bc93d464a046778562` to the established checkpoint predecessor list. No gameplay, economy or RNG rules changed.

- Before the fix, `.codex-godot-temp/studio-notice-clearance-baseline/run.log` reproduced three panel intersections. An initially reported 900×600 overflow used physical dimensions against Godot's scaled logical viewport; the corrected test uses the visible logical rect.
- Native `verify_studio_notice_clearance.gd`: 20/20, including actual pointer dismissal, open companion stacking, resize, and five wrapped publisher names; `.codex-godot-temp/studio-notice-wrapping-native/run.log`. Native selected-companion capture inspected at `.codex-godot-temp/studio-notice-clearance-native-final/appdata/Godot/app_userdata/Patch Notes/studio-notice-selected.png`.
- Native `verify_studio_panel_motion.gd`: 48/48, including navigation and finance, calendar, ownership and RNG preservation; `.codex-godot-temp/studio-notice-motion-final/run.log`.
- Headless `verify_publisher_list_progression.gd`: zero failures, including original publisher progression and dismissal; `.codex-godot-temp/studio-notice-publisher-progression-20261104/run.log`.
- Isolated prior player/eight-rival pair restored exactly except for the expected current source stamp; unknown source rejected. `.codex-godot-temp/studio-notice-compat-final-20261104/verify.log`.

Changed `patch-notes/scripts/ui/studio_hub.gd`, `patch-notes/scripts/market/rival_world_checkpoint.gd`, `patch-notes/scripts/debug/verify_studio_notice_clearance.gd`, and the Studio notice entries in `CURRENT_STATE.md`, `TODO.md`, and `design/ui-design-system.md`. The user's earlier uncommitted visualizer changes were preserved. Exported-build and other-device acceptance were not performed. No commit, push, or package was made.
