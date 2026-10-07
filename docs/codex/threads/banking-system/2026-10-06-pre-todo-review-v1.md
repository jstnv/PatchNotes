# Banking decisions before a shared To Do List handoff

2026-10-06 (America/Los_Angeles). **Review packet only; do not copy to the shared TODO yet.** The user subsequently [ruled on selectable amount/term, 1% rate, first-full-month due and delinquency](2026-10-06-selectable-loan-decision-v1.md), superseding this packet's former $100 minimum, fixed 12-month term and OPEN rate/due/default questions. The [economy design](../../design/economy-banking.md) is authority; [B1–B4 findings](2026-10-06-flexible-term-findings-v1.md) are read-only evidence. Loans are not implemented.

## Already decided

- Two consecutive completed months of positive settled portfolio sales are required for a first quote. A zero-sales month breaks the streak.
- Capacity uses 25% of surplus after $500 rent and live required obligations, with sales basis equal to the lower of the latest month and the floored two-month mean. No overdue bill or other active bank loan at origination.
- The Bank is reached through the passive cash HUD → Finances path in any active gameplay phase; accepting or paying off debt must be explicit and atomic.
- One active loan; future unaccrued interest is waived on early payoff. Typed bill identity, original due and age, payment history and credit effects must remain intact.
- The player chooses principal **at least $500** and a loan term. Interest is 1% per completed month on scheduled opening principal, half-up cents; first due is after a full calendar month. The first offer has no score-based rate or threshold. Rent is serviced before due bank interest/principal; partial bank bills keep their original age, and there is no extra late fee.
- $5,500 base and a separate $200 trait receipt are distinct starting cases. The first game should generally reach release by about 14 cycles; lending starts only after sales and cannot erase that pressure.

## Selector details to document in an implementation brief

| Detail | Analysis example, not a rule | Why it matters |
|---|---|---|
| Valid amount/term inputs | $500–$2,500 in $100 steps, 6/12/18 months, was one analysis menu. | The user accepted a $500 minimum and player choice. Exact input handling must be specified before gameplay changes. Long terms can make large principal pass the monthly capacity screen; the example cap is not approved policy. |
| Payment calculation | Nearly level amortized versus equal-principal declining bills were compared. | At $1,500/12, level bills peak at $133.32 with $99.29 interest; declining bills start at $140 with $97.50 interest. The formula must follow chosen amount/term, exact cents and accepted 1% interest. No example shape is required by the user. |

The offer's proceeds are ordinary spendable Studio cash recorded as financing, never profit; principal payments reduce cash but not operating profit. The quote should show selected amount/term, exact payment schedule, total cost, capacity source months, known bills and early payoff. Rejected/stale/replayed acceptance must change nothing. The selector and payment calculation need a reviewable implementation specification, not another prerequisite user ruling on the assistant's candidate menu. These integration requirements are not implemented.

## Handoff shape once the user requests shared-list contribution

1. **Loan domain and finance:** exact-cent quote/issuance, one-active guard, financing journal, installments, typed obligations, rent/bank service order, partial recovery, credit interaction and atomic rollback. Dependency: documented selector/payment mechanics consistent with the accepted rules and a nonoverlapping gameplay slot.
2. **Bank UI:** amount selector, eligibility/price explanation, explicit accept/payoff, due table, bill/payment history, phase-safe modal navigation at both supported resolutions. Dependency: stable domain API and approved copy.
3. **Verification and save mapping:** cent and boundary checks, weak/zero sales, $5,500/$5,700, even/odd issue, missed/partial bills, clean/late credit, full maturity and early payoff, restart schema mapping. Claim disk restore only when the separate durable checkpoint runtime exists.

The current [HANDOFF](HANDOFF.md) has detailed acceptance criteria for these three slices. B1/B2/B3 design analyses are complete within their fixed-action limits; they are not implementation tasks. Keep the shared TODO and Drive unchanged until the user explicitly asks to contribute.
