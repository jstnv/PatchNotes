# Exact bounded study invocations (2026-10-22)

These are the PowerShell runner invocations used for the stable world records and fresh-process checks. Each output directory already exists; use a new version tag for any repetition. `world.command.json` inside each output retains the exact Godot process argv and hard 240-second limit. Failed/excluded attempts are linked in the [finding](../2026-10-22-market-aware-choice-finding-v1.md).

```powershell
$pnPython = 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$pnGodot = 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64.exe'
$pnRoot = 'docs/codex/threads/ai-competitors'
$pnRunner = "$pnRoot/market-aware-study-20261022-v1/run_world.py"
$pnControl = "$pnRoot/sims/market-aware-control-freeze-20261022-v1"
$pnCandidate = "$pnRoot/sims/market-aware-targets-20261022-v1-smoke02"
$pnControlSource = '386d42892f3b34ece7cc88b1df5359ba584e97a4aa465fdce73e13d6ae4ec8bc'
$pnCandidateSource = 'eb2579eabc1cf40f3cab1f0e17d4ac5a7a57b723496351e66ca6d3b535d7a177'

& $pnPython $pnRunner --bundle $pnControl --output "$pnRoot/sims/market-aware-world-action-war-4417-control-v2" --godot $pnGodot --source $pnControlSource --route action-war --seed 4417 --candidate 0
& $pnPython $pnRunner --bundle $pnCandidate --output "$pnRoot/sims/market-aware-world-action-war-4417-candidate-v1" --godot $pnGodot --source $pnCandidateSource --route action-war --seed 4417 --candidate 1
& $pnPython $pnRunner --bundle $pnControl --output "$pnRoot/sims/market-aware-world-action-war-4418-control-v1" --godot $pnGodot --source $pnControlSource --route action-war --seed 4418 --candidate 0
& $pnPython $pnRunner --bundle $pnCandidate --output "$pnRoot/sims/market-aware-world-action-war-4418-candidate-v1" --godot $pnGodot --source $pnCandidateSource --route action-war --seed 4418 --candidate 1
& $pnPython $pnRunner --bundle $pnControl --output "$pnRoot/sims/market-aware-world-strong-4417-control-v1" --godot $pnGodot --source $pnControlSource --route strong --seed 4417 --candidate 0
& $pnPython $pnRunner --bundle $pnCandidate --output "$pnRoot/sims/market-aware-world-strong-4417-candidate-v1" --godot $pnGodot --source $pnCandidateSource --route strong --seed 4417 --candidate 1
& $pnPython $pnRunner --bundle $pnControl --output "$pnRoot/sims/market-aware-world-puzzle-war-4417-control-v1" --godot $pnGodot --source $pnControlSource --route puzzle-war --seed 4417 --candidate 0
& $pnPython $pnRunner --bundle $pnCandidate --output "$pnRoot/sims/market-aware-world-puzzle-war-4417-candidate-v1" --godot $pnGodot --source $pnCandidateSource --route puzzle-war --seed 4417 --candidate 1

& $pnPython $pnRunner --bundle $pnControl --output "$pnRoot/sims/market-aware-world-puzzle-war-4417-control-replay-v1" --godot $pnGodot --source $pnControlSource --route puzzle-war --seed 4417 --candidate 0 --replay-input "$pnRoot/sims/market-aware-world-puzzle-war-4417-control-v1/world-report.json.tape.json"
& $pnPython $pnRunner --bundle $pnCandidate --output "$pnRoot/sims/market-aware-world-puzzle-war-4417-candidate-replay-v1" --godot $pnGodot --source $pnCandidateSource --route puzzle-war --seed 4417 --candidate 1 --replay-input "$pnRoot/sims/market-aware-world-puzzle-war-4417-candidate-v1/world-report.json.tape.json"
& $pnPython $pnRunner --bundle $pnCandidate --output "$pnRoot/sims/market-aware-world-action-war-4417-candidate-replay-v1" --godot $pnGodot --source $pnCandidateSource --route action-war --seed 4417 --candidate 1 --replay-input "$pnRoot/sims/market-aware-world-action-war-4417-candidate-v1/world-report.json.tape.json"
& $pnPython $pnRunner --bundle $pnCandidate --output "$pnRoot/sims/market-aware-world-strong-4417-candidate-replay-v1" --godot $pnGodot --source $pnCandidateSource --route strong --seed 4417 --candidate 1 --replay-input "$pnRoot/sims/market-aware-world-strong-4417-candidate-v1/world-report.json.tape.json"
& $pnPython $pnRunner --bundle $pnCandidate --output "$pnRoot/sims/market-aware-world-action-war-4417-candidate-restore-v1" --godot $pnGodot --source $pnCandidateSource --route action-war --seed 4417 --candidate 1 --restore-input "$pnRoot/sims/market-aware-world-action-war-4417-candidate-v1/world-report.json.checkpoint.json"
```

The source-freezing smoke inputs are retained as [control](../sims/market-aware-control-freeze-20261022-v1/inputs/requested.json) and [candidate](../sims/market-aware-targets-20261022-v1-smoke02/inputs/requested.json); the successful run reports pin policy and snapshot manifests. The bounded comparison outputs are `comparison-*.json` in this folder.
