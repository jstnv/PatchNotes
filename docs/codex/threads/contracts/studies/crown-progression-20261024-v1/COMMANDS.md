# Commands — Crown design evidence v1

Run from `C:\Users\64jus\OneDrive\Documents\GitHub\PatchNotes` on2026-10-24. The saved runtime-paths-v2.json contains the persistent absolute evidence paths. Original runtime-paths.json identifies the failed pre-capture TEMP invocation; see environment-failure-v1.md. Source/policy/seed/limits were unchanged in the transport retry.

```powershell
$crownPaths = Get-Content docs/codex/threads/contracts/studies/crown-progression-20261024-v1/runtime-paths-v2.json -Raw | ConvertFrom-Json
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/simulate.py run --config docs/codex/threads/contracts/studies/crown-progression-20261024-v1/baseline.json --output $crownPaths.run --godot $crownPaths.godot --timeout 240
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' tools/simulate.py replay --bundle $crownPaths.run --case action-cult-4417-current-crown --output $crownPaths.replay --godot $crownPaths.godot --timeout 240
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' docs/codex/threads/contracts/studies/crown-progression-20261024-v1/arithmetic.py
& 'C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' docs/codex/threads/contracts/studies/crown-progression-20261024-v1/analyze-baseline.py
```

All four successful commands exited0. Initial failed runner used the same flags with runtime-paths.json and exited1 before producing a bundle. Reruns must choose new output folders and new analysis destinations; scripts intentionally refuse to replace existing result files. Exact Godot/import/replay subprocess commands are retained in each raw bundle's `*.command.json`. No canonical-source or accepted-save identity was edited.
