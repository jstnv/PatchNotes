# Commands — Crown visible planning v1

2026-10-24; repository-root PowerShell. Paths below expand to the exact invocations used. Runs use private projects/import caches/profiles, not player saves. Reproduction requires new output folders; retained originals are immutable.

```powershell
$crownPython = 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
$crownGodot = 'C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
$crownStudy = 'docs/codex/threads/contracts/studies/crown-planning-20261024-v1'
$crownVariant = 'docs/codex/threads/contracts/simulators/crown-planning-brief-v1'
$crownRaw = 'C:/Users/64jus/Downloads/Patch Notes Design Folder/Simulator Evidence/Contracts/crown-planning-20261024-v1'

& $crownPython tools/simulator_variant.py create --id crown-planning-brief-v1 --owner contracts --from-variant docs/codex/threads/contracts/simulators/crown-balance-brief-v1 --output $crownVariant
& $crownPython "$crownStudy/prepare.py"
& $crownPython tools/simulate.py run --variant $crownVariant --config "$crownStudy/cases.json" --output "$crownRaw/candidate-v1" --godot $crownGodot --timeout 240
& $crownPython "$crownStudy/prepare_analysis.py"
& $crownPython "$crownStudy/analyze.py" "$crownRaw/candidate-v1" analysis-v1.json
& $crownPython tools/simulate.py replay --bundle "$crownRaw/candidate-v1" --case balanced-4417 --output "$crownRaw/replay-balanced-4417" --godot $crownGodot --timeout 240
& $crownPython tools/simulate.py replay --bundle "$crownRaw/candidate-v1" --case retained_redraw-4417 --output "$crownRaw/replay-retained_redraw-4417" --godot $crownGodot --timeout 240
& $crownPython docs/codex/threads/simulation-engine/examples/prepare-continuation.py --bundle "$crownRaw/candidate-v1" --case retained_redraw-4417 --case-id cold-retained_redraw-4417 --target-release-count 7 --max-commands 40 --output "$crownStudy/cold-input.json"
& $crownPython tools/simulate.py run --variant $crownVariant --config "$crownStudy/cold-input.json" --output "$crownRaw/cold-retained_redraw-4417" --godot $crownGodot --timeout 240
& $crownPython "$crownStudy/diagnose.py"
& $crownPython "$crownStudy/closeout.py"
```

All commands exit0 except the15-case batch, which exits1 for five retained pre-Crown affordability rejections. Controls precede candidate policies in the batch; replays and cold Continue ran concurrently in separate folders. Analysis helper's preliminary redraw field name was corrected to the actual `available_redraws` before its first execution; no policy/config/source correction or outcome-driven retry. Low-level Godot arguments, environment profiles, hashes, timestamps and bounded timeouts are retained in each bundle's `*.command.json` and reports.

Final documentation/queue verification uses `update_queue.py`, `verify_docs.py` and scoped `git -c core.safecrlf=false -c core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol diff --check`. The mutation receipt verifies the entire previous TODO/README/HANDOFF byte content survives the insertion. No commit/push/export/GUI command was run.
