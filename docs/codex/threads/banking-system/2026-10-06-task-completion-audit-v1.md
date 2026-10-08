# Banking B3–B5 completion audit

**SUPERSEDED by the [2026-10-07 recheck](2026-10-07-task-completion-recheck-v1.md).** This audit described `main` at `553d1a4` before the overnight Banking implementation. B3–B5 are now marked complete locally on the later worktree; retain the observations below only as historical state.

2026-10-06 (America/Los_Angeles). Read-only check of the user's question whether the Banking tasks are done.

## Repository state

- Branch `main`, HEAD `553d1a46f33d59641efa4c2e4ff141f958c1230d` (`origin/main` locally points to the same commit). The worktree contains concurrent documentation/analysis changes, including the Banking TODO handoff; no gameplay scripts are modified in this checkout. No fetch, commit, push or implementation in this audit.
- Read `docs/codex/CURRENT_STATE.md` and `docs/codex/TODO.md` first, then the Banking handoff, relevant logs and current scripts. Inspected branch, HEAD, status, diff and local worktrees. The only registered local Git worktree is this `main` checkout; the other listed branch is Fanbase, not Banking. The separate `PN Implementation` task's recent work is on Employees/Challenges, not Banking.

## Acceptance check

| Slice | Current evidence | Result |
|---|---|---|
| B3 loan domain and finance | `patch-notes/scripts/run_state.gd` has no loan quote, issuance, schedule or payoff API; no loan script exists under `patch-notes/scripts`. `outstanding_expenses.gd` defines the `bank_installment` type and prototype credit weights, but no live producer. | **Not done.** Typed expense support is foundation only. |
| B4 Bank UI | `patch-notes/scripts/ui/studio_finances.gd:116` says loans are unavailable. The Bank page contains credit history, with no amount/term controls, offer acceptance or payoff controls. | **Not done.** Navigation/history exists. |
| B5 focused verification and save mapping | Existing `verify_studio_finances.gd` checks Bank history/navigation. `verify_outstanding_expenses.gd` constructs a synthetic bank bill. No live loan lifecycle verifier or versioned loan mapping was found. Durable Studio checkpoint/Continue remains absent in current state. | **Not done.** Some finance/typed-bill checks predate lending. |

## Exact checks and limits

- `rg -n -i 'bank_installment|loan|borrow|payoff|bank_page|bank_button' patch-notes/scripts --glob '*.gd'` found only the typed bill hooks, generic ledger comment, inactive Student Loan preview and the Bank history/unavailable copy; no lending API.
- `rg -n 'func .*loan|func .*bank|func .*payoff|bank_installment' patch-notes/scripts/run_state.gd` returned no matches. `rg --files patch-notes/scripts | rg -i 'bank|loan'` returned no dedicated lending files.
- `git branch -a`, `git worktree list --porcelain`, `git log -8 --oneline --decorate`, and `git status --short` confirmed the current checkout and no local Banking implementation branch or modified gameplay scripts. No remote fetch was performed; an unobserved external checkout cannot be ruled out.
- No runtime tests were run: the source has no loan issuance or payoff path to exercise, and the existing finance verifiers cover foundation behavior rather than B3–B5 acceptance. This is a current-checkout completion audit, not a release gate.

## Follow-up

Keep B3–B5 **QUEUED** in the shared TODO. The next implementing step is B3's exact amount/term input and payment calculation specification, followed by the loan domain, UI and verification in their recorded order. Preserve the concurrent worktree changes.
