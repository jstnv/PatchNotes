# AI Competitors G4 hand-envelope session — 2026-10-11

## Checkout and scope

`main` at `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, dirty shared worktree before and after. Inspected branch, HEAD, status and diff; `git diff --name-only -- patch-notes` returned no canonical gameplay paths. Preserved all existing edits and `.codex-godot-temp`; no computer control, commit or push. Read current state/TODO, repository guidance, simulator usage/variant contract and relevant AI Competitors findings before the run. Item 22 still reads DESIGN review needed with G4 numbers OPEN.

## This session's changes

- Added [predeclared plan](2026-10-11-g4-hand-envelope-plan-v1.md), [12-case config](2026-10-11-g4-hand-envelope-v1.json), [source-pinned audit script](2026-10-11-g4-hand-envelope-audit-v1.py) and [finding](2026-10-11-g4-hand-envelope-finding-v1.md).
- Added isolated [run](sims/g4-hand-envelope-v1/run-report.json), [audit](sims/g4-hand-envelope-audit-v1.json), [medium replay](sims/g4-hand-envelope-replay-action-medium-4417-v1/replay-report.json) and [long replay](sims/g4-hand-envelope-replay-adventure-long-90210-v1/replay-report.json). All outputs are new folders; unchanged private variant `simulators/g1a-cohort-current-v1` retains its original baseline/ancestry.
- Updated only this thread's README/working notes and a concise high-level entry in `CURRENT_STATE.md`. `TODO.md`, `DECISIONS.md` and canonical `patch-notes/` gameplay were not edited by this session.

## Exact checks and results

Commands and full paths are in the [finding](2026-10-11-g4-hand-envelope-finding-v1.md#exact-commands) and retained `*.command.json` bundles. `tools/simulate.py run --variant ...g1a-cohort-current-v1 --config ...g4-hand-envelope-v1.json --output ...g4-hand-envelope-v1 --timeout 240` completed all 12/12 independent cases. Both declared fresh-process `tools/simulate.py replay` commands passed: Action medium 22 recorded commands/23 telemetry samples and Adventure long 26 commands/27 samples, with exact state/tape and telemetry verification. `2026-10-11-g4-hand-envelope-audit-v1.py` passed 8/8 checks for declared cases, equal initial state/RNG, legal opening, no rejection, Studio release, nonnegative cash/no arrears, frozen archive separation and same archive within each triple. `python -m py_compile` passed for the auditor; JSON/config audit found 12 unique cases and a passed report. No rejected, incomplete or timed-out gameplay case occurred. The source/input hashes and Review/cash table are in the finding.

## Decision boundary and follow-up

The 5/7/3 test fixture reaches higher Reviews but gives up five cycles and leaves $1,300–$1,480 at release; its lowest sampled transaction cash is $800. Keep exact hands, resource reserves, card ranking/redraw/exit policy, G1a cohort, shared world and CPU limits **OPEN**. The next G4 screen should create a new private version for a deterministic legal phase-local choice and cash-aware exit policy, compare with this frozen fixture on matched legal openings, and assess second-project viability. This session supplies no approved adoption delta, so it does not change the existing TODO item or create an implementation adoption packet.
