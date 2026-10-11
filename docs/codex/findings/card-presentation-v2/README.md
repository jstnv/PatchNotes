# Card sounds, synergy pacing and separate selected fan

2026-10-10. Implemented locally on shared dirty `main` at `41c87c76fb4d3c06a5332d93f0e7b0997007475d`. No gameplay scoring, cards triggered, prices, RNG or save schema changed. No commit/push/export.

## Presentation

- Original procedural90ms card tap at base/bonus score reveal;300ms filtered-noise whoosh on one group removal, including redraw. Both route through existing SFX volume/mute. Generator and provenance retained; no third-party samples. WAV format/finite endpoints/no clipping/hash checks in `audio-checks.json`.
- Popup appears after base scoring, followed by one music subdivision (`60/140` seconds ≈0.429s) before bonus bounces. Four bonuses still occupy four subdivisions. Removed the redundant victory wave after synergy; group slide follows bonuses. Non-synergy exit behavior retained.
- Balanced Production/Operations now use the same deferred popup/bonus presentation. Actual resolved deltas still come from the single authoritative action; QA retains its capped first-pass display behavior.
- Music playback remains the timing authority. Popup entrance/lifetime and floating bonus labels now follow it too. Paused transport freezes these effects. Audio cues suppress stale score sounds after a frame misses their boundary by120ms, avoiding a burst of obsolete clicks. Visual events still catch up exactly once.
- Selected cards form a larger, fully exposed upper fan to the left; remaining cards form a separate lower fan to the right. This keeps readable scale instead of shrinking two full rows into352px. Only the remaining pool overlaps itself. Selected right edges are clear; minimum-screen width is respected. Sorting/identity/hit routing and four-card limit remain unchanged.

## Checks and evidence

- Godot4.7.1 clean import passed.
- `sync-final`:3479 checks, zero failures, including variable sequence lengths1/3/4/7, normal/bonus,60FPS/5FPS/1.1-second frames, modeled1000 loops, actual near-wrap playback, pause/resume/scene continuity, exact one-subdivision popup lead, no synergy exit wave and one removal boundary. Synthetic1/3/7 lists are timing stress, not new legal hand rules.
- `motion-final`: native Design/Alpha/Beta/Contract play, redraw, rejection, cancel, retained-card refill and once-only state checks pass. This precedes only the final viewport-width clamp, trace label and settings/credit copy; final fan/sync/settings checks cover those adjustments.
- `fan-bounded`:1740 geometry/selection assertions pass. One through four selected cards, eight idle-wave positions, two fan widths, right-score hit targets, sorting and deselection. Selected cards do not intersect each other or the lower group.
- `capture-final`: real Godot Alpha fixture renders at1152×648 and1280×720, all card corners in viewport, no selected/lower overlap. Final screenshots inspected. Fixtures are layout evidence, not legal gameplay-route claims.
- Settings and HUD overlay suites pass; Cult compatibility verifier also passes after adding the cues. Exact commands, fresh-profile paths, source hashes and driver hashes in per-run `command.json`.
- `audio-checks.json`: both mono48kHz PCM16, no clipping, tapered near-zero endpoints. Card tap peak−10.14dBFS; whoosh−10.26dBFS before runtime/bus gain.

Reproduce with the Python/Godot paths in `command.json`: `run.py <fresh-label> verify_soundtrack_sync.gd`, `run.py <fresh-label> verify_upper_card_fan.gd`, or `run.py <fresh-label> capture.gd render`. Generator: `generate_sfx.py`. Profiles isolated; user game/editor and saves untouched. Initial two-row small-card attempts retained for comparison; `capture-final` is the selected result.

Audible mix preference and real-device sound-to-picture latency still need a listening playtest. Audio commands occur at frame-quantized presentation events; no sample-accurate output guarantee is claimed. Existing certificate-store warning, deliberately invalid-hand fixture warnings and headless WAV shutdown-object warnings are recorded. No new runtime errors in passing runs. No computer control or refreshed export performed.
