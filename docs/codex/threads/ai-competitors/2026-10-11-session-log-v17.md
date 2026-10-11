# AI Competitors session log v17 — 2026-10-11

## Checkout and scope

At start: `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`, heavily dirty shared checkout (78 tracked files with pre-existing changes plus many untracked artifacts). Inspected branch, HEAD, status and diff stat before edits. Preserved all existing edits and `.codex-godot-temp`. User authorized bounded headless experiments, private prototypes if needed, thread documentation and a TODO handoff; prohibited computer control, canonical gameplay edits, commit and push. No private simulator variant was needed because the chosen question used existing behavior and an existing test policy. No canonical gameplay file, native window or player save was touched.

## Work and changed files

- Recorded [G2 study plan](2026-10-11-g2-envelope-study-plan-v1.md) and [prefix configuration](2026-10-11-g2-envelope-prefix-v1.json) before running.
- Added [checkpoint-to-arms materializer](prepare_g2_envelope_v1.py) and generated [six-arm input](2026-10-11-g2-envelope-arms-v1.json) from legal saved Studio envelopes. Both source-pinned run folders, four comparison folders and two replay folders are under this thread's `sims/` only.
- Added [finding](2026-10-11-g2-envelope-finding-v1.md) and [DESIGN review handoff](handoffs/2026-10-11-g2-envelope-design-review-v1.md); updated this thread's `README.md`, `working-notes.md`, `HANDOFF.md`, and one additive paragraph in shared `docs/codex/TODO.md` after rereading it. No decision record converted an OPEN number into LOCKED or ACTIVE/TRIAL.

## Exact checks and results

All commands and binary identities are in the [finding](2026-10-11-g2-envelope-finding-v1.md). `simulate.py run` prefix: **2/2 completed**, 18 commands and cycle 7 each, Studio checkpoints emitted. `simulate.py run` next-project arms: **6/6 completed**, 16/18/20 commands at 1/1, 2/2, 3/3 hands, release at cycles 12/14/16 for both seeds. Within-seed initial state/RNG and source identities matched across all arms. `compare_simulations.py`: **4/4 succeeded**, all complete, telemetry/source checks accepted. `simulate.py replay`: **2/2 succeeded** in fresh profiles (4417 3/3: 20 steps, 21 telemetry samples; 90210 1/1: 16 steps, 17 samples); exact final state and telemetry verified. No rejection, incomplete run, timeout or finance blocker. Failure reduction was not applicable. All six releases were legal under Scope 30 and returned to Studio.

The exact result table, money/calendar comparison caveats and links to raw run reports/tapes are in the finding. This is limited observed-route evidence for a finite hand envelope. It does not test an exhaustive jointly attainable planner, Store candidate, rival world, Fanbase consequences or market Review effects.

## Blockers and next work

G2 still needs a configurable legal-mix search with declared cash allocation after known dues and measured CPU bound; the hand count remains OPEN. G3 exact due snapshot and F6 prerequisite dead-end study depend on that planner. The handoff asks for a new private variant and a future adoption packet only once a concrete candidate, source delta and matched evidence exist. G1a, G4 and G5 remain separately OPEN. TODO marks DESIGN review needed, not QUEUED implementation. No commit or push was made.
