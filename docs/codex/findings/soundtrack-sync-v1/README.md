# Crunch Time soundtrack / presentation grid prototype

2026-10-09, main at41c87c76fb4d3c06a5332d93f0e7b0997007475d; existing shared uncommitted work preserved. No commit/push. Internal TODO was not edited by this task.

## Playback and timing

User-selected `Tempo_70/WAV/crunch_time_A_jazz.wav` is the initial loop. Both original24-bit stereo48kHz WAV files are copied unchanged into `patch-notes/assets/audio/crunch_time_70/`; [hashes and sample metadata](assets.json). No MP3 is used at runtime. Source provenance notes are preserved, with a prototype audio-credits manifest; final commercial clearance remains separate.

One Soundtrack autoload owns the Music-bus player through menu/phase/scene changes. Existing volume/mute controls apply. Set `audio/soundtrack/prototype_variant` to `B` in `project.godot` and restart for the techno comparison; default is `A`. There is no live seek/track-switch gameplay control.

The clock uses playback position + time since last audio mix - output latency, clamped against backward jitter, following [Godot audio synchronization guidance](https://docs.godotengine.org/en/stable/tutorials/audio/sync_with_audio.html) and [AudioStreamPlayer](https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html). Godot WAV playback returns0 from its loop-count method ([engine implementation](https://github.com/godotengine/godot/blob/master/scene/resources/audio/audio_stream_wav.cpp)); actual tests reproduced this. Position unwrapping therefore tracks integer loops, using monotonic elapsed time only to disambiguate laps after long frames. Fractional timing remains playback-led. Output latency is cached and refreshed on bus-layout changes. Device suspension/reconnection and Bluetooth/display latency calibration are not verified.

Each eight-bar loop has64 eighth-note subdivisions. The WAV's1,316,571 frames are8.93microseconds shorter than the ideal27.428571429s; mapping its endpoint to exactly64 subdivisions avoids accumulating that quantization offset. Card cadence remains60/140s, with half for rise and half for fall. After the existing one-subdivision centering move, the first rise waits only to the next grid point. All subsequent base/bonus/exit bounces are contiguous music-driven Tween steps. Variable sequence lengths do not reset tempo or change triggered cards. Return/deal layout transitions retain their previous visual Tweens and do not resolve cards.

SceneTree pause or `Soundtrack.set_paused(true)` freezes audio and the presentation clock; mute does not freeze the transport. Scene replacement cancels obsolete presentation visuals while music continues. Confirmed gameplay action still executes exactly once before animation; all timed score callbacks change only display totals.

Trace entries include card index, event, beat_index (eighth-note units; score peaks at+.5), scheduled_seconds, observed music_seconds, lateness_seconds and wall msec. Per-hand traces reset on the next hand. [Actual native hand traces](actual-hand-traces.json); [synthetic sequence traces](sync-final/fit.json); [summary](summary.json).

## Verification

Commands use the existing focused runner copied into this findings folder, fresh profiles and verifier-only checkpoint lease isolation. `run.py LABEL SCRIPT [render]` invokes the pinned Godot4.7.1 console executable; every run retains exact command, errors, source and driver hashes.

- `run.py import import-v2`: import passes.
- `PN_AUDIO_LONG=1; run.py sync-final verify_soundtrack_sync.gd render`: **3385 checks, zero failures**, Windows WASAPI/OpenGL, including two complete real-time WAV loops, manual and SceneTree pause/resume, persistent transport,1000 modeled boundaries,24 sequence/frame-rate combinations, and empty card-focus style. Production four-card base and specialization passes covered;1/3/7-card cases are scheduler-only synthetic lists, not newly legal gameplay hands. Frame steps1/60s,1/5s and1.1s preserve once-only event order and exact grid deadlines. Events arriving after missed frames catch up once; skipped visual frames cannot be recreated.
- `run.py motion-final verify_card_motion.gd`: existing focused verifier passes with zero failures. Design/Alpha/Beta/Contract, redraw, cancellation, rejected/unaffordable actions, authoritative totals and four-bounce specialization invariants covered. Its old first-score wall wait now observes the actual score event because initial grid alignment is variable.68 timed headless events show0.588–6.702ms lateness; this is not measured physical speaker/display latency.
- `run.py settings-final verify_demo_settings.gd`, then `settings-cleanup`: pass volume/mute/settings and navigation checks. Cleanup variant includes an explicit Soundtrack exit stop; timing code is otherwise identical to the completed long-loop/motion runs.
- `run.py focus-capture capture.gd render`: selected card receives actual keyboard focus with an empty local focus style, at1152x648 and1280x720; screenshot inspected. Gold selection outline and keyboard focus behavior remain. No cyan card border.
- Focused `git diff --check`: pass.

## Preserved failures / limits

Initial import caught one newly written non-UTF8 punctuation byte in settings copy; corrected. Initial wrap tests caught reliance on the WAV loop-count stub; replaced with tested position unwrapping. First motion run passed behavior but its source hash changed when the focus-style fix landed, so it was rejected and rerun as motion-final on stable source. These originals remain intact.

Abrupt headless shutdown while WAV playback is active warns about two retained audio objects (AudioStreamWAV/AudioStreamPlaybackWAV), even with an exit stop. A separate explicit stop plus100ms drain probe exits without that warning; logs in `shutdown/`. This teardown limitation is recorded, not hidden by the error scan. The WASAPI long test exited without that warning. No unrelated quit-flow changes were made.

Still needed: human audible A/B preference, loop seam/click evaluation, perceived beat alignment on target speakers/headphones, output-device changes and real low-FPS feel. At very low FPS callbacks remain correct but rises/peaks can be visually skipped. No refreshed Windows export or full-suite/release-ready claim. Sound effects remain absent. Card rules, scoring and the internal TODO are unchanged.
