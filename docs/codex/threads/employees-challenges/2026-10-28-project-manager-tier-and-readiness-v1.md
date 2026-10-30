# Project Manager tiers and implementation readiness — 2026-10-28

**Queue update, later 2026-10-28:** The user requested and received a [shared To Do List entry](../../TODO.md) pointing to the [implementation handoff](2026-10-28-project-manager-implementation-handoff-draft-v1.md). The original NOT QUEUED status below is historical; trial values and implementation acceptance remain unchanged.

**Status: selected design for a bounded playable trial; not implemented or queued.** The user selected a five-percentage-point decrease in the legal minimum and increase in the legal maximum on each **completed** Project Manager course challenge. There are **four sequential courses**. Purchasing a course unlocks only that level's tracker; it changes neither sliders nor wages immediately. The identical challenge is repeated at each level: two actual Specializations in categories at their screen's legal minimum within each of four distinct successfully released games. The two events may use different categories. Count committed Design, Alpha or Beta hands in that game; publisher Contract hands do not count toward training, although the earned benefit applies to Contract planning. This resolves the earlier OPEN course-count and eligible-phase questions.

## Trial range table

All values are percentage points. Four-category plans cover Pre-Development, Design, Alpha, Contracts and Specialist planning. Two-category Beta covers QA and Marketing while Insider is held at zero. Each active plan totals exactly 100 in five-point steps.

| Completed Project Manager challenges | Four-category min–max | Two-category Beta min–max | Monthly wage for this employee |
| --- | --- | --- | --- |
| 0 | 20–40 | 40–60 | $1,000 |
| 1 | 15–45 | 35–65 | $1,100 |
| 2 | 10–50 | 30–70 | $1,200 |
| 3 | 5–55 | 25–75 | $1,300 |
| 4 | 0–60 | 20–80 | $1,400 |

The no-hire baselines remain **trial candidates**, and the $5-point tier movement is the user's selected trial rule, not a final balance finding. Reaching 0% applies to four-category sliders; the user explicitly chose four courses, so active two-category Beta stops at 20%. The tighter no-hire ranges replace the current runtime's 10%–75% new-command limits in this candidate; historical saved allocations must retain their original facts and must not be silently reweighted. A future Insider return requires a separate three-category Beta range decision.

## Course and pay interpretation

“Keep standard course/wage” carries the existing employee/QA **ACTIVE/TRIAL** package into this new type: $100 confirmed zero-cycle hire after two released games, $1,000 monthly base wage, $150 per course, and a $100/month raise **when that course challenge completes**, once per level. Each prospective raise begins in the next expense month; issued payroll bills remain unchanged. Hiring follows the existing first-full-month payday and typed rent → payroll → bank recovery. These are trial numbers, not final affordability approval. Four courses cost $600 total tuition and add $400/month to one fully trained Project Manager's base wage. No purchase grants an immediate buff or raise.

## Derived implementation rules for the handoff

- One active Project Manager course level at a time. Enroll in level 1, finish its four-game challenge, then unlock purchase of level 2; otherwise the same four games could complete several courses at the old floor and defeat the user's progressive-difficulty intent.
- Credit a specialization only from a successfully committed, post-enrollment Design/Alpha/Beta hand, using that hand's committed priority distribution and its then-current legal floor. A display replay, rejected action or non-specialized hand contributes nothing. Each qualifying release gives at most one game credit to the active level; progress carries to later projects at that level, then a new level starts at zero.
- Keep the release's game/project identity and the two qualifying hand identities so Continue, duplicate callbacks and restored history cannot count again. Earlier hand events in a project or releases before enrollment do not count. The fourth qualifying release awards the tier once; it cannot be reused for the next course.

These rules are the direct implementation interpretation of the selected course-unlocks-challenge, fixed four-game requirement, release-only credit and progressively lower floor. They are recorded for review in the draft handoff, not silently treated as already implemented. The live runtime has separate `PriorityAllocation` and `BetaPriorityAllocation` validators plus screen-specific UI limits; the current constants are 10/75, with a historical saved 5% Core floor and disabled Insider at 0. Changing only the visible slider would not implement this design.

## Readiness and evidence boundary

The mechanics are now sufficiently specified for a **candidate implementation review**: ranges, level count, costs, raises, qualifying phases, release credit and save identity have concrete rules. The implementation must still prove that every player and rival planning path uses the trained bounds, that 0% Core distributions and old saves are valid, and that the tighter no-hire baseline does not break progression. Matched economic and specialization-frequency tests are acceptance evidence, not prior approval of final balance. No behavior test or simulation was run in this design thread.

Sources: [course-purchase ruling](2026-10-28-course-unlocks-challenge-decision-v1.md), [fixed challenge](2026-10-28-project-manager-fixed-challenge-decision-v1.md), [release credit](2026-10-28-project-manager-release-count-decision-v1.md), [existing QA course/pay package](2026-10-25-qa-courses-wages-direction-v1.md), `patch-notes/scripts/employees/qa_employee_rules.gd`, `patch-notes/scripts/phases/priority_allocation.gd`, and `patch-notes/scripts/phases/beta_priority_allocation.gd` inspected at HEAD `f3e0f2b5d35270c879327bc297b389748571feb4` on branch `main`. The worktree already contained concurrent edits. No Google Drive, gameplay code, tests, shared TODO, commit or push was changed for this note.
