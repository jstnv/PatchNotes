# Continue tutorial invitation — 2026-11-03

Branch `main`, HEAD `529aeac81bef9a36600761a35d8518f2a75f993c`; pre-existing edits and `.codex-godot-temp` preserved. No commit or push.

The user's new instruction supersedes the old save-opening invitation rule. New Studio creation continues to offer the experience/tutorial choice; staged and synchronous Continue no longer schedule it, including with unanswered preferences. The manual practice entry is unchanged. Existing awards and focused milestone guidance retain their own scheduling.

Changed `scripts/gameplay.gd`, the exact preceding compatible source entry in `scripts/market/rival_world_checkpoint.gd`, six tutorial/Continue-dependent debug checks, `design/guided-production-tutorial.md`, and `CURRENT_STATE.md`. Results and test inputs are retained under `findings/continue-no-tutorial-20261103-v1/`.

Checks (isolated profiles, Godot 4.7.1, dummy audio):

- Before the change, `verify_save_tutorial_invitation.gd` reproduced four failures: staged Continue with unanswered, skipped, and completed preferences, plus synchronous Continue.
- `verify_save_tutorial_invitation.gd`: 25/25 passed on final sources, including real staged Continue, saved Studio/world and RNG equality, optional practice, and failed-save recovery.
- `verify_new_save_loading.gd`: 18/18 passed on final sources, including new save invitation even on a returning profile and a saved checkpoint before the prompt.
- `store-center-square-20261102-v1/check_pair.gd`: 4/4 passed on final sources with the immediately preceding genuine paired fixture; typed player, finance, history, RNG and rival state preserved, unknown identity rejected. Added only exact previous source `5d104eb150215abcbbd532defc7c73fa64b4d7abd7b09bbee558e18853b2ce49` to existing compatibility validation.
- `verify_focused_integration.gd` with the real paired fixture confirmed the unrelated focused invitation still appears and preserves state, but later stopped at the employee tour because `EmployeePanel.content` is missing. The full focused-guidance suite is not a pass.
- `verify_annual_awards_gameplay.gd` ran only its three initial checks without a fixture. An older pending-ceremony fixture was rejected as incompatible; the full resumed-ceremony matrix is not verified here. No old fixture was relabeled or granted speculative compatibility.
- `git -c core.whitespace=cr-at-eol diff --check` passed for the scoped tracked files; an existing Windows line-ending warning remains.

The initial paired baseline passed its four behavioral assertions, but its source-unchanged receipt was false because a separate test file was edited while it ran; the final paired check was rerun against unchanged source and passed. Native/device and exported-build acceptance were not run.
