# AI Competitors trial activation — local session log, 2026-10-17

## Checkout and scope

Branch `main`, starting and final observed HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`. The shared worktree was dirty before this pass, including other Gameplay, Store, finance, audio, documentation and simulator artifacts. Existing edits and `.codex-godot-temp` were preserved. The user authorized foundation implementation, deferred balance work, and chose to activate provisional rivals in normal new games. No commit, push, external dispatch or player-save access occurred.

This pass extended the earlier scene-free `RivalWorld` with a typed frozen historical archive and a separate `RivalWorldCheckpoint`, created a provisional two-studio `RivalTrial`, connected world creation/calendar ticking/Continue in `gameplay.gd`, extended the checkpoint coordinator/schema/Studio validation for active rival hands, added no-redraw development restore and a trial roster in Studio. The source files are `patch-notes/scripts/market/{rival_world,rival_world_checkpoint,rival_trial}.gd`, `scripts/gameplay.gd`, `scripts/persistence/{checkpoint_coordinator,checkpoint_schema,studio_checkpoint,startup_data_check}.gd`, `scripts/simulation/development_session.gd`, and `scripts/phases/studio_phase.gd`, plus their applicable Godot UIDs. Three new focused activation verifiers and UIDs live under `scripts/debug/`. No Store/Core planner, entrant logic, Review modifier or release news was added.

The thread-owned records are the [decision](../threads/ai-competitors/2026-10-17-trial-activation-decision-v1.md), [acceptance plan](../threads/ai-competitors/2026-10-17-trial-activation-acceptance-plan-v1.md), [source-pinned finding](../threads/ai-competitors/2026-10-17-trial-activation-finding-v1.md) and isolated [verifier runner](../threads/ai-competitors/run_rival_verifier_v2.py). The AI thread README/notes, cross-system decisions, current state and TODO item 22 were minimally reconciled. Earlier records remain historical.

## Exact evidence

Final isolated source bundle: [v21 run report](../threads/ai-competitors/sims/trial-activation-smoke-20261017-v21/run-report.json), source identity `266677e2393536b7a3fc69b224479b81e04ebc158299e053a4c32331d8ccd235`, Godot 4.7.1 hash `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`. Import source changes were empty. The legal 18-command player route completed one release and [fresh-process replay](../threads/ai-competitors/sims/trial-activation-replay-20261017-v1/replay-report.json) matched 18/18 commands.

From repository root, the frozen run and focused command form were:

```powershell
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/simulate.py run --config docs/codex/threads/ai-competitors/2026-10-17-foundation-smoke-v1.json --output docs/codex/threads/ai-competitors/sims/trial-activation-smoke-20261017-v21 --godot 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --timeout 90
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' docs/codex/threads/ai-competitors/run_rival_verifier_v2.py --bundle docs/codex/threads/ai-competitors/sims/trial-activation-smoke-20261017-v21 --output docs/codex/threads/ai-competitors/sims/trial-activation-acceptance-20261017-v1 --godot 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --script verify_rival_trial_activation.gd --test-port 47738 --timeout 100
```

The same focused runner used unique outputs for `verify_rival_gameplay_activation.gd` (`trial-gameplay-acceptance-20261017-v1`, port 47739, timeout 60) and `verify_rival_gameplay_cold_continue.gd` (`trial-cold-acceptance-20261017-v1`, same isolated profile/port, timeout 60), and for the existing `verify_studio_checkpoint.gd`, `verify_campaign_session.gd` and `verify_rival_world_foundation.gd` regressions. Exact paths, cold profile argument and logs are in the finding.

Results: [118/118 controlled world checks](../threads/ai-competitors/sims/trial-activation-acceptance-20261017-v1/rival-verifier.log) with 20 synchronized cycles and four real releases; [10/10 normal Gameplay checks](../threads/ai-competitors/sims/trial-gameplay-acceptance-20261017-v1/rival-verifier.log); [9/9 separate-process Continue checks](../threads/ai-competitors/sims/trial-cold-acceptance-20261017-v1/rival-verifier.log). Existing checkpoint and campaign checks had zero failures; original world regression passed 156/156. Design and Beta hands kept full-state digests across Continue. A current-revision player-only payload remained valid and did not acquire rivals. Future-dated historical archive tampering was rejected. `git -c core.whitespace=cr-at-eol diff --check` passed on the edited tracked paths.

## Failed attempts and remaining work

Earlier v1–v20 exploratory bundles and focused outputs are retained. They include parse/schema/typed-array restore repairs, a verifier lease collision corrected by isolated test ports, and a timed-out verifier corrected by a script watchdog. Final successful runs still show six Godot ObjectDB exit warnings; they have no failed assertions or runtime error marker.

This is **ACTIVE/TRIAL foundation**, not final AI or balance approval. Cohort names/resources, exact action allowances and AI choices, dynamic Genre-Core Store shopping, entrants, next-month high-Review news, CPU/population bounds and cross-revision migration remain **OPEN**. Rendered interaction and exported build checks are **NOT RUN**. Existing player-only saves prospectively continue without rivals. Market influence on Reviews remains a separate design topic. Item 22 stays PARTIAL.
