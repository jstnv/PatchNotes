# AI Competitors: equal-duration QA allocation — 2026-10-24

**COMPLETE bounded DESIGN finding; reject both candidate allocations.** The [pre-run plan](2026-10-24-qa-allocation-plan-v1.md) held each rival title at thirteen productive cycles and moved Alpha or Design hands to Beta. The two candidate policies lowered Reviews. No gameplay rule or balance value is approved.

## Source and comparison

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`; shared dirty worktree preserved. The [thread-owned v5 variant](simulators/rival-qa-allocation-20261024-v5/variant.json) descends from private v4 and original canonical baseline `ea4a095970c0893d0af20b85236d9be9f171177bc39cebc7deacabd03a91a18d`. Only its `project/scripts/market/rival_trial.gd` policy changed. Frozen replay source identity: `56e14a858877ae5dd02ba6251a5d0da19b4a3e8793d20ac26c44a5b83d9a81fb`. Current canonical project has drifted from that baseline; fresh reconciliation would be required for any adoption. Godot 4.7.1 SHA-256 `323f9c4cc5db674e98815cdd8e69da007d5efc779abedc8c0e42883b7fdea12a`.

All arms use the actual two-incumbent January cohort, the same Action/Fantasy player, best-visible-four Design/Alpha choice and ordinary Beta choice. A is 4/6/2, B 4/5/3, C 3/6/3. Each has a project start plus twelve legal hands. [Read-only audit](sims/rival-qa-allocation-audit-20261024-v1.json) confirms full initial state, typed RNG and source equality. Seed 4417, 144 legal player commands, eight player releases through cycle 56, and eight rival titles in every arm. Each world completed with 9,974 checks, zero failures. Command/release/cycle/wall guards were 210/eight/64/480 seconds; seed 4418 was **NOT RUN** under the declared stop.

| Arm | Arcade Reviews, tenths | Wayfinder Reviews, tenths | Reviews at least 6.0 | Rival CPU |
| --- | --- | --- | ---: | ---: |
| A 4/6/2 | 57, 67, 44, 45 | 45, 59, 73, 63 | 3/8 | 65.2 s |
| B 4/5/3 | 55, 51, 54, 51 | 43, 49, 62, 61 | 2/8 | 65.3 s |
| C 3/6/3 | 53, 49, 49, 48 | 44, 47, 60, 59 | 1/8 | 63.5 s |

All rival publications remained at cycles 13, 26, 39 and 52 per studio. Compared with A, both candidates left player earned/paid units, settled cash, final cash and Fans exactly unchanged at this fixed horizon. Residual Bugs sometimes fell, yet lost Core production outweighed that gain on this seed. The audit retains each title's four Core values, Scope and Bugs, sampled cash/dues, CPU and checkpoint size; two-rival CPU is not a population budget.

[B's fresh-process exact replay](sims/rival-qa-allocation-4417-B-replay-20261024-v1/world-run.json) passed 144 commands and exact checkpoint comparison. A/B/C source reports, logs, tapes, checkpoints and command records are retained in separate [A](sims/rival-qa-allocation-4417-A-20261024-v1/world-run.json), [B](sims/rival-qa-allocation-4417-B-20261024-v1/world-run.json), [C](sims/rival-qa-allocation-4417-C-20261024-v1/world-run.json) directories. No Studio-only Continue was run because neither candidate met the quality gate.

## Disposition

Do not queue B or C. A further Beta hand is not a sufficient Bug-control fix at a fixed thirteen-cycle plan. Exact QA choice, Feature/Core supply, frozen market-target observation, later Genre/Theme choices, entrant density, news, leaderboard and population CPU remain **OPEN**.

## Reproduction

```powershell
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/simulate.py run --variant docs/codex/threads/ai-competitors/simulators/rival-qa-allocation-20261024-v5 --config docs/codex/threads/ai-competitors/six-hand-phase-study-20261023-v1/smoke.json --output docs/codex/threads/ai-competitors/sims/rival-qa-allocation-smoke-20261024-v1 --godot 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe' --timeout 240
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' docs/codex/threads/ai-competitors/six-hand-phase-study-20261023-v1/run_world.py --bundle docs/codex/threads/ai-competitors/sims/rival-qa-allocation-smoke-20261024-v1 --output docs/codex/threads/ai-competitors/sims/rival-qa-allocation-4417-B-20261024-v1 --godot 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe' --source 56e14a858877ae5dd02ba6251a5d0da19b4a3e8793d20ac26c44a5b83d9a81fb --route action-fantasy --seed 4417 --candidate 1 --arm B
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' docs/codex/threads/ai-competitors/2026-10-24-qa-allocation-audit-v1.py
```

Use `--arm A --candidate 0` and `--arm C --candidate 1` with unique output directories for the other arms. Existing output directories are evidence, not rerun targets. The archived `world.command.json` files pin every actual argv and process status.
