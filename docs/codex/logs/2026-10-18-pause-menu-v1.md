# Esc pause menu — 2026-10-18

Direct user request: add an Esc menu with Resume, Settings and Main Menu. Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; shared dirty worktree and `.codex-godot-temp` preserved. Read current state/TODO, release-engineering contract and relevant source/diffs before edits. No unrelated queue implementation, commit or push.

## Behavior and files

- `patch-notes/scripts/ui/pause_menu.gd` (+UID): pause overlay with mouse and keyboard controls, Resume focus, Tab/Shift+Tab/up/down containment, Escape resume, cancellation-first discard confirmation and focus restoration. Its input callback can pause during a busy HandPresentation before that Control consumes keyboard input. The menu owns SceneTree pause and releases it on close/teardown; it cannot open over the title or checkpoint recovery.
- `patch-notes/scripts/gameplay.gd`: binds the menu and existing Settings; Main Menu flushes committed Studio state, warns before abandoning mid-phase progress and reloads the real gameplay scene. The old coordinator releases its writer; title Continue reads the existing slot. No mid-phase checkpoint is created. Save failures retain the game and open existing recovery; OS-close resumes before presenting its existing confirmation so it cannot become unresponsive.
- `patch-notes/scripts/ui/demo_settings_menu.gd`: processes while paused, keeping keyboard/mouse controls and display confirmation/revert alive. Back/Escape returns to the underlying pause menu without resuming gameplay.
- `patch-notes/scripts/market/rival_world_checkpoint.gd`: adds only exact pre-pause source `200a5b089b34f95c31231bade1e3f6720b77b8ec87c9691e19b496b91098bfd6` to the existing presentation compatibility list. Existing identity includes UI scripts, so this prevents invalidating unchanged rival/Founder saves. All schema/catalog/journal validation still runs; unknown sources reject.
- `scripts/debug/verify_pause_menu.gd`, `scripts/debug/capture_pause_menu.gd` (+UIDs): focused behavior verifier and separate graphical capture script. Updated release-engineering design, CURRENT_STATE and one direct-request completion entry in TODO; existing queue entries preserved. Findings runner/audit and records are below.

The existing Soundtrack observes SceneTree pause: gameplay timers, card presentation, soundtrack transport and its continuous grid stop together. Resume continues their existing state. No audio assets, scoring, calendar, finance, AI policy or card-resolution rules changed.

## Verification

Godot **4.7.1**, isolated frozen project copies, isolated APPDATA/LOCALAPPDATA/TEMP and test writer ports. The player's saves were not used. External process timeout240s; pause verifier timeout90s. [Final commands, exits and summaries](../findings/pause-menu-20261018-v1/final-v1/results.json), [source manifest](../findings/pause-menu-20261018-v1/final-v1/source.json), [source comparison](../findings/pause-menu-20261018-v1/audit.json).

| Check | Result |
|---|---|
| Fresh import | PASS, no errors |
| Pre-edit `verify_legacy_world` | 30/30, real old-source world/Founder-v2 checkpoint produced |
| `verify_pause_menu` | **64/64** |
| Existing `verify_demo_settings` | **29/29** |
| Existing `verify_studio_soundtrack` | **7,620/7,620** |
| Existing `verify_soundtrack_sync` | **3,503/3,503** |
| Existing `verify_legacy_gameplay` | **10/10** |
| `capture_pause_menu` | **39/39**, six captures inspected at1280×720 and1152×648 |

Pause verifier covers title exclusion, keyboard navigation and focus, timer/music freeze and continuation, settings persistence, display preview/reversion while paused (deadline forced past due), real Studio→title→Continue, real four-card Design hand paused mid-presentation, unchanged paused state/RNG, exactly four ordered rise/score/grounded events after resume, discard cancel/accept, unchanged disk checkpoint and rollback, injected save failure/retry, usable OS-close confirmation, pause teardown and exact prior-source player/world/Founder restore. [Card event trace and check count](../findings/pause-menu-20261018-v1/final-v1/verify_pause_menu.json).

Finishing the first hand marks the already-existing next tutorial tip seen; the resumed-state assertion permits exactly that acknowledgment and requires all other run/project fields to match. Earlier retained `check-v1` caught a typed conditional Array assignment in keyboard navigation; repaired. `check-v2` isolated that legitimate tutorial acknowledgment, then the final fixture compared the explicitly expected full state. No gameplay was changed to satisfy it.

Rendered captures: [Pause1280](../findings/pause-menu-20261018-v1/final-v1/pause-1280x720.png), [Pause1152](../findings/pause-menu-20261018-v1/final-v1/pause-1152x648.png), [Settings1280](../findings/pause-menu-20261018-v1/final-v1/settings-1280x720.png), [Settings1152](../findings/pause-menu-20261018-v1/final-v1/settings-1152x648.png), [Discard1280](../findings/pause-menu-20261018-v1/final-v1/confirm-1280x720.png), [Discard1152](../findings/pause-menu-20261018-v1/final-v1/confirm-1152x648.png). All controls/text fit; focus and dimming are visible. Graphical capture uses the actual Godot scene, scripted input and a private profile, not a human playtest.

## Reproduction and limits

Run `docs/codex/findings/pause-menu-20261018-v1/run.py <new-output-name> verify_pause_menu verify_demo_settings verify_studio_soundtrack verify_soundtrack_sync verify_legacy_gameplay capture_pause_menu` with the bundled Python. Its stored pre-edit producer supplies the optional old-source checkpoint check. `audit.py` compares all tested inputs to canonical files and permits only the three copied, engine-generated UID sidecars after import. Whitespace check uses `git -c core.whitespace=cr-at-eol diff --check` to respect the existing CRLF files; new files are separately checked for trailing spaces.

All final processes exit0 without script/runtime errors. Existing missing-card-artwork warnings remain. Tests use Dummy audio: real device listening for pause/resume and audible continuity remains NOT RUN. No refreshed exported package, whole release gate or release-readiness claim; this is verified local source/UI behavior.
