# Near-neutral Fan loss rounding screen v1

2026-10-08, America/Los_Angeles. **CALCULATED sensitivity, not a played route or approved rate.** Source: isolated `codex/fanbase-quarter-trial` at `bd450a9e4e8d83ece1478cdf5a16526432e36cce` plus its recorded two-file trial diff, cross-checked against `StudioFanbase.plan` in that worktree. Main has no Fanbase runtime. The [legal v1 capture](2026-10-07-near-neutral-findings-v1.md) observed Reviews 3.6/3.5 after 90/93 launch Fans; it did not observe the Reviews below.

For a weak title, the branch computes cumulative `exposed = min(launch_fans, neutral_estimated_reach)` and `loss_target = floor(exposed × 15 × (50 − review_tenths) / 1000)`. A month charges only the increase in that title's target, subject to the shared pre-boundary Fan cap. `15` is the **provisional** coefficient. Review exactly 5.0 has zero loss. The first cumulative loss requires at least the following estimated exposure:

| Review | Trial loss at full reach, before flooring | Exposure needed for first lost Fan |
|---:|---:|---:|
| 4.9 | 1.5% of exposed Fans | 67 |
| 4.8 | 3% | 34 |
| 4.5 | 7.5% | 14 |
| 4.0 | 15% | 7 |

The next table assumes **full exposure reaches all launch Fans**, no other title gains or loses Fans, and no further change before a later launch. It therefore shows a conditional cumulative target, not monthly timing, actual studio net Fans, sales or cash. Fan Awareness uses the selected **ACTIVE/TRIAL** `min(150, floor(Fans/4))` at that later launch.

| Launch Fans | Review 4.9: loss; Fan Awareness before→after | Review 4.8: loss; Awareness | Review 4.5: loss; Awareness |
|---:|---:|---:|---:|
| 55 | 0; 13→13 | 1; 13→13 | 4; 13→12 |
| 90 | 1; 22→22 | 2; 22→22 | 6; 22→21 |
| 93 | 1; 23→23 | 2; 23→22 | 6; 23→21 |
| 96 | 1; 24→23 | 2; 24→23 | 7; 24→22 |
| 150 | 2; 37→37 | 4; 37→36 | 11; 37→34 |
| 600 | 9; 150→147 | 18; 150→145 | 45; 150→138 |

**Interpretation:** A Review 4.9 title at 55 launch Fans can fully exhaust its capped reach and still lose zero Fans under this trial. At 90 or 93 Fans it loses one at full reach, but the later quarter-Fan Awareness can remain unchanged. At 96 Fans the same one-Fan loss crosses an Awareness step. If neutral reach is below the first-loss threshold, loss is zero even when launch Fans exceed it. Other titles' gains may hide the net studio-count decline; a later release's own Review, organic Awareness, Marketing, market and settlement also affect sales/cash. No player-facing fairness conclusion follows from these calculations alone.

**Next decision boundary:** Read the dispatched [one-attempt v2 capture](handoffs/2026-10-07-near-neutral-continuation-v2.md) when it arrives. A Review near 4.8–4.9 with nonzero Fans would test this edge directly; a Review near 4.0 would inform moderate weakness but leave the immediate-neutral edge unplayed. If the attempt misses, do not expand the search from this screen. Decide separately whether zero loss for low Fan counts near 5.0 is acceptable; changing coefficient, rounding or a minimum loss requires explicit design approval.
