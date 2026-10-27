# Employee Research taper selected — 2026-10-26

**Later 2026-10-26 decision:** Employee half-steps may [carry to the next already queued FIFO Feature](2026-10-26-research-fifo-carry-decision-v1.md) when the active Research action completes the head. The OPEN-carry text below is this note's earlier state; further same-action cascade and accounting remain OPEN.

## User decision

**LOCKED design, NOT IMPLEMENTED:** The user accepted the proposed deterministic falloff. Only a successfully committed active Feature Store Research action can trigger employee research. Of the employees assigned to research, the first two each add **one paid half-step on every eligible action**. Each additional assigned employee adds **one paid half-step on every second eligible action while assigned**, an average of one quarter research-cycle per action. The Store timer may hold half-steps; the game calendar still advances in whole cycles. Charge a half-step only when that step actually commits. This is the [earlier candidate](2026-10-26-active-research-falloff-direction-v1.md) selected in the user's answer “Id say so” to the exact first-two/every-other-action proposal. The hard two-person effective cap remains an unselected alternative.

**Scope at this decision:** Shared research duty is available independent of specialty training. This selection changes neither the $1,000 per-employee trial wage nor challenge rewards. It does not establish a staffing cap or approve a live employee Research implementation. The menu was separately reopened later on 2026-10-26 at the user's direction; failed economic evidence remains on record.

## Next design boundary

The current Store's one paid Research action completes any live queued Feature. The selected boost has no use when only that one Feature is queued and cannot reduce the whole calendar cycle. The next decision is whether the employee half-steps **carry in FIFO order to other Features already queued before the action**. The [prior design note](2026-10-26-active-research-falloff-direction-v1.md) recommends such same-action carry, with no automatic admission, no saved unused capacity, exact preview/payment, and future-project-only supply. This carry rule is still **OPEN**.

Which employees receive the first two full-rate positions; how every-other-action cadence persists through reassignment, dismissal and save/Continue; whether a partially fundable boost can commit; exact familiarity/Resourceful timing; and same-action payment ordering remain **OPEN**. Do not infer them from the selected rate.

## Session record

Branch `main`, HEAD `087df09d653858b72c6e2dc344352237433dd3ac` at inspection. Read `CURRENT_STATE.md` and `TODO.md` first, then the thread's dated proposal, Store/Employee authority and targeted repository status/diff. This is documentation only; preserve concurrent work. No gameplay code, tests, simulator run, shared TODO, Drive, commit or push.
