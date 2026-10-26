# Save-opening tutorial invitation — 2026-10-24

**IMPLEMENTED locally.** Opening a save now offers the optional tutorial even after a previous Skip or completion. The loading overlay finishes first. Start enters isolated practice; Skip reveals the restored Studio. Ordinary Studio navigation does not repeat an answered invitation, and failed loads retain the recovery flow.

## Source and scope

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty shared worktree preserved. Exact preceding runtime `6800a07e9c01c2aa0476d8251afdfc3f0f3c61ad5989ff2c99bcd813d1c2ae65`; current runtime `900d63cc8e8ce4f2928ec127c3cb9d87e1ca6b5ec3ba18555ac49294fc7c2c1c`. [Full source hashes](source.json), [scoped delta against the frozen preceding source](scoped.patch), [audit summary](result.json).

- `scripts/gameplay.gd`: explicit save-opening invitation bypasses the remembered-answer filter after successful staged or synchronous restore. Existing single-instance/loading guards remain active.
- `scripts/market/rival_world_checkpoint.gd`: admit only the measured immediately preceding presentation source with current content; ordinary full-world validation still applies.
- New `scripts/debug/verify_save_tutorial_invitation.gd`: actual Continue after previous Skip/completion, duplicate input, Start/Skip/Exit, ordinary navigation, synchronous restore, failed load and exact state/disk checks.
- Pause/recovery verifiers explicitly Skip the newly expected invitation before testing those systems.
- Design, execution ledger, current-state summary and dated session record document the changed trigger.

## Verification

| Check | Result |
|---|---|
| Before implementation: remembered Skip/completion and synchronous restore | RED: three missing-invitation failures |
| New save invitation verifier | PASS: 26 checks |
| Existing full tutorial UI verifier | PASS: 115 checks |
| Tutorial preferences verifier | PASS |
| Continue loader verifier | PASS: 158 checks in this run |
| Pause verifier after explicit invitation Skip | PASS: 63 checks |
| Recovery UI verifier after explicit invitation Skip | PASS |
| Genuine preceding-source two-release world, 36 legal commands, cold restore | PASS: every saved field/RNG exact; unknown source and mixed content reject |

Six final maintained suites passed in private profiles and immutable imported project copies. The last source delta between the tutorial/loader checks and final pause/recovery checks contains only those two verifier fixtures. Both successful runner batches report `canonical_unchanged: true`. [Retained receipts and logs](receipts/) include the initial regression attempt whose old pause fixture did not dismiss the new prompt; that fixture failure is not presented as a runtime pass.

Commands, private profile paths, harness hashes and exit/error records are in receipts. Run `all_checks.py --tests verify_save_tutorial_invitation verify_guided_tutorial_ui verify_guided_tutorial_preferences verify_continue_loading` with a new output folder; run pause/recovery with `--answered-onboarding` for their initial Studio fixture. `work.py prior` and `work.py cold` generate/restore the frozen preceding world; `audit.py` checks the retained evidence/source fence.

Raw workspace: `C:/Users/64jus/AppData/Local/Temp/pn-save-tutorial-20261024-v1`. No player saves were accessed. Existing practice sandbox, Studio-only Continue boundary and gameplay rules remain intact. This trigger change was verified headlessly; no new audible/device playtest or EXE export was performed. Download packages still predate this change. No commit or push.
