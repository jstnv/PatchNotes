# Main Menu Settings slide —2026-10-25

**FIXED locally and in the separate Menu Slides package.** Settings already used the title navigation stack, but its `FolderUI.SurfaceHost` repeatedly fitted the animated panel back to x20, canceling the slide. The native predecessor reproduces both missing-forward-motion assertions, including with a controlled slow clock.

`MenuTransitions` now marks the active view's horizontal position as animation-owned and restores/clears that state on completion or teardown. `SurfaceHost` keeps responsive width/height/top layout while honoring that moving X. The same shared stack still supplies the existing0.24s forward/back motion, input lock, focus restoration and nonanimated bypass. No separate Settings transition/controller, new UI speed, display/audio-setting behavior or gameplay change.

Main / HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`;171 inherited tracked modifications at start. Shared edits and `.codex-godot-temp` preserved. Runtime files: `scripts/ui/menu_transitions.gd`, `scripts/ui/folder_ui.gd`, and two exact predecessor identities in `scripts/market/rival_world_checkpoint.gd`. New verifier: `scripts/debug/verify_title_settings_motion.gd`. [Scoped patch](scoped-delta.patch), [file hashes](source-delta.json), [verification](verification.json), [raw manifest](external-artifacts.json).

## Checks

| Check | Result |
|---|---|
| Previous native runtime | **RED**, two missing-forward-motion failures; same result with slow clock |
| Focused immutable matrix | **5/5 PASS**, canonical unchanged: title Settings motion, folder navigation89, Settings behavior, shared padding27, Pause63 |
| Native editor, normal clock | **14/14 PASS**: visible intermediate X positions on opening/Back twice, bounded completion, stack/focus and GUI-lock restoration |
| Actual new EXE, controlled clock | **14/14 PASS**, full outgoing/incoming position traces with the same production tween; old runtime still fails under this identical checker |
| Save compatibility | Exact prior editor and actual Menu Spacing EXE player/world/RNG restoration; unknown/mixed sources reject |
| Matched model outcomes |36 legal commands/two releases retain every field except source identity; no game rules changed |
| Clean package |410 payloads/hashes/exclusions, current editor save, six native PE icon frames, headless/native EXE startup and ZIP integrity pass |

[Matrix/commands](receipts/green/result.json), [normal native trace](receipts/native/run.log), [actual EXE trace](receipts/exe-native-motion-v2/run.log), [old controlled-clock failure](receipts/red-native-slow/receipt.json), [model comparison](model-comparison.json), [build/result hashes](result.json).

The first cold packaged-renderer probe produced only one frame during its first0.24s entrance, so a trajectory checker could not observe an intermediate point. Its failure is retained. The optional **verifier-only** `--slow-ui` uses Engine time scale0.1 to expose the full trajectory; the unchanged game still uses0.24s. This is not a frame-rate/perceived-smoothness benchmark or whole-release acceptance. The normal-clock native editor route also passes. No gameplay pacing/audio clock changes or production retuning followed this harness refinement.

## Download

[Menu Slides ZIP](<C:/Users/64jus/Downloads/Patch Notes Design Folder/Builds/Patch Notes v0.02 - Menu Slides.zip>) · [EXE](<C:/Users/64jus/Downloads/Patch Notes Design Folder/Builds/Patch Notes v0.02 - Menu Slides/Patch Notes v0.02 - Menu Slides.exe>). Includes the previous spacing, starting-pool, Store and Studio fixes; preserves old packages and the Patch Notes save/settings directory. Exact bytes/hashes/build-only overrides are in [result](result.json).

Run the five exact selectors via `all_checks.py` into a fresh output/private profile; `extra.py` supplies native and genuine previous-EXE/cold-world evidence. `build.py`, `package_acceptance.py` and `report.py` retain the isolated build/direct-EXE/evidence workflow. Bulk projects/profiles remain outside OneDrive. No unrelated queued implementation, commit/push or release-readiness claim.
