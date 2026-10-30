# One Action January world checkpoint and cold Continue — 2026-10-29

**Finding: PASS for two bounded private cases; DESIGN evidence only.** The one-rival January projection now survives a fresh-process world restore and one more committed player month while retaining the 1977–79 archive, active rival project and exact player/rival encoded states. This is a private simulator contract, not an adopted save format or a claim that a rival can finish a 1980 game from this save.

## Question, setup and limits

The [pre-run plan](2026-10-28-one-action-world-checkpoint-plan-v1.md) fixed two legal Action careers, seeds 5607 and 5613, `full_pool`, midpoint first-release standard, trial $25,000 founding receipt, maximum 340 commands and 240 seconds per process. The legal 1977–79 prefix stops at rival c72. Player c0 maps to rival c72 through an explicit +72 offset; the test advances both to player c2/rival c74, saves there, then continues to c3/c75. Seed 5607 has three historical releases and a Beta project; seed 5613 has four and a Design project. The separate cold-process extension reuses these exact cases, source identity, fixture and one-cycle stop. It adds no seed or budget search.

Variant [v22](simulators/one-action-january-projection-20261029-v22/variant.json) descends from v21→v20→v19, preserving its original canonical baseline. Only `project/` was changed: v20 introduced a typed version-2 world payload with per-studio offset and owner-verified historical archive; v21 converted native archive IDs/Genre/Theme to `StringName` before encoding; v22 adds full-state fixture capture and cold restore probe. The retained [v22 bundle](sims/one-action-january-projection-bundle-20261029-v22/run-report.json) reports candidate source identity `87ac0166b451828fd0f4e4caacac5977bae6ee4c1992e9b0266ac967aa740c61`, original baseline identity `91e4244586bd3bf361a0cbfdb14dedcd4c4e09a14c47f1febabc9b0bba705d7b`, branch `main` at `f3e0f2b5d35270c879327bc297b389748571feb4`, and baseline drift from concurrent canonical work. Godot 4.7.1 executable SHA-256: `323f9c4cc5db674e98815cdd8e69da007d5efc779abedc8c0e42883b7fdea12a`. No canonical gameplay, TODO or player save was edited.

## Exact commands

From repository root in PowerShell, with `$py='C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'`, `$godot='C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe'`, `$t='docs/codex/threads/ai-competitors'`:

```powershell
& $py tools/simulate.py run --variant "$t/simulators/one-action-january-projection-20261029-v22" --config "$t/sims/one-action-january-projection-bundle-20261029-v21/inputs/experiment.json" --output "$t/sims/one-action-january-projection-bundle-20261029-v22" --timeout 240 --godot $godot
foreach ($seed in @('5607','5613')) {
  & $py "$t/run_one_action_january_projection_v1.py" --bundle "$t/sims/one-action-january-projection-bundle-20261029-v22" --output "$t/sims/one-action-january-$seed-20261029-v22" --seed $seed --policy full_pool --standard midpoint --godot $godot
  & $py "$t/run_one_action_cold_world_v1.py" --bundle "$t/sims/one-action-january-projection-bundle-20261029-v22" --fixture "$t/sims/one-action-january-$seed-20261029-v22/prelude-world-fixture.json" --output "$t/sims/one-action-january-$seed-cold-20261029-v22" --godot $godot
}
& $py "$t/run_one_action_january_projection_v1.py" --bundle "$t/sims/one-action-january-projection-bundle-20261029-v22" --output "$t/sims/one-action-january-5607-replay-20261029-v22" --seed 5607 --policy full_pool --standard midpoint --replay-tape "$t/sims/one-action-january-5607-20261029-v22/prelude.tape.json" --godot $godot
```

The first attempted v22 smoke using bare `python` did not start because the WindowsApps alias was inaccessible; no variant output was produced from that attempt. The explicit bundled Python command above passed. An older attempted console Godot path was missing; the retained v20 failure and v20b source-drift result are described in the preceding session notes. v20c then exposed the native archive type error; [its retained run](sims/one-action-january-5607-20261028-v20c/prelude.json) is the rejected control. v21 fixed that type and passed in-process world restore; v22 adds the cold check.

## Results

| Seed | c72 project | Pre-1980 archive Reviews | Player/rival save | c3/c75 uninterrupted = restored | Fresh-process Continue |
|---|---|---|---|---|---|
| 5607 | Beta | 6.9, 9.2, 9.7 | world capture/validation/restore PASS | exact full encoded state PASS | PASS; actual/expected digest `1a5013451c0ffe83d62e6dc1f2eb591e21b00735eeb9cfff68f11ec8fd9c7749` |
| 5613 | Design | 6.8, 8.1, 7.1, 7.9 | world capture/validation/restore PASS | exact full encoded state PASS | PASS; actual/expected digest `15f0491022b902bef6c8964c3600440f257e10519c5878155b56c86f1f526951` |

Evidence: [5607 prelude](sims/one-action-january-5607-20261029-v22/prelude.json), [5607 cold run](sims/one-action-january-5607-cold-20261029-v22/cold-world-run.json), [5613 prelude](sims/one-action-january-5613-20261029-v22/prelude.json), [5613 cold run](sims/one-action-january-5613-cold-20261029-v22/cold-world-run.json), and [5607 source-matched fresh replay](sims/one-action-january-5607-replay-20261029-v22/prelude-run.json) (`replay_ok=true`). The saved fixtures and command/log files are retained in their output folders.

Both old archives have zero entries in the live Market index at c2; their old release records, earned sales units/cents and Fan totals have zero post-start delta. The world codec rejects changed offset, removed archive title and changed Core in both cases. The Studio codec rejects altered closure ID/cycle. Active-project target provenance and owner records are validated before restore. The c3 comparison includes both encoded Studio payloads, world offset/archive and RNG, not just cash and cycle.

## Recommendation and remaining gates

Keep the typed offset plus frozen owner-verified archive as the **TRIAL private save contract**. The user's frozen-history and legal pre-start-work direction remains **LOCKED**; the +72 offset, $25,000 receipt, particular titles/scores and version-2 schema are candidate mechanics, not approved gameplay. **OPEN:** complete an actual 1980 rival project after cold Continue, map a live release into the world calendar/market correctly, prove player Review pressure from the historical standard, expand beyond one Action rival to eight Genres, test CPU and load/migration compatibility, and reconcile with current canonical source. Do not queue implementation from this checkpoint alone.
