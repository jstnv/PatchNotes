# Production bass and hook visualizer — 2026-11-04

Started on `main` at `2ad3cf2b2bb63d324a970b10864b0f69843dcb1a`; tracked worktree was clean. The user requested orange Production bass and blue Production hook threads without further input. Preserved unrelated untracked files, `.codex-godot-temp`, and real saves.

## Investigation and implementation

The shared soundtrack exposes note clocks for menu and Studio music but not synchronized stream 0, the Production arrangement. Production therefore fell back to neutral generic audio trails. The red focused test recorded 11 expected failures out of 14 checks before runtime changes, retained at `.codex-godot-temp/production-visualizer-notes-red-20261104/godot.log`.

Added source-pinned Production A/B note maps: `FM synthesizer bass` drives orange and `FM synth melody` drives blue. The soundtrack now exposes its actual selected production variant, audible cursor and transition gain; the existing shared observer schedules notes against it. Playback, pool selection, card resolution, finance and RNG are unchanged. The manifest is explicitly included in the Windows export preset. The source WAVs are not byte-identical to their runtime mixes; zero-lag sampled correlations are 0.99387341 (A) and 0.99436435 (B). MIDI and both WAV hashes are recorded in the manifest. A has 49 bass and 42 hook note-ons; B has 49 bass and 50 hook note-ons.

Runtime files: `patch-notes/scripts/audio/soundtrack.gd`, `patch-notes/scripts/ui/menu_circuit_background.gd`, `patch-notes/assets/audio/crunch_time_70/production_visual_notes.json`, `patch-notes/export_presets.cfg`, and the single captured predecessor source in `patch-notes/scripts/market/rival_world_checkpoint.gd`. Added `tools/build_production_visual_notes.py`, `tools/tests/verify_production_visual_notes.py`, and the focused `verify_production_visualizer_notes.gd` and `verify_production_visualizer_live.gd` debug scripts. Updated the existing clock, Studio and menu integration verifier expectations for the additional audible Production clock. Updated this log, current state, TODO and UI design.

## Verification

- Source manifest verifier regenerated both maps from the source MIDI, verified hashes and alignment against the actual runtime/reference WAVs, and passed.
- `verify_production_visualizer_notes.gd`: 14/14 headless and native; both variants, blend gain, silent layers, deduplication, mute and mid-loop attachment. `.codex-godot-temp/production-visualizer-notes-green-{headless,native}-20261104/godot.log`.
- `verify_production_visualizer_live.gd`: 12/12 native with real audio and renderer in an actual Design card hand; both colors, nonzero Music spectrum, continuous player and mute suppression. `.codex-godot-temp/production-visualizer-hand-native-20261104/godot.log`; screenshot in its isolated profile inspected. Existing artwork and invalid-UID fallback warnings are retained in the log.
- Existing headless visual clock 19/19, Studio notes 28/28 and menu-note integration 13/13: `.codex-godot-temp/production-prior-clock-regressions-20261104/`. An initial menu test fixture omitted `menu_seconds` and errored; the corrected fixture and retry passed, with the original log retained.
- Exact preceding player/eight-rival pair restored with identical player and world data apart from expected source stamp, and unknown source rejected: `.codex-godot-temp/production-compat-20261104/verify.log`. Compatibility exception is limited to source `8b140acb4a65c45ca85556d24b7a87ca4eb251e05a795435606a73a785053d03`.
- Isolated Windows PCK export completed with no stderr; an independent empty-project reader loaded the pack and verified both Production maps and note counts. `.codex-godot-temp/production-notes-pack-20261104/export-out.log` and `pack-check-out.log`. This is asset coverage, not exported-game interaction.

The ordinary `python` command resolved to an inaccessible Windows app alias; rerunning the source-manifest verifier with the bundled Python succeeded.

Physical listening, full exported-game interaction and other-device acceptance are not claimed. No release EXE/ZIP, commit or push was requested in this turn.
