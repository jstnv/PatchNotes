# Live rival Reviews still fail the challenge goal — 2026-10-30

## Result and status

**Reproduced for the former 14-Scope trial; the newly implemented 27-Scope fresh cohort improves but remains weak.** The user's screenshot shows several live rival Reviews near 1.0 while a player title is 3.2. The save's origin/seed is unknown, so it is an observation, not a replay. Old saves retain the 14-Scope rivals they were created with. A concurrent, locally implemented fresh-rival update now grants 27 active printed Scope, but its two retained 20-cycle seeds still release first games at **5.0/2.2** and **3.5/3.3**. No first game reaches 6.0. This is not yet a strong market opponent.

**Mechanism:** the old trial had 14 eligible Scope against required 30, yielding at most `10 × 14/30 + 0.5 = 5.2` Review under the most favorable possible Core/Bug/variance factors. Its stock policy never shops. The new grant raises owned future Scope to 27, but that is still below the required 30 and actual releases play only 24–27. Core production remains the main quality limit after the grant: all five observed 27-Scope releases remain below 6.0 even in a formula-only comparison that gives their unchanged four Core a completed 30 Scope and zero Bugs. The current policy also has two fixed Beta hands and no Store acquisition. A full-Scope launch gate alone would block these 27-Scope rivals; it must be paired with enough legal Feature supply.

## Source identities and bounded checks

The [pre-run recheck plan](2026-10-30-low-live-review-recheck-plan-v1.md) froze the then-current two-rival source in thread-owned [`low-live-review-recheck-20261030-v1`](simulators/low-live-review-recheck-20261030-v1/variant.json), with original baseline `05eb34e6701f42a8f7a5645dddb47706b146a3f9bfba6638dfddef15f4932dc6`, parent identity `4c52b17c54292876e22ab943afb6c64dab328451971e21333b43ffd24334b779`, candidate identity `8dafb75fd45d90ea1c0872d0d171381bcdf1b63f4ddfc787a9075d9ff1aa6192`, and executed gameplay identity `33f44f0c61446daf6f464bee3c04f689a437d4b08704d2c3dbc65874778a1f27`. Branch `main`, HEAD `3a61522f18db7a2bae892cb8c5be1fee68cd4100`, dirty shared worktree preserved. Godot 4.7.1 SHA-256 `323f9c4cc5db674e98815cdd8e69da007d5efc779abedc8c0e42883b7fdea12a`.

The [source freeze](sims/low-live-review-recheck-freeze-20261030-v1/run-report.json) retained two intentionally **INCOMPLETE/command-bound** one-command cases; no player Review was produced. The [first](sims/low-live-review-recheck-probe-20261030-v1/opening-rival-reviews-run.json) and [fresh repeat](sims/low-live-review-recheck-probe-repeat-20261030-v1/opening-rival-reviews-run.json) isolated probes passed, with no script errors and matching result SHA-256 `49904ec2d6eb41f3214c706f7ea2ac6bfbff07f5290ca687753d5afb899fb76b`. Both seeds began with two rivals, 11 future Features and **14 printed Scope each**; by cycle 18 they produced four live rival releases per seed, all 0.6–1.9, with matching owner/world ledgers. [Raw per-release Scope/Core/Bug/Review data](sims/low-live-review-recheck-probe-20261030-v1/opening-rival-reviews.json) is retained. The private variant changed only its diagnostic script.

While that frozen probe ran, another implementation added `rival_starting_pool.gd` and updated fresh `RivalTrial` creation. The variant runner correctly reported canonical baseline drift; **the 14-Scope probe does not describe new saves after that update**. The new locally implemented source has mechanics identity `c4436b020d6580b0ddc79f40e18f085e43c742965e2bcfdce75104fe386255d1`, documented in the [27-Scope implementation decision](2026-10-30-live-rival-27-scope-decision-v1.md) and [log](../../logs/2026-10-30-live-rival-27-scope-v1.md). Its independent [seed 4417](sims/live-rival-27-final-4417-20261030-v1/probe.json) and [seed 4418](sims/live-rival-27-final-4418-20261030-v1/probe.json) headless checks each passed 100 assertions through cycle 20. They used legal fresh player Studio states, stock rival policy, no player Review and did not change rating math.

## Current 27-Scope release factors

The [read-only factor audit](sims/live-rival-27-review-factors-20261030-v1.json) decodes the frozen release metadata in those two 20-cycle checks, recomputes each actual Review with the source formula and uniquely matches its legal variance modifier. Its `zero_bugs_only`, `full_scope_only` and `full_scope_zero_bugs` columns are **formula-only diagnostics** with the same Core and variance, not legal release routes or approved boosts. All five actual results match. The audit command is below.

| Seed / rival / cycle | Actual | Played Scope | Bugs | Core production before Scope/Bugs | Same-Core full Scope + zero Bugs |
| --- | ---: | ---: | ---: | ---: | ---: |
| 4417 Wayfinder c9 | 2.2 | 24/30 | 4 | 3.96 | 3.5 |
| 4417 Arcade c12 | 5.0 | 27/30 | 1 | 5.78 | 5.8 |
| 4418 Wayfinder c10 | 3.3 | 25/30 | 7 | 4.72 | 5.0 |
| 4418 Arcade c11 | 3.5 | 26/30 | 7 | 5.96 | 5.5 |
| 4418 Arcade c19 | 3.4 | 23/30 | 1 | 4.31 | 4.6 |

Wayfinder c9 has Core `[28,10,24,15]` against Adventure standards `[33,26,20,53]`; Sound and especially Design lag. Arcade c12 has `[30,15,35,26]` against Action `[40,26,40,26]`. The same-Core clean comparisons show that fixing only late QA or allowing 30 Scope cannot by itself make these five releases 6.x or 7.x. Changing current market coefficients or lowering player capability would not address their actual production gap.

## Exact commands and boundaries

From repo root, `$py='C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'`, `$godot='C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe'`, `$t='docs/codex/threads/ai-competitors'`:

```powershell
& $py tools/simulator_variant.py create --id low-live-review-recheck-v1 --owner ai-competitors --from-variant "$t/simulators/cycle-zero-market-visibility-20261030-v1" --output "$t/simulators/low-live-review-recheck-20261030-v1"
& $py tools/simulate.py run --variant "$t/simulators/low-live-review-recheck-20261030-v1" --config "$t/2026-10-30-cycle-zero-market-visibility-freeze-v1.json" --output "$t/sims/low-live-review-recheck-freeze-20261030-v1" --timeout 240 --godot $godot
& $py "$t/run_cycle_zero_market_visibility_v1.py" --bundle "$t/sims/low-live-review-recheck-freeze-20261030-v1" --output "$t/sims/low-live-review-recheck-probe-20261030-v1" --godot $godot
& $py "$t/run_cycle_zero_market_visibility_v1.py" --bundle "$t/sims/low-live-review-recheck-freeze-20261030-v1" --output "$t/sims/low-live-review-recheck-probe-repeat-20261030-v1" --godot $godot
& $py "$t/analyze_live_27_review_factors_v1.py" --input "$t/sims/live-rival-27-final-4417-20261030-v1/probe.json" --input "$t/sims/live-rival-27-final-4418-20261030-v1/probe.json" --output "$t/sims/live-rival-27-review-factors-20261030-v1.json"
```

## Recommendation, status and limits

Keep the **LOCKED** full-Scope/no-underscored-launch rule and target-aware Feature/QA direction, but make it feasible first: rivals need at least 30 eligible printed Scope, preferably the selected January **35+** target through legal acquisition; then a frozen-market-standard/Core-shortfall hand planner and funded QA before Marketing. Measure actual played Core, Scope, Bugs, cash, release density and elapsed cycles together. The separate [current-source eight-rival founder candidate](2026-10-30-current-founder-candidate-findings-v1.md) demonstrates legal 35-Scope supply but remains **HELD**: its two seeds produce 8/0 historical 8+ titles, and funding/performance/migration gates are OPEN. Its numerical policies are not adopted by this finding.

The user subsequently clarified that the screenshot came from a **new save in the Godot project after the update**, not an older Continue save, and that they fully relaunched the game. A [fresh-source identity screen](2026-10-30-fresh-27-low-review-reproduction-finding-v1.md) confirmed 27 Scope in five new-source cases and did not reproduce the screenshot's near-1.0 Reviews. A later [read-only inspection of the matching Studio save](2026-10-30-pictured-save-source-finding-v1.md) resolved the discrepancy: that save's rival world carries predecessor source `33f44f` and was written before the 27-Scope code files. Relaunching later correctly preserves its old roster. No player Review was simulated. The 14-Scope and 27-Scope cases have different source/starting states, so equal seed numbers alone do not justify a direct paired causal estimate. The 27-Scope evidence rejects a claim that the grant already delivers a challenging market; it does not select final balance values. Historical archive display is a separate queued UI handoff. No canonical gameplay, TODO, commit, push or packaged build was changed by this design finding.
