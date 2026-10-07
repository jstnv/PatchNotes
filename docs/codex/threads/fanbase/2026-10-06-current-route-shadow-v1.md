# Fanbase on a rent-era legal route: fixed-sales shadow v1

2026-10-06, America/Los_Angeles. **Status: OBSERVED source route plus READ-ONLY modeled fan overlays. No design value is approved.** This narrows the next branch capture without changing gameplay or rerunning a broad grid.

## Source and method

The local Task 32 [native route](../../../../patch-notes/design-logs/task32-v1/route_early_ordinary_1104_available_0_0.json) is a legal five-release, Action/ordinary/seed 1104/early-alignment/available-Contract path under main `e054791d0348d90faf70e9d827892c351fa018bc` plus documented pending Task 33 finance work. Its [source report](../../../../patch-notes/design-logs/task32-v1/native-summary.csv) gives Reviews 4.9 / 7.0 / 6.1 / 7.0 / 6.9 at cycles 12 / 32 / 50 / 68 / 86, with no final arrears. It is automated legal play, not a human route, and precedes the Fanbase branch and current trait-selection start. The source records actual per-cycle sales, cash and actions; this analysis holds its sales sequence fixed.

I read each recorded release's cumulative earned units at even calendar cycles. On that frozen sequence, I applied the `bd450a9` branch's provisional rule: launch fans reserved once per title; cumulative gain target `floor(max(0, cumulative earned units − launch fans) × 0.08 × min(1.5,(Review−5)/2))`, with monthly gain as the target minus previously booked gain. The comparison changes only the gain shape to `sqrt((Review−5)/2)` inside the same cap. Both are zero at/below 5.0. A new release snapshots the total after earlier titles' same-cycle settlement. No loss occurs in this particular overlay because the only below-5 title launches with zero fans. The saturated Awareness calculation is `floor(150 × fans/(fans+300))`.

| Release | Cycle | Recorded Review | Recorded launch Awareness without fans | Linear shadow fans at launch → fan Awareness | Square-root shadow fans at launch → fan Awareness |
|---|---:|---:|---:|---:|---:|
| 1 | 12 | 4.9 | 104 | 0 → 0 | 0 → 0 |
| 2 | 32 | 7.0 | 110 | 0 → 0 | 0 → 0 |
| 3 | 50 | 6.1 | 111 | 96 → 36 | 96 → 36 |
| 4 | 68 | 7.0 | 111 | 141 → 47 | 157 → 51 |
| 5 | 86 | 6.9 | 102 | 238 → 66 | 251 → 68 |

At cycle 34, the 7.0 title has earned 697 units and the linear/square-root curves both grant 55 fans from the zero-fan launch. At cycle 50 its cumulative target is 96 fans. The 6.1 title launches with those 96; at cycle 52 the two curves grant 25 versus 34 additional fans on its frozen sales, after reserving those 96 launch fans. By Game 4, the square-root candidate is 16 fans and four launch Awareness points ahead on the frozen sequence. This is a concrete near-threshold difference, not evidence that one curve feels better to players.

## Limits and decision use

These are **fixed-sales shadows**, not Fanbase-branch runtime results. Applying fan Awareness to Game 3 and later would change their units, later fan gains, cash, and perhaps legal actions. Task 32's source predates the current trait preview and other branch changes; its old actions must be revalidated before replay. The route has no established fanbase when its 4.9 release launches, so it provides no weak-release loss evidence. It also cannot identify unique buyers or audience overlap from aggregate units.

This route is therefore suitable for one bounded current-branch replay and gain-curve comparison. Keep a separate weak-release exposure decision open. The older Task 17 6.4→9.8 route is useful historical sensitivity, but its pre-rent action sequence is a poorer direct replay target. [Focused handoff v2](handoffs/2026-10-06-current-branch-replay-v2.md) scopes the next evidence step.
