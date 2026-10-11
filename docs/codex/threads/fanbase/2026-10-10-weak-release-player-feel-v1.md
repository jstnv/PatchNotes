# Player 0.4 Review Fan loss — bounded review v1

2026-10-10, America/Los_Angeles. **USER-PROVIDED VISIBLE CAPTURE AND PLAYER FEEL; no new numerical ruling.** This continues the same no-Cult run in the [earlier screenshot review](2026-10-10-player-capture-review-v1.md). The user says the later **0.4 Review** and resulting Fan loss “feels right.” Images are preserved in this thread; no build/checkpoint hash accompanied them. Shared checkout inspected: `main` at `41c87c76fb4d3c06a5332d93f0e7b0997007475d` with concurrent uncommitted work. The source formula was read, but screenshot-to-source identity is not independently proven.

| Capture | SHA-256 | Directly visible |
|---|---|---|
| [Release list](captures/2026-10-10-player-review-list-v1.png) | `FA396565BDDD7040BA0863182E3A0584957A42C82320C4C2238098076CBDE17F` | Prior titles have Reviews7.7,9.1 and9.3; title “3” is the9.3 third release. |
| [0.4 Review with Fans history](captures/2026-10-10-player-weak-release-loss-v1.png) | `16C97896E18427731A25AAECE2021A034AF8B50FF95B0D5A97E5F11D7FD74A54` | Fourth title “a (1984)” Review0.4; current338 Fans at1984 Month58 First Half/cycle114; monthly gains/losses through month57. |

## Visible arithmetic

The earlier capture ended month52 with867 Fans. Month53 adds28, reaching895. The weak-release loss is then charged incrementally:

| Calendar month | Starting Fans | Other gains | Loss | Ending Fans | Cumulative shown loss |
|---:|---:|---:|---:|---:|---:|
|54|895|21|207|709|207|
|55|709|17|279|447|486|
|56|447|12|109|350|595|
|57|350|10|22|338|617|

Every row reconciles. Across months54–57, other releases add60 Fans while the weak title loses617, giving `895 + 60 − 617 = 338`. The screenshots show only one below-5.0 title in the four-title list, so attributing the displayed losses to the0.4 title is supported by the visible release set, though per-title Fan journal details are not shown.

**Formula cross-check, conditional on the screenshot using the inspected trial source:** [StudioFanbase](../../../patch-notes/scripts/fanbase/studio_fanbase.gd) uses `floor(exposed × 15 × (50 − review_tenths) / 1000)`. At Review0.4, the factor is `15 × 46 / 1000 = 0.69`. `floor(895 × 0.69) = 617`, exactly the cumulative displayed loss. The895 Fans at the preceding boundary are therefore consistent with a frozen895-Fan launch and capped neutral reach ultimately exposing all895. Frozen launch Fans, neutral reach and source hash are **inferred**, not directly displayed. This is a strong consistency check, not a native journal audit.

The visible summary shows total launch Awareness250, projected Month1 units48, lifetime68 units at the captured point, earned/settled net$475.52 and no unpaid sales. If frozen launch Fans were895, the current quarter mapping would cap Fan Awareness at150; the screenshot does not break out that contribution from other Awareness sources. A very poor Review produced low sales despite high total Awareness, consistent with the design's Review-dependent sales and Review-neutral shadow reach. The screenshot alone cannot quantify that counterfactual reach.

## Design disposition

The player said this severe loss **feels right**. Record that as **OBSERVED qualitative support** for retaining the existing15% loss coefficient and incremental structure in the ongoing playable trial. It does **not** lock15% as a final rate, validate losses near Review4.8–4.9, settle cross-title audience overlap, or establish longer recovery balance. The earlier no-Cult growth to867 also felt “About right” to the player. Together these observations support continuing the trial without a Fanbase tuning change from these screenshots. No new implementation handoff or TODO entry is justified by this capture alone.
