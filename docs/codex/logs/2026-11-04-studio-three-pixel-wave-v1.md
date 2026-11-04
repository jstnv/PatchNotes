# Studio three-pixel button wave — 2026-11-04

Started on `main` at HEAD `72edd6b4eb0f139fca2d1803248d957b1f737f18` with the previous Dream Synth, Studio notice and Studio bass/hook visualizer work uncommitted. Those edits and `.codex-godot-temp` were preserved.

The user requested three pixels of total Studio-button bounce and the hover stretch to reach the same minimum and maximum positions. Set the Studio wave travel to 3.0 and its period to `3.6 * 3.0 / 7.0`, retaining the existing travel/period speed. Adjusted the fully stretched pose to the union of the normal button's two bounce extremes; both remain one pixel inside the visible inner panel border. Preserved wave phases, hover easing, navigation and gameplay behavior.

Changes: `patch-notes/scripts/ui/studio_hub.gd`, `studio_button_wave.gd`, `scripts/debug/verify_studio_wave_bounds.gd`, two superseded hover assertions in `verify_studio_panel_motion.gd`, and one exact predecessor in `scripts/market/rival_world_checkpoint.gd`. Updated `CURRENT_STATE.md`, `TODO.md` and `design/ui-design-system.md`.

- Before the fix, the focused regression failed its 24 bounce/hover assertions across four buttons and two sizes. `.codex-godot-temp/studio-wave-bounds-baseline-20261104/run.log`.
- Final focused checks: 25/25 headless and 27/27 native, including two native captures, exact 3-pixel travel, hover limits and unchanged movement-speed ratio. `.codex-godot-temp/studio-wave-bounds-headless-final-20261104/run.log` and `studio-wave-bounds-native-final-20261104/run.log`.
- Native existing Studio motion/navigation regression: 48/48, including pointer, keyboard, resize and unchanged finance/calendar/ownership/RNG. `.codex-godot-temp/studio-bounce-motion-native-final-20261104/run.log`. The initial run retained one failure in an outdated second two-pixel assertion; the assertion was updated to the new requested endpoint and the rerun passed.
- Captured exact preceding source `35dfed1c2b25d7758b1eaa588e6e2c37a0c1da9ff0fc81436af010ce720cb2db`; the final isolated player/eight-rival pair restored exactly except the current source stamp, and unknown source was rejected. `.codex-godot-temp/studio-bounce-compat-final-20261104/verify.log`.

No commit, push, executable rebuild or exported-build/device acceptance was performed in this pass.
