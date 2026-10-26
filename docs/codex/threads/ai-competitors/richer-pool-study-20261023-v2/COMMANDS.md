# Exact richer-pool study commands — 2026-10-23

Run from repository root in PowerShell. Output directories below are retained and must never be reused. The runner's `world.command.json` and each simulator `run-report.json` record exact argv, import, executable SHA and process results.

```powershell
$pnPython = 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$pnGodot = 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe'
$pnThread = 'docs/codex/threads/ai-competitors'
$pnStudy = "$pnThread/richer-pool-study-20261023-v2"
$pnControl = "$pnThread/sims/richer-pool-control-smoke-20261023-v1"
$pnCandidate = "$pnThread/sims/richer-pool-policy-smoke-20261023-v3"
$pnControlSource = '652f14adf47d7b305e40503e6f624ce1acfe8813fe72d31e249e8572930de14f'
$pnCandidateSource = '63902c20526add5c2584d497583e7d5379c4054c0ec580a3291ca8f54d3122d0'

& $pnPython tools/simulator_variant.py create --id richer-pool-control-20261023-v1 --owner ai-competitors --output "$pnThread/simulators/richer-pool-control-20261023-v1"
& $pnPython tools/simulator_variant.py create --id richer-pool-policy-20261023-v1 --owner ai-competitors --from-variant "$pnThread/simulators/richer-pool-control-20261023-v1" --output "$pnThread/simulators/richer-pool-policy-20261023-v1"
& $pnPython tools/simulator_variant.py create --id richer-pool-policy-20261023-v2 --owner ai-competitors --from-variant "$pnThread/simulators/richer-pool-policy-20261023-v1" --output "$pnThread/simulators/richer-pool-policy-20261023-v2"
& $pnPython tools/simulator_variant.py create --id richer-pool-policy-20261023-v3 --owner ai-competitors --from-variant "$pnThread/simulators/richer-pool-policy-20261023-v2" --output "$pnThread/simulators/richer-pool-policy-20261023-v3"

& $pnPython tools/simulate.py run --variant "$pnThread/simulators/richer-pool-control-20261023-v1" --config "$pnThread/richer-pool-study-20261023-v1/smoke.json" --output $pnControl --godot $pnGodot --timeout 240
& $pnPython tools/simulate.py run --variant "$pnThread/simulators/richer-pool-policy-20261023-v3" --config "$pnThread/richer-pool-study-20261023-v1/smoke.json" --output $pnCandidate --godot $pnGodot --timeout 240

& $pnPython "$pnStudy/run_world.py" --bundle $pnControl --output "$pnThread/sims/richer-pool-action-fantasy-4417-control-v4" --godot $pnGodot --source $pnControlSource --route action-fantasy --seed 4417 --candidate 0 --arm A
& $pnPython "$pnStudy/run_world.py" --bundle $pnCandidate --output "$pnThread/sims/richer-pool-action-fantasy-4417-A-v1" --godot $pnGodot --source $pnCandidateSource --route action-fantasy --seed 4417 --candidate 1 --arm A
& $pnPython "$pnStudy/run_world.py" --bundle $pnCandidate --output "$pnThread/sims/richer-pool-action-fantasy-4417-B-v1" --godot $pnGodot --source $pnCandidateSource --route action-fantasy --seed 4417 --candidate 1 --arm B
& $pnPython "$pnStudy/run_world.py" --bundle $pnCandidate --output "$pnThread/sims/richer-pool-action-fantasy-4417-C-v1" --godot $pnGodot --source $pnCandidateSource --route action-fantasy --seed 4417 --candidate 1 --arm C
& $pnPython "$pnStudy/run_world.py" --bundle $pnCandidate --output "$pnThread/sims/richer-pool-action-fantasy-4418-A-v1" --godot $pnGodot --source $pnCandidateSource --route action-fantasy --seed 4418 --candidate 1 --arm A
& $pnPython "$pnStudy/run_world.py" --bundle $pnCandidate --output "$pnThread/sims/richer-pool-action-fantasy-4418-B-v1" --godot $pnGodot --source $pnCandidateSource --route action-fantasy --seed 4418 --candidate 1 --arm B
& $pnPython "$pnStudy/run_world.py" --bundle $pnCandidate --output "$pnThread/sims/richer-pool-action-fantasy-4418-C-v1" --godot $pnGodot --source $pnCandidateSource --route action-fantasy --seed 4418 --candidate 1 --arm C

& $pnPython "$pnStudy/run_world.py" --bundle $pnCandidate --output "$pnThread/sims/richer-pool-action-fantasy-4417-C-replay-v1" --godot $pnGodot --source $pnCandidateSource --route action-fantasy --seed 4417 --candidate 1 --arm C --replay-input "$pnThread/sims/richer-pool-action-fantasy-4417-C-v1/world-report.json.tape.json"
& $pnPython "$pnStudy/run_world.py" --bundle $pnCandidate --output "$pnThread/sims/richer-pool-action-fantasy-4418-C-replay-v1" --godot $pnGodot --source $pnCandidateSource --route action-fantasy --seed 4418 --candidate 1 --arm C --replay-input "$pnThread/sims/richer-pool-action-fantasy-4418-C-v1/world-report.json.tape.json"
& $pnPython "$pnStudy/run_world.py" --bundle $pnCandidate --output "$pnThread/sims/richer-pool-action-fantasy-4418-C-restore-v1" --godot $pnGodot --source $pnCandidateSource --route action-fantasy --seed 4418 --candidate 1 --arm C --restore-input "$pnThread/sims/richer-pool-action-fantasy-4418-C-v1/world-report.json.checkpoint.json"

& $pnPython "$pnStudy/analyze.py"
& $pnPython "$pnStudy/compare_player_final.py"
```

Retained failures: candidate [v1 import](../sims/richer-pool-policy-smoke-20261023-v1/import.log) and [v2 import](../sims/richer-pool-policy-smoke-20261023-v2/import.log) stopped on private GDScript type inference; [control world v1](../sims/richer-pool-action-fantasy-4417-control-v1/world.log) and [v2](../sims/richer-pool-action-fantasy-4417-control-v2/world.log) stopped on diagnostic references to candidate-only static methods; [control world v3](../sims/richer-pool-action-fantasy-4417-control-v3/world.command.json) reached player step 121/cycle 47 then hit the original 240-second wall guard during concurrent import. The [v2 pre-run amendment](../2026-10-23-richer-pool-competence-plan-v2.md) changed only the whole-process guard to 480 seconds and made remaining worlds sequential. No failed output was overwritten.
