# Employee Research continues through the queued FIFO chain — 2026-10-26

**Later 2026-10-26 confirmation:** The affordable-prefix candidate under “Next accounting decision” was [selected by the user](2026-10-26-research-partial-affordability-decision-v1.md). That section records the question before confirmation; exact ledger integration remains OPEN.

## User decision

**LOCKED design, NOT IMPLEMENTED:** During one successfully committed active Feature Store Research action, apply the player's normal Research progress to the FIFO head first. Then apply eligible employee half-steps in order. Whenever a Feature completes, any remaining employee half-steps continue to the **next already queued Feature** in FIFO order, including a third or later queued Feature. Stop when staff steps or pre-existing queue entries run out. Do not auto-admit a new Feature or bank unused capacity. Each half-step charges its Store share **only when that step actually commits**; an unused step costs nothing. Ownership/child unlock occurs on completion, but newly owned Features join only future projects' supply. The game calendar advances by the Research action's one whole cycle.

This extends the [next-entry carry decision](2026-10-26-research-fifo-carry-decision-v1.md) after the user's “Yes” to the specific question about continuing into a third already queued Feature. The [selected taper](2026-10-26-research-taper-decision-v1.md) still limits the number of half-steps: the first two assigned employees each add one per eligible action; each later employee adds one every second eligible action. With two staff and two currently live one-cycle Features queued, one manual Research action could finish both if the combined unpaid installments and ordinary due bills are affordable. With additional staff and pre-queued entries, remaining steps can advance farther along the chain. This describes possible throughput, not a claim of affordable or implemented gameplay.

## Next accounting decision

**OPEN:** If the manual Research action and bills are affordable but the next optional employee half-step is not, decide whether to keep the manual action and stop the staff chain, or reject the whole action. A predictable candidate is to commit the affordable manual action and any earlier affordable staff steps, then stop before the first unaffordable step; never skip a FIFO entry, borrow from later same-cycle sales, charge an uncommitted step, or make cash negative. Exact preflight and atomicity must preserve ordinary rent → payroll → bank/education service, familiarity/Resourceful timing and current-bill rules. The preview must show the combined possible charge and the affordable stopping point.

Employee rank, every-second-action cadence through reassignment/Continue, exact-cent half-step splits, same-action Store discounts, transaction identities, UI and save migration remain OPEN. The player-facing Employees menu was separately [reopened after Game 2](../../logs/2026-10-26-employee-unlock-v1.md); employee Research remains unimplemented. The earlier dual-hire affordability failure remains evidence and is not reclassified as a pass. No shared To Do List contribution follows from this decision.

## Session record

Branch `main`, HEAD `087df09d653858b72c6e2dc344352237433dd3ac` at inspection. Read `CURRENT_STATE.md` and `TODO.md` first, then the current Store/Employee design, prior FIFO/taper decisions, local unlock log and targeted status/diff. Documentation only. Preserved concurrent worktree and `.codex-godot-temp`; no gameplay code, tests, simulator run, shared TODO edit, Google Drive, commit or push.
