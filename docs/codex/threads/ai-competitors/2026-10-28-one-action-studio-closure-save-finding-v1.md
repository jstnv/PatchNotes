# One-Action historical closure Studio save — private finding, 2026-10-28

**Status: bounded DESIGN evidence. Player and rival Studio checkpoints PASS; world checkpoint and cold Continue remain OPEN.** The [pre-run plan](2026-10-28-one-action-studio-closure-save-plan-v1.md) fixed the v18 control, seeds, policy and two-cycle bound. Private v19 versions per-run start year, closure cycle and exact closed IDs, then reconstructs real pre-1980 Fanbase/sales through c72 and holds them fixed afterward. It does not rebase the rival's finance, Feature or release history. This is a private candidate, not adopted gameplay or an approved capital/standard value.

The [v19 variant](simulators/one-action-january-projection-20261028-v19/variant.json) descends from v18 and the original baseline identity `91e4244586bd3bf361a0cbfdb14dedcd4c4e09a14c47f1febabc9b0bba705d7b`. [Isolated bundle](sims/one-action-january-projection-bundle-20261028-v19/run-report.json): candidate identity `35aba3f2a5aa7c6eff0a535e134511fdc575c9460f795aaf016175ea44222a31`, gameplay source identity `0809a636801a47a9cc778a6a94eefdc9b3edae10f983ab92cdd0a0e8a1598e34`, canonical identity at capture `83412d1ade31cb6e88eafa7b8261ad7ed37fbf7bede8d60fa6bd7e443416ba85`, baseline drift `true`. Branch/HEAD `main` / `f3e0f2b5d35270c879327bc297b389748571feb4`, dirty shared worktree. Godot 4.7.1 console SHA-256 `35dab11e04ece16a2b93035e65204f4a944a3e00b020d43e54409193379d5eef`.

Both legal 1977–79 `full_pool` Action careers use the unchanged trial $25,000 founding receipt, paid 36 printed Scope and midpoint first-release standard. They stop c72 after 128 accepted actions, then a distinct c0 player and the original rival advance through c2/c74. Old sale records, earned units, settled cents, Fans and live Market exclusion remain exact. The private Studio schema records `calendar_start_year`, `historical_close_cycle` and closed IDs under a new content revision. In both cases, the player restores with year1980; the rival Studio checkpoint captures, validates and hydrates with year1980, exact post-c74 cash/Fans/RNG and the same closure IDs/cycle. Tampering with a closed ID or the close cycle rejects encoding. This is an in-process capture/hydrate result; the projected world was not cold-restored in a fresh process.

| Seed | c72 phase; old titles | c74 rival cash / Fans after two cycles | Player Studio restore | Rival Studio restore | World checkpoint |
| --- | --- | ---: | --- | --- | --- |
| 5607 | Beta; 3 | $43,408.54 / 762 | year1980 | exact closure, cash, Fans, RNG | rejects raw c74 vs c2 clock |
| 5613 | Design; 4 | $38,094.41 / 555 | year1980 | exact closure, cash, Fans, RNG | rejects raw c74 vs c2 clock |

[Audit JSON](sims/action-studio-closure-save-audit-20261028-v19.json), SHA-256 `4d2a86bc0c0aee8ef8bd3a49b1170fac06d3c00265dd21a4ee29782271e44035`, reports `studio_checkpoint_pass=true`, `world_checkpoint_pass=false`, no issues. [Audit script](analyze_action_studio_closure_save_v1.py), SHA-256 `5c4b501bf7e710824d46d84f13f4cabd2b427daa65e9e4f215f837fe60b6ddf1`, compiles. [5607](sims/one-action-january-5607-20261028-v19/prelude-run.json) and [5613](sims/one-action-january-5613-20261028-v19/prelude-run.json) reports retain successful/failed nested checkpoint results. The [source-matched 5607 fresh-process replay](sims/one-action-january-5607-replay-20261028-v19/replay.json) passes all 128 prelude steps and lands at c72.

**Next required private delta:** version the world offset and pre-1980 archive under an explicit projected-world schema. World validation must compare mapped physical dates and check each archive row against its owner Studio checkpoint while excluding archive IDs from live history/Market facts. The existing world checkpoint's `Rival clock or Contract unavailable` rejection is expected at c2/c74; no true cold Continue has passed. Then test restoring both Studios plus active development/hand, another month turn, legal project completion and post-start release mapping. Preserve old-world save behavior and reject altered archive/offset/source. Current-canonical rebaseline, eight Genres, CPU and player challenge remain OPEN. No adoption handoff or TODO queue.

## Exact commands

From repo root in PowerShell, with `$pnPython='C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'`, `$pnGodot='C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'`, `$stem='docs/codex/threads/ai-competitors'`:

```powershell
& $pnPython tools/simulator_variant.py create --id one-action-january-projection-20261028-v19 --owner ai-competitors --from-variant $stem/simulators/one-action-january-projection-20261028-v18 --output $stem/simulators/one-action-january-projection-20261028-v19
& $pnPython tools/simulate.py run --variant $stem/simulators/one-action-january-projection-20261028-v19 --config $stem/one-rival-prelude-capital-20261027-v3.json --output $stem/sims/one-action-january-projection-bundle-20261028-v19 --godot $pnGodot --timeout 240
& $pnPython $stem/run_one_action_january_projection_v1.py --bundle $stem/sims/one-action-january-projection-bundle-20261028-v19 --output $stem/sims/one-action-january-5607-20261028-v19 --seed 5607 --policy full_pool --standard midpoint --godot $pnGodot
& $pnPython $stem/run_one_action_january_projection_v1.py --bundle $stem/sims/one-action-january-projection-bundle-20261028-v19 --output $stem/sims/one-action-january-5613-20261028-v19 --seed 5613 --policy full_pool --standard midpoint --godot $pnGodot
& $pnPython $stem/run_one_action_january_projection_v1.py --bundle $stem/sims/one-action-january-projection-bundle-20261028-v19 --output $stem/sims/one-action-january-5607-replay-20261028-v19 --seed 5607 --policy full_pool --standard midpoint --godot $pnGodot --replay-tape $stem/sims/one-action-january-5607-20261028-v19/prelude.tape.json
& $pnPython -m py_compile $stem/analyze_action_studio_closure_save_v1.py
& $pnPython $stem/analyze_action_studio_closure_save_v1.py
```

Each process used a unique output folder and 240-second cap; legal prelude stopped at c72/340 attempted-command bound; projection stopped at c74 or first rejection. No canonical gameplay, TODO, player save, `.codex-godot-temp`, commit or push was changed.
