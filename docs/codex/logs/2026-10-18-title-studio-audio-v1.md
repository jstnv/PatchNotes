# Faster title-to-Studio music — 2026-10-18

User requested faster dynamic resequencing from title to Studio. `main` at `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; existing dirty changes and `.codex-godot-temp` preserved. Inspected current state/TODO, repository workflow, audio design and prior Studio integration, source and diff before edits. No unrelated queue work, commit or push.

## Change

The prior cue waited for the next four-beat bar and faded over a quarter note: up to30/7 seconds (4.286s) at70BPM. Title/Main Menu -> Studio now waits for the next eighth-note card pulse and fades over one eighth note: at most6/7 seconds (0.857s) on the music clock. Initial/new and restored-Studio presentation both use this route. Other transitions retain the prior bar/quarter-note envelope. Rebinding does not postpone a cue; cancel/reverse/pause behavior uses absolute corrected mix position.

The two arrangements keep one playback and the same phase/key map. No WAV, playback rate, card rules,140/minute activation rate or economic effect changes. Fade updates remain frame-quantized and output latency still applies; the bound describes the music timeline, not a promise during a stalled application.

Runtime edits: `scripts/audio/theme_blend.gd` adds the optional entry interval/duration and retains the active envelope duration separately; `scripts/audio/soundtrack.gd` forwards the cue; `scripts/ui/gameplay_hud.gd` selects it only when leaving Main Menu for Studio music. `scripts/market/rival_world_checkpoint.gd` recognizes the exact prior source `f8f130c6a3e6b7d27710e11a56b445ea6c73d9dbc26ca26a8501ca2cf7ca32de`, because the existing source fingerprint includes presentation scripts. Schema/state validation remains intact; this avoids invalidating saved worlds for an audio-only change.

Extended `scripts/debug/verify_studio_soundtrack.gd` with all64 subdivision positions at three offsets, quick-cue cancellation/reversal, sparse-frame catch-up, real Main Menu/Studio controller fixtures and optional actual pre-edit checkpoint restore. Updated `assets/audio/crunch_time_70/STUDIO_THEME.md`, the core/Studio design record and current-state note. TODO unchanged.

## Verification

All runs use frozen project copies and isolated profiles, Godot4.7.1, headless/Dummy audio,240-second external bound. [Exact commands/results and source](../findings/title-studio-audio-20261018-v1/after-v1/results.json).

- Pre-edit `verify_legacy_world`:30/30, creating a genuine prior-source world/Founder-v2 checkpoint with an active former Studio. [Producer](../findings/title-studio-audio-20261018-v1/before/results.json).
- Revised `verify_studio_soundtrack`: **7,626 checks,0 failures**. Includes existing repeated loop/low-FPS/pause tests, fast title cues, native playback identity, unchanged calendar/cash and exact old-source player/rival/Founder restore with only the source marker updated. An unrecognized source remains rejected.
- Existing `verify_soundtrack_sync`: **3,503 checks,0 failures**, preserving the continuous140/minute card/synergy clock.
- `verify_demo_settings`:0 failures. Fresh import succeeds; all three processes exit0, no recorded script/runtime errors. Existing missing-artwork warnings remain in the scene fixture.
- [Source audit](../findings/title-studio-audio-20261018-v1/audit.json) pins before/after files, verifies unchanged WAVs and records the focused whitespace check.

Reproduce with the evidence folder's `run.py <fresh-output-name> verify_studio_soundtrack verify_soundtrack_sync verify_demo_settings`; its retained pre-edit checkpoint supplies the optional compatibility check. The title/Continue routing probes are in-memory presentation fixtures; the separate codec test is a real prior-source checkpoint, not a player-save interaction. No full release gate/export or human audible listening is claimed. Remaining: user/device listening for the preferred blend feel.
