# Selectable amount and term — payment-shape comparison

2026-10-06 (America/Los_Angeles). **Design analysis only.** The user approved a $500 **minimum**, player choice of loan amount and term, and payments determined by that amount/term relationship. They agreed with the preceding proposed rate, first-full-month due, neutral first-offer score pricing and missed-bill treatment except the size menu. The maximum amount, permitted terms, increments and exact payment shape still need a ruling. This [read-only script](b4_flexible_terms_v1.py) compares two payment shapes using the locked two-settlement capacity and the same 32 native no-loan routes; [exact-cent output](evidence/b4-flexible-term-comparison-v1.json). No loan gameplay exists.

## Two ways to turn amount and term into monthly bills

Both models apply the agreed **1% monthly interest to scheduled opening principal**, round each month's interest half-up to cents and reconcile all principal by the final installment. A payment is due at the end of the first full calendar month after acceptance, then every two productive cycles. Missed payments do not compound the scheduled rate.

1. **Equal principal, declining bill:** Each regular month's principal is `floor(amount_cents / term_months)`, with the remainder in the last principal payment. Monthly bill is that principal share plus `round_half_up(1% × scheduled opening principal)`. The first bill is highest and each later bill generally falls. This is the shape used in B1–B3.
2. **Nearly level bill:** Compute the standard fixed-payment amortization amount from selected principal, monthly rate and selected term; round it to cents. Each month's interest is 1% of scheduled opening principal, with the rest of that bill paying principal. Adjust the final bill by a few cents to close the principal exactly. This makes payment comparison easier for a player, but total interest is slightly higher at the same rate/term because principal falls more slowly.

| Amount / term | Declining bill: first → last, total interest, eligible quotes | Nearly level bill: regular → final, total interest, eligible quotes |
|---|---|---|
| $500 / 12 months | $46.66 → $42.16; $32.50; 30/32 | $44.42 → $44.50; $33.12; 30/32 |
| $1,500 / 6 months | $265.00 → $252.50; $52.50; 6/32 | $258.82 → $258.83; $52.93; 6/32 |
| $1,500 / 12 months | $140.00 → $126.25; $97.50; 16/32 | $133.27 → $133.32; $99.29; 18/32 |
| $1,500 / 18 months | $98.33 → $84.22; $142.50; 22/32 | $91.47 → $91.53; $146.52; 22/32 |
| $2,500 / 12 months | $233.33 → $210.45; $162.50; 8/32 | $222.12 → $222.16; $165.48; 8/32 |
| $2,500 / 18 months | $163.88 → $140.43; $237.51; 12/32 | $152.46 → $152.39; $244.21; 14/32 |

The eligibility count compares each schedule's **highest** payment with the locked capacity, not just `amount / term`. At $1,500/12 months, level billing adds $1.79 full-term interest and qualifies two more matched routes because its highest bill is $133.32 rather than $140.00. Longer terms lower bills but cost more total interest and keep debt active longer. The route horizon is too short to show full maturity on most choices.

## Why the selectors need explicit bounds

If the only principal limit is the current capacity formula, a 12-month nearly level quote could permit $2,700–$4,000 on all four cycle-13 base routes; 18 months permits $4,000–$5,900; 24 months permits $5,200–$7,600 in $100-step arithmetic. Those runs have first-game Reviews from 4.2 to 5.9. This is a capacity calculation, **not** evidence that a $7,600 loan is balanced or playable. It shows that extending the term can bypass the practical restraint of a monthly-payment screen. The $500 minimum also makes a 6-month quote unavailable on several early low-sales routes even though 12 or 18 months would qualify.

**Recommendation for review:** Offer a selectable amount from **$500 up to a first-loan hard ceiling of $2,500**, in $100 steps, and terms of **6, 12 or 18 completed months**. Keep 24 months out of the first offer because it raises possible principal while extending debt across multiple games. Apply the locked capacity screen to the exact largest payment of every amount/term quote. An eligible player may choose any qualifying amount and term within the bounds; a longer term is not a promise that the loan is profitable. The ceiling, steps, term menu and level-versus-declining payment shape are **OPEN** until the user chooses them.

Any selected schedule must show total interest, total paid, all due dates, principal/interest splits, current capacity and early payoff. No score threshold or price change applies to this first offer; overdue bills still block origination. Early payoff remains unpaid principal plus already-due unpaid interest, with future unaccrued interest waived and no payoff fee. The typed obligation system must preserve partial payments, original age and credit history. No shared TODO task is created by this analysis.
