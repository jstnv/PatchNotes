# Fanbase gain-curve review v1

2026-10-06, America/Los_Angeles. **OPEN design recommendation, not a numerical approval or implementation handoff.** Source: the [legal current-branch replay](2026-10-06-current-branch-replay-v1.md) on `bd450a9e4e8d83ece1478cdf5a16526432e36cce` and the [verified loss accounting](2026-10-06-incremental-loss-verification-v1.md).

## What the curves do

Both candidates are zero at Review 5.0 and use the same provisional 8% scale. The branch uses `8% × min(1.5, (Review−5)/2)` for positive gain. The alternative uses `8% × min(1.5, sqrt((Review−5)/2))`. These are multipliers on the branch's trial eligible-unit proxy, not final conversion rates.

| Review | Branch linear gain per eligible unit | Square-root candidate | Direction |
|---:|---:|---:|---|
| 5.1 | 0.4% | 1.8% | Square-root gives about 4.5× the near-neutral reward. |
| 5.5 | 2.0% | 4.0% | Square-root gives 2×. |
| 6.1 | 4.4% | 5.9% | Square-root gives about 1.35×. |
| 7.0 | 8.0% | 8.0% | Equal. |
| 8.0 | 12.0% | 9.8% | Linear rewards the high Review more. |

The square-root proposal is more generous just above 5.0 but less generous from above 7.0 until its later cap. Calling it simply “gentler” obscures that tradeoff. Rounding can erase either candidate's reward for small eligible-unit counts.

## Observed route and limits

The legal route reached Reviews 4.9/7.0/6.1/7.0/6.9. At the first 6.1 monthly boundary the branch had 124 Fans and the fixed-sales square-root overlay had 135: **+11 Fans**. At the next launch the overlay had 167 rather than 149 Fans, producing **53 rather than 49 fan Awareness**. At unchanged other inputs, the next title's Month 1 formula gives a conditional **910 rather than 900 units**; that sale was not played under the alternative curve, and later compounding/cash are not fully propagated. This route has no near-5.1 or high-8+ positive Review comparison, no human response, and no identified buyer overlap.

## Recommendation for a ruling

**Retain the branch's linear quality shape as ACTIVE/TRIAL for the next playable demo comparison**, with its 8% scale and all buyer/reach/visibility constants still provisional. It is monotone through the observed 5–8 range and keeps rewards near 5.0 small; the current capture does not show a need to amplify marginally positive Reviews. This is a design recommendation, not user approval. A square-root choice would intentionally boost 5–7 Reviews and soften high Review rewards; if that is the intended player experience, it should be stated as the reason for switching.

The smallest later balance check, if the shape remains uncertain, is one legal route with a Review just above 5.0 and one above 8.0, comparing the two cumulative fan histories and next-launch Awareness while preserving true played sales versus fixed-sales overlays. Do not repeat the completed five-release route or lock the 8% rate from this analysis. Cult Following effect, loss rate, reserve size, cross-title overlap, rounding and fan-to-Awareness saturation remain OPEN.
