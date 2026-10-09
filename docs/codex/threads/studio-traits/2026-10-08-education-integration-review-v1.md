# Education debt integration review — 2026-10-08

Read-only review on main91ce539 plus current local changes. No debt trait activation or new numerical ruling.

## Verified current path

`StudioFinanceLedger.payoff_quote/pay_off` already supplies revision-bound, zero-cycle explicit Bank payoff. The quote includes outstanding principal and due unpaid interest; acceptance reserves unpaid rent and payroll. Normal servicing currently iterates rent, payroll, then bank categories, chronologically within each category. Loan closure retains original history. The actual exported $500 loan paid one $46.67 installment and $458.33 payoff, with $5 interest and $500 principal paid; captured evidence is under `findings/export-ui-queue-v1`.

The payoff API is a useful implementation pattern, but education cannot simply be added to the Bank array. Its twelve-month grace, fixed amortizing schedule, no cash deposit, separate credit type and overlapping-term Bank capacity reserve differ. Current Bank capacity reserves live payroll only. The approved education text orders Bank/education by original due with Bank winning same-date ties; that also requires a shared ordered debt pass rather than appending education after every Bank bill.

## Remaining ruling and proposed migration

Payroll versus education priority is explicitly OPEN in the portable TODO. Recommendation for a later user ruling: rent first, payroll second, then Bank/education by original due with Bank first on ties, including explicit-payoff affordability reserves. This recommendation is not applied.

Current trait versions3–5 keep College Dropout/Graduate inactive with zero point refund and zero debt. New activation should use a new trait version and typed debt schema. Preserve those saved versions as inactive; never retrospectively charge debt or refund points on Continue. Add education state to strict checkpoint validation and reject unsupported content without replacing original save bytes. This is a proposed migration policy pending the debt dispatch, not a new compatibility claim.

Future acceptance should cover grace-month12/13, installment96/final residual cents, old-due partial recovery, late-credit once-only behavior, nonblocking education-only arrears, overlapping/nonoverlapping Bank terms, explicit payoff with all prior bill categories, and separate-process restore at each boundary. Approved principal/rate/due amounts remain as recorded in TODO; final activation awaits the outstanding priority/migration ruling.

An independent Decimal/ROUND_HALF_UP calculation confirms the recorded amortization: starting500000c with95 payments7068c leaves a7111c final payment and178571c total interest; starting2000000c with95 payments28273c leaves28328c and714263c interest. Each month's interest is round-half-up(opening principal ×8/1200); both close at zero after96 dues. This verifies the design arithmetic only, not a live debt implementation.
