# Rival Beta shadow runway implementation plan — 2026-10-25

> **For agentic workers:** Execute the checked steps in this thread without touching canonical gameplay. A private simulator variant and its frozen runs are the only executable artifacts.

**Goal:** Capture exact decision-time finance and run-cycle inputs at every ordinary rival Beta exit while leaving choices, state and RNG unchanged.

**Architecture:** Fork the frozen two-hand control variant. Put a copy of the existing shared-world study harness under that variant's `project/scripts/debug/`, changing only its trace row at Beta exits. A small thread-owned runner wrapper selects that frozen harness from the bundle and delegates to the documented isolated `run_world.py`. Read-only analysis compares its exit rows and complete world/replay state with the prior control.

**Tech stack:** Godot 4.7.1 GDScript, Python 3, `tools/simulator_variant.py`, `tools/simulate.py`, the existing isolated shared-world runner.

**Spec:** [cash-funded Beta direction](2026-10-25-cash-funded-beta-direction-v1.md) and [input gap finding](2026-10-25-beta-runway-input-finding-v1.md). This plan validates observation only; the reserve, duration and marginal-value policy remain **OPEN**.

## Global constraints

- Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f` at intake. Preserve the broad shared dirty worktree and `.codex-godot-temp`.
- No canonical gameplay, player save, shared TODO, commit, push or new Bank loan action.
- Keep the frozen two-hand control as ancestry; do not edit its files or prior bundles. Any revision after the first executed snapshot gets a new variant.
- Use only distinct output directories under this thread's `sims/`. Preserve failures, source/RNG identity checks and Studio-only Continue.

## Files and responsibilities

- `simulators/rival-beta-shadow-runway-20261025-v1/project/scripts/debug/rival_beta_shadow_world_study.gd`: private copy of the source-pinned `world_study.gd`, adding exact `view.run_cycle` and `RunState.get_studio_finance_report()` to `request_exit` Beta rows. Do not alter policy, actions, random streams or comparison checks.
- `2026-10-25-run-beta-shadow-world-v1.py`: wrapper that selects the frozen bundle's private harness, then calls the existing isolated world runner; it must not point at mutable canonical or another thread's project.
- `2026-10-25-beta-shadow-runway-audit-v1.py`: compare control/telemetry world choices after removing new fields, final state/RNG, release/cash outcomes, and validate finance cash/cycle at each exit. Report liability fields and unknown future bills explicitly.
- Unique `sims/` folders: smoke, one or two legal worlds, exact fresh replay and Studio-only Continue. Retain full receipts.

## Steps

- [x] Fork the control with `tools/simulator_variant.py create --id rival-beta-shadow-runway-20261025-v1 --owner ai-competitors --from-variant docs/codex/threads/ai-competitors/simulators/rival-proportional-beta-control-20261024-v1 --output docs/codex/threads/ai-competitors/simulators/rival-beta-shadow-runway-20261025-v1`.
- [x] Copy and minimally instrument the frozen shared-world harness inside only the new variant's `project/`. Capture a read-only finance report once at each `request_exit` Beta choice; assert it is available and its cash/current cycle match the observation. Record the original `world.cycle` separately.
- [x] Run `tools/simulate.py run --variant ... --config docs/codex/threads/ai-competitors/six-hand-phase-study-20261023-v1/smoke.json --output <new smoke folder> --godot <console Godot> --timeout 240`. Record the bundle's exact source identity, ancestry and changed-file set.
- [x] Run the documented shared-world runner through the wrapper for seed 4417, Action/Fantasy, arm B, existing 210-command/eight-player-release/cycle64/twelve-zero-step/480-second bounds. Stop on import, source, legality or telemetry mismatch. If clean, repeat seed 4418. Match each seed's control initial state and typed RNG, all ordinary choices/state/RNG after stripping telemetry, and release outcomes.
- [x] Run one representative fresh-process exact replay and Studio-only Continue from this version. Validated exit finance and next rent timing; 15 accepted Beta hands select an Insider payout card, but the exact operating-income journal was **NOT RUN** as a separate assertion. Low-cash and existing-debt Beta cases did not arise legally in these worlds and are **NOT RUN**.
- [x] Write a dated finding with exact commands, hashes, PASS/FAIL/NOT RUN, failures, evidence, remaining unknowns and the next policy comparison. No implementation handoff or TODO entry follows from telemetry alone.

## Review focus

The world-policy callback can occur after a rival productive action but before `world.cycle` commits. Use the rival's `view.run_cycle` and finance report, not `world.cycle`, for dues. A full finance report is diagnostic data, not AI input. Avoid any call that advances RNG, mutates cash, or attempts another next-cycle preflight at this interim clock boundary.
