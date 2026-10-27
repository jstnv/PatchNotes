# Pause menu appearance/disappearance — 2026-10-26

User request: animate pause appearance/disappearance, assume no user input. Read current state/TODO first, relevant UI/Studio design, pause source and recent audio work; inspected branch, HEAD, status and diff. Shared dirty `main`, HEAD `087df09d653858b72c6e2dc344352237433dd3ac`. Existing edits, export settings, player saves and `.codex-godot-temp` preserved. No commit, push or export.

## Implementation and files

- `patch-notes/scripts/ui/pause_menu.gd`: fade the existing overlay/dimmer and slide its full-rect content20px. Entrance reuses `MenuTransitions.ENTRANCE_SECONDS`0.24s, with cubic easing out; exit0.18s uses quadratic easing in. No new navigation stack. Pause/resume and focus transfer remain immediate; visual exit is noninteractive through recursive mouse/focus disabling. Button callbacks require owned pause. Preserve normal button appearance during the fade. Cancel superseded tweens to reverse from current pose; run through pause and zero time scale. Scene teardown kills the tween and releases owned pause.
- `patch-notes/scripts/debug/verify_pause_motion.gd`: actual Gameplay fixture, both1152×648 and1280×720. Tests intermediate and settled pose, duplicate open, immediate ownership/focus, closing input/action guards, rapid reopen, full exit, unchanged state/RNG/audio instance, real-time zero-scale animation and teardown. Native run captures entrance/open/exit at both sizes.
- `patch-notes/scripts/debug/verify_pause_menu.gd`: existing onboarding-dismiss helper now waits up to3 wall-clock seconds for the asynchronous new-save invitation. It still fails if the invitation never arrives. Existing audio wait and all navigation assertions retained.
- `patch-notes/scripts/market/rival_world_checkpoint.gd`: admit the exact preceding editor source `abbfa387743973cc6c727912041bee407ebeebe4fa370fd26751a1d9d87eace7` alongside the prior pause-audio identity. Presentation is part of the executable fingerprint. No schema/rule change; unknown-source rejection and full validation remain.
- `docs/codex/design/core-and-studio.md`, `docs/codex/TODO.md`, this log and findings record the implementation. Concurrent employee design edits preserved.

## Verification

[Exact commands, outputs, source pins and captures](../findings/pause-menu-motion-20261026-v1/). Runner uses Godot4.7.1, separate test profiles and private writer ports; native means OpenGL/NVIDIA with WASAPI. Canonical player saves are never used.

```text
python docs/codex/findings/pause-menu-motion-20261026-v1/run.py <fresh-label> res://scripts/debug/verify_pause_motion.gd
python docs/codex/findings/pause-menu-motion-20261026-v1/run.py <fresh-label> res://scripts/debug/verify_pause_menu.gd
```

For native motion add `--native --device --out=<absolute new capture directory>`. The retained prior task's absolute `restore.gd` supports `--capture` before the edit, then a separate process without that flag for exact restore against this task's original pair.

| Final-source check | Result |
| --- | --- |
| Original pause lacks animation, `motion-red` | Expected FAIL1/2 |
| Actual headless motion, `motion-final` | PASS33/33 |
| Actual native motion, `motion-native-final` | PASS39/39 |
| Existing pause/menu/Settings/Main Menu/recovery/Continue, `pause-menu-final` | PASS65/65 |
| Genuine pre-edit Studio fixture capture, `baseline` | PASS2/2 |
| Exact fresh-process predecessor restore, `cold-restore` | PASS10/10 |
| Scoped CRLF-aware diff check | PASS |

Six final native captures are in `captures-final/`; representative settled1152 and exiting1280 images were opened and inspected. Endpoints fit both viewports. Pre-edit restore preserves player/finance/RNG and rival world except the executable source marker, leaves generation bytes unchanged, publishes no replacement generation and rejects unknown sources. This single fresh Studio fixture does not establish every historical save's compatibility.

## Retained attempts and limits

- Before UI edits, an unisolated local API startup probe crashed in Godot native startup and was interrupted. The isolated Dummy probe verified recursive Control mouse/focus behavior, and all final isolated native/headless runs completed. That startup crash's cause was not investigated; no product diagnosis inferred.
- Initial `pause-menu` failed only the first invitation assertion: its one-frame setup outran asynchronous new-save loading. The bounded helper correction passes in `pause-menu-v2` and the final fresh-profile run. Earlier native/headless motion outputs are retained; final outputs also avoid the initially disabled button palette changing abruptly during exit.
- The copied runner initially reused the prior audio task's profile prefix for matching labels. Fixed it to `pause-menu-motion-<label>` and reran final motion/native/navigation/cold checks with separate fresh profiles. Previous test profiles remain preserved.
- Existing missing temporary art/six ObjectDB shutdown warnings appear in some UI/headless attempts; final native and final navigation logs contain no logged errors. Music source, gameplay resolution and save schema were not changed by this task. Audio gain/transport has the same unchanged source as the previous task; this task checks its playback identity rather than repeating full-song audio acceptance.
- Teardown cancels pending visual callbacks, including when Main Menu replaces the scene; it does not delay scene replacement for an old overlay. Subjective motion preference and full release acceptance remain separate. Existing EXE/ZIP have not been rebuilt.
