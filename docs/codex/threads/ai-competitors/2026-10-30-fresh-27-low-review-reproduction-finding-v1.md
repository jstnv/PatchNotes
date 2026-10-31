# Fresh 27-Scope cohort does not reproduce the pictured 1.0 Reviews — 2026-10-30

## Result

The user described the pictured save as newly created after the 27-Scope update in the current Godot project. A bounded current-source headless screen of five legal new Studio recipes found **27 future-eligible printed Scope for both rivals in every case**. Their cycle-18 live Reviews ranged **2.2–5.0**, with two or three rival releases per case. Neither the near-1.0 pictured Reviews nor four rival releases by cycle16 appeared. This did not disprove the screenshot; its saved Studio ID, RNG, player release timing and source were not known during this screen. The later [save inspection](2026-10-30-pictured-save-source-finding-v1.md) establishes that this particular Studio's checkpoint was written before the 27-Scope code files.

The current code's `RivalTrial.create_world` calls `RivalStartingPool.apply_to_new_rival` for each fresh Studio and rejects world creation if the 27-Scope grant fails. The user confirms they fully relaunched the Godot game, and the later read-only save inspection found the predecessor world preserved from a checkpoint written before the roster update. This study itself did not touch user saves.

## Plan, identities and exact commands

The [pre-run plan](2026-10-30-fresh-27-low-review-reproduction-plan-v1.md) fixed five recipe identity/seed cases and 18 legal calendar boundaries, without a player project. Thread-owned private [variant](simulators/fresh-27-low-review-reproduction-20261030-v1/variant.json) copied the current project at original full identity `fa1cc2b8e2376331d98c45c52a8d225ef4d49f87af987b882c520bce6ad9b71e`, candidate full identity `1346af094d1cdf76ad02b521e7d203dab0db166323afc581ff081a3528cde396`, executed gameplay mechanics `c4436b020d6580b0ddc79f40e18f085e43c742965e2bcfdce75104fe386255d1`; no canonical baseline drift at capture. Only a private diagnostic script was added. Branch `main`, HEAD `3a61522f18db7a2bae892cb8c5be1fee68cd4100`, dirty shared changes preserved. Godot4.7.1 SHA-256 `323f9c4cc5db674e98815cdd8e69da007d5efc779abedc8c0e42883b7fdea12a`.

From repo root, `$py='C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'`, `$godot='C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe'`, `$t='docs/codex/threads/ai-competitors'`:

```powershell
& $py tools/simulator_variant.py create --id fresh-27-low-review-reproduction-v1 --owner ai-competitors --output "$t/simulators/fresh-27-low-review-reproduction-20261030-v1"
Copy-Item -LiteralPath "$t/simulators/low-live-review-recheck-20261030-v1/project/scripts/debug/opening_rival_review_census_probe.gd" -Destination "$t/simulators/fresh-27-low-review-reproduction-20261030-v1/project/scripts/debug/opening_rival_review_census_probe.gd"
& $py tools/simulate.py run --variant "$t/simulators/fresh-27-low-review-reproduction-20261030-v1" --config "$t/2026-10-30-cycle-zero-market-visibility-freeze-v1.json" --output "$t/sims/fresh-27-low-review-freeze-20261030-v1" --timeout 240 --godot $godot
& $py "$t/run_cycle_zero_market_visibility_v1.py" --bundle "$t/sims/fresh-27-low-review-freeze-20261030-v1" --output "$t/sims/fresh-27-low-review-probe-20261030-v1" --godot $godot
& $py "$t/run_cycle_zero_market_visibility_v1.py" --bundle "$t/sims/fresh-27-low-review-freeze-20261030-v1" --output "$t/sims/fresh-27-low-review-probe-repeat-20261030-v1" --godot $godot
```

The [freeze](sims/fresh-27-low-review-freeze-20261030-v1/run-report.json) intentionally ended **INCOMPLETE/command-bound** after one command for each of two source-capture cases. Both isolated [first](sims/fresh-27-low-review-probe-20261030-v1/opening-rival-reviews-run.json) and [repeat](sims/fresh-27-low-review-probe-repeat-20261030-v1/opening-rival-reviews-run.json) probes PASS/exit0 with no script errors and identical result SHA-256 `a5b1e5cef08c29bb1f78c5bfbdcee5b24d70bbf280e33559b3c607818a0f6537`. All five cases pass c0 world/checkpoint validity, exact27-Scope supply, legal18-boundary advancement, world/owner release agreement and final checkpoint. [Raw results](sims/fresh-27-low-review-probe-20261030-v1/opening-rival-reviews.json) include per-release Core/standards, played Scope, Bugs, production, phase/action/cash trace and Market fact counts.

| Player Studio ID / seed | Rival live Reviews through c18 | Release cycles | Opening rival Scope |
| --- | --- | --- | --- |
| `a` /4417 | Arcade3.9, Wayfinder4.2 | c11,c12 | 27/27 |
| `a` /5607 | Arcade3.9, Wayfinder4.2 | c11,c12 | 27/27 |
| `pool-player-4417` /4417 | Wayfinder2.2, Arcade5.0 | c9,c12 | 27/27 |
| `pool-player-4418` /4418 | Wayfinder3.3, Arcade3.5 | c10,c11 | 27/27 |
| `opening-review-player-4417` /4417 | Arcade3.1, Wayfinder3.5, Arcade3.2 | c9,c10,c17 | 27/27 |

The duplicate `a` output under different player RNG seeds indicates that, with the player only advancing the calendar, this rival path is driven by its Studio identity and own seeded world state. It is not evidence that all player campaigns with that name behave the same after player releases alter Market facts.

## Disposition and later source resolution

The [factor audit](2026-10-30-live-rival-review-gap-finding-v1.md) still shows the 27-Scope cohort is too weak for the intended challenge. A later [read-only inspection of the pictured Studio](2026-10-30-pictured-save-source-finding-v1.md) **resolved the screenshot mismatch**: its saved rival world is the `33f44f` predecessor and was written before the new pool code. The user's complete Godot relaunch does not retroactively regrant that saved world. Keep the legal35+ supply, Core targeting and QA design study separate from this provenance check. No canonical source, player save, TODO, commit or push changed here.
