# Player 10.0 Review launch benefit — bounded capture v1

2026-10-10, America/Los_Angeles. **USER-PROVIDED SCREENSHOTS / OBSERVED ACCOUNTING; no numerical ruling.** This follows the same no-Cult run's [recovery capture](2026-10-10-10-review-recovery-player-feel-v1.md). The user supplied the 10.0 title's Monthly Sales and detailed Review Marketing/Sales panels. The images do not include a build hash, release identity across panels, full launch market context, or a matched zero-Fan launch. Shared checkout inspected: `main` at `41c87c76fb4d3c06a5332d93f0e7b0997007475d`, with concurrent uncommitted work. Current source was read for the Awareness and sales formulas, but screenshot-to-source identity is unverified.

| Capture | SHA-256 | Visible content |
|---|---|---|
| [Monthly Sales](captures/2026-10-10-player-10-review-sales-v1.png) | `CC46F433C434A5A71F7AC42B6D0382A343DBE436A2F695BADA1D5525919C442A` | Month1 complete and age month2 partial; lifetime units, gross, net, paid and unpaid. |
| [Review Sales panel](captures/2026-10-10-player-10-review-review-sales-v1.png) | `CBAA71E23524C98C6CDF24456134169C6DAA03E71C1FF381A4CD6EA72E16CC2A` | Projected Month1 units1930, projected gross/net and earned/paid totals. |
| [Review Marketing panel](captures/2026-10-10-player-10-review-marketing-v1.png) | `5F925354167BDB31D678E25FC31F58C8D1D688A24399EA261F6962B54F628CD4` | Total Awareness270, Launch Marketing59, frozen Fans367 and Fan Awareness91. |

## Visible reconciliation

Frozen **367 Fans → 91 Fan Awareness** matches the current trial `min(150, floor(367/4)) = 91` and is below the cap. Total Awareness is270; Fan Awareness is91/270, about33.7% of that total, **not** a 33.7% sales share. [Current Awareness source](../../../patch-notes/scripts/awareness/primitive_awareness_calculator.gd) has100 organic Awareness and59 shown Marketing; `270−100−59−91=20` remains attributable to an additional launch contribution or trait transformation, but the screenshots do not identify it. Do not infer a discrepancy or name its source from these panels alone.

The Month1 projection **1930 units** equals the Month1 actual shown in Monthly Sales. Month2 is explicitly **partial**, at359 units. `1930+359=2289` lifetime units; gross `$19,280.70+$3,586.41=$22,867.11`; net `$13,496.49+$2,510.48=$16,006.97`. Paid equals net and unpaid is `$0.00` in this capture. These totals reconcile across both panels. Month1 gross is exactly1930×$9.99, and its net is70% of gross rounded to cents under the inspected trial sales source. The same holds for the partial second month.

**Fixed-input source implication, not a measured alternate run:** [Current sales source](../../../patch-notes/scripts/sales/primitive_units_sold_calculator.gd) uses the multiplier `1 + total Awareness/200` once in Month1 units. At270 Awareness it is2.35. If only the91 Fan Awareness were removed while keeping all other inputs fixed, total Awareness would be179 and the multiplier1.895. Thus the Fan contribution raises **pre-rounded Month1 demand by about24.0% relative to that hypothetical zero-Fan case** (`2.35/1.895−1`). The screenshots do not supply a played zero-Fan comparator or independently verify the precise counterfactual integer units. Do not treat91/270 as the causal fraction of observed sales.

## Design disposition

This capture closes the narrow **visible frozen-Fans → Fan-Awareness → Month1 projection/actual** check for this player run, subject to its unverified build identity. It does not prove subjective sales usefulness, isolate the new title's Fan gains from older titles, or establish final 8% gain,15% loss or quarter-Awareness tuning. Keep those values **ACTIVE/TRIAL** and the final sales-benefit judgment **OPEN** pending the player's reaction. No implementation handoff or shared TODO change follows from reconciled panels alone.
