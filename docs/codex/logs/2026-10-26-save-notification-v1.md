# Animated save notification; remove footer Quit — 2026-10-26

## Request and starting state

User requested removing the bottom-right Quit button and replacing permanent “Studio saved” with a notification whose appearance/disappearance is smooth. Branch `main`, HEAD `087df09d653858b72c6e2dc344352237433dd3ac`; index empty. Preserve the prior Search-first, hover, employee-unlock and Bank UI work, concurrent design records, local export preset and `.codex-godot-temp`.

## Changes

- `patch-notes/scripts/ui/save_notification.gd`: small shared-theme passive notification above the footer. Fade/slide in0.20s/12px, hold successful status2.40s, fade/slide out0.25s. Interruptible tweens start from current opacity/position. Saving and failure do not expire while unresolved. Always-process animation, no input/focus capture.
- `patch-notes/scripts/gameplay.gd`: remove the persistent Quit node and its tutorial show/hide bookkeeping; use the notification instead of the permanent status row. Existing save label reference remains available to maintained status verifiers, even when its success presentation has disappeared. OS-close, Main Menu Quit, error-dialog Quit and recovery/confirmation guards stay intact.
- `patch-notes/scripts/persistence/checkpoint_coordinator.gd`: process-local `completed_saves` token advances only after an actual successful durable publication. It adds no saved field, payload scan, file read, gameplay action or RNG. Coalesced writes keep the UI in Saving until latest state is durable; unchanged/failure/load do not create another success token.
- `patch-notes/scripts/debug/verify_save_notification.gd`: real Studio publication plus deterministic entrance/hold/exit samples, focus/click/bounds checks, repeated status, unresolved saving/failure, replacement success and real-clock paused completion at both supported sizes.
- `patch-notes/scripts/debug/verify_background_checkpoint.gd`: four additional assertions bind the notification token to actual published generations, unchanged/failure and cold load.
- `docs/codex/design/core-and-studio.md`, `design/release-engineering.md`, `TODO.md`: adopted presentation behavior and completed scope.

## Checks and exact commands

Godot executable `C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe`, version `4.7.1.stable.official.a13da4feb`. Commands from repository root; each process gets isolated `APPDATA`/`LOCALAPPDATA` under `.codex-godot-temp/save-notification*-20261026/`.

```
<godot> --headless --path patch-notes --script res://scripts/debug/verify_save_notification.gd
<godot> --path patch-notes --position 60,60 --resolution 1152x648 --script res://scripts/debug/verify_save_notification.gd -- --out=<absolute findings folder>
<godot> --headless --path patch-notes --script res://scripts/debug/verify_background_checkpoint.gd
<godot> --headless --path patch-notes --script res://scripts/debug/verify_pause_menu.gd
```

Focused notification fixtures use their private slot and TCP lease47755. Lifecycle uses its existing isolated lease47413, `PN_BG_FIXTURE=<repo>/docs/codex/findings/campaign-latency-20261025-v1/long-v003.result.json` and `PN_CARD_FRAME_OUTPUT=<private lifecycle folder>/result.json`. Pause uses `PN_CHECKPOINT_TEST_PORT=47756`. Real player saves/settings are untouched.

- RED: initial test harness needed explicit types for `quit_buttons`/`saved`; corrected before accepting the semantic red. Old runtime then exits1 with **8 checks/4 expected failures**, proving persistent Quit and missing notification at both sizes.
- PASS: focused headless **36/36**, exit0. Actual durable save, gradual intermediate opacity/position, settled placement, focus/click safety, repeated callbacks, automatic disappearance, Saving/failure persistence and paused animation completion.
- PASS: focused native **36/36**, exit0, OpenGL/NVIDIA at1152×648 and1280×720. Four actual Studio captures inspected: `saved-1152.png`, `dismissed-1152.png`, `saved-1280.png`, `dismissed-1280.png`.
- PASS: background lifecycle **29/29**, exit0. Coalesced two-generation publication, unchanged suppression, failed write/retry, durable-token correspondence, joined teardown, cold restoration and no publication from load. Existing timing gates pass on this bounded fixture; no new general performance claim.
- PASS: maintained Pause/Menu **65/65**, exit0. Resume/settings/guide, real scene return/Continue, save failure/retry and existing OS-close confirmation remain usable.
- Existing headless notification/lifecycle runs retain six ObjectDB cleanup warnings. Pause retains temporary-artwork warnings; successful native notification has no cleanup warning. No failing assertions/script errors in final runs; no broad clean-teardown claim.

[Raw logs, lifecycle receipt, source hashes and captures](../findings/save-notification-20261026-v1/result.json).

## Limits

No new EXE/ZIP, commit/push, Drive update or whole-release acceptance. Current download packages retain the former footer UI until rebuilt. Studio-only Continue, durability, save schemas, gameplay, audio transport and pause rules are unchanged.
