# Continue loading overlay — 2026-10-23

Status: **COMPLETE locally at the approved presentation scope.** [Session/results](../../logs/2026-10-23-continue-loading-v1.md) · [approved design and execution ledger](../../logs/2026-10-23-continue-loading-plan-v1.md).

Scope: real Main Menu Continue and recovery Retry show a modal overlay with the saved Studio name/calendar date and actual validation/restoration stages. A shared incremental operation retains the synchronous coordinator API used by tools. The Soundtrack autoload, its stream/player, continuous time map, theme sequencing and volume remain untouched. No scoring, calendar, cash, card, Bank, migration/content or checkpoint-boundary rule changes.

## Retained investigation

- `pn-continue-loading-20261023-red`: new behavior check fails because no overlay exists (3 checks,1 expected failure).
- `pn-continue-loading-20261023-green1`: overlay/stage/state/music checks pass; two competing-writer fixture failures were caused by the fixture still owning its first lease. Fixed only the test setup.
- `pn-continue-loading-20261023-green2`: added calendar-boundary test had an untyped dynamically loaded overlay variable; explicit `CanvasLayer` type fixes the parser error. The import command alone returned0, while the verifier correctly rejected the script.
- `pn-continue-loading-newrun-red`: first external regression invocation retained the same test parser error.
- `pn-continue-loading-newrun-red2`: after correcting the parser,114 checks expose exactly the reviewer's New Run-after-Cancel regression. Disk-input rejection had incorrectly set the coordinator's mutation-blocking save failure; the corrected operation preserves the original inspection-failure semantics. Cancellation after player hydration/before attachment has no coroutine error.
- `pn-continue-loading-20261023-green3`: loading and checkpoint runtime pass. The existing recovery UI test still assumed a one-frame Retry; its next iteration saw the new cover instead of an `AcceptDialog` and the test timed out. The test now waits for the loader's completion.
- `pn-continue-loading-20261023-green4`: loading and checkpoint runtime pass; the first helper insertion split the test's key-release block and caused a parser error. Fixed immediately in canonical test code; the frozen failed run is unchanged. `pn-continue-loading-parse-fixed` confirms the correction; the helper now preflights every selected script before executing any tests.
- `pn-continue-loading-20261023-green5`: all9 focused headless suites pass on the separately pinned pre-cover source.
- `pn-continue-loading-20261023-native`: WASAPI loading130/0, but Settings reset the requested first window size, so both captures are1280×720. This does **not** verify1152×648. Test now applies its size after HUD/Settings initialization and records actual window and PNG dimensions.
- `pn-continue-loading-20261023-native2`: WASAPI134/0 and true supported-size PNGs; captures caught old-menu bleed during a partly faded frame held by validation. The final cover waits for its actual entrance tween before validation, and final captures wait for opaque cover. Early resize render-target dimensions can be transient; acceptance verifies actual window plus post-draw PNG dimensions.
- Broad all-untracked provenance inventory timed out in early runs; later helper uses tracked status plus a complete hash inventory including new runtime files. No dirty files were removed to speed it up.

All runs above are in separate folders under `C:/Users/64jus/AppData/Local/Temp/`. Original failed results are preserved. Tests use fresh isolated profiles and real dedicated test TCP writer leases, never player saves. Engine executable: Godot4.7.1 stable console from the user Downloads folder. `run_checks.py` records commands, manifests and results; per-verifier wrappers retain the maintained release gate's test-only writer isolation on47733. The standalone New Run probe uses47734.

## Final acceptance

`pn-continue-loading-20261023-final`: **all9 focused suites PASS on one unchanged final source snapshot**, natively with WASAPI. Clean import and all9 script parser checks pass. [Command/results](focused-result.json) · [149/0 loading checks, stage cursors/sample energy and actual window sizes](native-result.json) · [source inventory](final-source.json) · [audit](final-audit.json).

| Check | Result |
| --- | --- |
| Continue loading / exact fields and RNG / unchanged generation bytes |149/0; no duplicated settlement or progression |
| Corrupt/stale preview, actual writer collision/Retry, New Run after Cancel, teardown before attachment |PASS |
| Checkpoint runtime, recovery UI, MainMenu/history, typed Studio checkpoint |PASS,0 failures each |
| Pause menu / rival activation / Founder-Legacy gameplay |60/0,10/0,10/0 |
| Existing Studio soundtrack/time-map checks |7,620/0 |
| Real device-driver output during loading |Same playback instance, advancing cursor,7 nonzero WASAPI sample buffers |
| Long Unicode name and saved year/month/half |PASS; wrapped text fully visible at both supported sizes |
| Source preservation / scoped whitespace |Exactly9 source paths changed; all other runtime inputs preserved;0 whitespace errors |

Final full source inventory digest: `8f3feba60d306818335724c77e43de3f0a72fe1bae2634404b1bf35fdb48ca34`. Nine earlier headless suites passed before the final visual correction; that source is [retained separately](preceding-headless-result.json), not relabeled as final. The [review](REVIEW.md) has no remaining actionable findings.

Actual rendered captures: [loading1152×648](loading-1152x648.png), [loading1280×720](loading-1280x720.png), [restored Studio1280×720](studio-1280x720.png). Captures and their IHDR dimensions/hashes are audited; no desktop or player-save capture was needed.

Reproduce with `run_checks.py --native --output <new-folder> --godot <console-exe> --tests verify_continue_loading verify_checkpoint_runtime verify_checkpoint_recovery_ui verify_main_menu_history verify_pause_menu verify_rival_gameplay_activation verify_legacy_gameplay verify_studio_soundtrack verify_studio_checkpoint`. Omit `--native` for isolated headless checks. `run_native.py --fresh` runs only render/audio acceptance on a new source copy; `--from-run <folder>` reuses an unchanged imported snapshot.

**Remaining limits:** each validation/hydration stage is still synchronous on the main thread (representative final native costs about187/15/139ms, attachment0.2ms; slower headless samples are retained). Larger saves can hold an individual frame. No background-streaming, final mix/human listening, clean-machine, refreshed EXE/export, full174-suite gate or release-readiness claim. Local/uncommitted; existing design gates remain separate.
