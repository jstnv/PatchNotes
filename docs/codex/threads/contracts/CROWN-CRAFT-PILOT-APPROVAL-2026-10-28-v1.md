# Crown Craft Package — full bounded-pilot rules approved

2026-10-28. **APPROVED pilot rules; not implemented or final balance.**

User answered “Yes” to the bundled remaining rules review: two hands plus existing one-cycle Search, Scope9/Core4 completion, full balance at spread2.0 fading to zero at6.0, ordinary redraws, no extra Scope ceiling, no advance/base Promotion/Reputation/Investment. This completes the rules approval alongside the earlier [R5](CROWN-CRAFT-R5-APPROVAL-2026-10-28-v1.md) and [payout](CROWN-CRAFT-PAYOUT-APPROVAL-2026-10-28-v1.md) rulings.

## Approved pilot contract

| Field | Approved bounded-pilot rule |
|---|---|
| Eligibility | Crown discovered under existing rules and verified Crown Reputation≥5.00; standing is not spent. |
| Format | Two successful four-card hands with ordinary candidate/pool/specialization/redraw rules. Existing paid Search adds one cycle for a new offer; an already pending offer requires no repeat Search. |
| Completion | Scope9 and each Core4.0, using the existing weighted weakest-Core structure. Partial completion earns proportional base cash. |
| Base cash | Up to$1,500, rounded down to cents from the exact completion fraction. |
| Challenge | Core balance only: full through spread2.0, linear fade to zero at6.0. No extra Scope ceiling/no-redraw condition. |
| Bonus | Up to$100 and4 Promotion, independently rounded down from final balance grade. Missing the bonus does not reduce base cash. |
| Other rewards | Advance0, base Promotion0, Reputation0, Investment0. |
| Timing | Completion payment once on hand2 through ordinary transaction/finance/calendar rules. No award on hand1 or acceptance. |

With final Scope S and Core half-units h, approved existing completion semantics are `N = 2*min(S,9) + sum(min(hi,8)) + 2*min(min(hi),8)`, denominator66. Base cents=`floor(150000*N/66)`. Balance basis points=`max(0,10000-1250*max(0,max(hi)-min(hi)-4))`; bonus cents=`floor(10000*balance_bp/10000)` and Promotion=`floor(4*balance_bp/10000)`. Keep these components independent. Raw Scope above9 has no new penalty; no hidden minimum-work gate is added to the bonus.

## Supersession and scope

The pilot terms above supersede earlier proposed/OPEN labels for this package's rules in the [terms](CROWN-PAID-WORK-TERMS-2026-10-26-v1.md), previous approvals' remaining-review sections, v3 handoff and thread summaries. Earlier evidence remains historical; none approves balance. New [v4 pilot handoff](COMPACT-PACKAGE-HANDOFF-2026-10-28-v4.md) is the current work contract.

Existing publishers, cash introductions, frozen offers, Brief rewards, commissions and support retain their rules. This approval is for the bounded pilot and its isolated implementation/testing. It does not establish profitability, grant standing, activate the canonical Crown catalog, settle migration/exposure dependencies, or authorize a release. The known zero-Reputation exclusion remains. Current-source legal access, actual cash/Promotion settlement and payroll-aware career evidence remain to be produced.
