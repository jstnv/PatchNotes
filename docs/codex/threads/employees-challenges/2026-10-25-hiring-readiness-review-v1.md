# Employee hiring readiness review — 2026-10-25

**Conclusion: not ready to reopen new player hiring.** This is a read-only status assessment, not a new design ruling or a request to change gameplay.

**Later same-day clarification:** the user's [economic readiness decision](2026-10-25-economic-readiness-decision-v1.md) supersedes the “define the first mid-game milestone” prerequisite in this review. Economic capacity for at least $1,000/month determines readiness for implementation review; the player-facing unlock remains a separate OPEN rule. The button-hold conclusion still stands.

## Current evidence

- The direct [2026-10-24 user hold](../../logs/2026-10-24-employee-button-hold-v1.md) is implemented: `patch-notes/scripts/phases/studio_phase.gd` sets the visible Employees button disabled with “Temporarily unavailable.” Its focused recorded check passed 11/11 assertions at both supported sizes, including pointer/Enter rejection and preserved saved state.
- The retained hire code in `run_state.gd`, `studio_finance_ledger.gd` and `employee_panel.gd` still offers one Production Specialist after a release for a $100 fee and **$10/month**. Existing employees, training, payroll, simulator commands and saves remain functional. The button hold is a player-entry block, not removal of existing employees.
- The [later user direction](2026-10-07-midgame-wage-direction-v1.md) instead places Employees at the beginning of the mid game with **$1,000/month starting pay**. Its exact unlock, fee and surrounding economic rules are OPEN; further employee work was deferred. At current $500 base rent, one $1,000 salary would produce $1,500 in scheduled rent and pay per month before Bank or education obligations. This arithmetic is not an affordability study.
- The current [Employees design](../../design/employees-courses.md) and [Store progression](../../design/feature-store-progression.md) have no selected mid-game employee gate. The older wage studies tested much smaller amounts and early-game hiring; they do not validate this later package. Future default employee contribution to Store research is a direction with exact mechanics OPEN.

## Disposition

Do not interpret the existence of a working internal hire transaction, successful old employee tests or a later-game cash-rich route as readiness to expose hiring. Keep the button hold until the user directs reopening. To establish economic readiness, test actual earned and settled portfolio income and other obligations against at least $1,000/month per employee, then price the hire and employee benefits and decide how prior $10 employees/saves transition. The player-facing hire rule remains separate and OPEN. Implement and verify the chosen package in a coordinated gameplay task only after the hold is lifted.

## Session record

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f` at inspection. Read CURRENT_STATE and TODO first, then repository conventions, the relevant design/decision/thread notes, the 2026-10-24 hold log and current UI/hire source. Inspected branch, HEAD, status and diff before this edit; the shared worktree was already heavily modified. Changed only this dated thread note. No gameplay, tests, shared TODO, Drive, commit or push. The recorded 11/11 check was reviewed, not rerun. Four local links checked with zero missing; zero trailing-whitespace lines. Scoped `git diff --check` passed for tracked thread files; this new untracked note received the separate whitespace check.
