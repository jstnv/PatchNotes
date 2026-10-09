# Fanbase and future-game Awareness

Authority: “Fanbase and Future-Game Awareness” in the Sep30 design archive; current Tasks6,22 and accepted rent/lifespan authority. Status: DESIGN on main; a separate `codex/fanbase-on-main` implementation at `bd450a9` adds provisional monthly fans, launch Awareness and Fans HUD/history. It is not merged into main. Numerical rates remain unapproved.

## Locked design

Exactly5.0 Review is fan-neutral regardless of sales/marketing: zero gain and loss. Above5 may gain; below5 may lose existing fans. This supersedes Formula Bible's8%×Review/7 gain (which gains at5) and older gain/loss offset proposals. Preserve current Review and sales formulas.

RunState should own studio total and per-release processed earned-unit/exposure history with shared boundary identity. Use actual earned sales, not launch projection. Separate gain/loss/net, clamp total at zero, and prevent repeat callbacks/reconstruction from reapplying losses. The separate branch implements a first pass with provisional values; its presence does not approve final balance or timing policy.

**LOCKED audience meaning, 2026-10-06:** Fans are an estimated studio audience count, not an identified count of unique people. Sales records contain copies rather than buyer identities. The user accepted retaining the Fanbase branch's conservative eligible-unit proxy as **ACTIVE/TRIAL** for demo comparison: each title reserves up to its launch fan count from cumulative earned units before those units can recruit new fans. This does not lock a conversion rate, the size of the reserve, or overlap between simultaneous titles. [Decision and scope](../threads/fanbase/2026-10-06-buyer-definition-decision-v1.md).

**LOCKED incremental loss structure, 2026-10-06:** A below-5.0 release may lose more fans in later months only when its cumulative estimated reach increases. Charge only that title's newly reached portion, never its previously accounted exposure. All releases at one monthly boundary use the same pre-boundary studio fan count; summed losses cannot exceed that count, and same-boundary gains do not enlarge the loss pool. This does not lock the loss rate, reach estimate, rounding, or cross-title audience overlap. [Decision and focused verification](../threads/fanbase/2026-10-06-incremental-loss-decision-v1.md).

**LOCKED zero-minimum loss behavior, 2026-10-08:** A below-5.0 title may lose zero integer Fans when its cumulative calculated loss target is below one. Do not force a minimum one-Fan penalty; continue charging only increases in the cumulative target when later exposure warrants it. This narrow ruling does not approve the provisional 15% coefficient, reach/reserve proxy, other rounding details or cross-title overlap. The isolated branch already exhibits this behavior, so no gameplay correction is requested. [User decision and scope](../threads/fanbase/2026-10-08-zero-minimum-loss-decision-v1.md).

**ACTIVE/TRIAL loss scale, 2026-10-08:** After the played Review4.3 release lost9 of93 launch Fans, the user accepted that severity for the next playable comparison and selected retaining the branch's 15% coefficient. This is not final balance approval. The branch already uses the coefficient; current-main integration remains a separate task. The reach/exposure proxy, other rounding details and Review4.8–4.9 player feel remain OPEN. [Decision](../threads/fanbase/2026-10-08-loss-rate-trial-decision-v1.md).

**ACTIVE/TRIAL gain shape, 2026-10-06:** Keep the branch's linear increase with Review above 5.0 for the next playable comparison. This is the user's chosen trial shape; the 8% scale, quality cap and other numerical parameters are not approved. The square-root alternative remains read-only comparison evidence, not the current trial rule. [Decision](../threads/fanbase/2026-10-06-linear-gain-trial-decision-v1.md).

**LOCKED Fan Awareness direction / ACTIVE/TRIAL mapping, 2026-10-06:** Freeze the studio Fan count at launch and make its fan-derived Awareness contribution proportional over the intended playable range. For the next playable comparison, the user selected `min(150, floor(Fans/4))`: one fan contributes a quarter Awareness up to the 150 fan-Awareness cap. Total Awareness enters the existing Month 1 sales conversion once; do not multiply total Awareness or sales by Fans again. Zero Fans contributes zero fan Awareness, without disabling organic or Marketing Awareness. The exact ratio/cap/rounding are trial values, not final balance locks. The branch trial is implemented in isolated `codex/fanbase-quarter-trial` at bd450a9 plus two uncommitted files, verified2026-10-07; the original published branch is unchanged. [Direction](../threads/fanbase/2026-10-06-proportional-fan-awareness-decision-v1.md); [trial choice](../threads/fanbase/2026-10-06-quarter-awareness-trial-decision-v1.md).

## Candidate models and rationale

The branch's current launch Fan Awareness `150×Fans/(Fans+300)` is **SUPERSEDED for the next trial** by the user-selected quarter-per-Fan mapping above, though it remains the observed behavior of the published branch until changed. The older `Fans×0.25` proposal included launch decay1/.60/.35/.15; that decay is not approved by the new trial ruling. The branch's **provisional numbers** on the selected linear gain shape give 0.08×min(1.5,(Review−5)/2) above5. The unselected square-root comparison used 0.08×min(1.5,sqrt((Review−5)/2)); neither expression locks its 8% scale or cap. Both are zero at5. ACTIVE/TRIAL loss below5:0.15×(5−Review) applied to min(pre-release fans, Review-neutral potential reach); zero at/above5. Its 15% coefficient is selected for a playable trial, not final balance. Review-neutral reach avoids worse Reviews paradoxically protecting fans by reducing sales.

Task6 compared actual monthly sales with all-earned units versus estimated new buyers and returning-fan bounds. Copies sold do not identify unique people. Derive monthly integer deltas from cumulative per-title accounting and a common pre-boundary fan snapshot. The branch's Review-neutral shadow reach and per-title launch-fan cap remain trial exposure estimates.

## Open decisions / dependencies

Final gain/loss rates and caps, thresholds beyond5-neutrality, exact exposure estimate/returning-buyer bounds, rounding details beyond the zero-minimum rule, concurrent shared/distinct audiences, monthly revival, whether current gains feed same title versus future launch snapshot, final Fan-to-Awareness ratio/cap and later-month carryover. Linear gain shape, 15% loss scale and quarter-per-Fan Awareness mapping are selected trials above; incremental loss timing, the shared-boundary cap, zero-minimum loss behavior and proportional fan contribution direction are locked. Mature-studio weak-release recovery and20-release compounding require bounded evidence. Cult Following valuation depends on these choices; monetization backlash is deferred until monetization exists.

Historical3,000 below5 first games used old capped pools/approximate policies. Later legal high-Review routes and human9+ reports invalidate treating those distributions as a universal ceiling. Older bill$75/payroll$100 assumptions are overlays superseded for current economy comparisons by actual$500 rent/settlement. Reuse Task6 findings, then focus a new question after design ruling; do not repeat broad grids or infer fan numbers from sales.

See [evidence index](../findings/current-balance-evidence.md), [Traits](studio-traits.md), [lifespan](game-lifespan.md), [TODO](../TODO.md). Exact current task briefs remain in the targeted queue snapshot; no fan numerical approval was migrated.

## Trial verification, 2026-10-07

[Quarter and recovery findings](../threads/fanbase/2026-10-07-quarter-trial-recovery-findings-v1.md):92-action native route parity; propagated Game3/4/5 projections729/867/1172 distinguish fixed-original-Fan729/870/1178. A legal restrained0.0 Review after55 Fans loses41 at the first boundary, no repeated exhausted exposure, then a7.0 release rebuilds to165 bycycle70. Fixed-action no-loss comparison remains conditional. Retain structure for trial; defer final15% rate judgment from one extreme failure. No main merge or Cult amount approval.

## Near-neutral follow-up, 2026-10-07

[Two bounded attempts](../threads/fanbase/2026-10-07-near-neutral-findings-v1.md) produced Reviews3.6/3.5 after90/93 Fans, losing18/20. All accounting reconciles, but neither meets[4.0,5.0); near-neutral rounding remains unresolved. No coefficient/mapping or other trial rule changes. Further capture needs a separately scoped continuation; do not silently extend the exhausted two-attempt search.

## Separately approved continuation, 2026-10-08

The [single v2 continuation](../findings/fanbase-near-neutral-v2/README.md) reached native Review4.3 with93 launch Fans using4/4/4 hands on the same isolated trial source. Cumulative loss floors9.765 to9; the second earning boundary adds no exposure or loss. Concurrent other-title gains produce93→85→86 total Fans. Both boundaries and exact finance reconcile. This completes the bounded[4.0,5.0) capture; it does not directly observe4.8–4.9 or approve final rates, rounding beyond the zero-minimum rule, overlap or integration into main. The one-attempt allowance is exhausted; all design statuses above remain unchanged.
