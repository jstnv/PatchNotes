# Employee Research FIFO carry selected — 2026-10-26

**Later 2026-10-26 extension:** The user [selected continued FIFO carry through third and later already queued Features](2026-10-26-research-fifo-chain-decision-v1.md). The OPEN-cascade text below records this note's earlier state; affordability and transaction integration remain OPEN.

## User decision and boundary

**LOCKED design, NOT IMPLEMENTED:** After a successfully committed active Feature Store Research action finishes the current FIFO head, eligible employee half-steps may advance the **next Feature that was already queued before that action**. Resolve the head first, then the employee work in FIFO order. Each half-step pays its unpaid Store share only when it actually commits. If there is no next queued Feature, the surplus boost grants no progress and costs nothing. The action still advances one whole game cycle; the boost does not admit a Feature, change queue order, or put an owned Feature into the current project's draw pool.

This selects the [same-action carry proposal](2026-10-26-active-research-falloff-direction-v1.md) in the user's answer “Yes, it should” to the question of carrying staff progress into the next already queued Feature. The [selected taper](2026-10-26-research-taper-decision-v1.md) remains: the first two assigned employees add one half-step each per active Research action, and each later assigned employee adds one half-step every second eligible action. At zero discount, a current $1,700 Feature already admitted for $850 has $850 left; two employee half-steps could complete that second queued Feature for $425 plus $425 during the same action that completes the head. The manual head's own installment, any bills and other due costs remain additional. This example is arithmetic, not a new price or affordability approval.

**OPEN:** If staff steps remain after that second queued Feature finishes, whether they continue to a third and later already queued Feature in the same action is not yet ruled. This matters for the third-and-later employee taper while every live Feature still needs only one Research action. Also open are all-step versus partial affordability, exact discount/Resourceful ordering, employee rank/cadence persistence, and the combined quote/Continue schema. A rejected or unaffordable step must never create free progress or negative cash.

## Current implementation and session boundary

The player-facing Employees menu was separately [reopened after Game 2](../../logs/2026-10-26-employee-unlock-v1.md) under the existing ACTIVE/TRIAL QA, course and payroll package. Employee Research is still unimplemented. The earlier failed dual-hire economic result remains evidence; reopening did not prove affordability. This design decision changes no live Store action or To Do List entry.

Branch `main`, HEAD `087df09d653858b72c6e2dc344352237433dd3ac` at inspection. Read `CURRENT_STATE.md` and `TODO.md` first, then the relevant Employee/Store authority, prior taper note, current unlock log and targeted branch/status/diff. Documentation only; preserve concurrent worktree changes. No gameplay code, tests, simulator run, shared TODO edit, Drive, commit or push.
