# Checkpoint recovery modal repair — 2026-10-09

Branch `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`, existing dirty worktree preserved. No commit/push/export or Computer Use. User supplied a screenshot of `gameplay.gd:613 _show_checkpoint_recovery`: a ConfirmationDialog attempted exclusive display while the save-failure AcceptDialog was already exclusive.

## Cause and fix

`CheckpointCoordinator.load_current()` emits `status_changed` synchronously when the writer lease is busy. `_checkpoint_status()` opened “Not saved”; `_continue_checkpoint()` then opened recovery without hiding that dialog. Repeated Retry and confirmed return could repeat the collision.

Changed `patch-notes/scripts/gameplay.gd`: Continue hides preceding checkpoint prompts and suppresses the generic save-failure popup while loading; recovery owns load failures. Checkpoint Quit/Return/Recovery transitions hide preceding checkpoint dialogs. Repeated recovery/return creation disposes the previous hidden window. Ordinary write failures still expose Retry. Save formats, writer lock rules, recovery consent, file preservation and gameplay are unchanged.

Expanded `patch-notes/scripts/debug/verify_checkpoint_recovery_ui.gd`: a real isolated TCP lease contention reproduces the production failure branch without accessing the user's save or writer port. At1152×648 and1280×720, test three retries, repeated status notification, confirmed-return failure, disposal of stale dialogs, successful restore after lease release, direct recovery over a save-failure prompt, Quit/Cancel and unchanged original bytes. Existing corrupt-save Cancel checks remain.

## Exact checks/results

Evidence: [checkpoint-modal-v1](../findings/checkpoint-modal-v1/). Godot4.7.1, fresh APPDATA/LOCALAPPDATA profiles. The runner is the unchanged `findings/symmetric-card-frame-v1/run.py`, loaded with runpy and its HERE redirected to this finding. Exact commands, outputs, source-before/after hashes and wrapper provenance are retained in each named folder. Its required capture-driver file is an explicit unused placeholder; no graphical capture occurred.

- `red`: BEFORE runtime fix, exit1; reproduced the exact exclusive-child engine error four times across both sizes and16 failed regression assertions. The original source is hashed in this folder.
- `verify_checkpoint_recovery_ui-green`: initial repair passes, exit0/no error markers.
- `verify_checkpoint_recovery_ui-final`: extended regression passes, exit0/no errors, both sizes.
- `verify_checkpoint_runtime-green`: exit0/no errors.
- `verify_checkpoint_store-green`: exit0/no errors.
- `verify_studio_mouse_navigation-final`: exit0/no errors; headless input-path verification, not a visible user playthrough.
- Every completed run records source/driver stability. The exact host certificate-store diagnostic remains separately filtered by the runner.
- One attempted `verify_mouse_navigation-green` dispatch stopped before Godot because that filename did not exist; corrected to the existing `verify_studio_mouse_navigation.gd` above. Its partial evidence folder is retained.

Only the UI regression was extended after the first three green runs; gameplay.gd is unchanged between all accepted checks. No new package was built; the preceding card-kit export remains pinned to its earlier source. Running game instances were not touched. The screenshot's yellow integer-division/shadowing warnings are separate from the reproduced modal error and were not changed.
