# Banking checkpoint and export TODO handoff

2026-10-07 (America/Los_Angeles). The user asked to update the shared To Do List for the next Banking follow-up.

## Repository state and scope

- `main` at `b84d1a5b4e4957b044b4b52c41553cf611aff3ae` when inspected. The worktree already contained concurrent implementation and documentation edits; all were preserved. No gameplay edit, commit or push in this Banking design thread.
- Read `CURRENT_STATE.md`, the current `TODO.md`, `design/release-engineering.md`, [checkpoint foundation](../../findings/2026-10-07-checkpoint-foundation-v1.md) and [Banking state mapping](2026-10-07-save-mapping-v1.md). Inspected branch, HEAD, status and the preexisting TODO diff before editing.

## Change

- Added Banking-specific restore acceptance to the existing Task10 checkpoint follow-up in [TODO.md](../../TODO.md): lossless schema5/Bank1 state, committed-Studio separate-process restart, installment and partial recovery history, payoff closure, mid-phase rollback and corrupt-state recovery.
- Added an exported interactive Bank/Continue route to existing Task11 after Task10 integration. It covers quote/accept, checkpoint, exit/Continue, installment, payoff and second-game continuation with finance reconciliation.
- Kept B3–B5 complete locally and kept full checkpoint integration and exported interaction unverified. No new loan economics or duplicate Banking implementation task was added.

## Checks and follow-up

- Local Markdown links resolved, and `git diff --check -- docs/codex/TODO.md docs/codex/threads/banking-system/` returned no whitespace errors. No runtime tests were run because only task wording changed.
- The implementing thread owns Task10 completion, then Task11 exported interaction. Report exact separate-process and exported evidence before changing those statuses.
