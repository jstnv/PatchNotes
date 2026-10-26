# Continuous music and room effect during pause — 2026-10-18

User request: keep the music time map and current track playing during pause, with muffled reverb like a bathroom at a house party. This supersedes the old Esc soundtrack-freeze behavior. Read CURRENT_STATE/TODO, repository update conventions, release-engineering, relevant pause/audio logs, branch/HEAD/status/diffs and current source first.

Branch `main`; HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`. Shared dirty edits and `.codex-godot-temp` preserved. No commit/push, release gate or export. [Implementation, retained failures, reproduction and acceptance boundaries](../findings/pause-music-20261018-v1/README.md).

## Files and behavior

- `patch-notes/scripts/audio/soundtrack.gd`: continuous SceneTree-pause transport/grid and theme blending; Music-only low-pass/reverb with 0.3-second fade, bypass on resume, shared whole-subdivision resume signal. Existing explicit backend suspension remains separate. Settings volume/mute and SFX are unchanged.
- `patch-notes/scripts/ui/hand_presentation.gd`: shift pending presentation beats/cursor and floating bonus lifetimes together; hold during rejoin; preserve ordered exactly-once card events and diagnostic trace fields.
- `patch-notes/scripts/ui/synergy_notification.gd`: use the same shift and hold partially shown popup poses until their music phase returns.
- `patch-notes/scripts/ui/how_to_play_content.gd`: explain ongoing muffled music and on-grid resume.
- `patch-notes/scripts/market/rival_world_checkpoint.gd`: exact pre-edit presentation-source compatibility entry only. Genuine old player/world/Founder state restores unchanged except the source marker; unknown revisions still reject.
- `patch-notes/scripts/debug/verify_pause_music.gd` (+UID): new maintained check, automatically discovered by the release gate. Existing `verify_pause_menu.gd`, `verify_soundtrack_sync.gd`, `verify_studio_soundtrack.gd` and `verify_how_to_play.gd` now assert the new audio behavior while retaining frozen gameplay assertions.
- Local findings/runner, design/DECISIONS, CURRENT_STATE and minimal direct-request TODO status updated. No audio assets, card-resolution, score, finance, calendar, AI policy or Studio-only save rule changed.

## Verification

Godot 4.7.1, separate frozen projects/profiles and Dummy audio. [Commands, exits and errors](../findings/pause-music-20261018-v1/long-verified-v1/results.json); [input audit](../findings/pause-music-20261018-v1/audit.json). Before/after runtime identities `38f92c219924494964e5982c6ed7976a5d2fec97de6ea1a7565fdd4d7e6bb41e` → `81d4c3577b722bd2bbf552618ae3011cd9f8672f5ee83b3f4c0851c4aa750aed`. All 721 tested inputs match the final canonical source.

| Check | Result |
|---|---|
| Fresh isolated import | PASS |
| New pause music / DSP / two actual paused loops | 714/714 |
| Real Pause menu, hand, state/RNG, Settings and Continue | 64/64 |
| Existing soundtrack synchronization | 3,503/3,503 |
| Existing Studio theme transitions | 7,620/7,620 |
| Settings | 29/29 |
| How to Play | 288/288 |
| Actual prior-source world restore | 5/5; all saved fields preserved except source marker; unknown sources rejected |


The new verifier covers Music-only DSP with a real captured impulse, continuous clock and theme transitions across WAV wrap, two actual paused loops, rapid pause/resume at 5 FPS, settings isolation, popup/bonus pose preservation, and 1/4/7-card synthetic presentation lengths at 60/5 FPS. Multi-loop and repeated pauses during centering, rise, fall and synergy leave events ordered once; actual four-card Gameplay pause also preserves full state/RNG. Larger/smaller visual fixtures do not authorize new legal hand sizes.

Earlier failed test-development stages remain in the findings: pre-seek playback identity comparison, synthetic SFX shutdown drain, old guide-freeze expectation and wall-time-based long-loop bounds. The final long check observes actual audio playback under a wall timeout instead of treating Dummy playback as a hardware clock. Audio shutdown ObjectDB and preexisting missing-artwork warnings are recorded; final runs have no script/runtime errors.

## Remaining acceptance

Audible speaker/headphone tuning of cutoff/room character and transition feel remains OPEN, along with real-device latency and refreshed exported acceptance. No human playtest, graphical check, performance or whole-release claim. The user-requested behavior and focused automated implementation are complete locally.
