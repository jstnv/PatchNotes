# Larger first-loan offers — design sensitivity

2026-10-06 (America/Los_Angeles). **Amount ceiling reopened, no new cap approved.** The user questioned the earlier $500 ceiling because one month's rent is already $500 and early-game sales progress beyond that scale. This read-only comparison uses the [locked two-settlement capacity rule](2026-10-06-two-settlement-decision-v1.md), the same 32 native $5,500/$5,700 no-loan routes as [B1/B2](2026-10-06-b2-two-settlement-findings-v1.md), and trial 1% monthly scheduled-principal interest. See [script](b3_larger_offers_v1.py) and [exact-cent results](evidence/b3-larger-offer-comparison-v1.json). No gameplay or shared TODO change was made.

## Quote sizes under the locked capacity screen

| Candidate amount | Max payment, 12 months | Full interest, 12 months | Quotes qualifying, 12 months | Max payment, 18 months | Full interest, 18 months | Quotes qualifying, 18 months |
|---|---:|---:|---:|---:|---:|---:|
| $500 | $46.66 | $32.50 | 30/32 | $32.77 | $47.51 | 32/32 |
| $750 | $70.00 | $48.78 | 26/32 | $49.16 | $71.25 | 30/32 |
| $1,000 | $93.33 | $65.00 | 22/32 | $65.55 | $95.01 | 28/32 |
| $1,250 | $116.66 | $81.26 | 20/32 | $81.94 | $118.76 | 22/32 |
| $1,500 | $140.00 | $97.50 | 16/32 | $98.33 | $142.50 | 22/32 |
| $2,000 | $186.66 | $130.00 | 12/32 | $131.11 | $190.00 | 18/32 |
| $2,500 | $233.33 | $162.50 | 8/32 | $163.88 | $237.51 | 12/32 |

The 12-month $1,500 payment is $140, versus $500 monthly rent. It is large enough to cover the observed ~$1,150 first Feature spend and most of one rent bill, although that spend is a route average, not a fixed cost. A $2,000 payment is $186.66 and full-term interest $130. The 18-month term makes larger principals pass more quotes but raises total interest and leaves the obligation active six months longer; these traces do not reach full maturity. For the already eligible fixed-action overlays, no modeled payment missed or native rent-service path diverged **through the observed route horizon**. Those paths keep their original purchases and project actions, so this is not evidence that spending a larger loan is safe or balanced.

Qualification varies sharply by release alignment and revenue, which argues for an amount menu rather than one mandatory large principal:

| First release | $1,000 eligible, 12 months | $1,500 eligible, 12 months | $2,000 eligible, 12 months | Reading |
|---|---:|---:|---:|---|
| Cycle 12 | 0/8 | 0/8 | 0/8 | Month 2 sales $671–$797; $100-step affordable maximum is $400–$700. |
| Cycle 13 | 8/8 | 8/8 | 8/8 | A partial first sales month followed by a stronger full second month lifts capacity even for Reviews 4.2–5.9. All eight also quote $2,500, a warning against an uncapped capacity-only loan. |
| Cycle 14 | 6/8 | 2/8 | 0/8 | Sales support mid-sized offers; $100-step affordable maximum ranges $800–$1,500. |
| Cycle 18 | 8/8 | 6/8 | 4/8 | Later high sales support more principal, but these runs hit $0 cash and rent arrears at first release, before any loan is available. |

## Recommendation for review

Use **$100–$1,500 in $100 steps** for the first loan, still constrained by the approved two-month capacity and overdue-bill guards. This replaces the earlier $100–$500 menu as the candidate. $1,500 is roughly one observed Feature pool plus most of one rent bill; it is 27% of $5,500 starting capital. A $100-step menu lets the weakest observed pair borrow $400 even though $500 fails, while strong routes can request a meaningful larger amount. The $1,500 ceiling also prevents the 13-cycle routes with Reviews as low as 4.2 from immediately borrowing $2,500 solely because their second sales month is strong. Neither the $1,500 cap nor the $100 step is approved.

Keep the **12-month term** as the current candidate. Extending to 18 months changes eligibility considerably but increases total interest, leaves debt open longer and is not necessary to offer up to $1,500 on the strongest 12-month routes. The exact rate, term, first due, score pricing and loan amount ceiling still need a user ruling. A later lending tier could be studied after more settled sales and a repayment record; no later tier or automatic increase is approved now.

## Evidence limits and next checks

These are arithmetic quotes and additive fixed-action overlays on no-loan routes. They exclude adaptive Store purchases, changed development speed, how extra cash affects credit/rent choices, true bank bills, and full-term repayment. At $1,500, observed route horizons included only 7–9 of 12 installments, leaving $375–$625 principal; that remaining debt must not be counted as available wealth. The exact human 6.2-rated late path remains unavailable. Before implementation, test a legal adaptive route that actually spends a larger loan and reaches full maturity, plus a weak second-sales rejection and rent/bank payment collision. Keep the accepted first-game pressure intact: no offer exists before two completed positive sales months.
