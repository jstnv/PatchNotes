# Continuous pause music — 2026-10-18

Direct user request: continue the time map and soundtrack while paused, with a muffled/reverberant bathroom-at-a-house-party treatment. This supersedes the earlier music-freeze part of Esc pause. Gameplay remains paused.

## Implementation

- The always-processing Soundtrack keeps both synchronized WAV arrangements and the corrected, unwrapped audio clock running through SceneTree pause. Existing 70 BPM harmony, 140/minute card subdivision, loop assets and dynamic theme scheduling are unchanged.
- Music bus only: 24 dB/octave low-pass to 650 Hz, followed by room reverb (room 0.65, damping 0.45, 35 ms predelay, feedback 0.2, spread 0.8, wet 0.38, dry 0.8). Filter cutoff sweeps logarithmically, reverb fades over 0.3 seconds. Both effects are bypassed after resume. Settings retain ownership of bus mute/volume; SFX is separate. These are initial presentation mix choices, not final audible approval.
- On resume, Soundtrack publishes one shared whole-subdivision shift. Pending hand steps, bonus labels and the synergy banner keep their frozen pose until that phase of the ongoing music returns (less than one subdivision plus normal frame latency). Completed events are not replayed. The trace retains absolute beat indices and records each `music_resume` shift. Gameplay effects are still resolved once by the original action.
- The explicit `set_paused()` transport suspension/test seam still stops audio intentionally; the player-facing Esc menu does not call it.
- Updated the Pause article in How to Play. Exact pre-edit source `38f92c219924494964e5982c6ed7976a5d2fec97de6ea1a7565fdd4d7e6bb41e` is admitted through the existing narrow presentation-source list. All checkpoint schema/catalog/journal checks remain active; Studio-only Continue is unchanged.

## Evidence

All seven focused suites PASS on the final frozen source; all processes exit 0 with no script/runtime errors. [Exact commands/results](long-verified-v1/results.json), [source manifest](long-verified-v1/source.json), [source audit](audit.json), [pause/DSP/event traces](long-verified-v1/verify_pause_music.json). The 721 tested input files match canonical source byte-for-byte. Tests use private profiles and Dummy audio, never the player's save directory.

| Check | Result |
|---|---|
| Fresh isolated import | PASS |
| New pause music / DSP / two actual paused loops | 714/714 |
| Real Pause menu, hand, state/RNG, Settings and Continue | 64/64 |
| Existing soundtrack synchronization | 3,503/3,503 |
| Existing Studio theme transitions | 7,620/7,620 |
| Settings | 29/29 |
| How to Play | 288/288 |
| Actual prior-source world restore | 5/5; all saved fields preserved except source marker; unknown sources rejected |


The long pause observed two loops: 54.8843 audio seconds in 58.107 wall seconds on Dummy. The actual mixer capture measured impulse peak 0.96344 dry versus 0.00244 filtered, with late-tail energy 0.00000404 versus 0.01127. These demonstrate signal processing, not subjective mix or hardware-latency acceptance.

Final runtime identity: `81d4c3577b722bd2bbf552618ae3011cd9f8672f5ee83b3f4c0851c4aa750aed`. Actual pre-edit fixture: `38f92c219924494964e5982c6ed7976a5d2fec97de6ea1a7565fdd4d7e6bb41e`. [Restored frame](long-verified-v1/restored-world.json).

The new maintained verifier exercises actual mixer low-pass/reverb output with a captured impulse, pause/resume fades, volume/mute isolation, rapid toggles at 5 FPS, real arrangement switching across loop wrap, shared popup shift, and deterministic 1/4/7-card visual sequences at 60/5 FPS. Synthetic sizes test the scheduler and do not expand legal gameplay hands. Pauses occur during centering, rise, fall, popup lead and bonus motion, including multi-loop waits and another pause during rejoin. The long mode observes two actual audio loops while paused with a 90-second wall timeout.

## Retained test-development findings

- `check-v1`: two fixture assertions compared against the playback instance from before an intentional test seek; Godot replaces that instance on seek. The fixture now records its identity after seeking.
- `check-v2`: behavior passed, but synthetic rapid SFX needed a short audio-thread drain before test shutdown to avoid pending-playback resource errors. `check-v3` confirms clean shutdown.
- `check-v3`: Pause 64, original synchronization 3,503, Studio soundtrack 7,620 and Settings pass. The guide verifier still asserted the superseded soundtrack freeze; its assertion now requires continued audio and unchanged gameplay/RNG.
- `long-v1` and `long-final`: a wall-timer-based two-loop assertion failed under Dummy audio (the former recorded only 120 subdivisions during that nominal wait). The final test observes actual playback-led loop completion and records audio elapsed, wall elapsed and lap count. This does not establish real-device latency or performance.

## Limits and reproduction

No new export, graphical acceptance, speaker/headphone listening, hardware latency claim, full release gate, commit or push. Existing missing-artwork warnings and ObjectDB warnings at audio shutdown in the long pause and Studio soundtrack verifiers are recorded separately from script/runtime errors. Audible strength/room character still needs a playtest.

Use the bundled Python to run `run.py long-verified-v2 verify_pause_music verify_pause_menu verify_soundtrack_sync verify_studio_soundtrack verify_demo_settings verify_how_to_play verify_world_restore_file` into a fresh stage name; `long-` enables the bounded real-loop test. `before/verify_legacy_world.json` is the actual pre-edit save fixture. The release gate discovers `verify_pause_music.gd` automatically.

API references checked: [Godot reverb](https://docs.godotengine.org/en/stable/classes/class_audioeffectreverb.html), [Godot filter](https://docs.godotengine.org/en/stable/classes/class_audioeffectfilter.html).
