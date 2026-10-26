# No-Research project-plan study commands — 2026-10-23

Run from repository root in PowerShell. Each listed output was created once; use a new name for any rerun. `world-run.json` and `world.command.json` retain the expanded actual argv, executable/source hashes, import and process outcomes.

```powershell
$pnPython = 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$pnGodot = 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe'
$pnThread = 'docs/codex/threads/ai-competitors'
$pnStudy = "$pnThread/no-research-plan-study-20261023-v1"
$pnControlVariant = "$pnThread/simulators/no-research-plan-control-20261023-v1"
$pnCandidateVariant = "$pnThread/simulators/no-research-plan-candidate-20261023-v1"
$pnControlBundle = "$pnThread/sims/no-research-plan-control-smoke-20261023-v1"
$pnCandidateBundle = "$pnThread/sims/no-research-plan-candidate-smoke-20261023-v1"
$pnControlSource = '026fcaf5c59c1a01cceeeea7262a8711705269488bb911afd27ca53214b47e3a'
$pnCandidateSource = 'eb00479a5de7908617fb812707340abbbf25365dc9d00b067bc1e557eb580189'

& $pnPython tools/simulator_variant.py create --id no-research-plan-control-20261023-v1 --owner ai-competitors --output $pnControlVariant
& $pnPython tools/simulator_variant.py create --id no-research-plan-candidate-20261023-v1 --owner ai-competitors --from-variant $pnControlVariant --output $pnCandidateVariant
& $pnPython tools/simulate.py run --variant $pnControlVariant --config "$pnStudy/smoke.json" --output $pnControlBundle --godot $pnGodot --timeout 240
& $pnPython tools/simulate.py run --variant $pnCandidateVariant --config "$pnStudy/smoke.json" --output $pnCandidateBundle --godot $pnGodot --timeout 240

& $pnPython "$pnStudy/run_world.py" --bundle $pnControlBundle --output "$pnThread/sims/no-research-plan-4417-control-v1" --godot $pnGodot --source $pnControlSource --route action-fantasy --seed 4417 --candidate 0 --arm A
& $pnPython "$pnStudy/run_world.py" --bundle $pnCandidateBundle --output "$pnThread/sims/no-research-plan-4417-A-v1" --godot $pnGodot --source $pnCandidateSource --route action-fantasy --seed 4417 --candidate 1 --arm A
& $pnPython "$pnStudy/run_world.py" --bundle $pnCandidateBundle --output "$pnThread/sims/no-research-plan-4417-B-v1" --godot $pnGodot --source $pnCandidateSource --route action-fantasy --seed 4417 --candidate 1 --arm B
& $pnPython "$pnStudy/run_world.py" --bundle $pnCandidateBundle --output "$pnThread/sims/no-research-plan-4417-C-v1" --godot $pnGodot --source $pnCandidateSource --route action-fantasy --seed 4417 --candidate 1 --arm C
& $pnPython "$pnStudy/run_world.py" --bundle $pnCandidateBundle --output "$pnThread/sims/no-research-plan-4418-A-v1" --godot $pnGodot --source $pnCandidateSource --route action-fantasy --seed 4418 --candidate 1 --arm A
& $pnPython "$pnStudy/run_world.py" --bundle $pnCandidateBundle --output "$pnThread/sims/no-research-plan-4418-B-v1" --godot $pnGodot --source $pnCandidateSource --route action-fantasy --seed 4418 --candidate 1 --arm B
& $pnPython "$pnStudy/run_world.py" --bundle $pnCandidateBundle --output "$pnThread/sims/no-research-plan-4418-C-v1" --godot $pnGodot --source $pnCandidateSource --route action-fantasy --seed 4418 --candidate 1 --arm C

& $pnPython "$pnStudy/run_world.py" --bundle $pnCandidateBundle --output "$pnThread/sims/no-research-plan-4418-C-replay-v1" --godot $pnGodot --source $pnCandidateSource --route action-fantasy --seed 4418 --candidate 1 --arm C --replay-input "$pnThread/sims/no-research-plan-4418-C-v1/world-report.json.tape.json"
& $pnPython "$pnStudy/run_world.py" --bundle $pnCandidateBundle --output "$pnThread/sims/no-research-plan-4417-B-replay-v1" --godot $pnGodot --source $pnCandidateSource --route action-fantasy --seed 4417 --candidate 1 --arm B --replay-input "$pnThread/sims/no-research-plan-4417-B-v1/world-report.json.tape.json"
& $pnPython "$pnStudy/run_world.py" --bundle $pnCandidateBundle --output "$pnThread/sims/no-research-plan-4418-C-restore-v1" --godot $pnGodot --source $pnCandidateSource --route action-fantasy --seed 4418 --candidate 1 --arm C --restore-input "$pnThread/sims/no-research-plan-4418-C-v1/world-report.json.checkpoint.json"
& $pnPython "$pnStudy/analyze.py"
```

The first `analyze.py` invocation failed with a Python `TypeError` because checkpoint cash/Fans fields deserialize as strings. The script was corrected to convert those fields to integers; no simulator source, seed, policy or output changed. That successful invocation wrote `analysis.json`, which double-counted duplicated traced policy rows as extra hands. The script was corrected to count unique project/phase/sequence keys and rerun to `analysis-v2.json`; the original result remains retained. The failed diagnostic and correction are also in the local session log.
