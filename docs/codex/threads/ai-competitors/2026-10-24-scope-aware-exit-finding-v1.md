# AI Competitors: fixed exits leave Scope unfinished — 2026-10-24

**CONFIRMED ACTIVE/TRIAL behavior and OPEN design correction.** The user's observation about leaving available Feature work unfinished applies to the present rival policy's *stopping rule*. It is not an instruction copied from computer-control play: `patch-notes/scripts/market/rival_trial.gd` fixes `HANDS_PER_PHASE = 2` and requests exit after two played hands whenever `can_exit` is true. It does not require Scope completion, inspect the remaining positive-Scope cards at that decision, or weigh the expected Review gain against another hand. If an Alpha exit is under Scope, `development_session.gd` raises an `under_scope` warning, then the rival policy confirms it. A confirmed under-Scope release is legal under the [LOCKED finite-project decision](2026-10-09-finite-project-policy-decision-v1.md); the exact planned hands and exit thresholds are **OPEN**, not a locked rule to stop under Scope.

The [read-only source-pinned audit](sims/rival-scope-exit-audit-20261024-v1.json) checks the two frozen current-source v9 ACTIVE/TRIAL worlds, seed 4417 and 4418, with 32 actual incumbent releases. Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; source identity `52f17193654e59b9a3313b745919a86a8d769f1c667ff491a7f14d802ad04b1d`. All original worlds were legal, complete and source/RNG checked in the [prior Core/Review finding](2026-10-24-core-review-current-source-finding-v1.md). This audit has no new game run or source mutation.

| Observed current-policy result | Count |
| --- | ---: |
| Rival releases below required Scope 30 | **32/32** |
| Release Scope range / mean | **18–28 / 23.625** |
| Alpha exit requests below Scope | **32/32** |
| Those Alpha exit deals showing at least one positive-Scope Feature | **29/32** |
| Alpha exit confirmations | **32/32** |

`PrimitiveReviewCalculator` multiplies production quality by `min(Scope/required Scope, 1)`, so this shortfall directly lowers Reviews. A visible positive-Scope Feature does **not** prove that a full four-card next hand is legal, affordable or optimal, or that one hand could reach 30. The fixed exit condition nevertheless never asks those questions. The current selector ranks legal hands **only when the policy has already decided to play**; better synergy ranking cannot rescue an exit that occurs before another hand.

The previous legal thirteen-cycle 4/6/2 route filled Scope in 14/16 releases, but reduced rival publications from 32 to 16 across the same two seeds and eased the player's fixed-horizon market. Thus simply requiring Scope 30 before exit risks losing publication density and violates the finite-plan safeguard when cards/cash cannot complete it. The next design trial should use a **bounded Scope-aware exit**: inspect actual current Scope, the visible legal/affordable hand and cash, preserve a finite cycle/zero-step budget, and allow ordinary confirmed under-Scope exit when the bounded plan is exhausted or additional work cannot be justified. Score the decision with actual Review, Bug and market-density opportunity cost; test at least ten productive cycles and first/later title progression. Do not treat positive-Scope visibility alone as sufficient action legality. Exact floor/threshold, hand and cash envelope, Feature supply, QA, population/entrants and CPU are **OPEN**.

This finding recommends a next study, not a numerical rule or implementation handoff. It does not approve delaying every release until full Scope, modifying player exits, or adding free Core/Scope. No canonical gameplay, player save, computer control, commit or push was used.

## Reproduction

```powershell
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' docs/codex/threads/ai-competitors/2026-10-24-scope-exit-audit-v1.py
```

The script refuses to overwrite its preserved [output](sims/rival-scope-exit-audit-20261024-v1.json). Input report paths, per-exit candidate cards/Scope, actual releases and checks are in that output and the original v9 world folders.
