# Save tutorial invitation — 2026-10-24

User request: make the tutorial pop up when starting a save. Implement the existing optional invitation on each successful save opening, including previously answered/completed profiles; retain Start/Skip and no repeated prompt on ordinary Studio navigation.

## State and execution

Read CURRENT_STATE/TODO, relevant tutorial design and source, and inspected branch/HEAD/status/diff before changes. Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`. Shared worktree was already dirty; inherited work and `.codex-godot-temp` are preserved.

1. Added a focused actual-save/Continue verifier; observed three expected RED failures for previous Skip, completion and synchronous load.
2. Added the save-opening flag to the existing guarded invitation, called after successful load/overlay removal. Added exact preceding presentation-source compatibility.
3. Verified 26 invitation checks, existing tutorial UI115, preferences and loader158; genuine preceding two-release world restores every field and RNG exactly while unknown/mixed identities reject.
4. Updated pause/recovery fixtures to explicitly Skip the new invitation. Their refreshed checks pass, including pause63. Initial old-fixture pause failure is retained.
5. Updated design/TODO/CURRENT_STATE and retained source hashes, narrow deltas, commands/results and source-fenced receipts in [the finding](../findings/save-tutorial-invitation-20261024-v1/README.md).

## Exact checks

Python runtime: `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe -X utf8`.

- `docs/codex/findings/overnight-20261024-v1/all_checks.py --output C:/Users/64jus/AppData/Local/Temp/pn-save-tutorial-20261024-v1/red --port 47744 --tests verify_save_tutorial_invitation`: expected FAIL, three missing-invitation assertions, canonical unchanged.
- Same runner with `--output .../green --port 47744 --tests verify_save_tutorial_invitation verify_guided_tutorial_ui verify_guided_tutorial_preferences verify_continue_loading`: PASS4/4, canonical unchanged.
- Same runner with `--output .../regressions-final --port 47745 --answered-onboarding --tests verify_pause_menu verify_checkpoint_recovery_ui`: PASS2/2, canonical unchanged.
- `docs/codex/findings/save-tutorial-invitation-20261024-v1/work.py prior` and `cold`: PASS; runtime `6800a07e...` to `900d63cc...`,36-command preceding fixture, exact fields/RNG and rejection checks.
- `docs/codex/findings/save-tutorial-invitation-20261024-v1/audit.py`: six passing suite receipts plus exact compatibility/source fence.
- Scoped `git -c core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol diff --check`: PASS.

Changed source: gameplay invitation dispatch, exact prior-source codec entry, new save invitation verifier, pause/recovery test fixtures. Documentation changes are confined to tutorial design, queue/current summary, this log and the new finding. No gameplay schema/rule changes, export, commit or push. No blocker remains for the requested trigger; human learning/audible/device acceptance and refreshed EXE remain separate.
