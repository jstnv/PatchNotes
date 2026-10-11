# Simulation Engine session v11 — M4b self-service runner

Date: 2026-10-11, America/Los_Angeles. Branch `main`; HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`. Dirty worktree on entry and exit. No commit/push/TODO edit/export/computer control. Existing edits and `.codex-godot-temp` preserved.

## Request and implementation

The user authorized the proposed profiling/efficiency follow-up and asked for simulations that other threads can run themselves. Read CURRENT_STATE, TODO, source provenance, Simulation Engine and relevant AI records, inspected branch/HEAD/status/diff, and archived the starting source before edits. Parallel work was disjoint: runner/debug CLI/docs; finance aggregate and verifier; root replay projection/artifacts/integration.

Added an isolated source-pinned Python/Godot runner, explicit trusted policy interface/examples, exact source-based replay, readable outcomes, lossless final state and Studio-only continuation artifacts. Measured duplicate finance validation and object projection before narrowing those paths. Public commands, score rules, data, RNG consumption and Continue boundaries remain unchanged. [Implementation and changed-file table](2026-10-11-extraction-m4b.md).

## Exact checks and results

Python executable: `C:/Users/64jus/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`. Godot executable: `C:/Users/64jus/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe`.

- `python docs/codex/threads/simulation-engine/m4b-v1/prepare.py`: archived 267 original files plus HEAD/status/diff evidence.
- `python docs/codex/threads/simulation-engine/m4b-v1/profile.py baseline`: initial cost breakdown, zero pinned command/result/state mismatches.
- `python docs/codex/threads/simulation-engine/m4b-v1/make_oracle.py`: derived a test-only independent projection from archived source.
- `python docs/codex/findings/card-presentation-v2/run.py import m4b-import-02`: accepted import; no unignored errors.
- `python docs/codex/findings/card-presentation-v2/run.py m4b-efficiency-01 verify_simulation_efficiency.gd`: 119 checks, 36-command route, zero failures.
- `python docs/codex/threads/simulation-engine/m4b-v1/run_checks.py`: eight additional suites pass, bringing the focused gate to nine. Includes 108 finance checks, 38 batch checks, 94 native/headless boundaries and 52 Contract comparisons. Exact process argv and source hashes are in the referenced focused evidence.
- Runner real process commands are retained in every `m4b-v1/runner-*/*.command.json`; fixture/custom concurrent runs, Studio continuation and two intentional policy failures preserve expected outcomes. Five strict fresh replays match 91 recorded commands. `runner-audit.py` passes 111 artifact checks; `python -m unittest discover -s tools/tests -p test_simulate.py -v` passes 14 checks.
- `python docs/codex/threads/simulation-engine/m4b-v1/run_profile_pair.py`: serial frozen-source baseline/optimized profiling, one warmup and three measured ten-release samples each. All 180 commands, results and canonical state digests match the pinned M4 tape in every sample. [Exact timings](m4b-v1/profile-comparison.json).
- `python docs/codex/threads/simulation-engine/m4b-v1/audit.py`: final mechanics hashes, accepted checks, allowed changed files, unchanged TODO/data/HEAD and retained temp-directory audit; creates final source archive and [acceptance.json](m4b-v1/acceptance.json).
- Focused `git diff --check` over changed documentation, simulator, finance, verifiers and runner paths: exit 0; only existing line-ending normalization notices.

## Rejected attempts and repairs

`m4b-import-01` and private `optimized-01` exposed an inferred-Variant boolean in the new Run getter; adding the explicit bool type fixed it. `m4b-finance-01` exposed two test-local inferred Variant annotations. `m4b-finance-02` exposed the constructed test fixture's missing `_cash_initialized` flag: its public cash getter correctly returned -1, so its proposed receipt was rejected. Fixed the fixture and guarded dependent assertions. Those two failing wrappers skipped normal quit and reached their 240-second process timeout; raw logs are retained. Process enumeration to end the first failed wrapper early was unavailable, so the harness timeout handled termination. No unrelated process was stopped.

`optimized-02` passed exact comparisons but overlapped other verification, so its timing is not used as the final performance claim. Final measurements run serially after other verification finishes. A debug-only finance-verifier revision during runner tests is recorded; frozen runner mechanics/data/assets still match final source.

## Limits and follow-up

Known root-certificate environment errors and ObjectDB shutdown warnings remain in retained logs. No leak-free, graphical, audible, export or release-readiness assertion. AI policies, balance values, shared-calendar rival scheduling and population limits remain OPEN. The [usage guide](USAGE.md) is linked from shared repository context so other threads can author bounded studies and preserve source-pinned findings independently. Timing spread and residual serialization/offer-planning costs are documented; no unbounded optimization or new AI defaults were introduced.
