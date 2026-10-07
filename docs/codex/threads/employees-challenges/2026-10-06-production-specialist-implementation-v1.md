# Production Specialist implementation task

2026-10-06, America/Los_Angeles. **QUEUED.** Implement one playable Production Specialist using the [user-approved trial package](2026-10-06-trial-package-decision-v1.md). This is the separate Stage B task following the completed Tasks8/16/18 comparison. Begin in a coordinated gameplay slot after preserving current work and rechecking branch, HEAD, status, diff and applicable source. Approval is recorded; this document does not report implementation completion.

## Scope and dependencies

Deliver Studio hiring, persistent employee ownership/training, the optional Production benefit, typed payroll and finance/UI reporting. The first slice supports one Production Specialist. Courses, other specialists, dismissal/rehire and broader staffing are future work. Final wages remain open while the approved $10/month trial is playable.

Use current exact-cent RunState transactions, finite card pools, redraw rules, $500 rent and actual portfolio earnings/settlement. Keep lifespan coefficients and unrelated Store/trait/Fanbase/publisher rules fixed. Coordinate with Banking B3–B5 around shared finance code. Integrate with whichever Banking source exists when dispatched; missing live lending is not a reason to add a loan system here. Durable checkpoint work is separate.

Last inspected source was main `553d1a46f33d59641efa4c2e4ff141f958c1230d`, with no `patch-notes` diff and no employee runtime. Recheck this at execution rather than treating the analysis snapshot as a required implementation base. Preserve `.codex-godot-temp` and all existing worktree edits.

## Hiring and ownership

- Expose one Production Specialist in Studio after the first successful release. Hire costs **10,000 cents**, with **zero productive cycles**. Show the fee, monthly wage and first payday before explicit confirmation. Unaffordable fee or outstanding bills reject atomically; future earnings cannot fund the direct fee. A Contract is an available funding choice, not a hiring prerequisite.
- Assign a stable employee ID and Studio ownership. Commit the fee, employee record and payroll schedule together. A stale, canceled or duplicate confirmation changes nothing and cannot charge twice or create a second employee.
- Store permanent training independently from current project progress. Record project identity and committed action identity for the trigger and benefit use. New projects reset only project progress/use, not ownership or training. Do not grant pre-hire challenge progress from earlier games.

## Challenge and optional benefit

The locked training trigger is a successfully committed **Design** hand containing a Core Pass and at least one Feature matching that Pass's **printed primary or secondary Core stat**, once per employee/project. Alpha can use the trained benefit but does not substitute for the Design training trigger. Qualification uses selected, committed cards; retained/unplayed candidates and rejected actions do not train.

Training grants the permanent employee-owned planning benefit immediately. Once trained, allow **one optional valid changed Design/Alpha priority distribution per employee/project**, bundled with a later committed matching Pass/Feature hand. The newly training hand cannot spend its newly granted benefit. A previously trained employee can use the benefit on the new project's first qualifying hand. Decline, unchanged priorities, an invalid choice or canceled confirmation leaves the use available.

Preview the proposed distribution and qualifying cards using information already visible to the player. Run the full hand preflight before mutation. Commit priorities, hand effects, challenge/use identity, native finite replacement draws, one normal productive cycle/refill and finance settlement atomically. The priority choice changes normal replacement weights; it supplies no immediate Core bonus, extra card, pool reroll, extra redraw, separate cycle or separate refill. Preserve normal redraw caps, class eligibility and no-identical-replacement behavior. Rejection/duplicate callback/reconstruction must preserve cash, calendar, RNG, cards, priorities, training and remaining use.

## Payroll and recovery

- Schedule **1,000 cents/month** per hired Specialist. First due is `c+2` for an even completed hire cycle and `c+3` for an odd cycle; then every two productive cycles. Examples: hire at 12 → due14; hire at13 → due16; hire at14 → due16. Browsing and real time create no bill. Use stable employee/month source IDs to prevent duplicate issuance.
- Payroll expense belongs to the original due month, paid cash to its payment month. Service settled sales and genuine receipts in **rent → payroll → bank** order, oldest due within each category; preserve bank interest-before-principal. Partial payments retain original due date, age, balance, provenance and late history. No negative spendable cash, write-off or hidden receipt.
- Reuse the typed credit policy once per category/month, with existing prototype weights. Recovery at an opening boundary must not reapply the preceding close's penalty. Genuine recovery receipts cost no extra cycle. Existing arrears require a productive action's genuine inflow/settlement to cover old arrears plus newly due bills; free phase exit/launch remains available under current rules.
- Generalize rent-only blocked-action text and overdue totals where payroll is now relevant. Reconcile payroll due/paid/unpaid, operating profit, cash and credit reports. Include live required monthly payroll in existing Bank capacity exactly once, when that quote implementation is present. Do not count publisher receipts, financing or unsettled earnings as qualifying sales.

The future course timing approval is recorded in the decision but adds no course UI, bill producer or salary raise in this task. Course effects, tuition and raise amounts require a later ruling.

## State mapping and presentation

Define versioned lossless mapping for employee ID/type/ownership, training, project trigger/use identities, monthly wage, hire/first-due schedule, payroll bill source IDs and transaction history. Reconstructed state must not retrain, reset a spent project use, issue bills again or repeat a charge. Integrate with the current in-memory finance schema and validate malformed/duplicate identities. Disk restart safety is only claimable after the separate checkpoint runtime exists and a separate-process restore passes.

Studio should show hire availability/rejection reasons, wage, next payday, challenge requirement/progress and whether the project benefit is available or used. The hand confirmation should preview changed priorities and permit decline. Finances should expose typed payroll bills and history; HUD arrears must include them. Verify mouse/keyboard, focus, Back/Escape and passive navigation at 1280×720 and 1152×648. Keep future unavailable courses and unimplemented loans out of this task's offer flow.

## Acceptance and evidence

1. **Hiring:** unavailable before Game 1; legal confirmed $100 hire afterward; zero cycle; fee/current-bill rejection; duplicate/cancel/stale-input rollback; permanent Studio ownership and no retrospective training. Keep genuine $5,500 base and $5,700 trait-financing ledgers distinct.
2. **Challenge and use:** primary/secondary printed matches and nonmatches, Design versus Alpha, early/late training, trained versus untrained project starts, once per employee/project, benefit decline/unchanged/invalid/use, next-project reset and phase exits. Constructed multi-identity fixtures should prove employee isolation without adding extra playable staff.
3. **Atomic hand behavior:** preserve normal Core effects, finite replacement/class rules, shared redraw boundaries, one cycle/ordinary refill and exactly-once finance. Snapshot cash/calendar/RNG/cards/priorities/employee state around rejected, duplicate and reconstructed actions.
4. **Payroll:** exact-cent even/odd/boundary hires, first full-month due, recurring dates, passive openings, issuance identity and due/paid/unpaid/profit reconciliation. Include genuine Beta/publisher receipt recovery and productive old-arrears preflight.
5. **Shared bills:** rent/payroll same-boundary shortage, partial and full recovery, original-age retention and credit once; constructed rent/payroll/bank coexistence verifies the selected order and bank interest-before-principal. Check Bank capacity deduction against actual Banking code if present. A $505 receipt against $500 rent plus $10 salary leaves $5 payroll arrears; later recovery clears it without a new cycle or erased history.
6. **Mapping/UI/route:** lossless reconstruction and malformed identity rejection, both resolutions and navigation/input checks, plus a legal native overlapping three-release route with an actual post-Game-1 hire and recorded earning/settlement/payroll actions. No overlay counts as implemented employee behavior or disk restart proof.
7. **Completion:** run focused native employee/finance/priority regressions and the required integration gate for the actual changed source. Persist changed files, exact commands/results, source revision, route trace, remaining limits and follow-ups in findings and a dated session log. Update TODO/design/CURRENT_STATE only to the scope actually verified. No automatic commit, push, export or release-readiness claim.

## Follow ups

Revisit final wages after surrounding economy stability and human choice evidence. Keep course effect/tuition/raise decisions and subsequent course implementation separate. Reuse the [comparison evidence](comparison-v1/README.md); repeat a broad simulation only for a new discrepancy or changed balance question.
