# Fan Awareness after 600 Fans — decision screen v1

2026-10-10, America/Los_Angeles. **OPEN design question / read-only arithmetic; no tuning approval.** Shared checkout inspected: `main` at `41c87c76fb4d3c06a5332d93f0e7b0997007475d`, with concurrent uncommitted work. The current source's [trial mapping](../../../patch-notes/scripts/fanbase/studio_fanbase.gd) is `min(150, floor(Fans/4))`. The [original candidate screen](2026-10-06-proportional-awareness-screen-v1.md) flagged that its 150 cap ends growth at600 Fans, but the recorded legal launches then had only96–267 Fans. The player's [current no-Cult run](2026-10-10-player-trial-feel-disposition-v1.md) now reaches597, bringing that threshold into immediate view.

| Frozen Fans at a future launch | Trial Fan Awareness |
|---:|---:|
|367, as in the observed 10.0 launch|91|
|597, the latest shown Studio total|149|
|600|150|
|867, an earlier current total in this run|150|
|895, the pre-0.4-loss total|150|

The observed 10.0 title's367→91 launch mapping and Month1 sales felt right to the player. That judgment **does not test the cap**, since the title launched below600. If the next title launches at597 Fans, it would receive149 Fan Awareness under current trial rules; three more Fans reach150, then all additional Fans provide no further *direct launch Awareness* while the count remains above600. Those Fans still form a larger audience buffer that can be lost to a later weak release and remain visible in the Studio history. The previous 0.4 release demonstrates why that buffer can matter: the Studio fell from895 to338 across its shown loss window despite concurrent gains.

## Conceptual options

1. **Retain the hard150 cap (current ACTIVE/TRIAL behavior).** Predictable ceiling and protection against runaway Month1 sales, but launch reward plateaus at600 Fans. No implementation change.
2. **Keep a smaller positive marginal reward after600, with diminishing returns.** Preserves a reason to grow a large audience while slowing the sales feedback loop. Exact curve, cap/absence of cap and thresholds would require a separate numerical decision and bounded long-run comparison before gameplay work.
3. **Continue quarter Awareness per Fan without a cap.** Simple proportionality, but the earlier fixed-launch screen showed Review7.0 Month1 units rising to1402 at1000 Fans and2652 at3000 Fans versus1152 under the cap, with other inputs fixed. Those are conditional projections, not played balance outcomes.

**Recommendation for discussion:** decide first whether post-600 Fans should still improve future launches in principle. If yes, screen a small set of taper candidates on a current-source legal longer route before selecting numbers; do not implement or queue a rate change yet. The8% gain,15% loss and quarter-to-150 mapping remain ACTIVE/TRIAL; the post-600 policy remains OPEN. The user's positive reaction to the present run does not lock a final cap.
