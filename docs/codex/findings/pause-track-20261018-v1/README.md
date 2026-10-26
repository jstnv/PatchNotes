# Pause track continuity follow-up — 2026-10-18

User likes the existing muffled/reverbed sound but reports that the track stops while paused. Preserve the mix. Dirty `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; no commit, push or export.

## Change and reproduction boundary

`Soundtrack` already always processes. Its child `AudioStreamPlayer` now explicitly uses `PROCESS_MODE_ALWAYS` as well, instead of relying on inherited process mode. No filter coefficients, fades, theme map, card timing, gameplay or pause-menu semantics changed. This makes the transport's intended pause behavior explicit. Godot documents that the player's pause property is affected by node pause notifications: [AudioStreamPlayer reference](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html#class-audiostreamplayer-property-stream-paused).

The reported stop did **not** reproduce in a fresh pre-change run. Both baseline and changed-source tests use the real Gameplay scene, Studio creation, Esc pause/resume, Windows **WASAPI**, actual soundtrack PCM capture on the Music bus, and the raw WAV playhead. This is transport hardening with verified behavior, not a claimed identified cause in the user's already-running session. Restart the game from the current project to load the explicit player configuration. No existing exported binary was refreshed.

## Results

[Runner](run.py), exact commands in `before/results.json` and `final/results.json`, private profiles/snapshots only. The actual before-world producer additionally ran `verify_legacy_world.gd` against the same immutable before project and passed 30/30 (`before/verify_legacy_world.log`).

- Baseline WASAPI 29/29: inherited player mode0 already advanced through pause.
- Final WASAPI 29/29: explicit player mode3; raw playhead advances 6.037333 seconds across twelve half-second paused observations, each containing nonzero actual filtered-song samples. Existing filter reaches full weight; gameplay remains unchanged; playback object remains identical. Resume clears the treatment normally.
- `verify_pause_music`:713/713 (DSP capture, short real wrap, rapid toggles, low-FPS and variable-length presentation). This pass did not repeat the optional two-full-loop test from the original pause-music task.
- `verify_pause_menu`:64/64; card synchronization3,503/3,503; Studio soundtrack7,620/7,620.
- Actual preceding Store-source world/Founder restore:5/5, exact state preserved with source marker only. Only exact source `580bd1331cdc4bca578230005e3ca4f9cc91ead0b03b78be3238bdb7c9fc5150` was added to the existing presentation allowlist. Unknown sources remain rejected by the separately passing Store migration suite.
- All final commands exit0 without script/errors. [Final source audit](final-source-audit.json) matches canonical runtime `f4303f0101e1971026080ec0b0acf3c817e96675fa190758d7c8651b8969a412`.

Changed runtime: `scripts/audio/soundtrack.gd`, `scripts/market/rival_world_checkpoint.gd`. Added `scripts/debug/verify_pause_track.gd` and UID. Mix character is retained from the user's positively received version. User-session root cause and exported-device listening are not claimed verified; this check proves fresh-project transport and mixed audio output using WASAPI.
