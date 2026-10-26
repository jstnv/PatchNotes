# First-release disabled Studio actions — 2026-10-25

## Source / request

User's older-EXE screenshot shows Post Game Summaries/Contracts disabled after release, plus Produce First Game despite one title on market. Read current state/TODO, core/Studio and relevant Contract design/source, previous icon package records, branch/HEAD/status/diff. `main` / `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`;169 tracked files already modified before this pass. Preserved inherited UI/gameplay changes, `.codex-godot-temp`, player saves and all old packages. The newly queued Contracts Search handoff was preserved and is outside this bug fix.

## Investigation and fix

Used systematic debugging and a failing maintained regression before production edits. Actual Paper Icon EXE failed exactly the two new assertions. Gameplay prevalidates Studio before committing launch, and setup cached the old button states; scene `_ready()` refreshed lists/results but not actions. The release was already permanently registered.

Added one idempotent action refresh in Studio setup and `_ready()`, so the mounted scene uses committed state. Histories/Next Game and only legally available Contract offers enable without replaying any registration or payout. Added exact783a2929 predecessor compatibility after cold verification. Gameplay transaction order, scoring, finance, RNG and one-shot offer rules remain unchanged.

Production files: `patch-notes/scripts/phases/studio_phase.gd`, `patch-notes/scripts/market/rival_world_checkpoint.gd`. Maintained fixture: `patch-notes/scripts/debug/verify_beta_finalization_and_launch.gd`. Findings contain helpers, source/delta, compact receipts, three actual-EXE screenshots and build/package manifests. [Full results/files/downloads](../findings/studio-release-actions-20261025-v1/README.md).

## Checks / exact command pattern

Python: `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe -X utf8`.
Godot: `C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe`.
Raw root: `C:/Users/64jus/AppData/Local/Temp/pn-studio-release-actions-20261025-v1`.

```text
python -X utf8 docs/codex/findings/studio-release-actions-20261025-v1/checks.py red-exe --pack <Paper Icon EXE>
python -X utf8 docs/codex/findings/overnight-20261024-v1/all_checks.py --output <raw>/green --port 47745 --answered-onboarding --tests verify_beta_finalization_and_launch verify_main_menu_history verify_release_menus verify_contract_ui verify_contracts verify_checkpoint_phase verify_save_tutorial_invitation verify_continue_loading verify_ui_folder_navigation
python -X utf8 docs/codex/findings/studio-release-actions-20261025-v1/supplement.py
python -X utf8 docs/codex/findings/studio-release-actions-20261025-v1/build.py
python -X utf8 docs/codex/findings/studio-release-actions-20261025-v1/checks.py fixed-exe-launch --pack <Studio Fix EXE>
python -X utf8 docs/codex/findings/studio-release-actions-20261025-v1/checks.py played-fixed-exe --pack <Studio Fix EXE> --script docs/codex/findings/studio-release-actions-20261025-v1/played_launch_probe.gd --native
python -X utf8 docs/codex/findings/studio-release-actions-20261025-v1/checks.py exe-prior-save --pack <Studio Fix EXE> --script docs/codex/findings/store-prerequisite-links-20261024-v1/world_probe.gd --input C:/Users/64jus/AppData/Local/Temp/pn-ui-design-system-20261025-v1/prior-pack/result.json
python -X utf8 docs/codex/findings/studio-release-actions-20261025-v1/collect.py
```

Old EXE RED2 failures; fixed EXE same regression PASS. Native actual EXE18/18:12 legal headless Design/Alpha commands from a fresh Role-Playing Studio, two live Beta hands, real launch, pointer Continue/Summary/Back/Contracts, screenshot and passive-state/RNG checks. This is a bounded hybrid route; no claimed manual Design/Alpha playthrough. Nine maintained suites have passing receipts (six matrix, three valid supplement names), not one uninterrupted green gate. Folder UI89/89 and save invitation26/26 pass among them.

Two real releases/36 legal commands on old783a and new874f editor runtimes produce exact same player/world/RNG outcomes except source identity. Prior UI world restores exactly into fixed editor; actual prior0b04 EXE world restores exactly into57da compiled runtime, with unknown/mixed sources rejected. New current-editor world also restores exactly in the compiled package. All helpers use private profiles; no real player-save writes.

Clean import/export,410-entry payload audit/exclusions, current-editor bridge, six PE icon frames, actual headless/native startup and ZIP pass. Separate116,984,592byte EXE and44,246,929byte ZIP delivered; hashes in findings. Canonical source and all export inputs remain unchanged during build; old Paper Icon EXE hash is unchanged. Shared UI/fonts/license manifest are included in the new build.

## Retained failures / completion boundary

Initial matrix contains three nonexistent selectors and six auto-generated `.import` additions, so its aggregate remains false. Every executed suite passed; actual Contract/checkpoint selectors passed separately, and no runtime code/input asset changed. Native helper failures (type inference, planning-overlay closure, input scaling, ordinary Contract tip acknowledgement) are kept and corrected explicitly. Exact remaining saved fields/RNG are still asserted; no gameplay check was suppressed. Compact records retain original failures and successful receipts.

TODO/CURRENT_STATE and core/Studio design record the completed bug fix. No queued Contract Search task is marked complete. No commit/push, clean-machine/audio/full-game acceptance or whole-release-readiness claim.
