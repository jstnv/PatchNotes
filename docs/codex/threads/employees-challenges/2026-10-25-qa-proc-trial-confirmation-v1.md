# QA Feature replay Bug-search trial — 2026-10-25

## User choice and status

The user selected **25% per qualifying Feature synergy re-trigger** as the QA Bug-search trial chance. This confirms the value already delegated and implemented in the isolated employee trial; it is **ACTIVE/TRIAL**, not a final balance value or approval to expose Employees in normal play.

After the mixed Search/Debug challenge is complete, each eligible Feature's individual specialization replay in Design or Alpha gets one 25% roll. A success can discover **at most one actual Hidden Bug**. Ordinary Feature plays, Pass replays and Balanced hands do not qualify. Design successes wait for ordinary Bug generation and are capped by real generated Hidden Bugs; Alpha searches its existing Hidden pool in the current trial. Multiple trained QA employees and future synergy types remain outside this first slice.

## Evidence and remaining gate

The current isolated trial has `PROC_PERCENT := 25` in `patch-notes/scripts/employees/qa_employee_rules.gd`, records `chance_percent` and a rules version on QA proc events, and has source-pinned mechanics checks in [QA employee findings](../../findings/qa-employees-20261025-v1/README.md). The current implementation evidence reports that normal Employees remains disabled: the matched dual-hire route fails the recurring $1,000-per-employee affordability gate. This answer settles the proc trial percentage only. Final proc balance, normal exposure and the separate passive Store research design remain open.

## Local reconciliation

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f` at inspection. Read CURRENT_STATE, TODO, Employees design, the QA handoff and local implementation finding; inspected source, status and targeted diff. Reconciled `CURRENT_STATE.md`, `TODO.md`, `DECISIONS.md`, `design/employees-courses.md`, this thread's `README.md` and `working-notes.md`, and the dated QA course, handoff, TODO-contribution and synergy-search notes. The existing shared edits were preserved. No Google Drive, gameplay/test edit, simulator run, commit or push.

Documentation check: targeted tracked-document `git diff --check` passed; this note has no trailing whitespace and its local evidence link resolves. No gameplay behavior was rerun for this documentation-only reconciliation. Follow-up: keep normal Employees disabled until a new source-pinned matched study passes the dual-hire wage gate; retain 25% as a trial rate until balance review.
