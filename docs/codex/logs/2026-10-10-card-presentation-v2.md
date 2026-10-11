# Card presentation and SFX — 2026-10-10

User requested card-play/removal sounds, removal of the extra post-synergy bounce, a short music-grid delay after the popup, and an exposed upper selection fan. Inspected CURRENT_STATE/TODO, current source, branch/HEAD/status/diff and existing soundtrack/motion verifiers. Shared dirty `main` at41c87c76 preserved; no commit/push.

Implemented original procedural WAV cues on SFX; one-subdivision popup lead; direct post-bonus exit; music-clock popup/bonus-label animation; larger upper-left selected fan and separate lower-right pool. No scoring/action/RNG changes. Updated settings copy and audio credits/provenance.

Runtime files: `scripts/ui/hand_presentation.gd`, `card_fan.gd`, `synergy_notification.gd`, `phase_workspace.gd`, `demo_settings_menu.gd`; new `assets/audio/card_sfx/` WAV/import/provenance files; `data/audio_credits.json`. Tests: updated `verify_card_motion.gd`, `verify_soundtrack_sync.gd`; new `verify_upper_card_fan.gd`/UID. Evidence and generator in [card-presentation-v2](../findings/card-presentation-v2/README.md).

Import passes;3479 synchronization checks;1740 upper-fan geometry/selection checks; native motion, settings, HUD overlay and Cult compatibility pass. Captured and inspected both supported resolutions; final width clamp prevents minimum-screen overflow. Exact commands/source hashes are saved. Earlier small-row layouts were rejected during visual review and retained as evidence. Focused whitespace check passes.

Remaining: audible SFX mix/device latency playtest and export acceptance. Existing deliberate invalid-action/certificate/audio shutdown warnings are disclosed in evidence; no new runtime errors in passing checks. No computer control, user-save alteration, TODO work, commit or push in this scoped presentation pass.
