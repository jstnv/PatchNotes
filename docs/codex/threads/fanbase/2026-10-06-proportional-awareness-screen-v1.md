# Proportional Fan Awareness screen v1

2026-10-06, America/Los_Angeles. **Read-only fixed-launch arithmetic; candidate values only.** Implements the bounded [analysis handoff](handoffs/2026-10-06-proportional-awareness-analysis-v1.md) on the completed legal route from `origin/codex/fanbase-on-main` at `bd450a9e4e8d83ece1478cdf5a16526432e36cce`. The source route JSON SHA-256 is `62F6744CD69881136E85851A7D235E4DE601C76B24A76E0C1F0582EB8D8B6BE8`. [Reproducible overlay script](proportional-awareness-v1.js) SHA-256 `9A361CA500018680CED2B2D4937FAC9573EA66BE61A35A760D9F6482655CA49A`; [full candidate output](proportional-awareness-v1.json) SHA-256 `516BD92E59730AA43427EADB8F1B7A2EF0B99C0B4F959A35354C5707842BA5EC`.

## Method

For each captured release, keep its actual launch Review, organic Awareness 100, Marketing, and market basis points fixed. Replace only the branch's fan-derived Awareness `floor(150×Fans/(Fans+300))` with candidate `floor(Fans×ratio)`, either uncapped or capped at a **candidate** 150 fan Awareness. Reuse the unchanged Month 1 formula `floor(500×Review/7×(1+total Awareness/200)×market)`. Net Month 1 entitlement if those units were earned is `floor(units×999 cents×70%)`; launch itself earns and settles nothing. The overlay exactly reproduced all five captured branch Month 1 units and projected net cents before alternatives were calculated. It is not a played route.

| Launch | Branch Fan Awareness / units | Quarter Awareness / units | Third Awareness / units | Two-fifths Awareness / units |
|---|---:|---:|---:|---:|
| Game 3: 96 Fans, Review 6.1 | 36 / 755 | 24 / 729 (−26) | 32 / 747 (−8) | 38 / 760 (+5) |
| Game 4: 149 Fans, Review 7.0 | 49 / 900 | 37 / 870 (−30) | 49 / 900 (0) | 59 / 925 (+25) |
| Game 5: 267 Fans, Review 6.9 | 70 / 1,191 | 66 / 1,178 (−13) | 89 / 1,252 (+61) | 106 / 1,307 (+116) |

All candidate caps at 150 are inactive for these three recorded launches. The quarter ratio's potential Month 1 net entitlement deltas versus branch are −$181.82, −$209.79 and −$90.91 for Games 3–5, respectively. The third ratio's are −$55.94, $0 and +$426.57. These are **conditional entitlements**, not cash received or a matched-calendar finance forecast.

## Scale and rounding stress

Hold Game 4's Review 7.0, Marketing 11 and market 10,000 basis points fixed; substitute hypothetical studio Fans. At zero Fans, all options have zero fan-derived Awareness and 777 Month 1 units from organic/Marketing. At 1–2 Fans all shown ratios still round fan Awareness to zero. At 3 Fans the quarter ratio still contributes zero, while the third and two-fifths ratios contribute one.

| Hypothetical Fans | Branch saturating Awareness / units | Quarter uncapped | Third uncapped | Quarter or third with 150 cap |
|---:|---:|---:|---:|---:|
| 1,000 | 115 / 1,065 | 250 / 1,402 | 333 / 1,610 | 150 / 1,152 |
| 3,000 | 136 / 1,117 | 750 / 2,652 | 1,000 / 3,277 | 150 / 1,152 |

The uncapped candidates become much stronger than the current branch as Fans grow. A 150 cap limits that stress effect but ends strict proportionality at 600 Fans for a quarter ratio or 450 for a third. Neither cap nor threshold is approved. A larger cap or taper would require another explicit tuning choice.

## Recommendation and boundary

**Candidate for the next trial:** quarter Fan Awareness per frozen Fan, with a candidate 150 fan-Awareness cap. It keeps the recorded 96–267-Fan launches close to branch demand, leaves a longer proportional range than the third ratio, and avoids the large uncapped stress outputs. This recommendation is not a user ruling or implementation request; the ratio, cap and integer rounding remain OPEN. If the design goal requires strict proportionality beyond 600 Fans, the cap would conflict with it and a larger-range balance comparison is needed.

The three launch rows deliberately hold each recorded Fan snapshot fixed. Changed Game 3 sales would alter later Fan gains, so Game 4's 149 and Game 5's 267 are **not** a propagated alternative route. For example, holding Game 4's 149 Fans fixed, quarter's 870 rather than 900 Month 1 units would change that title's provisional 8%-conversion target by three Fans for Month 1; earlier Game 3 and later monthly sales would also change. Do not add the table's conditional entitlements to a cash ledger or claim a legal strong→weak→recovery playthrough from it. That feedback and a mature-studio weak release remain the next focused capture if the user wants final tuning.

No gameplay, TODO, merge, commit, push or Drive change was made for this screen.
