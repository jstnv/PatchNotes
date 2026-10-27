# Employee-assisted Feature research — 2026-10-25

**SUPERSEDED in part on 2026-10-26:** The later [active Research correction](2026-10-26-active-research-falloff-direction-v1.md) limits employee progress to successfully committed Store Research actions. The passive progress after unrelated productive actions described below is historical. Shared duty, whole calendar cycles and payment on actual progress remain selected; falloff beyond two employees is directed but its curve remains OPEN.

## Selected direction

**LOCKED qualitative design; NOT IMPLEMENTED.** The user resumed Employees design and selected these rules:

1. An employee assigned to Feature Store research contributes a **guaranteed half research-cycle** of progress after each successful normal productive cycle. This is passive progress while the player uses that cycle for another action. The existing direction assigns employees to research by default.
2. Multiple assigned employees' contributions **stack**: two employees supply one full research-cycle of progress during one productive cycle.
3. Half units belong to the **Store research timer only**. The run calendar, sales, rent, payroll and other productive actions still advance in whole cycles.
4. Charge the unpaid Store research share **when each half-step actually progresses**. Hiring or assignment alone does not charge an installment, and a step that does not occur charges nothing.
5. **Every employee** can take this shared Feature Store research duty. Completing that employee's specialty challenge unlocks a separate specialty benefit; research progress is not gated behind specialty training.

This is a universal research duty selected by the user, separate from the Production Specialist's challenge and optional planning benefit. It does not add Core score. The $1,000 **minimum base monthly wage per employee** and economic-readiness proof remain the [separate gate](2026-10-25-economic-readiness-decision-v1.md). The visible Employees button stays disabled; no gameplay adoption follows from this note.

## Current Store boundary and design consequence

The implemented Store has an unlocked-only FIFO queue, zero-cycle half-base down payment, one paid manual Research action per currently live later/post-start Primitive Feature, and ownership/future-project supply only at completion. Ordinary actions outside the Store currently give no progress. The current `FeatureResearch` ledger records whole action payments, not a saved half-progress quantity; `RunState` admits live entries with `actions: 1`, and manual Research commits a paid action plus one full run cycle. Its validator also requires successive payments to have strictly increasing run cycles, while two employees would need two paid half-steps in the **same** cycle. Thus passive half-steps need distinct saved progress and exact same-cycle payment provenance; changing a displayed duration alone would be insufficient.

For a current one-cycle Feature, model the required work as **two half units**. One assigned employee reaches that amount after two committed productive cycles; two employees reach it after one. The manual Research button still uses one whole productive cycle in current gameplay. Its interaction with employee progress is an OPEN design choice.

## Accounting example — candidate, not approved amounts

The current ACTIVE/TRIAL $1,700 Alpha Store pack admits for $850 and leaves $850 unpaid before discounts. A **candidate** exact-cent split across two employee half-steps is $425 then $425, each charged only if that step commits, with the then-valid familiarity discount applied to that step. For an odd-cent remainder, assign the extra cent to the last half-step. This preserves the existing base cost at zero discount; actual discount timing and Resourceful's final-installment effect still need a ruling. It does not invent a second $850 charge.

At the minimum wage floor, one employee costs at least $1,000 per in-game month and two cost at least $2,000, before the current $500 monthly rent and any Store installments, Bank or education obligations. With two productive cycles per month, the example yields at most one current one-cycle Feature per month per continuously assigned employee before payment pauses, queue gaps and other limits. This is arithmetic to frame an economic test, not a finding that the economy can afford it.

## Candidate integration rules for review

- Apply employee half-steps only to the eligible FIFO head, then move to another **already queued** item if work remains after completing the head. Never bank unused capacity when the queue is empty. This preserves the selected queue order; same-cycle spillover is still OPEN.
- If the next step cannot be paid from cash legally available for that action, skip that step and its charge while letting the unrelated productive action proceed. Do not draw on sales that will settle later in that cycle. Exact precedence among direct action costs, new familiarity, employee installments and monthly bills is OPEN.
- Do not grant ownership, child prerequisites or current-project card supply on a single half-step unless that step completes the node. Continue to grant new supply only to later projects.
- Record each completed half-step, its responsible employee, source cycle, nominal share, discount, paid cents and any completion as one reconstructible transaction. Rejected/duplicate actions must preserve cash, progress, calendar and RNG. The exact checkpoint schema and migration path are OPEN.

## Open decisions and evidence gate

1. Does an assigned employee contribute during a manual Store Research action, and how do both contributions combine without double payment or an unintended extra calendar cycle?
2. How are the remaining acquisition cents split for future multi-cycle nodes, and how do familiarity/Resourceful changes apply to each half-step?
3. What happens to an unaffordable step, and how do two employees split progress when only one step is affordable? What happens to extra contributions at a FIFO completion boundary?
4. How can assignments change, and do training, courses, absence, dismissal or payroll arrears affect research eligibility? The earlier default-to-research direction alone does not answer these.
5. What exact UI shows half-step progress, next conditional charge and completion timing without implying a guaranteed draw or affordable finish?
6. Before employee implementation review, compare no-hire, one-hire and two-hire routes at the same monthly boundaries. Include short/long first games, overlapping titles, earned versus settled sales, rent/payroll/other bills, Store payments, cash low points, owned Features and next-project affordability. The older $10–$75 wage comparisons do not answer this $1,000+ case.

## Session record

Branch `main`, HEAD `0132c4dab398a2a94dbeae3caa68a36505fbfa4f` at inspection. Read CURRENT_STATE and TODO first, then relevant Employees/Store/economy design and source, thread notes and the prior dated decision. Inspected branch, HEAD, worktree status and targeted diff before edits; existing concurrent changes were preserved. Changed this dated thread note, thread README/working notes, Employees/Store design, DECISIONS and CURRENT_STATE. Targeted tracked-document `git diff --check` passed; the new dated note has zero trailing-whitespace lines, and all 417 local links in the seven touched documents resolve. No gameplay code or test edits, simulator variant, shared TODO, Drive, commit or push.
