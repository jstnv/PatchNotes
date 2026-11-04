# Persistent Dream Synth threads — 2026-11-04

## Scope and source

Branch `main`; starting HEAD `72edd6b4eb0f139fca2d1803248d957b1f737f18`. The pre-existing TODO addition was the approved handoff; other worktree evidence and `.codex-godot-temp` were preserved. The user asked for the visualizer to persist throughout the game. The existing single observer already transfers between scenes, so it was retained and checked rather than replaced. The approved [source-pinned handoff](2026-11-04-approved-dream-synth-threads-handoff.md) and [source evidence](../findings/dream-synth-note-paths-20261103-v2/manifest.json) define the Dream Groove-only note treatment.

## Changes

- Rebuilt `patch-notes/assets/boot/sequence_v1/menu_visual_notes.json` and updated its builder and independent verifier. The blue source is exclusively `Dream Groove chord synth`; same-frame/same-pitch duplicates collapse to the strongest velocity, distinct pitches and later attacks remain. Bass arrays match the previous map for all five segments. Startup, A, B, menu each have 80 synth attacks; switch has 19.
- `circuit_pulse_field.gd`, `menu_circuit_background.gd` and `circuit_glow.gdshader` route bass and synth to disjoint starting lanes, prevent blue forks, preserve orange junction behavior, and draw muted/unidentified-track fallback as neutral. The mapped boot/menu notes use their existing actual playback clocks. Other soundtracks have no approved isolated note map and therefore use neutral spectrum-reactive trails, not fabricated instrument notes.
- Added exact previous source `870b788c4ab78798f55c130a02e795646e96841a79e9db28b1a6bc8580d2e800` to the existing `rival_world_checkpoint.gd` compatibility list. The captured predecessor is a genuine paired player/eight-rival checkpoint; no broader source exemption was added.
- Added route, stream and native neutral-render debug checks; expanded the existing title and pause checks for neutral fallback and ownership across scenes. Updated TODO, current state and UI design. The portable handoff and small source-evidence files were copied from the approved design worktree; the large approved preview remains at its linked original location.

## Checks and evidence

- Source verifier: 543 total bass/synth events, zero failures; original WAV-to-runtime PCM and composite stream checks passed. Bass events match HEAD exactly. The updated verifier rejected the previous combined-layer blue map for each of the five segments.
- `verify_dream_synth_routes.gd`: headless 16/16; baseline before changes failed six intended assertions. Checks include distinct routes, intersections, unsplit synth, retained bass fork, note deduplication and neutral unknown/muted fallback.
- `verify_dream_synth_streams.gd`: headless 4/4; 384 note events across startup and alternating loops, all scheduled and admitted with correct route/split behavior.
- `verify_title_circuits.gd`: headless 234/234, including unknown and muted neutral fallback.
- `verify_pause_menu.gd`: headless 86/86, including the same active background and single analyzer through title, new-save loading, invitation, guided practice, Studio, Continue loading, production, pause and return. Pause animation progresses and gameplay/RNG checks pass.
- `verify_menu_visualizer.gd`: native Windows/OpenGL, default audio, 36/36; actual FFT peak 0.571, five viewport sizes, mute, volume, navigation and analyzer teardown.
- `verify_visual_note_clocks.gd`: native Windows/default audio, 19/19; real boot and switch clocks plus deterministic overlapping-clock projection.
- `verify_dream_synth_neutral_render.gd`: native NVIDIA OpenGL 3.3, two neutral and zero non-neutral pulses; capture inspected. Isolated `.codex-godot-temp/visualizer-neutral-final`.
- Isolated prior player/eight-rival pair restored exactly except expected source stamp; unknown source rejected; final-source rerun exit 0. `.codex-godot-temp/visualizer-persistence-compat-final/verify.log`.

## Retained failures and limits

The first stream test used the candidate's preview-only `Soundtrack.preview_seconds`, absent from the actual game, and timed out after the GDScript error. The harness was corrected to use the real shared note timeline; its rerun passed as above. Headless lifecycle runs emitted existing missing-art warnings and an ObjectDB exit warning. Native tests used actual device playback and observed audio, but no physical listening was performed. Full exported-build and other-device acceptance remain open. No performance-task work, gameplay balancing, commit, push or export was performed in this pass.
