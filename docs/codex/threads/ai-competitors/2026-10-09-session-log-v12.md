# 2026-10-09 AI Competitors opening-gate reconciliation v12

**Scope:** documentation-only response to the user's report that the implementation thread awaits an opening-rule decision. This session records the current evidence and asks for the explicit revised ruling required by the earlier O4 stop gate. It does **not** select a new rule, implement gameplay, send a cross-thread message, commit or push.

## Source and worktree

- `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d` at intake. `TODO.md`, `CURRENT_STATE.md`, `DECISIONS.md` and the AI Competitors thread were already dirty; preserve unrelated implementation work and `.codex-godot-temp`. The separately dispatched implementation task and G1 failure were already recorded in current TODO/CURRENT_STATE.
- Read the [implementation findings](../../findings/ai-competitors-gates-v1/README.md) and [session log](../../logs/2026-10-09-ai-competitors-gates-v1.md), plus the local opening/foundation decisions and staged handoff. The implementation findings report two fresh-process legal 10.0 first releases, $840/no arrears, exact checkpoint roundtrip and 2,327 independent audit assertions. Those are **other-thread evidence**, not checks rerun here. No Drive reread.

## Documentation changed

- Added [G1 failure and options](2026-10-09-opening-g1-failure-options-v1.md). Recommendation A preserves strong legally played incumbents while allowing an exceptional player first game to tie or beat them. B requires proved legal 10.0 incumbent openings and permits ties. C retains strict superiority through a separately approved player-start/scoring rebalance. All remain **OPEN** pending user selection.
- Updated [README](README.md), [current handoff](HANDOFF.md), [working notes](working-notes.md), [foundation](2026-10-09-foundation-decision-v1.md), [opening decision](2026-10-09-opening-delegated-decisions-v1.md), [staged brief](2026-10-09-implementation-handoff-draft-v1.md) and [TODO authorization record](2026-10-09-todo-handoff-decision-v1.md) to show implementation dispatched, G1 failed and revised rule pending. Appended evidence status to [DECISIONS.md](../../DECISIONS.md). Did not edit TODO/CURRENT_STATE, which the implementation task already updated.

## Checks and next step

- PowerShell local Markdown link scan across the AI thread → `all AI thread local markdown targets exist`. `git diff --check -- docs/codex/DECISIONS.md` produced no diagnostics; the thread Markdown trailing-whitespace scan found none. No gameplay tests or balance search were run by this thread.
- Await the user's revised opening-rule choice. Then record one dated superseding decision and reconcile the handoff/TODO status; do not silently promote a recommended option or ask the implementation task to proceed while G1 is unresolved. G2–G5 remain separately OPEN; market effects on Reviews stay separate.
