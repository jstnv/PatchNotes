# Employee Research partial affordability — 2026-10-26

## User decision

**LOCKED design, NOT IMPLEMENTED:** If a Store Research action's manual progress and required due bills are affordable, commit that action even when the player cannot afford every optional employee half-step. Resolve eligible staff steps in their established order across Features queued before the action, moving through that queue in FIFO order. Commit and charge each affordable half-step. Stop before the **first unaffordable** half-step; do not skip it or a queued Feature to reach cheaper later work. Uncommitted steps make no progress and incur no Store charge. The Research action still advances the calendar by one whole productive cycle.

If the manual Research action or its required due bills fail the existing preflight, reject the action normally and grant no employee progress. Do not let cash go negative or use sales that settle later in the same cycle to fund a current installment. This extends the [selected FIFO chain](2026-10-26-research-fifo-chain-decision-v1.md) and the user's direct confirmation of its proposed affordable-prefix rule.

## Accounting boundary and example

The implementation must quote the mandatory manual action and due bills separately from the maximum possible employee charges, then show the affordable stopping point before confirmation. For example, if the manual installment and due bills are affordable, the first staff half-step costs $200 and is affordable, and the next costs $200 but is not, the action and first staff step commit; the second and all later staff steps do not. These amounts illustrate the sequence, not a price decision.

The existing half-base down payment, current familiarity discount, Resourceful installment rule, scheduled bill service, ownership on completion and future-project supply boundary remain in force. **OPEN:** exact ledger/preflight ordering and quote timing for manual and staff installments versus rent, payroll, Bank/education and sales settlement; exact-cent half-step split; same-action discounts; transaction identities; rank/cadence through reassignment and Continue; UI and save migration. The already selected first-two/full-step and later/every-other-action taper is unchanged. Employee Research remains unimplemented. The Employees menu was [reopened after Game 2](../../logs/2026-10-26-employee-unlock-v1.md) under its existing ACTIVE/TRIAL rules; the old dual-hire affordability failure remains evidence, not an employee-Research acceptance result.

## Session record

Branch `main`, HEAD `087df09d653858b72c6e2dc344352237433dd3ac` at inspection on 2026-10-26. Read `CURRENT_STATE.md` and `TODO.md` first, then the relevant local design, prior taper/FIFO records and targeted Git status/diff. Documentation only; no gameplay code, tests, simulator, shared TODO, Google Drive, commit or push. Concurrent worktree edits and `.codex-godot-temp` preserved.

Changed files: this note; this thread's `README.md`, `working-notes.md` and prior FIFO-chain note; `docs/codex/CURRENT_STATE.md`, `DECISIONS.md`, `design/employees-courses.md` and `design/feature-store-progression.md`. Check: targeted `git diff --check` passed on the updated tracked documentation; no gameplay checks were run for this design-only decision. `TODO.md` remains modified by a concurrent thread and was not edited here. Follow-up: settle exact payment/preflight ordering and employee cadence persistence before an implementation handoff.
