# Employees/Challenges working notes

Status: **OPEN discussion**, started 2026-10-06 (America/Los_Angeles). This file approves no new gameplay or numerical values.

## Established baseline

- **LOCKED:** Specialists belong to the Studio; completing a challenge grants an immediate permanent employee-owned benefit. Temporary effects, if used, need an explicit project or productive-cycle scope.
- **LOCKED:** The Production challenge triggers once per employee/project on a successfully committed Design hand containing a Core Pass and a Feature matching the Pass's printed primary or secondary Core stat. Failed or unaffordable actions and duplicate callbacks grant nothing.
- **OBSERVED:** No employee, challenge, course, hiring, or payroll runtime is implemented. Typed payroll policy exists only as an inactive finance hook.
- **OPEN:** Benefits, other challenge triggers, hiring and dismissal, courses, salaries, raises, payment timing, stacking, and insufficient-cash recovery.

The [system design](../../design/employees-courses.md) contains the candidate Production, Planning, QA/Marketing, and Contract paths. Tasks 8, 16, and 18 are completed read-only studies, not approved implementations. Historical salary and course comparisons used a different rent baseline; new economic decisions must use current $500 rent, actual settled portfolio cash, and productive-cycle opportunity cost.

## Questions for this thread

1. Which specialist/challenge paths belong in the first playable employee system, and what player choices should they create?
2. What immediate permanent benefit does each completed challenge grant? When can it first be used, how often, and how does it interact with shared redraws and other specialists?
3. What are the hire, dismissal, rehire, course, and payroll rules, including exact payment boundaries and recovery when cash is insufficient?
4. What must the Studio and phase UI show for employee ownership, challenge progress, earned benefits, costs, and obligations?
5. What focused behavior and economic checks will establish that the rules work across multiple projects and overlapping releases?

## Decision record

| Date | Topic | Status | Ruling / evidence | Design update |
|---|---|---|---|---|
| 2026-10-06 | Thread setup | OPEN | Existing locked architecture and Production trigger are the baseline; rewards and economics remain open. | No new ruling |
| 2026-10-06 | Wage direction and pass-off | ACTIVE/TRIAL planning value / OPEN final wage | Drive design archive records $10 per in-game month as interim Production Specialist planning pay. Later lifespan authority preserves its interim status. User directs a wage revisit after economy polish. | [Design note](2026-10-06-design-note-v1.md); [source reconciliation](2026-10-06-drive-passoff-reconciliation-v1.md); no final numerical lock |

## Shared TODO contribution

The user prompted a contribution on 2026-10-06. Stage A of the [handoff](2026-10-06-implementing-thread-draft-v1.md) is now a [QUEUED read-only follow-up](../../TODO.md) to Tasks 8/16/18. Stage B remains a draft that requires explicit reward, hiring, payroll and course rulings before implementation. Record further candidate tasks here as decisions settle, with source revision, dependencies, exact behavior, UI implications and acceptance checks.
