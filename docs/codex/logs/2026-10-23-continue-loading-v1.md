# Continue loading overlay — session2026-10-23 (America/Los_Angeles)

## Authority and checkout

User approved showing the saved Studio name/date and implementing a loading overlay with uninterrupted music. [Design/plan and implementation rulings](2026-10-23-continue-loading-plan-v1.md). Read CURRENT_STATE/TODO/README, release-engineering, current source and scoped diffs first.

Shared dirty `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, unchanged. Work remains local/uncommitted. Preserve prior edits and `.codex-godot-temp`; no deletion, Git mutation or player-profile operation. Isolated project copies, settings/saves and dedicated real test TCP leases were used throughout.

## Changes

- `patch-notes/scripts/persistence/checkpoint_load.gd` (+UID): shared incremental restore with inspection, player hydration, rival-world hydration and final attachment. No partial run/world attachment or save writes. `checkpoint_coordinator.gd` drains that identical operation for existing synchronous tools.
- `patch-notes/scripts/ui/continue_loading.gd` (+UID): modal cover, wrapped saved name/date, activity dots, actual stage labels and short entrance/reveal. Finish the entrance before a synchronous validator can hold a half-faded frame. Graphics tweens ignore gameplay time scale.
- `patch-notes/scripts/gameplay.gd`: MainMenu/recovery presented route, loading/input guards, shared finalization, explicit Studio setup result and final keyboard focus. Existing synchronous debug route remains compatible. No Soundtrack transport call was added.
- `patch-notes/scripts/debug/verify_continue_loading.gd` (+UID): real disk/MainMenu/recovery/lease/teardown tests, exact player/RNG/save bytes, audio playback identity/cursors/sample energy, calendar boundaries and long Unicode name at actual supported window sizes. `verify_checkpoint_recovery_ui.gd` now waits for async Retry completion.
- TODO, CURRENT_STATE, release-engineering, plan, this session log and the [finding folder](../findings/continue-loading-20261023-v1/README.md): review, reproducible helpers, compact source/result/audit manifests and three representative PNGs. Large import caches/profiles/raw logs remain in named Temp folders.

## Exact checks and outcomes

Python: `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe -X utf8`.
Godot: `C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe` (4.7.1).

Final command:

```text
python -X utf8 docs/codex/findings/continue-loading-20261023-v1/run_checks.py --native --output C:/Users/64jus/AppData/Local/Temp/pn-continue-loading-20261023-final --godot <Godot-console-path-above> --tests verify_continue_loading verify_checkpoint_runtime verify_checkpoint_recovery_ui verify_main_menu_history verify_pause_menu verify_rival_gameplay_activation verify_legacy_gameplay verify_studio_soundtrack verify_studio_checkpoint
```

PASS: clean isolated import; all9 parser checks; all9 actual native verifier processes exit0 with no error markers; source snapshot unchanged. Loading149/0; Pause60/0; rival Gameplay10/0; Legacy Gameplay10/0; Studio soundtrack7,620/0. Checkpoint runtime/recovery, menu/history and typed checkpoint suites each report0 failures. Exact commands/results are retained in [focused-result.json](../findings/continue-loading-20261023-v1/focused-result.json).

PASS: actual1152×648 and1280×720 window and PNG dimensions, wrapped long Unicode name, saved half-month/year boundaries, single modal/input guard, unchanged player fields/RNG and disk generation, no extra settlements, corrupt-after-preview recovery, real writer collision/Retry, New Run after Cancel and scene teardown after player hydration but before attachment. [Native details](../findings/continue-loading-20261023-v1/native-result.json).

PASS: same actual audio playback instance throughout; increasing music cursor, all5 restore stages, seven nonzero WASAPI sample buffers (minimum summed energy12.3795), existing main→Studio sequencing and pause behavior. Capture effect is test-only and removed. These are device-driver/sample checks, not a human listening approval.

The same nine suites previously passed headless in `pn-continue-loading-20261023-green5`, before the final cover/viewport correction. This earlier source is retained separately, not relabeled as final. The final native run rechecks all9 on one final snapshot; no union is needed for its result. Missing-card-art warnings remain in pre-existing card/pause paths; no new runtime error markers were accepted.

Audit command: `python -X utf8 docs/codex/findings/continue-loading-20261023-v1/final_audit.py` — PASS: exact9 changed source paths versus the pre-change snapshot, current source equals final tested source, all other source inputs preserved, PNG dimensions/hashes and scoped whitespace clean. Final source inventory digest: `8f3feba60d306818335724c77e43de3f0a72fe1bae2634404b1bf35fdb48ca34`. [Audit](../findings/continue-loading-20261023-v1/final-audit.json).

## Investigation and review

Retained expected initial RED (no overlay), competing-writer fixture correction, test parser/Retry-timing repairs, independently found New Run regression and fix, first capture's Settings size reset, and intermediate half-fade captures are catalogued in the [finding](../findings/continue-loading-20261023-v1/README.md). No failed result/source manifest was rewritten. Final [review](../findings/continue-loading-20261023-v1/REVIEW.md) has no remaining actionable findings.

Ruling: keep per-stage validation/hydration on the main thread, drawing between stages, rather than introducing thread-unsafe Node/Resource restoration. Final native representative stage costs were approximately187ms checking,15ms player hydration,139ms world hydration and0.2ms attachment; an earlier Dummy/headless run was slower (about2s/0.15s/1.45s). These are bounded fixture observations, not a performance guarantee. Large saves can still hold an individual frame; this is not background streaming.

Ruling: wait for the real120ms cover entrance before validation; this fixes observed old-menu bleed without adding a fake minimum loading duration. Reveal is160ms once Studio has entered and laid out. Do not change music transport, time map, volume, rules or checkpoint content for a presentation transition.

## Remaining boundaries

No refreshed EXE/export, clean-machine test, human listening/mix acceptance or full174-suite release gate is claimed. Existing open design/human tasks retain their separate statuses. No gameplay, Bank, scoring, RNG evolution, audio asset, save schema or migration rule changed. TODO marks this bounded loading implementation complete; SideStreet P2 and other unapproved proposals remain separate.
