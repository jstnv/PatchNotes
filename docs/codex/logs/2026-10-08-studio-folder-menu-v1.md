# Studio creation folder menu — 2026-10-08

## Scope and state

User requested “lets work on the studio folder menu.” Used the two recommended attention defaults under the user's standing instruction to use recommended answers; announced them before implementation. Branch `main`, HEAD `91ce539978b87ac0a6efe3a1e028cae5f1360f19`. Existing shared worktree edits and `.codex-godot-temp` preserved. No commit, push or export performed for this task.

## Changes

- `patch-notes/scripts/phases/main_menu.gd`: horizontal Genre Specializations / Traits / Overview folders, fixed shared panel, name above and Play below. Positive/Negative trait columns share the existing validator. Keyboard-focus scrolling, selected styling, attention stars and a short single bounce are included.
- Optional Traits clears on visit; undefined Genre and invalid Traits retain attention. Name/Genre/trait changes invalidate Overview until revisited. Play requires valid name, selections and all folders reviewed, and retains the duplicate-submission guard. Back/Escape clears draft choices. Existing checkpoint replacement confirmation remains before entering setup.
- `patch-notes/scripts/debug/verify_studio_folder_menu.gd`: focused gate, geometry, focus, cancellation, invalid traits, changed Overview, duplicate-submit and replacement-dialog coverage.
- Updated creation fixtures to the new Genre path and explicit Traits visit in `capture_first_game_tutorial`, `verify_card_motion`, `verify_feature_store_navigation`, `verify_feature_store_radial`, `verify_first_game_and_tips`, `verify_main_menu_history`, `verify_primitive_run_initialization`, `verify_sidestreet_scope_and_year`, `verify_studio_specialties`, `verify_studio_traits`, and `verify_zero_work_release` (all `.gd` under scripts/debug).
- Updated TODO, CURRENT_STATE and Studio Traits design. No economy or trait-effect implementation changed.

## Verification

Godot 4.7.1 console, isolated APPDATA/LOCALAPPDATA profiles. Exact commands and logs are in [studio-folder-menu-v1](../findings/studio-folder-menu-v1/). Headless invocation for each check: `Godot --headless --path patch-notes --script res://scripts/debug/<name>.gd`.

Passed with exit 0 and no unexpected script errors:

1. `verify_studio_folder_menu`: both 1152×648 and 1280×720; stable panel/Play geometry across three folders; optional-empty visit, invalid build, stale Overview, missing name focus, cancel reset, one creation signal and replacement cancel.
2. `verify_studio_traits`: existing trait arithmetic, actual gameplay creation, once-only financing and reconstruction; both sizes including footer clearance above HUD.
3. `verify_main_menu_history`.
4. `verify_studio_specialties`.
5. `verify_primitive_run_initialization` (its expected intentional invalid-snapshot error classified by the existing runner).
6. `verify_zero_work_release`.
7. `verify_sidestreet_scope_and_year`.

Rendered check: `Godot --path patch-notes --rendering-method gl_compatibility --script res://scripts/debug/verify_studio_folder_menu.gd -- --capture`, exit 0. Six screenshots retained; inspected Traits at 1152×648 and Overview at 1280×720. Initial nested scrollbars were removed; initial Back/HUD clearance failure was fixed by hiding the main-menu title during setup. A temporary source encoding error during editing was fixed before final passing runs. Routine root-certificate-store warning is environment noise, not a script failure.

Additional `verify_card_motion` headless run timed out at 45 seconds after reaching Store navigation; its log is retained and it is **not counted as passed**. No card-motion runtime code was changed. The updated tutorial capture and Store-specific fixtures were not fully rerun. This is local source/UI verification, not exported-build acceptance.

`git diff --check` passed (line-ending normalization warnings only).

## Follow-ups

Resourceful and Publisher Connections effects remain separate queued tasks. Banking exported acceptance and Feature research queue work remain separate; this menu change does not close them.
