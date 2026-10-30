# Project Manager priority ranges — design direction, 2026-10-28

**Later same-day tier/readiness ruling:** [Four sequential courses move each active slider bound by five points per completed challenge](2026-10-28-project-manager-tier-and-readiness-v1.md). Four-category planning reaches 0–60; two-category Beta stops at 20–80. The user carried standard trial tuition/wages and selected Design/Alpha/Beta hands for challenge progress. The exact-tier, course-count and phase OPEN statements below are historical; see the [draft implementation handoff](2026-10-28-project-manager-implementation-handoff-draft-v1.md).

**Later same-day course ruling:** [Buying a course unlocks its challenge but grants no immediate buff](2026-10-28-course-unlocks-challenge-decision-v1.md). Completing that challenge grants the next priority-range benefit.

**Later same-day count ruling:** [Four distinct games](2026-10-28-project-manager-four-games-decision-v1.md) are required per course level; the pair's exact qualification rules remain OPEN.

**Later same-day minimum ruling:** [Each actual Specialization must hit a category set to its legal minimum](2026-10-28-project-manager-minimum-priority-decision-v1.md); the two categories may differ. The remaining OPEN pair-qualification wording below is historical.

**Later same-day release ruling:** [Each of the four qualifying games counts at successful release](2026-10-28-project-manager-release-count-decision-v1.md), preventing abandoned-project course progress.

**Later same-day progression ruling:** [The challenge requirement stays identical at every course level](2026-10-28-project-manager-fixed-challenge-decision-v1.md). Lower legal floors supply the intended difficulty progression; exact tier values and course count remain OPEN.

**SELECTED DESIGN DIRECTION; numeric ranges are TRIAL CANDIDATES; NOT IMPLEMENTED.** The working employee name is **Project Manager**. This specialist would expand legal priority-allocation choices through courses rather than add Core score. The user wants the benefit across every priority screen: Pre-Development, Design, Alpha, Beta, Contracts and Specialist planning. Each purchased course unlocks its challenge; completing that challenge lowers the permitted minimum and raises the permitted maximum together, with later training eventually permitting a category at 0%. Course count, exact per-level ranges, price, wage effects and unlock timing remain OPEN. This is separate from the Production Specialist's hand-bundled priority change.

## Starting allocation direction

The user proposed a tighter starting **20% minimum / 40% maximum**. That is a feasible trial range for four active categories: `40/20/20/20` and `25/25/25/25` both total 100. With Insider temporarily held, Beta has only QA and Marketing active; two values capped at 40 cannot total 100. The user accepted the count-aware exception recommended in discussion: **Beta starts at a candidate 40%–60%** while it has two active categories. Its `50/50` default remains legal, and `60/40` is the proposed starting extreme. All plans retain five-point steps and an exact 100-point total. If Insider returns, the Beta baseline must be revisited rather than silently applying the two-category range to three active categories.

Current local `PriorityAllocation` and `BetaPriorityAllocation` source still uses 10% new-command minimum and 75% cap. The Insider hold makes ordinary Beta a two-category QA/Marketing choice. These proposed ranges would change no-hire planning as well as the employee benefit, so implementation would need separate matched balance and old-save checks. No live slider, validator, rival policy or save rule changed in this design note.

## Course challenge candidate

The user's repeatable challenge is **two actual Specializations in categories set to their screen's legal minimum, across four distinct released games per course level**. The two Specializations may use different categories, and ties at that legal minimum qualify. This is stricter than being merely the lowest category in a particular allocation. The requirement is identical at every level; the lower floor after each completed course challenge is the intended difficulty progression. Count each qualifying game only on its successful release. Use the committed priority snapshot for the hand that actually triggers each Specialization, rather than a later-edited slider; eligible phases/Contract hands, whether both events can occur in one hand, pre-course events and progress persistence still need rulings. A course/challenge should never award a free Core point, grant progress from a rejected hand or count a visual replay as an extra Specialization. [Four-game count](2026-10-28-project-manager-four-games-decision-v1.md); [legal-minimum ruling](2026-10-28-project-manager-minimum-priority-decision-v1.md); [release timing](2026-10-28-project-manager-release-count-decision-v1.md); [fixed requirement](2026-10-28-project-manager-fixed-challenge-decision-v1.md).

## Next design choices

1. Specify a short five-point-step tier table for four-category and two-category planning, including when each reaches a 0% minimum. A single flat increment cannot reach 0% in both groups at the same tier because their proposed baselines differ.
2. Define eligible phases/Contract hands, whether two actual Specializations in one hand can count, pre-course project events and progress reset for each newly purchased course. Different categories, ties at the legal minimum and release-time game credit are selected.
3. Later, source-pin the UI/validator/save/rival/balance handoff. Preserve historical committed distributions and the current temporary Insider hold.

## Session record

2026-10-28, branch `main`, HEAD `f3e0f2b5d35270c879327bc297b389748571feb4` at inspection. Read current local state and TODO first, then repository source rules, employee/core design and the current slider source; inspected branch, HEAD, status and relevant diff before edits. Added this thread note and updated this thread's README/working notes plus concise design-only summaries in `CURRENT_STATE.md`, `DECISIONS.md`, `design/core-and-studio.md` and `design/employees-courses.md`. Existing concurrent edits were preserved. Targeted `git diff --check` passed; this note has no trailing whitespace. No gameplay code, tests, simulation, Google Drive, commit or push. The shared TODO was already dirty but was not edited in this session.
