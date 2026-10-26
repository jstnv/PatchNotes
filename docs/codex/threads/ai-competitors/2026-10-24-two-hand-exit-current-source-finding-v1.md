# Current-source retirement of the two-hand rival exit — 2026-10-24

**COMPLETE bounded DESIGN study; narrow implementation review recommended.** The [pre-run plan and retained amendments](2026-10-24-two-hand-exit-replacement-plan-v1.md) test the user's [LOCKED visible-Feature rule](2026-10-24-feature-exhaustion-exit-decision-v1.md), reaffirmed in the [retirement decision](2026-10-24-two-hand-exit-retirement-decision-v1.md). The first private revision exposed a bad extra preflight; the corrected current-source revision legally plays visible Features and reproduces the older study's Scope/Review improvement and loss of publication density. No canonical gameplay changed.

## Source and experiment boundary

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; the broad inherited dirty checkout and `.codex-godot-temp` were preserved. [Private v19](simulators/rival-feature-maximal-current-20261024-v19/variant.json) forks retained rejected v18 from current canonical baseline `2854718a8c8f6f7c10dbc42ec69e66c7deb975f75c35720e6e659b424524e29a`. Its frozen gameplay source identity is `0749046f8ae3d111ec703dc5906d4bab111da9c2ec53549ae7026000ff9d6c12`; Godot 4.7.1 SHA-256 is `323f9c4cc5db674e98815cdd8e69da007d5efc779abedc8c0e42883b7fdea12a`. Only the private `project/scripts/market/rival_trial.gd` changes. No QA, cohort, cash, Store, Review or market coefficient changes were made.

Both arms share the same frozen source. Diagnostic A calls the original current two-hand policy. Production-facing B calls the Feature-maximal wrapper: enumerate legal four-card subsets of the **current visible** Design/Alpha pool, require actual phase-hand legality and exact current Feature fee within cash, maximize Feature count, then use the existing G4 proxy and stable token tie. It re-evaluates after every real hand and exits when no current visible Feature hand is legal and affordable. Beta remains two hands. The diagnostic `project_plan_policies` A helper is **not intended for canonical adoption**. B has no artificial Design/Alpha or total project-cycle limit.

The two legal January worlds use the existing Arcade Foundry and Wayfinder Works cohort and the Action/Fantasy player route, seeds 4417/4418. Each A/B pair has an equal **full founding-state digest and typed RNG**; the [read-only audit](sims/rival-feature-maximal-current-audit-20261024-v19.json) enforces both. All four worlds finish eight legal player releases, 144 commands and cycle56 under the declared 210-command/cycle64/twelve-zero-step/480-second limits. No released or active project is fabricated at the horizon.

## Actual outcomes

| Seed | Policy | Rival titles | Mean rival Review | Reviews ≥6.0 | Scope ≥30 | Player earned units | Player final cash |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 4417 | A, two-hand | 16 | 2.54 | 0 | 0 | 1,737 | $1,336.82 |
| 4417 | B, visible Features | 10 | 5.00 | 1 | 9 | 1,860 | $2,196.95 |
| 4418 | A, two-hand | 16 | 2.44 | 0 | 0 | 1,733 | $2,128.84 |
| 4418 | B, visible Features | 10 | 4.54 | 0 | 7 | 1,819 | $2,730.25 |

B plays **82 distinct Design/Alpha Feature hands per seed**, each selecting `min(4, visible Feature count)` from its observed deal. All **41 distinct Design/Alpha exit requests** across B have zero visible Features. Actual commands report no failure. First B reviews are Arcade/Wayfinder 5.9/3.4 on 4417 and 4.7/5.6 on 4418; later releases do not make 6s or 7s common. The player earns **123/86 more units** and has **$860.13/$601.41 more settled cash** than A. Replacing the exit is justified by the LOCKED play rule and Scope repair, but **does not by itself meet the rival challenge target**; publication density and legal QA need separate work. This is not approval of a market coefficient or four-rival opening cohort.

The [4417 A](sims/rival-feature-maximal-4417-A-20261024-v19/world-run.json), [4417 B](sims/rival-feature-maximal-4417-B-20261024-v19/world-run.json), [4418 A](sims/rival-feature-maximal-4418-A-20261024-v19/world-run.json) and [4418 B](sims/rival-feature-maximal-4418-B-20261024-v19/world-run.json) records pass with 15,174/11,015/15,174/11,518 world checks respectively. [4417 B exact fresh-process replay](sims/rival-feature-maximal-4417-B-replay-20261024-v19/world-run.json) passes 11,099 checks; [Studio-only cold Continue](sims/rival-feature-maximal-4417-B-restore-20261024-v19/world-run.json) passes eight. The [isolated v19 smoke](sims/rival-feature-maximal-smoke-20261024-v19/run-report.json) passes 18 legal commands and one player release. World process CPU is 176.03/159.61 seconds for 4417 A/B and 173.56/165.88 for 4418 A/B; checkpoints are about 0.80 MB A and 0.71–0.73 MB B. These shared-host diagnostic costs, with only two rivals, establish no approved CPU or population budget.

## Retained failed and incomplete attempts

- Two current-source variant creations, v16 and v17, were interrupted during slow metadata/provenance work before `variant.json` existed. Their partial directories are retained and are **not** candidate versions. v18 and v19 completed the required variant creation and integrity checks.
- [v18 simultaneous 4417 B](sims/rival-feature-maximal-4417-B-20261024-v18/world-run.json) hit the unchanged 480-second process limit after player cycle56/step143, before a completed report. Its [solo repeat](sims/rival-feature-maximal-4417-B-solo-20261024-v18/world-run.json) completed, exposing an **invalid policy revision**: the extra `can_complete_productive_cycle(-cost)` call inside choice screened every opening Design Feature despite $5,850 cash, and rivals exited Design with no Feature hands. The resulting 28 weak titles are not evidence for the intended rule. v19 removed only that extra preflight and retained actual hand legality, exact cost and ordinary resolver validation. No timeout, seed or bound was altered to make v18 pass.

## Disposition and remaining acceptance

Recommend a **narrow current-source implementation review** for the qualitative Design/Alpha stopping rule. Implement the B production behavior while omitting its diagnostic A helper. Keep the current G4 proxy only as an ACTIVE/TRIAL tie among equally Feature-maximal hands. Do not combine the rejected v18 preflight or the v15 redraw/four-Studio/full-pool cash policies. The player hand, Beta, current rivals, score formula and market coefficients are unchanged in this packet.

The observed B exits all have zero visible Features; a **cash-blocked visible Feature, short pool and illegal-exit fallback were NOT TESTED** here. A focused legal fixture and explicit blocked reason are required before calling canonical integration complete. Also verify current-source saved action/RNG, one productive action per rival player cycle, bounded zero-cycle transitions, later owned Store cards, and representative population CPU/save limits. The v19 helper ranks equal-Feature hands with the G4 proxy even when `uses_synergy_trial` would disable it for former-player or richer-pool Studios. These two worlds contain only enabled incumbents; **do not byte-copy that tie behavior** into canonical gameplay. Preserve the current cohort gate and test its disabled branch. Subsequent QA and publication-density work must restore challenge without weakening the locked Feature rule. Passing this study is not balance approval or release readiness.

## Reproduction

Every linked `world.command.json` contains its exact command, source and limits. Representative invocations from the repo root:

```powershell
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/simulator_variant.py create --id rival-feature-maximal-current-20261024-v19 --owner ai-competitors --from-variant docs/codex/threads/ai-competitors/simulators/rival-feature-maximal-current-20261024-v18 --output docs/codex/threads/ai-competitors/simulators/rival-feature-maximal-current-20261024-v19
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/simulate.py run --variant docs/codex/threads/ai-competitors/simulators/rival-feature-maximal-current-20261024-v19 --config docs/codex/threads/ai-competitors/six-hand-phase-study-20261023-v1/smoke.json --output docs/codex/threads/ai-competitors/sims/rival-feature-maximal-smoke-20261024-v19 --godot 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe' --timeout 240
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' docs/codex/threads/ai-competitors/six-hand-phase-study-20261023-v1/run_world.py --bundle docs/codex/threads/ai-competitors/sims/rival-feature-maximal-smoke-20261024-v19 --godot 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe' --source 0749046f8ae3d111ec703dc5906d4bab111da9c2ec53549ae7026000ff9d6c12 --route action-fantasy --seed 4417 --candidate 1 --arm B --output docs/codex/threads/ai-competitors/sims/rival-feature-maximal-4417-B-20261024-v19
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' docs/codex/threads/ai-competitors/2026-10-24-feature-maximal-current-audit-v1.py
```

Use new output names on rerun. Existing successful, incomplete, rejected, replay and restore folders are retained.
