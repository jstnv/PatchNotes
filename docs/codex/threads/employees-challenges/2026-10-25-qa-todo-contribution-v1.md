# QA implementation TODO contribution — 2026-10-25

## User request and scope

The user directed an internal TODO update for QA implementation, a course-purchase menu that enables challenge trackers, a $1,000 monthly employee starting wage, and $100 wage increases from each of QA's first two challenges. Follow-up choices set **one $150 course per challenge**, QA and Production hiring after Game 2 for a $100 fee each, and the $1,000 base for all employee types. The [dated direction](2026-10-25-qa-courses-wages-direction-v1.md) and [implementation handoff](2026-10-25-qa-implementation-handoff-v1.md) are stored in this thread folder.

## Repository contribution

Added one concise QUEUED implementation entry near the top of `docs/codex/TODO.md`, pointing to the handoff. Updated that file's historical Employees-button and design-package summaries to recognize the later instruction while retaining the current disabled/$10 source status. Updated `docs/codex/design/employees-courses.md`, `docs/codex/DECISIONS.md`, `docs/codex/CURRENT_STATE.md`, and this thread's README/working notes with selected versus still-open status. No gameplay, tests, simulations or Google Drive were changed.

## Source state, checks and follow-up

Inspected branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f`, status and targeted diff before editing. The worktree was already extensively modified. `docs/codex/TODO.md` had a `240/27` numstat diff before this contribution and `243/28` afterward; existing unrelated content was preserved. Targeted `git diff --check` passed on TODO, CURRENT_STATE, DECISIONS, Employees design and thread index/working notes. Both new dated thread notes have no trailing whitespace; their links from the queue resolve. No gameplay verification was run because this turn only prepared documentation and a queue entry. No commit or push.

**Later reconciliation, 2026-10-25:** The user confirmed 25% per qualifying Feature re-trigger as an ACTIVE/TRIAL QA search chance, with at most one actual Hidden Bug per successful roll. The isolated mechanics now use that value; the dual-hire affordability gate failed and normal Employees remains disabled. See the [proc confirmation](2026-10-25-qa-proc-trial-confirmation-v1.md) and [implementation finding](../../findings/qa-employees-20261025-v1/README.md). This original TODO contribution is a historical queue record, not a claim of passed economics, final balance or release readiness.
