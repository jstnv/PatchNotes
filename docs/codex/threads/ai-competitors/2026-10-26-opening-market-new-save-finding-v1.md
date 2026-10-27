# Fresh-save Market bootstrap — bounded headless finding, 2026-10-26

**Result: PASS for the declared cycle-zero read-only probe; proposed generated Market/WIP opening NOT RUN.** The [pre-run plan](2026-10-26-opening-market-new-save-study-plan-v1.md) asked whether current fresh saves already hold historical titles separately from an empty live market, and whether a historical chronological projection can be formed without changing gameplay. Both seeds pass. This does **not** implement the user's [generated-history and active-project design](2026-10-26-generated-incumbent-history-active-project-direction-v1.md), approve any cohort value, or establish 8.0 rival Reviews.

## Version and method

- Branch `main`, HEAD `087df09d653858b72c6e2dc344352237433dd3ac`, dirty shared worktree preserved. [Private variant v2](simulators/opening-market-new-save-20261026-v2/variant.json) retains original baseline `a9e0e2137813caa06147305557f4e44fc82c7268d43470c7a909c8ba45c77149`, candidate `2bcf855811a302a903e2216ae977bb3b6afe00e7d301639dc954e5338105da97`, and canonical-at-bundle `214c13b09240b5b27e581e75b4052b8c2a6028d355ba9cbf507f7c20de37498e`. Baseline drift is **true** because concurrent canonical source changed after variant capture; the retained bundle's exact variant source, not current canonical, governs these outcomes. Candidate delta is only private [`scripts/debug/opening_market_new_save_probe.gd`](simulators/opening-market-new-save-20261026-v2/project/scripts/debug/opening_market_new_save_probe.gd). Its gameplay `DevelopmentReplay.source_identity()` is `8729151ff35fd17df5dbd08fad8ca12ca1288b805208e43f8950bd924e28f3b7`.
- [Bundle02](sims/opening-market-new-save-20261026-v2-bundle02/run-report.json) was captured with `tools/simulate.py run --variant`; its one existing independent-Studio smoke case completed one legal release in 18 commands/cycle7. That case only verifies the frozen project can run; it is **not** the shared-world observation. The [thread-owned runner](run_opening_market_new_save_v1.py) then copied that bundle into fresh output projects/profiles and ran the private shared-world cycle-zero probe with **zero productive commands and zero releases** for each seed. Godot 4.7.1 console SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`; Python 3.12.14. Each import/probe limit was 240 seconds. No player saves, canonical code, network or computer UI were used.
- The probe used legal player recipes `opening-market-probe-4417` and `opening-market-probe-4418`, Action/no traits, then `RivalTrial.create_world`. It read both `MarketBrowserModel.query` and `MarketReleaseIndex.query`, sorted copied archive rows by year/Studio/ID, and compared whole player/world/market digests before and after. No history, score, resource, project or market fact was injected.

## Observed cycle-zero state

| Measure | Seed 4417 | Seed 4418 |
| --- | --- | --- |
| Browser live rows / validated live index rows | 0 / 0 | 0 / 0 |
| Monthly market snapshot | `market-0-neutral`, 0 facts | same |
| Rivals | 2, both `studio`, cycle0, 0 live releases | same |
| Rival opening cash / Fans | $5,850 / 20 each | same |
| Historical archive titles | 4, separate from live ledger | same |
| Probe failures | 0 | 0 |

Chronological read-only projection: Wayfinder's 1976 *The Lantern Road* 7.1; Arcade's 1977 *Circuit Clash* 7.2; Arcade's 1979 *Skyline Siege* 7.8; Wayfinder's 1979 *Atlas of Ash* 7.6. The same four authored rows appear under both seeds. They trend upward but are neither the requested earlier low Reviews nor late 8.x–9.x history. The current [Market browser source](../../../patch-notes/scripts/ui/market_browser.gd) excludes these archived rows, so the projection is evidence of available data, **not** a visible historical Market UI. No rival has an active January project.

[4417 first process](sims/opening-market-new-save-20261026-v2-seed4417-01/opening-market-run.json), [4418 process](sims/opening-market-new-save-20261026-v2-seed4418-01/opening-market-run.json), and [4417 independent repeat](sims/opening-market-new-save-20261026-v2-seed4417-02/opening-market-run.json) all passed. The repeat matches seed4417's world digest, player RNG, rival Studio/RNG values, historical projection and market snapshot exactly; only measured timing/output-file hash differs. [Readable 4417 state](sims/opening-market-new-save-20261026-v2-seed4417-01/opening-market.json). No script-error markers appeared in the three probe logs. The probe subprocesses took 2.70, 2.44 and 2.72 seconds, respectively; these small isolated measurements are not a population CPU limit or save-size result.

## Retained failures and limits

- [Variant v1 partial capture](simulators/opening-market-new-save-20261026-v1/) stopped with “Source changed while taking the snapshot”; it was not reused or deleted.
- [Bundle01 failed capture](sims/opening-market-new-save-20261026-v2-bundle01/run-report.json) stopped with “Canonical source changed while recording drift.” Retry used the **same** seeds, policy and limits but a fresh bundle02 folder. Both failures are source-capture concurrency, not a gameplay pass or a rejected legal hand.
- The probe did not run a pre-1980 hand tape, create a partly completed January project, change the Market UI, seed Review standards, activate archived sales, run a 1980 campaign, test Studio-only Continue, or measure new-save CPU at a larger rival population. The existing maintained trial activation verifier covers current active-world Continue separately; this probe does not extend that evidence to the proposed generator. Balance and 8.0 attainment remain OPEN.

## Exact commands

From repository root in PowerShell, using the bundled Python and installed Godot:

```powershell
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/simulator_variant.py create --id opening-market-new-save-20261026-v2 --owner ai-competitors --output docs/codex/threads/ai-competitors/simulators/opening-market-new-save-20261026-v2
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/simulate.py run --variant docs/codex/threads/ai-competitors/simulators/opening-market-new-save-20261026-v2 --config docs/codex/threads/ai-competitors/six-hand-phase-study-20261023-v1/smoke.json --output docs/codex/threads/ai-competitors/sims/opening-market-new-save-20261026-v2-bundle02 --godot 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --timeout 240
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' docs/codex/threads/ai-competitors/run_opening_market_new_save_v1.py --bundle docs/codex/threads/ai-competitors/sims/opening-market-new-save-20261026-v2-bundle02 --output docs/codex/threads/ai-competitors/sims/opening-market-new-save-20261026-v2-seed4417-01 --seed 4417 --godot 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' docs/codex/threads/ai-competitors/run_opening_market_new_save_v1.py --bundle docs/codex/threads/ai-competitors/sims/opening-market-new-save-20261026-v2-bundle02 --output docs/codex/threads/ai-competitors/sims/opening-market-new-save-20261026-v2-seed4418-01 --seed 4418 --godot 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' docs/codex/threads/ai-competitors/run_opening_market_new_save_v1.py --bundle docs/codex/threads/ai-competitors/sims/opening-market-new-save-20261026-v2-bundle02 --output docs/codex/threads/ai-competitors/sims/opening-market-new-save-20261026-v2-seed4417-02 --seed 4417 --godot 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
```

The original failed `v1` create and `bundle01` run used the same commands with those distinct output names. Reproducing these commands again requires **new** version/output folders, not overwriting retained evidence.

**Recommendation:** The opening market simulation is feasible and now has a source-pinned current baseline. Next prototype the historical Market query/presentation and a validated pre-start project prefix as **separate** variant changes. Only then compare 1980 legal releases, 8.0 attainment, player challenge, replay/Continue and CPU/save. Do not queue canonical gameplay or approve opening numbers from this probe.
