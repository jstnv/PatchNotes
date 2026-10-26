# Preserved Studio Smooth source

These five Python files are byte-for-byte snapshots from the user's original `Patch Notes Music/soundtrack/prototype-01-crunch-time` synthesis project on 2026-10-11. Their original hashes are recorded in `docs/codex/findings/studio-theme-20261011-v1/source-assets.json`. They retain the original C-minor defaults as provenance.

Use **`python tools/audio/build_studio_theme.py`**, which imports them and renders the approved D-minor adaptation without writing to the original music workspace. Do not run the snapshot generators directly to update game assets. Dependencies: Python and NumPy; FFmpeg is not used by this integration renderer.

See `patch-notes/assets/audio/crunch_time_70/STUDIO_THEME.md` and `LICENSE_NOTES.md` for the musical map and resource/authorship provenance.
