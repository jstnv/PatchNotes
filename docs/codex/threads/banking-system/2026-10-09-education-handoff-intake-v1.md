# Education debt and Banking handoff intake v1

2026-10-09, America/Los_Angeles. Banking design only. This records the [Studio Traits discussion handoff](../../../../patch-notes/design-logs/threads/studio-traits/2026-10-08-education-banking-discussion-handoff-v1.md) for a later, separately approved education-debt activation package. No gameplay or shared To Do List change is authorized by this intake.

## Accepted rules

- The user approved monthly service of oldest rent, then payroll, then Bank and education bills together by original due date, Bank first on a same-date tie. Partly paid debt bills cover already-due interest before principal. This is a **LOCKED future rule**, not current gameplay.
- Education payoff, when eventually active, quotes remaining unpaid principal plus already-due unpaid interest. No payoff fee or future unaccrued interest. Past lateness/credit history remains. College Dropout/Graduate debt remains inactive today.
- The user subsequently approved the [voluntary-payoff reserve](2026-10-09-education-payoff-reserve-decision-v1.md): cash must cover the payoff plus all already-due unpaid rent, payroll and Bank installments, even when the education arrear is older than a Bank bill. Future bills are not reserved.
- The existing education design has a twelve-month grace period, first due month 13, 96 installments, fixed $5,000/$20,000 principal and 8% annual scheduled-balance interest. These are prior approved design values; this intake changes none of them.

## Current-source evidence and limits

- `StudioFinanceLedger` currently services `rent`, `payroll`, then `bank_installment`, oldest within a category. Its explicit Bank payoff is revision-bound and zero-cycle, quotes outstanding principal plus due unpaid interest, and preserves unpaid rent/payroll before allowing payment. A future education producer needs a merged original-due debt pass; appending a student-loan category after all Bank installments would violate the approved order.
- `OutstandingExpenses` already recognizes the `student_loan` expense type and prototype late-credit weights, but no education bill producer or schedule exists. Current Bank capacity deducts scheduled payroll; the approved future education overlap reserve still needs implementation and verification when debt activates.
- `StudioTraits.evaluate_traits` accepts versions 3–5; the two education selections are inactive previews. Checkpoint validation recomputes the trait snapshot and validates a narrow set of content revisions. This proves the need for an explicit compatibility design; it does not prove old save files already migrate under a future education revision.
- The Studio Traits integration review verified Bank payoff and the education amortization arithmetic on the then-current source. This intake read the current source paths but ran no gameplay or export check.
- At the initial intake, the shared `TODO.md` education paragraph still labeled payroll-versus-education ordering OPEN. A concurrent Studio Traits edit has since recorded the approved payment order there. Its payoff-reserve wording predates the 2026-10-09 Banking ruling; this thread leaves the shared list untouched until an education task/status update is requested.

## Approved payoff affordability; proposed quote controls

**Proposed implementation controls:** Use a passive, exact-cent quote and an explicit, atomic, zero-cycle confirmation. At confirmation, regenerate the quote from the current ledger and require an exact match on debt identity, remaining principal, already-due unpaid interest, total, current cycle and finance revision. Reject stale, repeated, unaffordable or malformed confirmations without changing cash, calendar, bills, credit, RNG or debt.

**LOCKED:** Require `cash >= payoff_total + unpaid_rent + unpaid_payroll + unpaid_bank_installments`, where each reserve includes **already-due unpaid balances only** at the action instant. The education payoff total already includes all education principal and due interest, so no second education reserve is added. Do not reserve future rent/payroll/Bank bills that have not come due. This voluntary-action cash protection is intentionally stricter than the automatic due-date service order when an education arrear predates a Bank arrear; it prevents an optional full payoff from consuming cash owed on another existing bill. An approved payoff deducts its principal and due-interest portions once, closes remaining education schedule, leaves existing bill/history provenance auditable, and grants no instant credit increase.

The passive quote, current-ledger revalidation and stale/duplicate rejection above remain proposed implementation controls to check against the live Bank pattern. The [decision record](2026-10-09-education-payoff-reserve-decision-v1.md) carries the approved cash rule.

## Approved inactive-preview migration

**LOCKED:** Keep saved version 3–5 College Dropout/Graduate selections as historical inactive previews on supported Continue: zero education principal, zero bills and no retroactive point refund or startup receipt. Enable debt only for a newly confirmed selection under a new trait version. The [decision record](2026-10-09-education-preview-migration-decision-v1.md) does not claim currently incompatible saves become loadable.

**Implementation acceptance:** Add new typed education finance/checkpoint state and define compatible content revisions against current source. Unsupported revisions must fail validation without overwriting original checkpoint bytes. A supported Continue must preserve existing loan, bill, cash, point, trait and history state through separate-process restore. Do not infer compatibility from the current single `previous_revision()` check.

## Deferred implementation handoff: acceptance and dependencies

Dependency: payoff reserves and preview migration are ruled. Education-debt activation still needs a separate user-requested shared-queue handoff. The implementing thread owns code, tests and export. Use one gameplay implementation slot and recheck current branch/source/checkpoint versions before work.

Acceptance should cover:

1. Monthly shortage ordering: rent/payroll first; Bank versus education by original due with Bank tie; older education arrear ahead of newer Bank due; each partial debt payment applies interest before principal and preserves original age/history.
2. Grace month 12, first due month 13/cycle 26, exact final 96th bill, no compounded missed interest/extra fee/new interest after bill 96, and one typed late-credit effect per genuinely late month. Education-only arrears do not trigger the rent production gate.
3. Bank quote capacity includes the largest contracted education payment overlapping its selected term, including grace-year quotes, and zero when there is no overlap; preserve existing settled-sales, rent, payroll and active-loan gates.
4. Education payoff before/after first due, with partial arrears and simultaneous rent/payroll/Bank arrears; fresh/stale/duplicate/insufficient-cash quotes; exact principal/interest split, future-interest waiver, zero-cycle behavior and finance/credit reconciliation.
5. New active trait selection versus saved v3–v5 inactive previews; strict typed checkpoint validation and separate-process restore at creation, grace, first due, partial arrears, payoff and bill 96. Never silently convert previews or replace incompatible original bytes.
6. Current-source focused checks, both supported UI sizes, and a separate exported interaction gate before claiming playable/export acceptance. Numerical design evidence alone does not establish implementation.

## Session record

At intake, branch `main`, HEAD `41c87c76fb4d3c06a5332d93f0e7b0997007475d`; target shared design files had no existing diff. Read `CURRENT_STATE.md`, `TODO.md`, `README.md`, economy/Studio Traits design, the Studio Traits decision/handoff and integration review, and the relevant current finance/trait/checkpoint source. Verified the user's agreement in the Studio Traits chat. Changes in this session: this intake, the economy-banking future-rule paragraph, the cross-system decision row and Banking README/HANDOFF references. Checks: documentation/source read and targeted Git status/diff only; no gameplay suite, export, commit or push. Later [payoff](2026-10-09-education-payoff-reserve-decision-v1.md) and [migration](2026-10-09-education-preview-migration-decision-v1.md) rulings resolve the two design questions; debt activation is still separate.
