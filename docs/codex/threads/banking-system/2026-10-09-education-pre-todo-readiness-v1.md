# Education activation pre-TODO readiness review v1

2026-10-09, America/Los_Angeles. **Design-only review; the payoff action-sequencing question was later resolved** in the [user-approved decision](2026-10-09-education-payoff-action-sequence-decision-v1.md). No shared TODO or gameplay change.

## Finding

The approved education payoff rule requires cash for the education quote plus all already-due unpaid rent, payroll and Bank installments. It does **not** say whether confirmation pays those other bills immediately or merely leaves their amount in cash. These produce different post-action cash, bill history and future late-credit behavior.

Current `StudioFinanceLedger._apply` services existing rent, payroll and Bank bills before executing an explicit Bank payoff, even when that payoff uses zero cycles. Reusing that path for education without stating the order could accidentally service education arrears twice or make the education quote stale within its own transaction. The education quote includes all due education interest and remaining principal; due education bill history must end paid after a successful payoff.

## Recommendation later approved

At education payoff confirmation, atomically service all already-due rent, payroll and Bank balances in that order, then apply the education payoff quote. Include existing education arrears **inside** the payoff once: record each due bill's interest/principal payment and original history, then allocate any remaining payoff principal to future scheduled principal. End the education schedule and leave zero unpaid education debt. No calendar cycle passes, and a failed preflight changes nothing. Ordinary monthly settlement still uses the approved mixed Bank/education original-due order. This voluntary-action sequence implements the stricter payoff cash reserve that the user already approved.

Example: with $1,700 cash, $500 rent due, $200 Bank due and a $1,000 education payoff quote, the approved action pays all $1,700 and leaves no unpaid included bill. A reserve-only action would pay $1,000 and leave $700 cash plus two due bills. Both pass the earlier affordability test; the user selected immediate payment.

## Other boundaries

No extra interest rate, trait value, 96-bill math or credit weight needs a new ruling. Exact compatible checkpoint revisions and quote identity fields are implementation acceptance to derive from then-current source; the approved migration rule applies only to **supported** Continue. A closed/fully paid education account contributes zero to a later Bank capacity quote. The [E1–E4 handoff](2026-10-09-education-activation-handoff-v1.md) incorporates the later action-sequencing decision and is ready for later shared-queue contribution.

Session: `main` at `41c87c76fb4d3c06a5332d93f0e7b0997007475d`; read current `CURRENT_STATE.md`, `TODO.md`, Banking handoff, payoff/migration decisions and `StudioFinanceLedger._apply`. Concurrent shared TODO edits were preserved. Changed files at readiness review: this note, Banking activation handoff and README; the later ruling also updated the cross-system design/decision records. Checks: targeted source/status/diff review, `git diff --check` exit 0 and relative-link/trailing-whitespace scan passed. No gameplay, tests, shared TODO edit, commit or push.
