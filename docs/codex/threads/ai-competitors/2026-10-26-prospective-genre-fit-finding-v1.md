# Prospective rival Genre fit — two-seed headless finding, 2026-10-26

**Result: modest help, not an adoption candidate.** In two matched 24-cycle worlds, a private pre-Begin Genre choice improved seven of eight actual rival Reviews, worsened one, and gained **0.175 Review points on average**. All eight release dates stayed fixed. Neither arm produced a 5.6+ title. Six of eight titles in **each** arm released below required Scope under the current trial. This candidate does not satisfy the [locked complete Genre/Core rule](2026-10-26-rival-genre-core-selection-decision-v1.md) or full-Scope gate.

## Source and cases

[Predeclared plan](2026-10-26-prospective-genre-fit-test-plan-v1.md). `main` HEAD `087df09d653858b72c6e2dc344352237433dd3ac`; dirty shared worktree preserved. [A control](simulators/genre-fit-control-20261026-v1/variant.json) adds only a private read-only probe to current source. [B child](simulators/genre-fit-choice-20261026-v1/variant.json) changes only private `project/scripts/market/rival_trial.gd` beyond A. Both retain original canonical base identity `3ef01083f37f22317c9735c1f9c30543a779526b58d431ddd91669cc4363aace`; captured baseline drift was **false**. A/B candidate identities are `796215fcc809148a50c7e9858e9db7cdcad2762ef2d77f1fe091cef814ba8c96` / `d0388a77066e47791a44dd32931902bcc661849b32502777f987247b4f60d4a5`. Their frozen gameplay source identities are `8593779f9afa7deab4ca218fab64118864efe5d763ff088485f8d6ad43be7ab8` / `f372e4d41c3eb4f9d6edd9c4d9ac5ae0c21a64d08d530e294d77bd2cfd48d88e`. B's private policy SHA-256 changed from `dab541a08cd1483fc556f9e57d7590d7379254970659ed12ccad08851116a2c0` to `f795194f37668d541b083be82138afd0dc256b7419458828f7061cad33b3921b`.

B totals only the **owned, pre-Begin printed** Design/Alpha Core contributions, compares them with each candidate Genre's next-cycle Market standards using ordinary production arithmetic, and picks the highest prediction; an exact tie favors specialty. Theme, actual hand/phase/Review/Market rules stay unchanged. This OPEN proxy does **not** model jointly playable hands, cost, synergy, full-Scope viability or a no-fit threshold. It is a single-variable direction test, not the approved implementation. Godot 4.7.1 console SHA-256: `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`.

The [paired analysis](sims/genre-fit-paired-analysis-20261026-v1.json) verifies exact A/B cycle-zero checkpoint equality within seeds4417 and4423, including rival RNG, cash, Fans, phase and Market. Different seeds have different rival RNG. No old checkpoint crossed the rule revisions.

| Seed | Title | Cycle A/B | A Genre/Review | B Genre/Review | Delta | Scope A/B |
|---|---|---:|---|---|---:|---:|
|4417|Arcade 1|9/9|Action 4.7|Puzzle 5.0|+0.3|30/30|
|4417|Wayfinder 1|10/10|Adventure 3.6|Puzzle 3.7|+0.1|27/30|
|4417|Arcade 2|19/19|Action 5.0|Puzzle 5.2|+0.2|31/30|
|4417|Wayfinder 2|19/19|Adventure 3.4|Strategy 3.5|+0.1|26/30|
|4423|Arcade 1|9/9|Action 4.3|Puzzle 4.6|+0.3|28/30|
|4423|Wayfinder 1|11/11|Adventure 4.0|Puzzle 3.9|−0.1|27/30|
|4423|Arcade 2|18/18|Action 4.4|Puzzle 4.6|+0.2|29/30|
|4423|Wayfinder 2|21/21|Adventure 4.9|Strategy 5.2|+0.3|27/30|

All matched rows kept the same Scope and residual Bugs. Some actual Core vectors changed because the existing hand selector reacted to the new Genre; the analysis JSON records every four-Core vector and frozen standard. A and B each published four titles per seed by cycle24, with no block. Direct world process times were A/B 3.329/3.360 seconds (4417) and 3.828/3.828 seconds (4423), excluding import and insufficient for a population CPU limit.

## Verification and limits

[A](sims/genre-fit-A-smoke-20261026-v1/run-report.json) and [B](sims/genre-fit-B-smoke-20261026-v1/run-report.json) isolated smokes each passed18 legal player commands/one release. [A replay](sims/genre-fit-A-smoke-replay-20261026-v1/replay-report.json) and [B replay](sims/genre-fit-B-smoke-replay-20261026-v1/replay-report.json) matched all18 steps and final state in new processes. Actual two-rival worlds [A4417](sims/genre-fit-A-4417-20261026-v1/prestart-shadow.json), [B4417](sims/genre-fit-B-4417-20261026-v1/prestart-shadow.json), [A4423](sims/genre-fit-A-4423-20261026-v1/prestart-shadow.json), [B4423](sims/genre-fit-B-4423-20261026-v1/prestart-shadow.json) each completed24 cycles with zero failures, blocks, timeouts or raw-log `SCRIPT ERROR`/`ERROR:`. The player fixture replay does not exercise rival choice; the fresh world processes do. The 240-second process limit and12 zero-cycle rival-step bound were retained.

The world probe advances a clock-only player, so player Review/sales/cash pressure was **NOT RUN**. Complete end-world rival cash/Fans, Studio-only Continue, low-cash/no-fit states, raised Genre targets, richer pools, entrant capacity and stable CPU cost are also **NOT RUN**. The current under-Scope releases are evidence against adopting this narrow policy as the complete rule, not an excuse to waive the hard Scope lock.

**Disposition:** keep the qualitative Genre/Core direction; reject this aggregate printed-Core selector as the final method. Test a jointly legal paid Feature/hand plan and explicit no-fit deferral alongside full-Scope supply before any implementation handoff. No fit threshold, Store retargeting, population value or gameplay change is approved.

## Exact executed commands

The [plan](2026-10-26-prospective-genre-fit-test-plan-v1.md) defines cases and bounds; every smoke/world bundle contains its literal `*.command.json` and log. From repo root:

```powershell
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/simulator_variant.py create --id genre-fit-control-20261026-v1 --owner ai-competitors --output docs/codex/threads/ai-competitors/simulators/genre-fit-control-20261026-v1
Copy-Item -LiteralPath 'docs/codex/threads/ai-competitors/simulators/whole-supply-gates-20261026-v3/project/scripts/debug/opening_prestart_shadow_probe.gd' -Destination 'docs/codex/threads/ai-competitors/simulators/genre-fit-control-20261026-v1/project/scripts/debug/opening_prestart_shadow_probe.gd'
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/simulator_variant.py create --id genre-fit-choice-20261026-v1 --owner ai-competitors --from-variant docs/codex/threads/ai-competitors/simulators/genre-fit-control-20261026-v1 --output docs/codex/threads/ai-competitors/simulators/genre-fit-choice-20261026-v1
```

Then `tools/simulate.py run --variant ... --config docs/codex/threads/ai-competitors/six-hand-phase-study-20261023-v1/smoke.json --output ... --godot <above> --timeout 240` once per arm; `run_low_review_cause_probe_v2.py --bundle <arm smoke> --output <arm-seed folder> --seed <4417 or 4423> --godot <above>` four times; `tools/simulate.py replay --bundle <arm smoke> --case foundation-legal-action-4417 --output <arm replay> --godot <above> --timeout 240` once per arm. Exact resolved argument arrays and output paths are in the linked bundles. The analysis was:

```powershell
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' docs/codex/threads/ai-competitors/analyze_prospective_genre_fit_v1.py --a4417 docs/codex/threads/ai-competitors/sims/genre-fit-A-4417-20261026-v1 --b4417 docs/codex/threads/ai-competitors/sims/genre-fit-B-4417-20261026-v1 --a4423 docs/codex/threads/ai-competitors/sims/genre-fit-A-4423-20261026-v1 --b4423 docs/codex/threads/ai-competitors/sims/genre-fit-B-4423-20261026-v1 --output docs/codex/threads/ai-competitors/sims/genre-fit-paired-analysis-20261026-v1.json
```
