# One-time menu opener and repeating Echo Reverb — 2026-10-31

Branch `main`; HEAD `3a61522f18db7a2bae892cb8c5be1fee68cd4100`. Inherited dirty gameplay/Store/documentation work was preserved. This follow-up changed only the Audio theme map/transport, its focused verifier, new Audio WAV/import and provenance/credits, and the relevant design/current-state lines. It did not edit the shared TODO, gameplay logic, saves or `.codex-godot-temp` evidence. No commit, push or export.

The user directed the previously integrated Dream Groove to be the one-time opener and supplied `C:/Users/64jus/Downloads/crunch_time_menu_theme_echo_reverb_v02.mp3` for the resequencing set. The new MP3 SHA-256 is `2bf4b7677a56c25e12833274da805222f2aff15981276b787e65339e43a65a5f`. Its duration header reports 7.752 seconds, while decoding yields approximately one 27.4-second phrase. The runtime asset is plain 24-bit PCM, 48 kHz stereo, exactly 1,316,571 frames: `crunch_time_menu_theme_echo_reverb_v02.wav`, SHA-256 `266af96b6be668dd7d6b2899d8701ff284e1ae24b01897ee36f3a8fe708c6c01`. The MP3 was not modified.

The startup Dream Groove and repeating Echo Reverb are two aligned streams within the existing synchronized playback. A 35 ms fade at the end of the first 8-bar phrase moves to Echo Reverb; the opener is then retired for the process lifetime. Leaving the title early retires it when the menu fade completes. Subsequent title returns use Echo Reverb. Main A/B still serve development and Contracts, Studio Smooth still serves Studio/Review, and all mode cues retain their existing shared music clock, bar/eighth-note boundaries, pause behavior and 140/minute card subdivision.

Godot 4.7.1, headless/Dummy, isolated `.codex-godot-temp/AppData`:

- Editor import **PASS**, exit 0; new PCM WAV imported without errors. Output `audio-menu-echo-import-{out,err}.txt`.
- `verify_studio_soundtrack.gd` **PASS**, 7,717 checks, 0 failures, exit 0. Covers four exact-length streams, one-time opener retirement, Echo takeover, title return, mode cues, playback identity, pause and loop timing. Output `audio-menu-echo-studio-{out,err}.txt`.
- `verify_soundtrack_sync.gd` **PASS**, 3,503 checks, 0 failures, exit 0. Output `audio-menu-echo-verify_soundtrack_sync-{out,err}.txt`.
- `verify_menu_visualizer.gd` **PASS**, 116 checks, 0 failures, exit 0, peak 0.592913. Output `audio-menu-echo-verify_menu_visualizer-{out,err}.txt`.
- Audio credits parse as JSON with seven shipped assets; source/output SHA-256 checked; CRLF-aware owned `git diff --check` **PASS**.

Open: listening judgment for the opener-to-Echo seam, harmonic compatibility and mode blends, plus release rights and native-device/export acceptance. Focused checks do not establish old-save compatibility under the concurrently changing whole-source fingerprint. The present menu resequencing set contains one repeating track; further variations require separate supplied/selected assets.
