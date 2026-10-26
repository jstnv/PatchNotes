# Studio theme and common music map — 2026-10-11

## Delivered

User request: sequence to the attached Studio Smooth theme on Studio entry, match the main theme's key map, and establish one consistent time map for future themes. Implementation started on dirty `main` at `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; existing design-thread changes and `.codex-godot-temp` were preserved. No gameplay rules, simulation policy, saves, internal TODO, commit or push changed in this task.

The attachment is byte-identical to the local music project's MP3. That original arrangement was **C minor**, while main A/B use **D minor**. Preserved original synthesis sources regenerate Studio at D minor: +2 semitones for all pitched note events, identical timing/velocities/drum notes, no playback-speed change. The new WAV is 48 kHz stereo/24-bit, exactly1,316,571 frames. Both existing main WAV hashes remain unchanged. [Source assets](source-assets.json), [credits/hash audit](asset-hashes.json), [source pin](source-final.json), [reproduction script](../../../../tools/audio/build_studio_theme.py).

The shared map is 70 BPM, 4/4, eight bars,64 eighth-note subdivisions, with harmony **Dm9 | G13 | Cmaj9 | A7alt | Dm9 | Bbmaj9 | Em7b5 | A7b9**. Studio and main run together at identical phrase offsets. Studio/Review/setup requests Studio; development, Contracts and Main Menu request main. The next bar starts a one-quarter-note crossfade. Repeated cues do not postpone it; canceled and reversed requests are handled. The existing card clock remains140 activations/minute with mix/output-latency correction. Gameplay commits are untouched.

## Verification

| Check | Result / retained evidence |
|---|---|
| Original preview/source match | MP3 byte equality; original source hashes in `source-assets.json` |
| D-minor source/render |432 note-on/off events checked; all times/velocities/drums preserved, pitched notes +2; peak0.77999985, seam0.02473128; repeat render byte-identical. `tools/audio/studio_render.json` |
| Shared streams native probe | Common length and position wrap observed on Godot4.7.1. `sync-probe.log` |
| New focused suite, long run | **7,417 checks,0 failures**;80 simulated wraps at each60FPS/5FPS/1.1s/5s interval; pending/repeated/canceled/reversed cues; real Dummy-backend loops0→3, pause/resume,5FPS reverse, actual Gameplay initial Studio/development/launch/Contract/main-menu routes and restored-Studio presentation. `verify_studio_soundtrack-v2.log`, `studio-result-v2.json` |
| Windows audio backend | **6,415 checks,0 failures** with actual **WASAPI** driver, including a real loop wrap and0.010000003s mapped output-latency correction. `studio-wasapi.log`, `studio-wasapi-result.json` |
| Existing card/synergy music suite | **3,503 checks,0 failures**. `verify_soundtrack_sync-final.log` |
| Adjacent regression suites | Gameplay transitions, Beta finalization/launch, Pre-Development, Demo settings all pass. Logs/commands named `verify_*.log` / `.command.json` |
| Clean package | Import, Windows release export, **281-entry** PCK payload/hash/allowlist audit and isolated exported startup pass. [Build record](package/build-manifest.json), [package audit](package/pack-manifest-verified.json), `package/export-startup.command.json` |
| Source whitespace | `git -c core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol diff --check` passed for this task's edited paths |

Command records retain the exact Godot path, arguments and exit status. Checks use the established isolated-profile runner at `docs/codex/findings/checkpoint-runtime-v1/run_checks.py`; `PN_CARD_FRAME_OUTPUT` records traces, and `PN_AUDIO_LONG=1` enables the two complete real-time loops. The new maintained verifier is `res://scripts/debug/verify_studio_soundtrack.gd`. Windows-backend invocation adds `--audio-driver WASAPI` to the usual `--headless --path patch-notes --script ...` command. Export uses the existing `export-queue-v3/export.py` and `inspect.py` helpers with this finding's output folder. Test profiles/build copies remain local and ignored.

## Failures retained and evidence limits

- The first probe without the standard isolated profile crashed at engine startup before script output; it was terminated. The isolated-profile probe and all subsequent audio runs executed successfully.
- First focused suite (`v1`) found a floating-point fade endpoint leaving a tiny nonzero residue. The production envelope now returns the exact target gain at the endpoint. That first fixture also finalized Beta before its presentation setup; corrected the fixture ordering. Both final focused runs pass.
- The first adjacent Gameplay run had exit0 and its expected negative-scene errors, but the runner's error classifier did not recognize the added `-final` suffix. Re-running with its maintained suite name correctly classifies those known negative probes. The earlier log remains.
- Existing Windows certificate-store warnings and scene/artwork/ObjectDB warnings are retained in logs; no new parse/script failure is ignored.
- This is an aligned, **frame-quantized gain crossfade**, not an audio-thread sample-scheduled cue. Both WAV timelines stay aligned during low FPS/stalls; gain updates catch up when the main thread runs. Long stalls can delay the audible fade.
- Native backend assertions do not constitute human listening. Blend comfort, loudness, seamless perception, device-specific latency and final music acceptance remain open. The scene test's launch is an explicit constructed boundary fixture, not a fresh campaign or disk Continue proof. No whole-project regression/release readiness claim.

## Implementation and future arrangement contract

[Asset/time-map contract](../../../../patch-notes/assets/audio/crunch_time_70/STUDIO_THEME.md) documents zero-offset bar alignment, common endpoint, harmonic order and reproduction. Runtime files: `scripts/audio/{theme_map,theme_blend,music_grid,soundtrack}.gd`; phase binding in `scripts/ui/gameplay_hud.gd`; audio inventory in `data/audio_credits.json`. New WAV/MIDI and source snapshots preserve attribution and reproducibility.

Godot references used: [synchronized audio streams](https://docs.godotengine.org/en/stable/classes/class_audiostreamsynchronized.html), [WAV looping](https://docs.godotengine.org/en/stable/classes/class_audiostreamwav.html). Runtime results above are local measurements, not inferred solely from those API descriptions.
