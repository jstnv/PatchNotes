# Six-hand phase-allocation study commands — 2026-10-23

Run from repository root in PowerShell. Every output folder was new and retained. The expanded exact argv, Godot executable hash, frozen source identity, import and world process result are in each `world-run.json`/`world.command.json`.

```powershell
$pnPython = 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$pnGodot = 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe'
$pnThread = 'docs/codex/threads/ai-competitors'
$pnStudy = "$pnThread/six-hand-phase-study-20261023-v1"
$pnVariant = "$pnThread/simulators/six-hand-phase-allocation-20261023-v1"
$pnBundle = "$pnThread/sims/six-hand-phase-smoke-20261023-v1"
$pnSource = '42bcc6ce59c0bcc3c239d97af8d20fcf1ad1eab2ad15a494f4f204e7fcc1a3f0'

& $pnPython tools/simulator_variant.py create --id six-hand-phase-allocation-20261023-v1 --owner ai-competitors --from-variant "$pnThread/simulators/no-research-plan-candidate-20261023-v1" --output $pnVariant
& $pnPython tools/simulate.py run --variant $pnVariant --config "$pnStudy/smoke.json" --output $pnBundle --godot $pnGodot --timeout 240

& $pnPython "$pnStudy/run_world.py" --bundle $pnBundle --output "$pnThread/sims/six-hand-phase-4417-A-v1" --godot $pnGodot --source $pnSource --route action-fantasy --seed 4417 --candidate 1 --arm A
& $pnPython "$pnStudy/run_world.py" --bundle $pnBundle --output "$pnThread/sims/six-hand-phase-4417-B-v1" --godot $pnGodot --source $pnSource --route action-fantasy --seed 4417 --candidate 1 --arm B
& $pnPython "$pnStudy/run_world.py" --bundle $pnBundle --output "$pnThread/sims/six-hand-phase-4417-C-v1" --godot $pnGodot --source $pnSource --route action-fantasy --seed 4417 --candidate 1 --arm C
& $pnPython "$pnStudy/run_world.py" --bundle $pnBundle --output "$pnThread/sims/six-hand-phase-4418-A-v1" --godot $pnGodot --source $pnSource --route action-fantasy --seed 4418 --candidate 1 --arm A
& $pnPython "$pnStudy/run_world.py" --bundle $pnBundle --output "$pnThread/sims/six-hand-phase-4418-B-v1" --godot $pnGodot --source $pnSource --route action-fantasy --seed 4418 --candidate 1 --arm B
& $pnPython "$pnStudy/run_world.py" --bundle $pnBundle --output "$pnThread/sims/six-hand-phase-4418-C-v1" --godot $pnGodot --source $pnSource --route action-fantasy --seed 4418 --candidate 1 --arm C

& $pnPython "$pnStudy/run_world.py" --bundle $pnBundle --output "$pnThread/sims/six-hand-phase-4417-B-replay-v1" --godot $pnGodot --source $pnSource --route action-fantasy --seed 4417 --candidate 1 --arm B --replay-input "$pnThread/sims/six-hand-phase-4417-B-v1/world-report.json.tape.json"
& $pnPython "$pnStudy/run_world.py" --bundle $pnBundle --output "$pnThread/sims/six-hand-phase-4418-C-replay-v1" --godot $pnGodot --source $pnSource --route action-fantasy --seed 4418 --candidate 1 --arm C --replay-input "$pnThread/sims/six-hand-phase-4418-C-v1/world-report.json.tape.json"
& $pnPython "$pnStudy/run_world.py" --bundle $pnBundle --output "$pnThread/sims/six-hand-phase-4418-B-restore-v1" --godot $pnGodot --source $pnSource --route action-fantasy --seed 4418 --candidate 1 --arm B --restore-input "$pnThread/sims/six-hand-phase-4418-B-v1/world-report.json.checkpoint.json"
& $pnPython "$pnStudy/analyze.py"
```

The current-policy baseline comparison is the retained no-Research [A/control world](../sims/no-research-plan-4417-control-v1/world-run.json) and [candidate A world](../sims/no-research-plan-4417-A-v1/world-run.json). This study's A 4417 will assert parity against that frozen control; no checkpoint crosses revisions.
