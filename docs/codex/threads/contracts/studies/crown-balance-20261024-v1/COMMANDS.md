# Exact commands — Crown balance study v1

2026-10-24. Run from repository root. Python executable: `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`. Godot: `C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe`. All game execution is headless through the isolated runner.

For readability, these variables abbreviate the exact paths used in the invocations:

```powershell
$crownPython = 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
$crownGodot = 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
$crownRaw = 'C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-balance-20261024-v1'
$crownStudy = 'docs/codex/threads/contracts/studies/crown-balance-20261024-v1'

& $crownPython tools/simulator_variant.py create --id crown-balance-base-v1 --owner contracts --output docs/codex/threads/contracts/simulators/crown-balance-base-v1
& $crownPython tools/simulate.py run --variant docs/codex/threads/contracts/simulators/crown-balance-base-v1 --config docs/codex/threads/contracts/studies/crown-progression-20261024-v1/baseline.json --output "$crownRaw/baseline" --godot $crownGodot --timeout 240
& $crownPython tools/simulator_variant.py create --id crown-balance-brief-v1 --owner contracts --from-variant docs/codex/threads/contracts/simulators/crown-balance-base-v1 --output docs/codex/threads/contracts/simulators/crown-balance-brief-v1
& $crownPython "$crownStudy/build_candidate.py"
& $crownPython tools/simulate.py run --variant docs/codex/threads/contracts/simulators/crown-balance-brief-v1 --config "$crownStudy/cases.json" --output "$crownRaw/candidate-v1" --godot $crownGodot --timeout 240
& $crownPython "$crownStudy/analyze.py" "$crownRaw/candidate-v1" analysis-v1.json
& $crownPython "$crownStudy/diagnose.py"

& $crownPython tools/simulate.py replay --bundle "$crownRaw/candidate-v1" --case balanced-4417 --output "$crownRaw/replay-balanced-4417" --godot $crownGodot --timeout 240
& $crownPython tools/simulate.py replay --bundle "$crownRaw/candidate-v1" --case naive-4417 --output "$crownRaw/replay-naive-4417" --godot $crownGodot --timeout 240
& $crownPython docs/codex/threads/simulation-engine/examples/prepare-continuation.py --bundle "$crownRaw/candidate-v1" --case balanced-4417 --case-id cold-balanced-4417 --target-release-count 7 --max-commands 40 --output "$crownStudy/cold-input.json"
& $crownPython tools/simulate.py run --variant docs/codex/threads/contracts/simulators/crown-balance-brief-v1 --config "$crownStudy/cold-input.json" --output "$crownRaw/cold-balanced-4417" --godot $crownGodot --timeout 240
& $crownPython "$crownStudy/closeout.py"
```

The candidate batch exited1, retaining seed4419's four identical unaffordable-policy-action rejections. Both variant creations, unchanged baseline, two replays, cold preparation/continuation and all analysis commands exited0. No candidate correction, extra seed, raised limit or second gameplay batch followed. Exact subprocess flags/logs are retained under each raw bundle's `*.command.json`. Existing folders/results are immutable evidence; reproduction needs new folders and new result destinations.
