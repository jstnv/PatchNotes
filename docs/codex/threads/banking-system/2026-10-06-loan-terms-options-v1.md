# First bank-loan contract — next design decision

2026-10-06 (America/Los_Angeles). **Historical proposed terms, not implemented.** The [two-settlement gate and Bank access](2026-10-06-two-settlement-decision-v1.md) are locked design. The later [selectable-loan ruling](2026-10-06-selectable-loan-decision-v1.md) supersedes this note's $100–$500 amount menu and fixed term, sets a $500 minimum, and accepts its 1% rate, first-full-month due and neutral first-offer score policy. Payment shape and selector bounds remain open. The [B1 candidate comparison](2026-10-06-b1-findings-v1.md) and [B2 qualification comparison](2026-10-06-b2-two-settlement-findings-v1.md) are read-only evidence.

## Recommended first offer

- Let the player choose **$100–$500 in $50 increments**, with at most one active loan. The quote's maximum scheduled installment must fit the locked capacity screen. A fixed $500-only offer is simpler, but the conservative screen rejected both matched early/synergy/seed 1104 routes at $46.66 capacity requirement; a $450 quote costs $42.00 at its highest installment and fits their $42.83 capacity. Thus adjustable amount makes the capacity rule useful rather than a binary denial in those observed cases. The $100 minimum and $50 step are proposals, not established economy values.
- Charge **1% per completed calendar month on scheduled opening principal**, simple and noncompounding, with integer-cent half-up interest rounding. Divide principal evenly across **12 monthly installments**: floor the first 11 principal shares to cents and place the remainder in installment 12. Missed payment does not compound the scheduled interest. Future unaccrued interest is waived on early payoff under the accepted direction.
- First due at the end of the **first full calendar month after issuance**. A quote accepted at an even completed cycle `c` first falls due `c+2`; at an odd cycle `c`, `c+3`. Every next due is two cycles later. Acceptance and browsing cost no productive cycle.
- Use the same rate for every eligible score in this first offer. Show the current score and its prototype status, without promising a discount or threshold. A score-based policy needs its own evidence and ruling; the existing overdue-bill guard remains mandatory. This leaves score-based pricing/eligibility **OPEN** for a later package.

| Amount | Maximum first payment | Last payment | 12-month interest | Full scheduled total | B2 conservative quotes qualified |
|---|---:|---:|---:|---:|---:|
| $450 | $42.00 | $37.88 | $29.28 | $479.28 | 32/32 |
| $500 | $46.66 | $42.16 | $32.50 | $532.50 | 30/32 |

These quote counts use the **same 32 fixed native no-loan routes**, with genuine $5,500 and $5,700 starts; they are capacity calculations, not played $450 loans. On the locked two-settlement gate, first issuance in those routes can happen at cycles 16, 18 or 22, after first-game release and its rent pressure. A $500 loan cannot rescue the $0-cash, overdue-rent cycle-18 launches because it is unavailable until two later positive sales months.

The B1 historical alternative was a 10%-total-interest illustration: $50 interest on a $500 loan, first due at the next completed month. The recommended 1%-monthly schedule charges $32.50 over the full $500 term and postpones an odd-cycle origination's first due by one month. B1's fixed-action paths paid either illustration through their observed horizon; they did not test player behavior after borrowing, bank bills or delinquency.

## Payoff and missed-bill shape

For a $500 loan, three on-time installments pay $13.75 interest and $124.98 principal, leaving $375.02 principal. Immediate payoff then costs $375.02 and saves $18.75 future interest. At any payoff, add only already-due unpaid interest to unpaid principal; waive not-yet-due interest and charge no payoff fee. Service overdue rent first, then due bank interest/principal, then remaining principal. A due installment is one typed `bank_installment` bill retaining original due, split, payment history and overdue age. Partial payment does not reset age; repaying ends future late penalties without erasing history. Prototype credit weights remain trial values.

## Decision still needed

Confirm or change the amount menu, 1% scheduled-principal rate, 12-month term, first-full-month due rule and neutral score pricing. After that ruling, the exact quote, installment and early-payoff formulas can move from candidate to the authoritative economy design. The [handoff](HANDOFF.md) keeps implementation acceptance criteria separate. Nothing here enters the shared TODO until the user asks.
