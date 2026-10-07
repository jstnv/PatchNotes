# First bank loan offer — design proposal v1

2026-10-06 (America/Los_Angeles). **Historical proposal, not implemented.** This small offer was compared with the [accepted foundation](../../design/economy-banking.md) and [B1 native routes](2026-10-06-b1-findings-v1.md). Its one-settlement gate is **SUPERSEDED** by the locked [two-settlement decision](2026-10-06-two-settlement-decision-v1.md). Its fixed $500 amount and fixed 12-month term are **SUPERSEDED** by the user's [selectable-loan ruling](2026-10-06-selectable-loan-decision-v1.md), which sets a $500 minimum. The proposed 1% rate and first-full-month due were later accepted; exact payment shape and selector limits remain open.

## Accepted constraints

Only genuine settled sales unlock borrowing; at most one loan may be active. Principal must fit recurring repayment capacity; the older $500 ceiling used for this v1 study is now open for larger offers. Early payoff waives future unaccrued interest. Cash cannot go negative, loan proceeds are financing rather than profit, principal repayment is a cash outflow rather than an expense, and a late bill retains original age/history. Credit weights are prototype values. The $5,500 base and separate $200 trait receipt must be compared separately.

## Proposed offer and quote

| Item | Candidate rule |
|---|---|
| Amount | One $500 offer in v1; no amount slider, fee, collateral, or pre-release loan. Requote after eligibility changes. |
| Interest | 1% per calendar month on the **scheduled opening principal**, simple and noncompounding. Compute each month's interest in integer cents, rounding half up. Missed payment does not increase future scheduled interest or add a late fee. |
| Term | 12 monthly installments. Scheduled principal is $41.66 for installments 1–11 and $41.74 for installment 12. Interest declines from $5.00 to $0.42; the first payment is $46.66, the last $42.16. Full on-time term costs $32.50 interest and $532.50 total. |
| First due | End of the first **full** calendar month after issuance. At even completed cycle `c`, first due is `c+2`; at odd `c`, first due is `c+3`. Then every two productive cycles. Issuing a quote or viewing Bank costs no cycle. |
| Price and credit | Same quoted 1% for all eligible scores in this first candidate. No score threshold or score-based discount is proposed yet; whether score should price or bar loans remains **OPEN**. The current score and prototype policy appear with the quote, without promising future pricing. |
| Origination | Available from Studio/Bank only after the run's first actual positive sales settlement. Reject when any bill is overdue, the finance journal is unavailable, another loan is active, or the $46.66 maximum installment exceeds calculated capacity. The loan receipt is a unique, atomic $500 financing transaction. |

The quote shows principal, all 12 dates and principal/interest splits, $532.50 scheduled total, first due, capacity calculation, current overdue state, and an explicit early-payoff example. Recheck source revision, eligibility, cash/ledger consistency, and quote identity on acceptance; repeated or stale acceptance must not issue a second receipt.

### Capacity calculation

**Historical v1 candidate:** the two-settlement study linked above recommends a more conservative screen. Retain this version to show what B1 tested; do not implement it as the selected rule.

Use actual **completed post-first-settlement months**, including later zero-sales months, up to the most recent three. For each month use settled net sales cash from the authoritative monthly finance row. Before the first settlement there is no sample and no eligibility. At first settlement the sample has one month. Publisher/Beta receipts, startup/trait financing, loan proceeds, forecasts, and unsettled earned revenue do not count.

```text
n = number of sampled completed months (1..3)
average_sales_cents = floor(sum(sampled sales_settled_cents) / n)
required_other_cents = highest monthly scheduled payroll and Student Loan
                       payments during this proposed 12-month loan term
recurring_surplus_cents = max(0, average_sales_cents - 50000 rent
                                - required_other_cents)
capacity_cents = floor(recurring_surplus_cents / 4)
eligible iff capacity_cents >= 4666 and all other origination guards pass
```

When future bill producers gain real schedules, their full required monthly cash amounts enter `required_other_cents`; do not treat the currently inert hooks as live costs. Recompute capacity for each quote. An accepted loan keeps its payment schedule even if later sales fall; declining capacity blocks a new quote but never rewrites a debt. The 25% surplus share is a **proposal**, chosen to leave three quarters of modeled post-rent recurring surplus for variability and other spending. One-off Store/Feature/campaign purchases are excluded from this recurrence estimate, so show actual cash and upcoming known bills beside capacity; the estimate is not a cash guarantee.

### Payment, delinquency, and payoff

At each due boundary, settle all released-title sales, create that month's installment with its original due cycle/month and interest expense, service oldest rent, and then service oldest due bank installment with remaining actual cash. Within an installment, service accrued interest before principal. No amount may be paid from forecast or unsettled sales. Finance must show original-month interest expense separately from actual payment-month interest cash, avoiding a double expense when recovered later. Principal never changes operating profit. Preflight the entire productive transaction before applying phase effects or publishing reports.

Each installment is one `bank_installment` typed obligation with a unique loan/installment ID, original principal/interest split, due amount, paid amount, payment provenance, age, and late history. A partial payment leaves the original due and age intact. Existing credit closure applies the strongest genuine bank-installment age once per month, not once for principal and again for interest. It may combine with a separate rent-category penalty. At the current **trial** weights a newly missed bank installment requests −10, then −20, then −30 at older tiers; no immediate payoff credit bonus. Outstanding debt keeps the loan active. Existing arrears action guards extend to both rent and bank installments, while genuine receipts and passive navigation remain possible.

An early payoff quote at a Studio cycle equals **unpaid principal plus interest from installments already due but unpaid**. Future scheduled interest, including the current partial month's not-yet-due interest, is waived; there is no payoff fee. Apply actual cash first to overdue rent, then due bank interest/principal, then remaining loan principal; reject atomically if cash cannot cover the quote under that order. After three on-time dues, for example, paid interest is $13.75, unpaid principal is $375.02, and immediate payoff is $375.02. Total paid becomes $513.75, saving $18.75 against the $532.50 full schedule. Closing the loan does not erase any past late bill or grant credit points. A later loan may be considered only through a fresh eligible quote.

## Pressure check against local evidence

The pre-sales arithmetic uses the observed ~$1,150 Feature spend as a **simplifying scenario**, not a fixed charge or a native trace. It excludes Contracts, Beta receipts, actual card-cost variation, and sales:

| First release timing | Rent paid | $5,500 start after $1,150 spend | $5,700 start after $1,150 spend | Lending effect before first sales settlement |
|---|---:|---:|---:|---|
| Cycle 14 | $3,500 | $850 | $1,050 | None; no settlement yet. |
| Cycle 16 | $4,000 | $350 | $550 | None if this is the first release. |
| Cycle 18 | $4,500 | −$150 theoretical shortfall | $50 | None if this is the first release. |

For a cycle-14 launch, Month 1 sales settle at cycle 16 in the matched native routes, so a loan issued then first falls due at cycle 18. Cycle-18 launch instead first settles at cycle 20 and a loan then first falls due at cycle 22. Thus this offer cannot erase the intended first-game pacing pressure or rescue a $5,500 route that cannot legally reach its first settlement. The $5,700 matched cases have exactly $200 more cash. A 6.2-rated late launch remains a qualitative human pressure observation; the reproducible late Reviews were 6.4–6.8.

The [Task33 eight-route summary](../../../../patch-notes/design-logs/task33-v1/route-summary.json) was the original $5,500-start native evidence. The subsequent [B1 comparison](2026-10-06-b1-findings-v1.md) ran 32 current-source no-loan routes with genuine matched $5,500 and $5,700 starts, first releases at cycles 12, 13, 14 and 18, and 80 fixed-action loan overlays. All first-settlement quotes cleared this proposed screen and all fixed overlays could pay through their observed horizons. Cycle-18 routes already had $0 cash and rent arrears at release; the offer was unavailable until cycle-20 settlement. The $200 trait receipt reduced those arrears but did not eliminate them in the matched routes.

At the weak-sales edge, a single completed month needs at least **$686.64** settled net sales to support $46.66 under the proposed 25% formula with $500 rent and no other recurring bills. At $600 sales, capacity is only $25.00 and the $500 quote is rejected; at $700, capacity is $50.00 and it passes, subject to no arrears. This screen can prevent a weak first release from turning a loan into an automatic bailout. A high first month may still fade: recheck matched later-month cash, arrears, and loan repayments before accepting these terms.

## Unresolved review questions

1. Is a fixed $500 offer sufficiently useful, or should a later design offer smaller increments without weakening the capacity guard?
2. Is 1% monthly on the scheduled principal and a 12-month term a fair first price, especially when weak titles fade? Should credit score affect eligibility or rate in a later version?
3. Is the first-full-month grace and 25% of settled-sales surplus appropriately cautious? The matched comparison found later rolling capacity reached zero for multiple months despite a qualified first quote; the one-month sample can overstate durable income.
4. Confirm rent-first service, interest-expense recognition at original due, and the exact Bank quote language through UI review before implementing.

These remain proposals. See [handoff](HANDOFF.md) for bounded analysis and implementation acceptance conditions; nothing here enters the shared TODO without an explicit prompt.
