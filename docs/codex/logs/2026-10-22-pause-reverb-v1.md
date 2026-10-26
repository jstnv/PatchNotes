# Pause music: reverb only — 2026-10-22

User ruling: pause should keep the music level and use reverb wetness for bathroom acoustics. This supersedes the prior low-pass/muffled treatment and reduced dry level. Read current state, TODO, relevant audio/design records and source; inspected branch, HEAD, status and diff before edits.

## Source and scope

Shared dirty `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; existing edits and `.codex-godot-temp` preserved. New runtime identity `386d42892f3b34ece7cc88b1df5359ba584e97a4aa465fdce73e13d6ae4ec8bc`. No commit, push or refreshed export. [Exact commands, source hashes and results](../findings/pause-reverb-20261022-v1/audit.json) · [task-only patch](../findings/pause-reverb-20261022-v1/task-only.patch).

- `scripts/audio/soundtrack.gd`: removed the Music low-pass filter; dry stays at 1.0. Only wet reverb fades between 0 and the existing 0.38 over the existing 0.3 seconds. Room/damping/predelay/spread, user volume/mute, transport, theme blend and music grid are unchanged. Resume bypasses the reverb.
- `scripts/ui/how_to_play_content.gd`: describe continuing music at the chosen volume with room reverb.
- `scripts/market/rival_world_checkpoint.gd`: allow only the exact preceding editor `5783246fcb2ecd6612eccf8e06cde72490db3ebb2944b8592e0943bfdaf94536` and compiled `d259a6545d3802f5a2493f96547d9e10ad26984f4342270724232a3764fbec72` market1 sources after this presentation change. Full current schema and owner-provenance checks still run; unknown sources reject. Older pre-market migration and strict replay identities remain unchanged.
- `scripts/debug/verify_pause_music.gd` and `verify_pause_audibility.gd`: assert only reverb, unity dry/unchanged player and bus gain, retained impulse peak, measurable room tail, continuous transport and unmodified gameplay.

Exactly these three runtime files differ from the preceding verified export's 301 source inputs; the other 298 match byte-for-byte, including Bank/finance rules. Two debug verifiers also changed. Task findings, this log and concise design/state/TODO updates record the direct request.

## Verification

Godot 4.7.1, isolated profiles and test writer ports. Runs use `python docs/codex/findings/pause-reverb-20261022-v1/run.py <fresh-label> <script>`; actual audio uses `--device --native`. Restore inputs and complete argument arrays are recorded in each run JSON.

| Check | Result |
| --- | --- |
| Pause effects, real DSP impulse, loop crossing, settings and visual sequences | 714/714 |
| Actual pause/menu/Settings/Continue and card presentation | 60/60 |
| Soundtrack synchronization | 3,503/3,503 |
| Standalone OpenGL + WASAPI, full phrases of Main and Studio | 555/555 |
| Actual prior editor and compiled saves, seed plus fresh cold process for each | 76/76 across four processes |

The real impulse retains its dry peak and gains a measurable reverb tail. Actual-song post-effect RMS gains are main +3.28 dB, studio +3.35 dB relative to the pre-effect signal. Wet reflections add energy; this is not an equal-loudness claim. Saved Music13, player gain, full dry signal, playback identity and gameplay freeze are checked throughout both themes. Original save generation bytes, exact player/finance/RNG and world state are preserved except the executable-source marker in a new capture. No replacement save is published by Continue. Unknown source and internally valid but owner-inconsistent market corruption both reject.

## Retained failures and limits

- The first headless WASAPI run passed its gain checks but failed one of 555 timing assertions: one observed half-second sample advanced the corrected clock by 0.2126 seconds against a 0.25 threshold while other checks were running. Retained as FAIL; no transport-stop cause is inferred. The subsequent standalone native run passed all 555 without changing audio or timing code.
- The initial local restore harness used the production writer port and returned `writer_busy`. Only the test harness was corrected to use the existing isolated-port test convention, then four new outputs passed. The failed harness and report are retained; player saves and the running application were not touched.
- Existing missing-card-art and six ObjectDB shutdown warnings remain in relevant headless logs. The final native audio run has no logged errors. No broad release gate, new export or human listening acceptance is claimed.

Restart an already-running Godot play session to construct the new effect chain. Subjective bathroom acoustics remain a listening preference; the requested implementation and focused automated checks are complete locally.
