# v13 repair v2

The first [Action/Starwave attempt](../action-1104-starwave/command.json) stopped before any legal action because GDScript could not infer the type of `cycle` at line 131. Its command, log, fallback result and attempt metadata remain in place. This revision changes that one analysis-only declaration to an explicit `int`. It uses a distinct disposable source copy, profiles, manifest and output directories, while retaining the [v13 predeclaration](../PREDECLARATION.md) and the exact three v12 checkpoint inputs.

Run the bundled Python from the repository root:

```powershell
$py = 'C:\Users\64jus\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
& $py docs/codex/threads/contracts/sim-v13/repair-v2/run.py prepare
& $py docs/codex/threads/contracts/sim-v13/repair-v2/run.py import
& $py docs/codex/threads/contracts/sim-v13/repair-v2/run.py parse
& $py docs/codex/threads/contracts/sim-v13/repair-v2/run.py attempt action-1104 starwave
& $py docs/codex/threads/contracts/sim-v13/repair-v2/run.py attempt action-1104 skip
& $py docs/codex/threads/contracts/sim-v13/repair-v2/run.py attempt puzzle-4417 starwave
& $py docs/codex/threads/contracts/sim-v13/repair-v2/run.py attempt puzzle-4417 skip
& $py docs/codex/threads/contracts/sim-v13/repair-v2/run.py attempt racing-1104 starwave
& $py docs/codex/threads/contracts/sim-v13/repair-v2/run.py attempt racing-1104 skip
```

The `parse` gate calls the script with a deliberately invalid arm; a controlled exit 1 and structured `undeclared arm or specialty` result confirm the analysis script loaded, without constructing gameplay. It is not counted as one of the six legal continuations. Every legal arm preserves a full native trace, command, log, input SHA, source drift check and explicit stop status. See the [parent README](../README.md) for the matched route policy and seed comparability.
