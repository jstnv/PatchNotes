# Studio theme integration — 2026-10-11

The user selected `crunch_time_studio_smooth_70bpm.mp3` and requested a shared key/time map for dynamic resequencing. That preview exactly matches the original music project's Studio_Smooth MP3. Its authoritative WAV/MIDI source is a C-minor arrangement, two semitones below the main theme.

`crunch_time_studio_smooth_D_minor.wav` resynthesizes the same arrangement in **D minor**. Every pitched note moves up two semitones; drum notes, onsets, durations and velocities remain unchanged. The separate original music project and preview are preserved. This is not a sped-up recording or an MP3-to-WAV conversion.

## Shared arrangement contract: `crunch-time-d-minor-70-v1`

- 70 BPM, 4/4, eight bars; quarter-note duration 6/7 seconds.
- 64 eighth-note steps per loop, each 3/7 seconds: unchanged 140 card activations per minute.
- Bar one/downbeat starts at sample zero, without count-in, silence padding or pickup offset.
- 48 kHz stereo; exactly 1,316,571 frames (27.4285625 seconds). Transport maps that rounded endpoint to exactly 64 steps.
- Bar harmony: **Dm9 | G13 | Cmaj9 | A7alt (flat-13 color) | Dm9 | Bbmaj9 | Em7b5 | A7b9**. All arrangements retain the same harmonic bar order; voicings and instrumentation may differ.
- Future dynamic themes must match this map and loop seam convention. A different tempo, bar count, key progression or introductory offset requires an explicit new map/transition design, not a silent metadata substitution.

Both WAVs run in one `AudioStreamSynchronized` playback. Successful Studio/Review/setup phase entry requests Studio; development, Contracts and Main Menu request the selected A/B main arrangement. Browsing Studio overlays does not change the cue. The next bar starts a one-quarter-note linear crossfade at the same phrase offset. A repeated request does not postpone it; leaving before it starts cancels it. A reverse request during a fade takes the following bar. Neither playback nor card timing restarts.

Gain evaluation uses corrected **mix position**, with absolute timestamps rather than accumulated frame deltas. Card presentation keeps its output-latency-corrected heard position. Both freeze on pause. Gains are applied by the main thread each frame and smoothed by Godot's mixer: this is a frame-quantized crossfade, not a sample-scheduled transition. Low frame rates catch up to the correct envelope; an application stall can delay the audible gain update until the next frame, while the two audio arrangements remain in phase.

## Reproduction and provenance

Run `python tools/audio/build_studio_theme.py` from the repository root (NumPy required). It uses the preserved procedural source snapshots under `tools/audio/studio_source/`, writes the D-minor WAV/MIDI and `tools/audio/studio_render.json`, and validates 432 note events, timing preservation, PCM bounds and loop seam. Original source/preview hashes and runtime evidence are in `docs/codex/findings/studio-theme-20261011-v1/`.

Synthesis and circular room reverb use the same original equations and deterministic noise as the user-provided arrangement. No new samples, SoundFonts, impulse responses or music services were used. The inherited [resource/authorship notes](LICENSE_NOTES.md) apply. Human listening/mix preference and final release review remain open.
