# Low rival Review cause — four-seed headless finding, 2026-10-26

**Finding: the current trial's weak Core production is the dominant opening quality limit in this bounded sample.** The user's 2.4 case is not cured by Scope completion or Bug removal alone. All eight first live releases in four declared seeds scored below 5.6; **seven of eight would still score below 5.6 with the same four Core, full Scope and zero Bugs**, retaining each actual variance. This last calculation is a formula-only diagnostic, not a legal hand route or promised maximum.

## Source and method

- [Pre-run plan and documented CLI correction](2026-10-26-low-review-cause-plan-v1.md). `main` HEAD `087df09d653858b72c6e2dc344352237433dd3ac`, dirty shared checkout preserved. Original current-source [census](2026-10-26-current-source-opening-census-finding-v1.md) covers seeds4417/4418. A [derived private diagnostic variant](simulators/low-review-cause-census-20261026-v1/variant.json) retained canonical base identity `d4834025c6e39d79e6f9e77261c6e178e57ae0c9a4c0c312857cddf2231b2338`, parent candidate identity `3b33281b6dab1cf0840310cdc5b81d0ff06a4a7f6e84785778ea5b43e5101b93`, and new candidate identity `de7ee58ca5f22ef63f8f3b4804adc534747f4c0b1ee0348ae7809e978047deb3`. The only private-project delta is the probe script's seed allowlist; gameplay source identity is the same `a4d9fc318694ef143ea9d59147ae8c5e33a823d31d05a68b35d74203025b51c5` in all four outputs. The new capture reported baseline drift **false at capture**. Current shared source may continue to change.
- The [isolated smoke](sims/low-review-cause-census-20261026-v1-bundle01/run-report.json) passed 18 legal commands/one release; [fresh-process replay](sims/low-review-cause-census-20261026-v1-replay01/replay-report.json) passed all 18 exact steps. The two added world probes [4423](sims/low-review-cause-20261026-seed4423-v1/prestart-shadow.json) and [4431](sims/low-review-cause-20261026-seed4431-v1/prestart-shadow.json) each completed 24 actual shared cycles/four releases with zero reported blocked turns, failures or timeouts. The earlier [4417](sims/opening-current-source-census-20261026-v1-seed4417-01/prestart-shadow.json) and [4418](sims/opening-current-source-census-20261026-v1-seed4418-01/prestart-shadow.json) cases use the same gameplay source and fixed player recipe. Godot 4.7.1 console SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`.
- The [read-only factor audit](sims/low-review-cause-analysis-20261026-v1.json) recalculates each actual Review using the current source's production rating × Scope completion × Bug factor plus one of five legal variance modifiers; all 16 release rows matched. It then recomputes the same-Core full-Scope, zero-Bug and combined results. These arms do **not** alter a saved state, produce a legal release or establish a reachable Review ceiling. Different seeds produce different legal initial RNG/states; no same-seed cross-revision numerical pairing is claimed.

## Actual first live releases

| Seed | Rival | Cycle | Actual Review | Production before Scope/Bugs | Played Scope | Bugs | Same-Core full Scope and zero Bugs |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 4417 | Arcade | 9 | 4.7 | 5.13 | 30/30 | 1 | 4.9 |
| 4417 | Wayfinder | 10 | 3.5 | 5.01 | 27/30 | 5 | 4.8 |
| 4418 | Wayfinder | 7 | **2.4** | **3.36** | 23/30 | 2 | **3.4** |
| 4418 | Arcade | 10 | 4.0 | 5.60 | 29/30 | 9 | 5.9 |
| 4423 | Arcade | 9 | 4.2 | 4.82 | 28/30 | 2 | 4.8 |
| 4423 | Wayfinder | 11 | 3.8 | 5.53 | 27/30 | 4 | 5.0 |
| 4431 | Arcade | 9 | 4.0 | 5.30 | 28/30 | 4 | 5.0 |
| 4431 | Wayfinder | 10 | 3.5 | 5.09 | 26/30 | 6 | 5.1 |

The **2.4** title had Core `[20,10,13,17]` versus Adventure targets `[33,26,20,53]`, with zero variance. Its unrounded calculation is approximately `3.361 × 23/30 × 28/30 = 2.405`, rounded to 2.4. With identical Core and variance, `3.361` is the full-Scope/zero-Bug production-limited value, rounded to **3.4**. The severe Design shortfall is one example of a capability problem, not evidence that QA is irrelevant: Arcade's seed4418 title carried nine Bugs and could rise from 4.0 to 5.9 under the same-Core idealization.

All **16** actual releases through cycle24 were below5.6, with the maximum at5.0. Fifteen of sixteen same-Core/full-Scope/zero-Bug diagnostic values remained below5.6. Thus simply extending Beta or enforcing full Scope on today's owned pools is insufficient in this sample. The current code selects Design/Alpha hands against **base Genre** targets, while actual Review uses the project's frozen Market standards; that mismatch will matter once market pressure raises targets. Current Wayfinder owns only27 printed Scope against required30, so a full-Scope gate alone would block its first game. Earlier longer legal plans did produce some 6.x/7.x Reviews but reduced rival title count and eased player sales in their matched worlds; they do not validate a fixed-hand solution for this source.

## Disposition and limits

Use the [proposed quality planner](2026-10-26-rival-quality-planner-design-v1.md) as the next candidate architecture: legal opening Core/Scope capability, target-aware finite hand planning, the already LOCKED full-Scope rule, then funded QA before Marketing. Test those stages separately and retain same-calendar publication/player challenge gates. A 5.6–6.2 ordinary first-live aim is **not** a Review floor; no Core award, coefficient change or starting dollar/Card value is approved here. This diagnostic did not test candidate gameplay, Store shopping, 1979 WIP, cold Continue, graphical UI, larger populations or CPU limits. **No adoption handoff or TODO queue yet.**

The initial `run_prestart_shadow_probe_v1.py --seed 4423` attempt exited with `invalid choice` during CLI parsing before a Godot run or output folder. Its seed restriction was documented in the plan; the original runner and variant were preserved, and the derived diagnostic-only version was used. No other failure was omitted.

Rejected command (no output directory was created):

```powershell
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' docs/codex/threads/ai-competitors/run_prestart_shadow_probe_v1.py --bundle docs/codex/threads/ai-competitors/sims/opening-current-source-census-20261026-v1-bundle01 --output docs/codex/threads/ai-competitors/sims/low-review-cause-20261026-seed4423-v1 --seed 4423 --godot 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
```

## Exact commands

```powershell
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/simulator_variant.py create --id low-review-cause-census-20261026-v1 --owner ai-competitors --from-variant docs/codex/threads/ai-competitors/simulators/opening-current-source-census-20261026-v1 --output docs/codex/threads/ai-competitors/simulators/low-review-cause-census-20261026-v1
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/simulate.py run --variant docs/codex/threads/ai-competitors/simulators/low-review-cause-census-20261026-v1 --config docs/codex/threads/ai-competitors/six-hand-phase-study-20261023-v1/smoke.json --output docs/codex/threads/ai-competitors/sims/low-review-cause-census-20261026-v1-bundle01 --godot 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --timeout 240
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' docs/codex/threads/ai-competitors/run_low_review_cause_probe_v2.py --bundle docs/codex/threads/ai-competitors/sims/low-review-cause-census-20261026-v1-bundle01 --output docs/codex/threads/ai-competitors/sims/low-review-cause-20261026-seed4423-v1 --seed 4423 --godot 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' docs/codex/threads/ai-competitors/run_low_review_cause_probe_v2.py --bundle docs/codex/threads/ai-competitors/sims/low-review-cause-census-20261026-v1-bundle01 --output docs/codex/threads/ai-competitors/sims/low-review-cause-20261026-seed4431-v1 --seed 4431 --godot 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' docs/codex/threads/ai-competitors/analyze_low_review_cause_v1.py --inputs docs/codex/threads/ai-competitors/sims/opening-current-source-census-20261026-v1-seed4417-01/prestart-shadow.json docs/codex/threads/ai-competitors/sims/opening-current-source-census-20261026-v1-seed4418-01/prestart-shadow.json docs/codex/threads/ai-competitors/sims/low-review-cause-20261026-seed4423-v1/prestart-shadow.json docs/codex/threads/ai-competitors/sims/low-review-cause-20261026-seed4431-v1/prestart-shadow.json --output docs/codex/threads/ai-competitors/sims/low-review-cause-analysis-20261026-v1.json
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' tools/simulate.py replay --bundle docs/codex/threads/ai-competitors/sims/low-review-cause-census-20261026-v1-bundle01 --case foundation-legal-action-4417 --output docs/codex/threads/ai-competitors/sims/low-review-cause-census-20261026-v1-replay01 --godot 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --timeout 240
```
