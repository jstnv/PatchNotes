# Post-600 Awareness taper — trial recommendation v1

2026-10-11, America/Los_Angeles. **DESIGN RECOMMENDATION / OPEN NUMERICAL DECISION.** This is analysis of existing evidence, not a new simulation, implementation request, or approval. Shared checkout inspected: `main` at `41c87c76fb4d3c06a5332d93f0e7b0997007475d` with concurrent edits. The current runtime remains `min(150, floor(Fans/4))` at **ACTIVE/TRIAL** status. The user has **LOCKED the direction** that launches continue benefiting above 600 Fans with diminishing returns, but has not chosen a curve.

## Concrete choice

The [played sixth release](2026-10-10-post-600-strong-launch-comparison-v1.md) is the best available anchor: Review 10.0, 940 frozen Fans, 150 Fan Awareness, 2,086 projected Month 1 units and 182 title-attributed Fans across months 86–87. The source-pinned, fixed-action alternatives below change only Fan Awareness; they were not played.

| At the played 940-Fan launch | Current cap | Mild candidate | Moderate candidate |
|---|---:|---:|---:|
| Fan Awareness | 150 | 165 | 180 |
| Month 1 units | 2,086 | 2,148 (+62, about 3%) | 2,209 (+123, about 6%) |
| Title Fans, months 86–87 | 182 | 192 (+10) | 201 (+19) |
| Studio Fans at month 87 | 1,133 | 1,143 (+10) | 1,152 (+19) |

The [fixed-input screen](2026-10-10-post-600-taper-screen-v1.md) also gives Fan Awareness at 1,500 Fans of 150 / 179 / 208 and at 3,000 Fans of 150 / 198 / 247. With the same other launch Awareness as the earlier observed 10.0 title, the 3,000-Fan mild/moderate values imply about 9% / 18% higher pre-rounded Month 1 demand than the current cap. These are scale indicators, not a late-game route or a balance verdict. Both candidate tails meet the 150 value at 600, but their marginal slopes drop at that threshold; integer display steps may be flat even as the underlying candidate rises.

## Recommendation and reason

**Recommend the mild candidate for the first bounded playable trial, if the user wants a numerical choice now.** It makes the approved post-600 direction visible on the actual 940-Fan launch while changing the tested early/midgame segment through 600 by zero. Its +3% Month 1 difference is a smaller change from the current played experience than the moderate +6%, and its distant fixed-input scale is less likely to outrun the still-unobserved late-game route. The user's “almost done” assessment for early/midgame growth supports preserving that segment; it is **not** feedback that 2,086 units or 182 Fans from the 940-Fan launch felt right, and it does not approve the mild constants.

Mild may feel too close to a plateau, especially just above 600. Moderate gives a clearer ongoing reward and a gentler drop in marginal contribution at 600, but raises Month 1 units and subsequent Fan growth more. A choice between them should be based on player preference for the 940-Fan anchor and one later natural launch if the distinction remains unclear.

## Smallest next gate

Ask the player to choose **mild first**, **moderate first**, or **defer until a later natural launch** after reviewing the actual 940-Fan anchor above. If a trial is selected, record the exact approved candidate as **ACTIVE/TRIAL** in a new decision and create a versioned implementation handoff. That handoff should preserve frozen launch Fans, all inputs through 600, once-only Awareness conversion, checkpoint/Continue parity, the source's monthly sales and Fan accounting, and a legal strong/weak later-launch route. Specify a deterministic integer tail before implementation; the logarithmic equations in the read-only comparison are mathematical candidate shapes, not approved runtime syntax. Record actual player feel after the playable change and check the longer route for compounding before final numeric approval.

**Status:** No numerical tail selected. No implementation handoff or shared TODO update is ready from this recommendation alone. Existing gain/loss rates, reach proxy and overlap remain **ACTIVE/TRIAL or OPEN** as recorded in [the authoritative design](../../design/fanbase.md).
