# Production courses To Do List contribution — 2026-10-29

**User request:** add the designed Production Specialist courses to the internal To Do List. The task is now **QUEUED for coordinated candidate implementation**, not implemented or balance-approved. [Queue entry](../../TODO.md) points to the [source-pinned handoff](2026-10-29-production-courses-implementation-handoff-draft-v1.md). Matched affordability and final balance are retained as a separate later review, outside initial functional implementation acceptance.

**Repository state:** Branch `main`, inspected HEAD `f3e0f2b5d35270c879327bc297b389748571feb4`. The worktree already contained concurrent edits, including the shared TODO. Read `CURRENT_STATE.md` and `TODO.md` first, then the relevant Employees design, thread decisions and handoff; inspected branch, HEAD, status and targeted TODO diff. Re-read TODO immediately before the minimal insertion. Other queue entries and `.codex-godot-temp` were preserved.

**Files changed in this contribution:** `docs/codex/TODO.md`; current queue-status summaries in `CURRENT_STATE.md`, `DECISIONS.md`, `design/employees-courses.md`, this thread's `README.md` and `working-notes.md`; later-status headers in the two-course design, migration decision, Redraw UI decision and handoff; this dated log. No gameplay code, tests or simulator files were edited.

**Checks:** The new queue entry appears once at TODO line 3 and its handoff target exists. `git diff --check` on touched tracked docs: **PASS**. Three referenced Production design/handoff files exist with **zero trailing-whitespace findings**. Gameplay tests and simulations: **NOT RUN** for a documentation-only queue contribution. No Google Drive, commit or push.

**Next:** The implementing thread must repin source and use one nonoverlapping canonical gameplay slot. Functional acceptance covers course purchase/tracking, Pass choice UI, migration and payroll history, replay and cold restore. The separate balance gate remains OPEN.
