# B2 two-settlement loan screen — design comparison

2026-10-06 (America/Los_Angeles). **Read-only evidence, not implementation.** After this study the user [approved the two-settlement gate, conservative capacity/share and mid-phase Bank access](2026-10-06-two-settlement-decision-v1.md). Loan price, term and due date remain open. The study reuses [B1](2026-10-06-b1-findings-v1.md)'s 32 native no-loan traces. The [analysis script](b2_two_settlements_v1.py) and [exact-cent output](evidence/b2-two-settlement-comparison-v1.json) stay in this thread folder. The shared TODO was not edited.

## Proposed first-loan screen

Require **two consecutive completed calendar months with positive actual settled portfolio sales** before the first $500 quote. A zero-sales month does not count as the second receipt and breaks the streak; a partial current month, earned-but-unsettled sales, publisher/Contract money, startup/trait financing and loan proceeds never count. Reject while any bill is overdue or another bank loan is active. Rent is $500 per completed month; live scheduled payroll/Student Loan/other loan payments would reduce surplus when those producers exist. The 1% monthly, 12-payment $500 offer and $46.66 maximum installment are still trial values.

At the second positive settlement, compare two exact-cent capacity rules:

```text
mean_sales = floor((older_settled_sales + latest_settled_sales) / 2)
average_capacity = floor(max(0, mean_sales - 50000 rent - live_other_dues) / 4)
conservative_sales = min(mean_sales, latest_settled_sales)
conservative_capacity = floor(max(0, conservative_sales - 50000 rent - live_other_dues) / 4)
qualify only if selected_capacity >= 4666 cents and the other guards pass
```

Use the **conservative rule** as the candidate. It respects the latest month's ability to cover rent and an installment while not treating an unusually high second month as the sole long-term signal. Requote from the most recent two consecutive positive completed months after eligibility; a zero month makes the new quote unavailable. An accepted loan keeps its original schedule when later sales decline. No rate, term, capacity coefficient, or score-based pricing has been approved by this analysis.

## Native route results

| First release | Second positive settlement | Current action when receipt lands | Month 2 settled sales, four unique routes | Two-month average capacity | Conservative capacity | Qualified with conservative screen |
|---|---|---|---|---|---|---|
| Cycle 12 | Cycle 16 | Design hand | $671.33–$797.20 | $271.85–$345.27 | $42.83–$74.30 | 3/4, or 6/8 including genuine trait pairs |
| Cycle 13 | Cycle 16 | Pre-Development | $1,657.34–$2,174.82 | $245.62–$361.01 | $245.62–$361.01 | 4/4, or 8/8 |
| Cycle 14 | Cycle 18 | Design hand | $811.19–$1,111.89 | $353.14–$527.97 | $77.79–$152.97 | 4/4, or 8/8 |
| Cycle 18 | Cycle 22 | Design hand | $1,055.94–$1,335.66 | $491.25–$660.83 | $138.98–$208.91 | 4/4, or 8/8 |

The plain two-month average qualifies **32/32** routes, so it adds timing but almost no screening in this set. The conservative rule qualifies **30/32**: both $5,500 and $5,700 versions of early/synergy/seed 1104 have $671.33 in Month 2, yielding only $42.83 capacity against the $46.66 installment. All 30 qualifying fixed-action $500 overlays could pay every observed due with no modeled negative cash or native rent-service divergence. Their first due is one completed month after the second settlement: cycles 18, 18, 20 and 24 by band. The trace horizon ends before full loan maturity, and these remain overlays rather than bank gameplay.

An exact boundary illustration uses the real $2,790.20 first settlement from early/ordinary/seed 1104 and hypothetical second settlements. At $100 of Month 2 sales, the average rule still says $236.27 capacity and approves; the conservative rule says $0 and rejects. At $600 it says $25.00 and rejects; at $686.63 it says $46.65 and rejects; at $686.64 it says $46.66 and qualifies, if bills are current. Zero sales fails the consecutive-positive gate even though the plain average alone would be high. These substituted second months are arithmetic counterexamples, **not** native gameplay routes.

## Access and pacing decision

The current cash HUD opens Finances and its Bank tab during any active gameplay phase, with no cycle cost (see `gameplay_hud.gd` `show_finances`, not just Studio). All observed second settlements occur while the player is in Design or Pre-Development. Therefore the two-settlement rule remains usable only if loan acceptance through that Bank tab is allowed during those phases. A Studio-only issuance rule would postpone these scripted offers until the second game's Studio return at cycles 26, 28, 30 or 38. **Propose Bank issuance and early payoff from any active phase through the existing passive HUD modal**, with an atomic transaction and input block; exact interaction policy still needs a design ruling.

The gate cannot add cash to the first game before its launch or first settlement. For a cycle-18 first release, it cannot issue until cycle 22; the native route already had $0 cash and rent arrears at cycle 18 and relied on genuine Contract cash to recover before settlement. The two-settlement screen therefore preserves the observed first-game pressure, including the $5,500/$5,700 difference. The exact human 6.2-rated route is still unavailable; these late scripted Reviews were 6.4–6.8.

## Review items

1. Rule on two **consecutive positive** completed sales months and the conservative `min(latest, two-month mean)` capacity basis. The user supports testing two settlements; the exact formula is a proposal.
2. Rule on Bank loan actions from every gameplay phase where the cash HUD already opens Finances. Studio-only issuance would make this gate much later in the current routes.
3. Then rule on the remaining $500 amount, 1% scheduled-principal monthly interest, 12-month term, first-full-month due convention, 25% surplus share, and score pricing/eligibility. Keep early-payoff waiver and typed original-due installment behavior from the accepted foundation.
4. Implementation verification must include a second month with $0/$100/$600/$686.63/$686.64 settled sales, stale quotes, one active loan, mid-phase finance modal input isolation, rent-first due ordering and partial/late bill history. No loan or shared-list task is authorized by this design note.
