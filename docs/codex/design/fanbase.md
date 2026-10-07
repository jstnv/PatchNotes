# Fanbase and future-game Awareness

Authority: “Fanbase and Future-Game Awareness” in the Sep30 design archive; current Tasks6,22 and accepted rent/lifespan authority. Status: DESIGN; no runtime accrual, persistent studio fan counter or attrition. PrimitiveAwarenessCalculator currently has EXISTING_FANS=0 and fan_awareness=0.

## Locked design

Exactly5.0 Review is fan-neutral regardless of sales/marketing: zero gain and loss. Above5 may gain; below5 may lose existing fans. This supersedes Formula Bible's8%×Review/7 gain (which gains at5) and older gain/loss offset proposals. Preserve current Review and sales formulas.

RunState should own studio total and per-release processed earned-unit/exposure history with shared boundary identity. Use actual earned sales, not launch projection. Separate gain/loss/net, clamp total at zero, and prevent repeat callbacks/reconstruction from reapplying losses. No runtime implementation approved without remaining balance/timing decisions.

## Candidate models and rationale

Trial launch fan Awareness150×fans/(fans+300) bounded linear compounding; it is unapproved, as is older visibility fans×0.25 with launch decay1/.60/.35/.15. Candidate gains above5:
- linear0.08×min(1.5,(Review−5)/2);
- gentler0.08×min(1.5,sqrt((Review−5)/2)).
Both zero at5. Candidate loss below5:0.15×(5−Review) applied to min(pre-release fans, Review-neutral potential reach); zero at/above5. Review-neutral reach avoids worse Reviews paradoxically protecting fans by reducing sales.

Task6 compared actual monthly sales with all-earned units versus estimated new buyers and returning-fan bounds. Copies sold do not identify unique people. Derive monthly integer deltas from cumulative per-title accounting and a common pre-boundary fan snapshot; do not charge full one-release loss every month.

## Open decisions / dependencies

Gain/loss curves, thresholds beyond5-neutrality, unique exposure/returning buyers, rounding, loss timing, concurrent shared/distinct audiences, monthly revival, whether current gains feed same title versus future launch snapshot, fan visibility saturation/decay. Mature-studio weak-release recovery and20-release compounding require bounded evidence. Cult Following valuation depends on these choices; monetization backlash is deferred until monetization exists.

Historical3,000 below5 first games used old capped pools/approximate policies. Later legal high-Review routes and human9+ reports invalidate treating those distributions as a universal ceiling. Older bill$75/payroll$100 assumptions are overlays superseded for current economy comparisons by actual$500 rent/settlement. Reuse Task6 findings, then focus a new question after design ruling; do not repeat broad grids or infer fan numbers from sales.

See [evidence index](../findings/current-balance-evidence.md), [Traits](studio-traits.md), [lifespan](game-lifespan.md), [TODO](../TODO.md). Exact current task briefs remain in the targeted queue snapshot; no fan numerical approval was migrated.
