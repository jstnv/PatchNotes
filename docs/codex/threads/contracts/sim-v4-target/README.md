# Task 34 follow-up: low-Scope target sensitivity

Read [predeclaration](PREDECLARATION.md) before [findings](FINDINGS.md). This folder contains the read-only pinned-source experiment and owns all authored artifacts. The generated `project/` and isolated `profile/` are ignored. Source main HEAD is `b84d1a5b4e4957b044b4b52c41553cf611aff3ae`.

From the repository root, use the bundled Python executable described in the workspace dependencies:

1. `python docs/codex/threads/contracts/sim-v4-target/prepare.py` on a fresh folder without `project/`.
2. `python docs/codex/threads/contracts/sim-v4-target/run.py import`.
3. `python docs/codex/threads/contracts/sim-v4-target/run.py`.
4. `python docs/codex/threads/contracts/sim-v4-target/audit.py` to verify retained outputs and regenerate `arms.csv`, `pairs.csv` and `audit-results.json`.

The four `crown-*.json` and `neon-*.json` files contain complete native hand/finance traces and candidate scoring. Matching `.command.json` files give exact Godot paths/arguments and exit codes; `.log` files give runtime warnings and success markers. [Copy manifest](copy-manifest.json) and the predeclared typed-input hashes identify the source. The prior Task 34 raw captures are read as inputs, never overwritten. A full source copy is unnecessary for inspecting the saved evidence.
