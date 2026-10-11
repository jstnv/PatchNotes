# Soundtrack synchronization prototype — 2026-10-09

User authorized bounded70BPM VersionA WAV plus140 card activations/minute, VersionB substitution, latency/loop/pause/scene handling, event traces and focused verification; also removal of the cyan focused-card border. Explicitly no TODO edits or card-rule changes.

Main/HEAD41c87c76fb4d3c06a5332d93f0e7b0997007475d; shared dirty work preserved. [Implementation, commands, evidence, failures and audible-playtest limits](../findings/soundtrack-sync-v1/README.md).

Changed: `patch-notes/project.godot`; new `scripts/audio/music_grid.gd` and `soundtrack.gd` with UID sidecars; two WAVs/imports and provenance under `assets/audio/crunch_time_70`; `scripts/ui/hand_presentation.gd`; `scripts/ui/demo_settings_menu.gd`; `scenes/cards/card_view.tscn`; `data/audio_credits.json`; new `scripts/debug/verify_soundtrack_sync.gd`/UID and adjusted event wait in `verify_card_motion.gd`. Documentation: this log, findings, CURRENT_STATE. No scoring/resolution/persistence schemas or TODO edited.

Pass:3385 synchronization checks, existing full hand-motion focused verifier, settings verifier and both-size focus captures.68 observed native hand events max6.702ms late in the headless run. Two real WASAPI loops plus pause/resume passed. Active-WAV abrupt headless shutdown has a retained-object warning; explicit audio drain probe is clean. Audible feel/seams/device changes remain unverified. No commit, push, export or release-readiness claim.
