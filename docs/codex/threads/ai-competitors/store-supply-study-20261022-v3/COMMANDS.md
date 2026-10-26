# Exact Store supply study commands — 2026-10-22

Run from the repository root in PowerShell. These output directories are retained and must not be reused. The actual Godot argv, executable SHA, process timeout, import hash, runner SHA and harness SHA are in each output's `world.command.json` / `world-run.json`.

```powershell
$pnPython = 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$pnGodot = 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe'
$pnThread = 'docs/codex/threads/ai-competitors'
$pnStudy = "$pnThread/store-supply-study-20261022-v3"
$pnBundle = "$pnThread/sims/store-supply-policy-smoke-20261022-v2"
$pnSource = 'aaeb3bd8a2a796eea3c453fa133bd0ce28b951ff35f5161eeb92d105d345f64a'

& $pnPython tools/simulator_variant.py create --id store-supply-control-20261022-v1 --owner ai-competitors --output "$pnThread/simulators/store-supply-control-20261022-v1"
& $pnPython tools/simulate.py run --variant "$pnThread/simulators/store-supply-control-20261022-v1" --config "$pnThread/store-supply-study-20261022-v1/smoke.json" --output "$pnThread/sims/store-supply-control-smoke-20261022-v2" --godot $pnGodot --timeout 240
& $pnPython "$pnThread/market-aware-study-20261022-v1/run_world.py" --bundle "$pnThread/sims/store-supply-control-smoke-20261022-v2" --output "$pnThread/sims/store-supply-existing-action-4417-v1" --godot $pnGodot --source e024ceb5e6aa2d9f94cacd203e121b52ce6e70c70107a12da592176e7661e94e --route action-war --seed 4417 --candidate 0
& $pnPython tools/simulator_variant.py create --id store-supply-policy-20261022-v1 --owner ai-competitors --from-variant "$pnThread/simulators/store-supply-control-20261022-v1" --output "$pnThread/simulators/store-supply-policy-20261022-v1"
& $pnPython tools/simulator_variant.py create --id store-supply-policy-20261022-v2 --owner ai-competitors --from-variant "$pnThread/simulators/store-supply-policy-20261022-v1" --output "$pnThread/simulators/store-supply-policy-20261022-v2"
& $pnPython tools/simulate.py run --variant "$pnThread/simulators/store-supply-policy-20261022-v2" --config "$pnThread/store-supply-study-20261022-v1/smoke.json" --output $pnBundle --godot $pnGodot --timeout 240

& $pnPython "$pnThread/store-supply-study-20261022-v1/run_world.py" --bundle $pnBundle --output "$pnThread/sims/store-supply-action-4417-A-v1" --godot $pnGodot --source $pnSource --route action-war --seed 4417 --candidate 0 --arm A
& $pnPython "$pnThread/store-supply-study-20261022-v1/run_world.py" --bundle $pnBundle --output "$pnThread/sims/store-supply-action-4417-B-v1" --godot $pnGodot --source $pnSource --route action-war --seed 4417 --candidate 0 --arm B
& $pnPython "$pnStudy/run_world.py" --bundle $pnBundle --output "$pnThread/sims/store-supply-action-4417-C-v3" --godot $pnGodot --source $pnSource --route action-war --seed 4417 --candidate 0 --arm C
& $pnPython "$pnStudy/run_world.py" --bundle $pnBundle --output "$pnThread/sims/store-supply-action-4418-A-v1" --godot $pnGodot --source $pnSource --route action-war --seed 4418 --candidate 0 --arm A
& $pnPython "$pnStudy/run_world.py" --bundle $pnBundle --output "$pnThread/sims/store-supply-action-4418-B-v1" --godot $pnGodot --source $pnSource --route action-war --seed 4418 --candidate 0 --arm B
& $pnPython "$pnStudy/run_world.py" --bundle $pnBundle --output "$pnThread/sims/store-supply-action-4418-C-v1" --godot $pnGodot --source $pnSource --route action-war --seed 4418 --candidate 0 --arm C

& $pnPython "$pnStudy/run_world.py" --bundle $pnBundle --output "$pnThread/sims/store-supply-action-4417-C-replay-v1" --godot $pnGodot --source $pnSource --route action-war --seed 4417 --candidate 0 --arm C --replay-input "$pnThread/sims/store-supply-action-4417-C-v3/world-report.json.tape.json"
& $pnPython "$pnStudy/run_world.py" --bundle $pnBundle --output "$pnThread/sims/store-supply-action-4418-C-replay-v1" --godot $pnGodot --source $pnSource --route action-war --seed 4418 --candidate 0 --arm C --replay-input "$pnThread/sims/store-supply-action-4418-C-v1/world-report.json.tape.json"
& $pnPython "$pnStudy/run_world.py" --bundle $pnBundle --output "$pnThread/sims/store-supply-action-4417-A-replay-v1" --godot $pnGodot --source $pnSource --route action-war --seed 4417 --candidate 0 --arm A --replay-input "$pnThread/sims/store-supply-action-4417-A-v1/world-report.json.tape.json"
& $pnPython "$pnStudy/run_world.py" --bundle $pnBundle --output "$pnThread/sims/store-supply-action-4418-B-replay-v1" --godot $pnGodot --source $pnSource --route action-war --seed 4418 --candidate 0 --arm B --replay-input "$pnThread/sims/store-supply-action-4418-B-v1/world-report.json.tape.json"
& $pnPython "$pnStudy/run_world.py" --bundle $pnBundle --output "$pnThread/sims/store-supply-action-4417-C-restore-v1" --godot $pnGodot --source $pnSource --route action-war --seed 4417 --candidate 0 --arm C --restore-input "$pnThread/sims/store-supply-action-4417-C-v3/world-report.json.checkpoint.json"
& $pnPython "$pnStudy/analyze.py"
```

Retained failed invocations (using the variables above):

```powershell
& $pnPython tools/simulate.py run --variant "$pnThread/simulators/store-supply-control-20261022-v1" --config "$pnThread/store-supply-study-20261022-v1/smoke.json" --output "$pnThread/sims/store-supply-control-smoke-20261022-v1" --timeout 240
& $pnPython tools/simulate.py run --variant "$pnThread/simulators/store-supply-policy-20261022-v1" --config "$pnThread/store-supply-study-20261022-v1/smoke.json" --output "$pnThread/sims/store-supply-policy-smoke-20261022-v1" --godot $pnGodot --timeout 240
& $pnPython "$pnThread/store-supply-study-20261022-v1/run_world.py" --bundle $pnBundle --output "$pnThread/sims/store-supply-action-4417-C-v1" --godot $pnGodot --source $pnSource --route action-war --seed 4417 --candidate 0 --arm C
& $pnPython "$pnThread/store-supply-study-20261022-v2/run_world.py" --bundle $pnBundle --output "$pnThread/sims/store-supply-action-4417-C-v2" --godot $pnGodot --source $pnSource --route action-war --seed 4417 --candidate 0 --arm C
```

The first command omitted `--godot`; the second found a private GDScript parse error; the third falsely rejected normal post-cycle Research deferment; the fourth found a diagnostic GDScript type inference error. Each has its own `run-report.json` or `world-run.json`, command and log. The corrected `v3` harness did not alter gameplay source, case, seed or bounds.
