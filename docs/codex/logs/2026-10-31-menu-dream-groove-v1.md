# Dream Groove Main Menu integration — 2026-10-31

Branch `main`, HEAD `3a61522f18db7a2bae892cb8c5be1fee68cd4100`. The worktree contained extensive inherited gameplay, Store, documentation and test edits. This thread edited only the Audio transport/map/blend, the one phase-to-theme routing line in the already-dirty `gameplay_hud.gd`, its focused soundtrack verifier, Audio credits/provenance, and dated design/state records. Inherited changes and `.codex-godot-temp` were preserved. No commit, push or export.

User-supplied `C:/Users/64jus/Downloads/crunch_time_menu_dream_groove_final_v01.mp3` has SHA-256 `5d8eb00362f1f24ca5c4c09da87f5205f77aa68518f86f3819446dfc4fef71a7`. FFprobe reports an inconsistent 7.752-second duration; FFmpeg decodes roughly 27.46 seconds. The runtime WAV keeps precisely the first 1,316,571 48 kHz stereo frames in a plain 24-bit PCM RIFF container, SHA-256 `7ec49fb82919f1e40f8708b2cca83571453b943e518b6884bf8c0ebc37e386e7`. The first FFmpeg WAV used a WAVE_FORMAT_EXTENSIBLE header, which Godot rejected. Rebuilding the header as ordinary PCM preserved the decoded samples; the subsequent Godot import passed. The original MP3 was not altered.

`MENU` is stream 2 in the existing `AudioStreamSynchronized` transport. It starts audible on Main Menu and is selected again on title return. Development and Contracts still use selectable main A/B; Studio and Review still use Studio Smooth. The existing main/Studio blend and an independent menu blend use the same absolute mix cursor. Title-to-Studio leaves the menu on the next eighth-note pulse with a one-eighth-note fade. Other mode changes use the next bar and quarter-note fade. No transport seek/restart, music-grid or gameplay rule change was made.

Verification on Godot 4.7.1, isolated `.codex-godot-temp/AppData` profile, headless/Dummy audio:

- Final editor import: **PASS**, exit 0; menu PCM imported. The initial import failed on the extensible WAV header and is retained in `audio-menu-import-err.txt`.
- `verify_studio_soundtrack.gd`: **PASS**, 7,707 checks, 0 failures, exit 0. Covers all three exact-length streams, menu start, title-to-Studio cue and title return with transport identity, existing mode routes, loop/pause behavior and fast/ordinary boundaries. Output: `audio-menu-studio-final-{out,err}.txt`.
- `verify_soundtrack_sync.gd`: **PASS**, 3,503 checks, 0 failures, exit 0. Output: `audio-menu-sync-{out,err}.txt`.
- `verify_menu_visualizer.gd`: **PASS**, 116 checks, 0 failures, exit 0; observed peak 0.615910. Output: `audio-menu-visualizer-{out,err}.txt`.
- CRLF-aware owned `git diff --check`: **PASS**. Existing artwork warnings and ObjectDB fixture warnings appeared; no classified script/runtime errors in final focused checks.

Open: human listening for harmonic fit to the existing D-minor progression, the MP3-derived loop seam and crossfade feel; authorship/release clearance; native audio device and export acceptance. These focused checks do not prove old-save compatibility under the concurrently changing whole-source fingerprint. No broader save or release gate was run.
