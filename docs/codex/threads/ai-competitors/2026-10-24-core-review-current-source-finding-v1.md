# AI Competitors: current-source Core-to-Review diagnosis — 2026-10-24

**COMPLETE bounded DESIGN finding; no gameplay adoption.** The [pre-run plan](2026-10-24-core-review-audit-plan-v1.md) re-ran the actual two-incumbent world at the current captured source. The thirteen-cycle witnessed legal route still does not make Reviews generally 6–7, but its **remaining Bugs, not an absolute four-Core ceiling, explain the observed misses**. This does not establish an attainable global maximum or approve free Bug removal.

## Source and method

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, shared dirty worktree preserved. The [thread-owned v9 variant](simulators/rival-core-review-audit-20261024-v9/variant.json) was captured directly from the then-current canonical working project, baseline and canonical identity both `975b3be9228c938032cce307c8410b4d57d03c77df9880b86f63e325807d05eb`, baseline drift **false at capture**. Only its private `project/scripts/market/rival_trial.gd` adds a 4/6/2 best-visible-four diagnostic plan; ordinary `policies(world)` stays 2/2/2. Frozen gameplay replay source identity `52f17193654e59b9a3313b745919a86a8d769f1c667ff491a7f14d802ad04b1d`. Godot 4.7.1 SHA-256 `323f9c4cc5db674e98815cdd8e69da007d5efc779abedc8c0e42883b7fdea12a`. The implementation thread may change the shared source after this capture; the frozen bundle is authoritative for these numbers.

The [isolated smoke](sims/rival-core-review-audit-smoke-20261024-v9/run-report.json) passed 18 legal commands/cycle 7. The existing isolated [interleaved world runner](six-hand-phase-study-20261023-v1/run_world.py) then ran seed 4417 and 4418, each A current 2/2/2 versus B private 4/6/2, with actual January Arcade Foundry and Wayfinder Works, legal Action/Fantasy player route, no injections, and eight player releases/144 commands by cycle 56. The [read-only formula/state audit](sims/rival-core-review-audit-20261024-v9.json) confirms matched full initial state, typed RNG and frozen source within each seed, all complete worlds, zero reported failures, and minimum thirteen-cycle rival publication spacing in B. A worlds report 15,174 checks each; B worlds 9,974 each. Bounds were 210 commands, eight releases by cycle 64, 12 zero-step rival actions and 480 seconds; neither seed was changed or dropped.

The analyzer reproduces the current `PrimitiveReviewCalculator` four capped Core/target ratios, balance penalty, production scale, Scope/30 and Bug/30 multipliers, and one of the five legal variance modifiers for every actual rival Review. Each of the 16 B releases matches exactly one variance modifier. Its **same-Core no-Bug** row changes only remaining Bugs in the formula while retaining actual Scope and variance. Its stronger full-Scope/zero-Bug/+0.5 result is explicitly an optimistic mathematical upper bound; neither is an executable route or a legal Feature-mix ceiling. [Audit script](2026-10-24-core-review-audit-v1.py).

## Actual outcomes

| Seed/arm | Rival titles by player cycle 56 | 6.0+ Reviews | Rival Review tenths, Arcade then Wayfinder | Player earned units | Player settled cash delta vs A |
| --- | ---: | ---: | --- | ---: | ---: |
| 4417 A, 2/2/2 | 16 | 0 | Arcade 15,37,24,22,23,30,15,24; Wayfinder 16,27,37,32,33,27,25,20 | 1,737 | control |
| 4417 B, 4/6/2 | 8 | 3 | Arcade 57,67,44,45; Wayfinder 45,59,73,63 | 1,903 | +$1,160.82 |
| 4418 A, 2/2/2 | 16 | 0 | Arcade 30,27,28,24,28,28,32,24; Wayfinder 25,13,20,19,25,19,28,21 | 1,733 | control |
| 4418 B, 4/6/2 | 8 | 2 | Arcade 55,57,62,47; Wayfinder 64,46,53,57 | 1,896 | +$1,139.85 |

B's player paid units rise by 71/83, settled cash by the amounts shown, and Fans remain unchanged. The longer plan is not a market-challenge policy; it halves actual rival publications, easing the fixed-horizon player economy. CPU was 64.6/63.0 seconds for A and 59.6/58.3 seconds for B in these two-rival worlds; these shared-host observations do not set a population budget. Full per-release Core, Scope, Bugs, standards, cash, CPU and checkpoint sizes remain in the audit.

Across B's **16 real releases**, 14 already met the Scope 30 target. Core production ratings range 6.24–7.77. All 16 had enough actual Core for a 6.0+ Review under the same actual Scope and variance if remaining Bugs were zero; only five actually reached 6.0. Thus the 11 misses are Bug-sensitive in this witnessed route. This does **not** prove a legal two-Beta-hand path could remove all Bugs. The active market raised frozen Action targets by two or four points on six later B projects; Adventure remained at base targets on this player route. Replacing frozen targets with base targets at unchanged Core/Scope/Bugs raises the 6.0+ count only from five to six. Market target pressure matters, but it does not account for most of these sub-6.0 Reviews. The public development observation exposed frozen standards in **0 of 570** B hand observations, so a target-aware AI policy would require a separately reviewed observation change.

The [visible Beta-hand census](sims/rival-beta-offer-audit-20261024-v9-v2.json) counted 32 legal B Beta plays: 14 visible deals had no Search card. Of the 16 deals offering both Search and Debug, the current selector chose both in 15. This points to card availability/redraw opportunity and limited QA time, rather than simply failing to select obvious Search/Debug pairs. The first read-only [census script v1](2026-10-24-beta-offer-audit-v1.py) failed with a missing script field before writing output; [v2](2026-10-24-beta-offer-audit-v2.py) corrected that analysis-only error. No world was modified.

[B seed 4417's exact fresh-process replay](sims/rival-core-review-audit-4417-B-replay-20261024-v9/world-run.json) passed 144 commands and 10,058 checks with matching final checkpoint. The four original A/B [4417 A](sims/rival-core-review-audit-4417-A-20261024-v9/world-run.json), [4417 B](sims/rival-core-review-audit-4417-B-20261024-v9/world-run.json), [4418 A](sims/rival-core-review-audit-4418-A-20261024-v9/world-run.json), [4418 B](sims/rival-core-review-audit-4418-B-20261024-v9/world-run.json) outputs retain exact commands, tapes, snapshots, checkpoints and logs. Studio-only Continue was not run because the 13-cycle policy fails the player-market gate.

## Disposition

Do not choose an arbitrary Store/Core purchase or change Review coefficients to force a 6.0 target. The next private test is a bounded legal Beta redraw when Search or Debug is missing, keeping the same productive hand count; its [pre-run plan](2026-10-24-beta-redraw-plan-v1.md) is separate. Longer-term Store/Core supply, frozen-target observation, Genre/Theme choices, entrant density, population CPU, news and leaderboard remain **OPEN**. No adoption packet or numerical approval follows this diagnosis.

## Representative reproduction

```powershell
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/simulate.py run --variant docs/codex/threads/ai-competitors/simulators/rival-core-review-audit-20261024-v9 --config docs/codex/threads/ai-competitors/six-hand-phase-study-20261023-v1/smoke.json --output docs/codex/threads/ai-competitors/sims/rival-core-review-audit-smoke-20261024-v9 --godot 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe' --timeout 240
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' docs/codex/threads/ai-competitors/six-hand-phase-study-20261023-v1/run_world.py --bundle docs/codex/threads/ai-competitors/sims/rival-core-review-audit-smoke-20261024-v9 --output docs/codex/threads/ai-competitors/sims/rival-core-review-audit-4417-B-20261024-v9 --godot 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe' --source 52f17193654e59b9a3313b745919a86a8d769f1c667ff491a7f14d802ad04b1d --route action-fantasy --seed 4417 --candidate 1 --arm B
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' docs/codex/threads/ai-competitors/2026-10-24-core-review-audit-v1.py
```

Use the actual Godot executable path in the retained `world.command.json`; fresh output directories are required for reruns. For A use `--candidate 0 --arm A`, and for seed 4418 change the seed/output path together. The archived command records, not this illustrative repeated-output path, pin the executed argv.
