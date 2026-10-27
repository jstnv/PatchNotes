# Active Research employee boost and falloff — 2026-10-26

**Later 2026-10-26 confirmation:** The user [selected the proposed first-two/every-other-action taper](2026-10-26-research-taper-decision-v1.md). The OPEN-curve and CANDIDATE-falloff labels below preserve this note's earlier design state; FIFO carry and transaction details remain OPEN.

**Later 2026-10-26 FIFO decision:** The user [selected carry to the next already queued Feature](2026-10-26-research-fifo-carry-decision-v1.md). The OPEN-FIFO labels below are historical; further cascade and transaction details remain OPEN.

## User correction and status

**LOCKED qualitative correction; NOT IMPLEMENTED:** Employees affect Feature Store research **only when the player successfully commits an active Store Research action**. The earlier plan to grant passive half-steps after unrelated productive actions is **SUPERSEDED**. Design, Alpha, Beta, Contract Search and other normal actions do not trigger employee research. The ordinary run clock stays in whole cycles. Every employee may take this shared research duty independently of specialty training. Store charges remain tied to research progress that actually commits, not merely to employing or assigning staff.

**USER-PREFERRED DIRECTION / OPEN curve:** Research boost should have diminishing marginal returns beyond two employees. The earlier first-two direction of one half research-cycle per employee per eligible action, stacking to one full research-cycle for two, remains the starting design premise. The third employee's precise contribution, later staffing limits, and whether contribution is deterministic are **not yet selected**. The $1,000 per-employee monthly wage and separate challenge benefits are unchanged by this design discussion.

## Current Store constraint

The [Store authority](../../design/feature-store-progression.md) and `patch-notes/scripts/run_state.gd` at lines 601–671 show an unlocked-only FIFO queue and a paid manual Research action. Every currently live later or post-start Primitive Feature has `actions: 1`, so the manual action already completes the head Feature in one whole productive cycle. An extra half-step applied only to that same head would be wasted. Staff cannot reduce the calendar clock to half cycles. This is a real design dependency: the boost has no present-day benefit with only one live one-cycle Feature queued unless the Store duration model changes.

**Candidate route for current nodes, not approved:** On a successful manual Research action, complete and charge the current FIFO head first. Then apply eligible employee half-steps, in stable employee order, to the next **already queued** FIFO entries. Each actual half-step pays its share of that entry's unpaid Research balance; ownership and child unlock occur only on completion, with new supply limited to future projects. Do not auto-admit or start an unqueued Feature, bank unused progress, or spend settlement income that arrives after the action. Preview the combined current-action cost and all Features that could finish before confirmation. If any contemplated employee step cannot be funded, the precise partial-versus-atomic behavior is **OPEN**; no negative cash or free progress is acceptable. Existing Store admission down payments and queue order remain intact.

**Candidate falloff for discussion, not approved:** The first two assigned employees each produce one paid half-step on every successful active Research action. Each additional employee produces one paid half-step on every **second** successful active Research action while assigned, for a long-run average of a quarter research-cycle per action. This preserves half-step progress and payment units without introducing quarter-cycle progress entries. A per-employee eligible-action counter would make the cadence deterministic, visible and saveable. An alternative is a hard two-person effective cap; it is simpler but makes a third research assignment provide no boost. Neither option is a selected rule. At zero discount on an already admitted $1,700 Feature, each of two half-steps would nominally charge $425 of its remaining $850; actual familiarity and Resourceful timing require their own exact-cent ruling.

## Decisions still needed before an implementation handoff

1. Confirm the falloff shape for employee three and beyond, including a useful staffing limit. Avoid presenting the candidate every-second-action rate as approved.
2. Decide whether staff may carry progress into the next already queued Feature during the same active Research action. With current one-cycle nodes, this determines whether the boost does anything at all.
3. Define the transaction order and affordability policy for a manual action plus multiple paid half-steps, including partial prior progress, rent/payroll due that cycle, same-action familiarity, Resourceful's final-installment saving, duplicate/rejected actions and FIFO completion.
4. Show the player the actual next-action cost and possible completions; persist employee assignment/cadence, half-progress, each exact payment and ownership through Continue. Do not imply a guaranteed draw in the current project.
5. Test whether the benefit justifies the selected $1,000+ monthly payroll using matched player careers with real earned/settled sales and next-game affordability. The existing failed dual-hire economic gate still holds; this design does not reopen Employees.

## Local session record

Branch `main`, HEAD `087df09d653858b72c6e2dc344352237433dd3ac` at inspection. Read current state and TODO first, then repository provenance, current Employee/Store design, the prior dated research direction, the live Research transaction, and targeted branch/status/diff. Existing concurrent worktree changes were preserved. This pass changes documentation only. No gameplay code, tests, simulator variant, shared TODO, Google Drive, commit or push.
