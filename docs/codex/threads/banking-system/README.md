# Banking System design thread

Started 2026-10-06 (America/Los_Angeles). This folder is the local workspace for the **Banking System** design discussion. Use repository documents and source for routine context; consult Google Drive only if local authority is missing or ambiguous, or if the user explicitly requests synchronization or historical evidence.

## Working agreement

1. Record questions, alternatives, evidence, and proposed work in [working-notes.md](working-notes.md). Keep unruled proposals **OPEN**; findings and candidate numbers do not approve gameplay.
2. Record agreed banking rules and rationale in the [economy and banking design](../../design/economy-banking.md). Record cross-system rulings in [DECISIONS.md](../../DECISIONS.md) when relevant.
3. The user explicitly prompted the [shared TODO contribution](../../TODO.md) on 2026-10-06. B3–B5 are queued there; keep future status updates synchronized with that list.

The original foundation included exact-cent cash and finance journals, $500 monthly rent, typed expenses, and monthly credit updates. Selectable loans are now implemented locally; [CURRENT_STATE](../../CURRENT_STATE.md) and the [current acceptance handoff](2026-10-08-next-acceptance-handoff-v1.md) track the remaining checkpoint and export gates. Accepted lending rules are in the [system design](../../design/economy-banking.md).

The [Studio Traits education handoff intake](2026-10-09-education-handoff-intake-v1.md) records the approved payment order. The [education-payoff reserve](2026-10-09-education-payoff-reserve-decision-v1.md) and [saved-preview treatment](2026-10-09-education-preview-migration-decision-v1.md) are also approved. The later E1–E4 education activation is implemented locally.

The [education activation handoff](2026-10-09-education-activation-handoff-v1.md) collects these rules into serial implementation and acceptance gates. The [zero-cycle payoff sequence](2026-10-09-education-payoff-action-sequence-decision-v1.md) is approved. The package was implemented by the main thread; this Banking thread's [review](2026-10-09-education-implementation-review-v1.md) records local completion and the remaining exported interaction gate. No gameplay was implemented here.

## Thread records

- [Exported Banking acceptance session](2026-10-09-export-acceptance-session-v1.md): user-accessible audited build, fresh Dropout payoff/Continue and genuine earned-cash installment.
- [Exported acceptance continuation](2026-10-10-export-acceptance-continuation-v1.md): genuine earned-cash education payoff, cold Continue and preserved active Bank loan pass on the pinned build; later whole-source export remains separate.
- [Education implementation review](2026-10-09-education-implementation-review-v1.md): E1–E4 local completion, exact source-hash check and remaining exported interaction gate.
- [Education debt and Banking intake](2026-10-09-education-handoff-intake-v1.md): approved future service order, current-source boundaries, payoff and migration decisions, and deferred acceptance.
- [Education-payoff reserve decision](2026-10-09-education-payoff-reserve-decision-v1.md): approved due-bill cash reserve, including older education arrears versus newer Bank bills.
- [Education preview migration decision](2026-10-09-education-preview-migration-decision-v1.md): v3–v5 previews remain inactive on supported Continue; only new-version selections activate debt.
- [Education activation handoff](2026-10-09-education-activation-handoff-v1.md): historical E1–E4 implementing scope, dependencies and acceptance; since implemented locally.
- [Education pre-TODO readiness review](2026-10-09-education-pre-todo-readiness-v1.md): identified the zero-cycle payoff servicing choice, later resolved.
- [Education payoff action-sequencing decision](2026-10-09-education-payoff-action-sequence-decision-v1.md): immediate due-bill service followed by education payoff in one atomic zero-cycle action.
- [Education TODO contribution session](2026-10-09-education-todo-contribution-session-v1.md): existing shared entry queued, with source state and documentation checks; no gameplay dispatch.
- [Working notes](working-notes.md): current baseline, open design questions, and future decisions.
- [State of the system, v1](2026-10-06-state-v1.md): current code and local evidence intake.
- [First loan proposal, v1](2026-10-06-first-loan-proposal-v1.md): candidate terms, math, and pressure checks.
- [B1 read-only findings](2026-10-06-b1-findings-v1.md): matched native $5,500/$5,700 routes and candidate loan overlays; no lending implementation or numeric approval.
- [B2 two-settlement findings](2026-10-06-b2-two-settlement-findings-v1.md): exact-cent comparison of average versus conservative capacity after two actual monthly receipts.
- [Two-settlement design ruling](2026-10-06-two-settlement-decision-v1.md): user-approved gate, conservative capacity/share and Bank access during active phases; loan economics remain open.
- [First-loan terms options](2026-10-06-loan-terms-options-v1.md): earlier $500-scale proposal and still-open rate, term, first due and score treatment; amount option superseded below.
- [Larger-offer findings](2026-10-06-larger-offer-findings-v1.md): user-reopened $500 ceiling, $500–$2,500 quote sensitivity and proposed $1,500 first-loan ceiling.
- [Selectable-loan decision](2026-10-06-selectable-loan-decision-v1.md): $500 minimum, chosen amount/term and accepted rate, due, payoff and delinquency rules.
- [Flexible-term findings](2026-10-06-flexible-term-findings-v1.md): level versus declining bills, amount/term qualification and why selector limits remain open.
- [Pre-TODO review packet](2026-10-06-pre-todo-review-v1.md): settled rules, remaining contract decisions and the intended three implementation slices; shared list untouched.
- [Source draft for shared TODO contribution](TODO-UPDATE-DRAFT-v1.md): fuller B3–B5 acceptance; selector/payment mechanics are implementation-brief details.
- [Handoff](HANDOFF.md): B3–B5 tasks, dependencies and acceptance criteria; contributed to the shared TODO.
- [Session log, v1](2026-10-06-session-log-v1.md): source state, checks, and limits for this design pass.
- [B1 session log](2026-10-06-b1-session-log-v1.md): route commands, source state, checks, and remaining evidence gaps.
- [B2 session log](2026-10-06-b2-session-log-v1.md): two-settlement inputs, checks, source state and open decisions.
- [Decision session log](2026-10-06-banking-decision-session-v1.md): approved gate/access reconciliation and next contract terms review.
- [Larger-offer session log](2026-10-06-larger-offer-session-v1.md): reopened ceiling, bounded quote calculations and remaining limits.
- [Pre-handoff session log](2026-10-06-pre-todo-session-v1.md): review packet, source state, checks and next ruling.
- [Selectable-loan session log](2026-10-06-selectable-loan-session-v1.md): amount/term calculations, accepted changes and open selector choices.
- [TODO draft session log](2026-10-06-todo-draft-session-v1.md): local draft, repository state and checks; no shared-list change.
- [Selector clarification session log](2026-10-06-selector-clarification-session-v1.md): corrected the assistant's extra decision gate after user clarification.
- [Proposal decline session log](2026-10-06-proposal-decline-session-v1.md): records the user's decision to leave the extra menu proposal behind and park this handoff.
- [Shared TODO contribution session log](2026-10-06-todo-contribution-session-v1.md): records the user-authorized transfer and exact checks.
- [Historical B3–B5 audit](2026-10-06-task-completion-audit-v1.md): pre-implementation snapshot, now superseded.
- [B3–B5 completion recheck](2026-10-07-task-completion-recheck-v1.md): current local implementation and hash-matched gate evidence; durable restart remains separate.
- [Checkpoint and export TODO handoff](2026-10-07-checkpoint-handoff-session-v1.md): user-requested Task10 Bank restore and Task11 exported Bank/Continue acceptance.
- [Current-source acceptance handoff](2026-10-08-next-acceptance-handoff-v1.md): next Task10/Task11 gates after Banking restart coverage and the Research/Resourceful checkpoint revision.
- [Shared-list update session](../../logs/2026-10-08-banking-todo-update-v1.md): current-source Task10/Task11 refresh and queued B6 read-only balance review.
- [Drive handoff reconciliation, v1](2026-10-06-drive-handoffs-v1.md): relevant historical pass offs compared with the local TODO and current source state.
- [Computer Use TODO update, 2026-10-10](2026-10-10-computer-use-todo-update-v1.md): current-source export and maintained-gate evidence, visible acceptance limits, and shared-list handoff.
- [Implementation status recheck, 2026-10-10](2026-10-10-implementation-status-recheck-v1.md): confirms bounded Banking and Cult export routes, the 108-suite gate, and later source drift before fresh acceptance.
- [Education grace study plan, 2026-10-11](2026-10-11-education-grace-study-plan-v1.md): predeclared legal cohorts, policy, measurements and stopping limits.
- [Education grace simulator finding, 2026-10-11](2026-10-11-education-grace-finding-v1.md): six current-rules routes, exact dues, fresh-process replay and bounded cash outcomes.
- [Education grace design-review handoff v1](HANDOFF-EDUCATION-GRACE-v1.md): no gameplay candidate; proposes a spending-sensitive follow-up decision.
- [Simulator session log, 2026-10-11](2026-10-11-simulator-session-v1.md): source state, checks, evidence and remaining scope.
- [Paid-Feature/Bank study plan, 2026-10-11](2026-10-11-spending-bank-study-plan-v1.md): predeclared seeds, legal Store route, matched Bank question and stopping conditions.
- [Paid-Feature/Bank simulator finding, 2026-10-11](2026-10-11-spending-bank-finding-v1.md): six legal paid-Feature prefixes, first education due, two rejected Bank quotes and fresh-process replay.
- [Paid-Feature/Bank design handoff v1](HANDOFF-SPENDING-BANK-v1.md): DESIGN review needed; no gameplay adoption candidate.
- [Paid-Feature/Bank session log, 2026-10-11](2026-10-11-spending-bank-session-v1.md): source status, exact commands and retained failures.
- [Eligible-sales TODO contribution, 2026-10-11](2026-10-11-eligible-sales-todo-session-v1.md): queues the next Banking-owned design study without assigning gameplay to the running implementation thread.
- [Eligible-sales study plan, 2026-10-11](2026-10-11-eligible-sales-study-plan-v1.md): fixed legal routes, comparison, seeds and limits before execution.
- [Eligible-sales finding, 2026-10-11](2026-10-11-eligible-sales-finding-v1.md): four eligible quotes and four matched pairs; borrowing improved cash but did not change actions in this funded route.
- [Eligible-sales design handoff v1](HANDOFF-ELIGIBLE-SALES-v1.md): bounded study complete; high-sales/low-cash usefulness is the next DESIGN question, with no gameplay adoption.
- [Eligible-sales session log, 2026-10-11](2026-10-11-eligible-sales-session-v1.md): source state, exact checks, verifier packaging limit and follow-up.
- [Liquidity usefulness plan, 2026-10-11](2026-10-11-liquidity-study-plan-v1.md): fixed high-sales/low-cash Store admissions and no-loan/$500/$1,000 comparison.
- [Liquidity usefulness finding, 2026-10-11](2026-10-11-liquidity-finding-v1.md): loans unlocked queued Research, but all declared game-two continuations stopped before release.
- [Liquidity design handoff v1](HANDOFF-LIQUIDITY-v1.md): no adoption candidate; next DESIGN study must protect a game-two cash reserve.
- [Liquidity session log, 2026-10-11](2026-10-11-liquidity-session-v1.md): source identity, retained failures, replays, verifiers and limits.
- [Reserve route plans v1/v2, 2026-10-11](2026-10-11-reserve-route-plan-v1.md): legal low-cash fork and separately declared one/two-hand production comparisons.
- [Reserve route finding, 2026-10-11](2026-10-11-reserve-route-finding-v1.md): one queued Research enabled by borrowing; weak one-hand Reviews, a $500 two-hand arrears stop and a later/lower-quality $1,000 release.
- [Reserve route design handoff v1](HANDOFF-RESERVE-ROUTE-v1.md): no gameplay adoption; meaningful-quality card draw/play and post-release sales remain DESIGN work.
- [Reserve route session log, 2026-10-11](2026-10-11-reserve-route-session-v1.md): source state, exact checks, retained failures and next design dependency.
- [Larger-offer plan, 2026-10-11](2026-10-11-larger-offer-plan-v1.md): predeclared selected $2,500 quote and four-hand legal comparison in a new private simulator version.
- [Larger-offer finding, 2026-10-11](2026-10-11-larger-offer-finding-v1.md): all six arms stopped before game two; $2,500 extended actions to c26 but accrued rent/Bank and Graduate education arrears.
- [Larger-offer design handoff v1](HANDOFF-LARGER-OFFER-v1.md): no gameplay adoption; meaningful-quality route and actual draw/play/sales benefit remain DESIGN work.
- [Larger-offer session log, 2026-10-11](2026-10-11-larger-offer-session-v1.md): v4 lineage, source parity, exact checks, retained rejections and limits.
- [Three-hand decision plan, 2026-10-11](2026-10-11-three-hand-decision-plan-v1.md): fixed legal low-cash forks, three-hand policies, comparison arms and limits before execution.
- [Post-launch settlement plan, 2026-10-11](2026-10-11-three-hand-settlement-plan-v1.md): one-cycle continuation from completed second-release checkpoints.
- [Three-hand finding, 2026-10-11](2026-10-11-three-hand-decision-finding-v1.md): source-pinned six-arm screen, matched comparisons, replays, reduced failures and actual c28 sales/debt.
- [Selectable-loan trial disposition, 2026-10-11](2026-10-11-selectable-loan-trial-disposition-v1.md): delegated ACTIVE/TRIAL ruling to retain current selectable Bank rules without a new numerical change.
- [Selectable-loan implementation handoff v1](HANDOFF-SELECTABLE-LOAN-TRIAL-v1.md): no canonical adoption delta; existing exported and human acceptance remain separate.
- [Selectable-loan decision session, 2026-10-11](2026-10-11-selectable-loan-decision-session-v1.md): source state, exact checks, files, evidence limits and follow-up.
- [Distressed-finance exported acceptance handoff v1](HANDOFF-DISTRESSED-FINANCE-ACCEPTANCE-v1.md): queued Bank/Education late, partial, payoff, Continue, migration and quote-comprehension checks; no gameplay delta.
- [Distressed-finance TODO contribution, 2026-10-11](2026-10-11-distressed-finance-todo-session-v1.md): user-authorized shared-list update, source status and documentation checks.
- [Foundation scope audit, 2026-10-17](2026-10-17-foundation-scope-audit-v1.md): current integrated Banking components and the clarification needed before a new foundation change.
- [Bank confirmation hardening, 2026-10-17](2026-10-17-confirmation-hardening-v1.md): one-shot displayed-quote confirmation for Bank and education, focused checks and remaining exported acceptance.
- [Current capability audit, 2026-10-17](2026-10-17-current-capability-audit-v1.md): loan/education actions present in source, remaining B7 acceptance, and a current check attempt blocked by a Contracts dependency compile error.
