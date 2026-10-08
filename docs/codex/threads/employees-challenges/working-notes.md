# Employees/Challenges working notes

Started 2026-10-06 (America/Los_Angeles). **Status updated 2026-10-07:** the bounded comparison and first Production implementation are COMPLETE locally; the user-approved rules remain ACTIVE/TRIAL. Approval comes from the [user trial ruling](2026-10-06-trial-package-decision-v1.md); completion evidence is in the [implementation findings](../../findings/2026-10-07-employees-implementation-v1.md).

## Established baseline

- **LOCKED:** Specialists belong to the Studio; completing a challenge grants an immediate permanent employee-owned benefit. Temporary effects, if used, need an explicit project or productive-cycle scope.
- **LOCKED:** The Production challenge triggers once per employee/project on a successfully committed Design hand containing a Core Pass and a Feature matching the Pass's printed primary or secondary Core stat. Failed or unaffordable actions and duplicate callbacks grant nothing.
- **OBSERVED:** One Production Specialist, hiring, challenge training, optional bundled planning and typed payroll are implemented locally. Courses and additional staff are absent. Durable disk restart proof belongs to the separate checkpoint task.
- **ACTIVE/TRIAL current runtime:** One Production Specialist after Game 1, $100/zero-cycle hiring, optional bundled planning, temporary $10/month, first-full-month payday, and original-due partial recovery ordered rent → payroll → bank. Future course availability/timing was approved separately from its effects and amounts; see the [trial ruling](2026-10-06-trial-package-decision-v1.md).
- **USER DIRECTION / DEFERRED:** Future Employees enter at the beginning of the mid game with $1,000/month starting pay. This supersedes the current slice as the intended timing/pay package without changing that runtime. [Dated direction](2026-10-07-midgame-wage-direction-v1.md).
- **OPEN:** Exact mid-game unlock, other specialist benefits/triggers/pay, broader staffing/stacking, dismissal/rehire, course effects, tuition and raise amounts.

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
| 2026-10-06 | Bounded comparison | COMPLETE read-only | 84 native-action routes, 56,928 financial sensitivities and 50 exact finance reconciliations. Findings are evidence, not approval. | [Findings](2026-10-06-benefit-payroll-comparison-v1.md); [reproduction](comparison-v1/README.md) |
| 2026-10-06 | First Production package | ACTIVE/TRIAL; queued at approval, since completed locally | User answered “Approve the trial package.” Reward, hiring, first payday and recovery prerequisites were satisfied for the first slice. Final wages and course effects/amounts remain OPEN. | [Approval](2026-10-06-trial-package-decision-v1.md); [separate implementation task](2026-10-06-production-specialist-implementation-v1.md) |
| 2026-10-07 | First Production implementation | COMPLETE locally; rules remain ACTIVE/TRIAL | One playable Specialist, hiring, training, optional planning and typed payroll passed 70 maintained suites and a legal three-release route. No disk restart, commit or push is claimed. | [Findings](../../findings/2026-10-07-employees-implementation-v1.md); [status update](2026-10-07-status-update-v1.md) |
| 2026-10-07 | Wage tuning | SUPERSEDED candidate | $50/month was the proposed next trial; the current-source screen found low-cash downside and the user later rejected $50 as far too low for the intended stage. Live $10 remains a prototype value only. | [Wage proposal](2026-10-07-wage-tuning-proposal-v1.md); [findings](../../findings/2026-10-07-employees-wage-comparison-v1.md) |
| 2026-10-07 | Mid-game Employees | USER DIRECTION; further work DEFERRED | Target early mid-game entry and $1,000/month starting pay. Exact unlock and surrounding economics remain OPEN. Current after-Game-1/$10 implementation is retained unchanged pending future work. | [Dated direction](2026-10-07-midgame-wage-direction-v1.md) |

## Shared TODO contribution

The user prompted a contribution on 2026-10-06. Stage A of the [handoff](2026-10-06-implementing-thread-draft-v1.md) and the [separate first Production Specialist implementation task](2026-10-06-production-specialist-implementation-v1.md) are both marked COMPLETE locally in the [internal TODO](../../TODO.md). The historical conditional Stage B draft is superseded by that approved task. Further employee work is now on hold under the [later user direction](2026-10-07-midgame-wage-direction-v1.md). The shared TODO was not changed in this design turn.

## 2026-10-07 — implementing-thread wage comparison completed

Executed the wage proposal at user direction on the current source. [Findings](../../findings/2026-10-07-employees-wage-comparison-v1.md): 180 native routes plus 48 fixed-journal sensitivities pass 38,347 checks. $50 harms some low-cash next-game paths, while the visible planning policy does not establish a compensating Review benefit. The then-current recommendation was to retain live $10 and consider $25; **the user's later mid-game/$1,000 direction supersedes that next-candidate recommendation**. The 22-cycle first-release feasibility gap is retained, not silently repaired. No gameplay code was changed in main for this analysis.
