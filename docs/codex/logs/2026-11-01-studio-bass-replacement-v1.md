# Bass-led Studio WAV replacement — 2026-11-01

Branch `main`, HEAD `5fb0cfdf561c36cf27ffe09f1ad810b9fd5a579b`. The shared worktree was dirty. PN Implementation was active, so this Audio thread sent it the exact three-asset/credits boundary before copying. All unrelated work, `.codex-godot-temp` and the original Studio trio were preserved. This thread made no commit, push or export.

The three new Downloads attachments differ from the previously imported bass-led assets. All are ordinary stereo 48 kHz 24-bit PCM with exactly 1,316,571 frames. `Copy-Item` replaced only these asset bytes in `patch-notes/assets/audio/crunch_time_70/studio_pool/`; source and destination SHA-256 matched after each copy:

| File | Previous SHA-256 | New SHA-256 |
| --- | --- | --- |
| `crunch_time_studio_bass_led_idle_70bpm.wav` | `d42b571df760439362131f56ea77724c46fedca22e88a9a15926b82f6db5fb3e` | `b2a7bc0ca15e16a4f321d3050c94efde829d658a845ac494aa0ffd80569343e3` |
| `crunch_time_studio_bass_led_main_70bpm.wav` | `827bf1bd899fb882e6d6c288fdff1d9874a23776bc1b505e5438e2e322ca1714` | `32397e6c441fe121ca3cf151d69deb5fef87b31178be7b690fc4c9f144cf44aa` |
| `crunch_time_studio_bass_led_active_70bpm.wav` | `1a31e8c12b1c590a20079e11efb3e415b6bdad31ae7982517cbbdd8e88784014` | `88af0f23f30f91edbe228d72877628420410b76670f17090b1c0bf27e43687a1` |

Other owned files changed: `patch-notes/data/audio_credits.json` (three current hashes and source description), `patch-notes/assets/audio/crunch_time_70/studio_pool/STUDIO_POOL.md` (replacement provenance), `docs/codex/CURRENT_STATE.md`, `docs/codex/TODO.md` and this log. The existing three `.wav.import` metadata files are retained; Godot reimported the changed WAV data. No selection, transport, transition or gameplay script was edited for this replacement.

Godot 4.7.1, headless/Dummy, redirected `.codex-godot-temp/AppData`:

- Editor import: **PASS**, exit 0, no import errors. `studio-bass-replace-import-{out,err}.txt`.
- `verify_studio_pool.gd`: **PASS**, 1,828 checks, 0 failures, exit 0. Six-track compatibility, random/no-repeat choice, observed boundary switch, one-track-only gain and playback continuity. `studio-bass-replace-verify_studio_pool-{out,err}.txt`.
- `verify_studio_soundtrack.gd`: **PASS**, 7,727 checks, 0 failures, exit 0. Existing menu/phase transitions and music-clock behavior. `studio-bass-replace-verify_studio_soundtrack-{out,err}.txt`.
- Source/destination SHA-256 and PCM metadata: **PASS** for all three. Audio credits JSON parses and every current bass-led credit hash matches its file; CRLF-aware owned `git diff --check` **PASS**.

Device listening for mix/reverb feel and export acceptance remain OPEN. Focused checks do not certify final audio mix or release readiness.
