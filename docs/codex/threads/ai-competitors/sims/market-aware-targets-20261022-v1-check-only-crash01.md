# Candidate direct parser attempt — retained failure, 2026-10-22

Source: `market-aware-targets-20261022-v1` private simulator candidate, after the three-file market-aware selector delta.

Command from the repository root:

```powershell
& 'C:\Users\64jus\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe' --headless --path 'docs/codex/threads/ai-competitors/simulators/market-aware-targets-20261022-v1/project' --check-only --script 'res://scripts/market/rival_synergy_choice.gd'
```

Result: exit 1 after 5.88 seconds. Godot 4.7.1 reported `CrashHandlerException: Program crashed with signal 11` and printed a native C++ backtrace without a GDScript diagnostic. This is a failed/inconclusive direct parser attempt, not evidence that candidate GDScript compiled. The subsequent isolated `simulate.py run` smoke is recorded in its own output folder.
