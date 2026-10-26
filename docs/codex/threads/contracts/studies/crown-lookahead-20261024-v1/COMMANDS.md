# Exact commands — Crown lookahead v1

2026-10-24, from repository-root PowerShell. Each output directory is unique. Original evidence folders must not be reused for reproduction.

```powershell
$crownPython = 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
$crownGodot = 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
$crownStudy = 'docs/codex/threads/contracts/studies/crown-lookahead-20261024-v1'
$crownVariant = 'docs/codex/threads/contracts/simulators/crown-lookahead-brief-v1'
$crownRaw = 'C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-lookahead-20261024-v1'

& $crownPython tools/simulator_variant.py create --id crown-lookahead-brief-v1 --owner contracts --from-variant docs/codex/threads/contracts/simulators/crown-planning-brief-v1 --output $crownVariant
& $crownPython "$crownStudy/prepare.py"
& $crownPython tools/simulate.py run --variant $crownVariant --config "$crownStudy/controls.json" --output "$crownRaw/controls" --godot $crownGodot --timeout 240
& $crownPython "$crownStudy/prepare_analysis.py"
& $crownPython tools/simulate.py run --variant $crownVariant --config "$crownStudy/controls.json" --output "$crownRaw/controls-v2" --godot $crownGodot --timeout 240
& $crownPython "$crownStudy/prepare_closeout.py"
& $crownPython tools/simulate.py run --variant $crownVariant --config "$crownStudy/candidates.json" --output "$crownRaw/candidates" --godot $crownGodot --timeout 240
& $crownPython "$crownStudy/analyze.py" $crownRaw analysis-v1.json
& $crownPython "$crownStudy/summarize.py"
& $crownPython tools/simulate.py replay --bundle "$crownRaw/candidates" --case lookahead-4417 --output "$crownRaw/replay-lookahead-4417" --godot $crownGodot --timeout 240
& $crownPython tools/simulate.py replay --bundle "$crownRaw/candidates" --case lookahead_safe-4418 --output "$crownRaw/replay-lookahead_safe-4418" --godot $crownGodot --timeout 240
& $crownPython docs/codex/threads/simulation-engine/examples/prepare-continuation.py --bundle "$crownRaw/candidates" --case lookahead_safe-4418 --case-id cold-lookahead_safe-4418 --target-release-count 7 --max-commands 40 --output "$crownStudy/cold-input.json"
& $crownPython tools/simulate.py run --variant $crownVariant --config "$crownStudy/cold-input.json" --output "$crownRaw/cold-lookahead_safe-4418" --godot $crownGodot --timeout 240
& $crownPython "$crownStudy/closeout.py"
```

The first control capture stops before import/gameplay because canonical source changes while recording drift; [retained failure/retry](CAPTURE-RETRY.md). The unchanged control command uses a new `controls-v2` output. Analysis is pointed to that retry while preserving the original capture report. No policy, candidate source, seeds or bounds are changed. Both executed batches retain their known seed4419 affordability rejections; final status/check counts are recorded in the finding. Low-level Godot arguments, process timestamps/timeouts and isolated environment profiles are in retained `*.command.json` files.

The independent analysis imports `policy_audit.py`; preparation helpers create versioned study files once. Final documentation/TODO reconciliation and verification use `update_records.py` and `verify_docs.py`, with receipts preserving every unrelated byte. No GUI, native export, player-save access, canonical gameplay write, commit or push command is used.
