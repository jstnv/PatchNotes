# Gradual pause reverb — 2026-10-26

Direct request: make the audio transition into the pause filter gradual. Read current state/TODO, repository conventions, relevant pause design/log and runtime/verifier source. Inspected shared dirty `main`, HEAD `087df09d653858b72c6e2dc344352237433dd3ac`, status and diff. Preserved concurrent edits, export settings, player saves and `.codex-godot-temp`. No commit, push or export.

## Implementation

- `patch-notes/scripts/audio/soundtrack.gd`: extend the real-time pause envelope from0.3 to0.9 seconds and apply smoothstep to wet reverb. The duration/easing are implementation choices for the requested gradual feel. Resume follows the same curve backwards; rapid toggles continue from current progress. Reverb bypass occurs only at zero. Existing full dry1.0, wet0.38 endpoint, Music/player gain, mute, room parameters, audio playback and music grid are unchanged.
- `patch-notes/scripts/market/rival_world_checkpoint.gd`: source identity includes audio presentation. Admit only the exact immediately preceding editor identity `3a8f41da6754dcf17269623586337daf39e1523263cbdb1aefcf0e8a9dba3ccc` with normal current payload checks. Unknown sources still reject. No schema or gameplay migration.
- `verify_pause_music.gd`: check gentle intermediate entry/exit, mid-fade reversal and zero gameplay time scale, alongside existing real DSP, continuous playback, loop crossing,5 FPS, settings, musical event ordering and exactly-once action checks.
- `verify_pause_menu.gd`, `verify_pause_audibility.gd`, `verify_pause_track_continuity.gd`: wait for the defined fade duration before asserting its endpoint. The latter two also dismiss the existing save tutorial invitation before Esc, using the maintained pause-menu setup helper.
- Relevant design and TODO record the change. The72-second dedicated track-continuity suite was updated but NOT RUN; focused native transport/DSP and menu checks cover this task. No whole-release acceptance claim.

## Reproduction and verification

[Findings](../findings/pause-transition-20261026-v1/) contain exact commands and outputs, source hashes in `audit.json`, task-only source diff, original pre-edit checkpoint and isolated restore harness. Run with the bundled Python:

```text
python docs/codex/findings/pause-transition-20261026-v1/run.py <fresh-label> res://scripts/debug/<verifier>.gd
```

Add `--native --device` for native OpenGL/WASAPI. Runner uses isolated profiles under `.codex-godot-temp` and a private writer port. Absolute script path plus `--capture` captures the pre-edit fixture; the same script in a fresh process without that flag tests restore.

| Check / finding label | Result |
| --- | --- |
| New transition assertions against original audio, `transition-red` | Expected FAIL:3 of717 checks, specifically gentle entry, longer entry and longer exit |
| Final headless audio/DSP, `transition-green` | PASS721/721 |
| Final native OpenGL/WASAPI audio/DSP, `native-transition` | PASS721/721 |
| Full Main/Studio songs with native WASAPI, `native-song-v2` | PASS556/556 |
| Actual Esc/menu/Settings, hand presentation, recovery and Continue, `pause-menu` | PASS65/65 |
| Genuine pre-edit checkpoint capture, `baseline-v3` | PASS2/2 |
| Fresh-process unchanged predecessor restore, `cold-restore` | PASS10/10 |
| Scoped CRLF-aware `git diff --check` | PASS |

Restore verifies exact player/finance/RNG and world state except the new executable-source marker, no generation rewrite on Continue, unchanged original bytes and rejection of an unknown source. This is one genuine fresh Studio fixture, not coverage of every historical/compiled save.

## Retained failures and limits

- `baseline` initially used a relative external script path, which Godot resolved inside `res://`; `baseline-v2` caught an untyped test variable. Corrected only the harness and captured the genuine fixture before the production edit in `baseline-v3`.
- The initial `native-song` full-song check returned555 checks/112 failures because its setup left the first-time tutorial invitation open. Esc did not enter pause; recorded preconditions showed `can_pause:false` and `guided:true`. Updated only the verifier setup to dismiss the invitation using the existing helper before its audio checks. The new native run passes556/556, including chosen gain, dry signal, actual PCM, frozen gameplay, transport identity and both full themes. Retain the failed log, not a product failure diagnosis.
- Existing missing temporary art and six ObjectDB shutdown warnings remain in relevant UI/headless logs. The final focused native transition/DSP log has no errors or warnings.
- Human listening preference is OPEN. Existing EXE/ZIP do not include this change; no export, release readiness, commit or push is claimed.
