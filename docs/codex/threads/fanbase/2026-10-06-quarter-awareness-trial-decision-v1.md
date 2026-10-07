# Quarter Fan Awareness trial decision v1

2026-10-06, America/Los_Angeles. Source: the user's “Lets try it out” in direct response to the proposed **1 Fan → 0.25 fan-derived launch Awareness, capped at 150** trial from the [read-only candidate screen](2026-10-06-proportional-awareness-screen-v1.md).

## Ruling

- **ACTIVE/TRIAL numbers:** At a title's launch, freeze the nonnegative studio Fan count. Trial fan-derived Awareness is `min(150, floor(Fans / 4))`. The proportional range runs through 600 Fans; beyond that, the fan-derived component stays at 150. These values are approved for a bounded playable comparison, not final balance locks.
- **LOCKED mechanism retained:** Add this fan-derived component to organic and Marketing Awareness once. Keep the existing total-Awareness-to-sales formula; do not add a second Fan multiplier. Zero Fans contributes zero fan Awareness. Later changes in studio Fans do not retroactively recalculate an already launched title.
- **Scope:** Replace only the separate Fanbase branch's provisional saturating Fan-to-Awareness mapping for the trial. Its monthly fan accounting, linear Review-based gain shape, loss exposure structure, HUD/history, Review and sales formulas and accepted lifespan/settlement coefficients are separate. No main-branch merge or release approval follows from this choice.
- **Still OPEN:** Final ratio/cap/rounding after playtest, 8% conversion scale, loss percentage, launch-Fan reserve, cross-title overlap, long-run compounding and Cult Following. The current branch's later-month use of frozen launch Awareness can remain for this trial; its final balance is not decided.

The [implementation handoff](handoffs/2026-10-06-quarter-awareness-trial-v1.md) isolates the one branch mapping change and its acceptance checks. Do not add duplicate fan systems or treat the fixed-launch overlay as a played result. No TODO edit, gameplay change in this design thread, merge or push is authorized by this record.
