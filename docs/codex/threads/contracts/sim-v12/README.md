# Native Starwave cross-specialty screen v12

Analysis-only harness for the [predeclared screen](PREDECLARATION.md). The `cross_specialty_route.gd` script is a parameterized copy of the pinned native-v3 legal Starwave route. It preserves real development, release, publisher-offer, Contract, Bank, payroll, rent and sales actions. The `run.py` runner verifies the pinned manifest, copies only runtime files into a disposable Godot project, installs the analysis script there, and checks source/copy drift after import and every attempt. It refuses to overwrite prior attempts.

Use the bundled Python interpreter (or another Python 3.12+) with these commands from the repository root:

```powershell
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' docs/codex/threads/contracts/sim-v12/run.py prepare
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' docs/codex/threads/contracts/sim-v12/run.py import
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' docs/codex/threads/contracts/sim-v12/run.py attempt action 1104
& 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' docs/codex/threads/contracts/sim-v12/run.py attempt sports 1104
```

Each attempt has `native-route.json`, `attempt.json`, `command.json`, `godot.log`, and `source-after.json`. Successful offer routes also write a before-Starwave checkpoint sidecar. A legal failed route exits Godot 1 but leaves structured results; runner errors distinguish technical failures. The native trace records owner/Genre, release ratings/Awareness, owned pool, action states, every Contract draw/selection/result, completion cash, original finance obligations and credit. An independent findings audit is still required before drawing a cross-roster recommendation.

The [completed v14 findings](../FINDINGS-v14-starwave-cross-specialty-screen.md) cover 14 legal attempts: Action 1104, Puzzle 4417 and Racing 1104 earned and completed Starwave; 11 routes stopped before Crown unlocked. The [independent audit](audit-summary.json) passed 158,470 checks, including source and Action-control parity. No successful route had a genuine cash block or original arrears before hand 3, so the conditional advance comparison was not triggered.

This first pass only screens foundation and live three-hand reachability. The [separate matched Game 4 continuation](../sim-v13/PREDECLARATION.md) is predeclared but not yet verified. No gameplay files or shared task authority were changed by this harness.
